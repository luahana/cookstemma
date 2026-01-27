import Foundation

final class CookingLogRepository: CookingLogRepositoryProtocol {
    private let apiClient: APIClientProtocol

    init(apiClient: APIClientProtocol = APIClient.shared) {
        self.apiClient = apiClient
    }

    func getHomeFeed() async -> RepositoryResult<HomeFeedResponse> {
        do {
            return .success(try await apiClient.request(LogEndpoint.home))
        } catch let error as APIError {
            return .failure(mapError(error))
        } catch {
            return .failure(.unknown)
        }
    }

    func getFeed(cursor: String?, size: Int) async -> RepositoryResult<PaginatedResponse<FeedLogItem>> {
        do {
            return .success(try await apiClient.request(LogEndpoint.feed(cursor: cursor, size: size)))
        } catch let error as APIError {
            return .failure(mapError(error))
        } catch {
            return .failure(.unknown)
        }
    }

    func getLog(id: String) async -> RepositoryResult<CookingLogDetail> {
        do {
            return .success(try await apiClient.request(LogEndpoint.detail(id: id)))
        } catch let error as APIError {
            return .failure(mapError(error))
        } catch {
            return .failure(.unknown)
        }
    }

    func getUserLogs(userId: String, cursor: String?) async -> RepositoryResult<PaginatedResponse<CookingLogSummary>> {
        do {
            return .success(try await apiClient.request(LogEndpoint.userLogs(userId: userId, cursor: cursor)))
        } catch let error as APIError {
            return .failure(mapError(error))
        } catch {
            return .failure(.unknown)
        }
    }

    func createLog(_ request: CreateLogRequest) async -> RepositoryResult<CookingLogDetail> {
        do {
            return .success(try await apiClient.request(LogEndpoint.create(request)))
        } catch let error as APIError {
            return .failure(mapError(error))
        } catch {
            return .failure(.unknown)
        }
    }

    func updateLog(id: String, _ request: UpdateLogRequest) async -> RepositoryResult<CookingLogDetail> {
        do {
            return .success(try await apiClient.request(LogEndpoint.update(id: id, request)))
        } catch let error as APIError {
            return .failure(mapError(error))
        } catch {
            return .failure(.unknown)
        }
    }

    func deleteLog(id: String) async -> RepositoryResult<Void> {
        do {
            try await apiClient.request(LogEndpoint.delete(id: id))
            return .success(())
        } catch let error as APIError {
            return .failure(mapError(error))
        } catch {
            return .failure(.unknown)
        }
    }

    func likeLog(id: String) async -> RepositoryResult<Void> {
        do {
            try await apiClient.request(LogEndpoint.like(id: id))
            return .success(())
        } catch let error as APIError {
            return .failure(mapError(error))
        } catch {
            return .failure(.unknown)
        }
    }

    func unlikeLog(id: String) async -> RepositoryResult<Void> {
        do {
            try await apiClient.request(LogEndpoint.unlike(id: id))
            return .success(())
        } catch let error as APIError {
            return .failure(mapError(error))
        } catch {
            return .failure(.unknown)
        }
    }

    func saveLog(id: String) async -> RepositoryResult<Void> {
        do {
            try await apiClient.request(LogEndpoint.save(id: id))
            return .success(())
        } catch let error as APIError {
            return .failure(mapError(error))
        } catch {
            return .failure(.unknown)
        }
    }

    func unsaveLog(id: String) async -> RepositoryResult<Void> {
        do {
            try await apiClient.request(LogEndpoint.unsave(id: id))
            return .success(())
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
