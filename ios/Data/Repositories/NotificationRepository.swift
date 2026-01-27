import Foundation

final class NotificationRepository: NotificationRepositoryProtocol {
    private let apiClient: APIClientProtocol

    init(apiClient: APIClientProtocol = APIClient.shared) {
        self.apiClient = apiClient
    }

    func getNotifications(cursor: String?) async -> RepositoryResult<PaginatedResponse<AppNotification>> {
        do {
            return .success(try await apiClient.request(NotificationEndpoint.list(cursor: cursor)))
        } catch let error as APIError {
            return .failure(mapError(error))
        } catch {
            return .failure(.unknown)
        }
    }

    func getUnreadCount() async -> RepositoryResult<Int> {
        do {
            let response: UnreadCountResponse = try await apiClient.request(NotificationEndpoint.unreadCount)
            return .success(response.count)
        } catch let error as APIError {
            return .failure(mapError(error))
        } catch {
            return .failure(.unknown)
        }
    }

    func markAsRead(id: String) async -> RepositoryResult<Void> {
        do {
            try await apiClient.request(NotificationEndpoint.markRead(id: id))
            return .success(())
        } catch let error as APIError {
            return .failure(mapError(error))
        } catch {
            return .failure(.unknown)
        }
    }

    func markAllAsRead() async -> RepositoryResult<Void> {
        do {
            try await apiClient.request(NotificationEndpoint.markAllRead)
            return .success(())
        } catch let error as APIError {
            return .failure(mapError(error))
        } catch {
            return .failure(.unknown)
        }
    }

    func registerFCMToken(_ token: String) async -> RepositoryResult<Void> {
        do {
            try await apiClient.request(NotificationEndpoint.registerFCM(token: token))
            return .success(())
        } catch let error as APIError {
            return .failure(mapError(error))
        } catch {
            return .failure(.unknown)
        }
    }

    func unregisterFCMToken(_ token: String) async -> RepositoryResult<Void> {
        do {
            try await apiClient.request(NotificationEndpoint.unregisterFCM(token: token))
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

private struct UnreadCountResponse: Codable {
    let count: Int
}
