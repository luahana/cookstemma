import Foundation

// MARK: - Backend Response Models

/// Backend CommentResponseDto structure
struct CommentResponse: Codable {
    let publicId: String
    let content: String
    let creatorPublicId: String
    let creatorUsername: String
    let creatorProfileImageUrl: String?
    let replyCount: Int
    let likeCount: Int
    let isLikedByCurrentUser: Bool
    let isEdited: Bool
    let isDeleted: Bool?
    let isHidden: Bool?
    let createdAt: Date

    /// Convert to existing Comment model for UI compatibility
    func toComment() -> Comment {
        Comment(
            id: publicId,
            content: content,
            author: UserSummary(
                id: creatorPublicId,
                username: creatorUsername,
                displayName: nil,
                avatarUrl: creatorProfileImageUrl,
                level: 1,
                isFollowing: nil
            ),
            likeCount: likeCount,
            isLiked: isLikedByCurrentUser,
            isEdited: isEdited,
            parentId: nil,
            replies: nil,
            replyCount: replyCount,
            createdAt: createdAt,
            updatedAt: nil
        )
    }
}

/// Backend CommentWithRepliesDto wrapper
struct CommentWithReplies: Codable {
    let comment: CommentResponse
    let replies: [CommentResponse]
    let hasMoreReplies: Bool
}

// MARK: - UI Model

struct Comment: Codable, Identifiable, Equatable {
    let id: String
    let content: String
    let author: UserSummary
    let likeCount: Int
    let isLiked: Bool
    let isEdited: Bool
    let parentId: String?
    let replies: [Comment]?
    let replyCount: Int
    let createdAt: Date
    let updatedAt: Date?

    enum CodingKeys: String, CodingKey {
        case id = "publicId"
        case content, author, likeCount, isLiked, isEdited
        case parentId, replies, replyCount, createdAt, updatedAt
    }

    var isReply: Bool { parentId != nil }
    var hasMoreReplies: Bool { (replies?.count ?? 0) < replyCount }
}

struct CommentThread: Identifiable, Equatable {
    let comment: Comment
    var replies: [Comment]
    var isLoadingMoreReplies: Bool = false

    var id: String { comment.id }

    init(comment: Comment) {
        self.comment = comment
        self.replies = comment.replies ?? []
    }
}
