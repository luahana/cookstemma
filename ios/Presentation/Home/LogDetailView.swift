import SwiftUI

struct LogDetailView: View {
    let logId: String
    @StateObject private var viewModel: LogDetailViewModel
    @EnvironmentObject private var authManager: AuthManager
    @EnvironmentObject private var appState: AppState
    @Environment(\.dismiss) private var dismiss

    init(logId: String) {
        self.logId = logId
        self._viewModel = StateObject(wrappedValue: LogDetailViewModel(logId: logId))
    }

    var body: some View {
        ScrollView {
            switch viewModel.state {
            case .idle, .loading:
                LoadingView()
            case .loaded:
                if let log = viewModel.log {
                    logContent(log)
                }
            case .error(let message):
                ErrorStateView(message: message) { viewModel.loadLog() }
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                HStack(spacing: DesignSystem.Spacing.sm) {
                    // Save button (icon only) - requires auth
                    Button {
                        appState.requireAuth {
                            Task { await viewModel.toggleSave() }
                        }
                    } label: {
                        Image(systemName: viewModel.isSaved ? AppIcon.save : AppIcon.saveOutline)
                            .foregroundColor(viewModel.isSaved ? DesignSystem.Colors.bookmark : DesignSystem.Colors.secondaryText)
                    }

                    // Share button (icon only)
                    ShareLink(item: URL(string: "https://cookstemma.com/logs/\(logId)")!) {
                        Image(systemName: AppIcon.share)
                            .foregroundColor(DesignSystem.Colors.text)
                    }

                    // More options (block/report) - only show for other users' logs
                    if let log = viewModel.log,
                       log.author.id != authManager.currentUser?.id {
                        BlockReportMenu(
                            targetUserId: log.author.id,
                            targetUsername: log.author.username,
                            onBlock: { Task { await viewModel.blockUser() } },
                            onReport: { reason in Task { await viewModel.reportUser(reason: reason) } }
                        )
                    }
                }
            }
        }
        .onAppear { if case .idle = viewModel.state { viewModel.loadLog() } }
    }

    @ViewBuilder
    private func logContent(_ log: CookingLogDetail) -> some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.md) {
            // Author header
            HStack {
                NavigationLink(destination: ProfileView(userId: log.author.id)) {
                    HStack {
                        AvatarView(url: log.author.avatarUrl, size: DesignSystem.AvatarSize.sm)
                        VStack(alignment: .leading) {
                            Text(log.author.displayNameOrUsername).font(DesignSystem.Typography.subheadline).fontWeight(.medium)
                            Text(log.createdAt, style: .relative).font(DesignSystem.Typography.caption).foregroundColor(DesignSystem.Colors.secondaryText)
                        }
                    }
                }
                Spacer()
            }
            .padding(.horizontal)

            // Images
            if !log.images.isEmpty {
                TabView {
                    ForEach(log.images, id: \.url) { image in
                        AsyncImage(url: URL(string: image.url)) { img in
                            img.resizable().scaledToFill()
                        } placeholder: {
                            Rectangle().fill(DesignSystem.Colors.secondaryBackground)
                        }
                    }
                }
                .tabViewStyle(.page)
                .frame(height: 300)
            }

            // Rating
            HStack {
                StarRating(rating: log.rating)
                Spacer()
            }
            .padding(.horizontal)

            // Content
            if let content = log.content, !content.isEmpty {
                Text(content)
                    .font(DesignSystem.Typography.body)
                    .padding(.horizontal)
            }

            // Hashtags
            if !log.hashtags.isEmpty {
                FlowLayout(spacing: DesignSystem.Spacing.xs) {
                    ForEach(log.hashtags, id: \.self) { hashtag in
                        Text("#\(hashtag)")
                            .font(DesignSystem.Typography.subheadline)
                            .foregroundColor(DesignSystem.Colors.primary)
                    }
                }
                .padding(.horizontal)
            }

            // Linked recipe
            if let recipe = log.recipe {
                NavigationLink(destination: RecipeDetailView(recipeId: recipe.id)) {
                    HStack {
                        AsyncImage(url: URL(string: recipe.coverImageUrl ?? "")) { img in
                            img.resizable().scaledToFill()
                        } placeholder: {
                            Rectangle().fill(DesignSystem.Colors.secondaryBackground)
                        }
                        .frame(width: 50, height: 50)
                        .cornerRadius(DesignSystem.CornerRadius.xs)
                        .clipped()

                        VStack(alignment: .leading, spacing: 4) {
                            Text(recipe.title).font(DesignSystem.Typography.subheadline).fontWeight(.medium)
                            HStack(spacing: DesignSystem.Spacing.sm) {
                                Text("by @\(recipe.userName)").font(DesignSystem.Typography.caption).foregroundColor(DesignSystem.Colors.secondaryText)
                                // Cooking style badge
                                if let style = recipe.cookingStyle, !style.isEmpty {
                                    HStack(spacing: 2) {
                                        Text(style.flagEmoji)
                                        Text(style.cookingStyleName)
                                    }
                                    .font(DesignSystem.Typography.caption)
                                    .foregroundColor(DesignSystem.Colors.secondaryText)
                                }
                            }
                        }
                        Spacer()
                        Image(systemName: "chevron.right").foregroundColor(DesignSystem.Colors.secondaryText)
                    }
                    .padding()
                    .background(DesignSystem.Colors.secondaryBackground)
                    .cornerRadius(DesignSystem.CornerRadius.sm)
                }
                .padding(.horizontal)
            }

            // Actions
            HStack(spacing: DesignSystem.Spacing.lg) {
                Button { Task { await viewModel.toggleLike() } } label: {
                    Label("\(log.likeCount)", systemImage: log.isLiked ? "heart.fill" : "heart")
                        .foregroundColor(log.isLiked ? .red : DesignSystem.Colors.primaryText)
                }
                Button { } label: {
                    Label("\(log.commentCount)", systemImage: "bubble.right")
                }
                Spacer()
            }
            .padding(.horizontal)

            Divider()

            // Comments section
            CommentsSection(logId: logId)
        }
        .padding(.bottom, DesignSystem.Spacing.xl)
        .safeAreaPadding(.bottom)
    }
}

