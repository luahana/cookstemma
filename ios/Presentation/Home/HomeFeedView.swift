import SwiftUI

enum HomeDestination: Hashable {
    case log(String)
    case notifications
    case user(String)
    case recipe(String)
}

struct HomeFeedView: View {
    @StateObject private var viewModel = HomeFeedViewModel()
    @EnvironmentObject private var appState: AppState
    @State private var navigationPath = NavigationPath()
    @State private var scrollProxy: ScrollViewProxy?

    var body: some View {
        NavigationStack(path: $navigationPath) {
            VStack(spacing: 0) {
                homeHeader
                contentView
            }
            .frame(maxHeight: .infinity, alignment: .top)
            .background(DesignSystem.Colors.background)
            .navigationBarHidden(true)
            .navigationDestination(for: HomeDestination.self) { destination in
                switch destination {
                case .log(let logId):
                    LogDetailView(logId: logId)
                case .notifications:
                    NotificationsView(navigationPath: $navigationPath)
                case .user(let userId):
                    ProfileView(userId: userId)
                case .recipe(let recipeId):
                    RecipeDetailView(recipeId: recipeId)
                }
            }
            // Handle ProfileNavDestination for when ProfileView is pushed and uses internal NavigationLinks
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
        .onAppear { if case .idle = viewModel.state { viewModel.loadFeed() } }
        .onChange(of: appState.homeScrollToTopTrigger) { _, _ in
            // Dismiss any presented views and pop to root
            if !navigationPath.isEmpty {
                navigationPath = NavigationPath()
                return
            }
            // Scroll to top with animation
            withAnimation(.easeInOut(duration: 0.3)) {
                scrollProxy?.scrollTo("home-top", anchor: .top)
            }
            Task { await viewModel.refresh() }
        }
    }

    private var homeHeader: some View {
        HStack {
            HStack(spacing: DesignSystem.Spacing.xs) {
                Image("LogoIcon")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 36, height: 36)
                Text("Cookstemma")
                    .font(DesignSystem.Typography.headline)
                    .foregroundColor(DesignSystem.Colors.text)
            }
            Spacer()
            Button {
                appState.requireAuth {
                    navigationPath.append(HomeDestination.notifications)
                }
            } label: {
                NotificationBadge(count: appState.unreadNotificationCount)
            }
        }
        .padding(.horizontal, DesignSystem.Spacing.md)
        .padding(.top, DesignSystem.Spacing.xs)
        .padding(.bottom, 0)
    }

    @ViewBuilder
    private var contentView: some View {
        switch viewModel.state {
        case .idle, .loading:
            Spacer()
            ProgressView()
            Spacer()
        case .loaded:
            ScrollViewReader { proxy in
                ScrollView(.vertical, showsIndicators: false) {
                    Color.clear.frame(height: 0).id("home-top")
                    feedContent
                }
                .contentMargins(.top, 0, for: .scrollContent)
                .refreshable {
                    await viewModel.refresh()
                }
                .onAppear { scrollProxy = proxy }
            }
        case .empty:
            Spacer()
            IconEmptyState(useLogoIcon: true, subtitle: String(localized: "home.noLogs"))
            Spacer()
        case .error(let msg):
            Spacer()
            ErrorStateView(message: msg) { viewModel.loadFeed() }
            Spacer()
        }
    }

