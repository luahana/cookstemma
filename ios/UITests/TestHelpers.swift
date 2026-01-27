import XCTest

/// Test helper extensions for UI testing
extension XCUIApplication {

    /// Launch the app with UI testing configuration
    func launchForUITesting() {
        launchArguments = ["--uitesting"]
        launchEnvironment["UITEST_DISABLE_ANIMATIONS"] = "1"
        launch()
    }

    /// Wait for an element to exist with timeout
    func waitForElement(_ element: XCUIElement, timeout: TimeInterval = 5) -> Bool {
        return element.waitForExistence(timeout: timeout)
    }
}

extension XCUIElement {

    /// Wait for element and tap
    func waitAndTap(timeout: TimeInterval = 5) -> Bool {
        guard waitForExistence(timeout: timeout) else { return false }
        tap()
        return true
    }

    /// Check if element is visible on screen
    var isVisibleOnScreen: Bool {
        guard exists && !frame.isEmpty else { return false }
        return XCUIApplication().windows.element(boundBy: 0).frame.contains(frame)
    }

    /// Scroll until element is visible
    func scrollToElement(in scrollView: XCUIElement) {
        while !isVisibleOnScreen {
            scrollView.swipeUp()
        }
    }
}

/// Test identifiers for UI elements
/// These should match the accessibilityIdentifier values set in the app
enum TestIdentifiers {
    // Tab Bar
    static let tabHome = "tab_home"
    static let tabRecipes = "tab_recipes"
    static let tabCreate = "tab_create"
    static let tabSaved = "tab_saved"
    static let tabProfile = "tab_profile"

    // Home Feed
    static let homeFeed = "home_feed"
    static let feedItem = "feed_item"
    static let feedUserAvatar = "feed_user_avatar"

    // Recipe
    static let recipeCard = "recipe_card"
    static let recipeDetailScreen = "recipe_detail_screen"
    static let recipesScreen = "recipes_screen"

    // Actions
    static let likeButton = "like_button"
    static let commentButton = "comment_button"
    static let shareButton = "share_button"
    static let saveButton = "save_button"
    static let followButton = "follow_button"

    // Navigation
    static let backButton = "back_button"
    static let closeButton = "close_button"
    static let searchButton = "search_button"
    static let notificationButton = "notification_button"
    static let settingsButton = "settings_button"
    static let moreMenuButton = "more_menu_button"

    // Search
    static let searchScreen = "search_screen"
    static let searchField = "search_field"
    static let searchResults = "search_results"
    static let clearSearchButton = "clear_search_button"
    static let searchTabAll = "search_tab_all"
    static let searchTabRecipes = "search_tab_recipes"
    static let searchTabLogs = "search_tab_logs"
    static let searchTabUsers = "search_tab_users"
    static let searchTabHashtags = "search_tab_hashtags"
    static let recentSearchesSection = "recent_searches_section"
    static let trendingSection = "trending_section"
    static let searchResultItem = "search_result_item"
    static let recentSearchItem = "recent_search_item"

    // Create Log
    static let createLogScreen = "create_log_screen"
    static let photoSection = "photo_section"
    static let addPhotoButton = "add_photo_button"
    static let ratingSection = "rating_section"
    static let recipeLinkSection = "recipe_link_section"
    static let recipeSearchField = "recipe_search_field"
    static let contentField = "content_field"
    static let hashtagSection = "hashtag_section"
    static let postButton = "post_button"

    // Saved
    static let savedScreen = "saved_screen"
    static let savedTabRecipes = "saved_tab_recipes"
    static let savedTabLogs = "saved_tab_logs"
    static let savedRecipesContent = "saved_recipes_content"
    static let savedLogsContent = "saved_logs_content"

    // Profile
    static let profileScreen = "profile_screen"
    static let userProfileScreen = "user_profile_screen"
    static let profileAvatar = "profile_avatar"
    static let profileStats = "profile_stats"
    static let profileTabRecipes = "profile_tab_recipes"
    static let profileTabLogs = "profile_tab_logs"
    static let profileRecipesContent = "profile_recipes_content"
    static let profileLogsContent = "profile_logs_content"
    static let followersCount = "followers_count"
    static let followingCount = "following_count"
    static let followersListScreen = "followers_list_screen"
    static let followingListScreen = "following_list_screen"
    static let profileMenu = "profile_menu"

    // Notifications
    static let notificationsScreen = "notifications_screen"
    static let markAllReadButton = "mark_all_read_button"

    // Comments
    static let commentsScreen = "comments_screen"
    static let commentInput = "comment_input"

    // Rating Stars
    static func star(_ number: Int) -> String { "star_\(number)" }

    // Settings
    static let settingsScreen = "settings_screen"

    // Detail
    static let detailScreen = "detail_screen"
    static let logDetailScreen = "log_detail_screen"
}

/// Test data for UI tests
enum TestData {
    static let testUsername = "testuser"
    static let testEmail = "test@example.com"
    static let testSearchQuery = "kimchi"
    static let testHashtag = "#koreanfood"
    static let testComment = "Looks delicious!"
    static let testLogContent = "Made this tonight, turned out great!"
}
