import XCTest
import SwiftUI
@testable import Cookstemma

final class SplashViewTests: XCTestCase {

    // MARK: - View Existence Tests

    func testSplashView_createsView() {
        let view = SplashView()
        XCTAssertNotNil(view)
    }

    func testSplashView_body_isNotNil() {
        let view = SplashView()
        let body = view.body
        XCTAssertNotNil(body)
    }
}
