import SwiftUI

struct LogDetailView: View {
    let logId: String
    @StateObject private var viewModel: LogDetailViewModel
    @EnvironmentObject private var authManager: AuthManager
    @EnvironmentObject private var appState: AppState
    @Environment(\.dismiss) private var dismiss
    @State private var showDeleteConfirmation = false
    @State private var showEditSheet = false
    @State private var showActionSheet = false
    @State private var showCommentsSheet = false

    init(logId: String) {
        self.logId = logId
        self._viewModel = StateObject(wrappedValue: LogDetailViewModel(logId: logId))
    }

    var body: some View {
        VStack(spacing: 0) {
            // Custom header
            HStack {
                Button {
                    dismiss()
                } label: {
                    Image(systemName: "chevron.backward")
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundColor(DesignSystem.Colors.primary)
                        .frame(width: 44, alignment: .leading)
                }
                .buttonStyle(.borderless)
                .padding(.leading, DesignSystem.Spacing.md)

                Spacer()

                HStack(spacing: 0) {
                    // Save button (icon only) - requires auth
                    Button {
                        appState.requireAuth {
                            Task { await viewModel.toggleSave() }
                        }
                    } label: {
                        Image(systemName: viewModel.isSaved ? AppIcon.save : AppIcon.saveOutline)
                            .font(.system(size: 18))
                            .foregroundColor(viewModel.isSaved ? DesignSystem.Colors.bookmark : DesignSystem.Colors.secondaryText)
                            .frame(width: 44, height: 44)
                            .contentShape(Rectangle())
                    }

                    // Share button (icon only)
                    ShareLink(item: URL(string: "https://cookstemma.com/logs/\(logId)")!) {
                        Image(systemName: AppIcon.share)
                            .font(.system(size: 18))
                            .foregroundColor(DesignSystem.Colors.text)
                            .frame(width: 44, height: 44)
                            .contentShape(Rectangle())
                    }

                    // More options menu
                    if let log = viewModel.log {
                        if log.author.id == authManager.currentUser?.id {
                            // Own log - show edit/delete action sheet
                            Button {
                                showActionSheet = true
                            } label: {
                                Image(systemName: "ellipsis")
                                    .font(.system(size: 18, weight: .medium))
                                    .foregroundColor(DesignSystem.Colors.text)
                                    .frame(width: 44, height: 44)
                                    .contentShape(Rectangle())
                            }
                            .confirmationDialog("", isPresented: $showActionSheet, titleVisibility: .hidden) {
                                Button(String(localized: "common.edit")) {
                                    showEditSheet = true
                                }
                                Button(String(localized: "common.delete"), role: .destructive) {
                                    showDeleteConfirmation = true
                                }
                                Button(String(localized: "common.cancel"), role: .cancel) { }
                            }
                        } else {
                            // Other user's log - show block/report
                            BlockReportMenu(
                                targetUserId: log.author.id,
                                targetUsername: log.author.username,
                                onBlock: { Task { await viewModel.blockUser() } },
                                onReport: { reason in Task { await viewModel.reportUser(reason: reason) } }
                            )
                        }
                    }
                }
                .padding(.trailing, DesignSystem.Spacing.xs)
            }
            .padding(.vertical, DesignSystem.Spacing.sm)
            .background(DesignSystem.Colors.background)

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
            .contentMargins(.bottom, 80, for: .scrollContent)
        }
        .toolbar(.hidden, for: .navigationBar)
        .enableSwipeBack()
        .navigationDestination(for: ProfileNavDestination.self) { destination in
            switch destination {
            case .settings:
                SettingsView()
            case .followers(let userId):
                FollowersListView(userId: userId, initialTab: .followers)
            case .following(let userId):
                FollowersListView(userId: userId, initialTab: .following)
            case .recipe(let id):
                RecipeDetailView(recipeId: id)
            case .log(let id):
                LogDetailView(logId: id)
            }
        }
        .onAppear { if case .idle = viewModel.state { viewModel.loadLog() } }
        .alert(String(localized: "menu.deleteCookingLog"), isPresented: $showDeleteConfirmation) {
            Button(String(localized: "common.cancel"), role: .cancel) { }
            Button(String(localized: "common.delete"), role: .destructive) {
                Task {
                    if await viewModel.deleteLog() {
                        dismiss()
                    }
                }
            }
        } message: {
            Text(String(localized: "menu.deleteCookingLogConfirm"))
        }
        .sheet(isPresented: $showEditSheet) {
            if let log = viewModel.log {
                EditLogView(log: log) {
                    viewModel.loadLog()
                }
            }
        }
        .sheet(isPresented: $showCommentsSheet) {
            CommentsBottomSheet(logId: logId)
                .presentationDetents([.medium, .large])
                .presentationDragIndicator(.visible)
        }
    }

    @ViewBuilder
    private func logContent(_ log: CookingLogDetail) -> some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.md) {
            // Author header
            HStack {
                NavigationLink(destination: ProfileView(userId: log.author.id)) {
                    HStack {
                        AvatarView(url: log.author.avatarUrl, name: log.author.username, size: DesignSystem.AvatarSize.sm)
                        VStack(alignment: .leading) {
                            Text(log.author.displayNameOrUsername).font(DesignSystem.Typography.subheadline).fontWeight(.medium)
                            Text(log.createdAt.timeAgo()).font(DesignSystem.Typography.caption).foregroundColor(DesignSystem.Colors.secondaryText)
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
                            img.resizable()
                                .scaledToFill()
                                .frame(maxWidth: .infinity)
                                .clipped()
                        } placeholder: {
                            Rectangle().fill(DesignSystem.Colors.secondaryBackground)
                        }
                    }
                }
                .tabViewStyle(.page)
                .frame(height: 300)
                .clipped()
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
                        NavigationLink(destination: HashtagView(hashtag: hashtag)) {
                            Text("#\(hashtag)")
                                .font(DesignSystem.Typography.subheadline)
                                .foregroundColor(DesignSystem.Colors.primary)
                        }
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

            Divider()

            // Comments button
            Button {
                showCommentsSheet = true
            } label: {
                HStack(spacing: DesignSystem.Spacing.xs) {
                    Image(systemName: AppIcon.comment)
                        .font(.system(size: DesignSystem.IconSize.md))
                    Text("\(log.commentCount)")
                        .font(DesignSystem.Typography.headline)
                }
                .foregroundColor(DesignSystem.Colors.text)
                .padding(.horizontal)
                .padding(.vertical, DesignSystem.Spacing.sm)
            }
        }
        .responsiveFrame()
        .frame(maxWidth: .infinity)
        .padding(.bottom, DesignSystem.Spacing.xl)
    }
}

#Preview { NavigationStack { LogDetailView(logId: "preview") } }
