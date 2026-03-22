import XCTest
@testable import ScreenStash

final class CategoryClassifierTests: XCTestCase {
    let classifier = CategoryClassifier()

    func testReceiptDetection() {
        let text = "Starbucks\nGrande Latte $5.75\nTax $0.46\nTotal $6.21\nVisa ending 4242"
        XCTAssertEqual(classifier.classify(text: text), .receipt)
    }

    func testCodeDetection() {
        let text = "Your verification code is 847291. This code expires in 10 minutes."
        XCTAssertEqual(classifier.classify(text: text), .code)
    }

    func testErrorDetection() {
        let text = "Something went wrong\nError: Unable to connect to the server. Please try again later."
        XCTAssertEqual(classifier.classify(text: text), .error)
    }

    func testSocialMediaDetection() {
        let text = "@johndoe\n1,234 likes\n42 comments\nShare this post\nInstagram"
        XCTAssertEqual(classifier.classify(text: text), .socialMedia)
    }

    func testConversationDetection() {
        let text = "iMessage\n10:32 AM\nHey, are you coming?\n10:33 AM\nYeah, on my way!\nDelivered"
        XCTAssertEqual(classifier.classify(text: text), .conversation)
    }

    func testMapDetection() {
        let text = "Google Maps\n15 min drive\n3.2 miles\nTake Route 66 to Main Street"
        XCTAssertEqual(classifier.classify(text: text), .map)
    }

    func testArticleDetection() {
        let longText = """
        The future of artificial intelligence is being shaped by a handful of companies \
        that are investing billions of dollars in research and development. These investments \
        are leading to breakthroughs in natural language processing, computer vision, and \
        robotics that could transform industries from healthcare to transportation.

        Published by John Smith. Read more about this topic in our related articles below.
        """
        XCTAssertEqual(classifier.classify(text: longText), .article)
    }

    func testMemeDetection() {
        let text = "WHEN YOU REALIZE"
        XCTAssertEqual(classifier.classify(text: text), .meme)
    }

    func testAppScreenDetection() {
        let text = "Settings\nGeneral\nNotifications\nPrivacy & Security\nDisplay & Brightness\nVersion 17.2"
        XCTAssertEqual(classifier.classify(text: text), .appScreen)
    }

    func testOtherForAmbiguousText() {
        let text = "Hello world"
        XCTAssertEqual(classifier.classify(text: text), .other)
    }

    func testEmptyTextReturnsOther() {
        XCTAssertEqual(classifier.classify(text: ""), .other)
    }
}
