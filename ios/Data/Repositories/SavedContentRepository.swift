import Foundation

final class SavedContentRepository: SavedContentRepositoryProtocol {
    private let apiClient: APIClientProtocol

    init(apiClient: APIClientProtocol = APIClient.shared) {
        self.apiClient = apiClient
    }

    func getSavedRecipes(cursor: String?) async -> RepositoryResult<PaginatedResponse<RecipeSummary>> {
        do {
            #if DEBUG
            print("[SavedContent] Fetching saved recipes, cursor=\(cursor ?? "nil")")
            #endif
            // Backend returns UnifiedPageResponse format with hasNext
            let response: PaginatedResponse<RecipeSummary> = try await apiClient.request(SavedEndpoint.recipes(cursor: cursor))
            #if DEBUG
            print("[SavedContent] Got \(response.content.count) saved recipes")
            #endif
            return .success(response)
        } catch let error as APIError {
            #if DEBUG
            print("[SavedContent] API error fetching saved recipes: \(error)")
            #endif
            return .failure(mapError(error))
        } catch {
            #if DEBUG
            print("[SavedContent] Unknown error fetching saved recipes: \(error)")
            #endif
            return .failure(.unknown)
        }
    }

    func getSavedLogs(cursor: String?) async -> RepositoryResult<PaginatedResponse<FeedLogItem>> {
        do {
            #if DEBUG
            print("[SavedContent] Fetching saved logs, cursor=\(cursor ?? "nil")")
            #endif
            // Backend returns UnifiedPageResponse format with hasNext
            let response: PaginatedResponse<FeedLogItem> = try await apiClient.request(SavedEndpoint.logs(cursor: cursor))
            #if DEBUG
            print("[SavedContent] Got \(response.content.count) saved logs")
            #endif
            return .success(response)
        } catch let error as APIError {
            #if DEBUG
            print("[SavedContent] API error fetching saved logs: \(error)")
            #endif
            return .failure(mapError(error))
        } catch {
            #if DEBUG
            print("[SavedContent] Unknown error fetching saved logs: \(error)")
            #endif
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
