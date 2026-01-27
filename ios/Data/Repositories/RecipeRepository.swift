import Foundation

final class RecipeRepository: RecipeRepositoryProtocol {
    private let apiClient: APIClientProtocol

    init(apiClient: APIClientProtocol = APIClient.shared) {
        self.apiClient = apiClient
    }

    func getRecipes(cursor: String?, filters: RecipeFilters?) async -> RepositoryResult<PaginatedResponse<RecipeSummary>> {
        do {
            return .success(try await apiClient.request(RecipeEndpoint.list(cursor: cursor, filters: filters)))
        } catch let error as APIError {
            return .failure(mapError(error))
        } catch {
            return .failure(.unknown)
        }
    }

    func getRecipe(id: String) async -> RepositoryResult<RecipeDetail> {
        do {
            return .success(try await apiClient.request(RecipeEndpoint.detail(id: id)))
        } catch let error as APIError {
            return .failure(mapError(error))
        } catch {
            return .failure(.unknown)
        }
    }

    func getRecipeLogs(recipeId: String, cursor: String?) async -> RepositoryResult<PaginatedResponse<RecipeLogItem>> {
        do {
            // Backend returns Spring Slice format, convert to PaginatedResponse
            let slice: SliceResponse<RecipeLogItem> = try await apiClient.request(RecipeEndpoint.logs(recipeId: recipeId, cursor: cursor))
            return .success(slice.toPaginatedResponse())
        } catch let error as APIError {
            #if DEBUG
            print("[RecipeRepository] getRecipeLogs error: \(error)")
            #endif
            return .failure(mapError(error))
        } catch {
            #if DEBUG
            print("[RecipeRepository] getRecipeLogs unknown error: \(error)")
            #endif
            return .failure(.unknown)
        }
    }

    func saveRecipe(id: String) async -> RepositoryResult<Void> {
        do {
            try await apiClient.request(RecipeEndpoint.save(id: id))
            return .success(())
        } catch let error as APIError {
            return .failure(mapError(error))
        } catch {
            return .failure(.unknown)
        }
    }

    func unsaveRecipe(id: String) async -> RepositoryResult<Void> {
        do {
            try await apiClient.request(RecipeEndpoint.unsave(id: id))
            return .success(())
        } catch let error as APIError {
            return .failure(mapError(error))
        } catch {
            return .failure(.unknown)
        }
    }

    func isRecipeSaved(id: String) async -> RepositoryResult<Bool> {
        .success(false)
    }

    func recordRecipeView(id: String) async {
        do {
            try await apiClient.request(ViewHistoryEndpoint.recordRecipeView(id: id))
        } catch {
            // Silently fail - view tracking shouldn't break the app
            print("Failed to record recipe view: \(error)")
        }
    }

    func getRecentlyViewedRecipes(limit: Int) async -> RepositoryResult<[RecipeSummary]> {
        do {
            return .success(try await apiClient.request(ViewHistoryEndpoint.recentRecipes(limit: limit)))
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
