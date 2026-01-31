package com.cookstemma.app.data.api

import com.cookstemma.app.data.repository.Comment
import com.cookstemma.app.data.repository.HashtagResult
import com.cookstemma.app.data.repository.Notification
import com.cookstemma.app.data.repository.SearchResults
import com.cookstemma.app.domain.model.*
import com.google.gson.annotations.SerializedName
import okhttp3.MultipartBody
import retrofit2.http.*

interface ApiService {
    // Auth
    @POST("auth/social-login")
    suspend fun login(@Body request: LoginRequest): AuthResponse

    @POST("auth/reissue")
    suspend fun refreshToken(@Body request: RefreshTokenRequest): AuthResponse

    @DELETE("auth/logout")
    suspend fun logout()

    // Recipes
    @GET("recipes")
    suspend fun getRecipes(
        @Query("cursor") cursor: String? = null,
        @Query("q") query: String? = null,
        @Query("cookingTimeRange") cookingTimeRange: String? = null,
        @Query("category") category: String? = null,
        @Query("servings") servings: String? = null,
        @Query("sort") sort: String = "trending"
    ): PaginatedResponse<RecipeSummary>

    @GET("recipes/{id}")
    suspend fun getRecipe(@Path("id") id: String): RecipeDetail

    @Headers("Content-Type: application/json")
    @POST("recipes/{id}/save")
    suspend fun saveRecipe(@Path("id") id: String)

    @Headers("Content-Type: application/json")
    @DELETE("recipes/{id}/save")
    suspend fun unsaveRecipe(@Path("id") id: String)

    @GET("log_posts/recipe/{id}")
    suspend fun getRecipeLogs(
        @Path("id") recipeId: String,
        @Query("page") page: Int? = null,
        @Query("size") size: Int = 20
    ): PaginatedResponse<RecipeLogItem>

    // Feed (log_posts endpoint)
    @GET("log_posts")
    suspend fun getFeed(
        @Query("cursor") cursor: String? = null,
        @Query("size") size: Int = 20
    ): PaginatedResponse<FeedItem>

    // Logs (using log_posts endpoint like iOS)
    @GET("log_posts/{id}")
    suspend fun getLog(@Path("id") id: String): CookingLogDetail

    @Multipart
    @POST("log_posts")
    suspend fun createLog(
        @Part photos: List<MultipartBody.Part>,
        @Query("rating") rating: Int,
        @Query("recipeId") recipeId: String?,
        @Query("content") content: String?,
        @Query("hashtags") hashtags: List<String>?,
        @Query("isPrivate") isPrivate: Boolean
    ): CookingLogDetail

    @PUT("log_posts/{id}")
    suspend fun updateLog(
        @Path("id") logId: String,
        @Query("rating") rating: Int?,
        @Query("content") content: String?,
        @Query("hashtags") hashtags: List<String>?,
        @Query("isPrivate") isPrivate: Boolean?
    ): CookingLogDetail

    @DELETE("log_posts/{id}")
    suspend fun deleteLog(@Path("id") id: String)

    @Headers("Content-Type: application/json")
    @POST("log_posts/{id}/like")
    suspend fun likeLog(@Path("id") id: String)

    @Headers("Content-Type: application/json")
    @DELETE("log_posts/{id}/like")
    suspend fun unlikeLog(@Path("id") id: String)

    @Headers("Content-Type: application/json")
    @POST("log_posts/{id}/save")
    suspend fun saveLog(@Path("id") id: String)

    @Headers("Content-Type: application/json")
    @DELETE("log_posts/{id}/save")
    suspend fun unsaveLog(@Path("id") id: String)



    // Home
    @GET("home")
    suspend fun getHome(): HomeResponse

    // Comments (using log_posts endpoint like iOS)
    @GET("log_posts/{logId}/comments")
    suspend fun getLogComments(
        @Path("logId") logId: String,
        @Query("cursor") cursor: String? = null
    ): com.google.gson.JsonObject

    @POST("log_posts/{logId}/comments")
    suspend fun createComment(
        @Path("logId") logId: String,
        @Body request: CommentRequest
    ): Comment

    @POST("comments/{parentCommentId}/replies")
    suspend fun createReply(
        @Path("parentCommentId") parentCommentId: String,
        @Body request: CommentRequest
    ): Comment

    @GET("comments/{commentId}/replies")
    suspend fun getCommentReplies(
        @Path("commentId") commentId: String,
        @Query("cursor") cursor: String? = null
    ): com.google.gson.JsonObject

    @PATCH("comments/{commentId}")
    suspend fun updateComment(
        @Path("commentId") commentId: String,
        @Body request: CommentRequest
    ): Comment

    @DELETE("comments/{commentId}")
    suspend fun deleteComment(@Path("commentId") commentId: String)

