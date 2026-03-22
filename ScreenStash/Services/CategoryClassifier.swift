import Foundation

struct CategoryClassifier {

    /// Classify a screenshot based on its extracted OCR text
    func classify(text: String) -> ScreenshotCategory {
        let lowered = text.lowercased()

        if isReceipt(lowered) { return .receipt }
        if isCode(lowered) { return .code }
        if isError(lowered) { return .error }
        if isSocialMedia(lowered) { return .socialMedia }
        if isConversation(lowered) { return .conversation }
        if isMap(lowered) { return .map }
        if isArticle(lowered) { return .article }
        if isMeme(text) { return .meme }
        if isAppScreen(lowered) { return .appScreen }

        return .other
    }

    // MARK: - Classification Heuristics

    private func isReceipt(_ text: String) -> Bool {
        let keywords = ["total", "subtotal", "tax", "receipt", "invoice", "payment",
                        "order #", "order number", "amount due", "visa", "mastercard",
                        "paid", "transaction"]
        let dollarPattern = #"\$\d+\.\d{2}"#
        let hasDollar = text.range(of: dollarPattern, options: .regularExpression) != nil
        let matchCount = keywords.filter { text.contains($0) }.count
        return matchCount >= 2 || (matchCount >= 1 && hasDollar)
    }

    private func isCode(_ text: String) -> Bool {
        let keywords = ["verification", "otp", "code:", "your code is", "confirm",
                        "two-factor", "2fa", "authenticate", "sign in code",
                        "security code", "passcode"]
        let sixDigitPattern = #"\b\d{4,8}\b"#
        let hasCodes = text.range(of: sixDigitPattern, options: .regularExpression) != nil
        let matchCount = keywords.filter { text.contains($0) }.count
        return matchCount >= 1 && hasCodes
    }

    private func isError(_ text: String) -> Bool {
        let keywords = ["error", "failed", "crash", "exception", "fatal",
                        "cannot connect", "something went wrong", "try again",
                        "not responding", "unexpected", "404", "500",
                        "unable to", "timed out"]
        let matchCount = keywords.filter { text.contains($0) }.count
        return matchCount >= 2
    }

    private func isSocialMedia(_ text: String) -> Bool {
        let keywords = ["@", "likes", "followers", "following", "retweet",
                        "share", "comment", "instagram", "twitter", "tiktok",
                        "snapchat", "facebook", "reddit", "threads",
                        "♥", "❤️", "reply", "repost"]
        let matchCount = keywords.filter { text.contains($0) }.count
        return matchCount >= 3
    }

    private func isConversation(_ text: String) -> Bool {
        let keywords = ["delivered", "read", "imessage", "whatsapp", "telegram",
                        "signal", "messenger", "text message", "sms"]
        let timePattern = #"\d{1,2}:\d{2}\s*(am|pm|AM|PM)"#
        let hasTimestamps = text.range(of: timePattern, options: .regularExpression) != nil
        let matchCount = keywords.filter { text.contains($0) }.count
        // Short lines with timestamps suggest chat
        let lines = text.components(separatedBy: "\n").filter { !$0.isEmpty }
        let shortLines = lines.filter { $0.count < 80 }
        let isChatlLike = shortLines.count > lines.count / 2 && lines.count > 3
        return matchCount >= 1 || (hasTimestamps && isChatlLike)
    }

    private func isMap(_ text: String) -> Bool {
        let keywords = ["directions", "navigate", "miles", "km", "min drive",
                        "route", "map", "street", "avenue", "boulevard",
                        "google maps", "apple maps", "waze"]
        let matchCount = keywords.filter { text.contains($0) }.count
        return matchCount >= 2
    }

    private func isArticle(_ text: String) -> Bool {
        // Long-form text with paragraphs
        let lines = text.components(separatedBy: "\n").filter { !$0.isEmpty }
        let longLines = lines.filter { $0.count > 100 }
        let keywords = ["read more", "subscribe", "published", "author",
                        "share this", "related articles", "min read"]
        let matchCount = keywords.filter { text.contains($0) }.count
        return longLines.count >= 3 || matchCount >= 2
    }

    private func isMeme(_ text: String) -> Bool {
        // Memes typically have very little text, often in ALL CAPS
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return false }
        let uppercaseRatio = Double(trimmed.filter(\.isUppercase).count) / Double(trimmed.count)
        return trimmed.count < 50 && uppercaseRatio > 0.6
    }

    private func isAppScreen(_ text: String) -> Bool {
        let keywords = ["settings", "general", "notifications", "privacy",
                        "display", "account", "profile", "preferences",
                        "toggle", "switch", "enable", "disable", "version"]
        let matchCount = keywords.filter { text.contains($0) }.count
        return matchCount >= 3
    }
}
