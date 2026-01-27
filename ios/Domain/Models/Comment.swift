import Foundation

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