    @Headers("Content-Type: application/json")
    @POST("comments/{commentId}/like")
    suspend fun likeComment(@Path("commentId") commentId: String)

    @Headers("Content-Type: application/json")
    @DELETE("comments/{commentId}/like")
    suspend fun unlikeComment(@Path("commentId") commentId: String)

    // Users
    @GET("users/me")
    suspend fun getMyProfile(): MyProfileResponse

    @GET("users/{id}")
    suspend fun getUserProfile(@Path("id") id: String): UserProfileResponse

    @GET("users/{id}/recipes")
    suspend fun getUserRecipes(
        @Path("id") userId: String,
        @Query("cursor") cursor: String? = null
    ): PaginatedResponse<RecipeSummary>

    @GET("users/{id}/logs")
    suspend fun getUserLogs(
        @Path("id") userId: String,
        @Query("cursor") cursor: String? = null
    ): PaginatedResponse<CookingLogSummary>

    @Headers("Content-Type: application/json")
    @POST("users/{id}/follow")
    suspend fun followUser(@Path("id") userId: String)

    @Headers("Content-Type: application/json")
    @DELETE("users/{id}/follow")
    suspend fun unfollowUser(@Path("id") userId: String)

    @GET("users/{id}/followers")
    suspend fun getFollowers(
        @Path("id") userId: String,
        @Query("cursor") cursor: String? = null
    ): PaginatedResponse<UserSummary>

    @GET("users/{id}/following")
    suspend fun getFollowing(
        @Path("id") userId: String,
        @Query("cursor") cursor: String? = null
    ): PaginatedResponse<UserSummary>

    @Headers("Content-Type: application/json")
    @POST("users/{id}/block")
    suspend fun blockUser(@Path("id") userId: String)

    @Headers("Content-Type: application/json")
    @DELETE("users/{id}/block")
    suspend fun unblockUser(@Path("id") userId: String)



    // Saved
    @GET("recipes/saved")
    suspend fun getSavedRecipes(
        @Query("cursor") cursor: String? = null
    ): PaginatedResponse<RecipeSummary>

    @GET("log_posts/saved")
    suspend fun getSavedLogs(
        @Query("cursor") cursor: String? = null
    ): PaginatedResponse<FeedItem>

    // Search
    @GET("search")
    suspend fun search(
        @Query("q") query: String,
        @Query("type") type: String? = null,
        @Query("cursor") cursor: String? = null,
        @Query("size") size: Int = 20
    ): com.cookstemma.app.data.repository.UnifiedSearchResponse



    @GET("hashtags/popular")
    suspend fun getTrendingHashtags(): List<HashtagResult>

    @GET("hashtags/{tag}/content")
    suspend fun getHashtagPosts(
        @Path("tag") hashtag: String,
        @Query("type") type: String? = null,
        @Query("cursor") cursor: String? = null
    ): PaginatedResponse<FeedItem>

    @GET("search/history")
    suspend fun getRecentSearches(): List<String>

    @DELETE("search/history")
    suspend fun clearRecentSearches()

    // View History
    @Headers("Content-Type: application/json")
    @POST("view-history/recipes/{id}")
    suspend fun recordRecipeView(@Path("id") id: String)

    @Headers("Content-Type: application/json")
    @POST("view-history/logs/{id}")
    suspend fun recordLogView(@Path("id") id: String)

    @GET("view-history/recipes")
    suspend fun getRecentRecipes(@Query("limit") limit: Int = 10): List<RecipeSummary>

    @GET("view-history/logs")
    suspend fun getRecentLogs(@Query("limit") limit: Int = 10): List<CookingLogSummary>

    // Notifications
    @GET("notifications")
    suspend fun getNotifications(
        @Query("cursor") cursor: String? = null
    ): PaginatedResponse<Notification>

    @GET("notifications/unread-count")
    suspend fun getUnreadNotificationCount(): UnreadCountResponse

    @Headers("Content-Type: application/json")
    @PATCH("notifications/{id}/read")
    suspend fun markNotificationRead(@Path("id") id: String)

    @Headers("Content-Type: application/json")
    @PATCH("notifications/read-all")
    suspend fun markAllNotificationsRead()

    @Headers("Content-Type: application/json")
    @DELETE("notifications/{id}")
    suspend fun deleteNotification(@Path("id") id: String)

    @Headers("Content-Type: application/json")
    @DELETE("notifications")
    suspend fun deleteAllNotifications()

    @POST("notifications/fcm-token")
    suspend fun registerFcmToken(@Query("token") token: String)

    @DELETE("notifications/fcm-token")
    suspend fun unregisterFcmToken(@Query("token") token: String)

    // Profile Management - without avatar
    @PATCH("users/me")
    suspend fun updateProfile(
        @Body request: UpdateProfileRequest
    ): UserInfoDto

