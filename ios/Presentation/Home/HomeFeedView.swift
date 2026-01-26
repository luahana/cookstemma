import SwiftUI

struct HomeFeedView: View {
    @StateObject private var viewModel = HomeFeedViewModel()
    @EnvironmentObject private var appState: AppState
    @State private var scrollOffset: CGFloat = 0

    private let headerHeight: CGFloat = 56

    var body: some View {
        NavigationStack {
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
                        IconEmptyState(icon: AppIcon.followers, subtitle: nil)
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
            .background(DesignSystem.Colors.secondaryBackground)
            .navigationBarHidden(true)
        }
        .onAppear { if case .idle = viewModel.state { viewModel.loadFeed() } }
    }

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
            NavigationLink(destination: NotificationsView()) {
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
            onRefresh: { await viewModel.refresh() }
        ) {
            feedContent
        }
    }

    private var feedContent: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.md) {
            // Recent Activity Section
            if !viewModel.recentActivity.isEmpty {
                sectionHeader(icon: AppIcon.log, title: "Recent Activity")

                ForEach(viewModel.recentActivity) { activity in
                    NavigationLink(destination: LogDetailView(logId: activity.id)) {
                        ActivityCard(activity: activity)
                    }
                    .buttonStyle(.plain)
                }
            }

            // Recent Recipes Section
            if !viewModel.recentRecipes.isEmpty {
                sectionHeader(icon: AppIcon.recipe, title: "Recent Recipes")
                    .padding(.top, DesignSystem.Spacing.md)

                ForEach(viewModel.recentRecipes) { recipe in
                    NavigationLink(destination: RecipeDetailView(recipeId: recipe.id)) {
                        HomeRecipeCard(recipe: recipe)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .padding(.horizontal, DesignSystem.Spacing.md)
        .padding(.vertical, DesignSystem.Spacing.sm)
    }

    private func sectionHeader(icon: String, title: String) -> some View {
        HStack(spacing: DesignSystem.Spacing.xs) {
            Image(systemName: icon)
                .font(.system(size: DesignSystem.IconSize.md))
                .foregroundColor(DesignSystem.Colors.primary)
            Text(title)
                .font(DesignSystem.Typography.headline)
                .foregroundColor(DesignSystem.Colors.text)
        }
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

// MARK: - Activity Card
struct ActivityCard: View {
    let activity: RecentActivityItem

    var body: some View {
        HStack(spacing: DesignSystem.Spacing.sm) {
            // Thumbnail
            AsyncImage(url: URL(string: activity.thumbnailUrl ?? "")) { img in
                img.resizable().scaledToFill()
            } placeholder: {
                Rectangle().fill(DesignSystem.Colors.tertiaryBackground)
            }
            .frame(width: 80, height: 80)
            .cornerRadius(DesignSystem.CornerRadius.sm)
            .clipped()

            VStack(alignment: .leading, spacing: DesignSystem.Spacing.xxs) {
                // Recipe title
                Text(activity.recipeTitle)
                    .font(DesignSystem.Typography.subheadline)
                    .fontWeight(.medium)
                    .lineLimit(2)
                    .foregroundColor(DesignSystem.Colors.text)

                // User and rating
                HStack(spacing: DesignSystem.Spacing.xs) {
                    Text("by @\(activity.userName)")
                        .font(DesignSystem.Typography.caption)
                        .foregroundColor(DesignSystem.Colors.secondaryText)

                    HStack(spacing: 2) {
                        Image(systemName: AppIcon.star)
                            .foregroundColor(DesignSystem.Colors.rating)
                        Text("\(activity.rating)")
                    }
                    .font(DesignSystem.Typography.caption)
                    .foregroundColor(DesignSystem.Colors.secondaryText)
                }

                // Food name and time
                HStack(spacing: DesignSystem.Spacing.xs) {
                    Text(activity.foodName)
                        .font(DesignSystem.Typography.caption)
                        .foregroundColor(DesignSystem.Colors.tertiaryText)

                    Text("•")
                        .foregroundColor(DesignSystem.Colors.tertiaryText)

                    Text(activity.createdAt.timeAgo())
                        .font(DesignSystem.Typography.caption)
                        .foregroundColor(DesignSystem.Colors.tertiaryText)
                }

                // Hashtags
                if !activity.hashtags.isEmpty {
                    Text(activity.hashtags.prefix(3).map { "#\($0)" }.joined(separator: " "))
                        .font(DesignSystem.Typography.caption2)
                        .foregroundColor(DesignSystem.Colors.primary)
                        .lineLimit(1)
                }
            }

            Spacer()

            Image(systemName: AppIcon.forward)
                .foregroundColor(DesignSystem.Colors.tertiaryText)
                .font(.system(size: DesignSystem.IconSize.xs))
        }
        .padding(DesignSystem.Spacing.sm)
        .background(DesignSystem.Colors.background)
        .cornerRadius(DesignSystem.CornerRadius.md)
    }
}

// MARK: - Home Recipe Card
struct HomeRecipeCard: View {
    let recipe: HomeRecipeItem

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
                            Text(formatCookingTime(time))
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

            Image(systemName: AppIcon.forward)
                .foregroundColor(DesignSystem.Colors.tertiaryText)
                .font(.system(size: DesignSystem.IconSize.xs))
        }
        .padding(DesignSystem.Spacing.sm)
        .background(DesignSystem.Colors.background)
        .cornerRadius(DesignSystem.CornerRadius.md)
    }

    private func formatCookingTime(_ timeRange: String) -> String {
        switch timeRange {
        case "UNDER_15": return "<15m"
        case "MIN_15_TO_30": return "15-30m"
        case "MIN_30_TO_60": return "30-60m"
        case "OVER_60": return ">60m"
        default: return timeRange
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