    private var feedContent: some View {
        VStack(spacing: DesignSystem.Spacing.md) {
            ForEach(viewModel.feedItems) { item in
                FeedLogCard(
                    item: item,
                    onUsernameTap: {
                        navigationPath.append(HomeDestination.user(item.creatorPublicId))
                    },
                    onCardTap: {
                        navigationPath.append(HomeDestination.log(item.id))
                    }
                )
                .responsiveFrame()
                .id("\(item.id)-\(item.thumbnailUrl ?? "")")
                .onAppear {
                    viewModel.loadMoreIfNeeded(currentItem: item)
                }
            }

            // Loading indicator at bottom
            if viewModel.isLoadingMore {
                ProgressView()
                    .padding(.vertical, DesignSystem.Spacing.md)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.bottom, DesignSystem.Spacing.sm)
    }
}

// MARK: - Feed Log Card (Instagram Style)
struct FeedLogCard: View {
    let item: FeedLogItem
    var onUsernameTap: (() -> Void)?
    var onCardTap: (() -> Void)?

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header: User and Rating
            HStack {
                Button {
                    onUsernameTap?()
                } label: {
                    HStack(spacing: DesignSystem.Spacing.xs) {
                        Circle()
                            .fill(DesignSystem.Colors.tertiaryBackground)
                            .frame(width: 32, height: 32)
                            .overlay(
                                Text(String(item.userName.prefix(1)).uppercased())
                                    .font(DesignSystem.Typography.caption)
                                    .fontWeight(.semibold)
                                    .foregroundColor(DesignSystem.Colors.secondaryText)
                            )

                        Text(item.userName)
                            .font(DesignSystem.Typography.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(DesignSystem.Colors.text)
                    }
                }
                .buttonStyle(.plain)

                Spacer()

                if let rating = item.rating {
                    HStack(spacing: 4) {
                        ForEach(1...5, id: \.self) { index in
                            Image(systemName: index <= rating ? AppIcon.star : AppIcon.starOutline)
                                .font(.system(size: 12))
                                .foregroundColor(index <= rating ? DesignSystem.Colors.rating : DesignSystem.Colors.tertiaryText)
                        }
                    }
                }
            }
            .padding(.horizontal, DesignSystem.Spacing.sm)
            .padding(.vertical, DesignSystem.Spacing.xs)

            // Tappable content area (image + footer) -> navigates to log detail
            Button {
                onCardTap?()
            } label: {
                VStack(alignment: .leading, spacing: 0) {
                    // Full-width Image (16:9 aspect ratio)
                    AsyncImage(url: URL(string: item.thumbnailUrl ?? "")) { img in
                        img.resizable().scaledToFill()
                    } placeholder: {
                        Rectangle()
                            .fill(DesignSystem.Colors.tertiaryBackground)
                            .overlay(
                                Image(systemName: AppIcon.photo)
                                    .font(.system(size: 32))
                                    .foregroundColor(DesignSystem.Colors.secondaryText.opacity(0.5))
                            )
                    }
                    .frame(height: 220)
                    .frame(maxWidth: .infinity)
                    .clipped()

                    // Footer: Description, Food, Comments, Hashtags
                    VStack(alignment: .leading, spacing: DesignSystem.Spacing.xs) {
                        // Description
                        if let content = item.content, !content.isEmpty {
                            Text(content)
                                .font(DesignSystem.Typography.body)
                                .lineLimit(2)
                                .truncationMode(.tail)
                                .foregroundColor(DesignSystem.Colors.text)
                        }

                        // Food name, cooking style, and comments
                        HStack(spacing: DesignSystem.Spacing.sm) {
                            if let foodName = item.foodName {
                                HStack(spacing: 4) {
                                    Image(systemName: AppIcon.recipe)
                                        .font(.system(size: 12))
                                    Text(foodName)
                                }
                                .font(DesignSystem.Typography.caption)
                                .foregroundColor(DesignSystem.Colors.secondaryText)
                            }

                            // Cooking style badge
                            if let style = item.cookingStyle, !style.isEmpty {
                                HStack(spacing: 2) {
                                    Text(style.flagEmoji)
                                    Text(style.cookingStyleName)
                                }
                                .font(DesignSystem.Typography.caption)
                                .foregroundColor(DesignSystem.Colors.secondaryText)
                            }

                            if let commentCount = item.commentCount, commentCount > 0 {
                                HStack(spacing: 4) {
                                    Image(systemName: AppIcon.comment)
                                        .font(.system(size: 12))
                                    Text("\(commentCount)")
                                }
                                .font(DesignSystem.Typography.caption)
                                .foregroundColor(DesignSystem.Colors.secondaryText)
                            }
                        }

                        // Hashtags
                        if !item.hashtags.isEmpty {
                            Text(item.hashtags.prefix(4).map { "#\($0)" }.joined(separator: " "))
                                .font(DesignSystem.Typography.caption)
                                .foregroundColor(DesignSystem.Colors.primary)
                                .lineLimit(1)
                        }
                    }
                    .padding(DesignSystem.Spacing.sm)
                }
            }
            .buttonStyle(.plain)
        }
        .background(DesignSystem.Colors.background)
        .contentShape(Rectangle())
    }
}

