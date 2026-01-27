import SwiftUI

struct ProfileView: View {
    var userId: String? = nil
    @StateObject private var viewModel: ProfileViewModel
    @EnvironmentObject private var authManager: AuthManager
    @EnvironmentObject private var appState: AppState

    /// True when viewing own profile (no userId provided)
    private var isViewingOwnProfile: Bool { userId == nil }

    init(userId: String? = nil) {
        self.userId = userId
        self._viewModel = StateObject(wrappedValue: ProfileViewModel(userId: userId))
    }

    var body: some View {
        NavigationStack {
            Group {
                if isViewingOwnProfile && !authManager.isAuthenticated {
                    loginPromptView
                } else {
                    mainContent
                }
            }
            .background(DesignSystem.Colors.secondaryBackground)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                if viewModel.isOwnProfile && authManager.isAuthenticated {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        NavigationLink(destination: SettingsView()) {
                            Image(systemName: AppIcon.settings)
                                .foregroundColor(DesignSystem.Colors.text)
                        }
                    }
                } else if viewModel.profile != nil {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Menu {
                            ShareLink(item: URL(string: "https://cookstemma.com/users/\(userId ?? "")")!) {
                                Label("", systemImage: AppIcon.share)
                            }
                            Button(role: .destructive) {
                                Task { await viewModel.blockUser() }
                            } label: {
                                Label("", systemImage: AppIcon.block)
                            }
                        } label: {
                            Image(systemName: AppIcon.more)
                        }
                    }
                }
            }
            .refreshable { viewModel.loadProfile() }
        }
        .onAppear {
            // Only load profile if authenticated (for own profile) or viewing someone else
            if !isViewingOwnProfile || authManager.isAuthenticated {
                if case .idle = viewModel.state { viewModel.loadProfile() }
            }
        }
    }

    private var loginPromptView: some View {
        VStack(spacing: DesignSystem.Spacing.lg) {
            Spacer()
            Image(systemName: AppIcon.profileOutline)
                .font(.system(size: DesignSystem.IconSize.xxl))
                .foregroundColor(DesignSystem.Colors.tertiaryText)
            Text("Sign in to view your profile")
                .font(DesignSystem.Typography.body)
                .foregroundColor(DesignSystem.Colors.secondaryText)
            Button {
                appState.showLoginSheet = true
            } label: {
                Text("Sign In")
                    .font(DesignSystem.Typography.headline)
                    .foregroundColor(.white)
                    .padding(.horizontal, DesignSystem.Spacing.xl)
                    .padding(.vertical, DesignSystem.Spacing.sm)
                    .background(DesignSystem.Colors.primary)
                    .cornerRadius(DesignSystem.CornerRadius.md)
            }
            Spacer()
        }
    }

    private var mainContent: some View {
        ScrollView {
            switch viewModel.state {
            case .idle, .loading: LoadingView()
            case .loaded: profileContent
            case .error(let msg): ErrorStateView(message: msg) { viewModel.loadProfile() }
            }
        }
    }

    @ViewBuilder
    private var profileContent: some View {
        VStack(spacing: DesignSystem.Spacing.md) {
            // Profile Card
            VStack(spacing: DesignSystem.Spacing.sm) {
                // Avatar
                AvatarView(
                    url: viewModel.isOwnProfile ? viewModel.myProfile?.avatarUrl : viewModel.profile?.avatarUrl,
                    size: DesignSystem.AvatarSize.xl
                )

                // Level badge (Icon-focused)
                if let profile = viewModel.myProfile {
                    HStack(spacing: DesignSystem.Spacing.xs) {
                        Image(systemName: AppIcon.fire)
                            .foregroundColor(DesignSystem.Colors.primary)
                        Text("\(profile.level)")
                            .font(DesignSystem.Typography.headline)
                    }

                    // XP Progress bar
                    ProgressView(value: profile.levelProgress)
                        .progressViewStyle(.linear)
                        .frame(width: 120)
                        .tint(DesignSystem.Colors.primary)
                }

                // Bio (if any)
                if let bio = (viewModel.isOwnProfile ? viewModel.myProfile?.bio : viewModel.profile?.bio), !bio.isEmpty {
                    Text(bio)
                        .font(DesignSystem.Typography.body)
                        .foregroundColor(DesignSystem.Colors.secondaryText)
                        .multilineTextAlignment(.center)
                        .lineLimit(3)
                }

                // Stats Row (Icons with counts)
                HStack(spacing: DesignSystem.Spacing.xl) {
                    // Recipes
                    StatIconItem(
                        icon: AppIcon.recipe,
                        count: viewModel.isOwnProfile ? viewModel.myProfile?.recipeCount ?? 0 : viewModel.profile?.recipeCount ?? 0
                    )

                    // Logs
                    StatIconItem(
                        icon: AppIcon.log,
                        count: viewModel.isOwnProfile ? viewModel.myProfile?.logCount ?? 0 : viewModel.profile?.logCount ?? 0
                    )

                    // Followers
                    NavigationLink(destination: FollowersListView(userId: userId ?? viewModel.myProfile?.id ?? "")) {
                        StatIconItem(
                            icon: AppIcon.followers,
                            count: viewModel.isOwnProfile ? viewModel.myProfile?.followerCount ?? 0 : viewModel.profile?.followerCount ?? 0
                        )
                    }
                }
                .padding(.vertical, DesignSystem.Spacing.sm)

                // Follow Button (for other profiles)
                if !viewModel.isOwnProfile, let profile = viewModel.profile {
                    FollowIconButton(isFollowing: profile.isFollowing) {
                        await viewModel.toggleFollow()
                    }
                }
            }
            .padding(DesignSystem.Spacing.lg)
            .background(DesignSystem.Colors.background)
            .cornerRadius(DesignSystem.CornerRadius.lg)
            .padding(.horizontal, DesignSystem.Spacing.md)

            // Tab Selector (Icons only)
            HStack(spacing: 0) {
                TabIconButton(
                    icon: AppIcon.recipe,
                    isSelected: viewModel.selectedTab == .recipes,
                    action: { viewModel.selectedTab = .recipes }
                )
                TabIconButton(
                    icon: AppIcon.log,
                    isSelected: viewModel.selectedTab == .logs,
                    action: { viewModel.selectedTab = .logs }
                )
            }
            .padding(DesignSystem.Spacing.xs)
            .background(DesignSystem.Colors.background)
            .cornerRadius(DesignSystem.CornerRadius.md)
            .padding(.horizontal, DesignSystem.Spacing.md)
            .onChange(of: viewModel.selectedTab) { _ in viewModel.loadContent() }

            // Content Grid
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: DesignSystem.Spacing.sm) {
                if viewModel.selectedTab == .recipes {
                    ForEach(viewModel.recipes) { recipe in
                        NavigationLink(destination: RecipeDetailView(recipeId: recipe.id)) {
                            GridItemView(imageUrl: recipe.coverImageUrl)
                        }
                    }
                } else {
                    ForEach(viewModel.logs) { log in
                        NavigationLink(destination: LogDetailView(logId: log.id)) {
                            GridItemView(imageUrl: log.images.first?.thumbnailUrl)
                        }
                    }
                }
            }
            .padding(.horizontal, DesignSystem.Spacing.md)

            if viewModel.isLoadingContent {
                ProgressView()
            }
        }
        .padding(.vertical, DesignSystem.Spacing.md)
        .safeAreaPadding(.bottom)
    }
}

