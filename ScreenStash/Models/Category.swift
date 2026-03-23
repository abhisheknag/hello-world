import Foundation
import SwiftUI

enum ScreenshotCategory: String, Codable, CaseIterable, Identifiable {
    case receipt
    case conversation
    case article
    case socialMedia
    case code
    case map
    case appScreen
    case meme
    case error
    case other

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .receipt: "Receipts"
        case .conversation: "Conversations"
        case .article: "Articles"
        case .socialMedia: "Social Media"
        case .code: "Codes & OTPs"
        case .map: "Maps & Addresses"
        case .appScreen: "App Screens"
        case .meme: "Memes"
        case .error: "Errors"
        case .other: "Other"
        }
    }

    var icon: String {
        switch self {
        case .receipt: "receipt"
        case .conversation: "bubble.left.and.bubble.right.fill"
        case .article: "doc.text.fill"
        case .socialMedia: "person.2.fill"
        case .code: "lock.shield.fill"
        case .map: "map.fill"
        case .appScreen: "apps.iphone"
        case .meme: "face.smiling.fill"
        case .error: "exclamationmark.triangle.fill"
        case .other: "square.grid.2x2.fill"
        }
    }

    var color: Color {
        switch self {
        case .receipt: .green
        case .conversation: .blue
        case .article: .orange
        case .socialMedia: .pink
        case .code: .red
        case .map: .teal
        case .appScreen: .indigo
        case .meme: .yellow
        case .error: .red
        case .other: .gray
        }
    }

    /// Categories available in the free tier
    static let freeCategories: [ScreenshotCategory] = [.receipt, .conversation, .code]

    /// Maximum screenshots in free tier
    static let freeScreenshotLimit = 25
}
