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
            #if DEBUG
            print("[CommentRepository] Received \(page.content.count) comments from API")
            for (index, wrapper) in page.content.enumerated() {
                let c = wrapper.comment
                print("[CommentRepository] Comment \(index): author=\(c.creatorUsername), " +
                      "deleted=\(c.isDeleted ?? false), hidden=\(c.isHidden ?? false)")
            }
            #endif
            // Convert wrapped comments to flat Comment array, filtering out deleted/hidden comments
            let comments = page.content.compactMap { wrapper -> Comment? in
                // Skip comments where content is null (deleted or hidden by moderation)
                // Note: Backend hides content from non-creators when comment is moderated
                guard wrapper.comment.content != nil else { return nil }

                var comment = wrapper.comment.toComment()
                // Attach replies if present, filtering out deleted/hidden ones
                let validReplies = wrapper.replies
                    .filter { $0.content != nil }
                    .map { $0.toComment() }

                if !validReplies.isEmpty {
                    comment = Comment(
                        id: comment.id,
                        content: comment.content,
                        author: comment.author,
                        likeCount: comment.likeCount,
                        isLiked: comment.isLiked,
                        isEdited: comment.isEdited,
                        parentId: comment.parentId,
                        replies: validReplies,
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
            // Backend has separate endpoints for top-level comments and replies:
            // - Top-level: POST /api/v1/log_posts/{logId}/comments
            // - Replies: POST /api/v1/comments/{parentCommentId}/replies
            let endpoint: CommentEndpoint
            if let parentId = parentId {
                endpoint = .reply(parentCommentId: parentId, content: content)
                #if DEBUG
                print("[CommentRepository] Creating reply to comment: \(parentId)")
                #endif
            } else {
                endpoint = .create(logId: logId, content: content)
                #if DEBUG
                print("[CommentRepository] Creating top-level comment on log: \(logId)")
                #endif
            }

            let response: CommentResponse = try await apiClient.request(endpoint)
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
