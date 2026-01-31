import Foundation

final class SearchRepository: SearchRepositoryProtocol {
    private let apiClient: APIClientProtocol

    init(apiClient: APIClientProtocol = APIClient.shared) {
        self.apiClient = apiClient
    }

    func search(query: String, type: SearchType?, cursor: String?, size: Int = 20) async -> RepositoryResult<UnifiedSearchResponse> {
        do {
            return .success(try await apiClient.request(SearchEndpoint.search(query: query, type: type, cursor: cursor, size: size)))
        } catch let error as APIError {
            return .failure(mapError(error))
        } catch {
            return .failure(.unknown)
        }
    }

    func searchRecipes(query: String, filters: RecipeFilters?, cursor: String?) async -> RepositoryResult<PaginatedResponse<RecipeSummary>> {
        let result = await search(query: query, type: .recipes, cursor: cursor)
        switch result {
        case .success(let response):
            let recipes = response.content.compactMap { item -> RecipeSummary? in
                if case .recipe(let recipe) = item.data {
                    return recipe
                }
                return nil
            }
            return .success(PaginatedResponse(
                content: recipes,
                nextCursor: response.nextCursor,
                hasNext: response.hasNext
            ))
        case .failure(let error):
            return .failure(error)
        }
    }

    func searchLogs(query: String, cursor: String?) async -> RepositoryResult<PaginatedResponse<CookingLogSummary>> {
        let result = await search(query: query, type: .logs, cursor: cursor)
        switch result {
        case .success(let response):
            let logs = response.content.compactMap { item -> CookingLogSummary? in
                if case .log(let log) = item.data {
                    return transformLogToSummary(log)
                }
                return nil
            }
            return .success(PaginatedResponse(
                content: logs,
                nextCursor: response.nextCursor,
                hasNext: response.hasNext
            ))
        case .failure(let error):
            return .failure(error)
        }
    }

    func searchUsers(query: String, cursor: String?) async -> RepositoryResult<PaginatedResponse<UserSummary>> {
        let result = await search(query: query, type: .users, cursor: cursor)
        switch result {
        case .success(let response):
            let users = response.content.compactMap { item -> UserSummary? in
                if case .user(let user) = item.data {
                    return user
                }
                return nil
            }
            return .success(PaginatedResponse(
                content: users,
                nextCursor: response.nextCursor,
                hasNext: response.hasNext
            ))
        case .failure(let error):
            return .failure(error)
        }
    }

    private func transformLogToSummary(_ log: LogPostSummaryResponse) -> CookingLogSummary {
        let recipe: RecipeSummary? = log.recipeTitle.map { title in
            RecipeSummary(
                id: "",
                title: title,
                description: nil,
                foodName: log.foodName ?? "",
                cookingStyle: nil,
                userName: "",
                thumbnail: nil,
                variantCount: 0,
                logCount: 0,
                servings: nil,
                cookingTimeRange: nil,
                hashtags: [],
                isPrivate: false
            )
        }
        return CookingLogSummary(
            id: log.id,
            rating: log.rating ?? 0,
            content: log.content,
            images: log.thumbnailUrl.map { [ImageInfo(id: log.id, url: $0, thumbnailUrl: $0, width: nil, height: nil)] } ?? [],
            author: UserSummary(id: log.creatorPublicId ?? "", username: log.userName, displayName: nil, avatarUrl: nil, level: 0, isFollowing: nil),
            recipe: recipe,
            likeCount: 0,
            commentCount: log.commentCount ?? 0,
            isLiked: false,
            isSaved: false,
            createdAt: Date()
        )
    }

    func getTrendingHashtags() async -> RepositoryResult<[HashtagCount]> {
        do {
            return .success(try await apiClient.request(SearchEndpoint.trending))
        } catch let error as APIError {
            return .failure(mapError(error))
        } catch {
            return .failure(.unknown)
        }
    }

    func getHashtagContent(hashtag: String, type: SearchType?, cursor: String?) async -> RepositoryResult<HashtagContentResponse> {
        do {
            return .success(try await apiClient.request(SearchEndpoint.hashtagContent(hashtag: hashtag, type: type, cursor: cursor)))
        } catch let error as APIError {
            return .failure(mapError(error))
        } catch {
            return .failure(.unknown)
        }
    }

    private func mapError(_ error: APIError) -> RepositoryError {
        switch error {
        case .networkError(let msg): return .networkError(msg)
        case .unauthorized: return .unauthorized
        case .notFound: return .notFound
        case .serverError(_, let msg): return .serverError(msg)
        case .decodingError(let msg): return .decodingError(msg)
        default: return .unknown
        }
    }
}
