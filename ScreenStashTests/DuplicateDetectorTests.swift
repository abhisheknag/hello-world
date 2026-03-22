import XCTest
@testable import ScreenStash

final class DuplicateDetectorTests: XCTestCase {
    let detector = DuplicateDetector()

    func testIdenticalHashesHaveZeroDistance() async {
        let distance = await detector.hammingDistance("abcdef0123456789", "abcdef0123456789")
        XCTAssertEqual(distance, 0)
    }

    func testCompletelyDifferentHashesHaveHighDistance() async {
        let distance = await detector.hammingDistance("0000000000000000", "ffffffffffffffff")
        XCTAssertEqual(distance, 64)
    }

    func testSimilarHashesHaveLowDistance() async {
        // Hashes differing by 1 bit
        let distance = await detector.hammingDistance("0000000000000000", "0000000000000001")
        XCTAssertEqual(distance, 1)
    }

    func testInvalidHashReturnsMaxDistance() async {
        let distance = await detector.hammingDistance("invalid", "0000000000000000")
        XCTAssertEqual(distance, Int.max)
    }

    func testHashComputationReturnsNonNil() async {
        // Create a simple test image
        let size = CGSize(width: 100, height: 100)
        UIGraphicsBeginImageContext(size)
        UIColor.red.setFill()
        UIRectFill(CGRect(origin: .zero, size: size))
        let image = UIGraphicsGetImageFromCurrentImageContext()!
        UIGraphicsEndImageContext()

        let hash = await detector.computeHash(for: image)
        XCTAssertNotNil(hash)
    }

    func testSameImageProducesSameHash() async {
        let size = CGSize(width: 100, height: 100)
        UIGraphicsBeginImageContext(size)
        UIColor.blue.setFill()
        UIRectFill(CGRect(origin: .zero, size: size))
        let image = UIGraphicsGetImageFromCurrentImageContext()!
        UIGraphicsEndImageContext()

        let hash1 = await detector.computeHash(for: image)
        let hash2 = await detector.computeHash(for: image)

        XCTAssertEqual(hash1, hash2)
    }
}
