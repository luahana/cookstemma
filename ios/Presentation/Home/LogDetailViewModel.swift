import Foundation

enum LogDetailState: Equatable { case idle, loading, loaded, error(String) }

@MainActor
final class LogDetailViewModel: ObservableObject {
    @Published private(set) var state: LogDetailState = .idle
    @Published private(set) var log: CookingLogDetail?
    @Published private(set) var isSaved = false

    private let logId: String
    private let logRepository: CookingLogRepositoryProtocol

    init(logId: String, logRepository: CookingLogRepositoryProtocol = CookingLogRepository()) {
        self.logId = logId
        self.logRepository = logRepository
    }

    func loadLog() {
        state = .loading
        Task {
            #if DEBUG
            print("[LogDetail] Loading log: \(logId)")
            #endif
            let result = await logRepository.getLog(id: logId)
            switch result {
            case .success(let log):
                #if DEBUG
                print("[LogDetail] Success: rating=\(log.rating)")
                #endif
                self.log = log
                self.isSaved = log.isSaved
                state = .loaded
            case .failure(let error):
                #if DEBUG
                print("[LogDetail] Error: \(error.localizedDescription)")
                #endif
                state = .error(error.localizedDescription)
            }
        }
    }

    func toggleLike() async {
        // Like functionality not available in current API
        // TODO: Implement when API supports likes
    }

    func toggleSave() async {
        guard log != nil else { return }
        let wasSaved = isSaved
        isSaved = !wasSaved

        let result = wasSaved
            ? await logRepository.unsaveLog(id: logId)
            : await logRepository.saveLog(id: logId)

        if case .failure = result {
            isSaved = wasSaved
        }
    }
}

// MARK: - Comments ViewModel
@MainActor
final class CommentsViewModel: ObservableObject {
    @Published private(set) var comments: [Comment] = []
    @Published private(set) var isLoading = false
    @Published private(set) var hasMore = true
    @Published var newCommentText = ""

    private let logId: String
    private let commentRepository: CommentRepositoryProtocol
    private let userRepository: UserRepositoryProtocol
    private var nextCursor: String?

    init(
        logId: String,
        commentRepository: CommentRepositoryProtocol = CommentRepository(),
        userRepository: UserRepositoryProtocol = UserRepository()
    ) {
        self.logId = logId
        self.commentRepository = commentRepository
        self.userRepository = userRepository
    }

    func loadComments() {
        guard !isLoading else { return }
        isLoading = true
        Task {
            #if DEBUG
            print("[Comments] Loading comments for log: \(logId)")
            #endif
            let result = await commentRepository.getComments(logId: logId, cursor: nil)
            isLoading = false
            switch result {
            case .success(let response):
                #if DEBUG
                print("[Comments] Loaded \(response.content.count) comments, hasMore: \(response.hasMore)")
                #endif
                comments = response.content
                nextCursor = response.nextCursor
                hasMore = response.hasMore
            case .failure(let error):
                #if DEBUG
                print("[Comments] Failed to load: \(error)")
                #endif
            }
        }
    }

    func loadMore() {
        guard !isLoading, hasMore else { return }
        isLoading = true
        Task {
            #if DEBUG
            print("[Comments] Loading more comments, cursor: \(nextCursor ?? "nil")")
            #endif
            let result = await commentRepository.getComments(logId: logId, cursor: nextCursor)
            isLoading = false
            switch result {
            case .success(let response):
                #if DEBUG
                print("[Comments] Loaded \(response.content.count) more comments")
                #endif
                comments.append(contentsOf: response.content)
                nextCursor = response.nextCursor
                hasMore = response.hasMore
            case .failure(let error):
                #if DEBUG
                print("[Comments] Failed to load more: \(error)")
                #endif
            }
        }
    }

    func postComment() async {
        guard !newCommentText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        let content = newCommentText
        newCommentText = ""

        let result = await commentRepository.createComment(logId: logId, content: content, parentId: nil)
        if case .success(let comment) = result {
            comments.insert(comment, at: 0)
        }
    }

    func likeComment(_ comment: Comment) async {
        guard let index = comments.firstIndex(where: { $0.id == comment.id }) else { return }
        let wasLiked = comment.isLiked

        // Optimistic update
        comments[index] = Comment(
            id: comment.id, content: comment.content, author: comment.author,
            likeCount: comment.likeCount + (wasLiked ? -1 : 1),
            isLiked: !wasLiked, isEdited: comment.isEdited,
            parentId: comment.parentId, replies: comment.replies,
            replyCount: comment.replyCount, createdAt: comment.createdAt,
            updatedAt: comment.updatedAt
        )

        let result = wasLiked
            ? await commentRepository.unlikeComment(id: comment.id)
            : await commentRepository.likeComment(id: comment.id)

        if case .failure = result {
            comments[index] = comment
        }
    }

    func blockUser(_ userId: String) async {
        let result = await userRepository.blockUser(userId: userId)
        if case .success = result {
            // Remove all comments from blocked user
            comments.removeAll { $0.author.id == userId }
            #if DEBUG
            print("[Comments] Blocked user \(userId), removed their comments")
            #endif
        }
    }

    func reportUser(_ userId: String, reason: ReportReason) async {
        let result = await userRepository.reportUser(userId: userId, reason: reason)
        #if DEBUG
        if case .success = result {
            print("[Comments] Reported user \(userId) for: \(reason.rawValue)")
        } else if case .failure(let error) = result {
            print("[Comments] Failed to report user: \(error)")
        }
        #endif
    }
}
