import XCTest
import SwiftUI
@testable import Cookstemma

final class IconComponentsTests: XCTestCase {

    // MARK: - Number Abbreviation Tests

    func testAbbreviated_smallNumbers() {
        XCTAssertEqual(0.abbreviated, "0")
        XCTAssertEqual(1.abbreviated, "1")
        XCTAssertEqual(999.abbreviated, "999")
    }

    func testAbbreviated_thousands() {
        XCTAssertEqual(1000.abbreviated, "1K")
        XCTAssertEqual(1500.abbreviated, "1.5K")
        XCTAssertEqual(9999.abbreviated, "9.9K")
        XCTAssertEqual(10000.abbreviated, "10K")
        XCTAssertEqual(50000.abbreviated, "50K")
        XCTAssertEqual(999000.abbreviated, "999K")
    }

    func testAbbreviated_millions() {
        XCTAssertEqual(1000000.abbreviated, "1.0M")
        XCTAssertEqual(1500000.abbreviated, "1.5M")
        XCTAssertEqual(10000000.abbreviated, "10.0M")
    }

    // MARK: - AppIcon Constants Tests

    func testAppIcon_tabBarIcons_exist() {
        XCTAssertFalse(AppIcon.home.isEmpty)
        XCTAssertFalse(AppIcon.homeOutline.isEmpty)
        XCTAssertFalse(AppIcon.recipes.isEmpty)
        XCTAssertFalse(AppIcon.recipesOutline.isEmpty)
        XCTAssertFalse(AppIcon.create.isEmpty)
        XCTAssertFalse(AppIcon.saved.isEmpty)
        XCTAssertFalse(AppIcon.profile.isEmpty)
    }

    func testAppIcon_actionIcons_exist() {
        XCTAssertFalse(AppIcon.like.isEmpty)
        XCTAssertFalse(AppIcon.likeOutline.isEmpty)
        XCTAssertFalse(AppIcon.comment.isEmpty)
        XCTAssertFalse(AppIcon.share.isEmpty)
        XCTAssertFalse(AppIcon.save.isEmpty)
    }

    func testAppIcon_navigationIcons_exist() {
        XCTAssertFalse(AppIcon.back.isEmpty)
        XCTAssertFalse(AppIcon.close.isEmpty)
        XCTAssertFalse(AppIcon.search.isEmpty)
        XCTAssertFalse(AppIcon.notifications.isEmpty)
        XCTAssertFalse(AppIcon.settings.isEmpty)
    }

    func testAppIcon_contentIcons_exist() {
        XCTAssertFalse(AppIcon.recipe.isEmpty)
        XCTAssertFalse(AppIcon.log.isEmpty)
        XCTAssertFalse(AppIcon.photo.isEmpty)
        XCTAssertFalse(AppIcon.timer.isEmpty)
        XCTAssertFalse(AppIcon.star.isEmpty)
    }

    func testAppIcon_socialIcons_exist() {
        XCTAssertFalse(AppIcon.follow.isEmpty)
        XCTAssertFalse(AppIcon.following.isEmpty)
        XCTAssertFalse(AppIcon.followers.isEmpty)
        XCTAssertFalse(AppIcon.block.isEmpty)
    }

    // MARK: - Tab Tests

    func testTab_allCases_haveFiveTabs() {
        XCTAssertEqual(MainTabView.Tab.allCases.count, 5)
    }

    func testTab_icons_areDifferent() {
        let tab = MainTabView.Tab.home
        XCTAssertNotEqual(tab.icon, tab.activeIcon)
    }

    // MARK: - View Existence Tests
    // These ensure views can be instantiated without crashing

    func testStarRating_createsView() {
        let view = StarRating(rating: 4)
        XCTAssertNotNil(view)
    }

    func testInteractiveStarRating_createsView() {
        var rating = 3
        let view = InteractiveStarRating(rating: .init(get: { rating }, set: { rating = $0 }))
        XCTAssertNotNil(view)
    }

    func testAvatarView_createsView() {
        let view = AvatarView(url: nil)
        XCTAssertNotNil(view)
    }

    func testLoadingView_createsView() {
        let view = LoadingView()
        XCTAssertNotNil(view)
    }
}
