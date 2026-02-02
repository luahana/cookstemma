import Foundation
import Combine

enum LogDetailState: Equatable { case idle, loading, loaded, error(String) }

@MainActor
final class LogDetailViewModel: ObservableObject {
    @Published private(set) var state: LogDetailState = .idle
    @Published private(set) var log: CookingLogDetail?
    @Published private(set) var isSaved = false

    private let logId: String
    private let logRepository: CookingLogRepositoryProtocol
    private let userRepository: UserRepositoryProtocol
    private var cancellables = Set<AnyCancellable>()

    init(
        logId: String,
        logRepository: CookingLogRepositoryProtocol = CookingLogRepository(),
        userRepository: UserRepositoryProtocol = UserRepository()
    ) {
        self.logId = logId
        self.logRepository = logRepository
        self.userRepository = userRepository
        setupSaveStateObserver()
    }

    private func setupSaveStateObserver() {
        // Observe SavedItemsManager for save state changes from other screens
        // Use dropFirst() to skip initial value - we get initial state from API
        SavedItemsManager.shared.$savedLogIds
            .dropFirst()
            .receive(on: DispatchQueue.main)
            .sink { [weak self] savedIds in
                guard let self = self else { return }
                let newSavedState = savedIds.contains(self.logId)
                if self.isSaved != newSavedState {
                    #if DEBUG
                    print("[LogDetail] Save state observer: id=\(self.logId), inSet=\(newSavedState), current=\(self.isSaved)")
                    #endif
                    self.isSaved = newSavedState
                }
            }
            .store(in: &cancellables)
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
        guard let logDetail = log else {
            #if DEBUG
            print("[LogDetail] toggleSave: log is nil, returning early")
            #endif
            return
        }
        let feedLogItem = logDetail.asFeedLogItem
        #if DEBUG
        print("========== [LogDetail] TOGGLE SAVE START ==========")
        print("[LogDetail] logId: \(logId)")
        print("[LogDetail] feedLogItem.id: \(feedLogItem.id)")
        print("[LogDetail] feedLogItem.thumbnailUrl: \(feedLogItem.thumbnailUrl ?? "NIL")")
        print("[LogDetail] logDetail.logImages.count: \(logDetail.logImages.count)")
        if let firstImage = logDetail.logImages.first {
            print("[LogDetail] First image URL: \(firstImage.imageUrl)")
        }
        print("[LogDetail] Calling SavedItemsManager.toggleSaveLog...")
        #endif
        await SavedItemsManager.shared.toggleSaveLog(
            id: logId,
            logItem: feedLogItem
        )
        #if DEBUG
        print("[LogDetail] SavedItemsManager.toggleSaveLog completed")
        print("[LogDetail] Current savedLogIds count: \(SavedItemsManager.shared.savedLogIds.count)")
        print("[LogDetail] Current savedLogs count: \(SavedItemsManager.shared.savedLogs.count)")
        print("========== [LogDetail] TOGGLE SAVE END ==========")
        #endif
    }

    func blockUser() async {
        guard let authorId = log?.author.id else { return }
        let result = await userRepository.blockUser(userId: authorId)
        if case .success = result {
            #if DEBUG
            print("[LogDetail] Blocked user: \(authorId)")
            #endif
        }
    }

    func reportUser(reason: ReportReason) async {
        guard let authorId = log?.author.id else { return }
        let result = await userRepository.reportUser(userId: authorId, reason: reason)
        #if DEBUG
        if case .success = result {
            print("[LogDetail] Reported user \(authorId) for: \(reason.rawValue)")
        }
        #endif
    }

    func deleteLog() async -> Bool {
        let result = await logRepository.deleteLog(id: logId)
        switch result {
        case .success:
            #if DEBUG
            print("[LogDetail] Deleted log: \(logId)")
            #endif
            NotificationCenter.default.post(name: .logDeleted, object: nil, userInfo: ["logId": logId])
            return true
        case .failure(let error):
            #if DEBUG
            print("[LogDetail] Failed to delete log: \(error)")
            #endif
            return false
        }
    }
}

// MARK: - Comments ViewModel
@MainActor
final class CommentsViewModel: ObservableObject {
    @Published private(set) var comments: [Comment] = []
    @Published private(set) var isLoading = false
    @Published private(set) var isPosting = false
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
        Task {
            await reloadComments()
        }
    }

    private func reloadComments() async {
        isLoading = true
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

    func postComment(parentId: String? = nil) async {
        guard !newCommentText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        let content = newCommentText
        newCommentText = ""
        isPosting = true

        #if DEBUG
        print("[Comments] Posting comment - parentId: \(parentId ?? "nil"), content: \(content)")
        #endif

        let result = await commentRepository.createComment(logId: logId, content: content, parentId: parentId)
        isPosting = false
        if case .success(let comment) = result {
            if parentId != nil {
                // Reply - reload comments to show the reply nested under parent
                await reloadComments()
            } else {
                // Top-level comment - insert at top
                comments.insert(comment, at: 0)
            }
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

    func editComment(_ comment: Comment, newContent: String) async -> Bool {
        guard !newContent.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return false }

        let result = await commentRepository.updateComment(id: comment.id, content: newContent)
        switch result {
        case .success(let updatedComment):
            if let index = comments.firstIndex(where: { $0.id == comment.id }) {
                // Preserve replies when updating
                comments[index] = Comment(
                    id: updatedComment.id,
                    content: updatedComment.content,
                    author: updatedComment.author,
                    likeCount: updatedComment.likeCount,
                    isLiked: updatedComment.isLiked,
                    isEdited: true,
                    parentId: updatedComment.parentId,
                    replies: comments[index].replies,
                    replyCount: updatedComment.replyCount,
                    createdAt: updatedComment.createdAt,
                    updatedAt: updatedComment.updatedAt
                )
            }
            #if DEBUG
            print("[Comments] Edited comment \(comment.id)")
            #endif
            return true
        case .failure(let error):
            #if DEBUG
            print("[Comments] Failed to edit comment: \(error)")
            #endif
            return false
        }
    }

    func deleteComment(_ comment: Comment) async -> Bool {
        let result = await commentRepository.deleteComment(id: comment.id)
        switch result {
        case .success:
            comments.removeAll { $0.id == comment.id }
            #if DEBUG
            print("[Comments] Deleted comment \(comment.id)")
            #endif
            return true
        case .failure(let error):
            #if DEBUG
            print("[Comments] Failed to delete comment: \(error)")
            #endif
            return false
        }
    }
}
