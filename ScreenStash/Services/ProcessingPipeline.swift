import Foundation
import SwiftData
import Photos
import UIKit

@Observable
final class ProcessingPipeline {

    var isProcessing = false
    var processedCount = 0
    var totalCount = 0
    var progress: Double {
        guard totalCount > 0 else { return 0 }
        return Double(processedCount) / Double(totalCount)
    }

    private let importer = ScreenshotImporter()
    private let ocrEngine = OCREngine()
    private let classifier = CategoryClassifier()
    private let batchSize = 20

    /// Run the full import → OCR → classify pipeline
    func processNewScreenshots(modelContext: ModelContext, since lastSync: Date? = nil) async {
        isProcessing = true
        defer { isProcessing = false }

        let assets = await importer.fetchScreenshots(after: lastSync)
        totalCount = assets.count
        processedCount = 0

        // Process in batches
        for batchStart in stride(from: 0, to: assets.count, by: batchSize) {
            let batchEnd = min(batchStart + batchSize, assets.count)
            let batch = Array(assets[batchStart..<batchEnd])

            for asset in batch {
                // Skip if already processed
                let assetID = asset.localIdentifier
                let existing = try? modelContext.fetch(
                    FetchDescriptor<Screenshot>(
                        predicate: #Predicate { $0.assetLocalID == assetID }
                    )
                )
                if existing?.isEmpty == false {
                    processedCount += 1
                    continue
                }

                await processAsset(asset, modelContext: modelContext)
                processedCount += 1
            }

            // Save after each batch
            try? modelContext.save()
        }
    }

    private func processAsset(_ asset: PHAsset, modelContext: ModelContext) async {
        // Load image
        guard let image = await importer.loadImage(for: asset) else { return }

        // Run OCR
        let ocrResult: OCREngine.OCRResult
        do {
            ocrResult = try await ocrEngine.extractText(from: image)
        } catch {
            // Still save the screenshot even if OCR fails
            ocrResult = OCREngine.OCRResult(text: "", urls: [], phoneNumbers: [], emails: [])
        }

        // Classify
        let category = classifier.classify(text: ocrResult.text)

        // Load thumbnail
        let thumbnailData = await importer.loadThumbnail(for: asset)

        // Create model
        let screenshot = Screenshot(
            assetLocalID: asset.localIdentifier,
            extractedText: ocrResult.text,
            category: category,
            createdAt: asset.creationDate ?? .now,
            processedAt: .now,
            detectedURLs: ocrResult.urls,
            detectedPhoneNumbers: ocrResult.phoneNumbers,
            detectedEmails: ocrResult.emails,
            thumbnailData: thumbnailData
        )

        modelContext.insert(screenshot)
    }
}
