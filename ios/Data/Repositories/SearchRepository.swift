import Foundation

final class SearchRepository: SearchRepositoryProtocol {
    private let apiClient: APIClientProtocol

    init(apiClient: APIClientProtocol = APIClient.shared) {
        self.apiClient = apiClient
    }

    func search(query: String, type: SearchType?, cursor: String?) async -> RepositoryResult<SearchResponse> {
        do {
            return .success(try await apiClient.request(SearchEndpoint.search(query: query, type: type, cursor: cursor)))
        } catch let error as APIError {
            return .failure(mapError(error))
        } catch {
            return .failure(.unknown)
        }
    }

    func searchRecipes(query: String, filters: RecipeFilters?, cursor: String?) async -> RepositoryResult<PaginatedResponse<RecipeSummary>> {
        do {
            return .success(try await apiClient.request(SearchEndpoint.searchRecipes(query: query, filters: filters, cursor: cursor)))
        } catch let error as APIError {
            return .failure(mapError(error))
        } catch {
            return .failure(.unknown)
        }
    }

    func searchLogs(query: String, cursor: String?) async -> RepositoryResult<PaginatedResponse<CookingLogSummary>> {
        do {
            return .success(try await apiClient.request(SearchEndpoint.searchLogs(query: query, cursor: cursor)))
        } catch let error as APIError {
            return .failure(mapError(error))
        } catch {
            return .failure(.unknown)
        }
    }

    func searchUsers(query: String, cursor: String?) async -> RepositoryResult<PaginatedResponse<UserSummary>> {
        do {
            return .success(try await apiClient.request(SearchEndpoint.searchUsers(query: query, cursor: cursor)))
        } catch let error as APIError {
            return .failure(mapError(error))
        } catch {
            return .failure(.unknown)
        }
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

    func getHashtagContent(hashtag: String, type: SearchType?, cursor: String?) async -> RepositoryResult<SearchResponse> {
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