// MARK: - Notification Badge (Icon-Only)
struct NotificationBadge: View {
    let count: Int

    var body: some View {
        ZStack {
            Image(systemName: count > 0 ? AppIcon.notifications : AppIcon.notificationsOutline)
                .font(.system(size: DesignSystem.IconSize.md))
                .foregroundColor(DesignSystem.Colors.text)
            if count > 0 {
                Circle()
                    .fill(DesignSystem.Colors.error)
                    .frame(width: 8, height: 8)
                    .offset(x: 8, y: -8)
            }
        }
    }
}

// MARK: - Recipe Card Compact (for RecipeSummary)
struct RecipeCardCompact: View {
    let recipe: RecipeSummary
    var onUsernameTap: (() -> Void)?

    var body: some View {
        HStack(spacing: DesignSystem.Spacing.sm) {
            // Cover image
            AsyncImage(url: URL(string: recipe.thumbnail ?? "")) { img in
                img.resizable().scaledToFill()
            } placeholder: {
                Rectangle().fill(DesignSystem.Colors.secondaryBackground)
            }
            .frame(width: 80, height: 80)
            .cornerRadius(DesignSystem.CornerRadius.sm)
            .clipped()

            VStack(alignment: .leading, spacing: DesignSystem.Spacing.xxs) {
                Text(recipe.title)
                    .font(DesignSystem.Typography.subheadline)
                    .fontWeight(.medium)
                    .lineLimit(2)
                    .foregroundColor(DesignSystem.Colors.text)

                // Food name and user
                HStack(spacing: DesignSystem.Spacing.xs) {
                    Text(recipe.foodName)
                        .font(DesignSystem.Typography.caption)
                        .foregroundColor(DesignSystem.Colors.secondaryText)
                    if let onTap = onUsernameTap {
                        Button {
                            onTap()
                        } label: {
                            Text("by @\(recipe.userName)")
                                .font(DesignSystem.Typography.caption)
                                .foregroundColor(DesignSystem.Colors.tertiaryText)
                        }
                        .buttonStyle(.plain)
                    } else {
                        Text("by @\(recipe.userName)")
                            .font(DesignSystem.Typography.caption)
                            .foregroundColor(DesignSystem.Colors.tertiaryText)
                    }
                }

                // Stats row (icons only)
                HStack(spacing: DesignSystem.Spacing.md) {
                    // Time
                    if let time = recipe.cookingTimeRange {
                        HStack(spacing: 2) {
                            Image(systemName: AppIcon.timer)
                            Text(time.cookingTimeDisplayText)
                        }
                        .font(DesignSystem.Typography.caption)
                        .foregroundColor(DesignSystem.Colors.secondaryText)
                    }

                    // Log count
                    HStack(spacing: 2) {
                        LogoIconView(size: 12)
                        Text("\(recipe.logCount)")
                    }
                    .font(DesignSystem.Typography.caption)
                    .foregroundColor(DesignSystem.Colors.secondaryText)

                    // Servings
                    if let servings = recipe.servings {
                        HStack(spacing: 2) {
                            Image(systemName: AppIcon.servings)
                            Text("\(servings)")
                        }
                        .font(DesignSystem.Typography.caption)
                        .foregroundColor(DesignSystem.Colors.secondaryText)
                    }
                }
            }
            Spacer()
        }
        .padding(DesignSystem.Spacing.sm)
        .background(DesignSystem.Colors.background)
        .cornerRadius(DesignSystem.CornerRadius.md)
        .contentShape(Rectangle())
    }
}

#Preview {
    HomeFeedView().environmentObject(AppState())
}
