package com.cookstemma.app.data.repository

import com.cookstemma.app.data.api.ApiService
import com.cookstemma.app.data.api.BlockedUser
import com.cookstemma.app.data.api.MyProfileResponse
import com.cookstemma.app.data.api.PagedResponse
import com.cookstemma.app.data.api.UserProfileResponse
import com.cookstemma.app.domain.model.*
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.flow
import okhttp3.MultipartBody
import javax.inject.Inject
import javax.inject.Singleton

@Singleton
class UserRepository @Inject constructor(
    private val apiService: ApiService
) {
    fun getMyProfile(): Flow<Result<MyProfile>> = flow {
        emit(Result.Loading)
        try {
            val response = apiService.getMyProfile()
            emit(Result.Success(response.toDomain()))
        } catch (e: Exception) {
            emit(Result.Error(e))
        }
    }

    fun getUserProfile(id: String): Flow<Result<UserProfile>> = flow {
        emit(Result.Loading)
        try {
            val response = apiService.getUserProfile(id)
            emit(Result.Success(response.toDomain()))
        } catch (e: Exception) {
            emit(Result.Error(e))
        }
    }

    fun getUserRecipes(userId: String, cursor: String?): Flow<Result<PaginatedResponse<RecipeSummary>>> = flow {
        emit(Result.Loading)
        try {
            emit(Result.Success(apiService.getUserRecipes(userId, cursor)))
        } catch (e: Exception) {
            emit(Result.Error(e))
        }
    }

    fun getUserLogs(userId: String, cursor: String?): Flow<Result<PaginatedResponse<CookingLogSummary>>> = flow {
        emit(Result.Loading)
        try {
            emit(Result.Success(apiService.getUserLogs(userId, cursor)))
        } catch (e: Exception) {
            emit(Result.Error(e))
        }
    }

    suspend fun followUser(userId: String): Result<Unit> = try {
        apiService.followUser(userId)
        Result.Success(Unit)
    } catch (e: Exception) {
        Result.Error(e)
    }

    suspend fun unfollowUser(userId: String): Result<Unit> = try {
        apiService.unfollowUser(userId)
        Result.Success(Unit)
    } catch (e: Exception) {
        Result.Error(e)
    }

    fun getFollowers(userId: String, cursor: String?): Flow<Result<PaginatedResponse<UserSummary>>> = flow {
        emit(Result.Loading)
        try {
            emit(Result.Success(apiService.getFollowers(userId, cursor)))
        } catch (e: Exception) {
            emit(Result.Error(e))
        }
    }

    fun getFollowing(userId: String, cursor: String?): Flow<Result<PaginatedResponse<UserSummary>>> = flow {
        emit(Result.Loading)
        try {
            emit(Result.Success(apiService.getFollowing(userId, cursor)))
        } catch (e: Exception) {
            emit(Result.Error(e))
        }
    }

    suspend fun blockUser(userId: String): Result<Unit> = try {
        apiService.blockUser(userId)
        Result.Success(Unit)
    } catch (e: Exception) {
        Result.Error(e)
    }

    suspend fun unblockUser(userId: String): Result<Unit> = try {
        apiService.unblockUser(userId)
        Result.Success(Unit)
    } catch (e: Exception) {
        Result.Error(e)
    }

    suspend fun updateProfile(
        avatar: MultipartBody.Part? = null,
        username: String? = null,
        bio: String? = null,
        youtubeUrl: String? = null,
        instagramHandle: String? = null
    ): Result<MyProfile> = try {
        val response = apiService.updateProfile(
            avatar = avatar,
            username = username,
            bio = bio,
            youtubeUrl = youtubeUrl,
            instagramHandle = instagramHandle
        )
        Result.Success(response.toDomain())
    } catch (e: Exception) {
        Result.Error(e)
    }

    suspend fun checkUsernameAvailability(username: String): Result<Boolean> = try {
        val response = apiService.checkUsernameAvailability(username)
        Result.Success(response.available)
    } catch (e: Exception) {
        Result.Error(e)
    }

    suspend fun getBlockedUsers(page: Int = 0): Result<PagedResponse<BlockedUser>> = try {
        Result.Success(apiService.getBlockedUsers(page))
    } catch (e: Exception) {
        Result.Error(e)
    }

    suspend fun reportUser(userId: String, reason: String): Result<Unit> = try {
        apiService.reportUser(userId, reason)
        Result.Success(Unit)
    } catch (e: Exception) {
        Result.Error(e)
    }

    suspend fun deleteAccount(): Result<Unit> = try {
        apiService.deleteAccount()
        Result.Success(Unit)
    } catch (e: Exception) {
        Result.Error(e)
    }

    fun getSavedRecipes(cursor: String?): Flow<Result<PaginatedResponse<RecipeSummary>>> = flow {
        emit(Result.Loading)
        try {
            emit(Result.Success(apiService.getSavedRecipes(cursor)))
        } catch (e: Exception) {
            emit(Result.Error(e))
        }
    }

    fun getSavedLogs(cursor: String?): Flow<Result<PaginatedResponse<FeedItem>>> = flow {
        emit(Result.Loading)
        try {
            emit(Result.Success(apiService.getSavedLogs(cursor)))
        } catch (e: Exception) {
            emit(Result.Error(e))
        }
    }
}

// Extension functions to map API responses to domain models
fun MyProfileResponse.toDomain() = MyProfile(
    id = user.id,
    username = user.username,
    displayName = null, // Not returned by API for own profile
    email = null,
    avatarUrl = user.profileImageUrl,
    bio = user.bio,
    level = user.level,
    levelName = user.levelName,
    xp = user.totalXp ?: 0,
    levelProgress = user.levelProgress ?: 0.0,
    recipeCount = recipeCount,
    logCount = logCount,
    followerCount = user.followerCount,
    followingCount = user.followingCount,
    savedCount = savedCount,
    socialLinks = null,
    youtubeUrl = user.youtubeUrl,
    instagramHandle = user.instagramHandle,
    createdAt = null
)

private fun UserProfileResponse.toDomain() = UserProfile(
    id = id,
    username = username,
    displayName = displayName,
    avatarUrl = avatarUrl,
    bio = bio,
    level = level,
    levelName = levelName,
    recipeCount = recipeCount,
    logCount = logCount,
    followerCount = followerCount,
    followingCount = followingCount,
    socialLinks = null,
    youtubeUrl = youtubeUrl,
    instagramHandle = instagramHandle,
    isFollowing = isFollowing,
    isFollowedBy = isFollowedBy,
    isBlocked = isBlocked,
    createdAt = null
)
