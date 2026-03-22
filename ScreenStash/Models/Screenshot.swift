import Foundation
import SwiftData

@Model
final class Screenshot {
    @Attribute(.unique) var assetLocalID: String
    var extractedText: String
    var category: ScreenshotCategory
    var createdAt: Date
    var processedAt: Date
    var isDuplicate: Bool
    var duplicateGroupID: UUID?
    var perceptualHash: String?
    var detectedURLs: [String]
    var detectedPhoneNumbers: [String]
    var detectedEmails: [String]
    var thumbnailData: Data?

    init(
        assetLocalID: String,
        extractedText: String = "",
        category: ScreenshotCategory = .other,
        createdAt: Date = .now,
        processedAt: Date = .now,
        isDuplicate: Bool = false,
        duplicateGroupID: UUID? = nil,
        perceptualHash: String? = nil,
        detectedURLs: [String] = [],
        detectedPhoneNumbers: [String] = [],
        detectedEmails: [String] = [],
        thumbnailData: Data? = nil
    ) {
        self.assetLocalID = assetLocalID
        self.extractedText = extractedText
        self.category = category
        self.createdAt = createdAt
        self.processedAt = processedAt
        self.isDuplicate = isDuplicate
        self.duplicateGroupID = duplicateGroupID
        self.perceptualHash = perceptualHash
        self.detectedURLs = detectedURLs
        self.detectedPhoneNumbers = detectedPhoneNumbers
        self.detectedEmails = detectedEmails
        self.thumbnailData = thumbnailData
    }
}
