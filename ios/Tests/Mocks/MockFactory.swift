import Foundation
@testable import Cookstemma

/// Factory for creating mock data for tests
enum MockFactory {

    // MARK: - Users

    static func userSummary(
        id: String = "user-1",
        username: String = "testuser",
        displayName: String? = "Test User",
        avatarUrl: String? = nil,
        level: Int = 5,
        isFollowing: Bool? = nil
    ) -> UserSummary {
        UserSummary(
            id: id,
            username: username,
            displayName: displayName,
            avatarUrl: avatarUrl,
            level: level,
            isFollowing: isFollowing
        )
    }

    static func myProfile(
        id: String = "me-1",
        username: String = "myuser",
        level: Int = 5,
        levelProgress: Double = 0.5,
        recipeCount: Int = 10,
        logCount: Int = 25,
        savedCount: Int = 5,
        followerCount: Int = 100,
        followingCount: Int = 50
    ) -> MyProfile {
        let userInfo = UserInfo(
            id: id,
            username: username,
            role: "USER",
            profileImageUrl: nil,
            gender: nil,
            locale: "en",
            defaultCookingStyle: nil,
            measurementPreference: "METRIC",
            followerCount: followerCount,
            followingCount: followingCount,
            recipeCount: recipeCount,
            logCount: logCount,
            level: level,
            levelName: "homeCook",
            totalXp: 500,
            xpForCurrentLevel: 100,
            xpForNextLevel: 200,
            levelProgress: levelProgress,
            bio: nil,
            youtubeUrl: nil,
            instagramHandle: nil
        )
        return MyProfile(
            user: userInfo,
            recipeCount: recipeCount,
            logCount: logCount,
            savedCount: savedCount
        )
    }

    static func userProfile(
        id: String = "user-1",
        username: String = "testuser",
        isFollowing: Bool = false,
        isBlocked: Bool = false
    ) -> UserProfile {
        UserProfile(
            id: id,
            username: username,
            displayName: "Test User",
            avatarUrl: nil,
            bio: "Test bio",
            level: 10,
            levelName: "homeCook",
            recipeCount: 5,
            logCount: 20,
            followerCount: 100,
            followingCount: 50,
            youtubeUrl: nil,
            instagramHandle: nil,
            isFollowing: isFollowing,
            isFollowedBy: false,
            isBlocked: isBlocked,
            createdAt: Date()
        )
    }

    // MARK: - Recipes

    static func recipeSummary(
        id: String = "recipe-1",
        title: String = "Test Recipe",
        cookCount: Int = 10,
        isSaved: Bool = false
    ) -> RecipeSummary {
        RecipeSummary(
            id: id,
            title: title,
            description: "A test recipe description",
            foodName: "Test Food",
            cookingStyle: "US",
            userName: "testuser",
            thumbnail: nil,
            variantCount: 1,
            logCount: cookCount,
            servings: 2,
            cookingTimeRange: "MIN_15_TO_30",
            hashtags: [],
            isPrivate: false,
            isSaved: isSaved
        )
    }

    static func recipeDetail(
        id: String = "recipe-1",
        title: String = "Test Recipe",
        isSaved: Bool = false
    ) -> RecipeDetail {
        RecipeDetail(
            id: id,
            title: title,
            description: "A detailed test recipe",
            coverImageUrl: nil,
            images: [],
            cookingTimeRange: .min30To60,
            servings: 4,
            cookCount: 50,
            saveCount: 25,
            averageRating: 4.2,
            author: userSummary(),
            ingredients: [
                Ingredient(name: "Flour", amount: "2 cups", category: .main),
                Ingredient(name: "Sugar", amount: "1 cup", category: .main),
                Ingredient(name: "Salt", amount: "1 tsp", category: .seasoning)
            ],
            steps: [
                RecipeStep(order: 1, instruction: "Mix dry ingredients", imageUrl: nil, tipContent: nil),
                RecipeStep(order: 2, instruction: "Add wet ingredients", imageUrl: nil, tipContent: "Mix slowly")
            ],
            hashtags: ["baking", "easy"],
            isSaved: isSaved,
            category: nil,
            createdAt: Date(),
            updatedAt: Date()
        )
    }

    // MARK: - Cooking Logs

