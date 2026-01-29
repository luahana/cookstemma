import Foundation

final class NotificationRepository: NotificationRepositoryProtocol {
    private let apiClient: APIClientProtocol

    init(apiClient: APIClientProtocol = APIClient.shared) {
        self.apiClient = apiClient
    }

    func getNotifications(cursor: String?) async -> RepositoryResult<PaginatedResponse<AppNotification>> {
        do {
            let response: NotificationListResponse = try await apiClient.request(NotificationEndpoint.list(cursor: cursor))
            return .success(PaginatedResponse(
                content: response.notifications,
                nextCursor: nil,
                hasNext: response.hasNext
            ))
        } catch let error as APIError {
            return .failure(mapError(error))
        } catch {
            return .failure(.unknown)
        }
    }

    func getUnreadCount() async -> RepositoryResult<Int> {
        do {
            let response: UnreadCountResponse = try await apiClient.request(NotificationEndpoint.unreadCount)
            return .success(response.unreadCount)
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

    func deleteNotification(id: String) async -> RepositoryResult<Void> {
        do {
            try await apiClient.request(NotificationEndpoint.delete(id: id))
            return .success(())
        } catch let error as APIError {
            return .failure(mapError(error))
        } catch {
            return .failure(.unknown)
        }
    }

    func deleteAllNotifications() async -> RepositoryResult<Void> {
        do {
            #if DEBUG
            print("[NotificationRepository] deleteAllNotifications: calling API")
            #endif
            try await apiClient.request(NotificationEndpoint.deleteAll)
            #if DEBUG
            print("[NotificationRepository] deleteAllNotifications: success")
            #endif
            return .success(())
        } catch let error as APIError {
            #if DEBUG
            print("[NotificationRepository] deleteAllNotifications: API error \(error)")
            #endif
            return .failure(mapError(error))
        } catch {
            #if DEBUG
            print("[NotificationRepository] deleteAllNotifications: unknown error \(error)")
            #endif
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

private struct NotificationListResponse: Codable {
    let notifications: [AppNotification]
    let unreadCount: Int
    let hasNext: Bool
}

private struct UnreadCountResponse: Codable {
    let unreadCount: Int
}
