import Foundation

final class CommentRepository: CommentRepositoryProtocol {
    private let apiClient: APIClientProtocol

    init(apiClient: APIClientProtocol = APIClient.shared) {
        self.apiClient = apiClient
    }

    func getComments(logId: String, cursor: String?) async -> RepositoryResult<PaginatedResponse<Comment>> {
        do {
            // Backend returns Page<CommentWithRepliesDto> with Spring Page format
            let page: SliceResponse<CommentWithReplies> = try await apiClient.request(
                CommentEndpoint.list(logId: logId, cursor: cursor)
            )
            // Convert wrapped comments to flat Comment array
            let comments = page.content.map { wrapper -> Comment in
                var comment = wrapper.comment.toComment()
                // Attach replies if present
                if !wrapper.replies.isEmpty {
                    comment = Comment(
                        id: comment.id,
                        content: comment.content,
                        author: comment.author,
                        likeCount: comment.likeCount,
                        isLiked: comment.isLiked,
                        isEdited: comment.isEdited,
                        parentId: comment.parentId,
                        replies: wrapper.replies.map { $0.toComment() },
                        replyCount: comment.replyCount,
                        createdAt: comment.createdAt,
                        updatedAt: comment.updatedAt
                    )
                }
                return comment
            }
            return .success(PaginatedResponse(
                content: comments,
                nextCursor: page.nextPage.map { String($0) },
                hasNext: page.hasMore
            ))
        } catch let error as APIError {
            #if DEBUG
            print("[CommentRepository] getComments failed: \(error)")
            #endif
            return .failure(mapError(error))
        } catch {
            #if DEBUG
            print("[CommentRepository] getComments unknown error: \(error)")
            #endif
            return .failure(.unknown)
        }
    }

    func createComment(logId: String, content: String, parentId: String?) async -> RepositoryResult<Comment> {
        do {
            // Backend returns CommentResponseDto
            let response: CommentResponse = try await apiClient.request(
                CommentEndpoint.create(logId: logId, content: content, parentId: parentId)
            )
            return .success(response.toComment())
        } catch let error as APIError {
            #if DEBUG
            print("[CommentRepository] createComment failed: \(error)")
            #endif
            return .failure(mapError(error))
        } catch {
            #if DEBUG
            print("[CommentRepository] createComment unknown error: \(error)")
            #endif
            return .failure(.unknown)
        }
    }

    func updateComment(id: String, content: String) async -> RepositoryResult<Comment> {
        do {
            // Backend returns CommentResponseDto
            let response: CommentResponse = try await apiClient.request(
                CommentEndpoint.update(id: id, content: content)
            )
            return .success(response.toComment())
        } catch let error as APIError {
            #if DEBUG
            print("[CommentRepository] updateComment failed: \(error)")
            #endif
            return .failure(mapError(error))
        } catch {
            #if DEBUG
            print("[CommentRepository] updateComment unknown error: \(error)")
            #endif
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
