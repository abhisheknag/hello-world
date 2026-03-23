import Foundation
import Vision
import UIKit

actor OCREngine {

    struct OCRResult {
        let text: String
        let urls: [String]
        let phoneNumbers: [String]
        let emails: [String]
    }

    func extractText(from image: UIImage) async throws -> OCRResult {
        guard let cgImage = image.cgImage else {
            return OCRResult(text: "", urls: [], phoneNumbers: [], emails: [])
        }

        let text = try await performOCR(on: cgImage)
        let urls = extractURLs(from: text)
        let phoneNumbers = extractPhoneNumbers(from: text)
        let emails = extractEmails(from: text)

        return OCRResult(
            text: text,
            urls: urls,
            phoneNumbers: phoneNumbers,
            emails: emails
        )
    }

    private func performOCR(on cgImage: CGImage) async throws -> String {
        try await withCheckedThrowingContinuation { continuation in
            let request = VNRecognizeTextRequest { request, error in
                if let error {
                    continuation.resume(throwing: error)
                    return
                }

                let observations = request.results as? [VNRecognizedTextObservation] ?? []
                let text = observations
                    .compactMap { $0.topCandidates(1).first?.string }
                    .joined(separator: "\n")
                continuation.resume(returning: text)
            }

            request.recognitionLevel = .accurate
            request.usesLanguageCorrection = true
            request.automaticallyDetectsLanguage = true

            let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
            do {
                try handler.perform([request])
            } catch {
                continuation.resume(throwing: error)
            }
        }
    }

    // MARK: - Entity Extraction

    private func extractURLs(from text: String) -> [String] {
        let detector = try? NSDataDetector(types: NSTextCheckingResult.CheckingType.link.rawValue)
        let range = NSRange(text.startIndex..., in: text)
        let matches = detector?.matches(in: text, range: range) ?? []
        return matches.compactMap { $0.url?.absoluteString }
    }

    private func extractPhoneNumbers(from text: String) -> [String] {
        let detector = try? NSDataDetector(types: NSTextCheckingResult.CheckingType.phoneNumber.rawValue)
        let range = NSRange(text.startIndex..., in: text)
        let matches = detector?.matches(in: text, range: range) ?? []
        return matches.compactMap { $0.phoneNumber }
    }

    private func extractEmails(from text: String) -> [String] {
        let pattern = #"[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}"#
        let regex = try? NSRegularExpression(pattern: pattern)
        let range = NSRange(text.startIndex..., in: text)
        let matches = regex?.matches(in: text, range: range) ?? []
        return matches.compactMap { match in
            guard let range = Range(match.range, in: text) else { return nil }
            return String(text[range])
        }
    }
}
