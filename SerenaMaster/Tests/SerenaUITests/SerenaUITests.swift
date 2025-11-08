import XCTest
@testable import SerenaUI

final class SerenaUITests: XCTestCase {
    
    func testSerenaUIVersion() {
        XCTAssertEqual(SerenaUI.version, "1.0.0")
    }
}