    static func cookingLogSummary(
        id: String = "log-1",
        rating: Int = 4,
        isLiked: Bool = false,
        isSaved: Bool = false
    ) -> CookingLogSummary {
        CookingLogSummary(
            id: id,
            author: userSummary(),
            images: [LogImage(thumbnailUrl: "https://example.com/thumb.jpg", originalUrl: "https://example.com/original.jpg")],
            rating: rating,
            contentPreview: "This was delicious!",
            recipe: nil,
            likeCount: 10,
            commentCount: 5,
            isLiked: isLiked,
            isSaved: isSaved,
            createdAt: Date()
        )
    }

    static func cookingLogDetail(
        id: String = "log-1",
        rating: Int = 4,
        isLiked: Bool = false,
        isSaved: Bool = false
    ) -> CookingLogDetail {
        CookingLogDetail(
            id: id,
            author: userSummary(),
            images: [LogImage(thumbnailUrl: "https://example.com/thumb.jpg", originalUrl: "https://example.com/original.jpg")],
            rating: rating,
            content: "This was a great recipe! I modified it slightly by adding extra garlic.",
            recipe: recipeSummary(),
            hashtags: ["homecooking", "dinner"],
            isPrivate: false,
            likeCount: 25,
            commentCount: 8,
            isLiked: isLiked,
            isSaved: isSaved,
            createdAt: Date()
        )
    }

    static func feedItem(log: CookingLogSummary? = nil, recipe: RecipeSummary? = nil) -> FeedItem {
        if let log = log {
            return .log(log)
        } else if let recipe = recipe {
            return .recipe(recipe)
        }
        return .log(cookingLogSummary())
    }

    // MARK: - Comments

    static func comment(
        id: String = "comment-1",
        content: String = "Great recipe!",
        isLiked: Bool = false,
        isEdited: Bool = false,
        parentId: String? = nil,
        replyCount: Int = 0,
        replies: [Comment]? = nil
    ) -> Comment {
        Comment(
            id: id,
            content: content,
            author: userSummary(),
            likeCount: 5,
            isLiked: isLiked,
            isEdited: isEdited,
            parentId: parentId,
            replies: replies,
            replyCount: replyCount,
            createdAt: Date(),
            updatedAt: nil
        )
    }

    static func commentResponse(
        publicId: String = "comment-1",
        content: String = "Great recipe!",
        creatorPublicId: String = "user-1",
        creatorUsername: String = "testuser",
        creatorProfileImageUrl: String? = nil,
        replyCount: Int = 0,
        likeCount: Int = 5,
        isLikedByCurrentUser: Bool = false,
        isEdited: Bool = false
    ) -> CommentResponse {
        CommentResponse(
            publicId: publicId,
            content: content,
            creatorPublicId: creatorPublicId,
            creatorUsername: creatorUsername,
            creatorProfileImageUrl: creatorProfileImageUrl,
            replyCount: replyCount,
            likeCount: likeCount,
            isLikedByCurrentUser: isLikedByCurrentUser,
            isEdited: isEdited,
            isDeleted: false,
            isHidden: false,
            createdAt: Date()
        )
    }

    static func commentWithReplies(
        comment: CommentResponse? = nil,
        replies: [CommentResponse] = [],
        hasMoreReplies: Bool = false
    ) -> CommentWithReplies {
        CommentWithReplies(
            comment: comment ?? commentResponse(),
            replies: replies,
            hasMoreReplies: hasMoreReplies
        )
    }

    // MARK: - Notifications

    static func notification(
        id: String = "notif-1",
        type: NotificationType = .newFollower,
        isRead: Bool = false
    ) -> AppNotification {
        AppNotification(
            id: id,
            type: type,
            title: "New follower",
            body: "@testuser started following you",
            actorAvatarUrl: nil,
            thumbnailUrl: nil,
            data: ["userId": "user-1"],
            isRead: isRead,
            createdAt: Date()
        )
    }

    // MARK: - Search

    static func hashtagCount(name: String = "cooking", postCount: Int = 100) -> HashtagCount {
        HashtagCount(name: name, postCount: postCount)
    }

    static func searchResponse(
        recipes: [RecipeSummary] = [],
        logs: [CookingLogSummary] = [],
        users: [UserSummary] = [],
        hashtags: [HashtagCount] = []
    ) -> SearchResponse {
        SearchResponse(recipes: recipes, logs: logs, users: users, hashtags: hashtags)
    }

    // MARK: - Paginated Responses

    static func paginatedResponse<T>(
        content: [T],
        nextCursor: String? = nil,
        hasNext: Bool = false
    ) -> PaginatedResponse<T> {
        PaginatedResponse(content: content, nextCursor: nextCursor, hasNext: hasNext)
    }
}