    // Profile Management - with avatar
    @Multipart
    @PATCH("users/me")
    suspend fun updateProfileWithAvatar(
        @Part avatar: MultipartBody.Part,
        @Part("username") username: okhttp3.RequestBody? = null,
        @Part("bio") bio: okhttp3.RequestBody? = null,
        @Part("youtubeUrl") youtubeUrl: okhttp3.RequestBody? = null,
        @Part("instagramHandle") instagramHandle: okhttp3.RequestBody? = null
    ): UserInfoDto

    @GET("users/check-username")
    suspend fun checkUsernameAvailability(@Query("username") username: String): UsernameAvailabilityResponse

    @GET("users/me/blocked")
    suspend fun getBlockedUsers(@Query("page") page: Int = 0): PagedResponse<BlockedUser>

    @POST("users/{id}/report")
    suspend fun reportUser(
        @Path("id") userId: String,
        @Query("reason") reason: String
    )

    @DELETE("users/me")
    suspend fun deleteAccount()
}

data class LoginRequest(val idToken: String, val locale: String)
data class RefreshTokenRequest(val refreshToken: String)
data class CommentRequest(val content: String)
data class AuthResponse(
    val accessToken: String,
    val refreshToken: String,
    val userPublicId: String? = null,
    val username: String? = null,
    val role: String? = null,
    val expiresIn: Long = 3600 // Default 1 hour if not provided
)
data class HomeResponse(
    val recentActivity: List<RecentActivityItem>? = null,
    val recentRecipes: List<HomeRecipeItem>? = null,
    val trendingTrees: List<TrendingTree>? = null
)

data class RecentActivityItem(
    @SerializedName("logPublicId") val id: String,
    val rating: Int,
    val thumbnailUrl: String?,
    val userName: String,
    val recipeTitle: String,
    @SerializedName("recipePublicId") val recipeId: String,
    val foodName: String,
    val createdAt: String,
    val hashtags: List<String>? = null,
    val commentCount: Int = 0
)

data class HomeRecipeItem(
    @SerializedName("publicId") val id: String,
    val foodName: String,
    val title: String,
    val description: String?,
    val cookingStyle: String?,
    val userName: String,
    val thumbnail: String?,
    val variantCount: Int = 0,
    val logCount: Int = 0,
    val servings: Int?,
    val cookingTimeRange: String?,
    val hashtags: List<String>? = null
)

data class TrendingTree(
    @SerializedName("rootRecipeId") val id: String,
    val title: String,
    val foodName: String,
    val cookingStyle: String?,
    val thumbnail: String?,
    val variantCount: Int = 0,
    val logCount: Int = 0,
    val latestChangeSummary: String?,
    val userName: String
)
data class UnreadCountResponse(val count: Int)
data class UsernameAvailabilityResponse(val available: Boolean)

// MyProfile API response (matches backend MyProfileResponseDto)
data class MyProfileResponse(
    val user: UserInfoDto,
    val recipeCount: Int = 0,
    val logCount: Int = 0,
    val savedCount: Int = 0
)

// User info (matches backend UserDto)
data class UserInfoDto(
    val id: String,
    val username: String? = null,
    val role: String? = null,
    val profileImageUrl: String? = null,
    val gender: String? = null,
    val locale: String? = null,
    val defaultCookingStyle: String? = null,
    val measurementPreference: String? = null,
    val followerCount: Int = 0,
    val followingCount: Int = 0,
    val recipeCount: Int = 0,
    val logCount: Int = 0,
    val level: Int = 0,
    val levelName: String? = null,
    val totalXp: Int? = null,
    val xpForCurrentLevel: Int? = null,
    val xpForNextLevel: Int? = null,
    val levelProgress: Double? = null,
    val bio: String? = null,
    val youtubeUrl: String? = null,
    val instagramHandle: String? = null
)

// UserProfile API response (matches backend UserProfileResponseDto)
data class UserProfileResponse(
    val id: String,
    val username: String? = null,
    val displayName: String? = null,
    @SerializedName("profileImageUrl") val avatarUrl: String? = null,
    val bio: String? = null,
    val level: Int = 0,
    val levelName: String? = null,
    val recipeCount: Int = 0,
    val logCount: Int = 0,
    val followerCount: Int = 0,
    val followingCount: Int = 0,
    val youtubeUrl: String? = null,
    val instagramHandle: String? = null,
    val isFollowing: Boolean = false,
    val isFollowedBy: Boolean = false,
    val isBlocked: Boolean = false,
    val createdAt: String? = null
)
data class PagedResponse<T>(
    val content: List<T>,
    val page: Int,
    val totalPages: Int,
    val hasMore: Boolean
)
data class BlockedUser(
    val id: String,
    val username: String,
    val avatarUrl: String?,
    val blockedAt: String
)
data class UpdateProfileRequest(
    val username: String? = null,
    val bio: String? = null,
    val youtubeUrl: String? = null,
    val instagramHandle: String? = null
)
