import XCTest
@testable import Cookstemma

@MainActor
final class AppStateTests: XCTestCase {
    var sut: AppState!

    override func setUp() {
        super.setUp()
        sut = AppState()
    }

    override func tearDown() {
        sut = nil
        super.tearDown()
    }

    // MARK: - Scroll To Top Trigger Tests

    func testHomeScrollToTopTrigger_initialValue_isZero() {
        XCTAssertEqual(sut.homeScrollToTopTrigger, 0)
    }

    func testRecipesScrollToTopTrigger_initialValue_isZero() {
        XCTAssertEqual(sut.recipesScrollToTopTrigger, 0)
    }

    func testSearchScrollToTopTrigger_initialValue_isZero() {
        XCTAssertEqual(sut.searchScrollToTopTrigger, 0)
    }

    func testProfileScrollToTopTrigger_initialValue_isZero() {
        XCTAssertEqual(sut.profileScrollToTopTrigger, 0)
    }

    func testTriggerHomeScrollToTop_incrementsCounter() {
        let initialValue = sut.homeScrollToTopTrigger

        sut.triggerHomeScrollToTop()

        XCTAssertEqual(sut.homeScrollToTopTrigger, initialValue + 1)
    }

    func testTriggerRecipesScrollToTop_incrementsCounter() {
        let initialValue = sut.recipesScrollToTopTrigger

        sut.triggerRecipesScrollToTop()

        XCTAssertEqual(sut.recipesScrollToTopTrigger, initialValue + 1)
    }

    func testTriggerSearchScrollToTop_incrementsCounter() {
        let initialValue = sut.searchScrollToTopTrigger

        sut.triggerSearchScrollToTop()

        XCTAssertEqual(sut.searchScrollToTopTrigger, initialValue + 1)
    }

    func testTriggerProfileScrollToTop_incrementsCounter() {
        let initialValue = sut.profileScrollToTopTrigger

        sut.triggerProfileScrollToTop()

        XCTAssertEqual(sut.profileScrollToTopTrigger, initialValue + 1)
    }

    func testTriggerSearchScrollToTop_multipleCalls_incrementsEachTime() {
        sut.triggerSearchScrollToTop()
        sut.triggerSearchScrollToTop()
        sut.triggerSearchScrollToTop()

        XCTAssertEqual(sut.searchScrollToTopTrigger, 3)
    }

    func testTriggerProfileScrollToTop_multipleCalls_incrementsEachTime() {
        sut.triggerProfileScrollToTop()
        sut.triggerProfileScrollToTop()
        sut.triggerProfileScrollToTop()

        XCTAssertEqual(sut.profileScrollToTopTrigger, 3)
    }
}
