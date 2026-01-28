import SwiftUI

struct CommentsBottomSheet: View {
    let logId: String
    @StateObject private var viewModel: CommentsViewModel
    @EnvironmentObject private var authManager: AuthManager
    @EnvironmentObject private var appState: AppState
    @Environment(\.dismiss) private var dismiss
    @State private var showBlockConfirmation = false
    @State private var userToBlock: UserSummary?
    @State private var replyingToComment: Comment?
    @State private var editingComment: Comment?
    @State private var showDeleteConfirmation = false
    @State private var commentToDelete: Comment?
    @FocusState private var isCommentInputFocused: Bool

    init(logId: String) {
        self.logId = logId
        self._viewModel = StateObject(wrappedValue: CommentsViewModel(logId: logId))
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Comment list
                ScrollViewReader { proxy in
                    ScrollView {
                        LazyVStack(alignment: .leading, spacing: DesignSystem.Spacing.sm) {
                            ForEach(viewModel.comments) { comment in
                                commentRow(for: comment)
                            }

                            if viewModel.hasMore {
                                Button(String(localized: "comments.loadMore")) {
                                    viewModel.loadMore()
                                }
                                .font(DesignSystem.Typography.subheadline)
                                .padding(.horizontal)
                            }

                            if viewModel.comments.isEmpty && !viewModel.isLoading {
                                emptyState
                            }
                        }
                        .padding(.vertical, DesignSystem.Spacing.sm)
                    }
                    .scrollDismissesKeyboard(.immediately)
                }

                Divider()

                // Reply/Edit indicator + Comment input
                VStack(spacing: 0) {
                    if replyingToComment != nil || editingComment != nil {
                        HStack {
                            if let replyingTo = replyingToComment {
                                Text("comments.replyingTo \(replyingTo.author.username)")
                                    .font(DesignSystem.Typography.caption)
                                    .foregroundColor(DesignSystem.Colors.secondaryText)
                            } else if editingComment != nil {
                                Text(String(localized: "comments.editing"))
                                    .font(DesignSystem.Typography.caption)
                                    .foregroundColor(DesignSystem.Colors.primary)
                            }
                            Spacer()
                            Button {
                                replyingToComment = nil
                                editingComment = nil
                                viewModel.newCommentText = ""
                            } label: {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundColor(DesignSystem.Colors.secondaryText)
                            }
                        }
                        .padding(.horizontal)
                        .padding(.top, DesignSystem.Spacing.xs)
                    }

                    HStack {
                        TextField(String(localized: "comments.placeholder"), text: $viewModel.newCommentText)
                            .textFieldStyle(.roundedBorder)
                            .focused($isCommentInputFocused)
                        Button {
                            appState.requireAuth {
                                submitComment()
                            }
                        } label: {
                            Image(systemName: "arrow.up.circle.fill")
                                .font(.title2)
                                .foregroundColor(viewModel.newCommentText.isEmpty ? DesignSystem.Colors.secondaryText : DesignSystem.Colors.primary)
                        }
                        .disabled(viewModel.newCommentText.isEmpty)
                    }
                    .padding(.horizontal)
                    .padding(.vertical, DesignSystem.Spacing.sm)
                }
                .background(DesignSystem.Colors.background)
            }
            .navigationTitle(String(localized: "comments.title"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(DesignSystem.Colors.secondaryText)
                    }
                }
            }
        }
        .onAppear { viewModel.loadComments() }
        .onChange(of: isCommentInputFocused) { _, focused in
            if !focused && viewModel.newCommentText.isEmpty {
                replyingToComment = nil
                editingComment = nil
            }
        }
        .alert(String(localized: "menu.blockUser"), isPresented: $showBlockConfirmation) {
            Button(String(localized: "menu.block"), role: .destructive) {
                guard let user = userToBlock else { return }
                Task { await viewModel.blockUser(user.id) }
            }
            Button(String(localized: "common.cancel"), role: .cancel) { userToBlock = nil }
        } message: {
            if let user = userToBlock {
                Text(String(localized: "menu.blockConfirmMessage \(user.username)"))
            }
        }
        .alert(String(localized: "comments.deleteComment"), isPresented: $showDeleteConfirmation) {
            Button(String(localized: "common.delete"), role: .destructive) {
                guard let comment = commentToDelete else { return }
                Task { await viewModel.deleteComment(comment) }
                commentToDelete = nil
            }
            Button(String(localized: "common.cancel"), role: .cancel) { commentToDelete = nil }
        } message: {
            Text(String(localized: "comments.deleteConfirm"))
        }
    }

    // MARK: - Empty State

    private var emptyState: some View {
        VStack(spacing: DesignSystem.Spacing.sm) {
            Image(systemName: AppIcon.commentOutline)
                .font(.system(size: 40))
                .foregroundColor(DesignSystem.Colors.secondaryText)
            Text(String(localized: "comments.empty"))
                .font(DesignSystem.Typography.body)
                .foregroundColor(DesignSystem.Colors.secondaryText)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, DesignSystem.Spacing.xxl)
    }

    // MARK: - Comment Row

    @ViewBuilder
    private func commentRow(for comment: Comment) -> some View {
        let isOwn = comment.author.id == authManager.currentUser?.id
        let currentUser = authManager.currentUser?.id

        CommentRow(
            comment: comment,
            isOwnComment: isOwn,
            currentUserId: currentUser,
            onLike: { likeComment(comment) },
            onReply: { replyToComment(comment) },
            onEdit: { startEditingComment(comment) },
            onDelete: { prepareDeleteComment(comment) },
            onBlock: { blockUser(comment.author) },
            onReport: { reason in reportUser(comment.author.id, reason: reason) },
            onEditReply: { reply in startEditingComment(reply) },
            onDeleteReply: { reply in prepareDeleteComment(reply) },
            onBlockReplyAuthor: { reply in blockUser(reply.author) },
            onReportReplyAuthor: { reply, reason in reportUser(reply.author.id, reason: reason) }
        )
    }

    // MARK: - Actions

    private func submitComment() {
        if let comment = editingComment {
            let text = viewModel.newCommentText
            editingComment = nil
            viewModel.newCommentText = ""
            Task { await viewModel.editComment(comment, newContent: text) }
        } else {
            let parentId = replyingToComment?.id
            replyingToComment = nil
            Task { await viewModel.postComment(parentId: parentId) }
        }
    }

    private func likeComment(_ comment: Comment) {
        appState.requireAuth {
            Task { await viewModel.likeComment(comment) }
        }
    }

    private func replyToComment(_ comment: Comment) {
        appState.requireAuth {
            editingComment = nil
            replyingToComment = comment
            viewModel.newCommentText = "@\(comment.author.username) "
            isCommentInputFocused = true
        }
    }

    private func startEditingComment(_ comment: Comment) {
        replyingToComment = nil
        editingComment = comment
        viewModel.newCommentText = comment.content
        isCommentInputFocused = true
    }

    private func prepareDeleteComment(_ comment: Comment) {
        commentToDelete = comment
        showDeleteConfirmation = true
    }

    private func blockUser(_ user: UserSummary) {
        userToBlock = user
        showBlockConfirmation = true
    }

    private func reportUser(_ userId: String, reason: ReportReason) {
        Task { await viewModel.reportUser(userId, reason: reason) }
    }
}