// MARK: - Stat Icon Item
struct StatIconItem: View {
    let icon: String
    let count: Int

    var body: some View {
        VStack(spacing: DesignSystem.Spacing.xxs) {
            Image(systemName: icon)
                .font(.system(size: DesignSystem.IconSize.md))
                .foregroundColor(DesignSystem.Colors.secondaryText)
            Text("\(count.abbreviated)")
                .font(DesignSystem.Typography.headline)
                .foregroundColor(DesignSystem.Colors.text)
        }
    }
}

// MARK: - Tab Icon Button
struct TabIconButton: View {
    let icon: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: DesignSystem.Spacing.xxs) {
                Image(systemName: icon)
                    .font(.system(size: DesignSystem.IconSize.lg))
                    .foregroundColor(isSelected ? DesignSystem.Colors.primary : DesignSystem.Colors.tertiaryText)

                // Selection indicator
                Circle()
                    .fill(isSelected ? DesignSystem.Colors.primary : Color.clear)
                    .frame(width: 4, height: 4)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, DesignSystem.Spacing.sm)
        }
    }
}

// MARK: - Grid Item View
struct GridItemView: View {
    let imageUrl: String?

    var body: some View {
        AsyncImage(url: URL(string: imageUrl ?? "")) { img in
            img.resizable().scaledToFill()
        } placeholder: {
            Rectangle().fill(DesignSystem.Colors.tertiaryBackground)
        }
        .frame(height: 120)
        .cornerRadius(DesignSystem.CornerRadius.sm)
        .clipped()
    }
}

#Preview {
    ProfileView()
        .environmentObject(AuthManager.shared)
        .environmentObject(AppState())
}
