import XCTest
@testable import PastPaperTracker

final class PhotoStoreTests: XCTestCase {
    func testSaveAndDeletePhotoData() throws {
        let store = PhotoStore()
        let relativePath = try store.saveImageData(Data([0x00, 0x01, 0x02]), for: UUID())

        XCTAssertTrue(store.fileExists(relativePath: relativePath))

        store.delete(relativePath: relativePath)

        XCTAssertFalse(store.fileExists(relativePath: relativePath))
    }
}
