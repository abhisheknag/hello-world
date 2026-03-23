import Foundation
import UIKit
import SwiftData

actor DuplicateDetector {

    /// Hamming distance threshold for considering images as duplicates
    private let hammingThreshold = 10

    /// Compute a perceptual hash (dHash) for an image.
    /// Resizes to 9x8 grayscale, compares adjacent pixels to produce a 64-bit hash.
    func computeHash(for image: UIImage) -> String? {
        guard let cgImage = image.cgImage else { return nil }

        // Resize to 9x8
        let width = 9
        let height = 8
        let colorSpace = CGColorSpaceCreateDeviceGray()
        let bitmapInfo = CGImageAlphaInfo.none.rawValue

        guard let context = CGContext(
            data: nil,
            width: width,
            height: height,
            bitsPerComponent: 8,
            bytesPerRow: width,
            space: colorSpace,
            bitmapInfo: bitmapInfo
        ) else { return nil }

        context.draw(cgImage, in: CGRect(x: 0, y: 0, width: width, height: height))

        guard let data = context.data else { return nil }
        let pixels = data.bindMemory(to: UInt8.self, capacity: width * height)

        // Compute difference hash: compare each pixel with its right neighbor
        var hash: UInt64 = 0
        for row in 0..<height {
            for col in 0..<(width - 1) {
                let leftPixel = pixels[row * width + col]
                let rightPixel = pixels[row * width + col + 1]
                if leftPixel > rightPixel {
                    hash |= 1
                }
                hash <<= 1
            }
        }

        return String(hash, radix: 16)
    }

    /// Compute Hamming distance between two hex hash strings
    func hammingDistance(_ hash1: String, _ hash2: String) -> Int {
        guard let val1 = UInt64(hash1, radix: 16),
              let val2 = UInt64(hash2, radix: 16) else {
            return Int.max
        }
        let xor = val1 ^ val2
        return xor.nonzeroBitCount
    }

    /// Find and flag duplicate screenshots in the database
    func detectDuplicates(modelContext: ModelContext) async throws {
        let screenshots = try modelContext.fetch(
            FetchDescriptor<Screenshot>(
                predicate: #Predicate { $0.perceptualHash != nil }
            )
        )

        // Group by similar hashes
        var processed = Set<String>()

        for i in 0..<screenshots.count {
            let screenshotA = screenshots[i]
            guard let hashA = screenshotA.perceptualHash,
                  !processed.contains(screenshotA.assetLocalID) else { continue }

            var duplicateGroup: [Screenshot] = []

            for j in (i + 1)..<screenshots.count {
                let screenshotB = screenshots[j]
                guard let hashB = screenshotB.perceptualHash,
                      !processed.contains(screenshotB.assetLocalID) else { continue }

                if hammingDistance(hashA, hashB) <= hammingThreshold {
                    duplicateGroup.append(screenshotB)
                    processed.insert(screenshotB.assetLocalID)
                }
            }

            if !duplicateGroup.isEmpty {
                let groupID = UUID()
                screenshotA.isDuplicate = true
                screenshotA.duplicateGroupID = groupID
                processed.insert(screenshotA.assetLocalID)

                for dup in duplicateGroup {
                    dup.isDuplicate = true
                    dup.duplicateGroupID = groupID
                }
            }
        }

        try modelContext.save()
    }
}
