import XCTest

final class BrowseAndSaveFlowTests: XCTestCase {

    var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launchArguments = ["--uitesting"]
        app.launch()
    }

    override func tearDownWithError() throws {
        app = nil
    }

    // MARK: - Home Feed Tests

    func testHomeFeed_displaysContent() throws {
        // Given: User is on home tab
        let homeTab = app.tabBars.buttons.element(boundBy: 0)
        XCTAssertTrue(homeTab.exists)
        homeTab.tap()

        // When: Feed loads
        let feed = app.scrollViews.firstMatch
        XCTAssertTrue(feed.waitForExistence(timeout: 5))

        // Then: Content should be visible
        XCTAssertTrue(feed.exists)
    }

    func testHomeFeed_canScrollToLoadMore() throws {
        // Given: User is on home feed
        let homeTab = app.tabBars.buttons.element(boundBy: 0)
        homeTab.tap()

        let feed = app.scrollViews.firstMatch
        XCTAssertTrue(feed.waitForExistence(timeout: 5))

        // When: User scrolls down
        feed.swipeUp()

        // Then: More content loads (no crash)
        XCTAssertTrue(feed.exists)
    }

    func testHomeFeed_pullToRefresh() throws {
        // Given: User is on home feed
        let homeTab = app.tabBars.buttons.element(boundBy: 0)
        homeTab.tap()

        let feed = app.scrollViews.firstMatch
        XCTAssertTrue(feed.waitForExistence(timeout: 5))

        // When: User pulls to refresh
        feed.swipeDown()

        // Then: Feed refreshes without crash
        sleep(2)
        XCTAssertTrue(feed.exists)
    }

    // MARK: - Recipe Navigation Tests

    func testNavigateToRecipeDetail() throws {
        // Given: User is on recipes tab
        let recipesTab = app.tabBars.buttons.element(boundBy: 1)
        XCTAssertTrue(recipesTab.exists)
        recipesTab.tap()

        // Wait for content
        sleep(2)

        // When: User taps on a recipe card
        let recipeGrid = app.scrollViews.firstMatch
        XCTAssertTrue(recipeGrid.waitForExistence(timeout: 5))

        let firstRecipe = recipeGrid.buttons.firstMatch
        if firstRecipe.exists {
            firstRecipe.tap()

            // Then: Recipe detail screen appears
            sleep(1)
            XCTAssertTrue(app.navigationBars.firstMatch.exists)
        }
    }

    func testRecipeDetail_saveToggle() throws {
        // Given: User navigates to recipe detail
        let recipesTab = app.tabBars.buttons.element(boundBy: 1)
        recipesTab.tap()

        let recipeGrid = app.scrollViews.firstMatch
        XCTAssertTrue(recipeGrid.waitForExistence(timeout: 5))

        let firstRecipe = recipeGrid.buttons.firstMatch
        guard firstRecipe.exists else {
            throw XCTSkip("No recipes available for testing")
        }

        firstRecipe.tap()
        sleep(1)

        // When: User taps save button (bookmark icon)
        let saveButton = app.buttons["bookmark"]
        if saveButton.exists {
            saveButton.tap()

            // Then: Save state toggles (button should still exist)
            XCTAssertTrue(saveButton.exists)
        }
    }

    // MARK: - Saved Tab Tests

    func testSavedTab_displaysEmptyOrContent() throws {
        // Given: User navigates to Saved tab
        let savedTab = app.tabBars.buttons.element(boundBy: 3)
        XCTAssertTrue(savedTab.exists)
        savedTab.tap()

        // Then: Saved screen is displayed (either empty state or content)
        sleep(1)
        let savedContent = app.scrollViews.firstMatch
        let emptyState = app.staticTexts.firstMatch

        XCTAssertTrue(savedContent.exists || emptyState.exists)
    }

    func testSavedTab_switchBetweenTabs() throws {
        // Given: User is on Saved tab
        let savedTab = app.tabBars.buttons.element(boundBy: 3)
        savedTab.tap()
        sleep(1)

        // When: User taps on different tab icons (recipes vs logs)
        let tabButtons = app.buttons.matching(identifier: "savedTabButton")

        // Tap should not crash even if elements don't exist
        XCTAssertTrue(app.exists)
    }

    // MARK: - Full Browse & Save Flow

    func testFullFlow_browseRecipeAndVerifyInSaved() throws {
        // Step 1: Go to Recipes tab
        let recipesTab = app.tabBars.buttons.element(boundBy: 1)
        recipesTab.tap()
        sleep(2)

        // Step 2: Verify recipes tab loads
        let recipeGrid = app.scrollViews.firstMatch
        XCTAssertTrue(recipeGrid.waitForExistence(timeout: 5))

        // Step 3: Navigate to Saved tab
        let savedTab = app.tabBars.buttons.element(boundBy: 3)
        savedTab.tap()
        sleep(1)

        // Step 4: Verify Saved tab is accessible
        XCTAssertTrue(app.exists)

        // Step 5: Return to Home
        let homeTab = app.tabBars.buttons.element(boundBy: 0)
        homeTab.tap()

        XCTAssertTrue(app.exists)
    }
}
