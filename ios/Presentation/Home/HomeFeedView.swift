import SwiftUI

struct HomeFeedView: View {
    @StateObject private var viewModel = HomeFeedViewModel()
    @EnvironmentObject private var appState: AppState
    @State private var scrollOffset: CGFloat = 0
    @State private var scrollToTopTrigger: Int = 0
    @State private var programmaticRefreshTrigger: Int = 0
    @State private var navigationPath = NavigationPath()

    private let headerHeight: CGFloat = 56

    var body: some View {
        NavigationStack(path: $navigationPath) {
            ZStack(alignment: .top) {
                // Main content area
                switch viewModel.state {
                case .idle, .loading:
                    // Loading content with header space
                    VStack {
                        Color.clear.frame(height: headerHeight)
                        Spacer()
                        ProgressView()
                        Spacer()
                    }
                case .loaded:
                    scrollContent
                case .empty:
                    VStack {
                        Color.clear.frame(height: headerHeight)
                        Spacer()
                        IconEmptyState(icon: AppIcon.log, subtitle: "No cooking logs yet")
                        Spacer()
                    }
                case .error(let msg):
                    VStack {
                        Color.clear.frame(height: headerHeight)
                        Spacer()
                        ErrorStateView(message: msg) { viewModel.loadFeed() }
                        Spacer()
                    }
                }

                // Header overlay - scrolls with content when loaded
                homeHeader
                    .offset(y: min(0, scrollOffset))
            }
            .background(DesignSystem.Colors.background)
            .navigationBarHidden(true)
            .navigationDestination(for: String.self) { logId in
                LogDetailView(logId: logId)
            }
            .navigationDestination(for: NotificationDestination.self) { _ in
                NotificationsView()
            }
        }
        .onAppear { if case .idle = viewModel.state { viewModel.loadFeed() } }
        .onChange(of: appState.homeScrollToTopTrigger) { _, _ in
            // Check if in a detail view (navigation path not empty)
            if !navigationPath.isEmpty {
                // Pop to root with back-button-style animation
                navigationPath = NavigationPath()
                return
            }

            // At root - check if scrolled
            let isAtTop = scrollOffset >= -10
            if isAtTop {
                // Already at top - trigger refresh with pull-down animation
                programmaticRefreshTrigger += 1
            } else {
                // Scrolled down - scroll to top smoothly
                scrollToTopTrigger += 1
            }
        }
    }

    // Placeholder type for notifications navigation
    private struct NotificationDestination: Hashable {}

    private var homeHeader: some View {
        HStack {
            HStack(spacing: DesignSystem.Spacing.xs) {
                Image("LogoIcon")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 28, height: 28)
                Text("Cookstemma")
                    .font(DesignSystem.Typography.headline)
                    .foregroundColor(DesignSystem.Colors.text)
            }
            Spacer()
            NavigationLink(value: NotificationDestination()) {
                NotificationBadge(count: appState.unreadNotificationCount)
            }
        }
        .padding(.horizontal, DesignSystem.Spacing.md)
        .frame(height: headerHeight)
        .frame(maxWidth: .infinity)
        .background(DesignSystem.Colors.background)
    }

    private var scrollContent: some View {
        CustomRefreshableScrollView(
            headerHeight: headerHeight,
            headerScrollOffset: $scrollOffset,
            scrollToTopTrigger: $scrollToTopTrigger,
            programmaticRefreshTrigger: $programmaticRefreshTrigger,
            onRefresh: { await viewModel.refresh() }
        ) {
            feedContent
        }
    }

    private var feedContent: some View {
        VStack(spacing: DesignSystem.Spacing.md) {
            ForEach(viewModel.feedItems) { item in
                NavigationLink(value: item.id) {
                    FeedLogCard(item: item)
                }
                .buttonStyle(.plain)
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
        .padding(.horizontal, DesignSystem.Spacing.md)
        .padding(.bottom, DesignSystem.Spacing.sm)
    }
}

// MARK: - Feed Log Card (Instagram Style)
struct FeedLogCard: View {
    let item: FeedLogItem

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header: User and Rating
            HStack {
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
        .background(DesignSystem.Colors.background)
        .cornerRadius(DesignSystem.CornerRadius.md)
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
                    Text("by @\(recipe.userName)")
                        .font(DesignSystem.Typography.caption)
                        .foregroundColor(DesignSystem.Colors.tertiaryText)
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
                        Image(systemName: AppIcon.log)
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
    }
}

#Preview {
    HomeFeedView().environmentObject(AppState())
}
