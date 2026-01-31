import SwiftUI

// MARK: - Navigation Destinations
enum ProfileNavDestination: Hashable {
    case settings
    case followers(userId: String)
    case following(userId: String)
    case recipe(id: String)
    case log(id: String)
}


struct ProfileView: View {
    var userId: String? = nil
    @StateObject private var viewModel: ProfileViewModel
    @EnvironmentObject private var authManager: AuthManager
    @EnvironmentObject private var appState: AppState
    @State private var navigationPath = NavigationPath()
    @State private var scrollProxy: ScrollViewProxy?

    private var isViewingOwnProfile: Bool { userId == nil }
    private let gridColumns = [
        GridItem(.flexible(), spacing: DesignSystem.Spacing.sm),
        GridItem(.flexible(), spacing: DesignSystem.Spacing.sm)
    ]

    init(userId: String? = nil) {
        self.userId = userId
        self._viewModel = StateObject(wrappedValue: ProfileViewModel(userId: userId))
    }

    var body: some View {
        // Use NavigationStack only for own profile (tab root), not when pushed from other views
        if isViewingOwnProfile {
            NavigationStack(path: $navigationPath) {
                profileBody
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
            }
        } else {
            profileBody
        }
    }

    @ViewBuilder
    private var profileBody: some View {
        Group {
            if isViewingOwnProfile && !authManager.isAuthenticated {
                loginPromptView
            } else {
                mainContent
            }
        }
        .background(DesignSystem.Colors.background)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            if !viewModel.isOwnProfile, let profile = viewModel.profile {
                ToolbarItem(placement: .navigationBarTrailing) {
                    BlockReportShareMenu(
                        targetUserId: profile.id,
                        targetUsername: profile.username,
                        shareURL: URL(string: "https://cookstemma.com/users/\(profile.id)")!,
                        onBlock: { Task { await viewModel.blockUser() } },
                        onReport: { reason in Task { await viewModel.reportUser(reason: reason) } }
                    )
                }
            }
        }
        .refreshable { viewModel.loadProfile() }
        .onAppear {
            if !isViewingOwnProfile || authManager.isAuthenticated {
                if case .idle = viewModel.state { viewModel.loadProfile() }
            }
        }
        .onReceive(appState.$profileScrollToTopTrigger.dropFirst()) { _ in
            // Only handle for own profile tab (not when viewing other users)
            guard isViewingOwnProfile else { return }

            // Pop to root if navigated
            if !navigationPath.isEmpty {
                navigationPath = NavigationPath()
            }
            // Scroll to top with animation
            withAnimation(.easeInOut(duration: 0.3)) {
                scrollProxy?.scrollTo("profile-top", anchor: .top)
            }
        }
    }

    private var loginPromptView: some View {
        VStack(spacing: DesignSystem.Spacing.lg) {
            Spacer()
            Image(systemName: AppIcon.profileOutline)
                .font(.system(size: DesignSystem.IconSize.xxl))
                .foregroundColor(DesignSystem.Colors.tertiaryText)
            Text(String(localized: "profile.signInPrompt"))
                .font(DesignSystem.Typography.body)
                .foregroundColor(DesignSystem.Colors.secondaryText)
            Button {
                appState.showLoginSheet = true
            } label: {
                Text(String(localized: "profile.signIn"))
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
        ScrollViewReader { proxy in
            ScrollView {
                Color.clear.frame(height: 0).id("profile-top")
                switch viewModel.state {
                case .idle, .loading: LoadingView()
                case .loaded: profileContent
                case .error(let msg): ErrorStateView(message: msg) { viewModel.loadProfile() }
                }
            }
            .scrollIndicators(.hidden)
            .contentMargins(.bottom, 80, for: .scrollContent)
            .onAppear { scrollProxy = proxy }
        }
    }

    @ViewBuilder
    private var profileContent: some View {
        VStack(spacing: DesignSystem.Spacing.md) {
            profileCard

            Divider()
                .padding(.horizontal, DesignSystem.Spacing.md)

            tabSection
            contentGrid
        }
        .padding(.vertical, DesignSystem.Spacing.md)
    }

    // MARK: - Profile Section (Seamless Layout)
    private var profileCard: some View {
        VStack(spacing: DesignSystem.Spacing.md) {
            profileHeader
            statsRow
            followButton
        }
        .padding(.horizontal, DesignSystem.Spacing.md)
    }

    private var profileHeader: some View {
        HStack(alignment: .top, spacing: DesignSystem.Spacing.md) {
            AvatarView(
                url: viewModel.isOwnProfile
                    ? viewModel.myProfile?.avatarUrl
                    : viewModel.profile?.avatarUrl,
                name: username,
                size: DesignSystem.AvatarSize.xl
            )

            VStack(alignment: .leading, spacing: DesignSystem.Spacing.xs) {
                Text("@\(username)")
                    .font(DesignSystem.Typography.title3)
                    .foregroundColor(DesignSystem.Colors.text)

                HStack(spacing: DesignSystem.Spacing.sm) {
                    // Level name badge
                    Text(localizedLevelName)
                        .font(DesignSystem.Typography.caption)
                        .fontWeight(.medium)
                        .foregroundColor(DesignSystem.Colors.primary)
                        .padding(.horizontal, DesignSystem.Spacing.sm)
                        .padding(.vertical, DesignSystem.Spacing.xxxs)
                        .background(DesignSystem.Colors.primary.opacity(0.1))
                        .cornerRadius(DesignSystem.CornerRadius.full)

                    // Level number
                    Text("Lv. \(level)")
                        .font(DesignSystem.Typography.subheadline)
                        .foregroundColor(DesignSystem.Colors.secondaryText)
                }

                if let bio = bio, !bio.isEmpty {
                    Text(bio)
                        .font(DesignSystem.Typography.body)
                        .foregroundColor(DesignSystem.Colors.secondaryText)
                        .lineLimit(2)
                }

                // Social Links
                if hasAnySocialLink {
                    HStack(spacing: DesignSystem.Spacing.sm) {
                        if let youtubeUrl = youtubeUrl, !youtubeUrl.isEmpty,
                           let url = URL(string: youtubeUrl) {
                            Link(destination: url) {
                                Image(systemName: "play.rectangle.fill")
                                    .font(.system(size: 16))
                                    .foregroundColor(.white)
                                    .frame(width: 32, height: 32)
                                    .background(Color.red)
                                    .cornerRadius(DesignSystem.CornerRadius.full)
                            }
                        }

                        if let handle = instagramHandle, !handle.isEmpty {
                            let cleanHandle = handle.replacingOccurrences(of: "@", with: "")
                            if let url = URL(string: "https://instagram.com/\(cleanHandle)") {
                                Link(destination: url) {
                                    Image(systemName: "camera.fill")
                                        .font(.system(size: 16))
                                        .foregroundColor(.white)
                                        .frame(width: 32, height: 32)
                                        .background(
                                            LinearGradient(
                                                colors: [.orange, .pink, .purple],
                                                startPoint: .bottomLeading,
                                                endPoint: .topTrailing
                                            )
                                        )
                                        .cornerRadius(DesignSystem.CornerRadius.full)
                                }
                            }
                        }
                    }
                }
            }

            Spacer()

            // Settings button (own profile only)
            if viewModel.isOwnProfile {
                NavigationLink(value: ProfileNavDestination.settings) {
                    Image(systemName: AppIcon.settings)
                        .font(.system(size: DesignSystem.IconSize.lg))
                        .foregroundColor(DesignSystem.Colors.secondaryText)
                }
            }
        }
    }

    private var statsRow: some View {
        HStack(spacing: 0) {
            ProfileStatItem(count: recipeCount, label: String(localized: "profile.recipes"))
            ProfileStatItem(count: logCount, label: String(localized: "profile.logs"))
            NavigationLink(value: ProfileNavDestination.followers(userId: userId ?? viewModel.myProfile?.id ?? "")) {
                ProfileStatItem(count: followerCount, label: String(localized: "profile.followers"))
            }
            .buttonStyle(.plain)
            NavigationLink(value: ProfileNavDestination.following(userId: userId ?? viewModel.myProfile?.id ?? "")) {
                ProfileStatItem(count: followingCount, label: String(localized: "profile.following"))
            }
            .buttonStyle(.plain)
        }
        .padding(.vertical, DesignSystem.Spacing.sm)
    }

    @ViewBuilder
    private var followButton: some View {
        if !viewModel.isOwnProfile, let profile = viewModel.profile {
            FollowIconButton(isFollowing: profile.isFollowing) {
                await viewModel.toggleFollow()
            }
        }
    }

    // MARK: - Tab Section
    private var tabSection: some View {
        VStack(spacing: DesignSystem.Spacing.sm) {
            tabBar
            if viewModel.isOwnProfile {
                visibilityFilter
            }
        }
        .padding(.horizontal, DesignSystem.Spacing.md)
    }

    private var tabBar: some View {
        HStack(spacing: 0) {
            ProfileTabButton(
                title: String(localized: "profile.recipes"),
                count: recipeCount,
                isSelected: viewModel.selectedTab == .recipes
            ) {
                viewModel.selectedTab = .recipes
            }

            ProfileTabButton(
                title: String(localized: "profile.logs"),
                count: logCount,
                isSelected: viewModel.selectedTab == .logs
            ) {
                viewModel.selectedTab = .logs
            }

            if viewModel.isOwnProfile {
                ProfileTabButton(
                    title: String(localized: "profile.saved"),
                    count: viewModel.savedCount,
                    isSelected: viewModel.selectedTab == .saved
                ) {
                    viewModel.selectedTab = .saved
                }
            }
        }
        .onChange(of: viewModel.selectedTab) { _, newTab in
                    #if DEBUG
                    print("[ProfileView] Tab changed to: \(newTab)")
                    #endif
                    viewModel.loadContent()
                }
    }

    @ViewBuilder
    private var visibilityFilter: some View {
        if viewModel.selectedTab == .saved {
            Picker("Saved Filter", selection: $viewModel.savedContentFilter) {
                ForEach(SavedContentFilter.allCases, id: \.self) { filter in
                    Text(filter.title).tag(filter)
                }
            }
            .pickerStyle(.segmented)
        } else {
            Picker("Visibility", selection: $viewModel.visibilityFilter) {
                ForEach(VisibilityFilter.allCases, id: \.self) { filter in
                    Text(filter.title).tag(filter)
                }
            }
            .pickerStyle(.segmented)
        }
    }

    // MARK: - Content Grid
    @ViewBuilder
    private var contentGrid: some View {
        if viewModel.selectedTab == .saved {
            savedFilterContent(for: viewModel.savedContentFilter)
        } else {
            visibilityFilterContent(for: viewModel.visibilityFilter)
        }
    }

    @ViewBuilder
    private func visibilityFilterContent(for filter: VisibilityFilter) -> some View {
        VStack(spacing: 0) {
            LazyVGrid(columns: gridColumns, spacing: DesignSystem.Spacing.md) {
                switch viewModel.selectedTab {
                case .recipes:
                    ForEach(viewModel.recipes) { recipe in
                        NavigationLink(value: ProfileNavDestination.recipe(id: recipe.id)) {
                            RecipeGridCard(recipe: recipe)
                        }
                        .buttonStyle(.plain)
                        .id("\(recipe.id)-\(recipe.coverImageUrl ?? "")")
                    }
                case .logs:
                    ForEach(viewModel.logs) { log in
                        NavigationLink(value: ProfileNavDestination.log(id: log.id)) {
                            LogGridCard(log: log)
                        }
                        .buttonStyle(.plain)
                        .id("\(log.id)-\(log.thumbnailUrl ?? "")")
                    }
                case .saved:
                    EmptyView()
                }
            }
            .padding(.horizontal, DesignSystem.Spacing.md)

            if viewModel.isLoadingContent {
                ProgressView()
                    .padding()
            }

            if isEmptyForCurrentTab {
                emptyState
            }
        }
    }

    @ViewBuilder
    private func savedFilterContent(for filter: SavedContentFilter) -> some View {
        VStack(spacing: 0) {
            LazyVGrid(columns: gridColumns, spacing: DesignSystem.Spacing.md) {
                if filter != .logs {
                    ForEach(viewModel.savedRecipes) { recipe in
                        NavigationLink(value: ProfileNavDestination.recipe(id: recipe.id)) {
                            RecipeGridCard(recipe: recipe, showSavedBadge: true)
                        }
                        .buttonStyle(.plain)
                        .id("\(recipe.id)-\(recipe.coverImageUrl ?? "")")
                    }
                }
                if filter != .recipes {
                    ForEach(viewModel.savedLogs) { log in
                        NavigationLink(value: ProfileNavDestination.log(id: log.id)) {
                            LogGridCard(log: log, showSavedBadge: true)
                        }
                        .buttonStyle(.plain)
                        .id("\(log.id)-\(log.thumbnailUrl ?? "")")
                    }
                }
            }
            .padding(.horizontal, DesignSystem.Spacing.md)

            if viewModel.isLoadingContent {
                ProgressView()
                    .padding()
            }

            if isEmptyForSavedFilter(filter) {
                savedEmptyState(for: filter)
            }
        }
        .onAppear {
            // Always refresh saved content when this view appears
            #if DEBUG
            print("[ProfileView] savedFilterContent onAppear, triggering refresh")
            #endif
            Task {
                await viewModel.refreshSavedContentIfNeeded()
            }
        }
    }

    private func isEmptyForSavedFilter(_ filter: SavedContentFilter) -> Bool {
        switch filter {
        case .all:
            return viewModel.savedRecipes.isEmpty && viewModel.savedLogs.isEmpty && !viewModel.isLoadingContent
        case .recipes:
            return viewModel.savedRecipes.isEmpty && !viewModel.isLoadingContent
        case .logs:
            return viewModel.savedLogs.isEmpty && !viewModel.isLoadingContent
        }
    }

    @ViewBuilder
    private func savedEmptyState(for filter: SavedContentFilter) -> some View {
        VStack(spacing: DesignSystem.Spacing.xs) {
            switch filter {
            case .all:
                Image(systemName: AppIcon.saveOutline)
                    .font(.system(size: DesignSystem.IconSize.xxl))
                    .foregroundColor(DesignSystem.Colors.tertiaryText)
                Text("No saved items yet")
            case .recipes:
                Image(systemName: AppIcon.recipe)
                    .font(.system(size: DesignSystem.IconSize.xxl))
                    .foregroundColor(DesignSystem.Colors.tertiaryText)
                Text("No saved recipes yet")
            case .logs:
                LogoIconView(size: 80, color: DesignSystem.Colors.tertiaryText, useOriginalColors: false)
                    .padding(.vertical, -16)
                Text("No saved logs yet")
            }
        }
        .font(DesignSystem.Typography.body)
        .foregroundColor(DesignSystem.Colors.tertiaryText)
        .frame(maxWidth: .infinity)
        .padding(.vertical, DesignSystem.Spacing.xxl)
    }

    private var isEmptyForCurrentTab: Bool {
        switch viewModel.selectedTab {
        case .recipes: return viewModel.recipes.isEmpty && !viewModel.isLoadingContent
        case .logs: return viewModel.logs.isEmpty && !viewModel.isLoadingContent
        case .saved: return false // Handled separately
        }
    }

    @ViewBuilder
    private var emptyState: some View {
        VStack(spacing: DesignSystem.Spacing.xs) {
            if viewModel.selectedTab == .logs ||
                (viewModel.selectedTab == .saved && viewModel.savedContentFilter == .logs) {
                LogoIconView(
                    size: 80,
                    color: DesignSystem.Colors.tertiaryText,
                    useOriginalColors: false
                )
                .padding(.vertical, -16)
            } else {
                Image(systemName: emptyIcon)
                    .font(.system(size: DesignSystem.IconSize.xxl))
                    .foregroundColor(DesignSystem.Colors.tertiaryText)
            }
            Text(emptyMessage)
                .font(DesignSystem.Typography.body)
                .foregroundColor(DesignSystem.Colors.tertiaryText)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, DesignSystem.Spacing.xxl)
    }

    // MARK: - Computed Properties
    private var username: String {
        viewModel.isOwnProfile
            ? viewModel.myProfile?.username ?? ""
            : viewModel.profile?.username ?? ""
    }

    private var level: Int {
        viewModel.isOwnProfile
            ? viewModel.myProfile?.level ?? 1
            : viewModel.profile?.level ?? 1
    }

    private var localizedLevelName: String {
        viewModel.isOwnProfile
            ? viewModel.myProfile?.localizedLevelName ?? LevelName.displayName(for: nil)
            : viewModel.profile?.localizedLevelName ?? LevelName.displayName(for: nil)
    }

    private var bio: String? {
        viewModel.isOwnProfile
            ? viewModel.myProfile?.bio
            : viewModel.profile?.bio
    }

    private var youtubeUrl: String? {
        viewModel.isOwnProfile
            ? viewModel.myProfile?.youtubeUrl
            : viewModel.profile?.youtubeUrl
    }

    private var instagramHandle: String? {
        viewModel.isOwnProfile
            ? viewModel.myProfile?.instagramHandle
            : viewModel.profile?.instagramHandle
    }

    private var hasAnySocialLink: Bool {
        (youtubeUrl != nil && !youtubeUrl!.isEmpty) ||
        (instagramHandle != nil && !instagramHandle!.isEmpty)
    }

    private var recipeCount: Int {
        viewModel.isOwnProfile
            ? viewModel.myProfile?.recipeCount ?? 0
            : viewModel.profile?.recipeCount ?? 0
    }

    private var logCount: Int {
        viewModel.isOwnProfile
            ? viewModel.myProfile?.logCount ?? 0
            : viewModel.profile?.logCount ?? 0
    }

    private var followerCount: Int {
        viewModel.isOwnProfile
            ? viewModel.myProfile?.followerCount ?? 0
            : viewModel.profile?.followerCount ?? 0
    }

    private var followingCount: Int {
        viewModel.isOwnProfile
            ? viewModel.myProfile?.followingCount ?? 0
            : viewModel.profile?.followingCount ?? 0
    }

    private var isEmpty: Bool {
        switch viewModel.selectedTab {
        case .recipes: return viewModel.recipes.isEmpty && !viewModel.isLoadingContent
        case .logs: return viewModel.logs.isEmpty && !viewModel.isLoadingContent
        case .saved:
            switch viewModel.savedContentFilter {
            case .all:
                return viewModel.savedRecipes.isEmpty
                    && viewModel.savedLogs.isEmpty
                    && !viewModel.isLoadingContent
            case .recipes:
                return viewModel.savedRecipes.isEmpty && !viewModel.isLoadingContent
            case .logs:
                return viewModel.savedLogs.isEmpty && !viewModel.isLoadingContent
            }
        }
    }

    private var emptyIcon: String {
        switch viewModel.selectedTab {
        case .recipes: return AppIcon.recipe
        case .logs: return AppIcon.log
        case .saved:
            switch viewModel.savedContentFilter {
            case .all: return AppIcon.saveOutline
            case .recipes: return AppIcon.recipe
            case .logs: return AppIcon.log
            }
        }
    }

    private var emptyMessage: String {
        switch viewModel.selectedTab {
        case .recipes: return String(localized: "profile.noRecipes")
        case .logs: return String(localized: "profile.noLogs")
        case .saved:
            switch viewModel.savedContentFilter {
            case .all: return String(localized: "profile.noSaved")
            case .recipes: return String(localized: "profile.noSavedRecipes")
            case .logs: return String(localized: "profile.noSavedLogs")
            }
        }
    }
}

// MARK: - Profile Stat Item
struct ProfileStatItem: View {
    let count: Int
    let label: String

    var body: some View {
        VStack(spacing: DesignSystem.Spacing.xxxs) {
            Text("\(count.abbreviated)")
                .font(DesignSystem.Typography.headline)
                .foregroundColor(DesignSystem.Colors.text)
            Text(label)
                .font(DesignSystem.Typography.caption)
                .foregroundColor(DesignSystem.Colors.secondaryText)
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Profile Tab Button
struct ProfileTabButton: View {
    let title: String
    let count: Int
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: DesignSystem.Spacing.xxs) {
                Text("\(title) (\(count))")
                    .font(DesignSystem.Typography.subheadline)
                    .fontWeight(isSelected ? .semibold : .regular)
                    .foregroundColor(
                        isSelected
                            ? DesignSystem.Colors.primary
                            : DesignSystem.Colors.secondaryText
                    )

                Rectangle()
                    .fill(isSelected ? DesignSystem.Colors.primary : Color.clear)
                    .frame(height: 2)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, DesignSystem.Spacing.sm)
        }
    }
}

// MARK: - Profile Grid Item
struct ProfileGridItem: View {
    let imageUrl: String?
    var isSaved: Bool = false

    var body: some View {
        ZStack(alignment: .topTrailing) {
            AsyncImage(url: URL(string: imageUrl ?? "")) { img in
                img.resizable().scaledToFill()
            } placeholder: {
                Rectangle().fill(DesignSystem.Colors.tertiaryBackground)
            }
            .frame(height: 120)
            .clipped()

            if isSaved {
                Image(systemName: AppIcon.save)
                    .font(.system(size: DesignSystem.IconSize.sm))
                    .foregroundColor(.white)
                    .padding(DesignSystem.Spacing.xs)
                    .background(Color.black.opacity(0.5))
                    .cornerRadius(DesignSystem.CornerRadius.xs)
                    .padding(DesignSystem.Spacing.xxs)
            }
        }
    }
}

#Preview {
    ProfileView()
        .environmentObject(AuthManager.shared)
        .environmentObject(AppState())
}