// MARK: - Comments Section
struct CommentsSection: View {
    let logId: String
    @StateObject private var viewModel: CommentsViewModel
    @EnvironmentObject private var authManager: AuthManager
    @State private var showBlockConfirmation = false
    @State private var userToBlock: UserSummary?

    init(logId: String) {
        self.logId = logId
        self._viewModel = StateObject(wrappedValue: CommentsViewModel(logId: logId))
    }

    var body: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.sm) {
            Text("Comments (\(viewModel.comments.count))")
                .font(DesignSystem.Typography.headline)
                .padding(.horizontal)

            ForEach(viewModel.comments) { comment in
                CommentRow(
                    comment: comment,
                    isOwnComment: comment.author.id == authManager.currentUser?.id,
                    onLike: { Task { await viewModel.likeComment(comment) } },
                    onBlock: {
                        userToBlock = comment.author
                        showBlockConfirmation = true
                    },
                    onReport: { reason in
                        Task { await viewModel.reportUser(comment.author.id, reason: reason) }
                    }
                )
            }

            if viewModel.hasMore {
                Button("Load more comments...") { viewModel.loadMore() }
                    .font(DesignSystem.Typography.subheadline)
                    .padding(.horizontal)
            }

            // Comment input
            HStack {
                TextField("Write a comment...", text: $viewModel.newCommentText)
                    .textFieldStyle(.roundedBorder)
                Button { Task { await viewModel.postComment() } } label: {
                    Image(systemName: "arrow.up.circle.fill")
                        .font(.title2)
                        .foregroundColor(viewModel.newCommentText.isEmpty ? DesignSystem.Colors.secondaryText : DesignSystem.Colors.primary)
                }
                .disabled(viewModel.newCommentText.isEmpty)
            }
            .padding()
        }
        .onAppear { viewModel.loadComments() }
        .alert("Block User", isPresented: $showBlockConfirmation) {
            Button("Block", role: .destructive) {
                guard let user = userToBlock else { return }
                Task { await viewModel.blockUser(user.id) }
            }
            Button("Cancel", role: .cancel) { userToBlock = nil }
        } message: {
            if let user = userToBlock {
                Text("Are you sure you want to block @\(user.username)? You won't see their content anymore.")
            }
        }
    }
}

struct CommentRow: View {
    let comment: Comment
    let isOwnComment: Bool
    let onLike: () -> Void
    let onBlock: () -> Void
    let onReport: (ReportReason) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.xs) {
            HStack(alignment: .top) {
                AvatarView(url: comment.author.avatarUrl, size: DesignSystem.AvatarSize.xs)
                VStack(alignment: .leading, spacing: 2) {
                    HStack {
                        Text(comment.author.displayNameOrUsername).font(DesignSystem.Typography.caption).fontWeight(.medium)
                        Text(comment.createdAt, style: .relative).font(DesignSystem.Typography.caption).foregroundColor(DesignSystem.Colors.secondaryText)
                    }
                    Text(comment.content).font(DesignSystem.Typography.body)
                    HStack {
                        Button { onLike() } label: {
                            HStack(spacing: 2) {
                                Image(systemName: comment.isLiked ? "heart.fill" : "heart").font(.caption)
                                Text("\(comment.likeCount)").font(DesignSystem.Typography.caption)
                            }
                            .foregroundColor(comment.isLiked ? .red : DesignSystem.Colors.secondaryText)
                        }
                        Button("Reply") { }.font(DesignSystem.Typography.caption).foregroundColor(DesignSystem.Colors.secondaryText)
                    }
                }
                Spacer()
                if !isOwnComment {
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
                    HStack(alignment: .top) {
                        AvatarView(url: reply.author.avatarUrl, size: DesignSystem.AvatarSize.xs)
                        VStack(alignment: .leading, spacing: 2) {
                            HStack {
                                Text(reply.author.displayNameOrUsername).font(DesignSystem.Typography.caption).fontWeight(.medium)
                                Text(reply.createdAt, style: .relative).font(DesignSystem.Typography.caption).foregroundColor(DesignSystem.Colors.secondaryText)
                            }
                            Text(reply.content).font(DesignSystem.Typography.body)
                        }
                    }
                    .padding(.leading, 40)
                    .padding(.horizontal)
                }
            }
        }
    }
}

#Preview { NavigationStack { LogDetailView(logId: "preview") } }
