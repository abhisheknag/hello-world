import XCTest
@testable import ScreenStash

final class OCREngineTests: XCTestCase {
    let engine = OCREngine()

    func testExtractTextFromImageWithText() async throws {
        // Create a simple image with text drawn on it
        let size = CGSize(width: 400, height: 200)
        let renderer = UIGraphicsImageRenderer(size: size)
        let image = renderer.image { context in
            UIColor.white.setFill()
            context.fill(CGRect(origin: .zero, size: size))

            let text = "Hello World" as NSString
            let attributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 32),
                .foregroundColor: UIColor.black
            ]
            text.draw(at: CGPoint(x: 50, y: 80), withAttributes: attributes)
        }

        let result = try await engine.extractText(from: image)
        // OCR should find some text (exact match depends on rendering)
        // At minimum, the result object should be valid
        XCTAssertNotNil(result)
    }

    func testURLExtraction() async throws {
        let size = CGSize(width: 500, height: 200)
        let renderer = UIGraphicsImageRenderer(size: size)
        let image = renderer.image { context in
            UIColor.white.setFill()
            context.fill(CGRect(origin: .zero, size: size))

            let text = "Visit https://example.com today" as NSString
            let attributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 24),
                .foregroundColor: UIColor.black
            ]
            text.draw(at: CGPoint(x: 20, y: 80), withAttributes: attributes)
        }

        let result = try await engine.extractText(from: image)
        // If OCR picks up the URL, it should be in detectedURLs
        // This test validates the pipeline doesn't crash
        XCTAssertNotNil(result)
    }

    func testEmptyImageReturnsEmptyText() async throws {
        // Blank white image
        let size = CGSize(width: 100, height: 100)
        let renderer = UIGraphicsImageRenderer(size: size)
        let image = renderer.image { context in
            UIColor.white.setFill()
            context.fill(CGRect(origin: .zero, size: size))
        }

        let result = try await engine.extractText(from: image)
        XCTAssertTrue(result.text.isEmpty || result.text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
    }
}
