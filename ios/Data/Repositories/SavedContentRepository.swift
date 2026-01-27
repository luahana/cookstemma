import Foundation

final class SavedContentRepository: SavedContentRepositoryProtocol {
    private let apiClient: APIClientProtocol

    init(apiClient: APIClientProtocol = APIClient.shared) {
        self.apiClient = apiClient
    }

    func getSavedRecipes(cursor: String?) async -> RepositoryResult<PaginatedResponse<RecipeSummary>> {
        do {
            return .success(try await apiClient.request(SavedEndpoint.recipes(cursor: cursor)))
        } catch let error as APIError {
            return .failure(mapError(error))
        } catch {
            return .failure(.unknown)
        }
    }

    func getSavedLogs(cursor: String?) async -> RepositoryResult<PaginatedResponse<CookingLogSummary>> {
        do {
            return .success(try await apiClient.request(SavedEndpoint.logs(cursor: cursor)))
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