// MARK: - Comment Row

struct CommentRow: View {
    let comment: Comment
    let isOwnComment: Bool
    let currentUserId: String?
    let onLike: () -> Void
    let onReply: () -> Void
    let onEdit: () -> Void
    let onDelete: () -> Void
    let onBlock: () -> Void
    let onReport: (ReportReason) -> Void
    let onEditReply: (Comment) -> Void
    let onDeleteReply: (Comment) -> Void
    let onBlockReplyAuthor: (Comment) -> Void
    let onReportReplyAuthor: (Comment, ReportReason) -> Void

    @State private var showActionSheet = false

    var body: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.xs) {
            HStack(alignment: .top) {
                NavigationLink(destination: ProfileView(userId: comment.author.id)) {
                    AvatarView(url: comment.author.avatarUrl, size: DesignSystem.AvatarSize.xs)
                }
                VStack(alignment: .leading, spacing: 2) {
                    HStack {
                        NavigationLink(destination: ProfileView(userId: comment.author.id)) {
                            Text(comment.author.displayNameOrUsername)
                                .font(DesignSystem.Typography.caption)
                                .fontWeight(.medium)
                                .foregroundColor(DesignSystem.Colors.text)
                        }
                        Text(comment.createdAt.timeAgo())
                            .font(DesignSystem.Typography.caption)
                            .foregroundColor(DesignSystem.Colors.secondaryText)
                        if comment.isEdited {
                            Text(String(localized: "comments.edited"))
                                .font(DesignSystem.Typography.caption)
                                .foregroundColor(DesignSystem.Colors.secondaryText)
                        }
                    }
                    Text(comment.content).font(DesignSystem.Typography.body)
                    HStack {
                        Button { onLike() } label: {
                            HStack(spacing: 2) {
                                Image(systemName: comment.isLiked ? "heart.fill" : "heart")
                                    .font(.caption)
                                Text("\(comment.likeCount)")
                                    .font(DesignSystem.Typography.caption)
                            }
                            .foregroundColor(comment.isLiked ? .red : DesignSystem.Colors.secondaryText)
                        }
                        Button(String(localized: "comments.reply")) { onReply() }
                            .font(DesignSystem.Typography.caption)
                            .foregroundColor(DesignSystem.Colors.secondaryText)
                    }
                }
                Spacer()
                if isOwnComment {
                    Button { showActionSheet = true } label: {
                        Image(systemName: "ellipsis")
                            .font(.caption)
                            .foregroundColor(DesignSystem.Colors.secondaryText)
                            .frame(width: 24, height: 24)
                            .contentShape(Rectangle())
                    }
                    .confirmationDialog("", isPresented: $showActionSheet, titleVisibility: .hidden) {
                        Button(String(localized: "common.edit")) { onEdit() }
                        Button(String(localized: "common.delete"), role: .destructive) { onDelete() }
                        Button(String(localized: "common.cancel"), role: .cancel) { }
                    }
                } else {
                    BlockReportMenu(
                        targetUserId: comment.author.id,
                        targetUsername: comment.author.username,
                        onBlock: onBlock,
                        onReport: onReport
                    )
                    .font(.caption)
                }
            }
            .padding(.horizontal)

            // Replies
            if let replies = comment.replies, !replies.isEmpty {
                ForEach(replies) { reply in
                    ReplyRow(
                        reply: reply,
                        isOwnReply: reply.author.id == currentUserId,
                        onEdit: { onEditReply(reply) },
                        onDelete: { onDeleteReply(reply) },
                        onBlock: { onBlockReplyAuthor(reply) },
                        onReport: { reason in onReportReplyAuthor(reply, reason) }
                    )
                }
            }
        }
    }
}

