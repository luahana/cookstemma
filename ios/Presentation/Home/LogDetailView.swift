import SwiftUI

struct LogDetailView: View {
    let logId: String
    @StateObject private var viewModel: LogDetailViewModel
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
                Menu {
                    ShareLink(item: URL(string: "https://cookstemma.com/logs/\(logId)")!) {
                        Label("Share", systemImage: "square.and.arrow.up")
                    }
                    Button(role: .destructive) { } label: {
                        Label("Report", systemImage: "flag")
                    }
                } label: {
                    Image(systemName: "ellipsis")
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
                Button { Task { await viewModel.toggleSave() } } label: {
                    Image(systemName: viewModel.isSaved ? "bookmark.fill" : "bookmark")
                        .foregroundColor(viewModel.isSaved ? DesignSystem.Colors.primary : DesignSystem.Colors.primaryText)
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
                CommentRow(comment: comment, onLike: { Task { await viewModel.likeComment(comment) } })
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
    }
}

struct CommentRow: View {
    let comment: Comment
    let onLike: () -> Void

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
