import Foundation

final class CommentRepository: CommentRepositoryProtocol {
    private let apiClient: APIClientProtocol

    init(apiClient: APIClientProtocol = APIClient.shared) {
        self.apiClient = apiClient
    }

    func getComments(logId: String, cursor: String?) async -> RepositoryResult<PaginatedResponse<Comment>> {
        do {
            return .success(try await apiClient.request(CommentEndpoint.list(logId: logId, cursor: cursor)))
        } catch let error as APIError {
            return .failure(mapError(error))
        } catch {
            return .failure(.unknown)
        }
    }

    func createComment(logId: String, content: String, parentId: String?) async -> RepositoryResult<Comment> {
        do {
            return .success(try await apiClient.request(CommentEndpoint.create(logId: logId, content: content, parentId: parentId)))
        } catch let error as APIError {
            return .failure(mapError(error))
        } catch {
            return .failure(.unknown)
        }
    }

    func updateComment(id: String, content: String) async -> RepositoryResult<Comment> {
        do {
            return .success(try await apiClient.request(CommentEndpoint.update(id: id, content: content)))
        } catch let error as APIError {
            return .failure(mapError(error))
        } catch {
            return .failure(.unknown)
        }
    }

    func deleteComment(id: String) async -> RepositoryResult<Void> {
        do {
            try await apiClient.request(CommentEndpoint.delete(id: id))
            return .success(())
        } catch let error as APIError {
            return .failure(mapError(error))
        } catch {
            return .failure(.unknown)
        }
    }

    func likeComment(id: String) async -> RepositoryResult<Void> {
        do {
            try await apiClient.request(CommentEndpoint.like(id: id))
            return .success(())
        } catch let error as APIError {
            return .failure(mapError(error))
        } catch {
            return .failure(.unknown)
        }
    }

    func unlikeComment(id: String) async -> RepositoryResult<Void> {
        do {
            try await apiClient.request(CommentEndpoint.unlike(id: id))
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