// MARK: - Reply Row

struct ReplyRow: View {
    let reply: Comment
    let isOwnReply: Bool
    let onEdit: () -> Void
    let onDelete: () -> Void
    let onBlock: () -> Void
    let onReport: (ReportReason) -> Void

    @State private var showActionSheet = false

    var body: some View {
        HStack(alignment: .top) {
            NavigationLink(destination: ProfileView(userId: reply.author.id)) {
                AvatarView(url: reply.author.avatarUrl, size: DesignSystem.AvatarSize.xs)
            }
            VStack(alignment: .leading, spacing: 2) {
                HStack {
                    NavigationLink(destination: ProfileView(userId: reply.author.id)) {
                        Text(reply.author.displayNameOrUsername)
                            .font(DesignSystem.Typography.caption)
                            .fontWeight(.medium)
                            .foregroundColor(DesignSystem.Colors.text)
                    }
                    Text(reply.createdAt.timeAgo())
                        .font(DesignSystem.Typography.caption)
                        .foregroundColor(DesignSystem.Colors.secondaryText)
                    if reply.isEdited {
                        Text(String(localized: "comments.edited"))
                            .font(DesignSystem.Typography.caption)
                            .foregroundColor(DesignSystem.Colors.secondaryText)
                    }
                }
                Text(reply.content)
                    .font(DesignSystem.Typography.body)
            }
            Spacer()
            if isOwnReply {
                Button { showActionSheet = true } label: {
                    Image(systemName: "ellipsis")
                        .font(.caption)
                        .foregroundColor(DesignSystem.Colors.secondaryText)
                        .frame(width: 24, height: 24)
                        .contentShape(Rectangle())
                }
                .confirmationDialog("", isPresented: $showActionSheet, titleVisibility: .hidden) {
                    Button(String(localized: "common.edit")) { onEdit() }
                    Button(String(localized: "common.delete"), role: .destructive) { onDelete() }
                    Button(String(localized: "common.cancel"), role: .cancel) { }
                }
            } else {
                BlockReportMenu(
                    targetUserId: reply.author.id,
                    targetUsername: reply.author.username,
                    onBlock: onBlock,
                    onReport: onReport
                )
                .font(.caption)
            }
        }
        .padding(.leading, 40)
        .padding(.horizontal)
    }
}

#Preview {
    CommentsBottomSheet(logId: "preview")
        .environmentObject(AuthManager())
        .environmentObject(AppState())
}
