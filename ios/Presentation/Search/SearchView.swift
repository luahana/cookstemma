import SwiftUI

enum SearchTab: CaseIterable {
    case all
    case recipes
    case logs
    case users
    case hashtags

    var icon: String {
        switch self {
        case .all: return "square.grid.2x2"
        case .recipes: return AppIcon.recipe
        case .logs: return AppIcon.log
        case .users: return AppIcon.followers
        case .hashtags: return "number"
        }
    }
}

struct SearchView: View {
    @StateObject private var viewModel = SearchViewModel()
    @State private var selectedTab: SearchTab = .all
    @FocusState private var isSearchFocused: Bool

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                searchBar
                contentView
            }
            .navigationBarHidden(true)
        }
        .onAppear {
            viewModel.loadRecentSearches()
            viewModel.loadHomeFeed()
        }
    }

    // MARK: - Search Bar

    private var searchBar: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundColor(DesignSystem.Colors.secondaryText)

            TextField("Search recipes, logs, users", text: $viewModel.query)
                .focused($isSearchFocused)
                .submitLabel(.search)
                .onSubmit { viewModel.search() }

            if isSearchFocused && viewModel.query.isEmpty {
                Button("Cancel") {
                    isSearchFocused = false
                    viewModel.resetSeeAllState()
                }
                .font(DesignSystem.Typography.subheadline)
                .foregroundColor(DesignSystem.Colors.primary)
            } else if !viewModel.query.isEmpty {
                Button { viewModel.clearSearch() } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(DesignSystem.Colors.secondaryText)
                }
            }
        }
        .padding()
        .background(DesignSystem.Colors.secondaryBackground)
        .cornerRadius(DesignSystem.CornerRadius.md)
        .padding()
    }

    // MARK: - Content View

    @ViewBuilder
    private var contentView: some View {
        if viewModel.showAllRecipes {
            seeAllRecipesView
        } else if viewModel.showAllLogs {
            seeAllLogsView
        } else if !viewModel.query.isEmpty {
            if viewModel.isSearching {
                LoadingView()
            } else {
                searchResults
            }
        } else if isSearchFocused {
            searchHistoryView
        } else {
            homeStyleContentView
        }
    }

    // MARK: - Home Style Content (Default View)

    private var homeStyleContentView: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: DesignSystem.Spacing.lg) {
                // Trending Recipes Section
                trendingRecipesSection

                // Popular Hashtags Section
                popularHashtagsSection

                // Recent Cooking Logs Section
                recentLogsSection
            }
            .padding(.vertical, DesignSystem.Spacing.md)
            .safeAreaPadding(.bottom)
        }
    }

    private var trendingRecipesSection: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.sm) {
            // Section header
            HStack {
                HStack(spacing: DesignSystem.Spacing.xs) {
                    Image(systemName: AppIcon.trending)
                        .font(.system(size: DesignSystem.IconSize.md))
                        .foregroundColor(DesignSystem.Colors.primary)
                    Text("Trending Recipes")
                        .font(DesignSystem.Typography.headline)
                        .foregroundColor(DesignSystem.Colors.text)
                }
                Spacer()
                Button {
                    viewModel.showAllRecipes = true
                } label: {
                    HStack(spacing: DesignSystem.Spacing.xxs) {
                        Text("See All")
                            .font(DesignSystem.Typography.subheadline)
                        Image(systemName: "chevron.right")
                            .font(.system(size: DesignSystem.IconSize.xs))
                    }
                    .foregroundColor(DesignSystem.Colors.primary)
                }
            }
            .padding(.horizontal, DesignSystem.Spacing.md)

            // Horizontal scroll of recipe cards
            if viewModel.isLoadingHomeFeed && viewModel.trendingRecipes.isEmpty {
                HStack {
                    Spacer()
                    ProgressView()
                    Spacer()
                }
                .frame(height: 180)
            } else if viewModel.trendingRecipes.isEmpty {
                emptyStateCard(icon: AppIcon.recipe, message: "No recipes yet")
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: DesignSystem.Spacing.sm) {
                        ForEach(viewModel.trendingRecipes) { recipe in
                            NavigationLink(destination: RecipeDetailView(recipeId: recipe.id)) {
                                HorizontalRecipeCard(recipe: recipe)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.horizontal, DesignSystem.Spacing.md)
                }
            }
        }
    }

    private var popularHashtagsSection: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.sm) {
            // Section header
            HStack(spacing: DesignSystem.Spacing.xs) {
                Image(systemName: "number")
                    .font(.system(size: DesignSystem.IconSize.md))
                    .foregroundColor(DesignSystem.Colors.primary)
                Text("Popular Hashtags")
                    .font(DesignSystem.Typography.headline)
                    .foregroundColor(DesignSystem.Colors.text)
            }
            .padding(.horizontal, DesignSystem.Spacing.md)

            // Flow layout hashtag pills
            if viewModel.trendingHashtags.isEmpty {
                emptyStateCard(icon: "number", message: "No hashtags yet")
                    .padding(.horizontal, DesignSystem.Spacing.md)
            } else {
                FlowLayout(spacing: DesignSystem.Spacing.sm) {
                    ForEach(viewModel.trendingHashtags, id: \.name) { hashtag in
                        NavigationLink(destination: HashtagView(hashtag: hashtag.name)) {
                            Text("#\(hashtag.name)")
                                .font(DesignSystem.Typography.subheadline)
                                .foregroundColor(DesignSystem.Colors.primary)
                                .padding(.horizontal, DesignSystem.Spacing.sm)
                                .padding(.vertical, DesignSystem.Spacing.xs)
                                .background(DesignSystem.Colors.primary.opacity(0.1))
                                .cornerRadius(DesignSystem.CornerRadius.full)
                        }
                    }
                }
                .padding(.horizontal, DesignSystem.Spacing.md)
            }
        }
    }

    private var recentLogsSection: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.sm) {
            // Section header
            HStack {
                HStack(spacing: DesignSystem.Spacing.xs) {
                    Image(systemName: AppIcon.log)
                        .font(.system(size: DesignSystem.IconSize.md))
                        .foregroundColor(DesignSystem.Colors.primary)
                    Text("Recent Cooking Logs")
                        .font(DesignSystem.Typography.headline)
                        .foregroundColor(DesignSystem.Colors.text)
                }
                Spacer()
                Button {
                    viewModel.showAllLogs = true
                } label: {
                    HStack(spacing: DesignSystem.Spacing.xxs) {
                        Text("See All")
                            .font(DesignSystem.Typography.subheadline)
                        Image(systemName: "chevron.right")
                            .font(.system(size: DesignSystem.IconSize.xs))
                    }
                    .foregroundColor(DesignSystem.Colors.primary)
                }
            }
            .padding(.horizontal, DesignSystem.Spacing.md)

            // Horizontal scroll of log cards
            if viewModel.isLoadingHomeFeed && viewModel.recentLogs.isEmpty {
                HStack {
                    Spacer()
                    ProgressView()
                    Spacer()
                }
                .frame(height: 180)
            } else if viewModel.recentLogs.isEmpty {
                emptyStateCard(icon: AppIcon.log, message: "No cooking logs yet")
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: DesignSystem.Spacing.sm) {
                        ForEach(viewModel.recentLogs) { log in
                            NavigationLink(destination: LogDetailView(logId: log.id)) {
                                HorizontalLogCard(log: log)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.horizontal, DesignSystem.Spacing.md)
                }
            }
        }
    }

    private func emptyStateCard(icon: String, message: String) -> some View {
        HStack {
            Spacer()
            VStack(spacing: DesignSystem.Spacing.xs) {
                Image(systemName: icon)
                    .font(.system(size: DesignSystem.IconSize.xl))
                    .foregroundColor(DesignSystem.Colors.tertiaryText)
                Text(message)
                    .font(DesignSystem.Typography.caption)
                    .foregroundColor(DesignSystem.Colors.tertiaryText)
            }
            Spacer()
        }
        .frame(height: 120)
        .background(DesignSystem.Colors.secondaryBackground)
        .cornerRadius(DesignSystem.CornerRadius.md)
    }

    // MARK: - Search History View (When Focused)

    private var searchHistoryView: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: DesignSystem.Spacing.lg) {
                if viewModel.recentSearches.isEmpty {
                    VStack(spacing: DesignSystem.Spacing.sm) {
                        Image(systemName: AppIcon.history)
                            .font(.system(size: DesignSystem.IconSize.xxl))
                            .foregroundColor(DesignSystem.Colors.tertiaryText)
                        Text("No recent searches")
                            .font(DesignSystem.Typography.subheadline)
                            .foregroundColor(DesignSystem.Colors.tertiaryText)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.top, DesignSystem.Spacing.xxl)
                } else {
                    VStack(alignment: .leading, spacing: DesignSystem.Spacing.sm) {
                        HStack {
                            Text("Recent Searches")
                                .font(DesignSystem.Typography.headline)
                                .foregroundColor(DesignSystem.Colors.text)
                            Spacer()
                            Button("Clear") {
                                viewModel.clearRecentSearches()
                            }
                            .font(DesignSystem.Typography.subheadline)
                            .foregroundColor(DesignSystem.Colors.primary)
                        }

                        ForEach(viewModel.recentSearches, id: \.self) { search in
                            Button {
                                viewModel.query = search
                                viewModel.search()
                            } label: {
                                HStack {
                                    Image(systemName: AppIcon.history)
                                        .font(.system(size: DesignSystem.IconSize.sm))
                                        .foregroundColor(DesignSystem.Colors.tertiaryText)
                                    Text(search)
                                        .font(DesignSystem.Typography.body)
                                        .foregroundColor(DesignSystem.Colors.text)
                                    Spacer()
                                    Button {
                                        viewModel.removeRecentSearch(search)
                                    } label: {
                                        Image(systemName: AppIcon.close)
                                            .font(.system(size: DesignSystem.IconSize.sm))
                                            .foregroundColor(DesignSystem.Colors.tertiaryText)
                                    }
                                }
                                .padding(.vertical, DesignSystem.Spacing.xs)
                            }
                        }
                    }
                    .padding(DesignSystem.Spacing.md)
                    .background(DesignSystem.Colors.background)
                    .cornerRadius(DesignSystem.CornerRadius.md)
                    .padding(.horizontal, DesignSystem.Spacing.md)
                }
            }
            .padding(.vertical, DesignSystem.Spacing.md)
        }
    }

    // MARK: - See All Views

    private var seeAllRecipesView: some View {
        VStack(spacing: 0) {
            // Back header
            HStack {
                Button {
                    viewModel.showAllRecipes = false
                } label: {
                    HStack(spacing: DesignSystem.Spacing.xs) {
                        Image(systemName: "chevron.left")
                        Text("Back")
                    }
                    .font(DesignSystem.Typography.subheadline)
                    .foregroundColor(DesignSystem.Colors.primary)
                }
                Spacer()
                Text("Trending Recipes")
                    .font(DesignSystem.Typography.headline)
                Spacer()
                // Spacer for balance
                Color.clear.frame(width: 60)
            }
            .padding(.horizontal, DesignSystem.Spacing.md)
            .padding(.vertical, DesignSystem.Spacing.sm)

            List {
                ForEach(viewModel.trendingRecipes) { recipe in
                    NavigationLink(destination: RecipeDetailView(recipeId: recipe.id)) {
                        RecipeCardCompactFromHome(recipe: recipe)
                    }
                }
            }
            .listStyle(.plain)
        }
    }

    private var seeAllLogsView: some View {
        VStack(spacing: 0) {
            // Back header
            HStack {
                Button {
                    viewModel.showAllLogs = false
                } label: {
                    HStack(spacing: DesignSystem.Spacing.xs) {
                        Image(systemName: "chevron.left")
                        Text("Back")
                    }
                    .font(DesignSystem.Typography.subheadline)
                    .foregroundColor(DesignSystem.Colors.primary)
                }
                Spacer()
                Text("Recent Cooking Logs")
                    .font(DesignSystem.Typography.headline)
                Spacer()
                // Spacer for balance
                Color.clear.frame(width: 60)
            }
            .padding(.horizontal, DesignSystem.Spacing.md)
            .padding(.vertical, DesignSystem.Spacing.sm)

            List {
                ForEach(viewModel.recentLogs) { log in
                    NavigationLink(destination: LogDetailView(logId: log.id)) {
                        LogCardCompactFromHome(log: log)
                    }
                }
            }
            .listStyle(.plain)
        }
    }

    // MARK: - Search Results

    private var searchResults: some View {
        VStack(spacing: 0) {
            // Tab bar (icons only)
            HStack(spacing: 0) {
                ForEach(SearchTab.allCases, id: \.self) { tab in
                    Button {
                        selectedTab = tab
                    } label: {
                        VStack(spacing: DesignSystem.Spacing.xxs) {
                            Image(systemName: tab.icon)
                                .font(.system(size: DesignSystem.IconSize.md))
                                .foregroundColor(
                                    selectedTab == tab
                                        ? DesignSystem.Colors.primary
                                        : DesignSystem.Colors.tertiaryText
                                )

                            Circle()
                                .fill(selectedTab == tab ? DesignSystem.Colors.primary : Color.clear)
                                .frame(width: 4, height: 4)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, DesignSystem.Spacing.sm)
                    }
                }
            }
            .background(DesignSystem.Colors.background)
            .cornerRadius(DesignSystem.CornerRadius.md)
            .padding(.horizontal, DesignSystem.Spacing.md)
            .padding(.vertical, DesignSystem.Spacing.xs)

            List {
                switch selectedTab {
                case .all:
                    allResultsSection
                case .recipes:
                    recipesResultsSection
                case .logs:
                    logsResultsSection
                case .users:
                    usersResultsSection
                case .hashtags:
                    hashtagsResultsSection
                }
            }
            .listStyle(.plain)
        }
    }

    @ViewBuilder
    private var allResultsSection: some View {
        if let topResult = viewModel.results.topResult {
            Section("Top Result") {
                searchResultRow(topResult)
            }
        }

        if !viewModel.results.recipes.isEmpty {
            Section("Recipes (\(viewModel.results.recipes.count))") {
                ForEach(viewModel.results.recipes.prefix(3)) { recipe in
                    NavigationLink(destination: RecipeDetailView(recipeId: recipe.id)) {
                        RecipeCardCompact(recipe: recipe)
                    }
                }
            }
        }

        if !viewModel.results.logs.isEmpty {
            Section("Cooking Logs (\(viewModel.results.logs.count))") {
                ForEach(viewModel.results.logs.prefix(3)) { log in
                    NavigationLink(destination: LogDetailView(logId: log.id)) {
                        LogCardCompact(log: log)
                    }
                }
            }
        }

        if !viewModel.results.users.isEmpty {
            Section("Users (\(viewModel.results.users.count))") {
                ForEach(viewModel.results.users.prefix(3)) { user in
                    NavigationLink(destination: ProfileView(userId: user.id)) {
                        UserRow(user: user)
                    }
                }
            }
        }

        if !viewModel.results.hashtags.isEmpty {
            Section("Hashtags") {
                ForEach(viewModel.results.hashtags.prefix(3).map { $0 }, id: \.id) { (hashtag: HashtagCount) in
                    NavigationLink(destination: HashtagView(hashtag: hashtag.name)) {
                        HStack {
                            Text("#\(hashtag.name)").fontWeight(.medium)
                            Spacer()
                            Text("\(hashtag.postCount) posts")
                                .foregroundColor(DesignSystem.Colors.secondaryText)
                        }
                    }
                }
            }
        }
    }

    private var recipesResultsSection: some View {
        ForEach(viewModel.results.recipes) { recipe in
            NavigationLink(destination: RecipeDetailView(recipeId: recipe.id)) {
                RecipeCardCompact(recipe: recipe)
            }
        }
    }

    private var logsResultsSection: some View {
        ForEach(viewModel.results.logs) { log in
            NavigationLink(destination: LogDetailView(logId: log.id)) {
                LogCardCompact(log: log)
            }
        }
    }

    private var usersResultsSection: some View {
        ForEach(viewModel.results.users) { user in
            NavigationLink(destination: ProfileView(userId: user.id)) {
                UserRow(user: user)
            }
        }
    }

    private var hashtagsResultsSection: some View {
        ForEach(viewModel.results.hashtags) { hashtag in
            NavigationLink(destination: HashtagView(hashtag: hashtag.name)) {
                HStack {
                    Text("#\(hashtag.name)").fontWeight(.medium)
                    Spacer()
                    Text("\(hashtag.postCount) posts")
                        .foregroundColor(DesignSystem.Colors.secondaryText)
                }
            }
        }
    }

    @ViewBuilder
    private func searchResultRow(_ result: SearchResult) -> some View {
        switch result {
        case .recipe(let recipe):
            NavigationLink(destination: RecipeDetailView(recipeId: recipe.id)) {
                RecipeCardCompact(recipe: recipe)
            }
        case .log(let log):
            NavigationLink(destination: LogDetailView(logId: log.id)) {
                LogCardCompact(log: log)
            }
        case .user(let user):
            NavigationLink(destination: ProfileView(userId: user.id)) {
                UserRow(user: user)
            }
        case .hashtag(let hashtag):
            NavigationLink(destination: HashtagView(hashtag: hashtag.name)) {
                HStack {
                    Text("#\(hashtag.name)").fontWeight(.medium)
                    Spacer()
                    Text("\(hashtag.postCount) posts")
                        .foregroundColor(DesignSystem.Colors.secondaryText)
                }
            }
        }
    }
}

// MARK: - Horizontal Card Components

struct HorizontalRecipeCard: View {
    let recipe: HomeRecipeItem

    private let cardWidth: CGFloat = 140
    private let cardHeight: CGFloat = 180

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Thumbnail
            AsyncImage(url: URL(string: recipe.thumbnail ?? "")) { image in
                image.resizable().scaledToFill()
            } placeholder: {
                Rectangle().fill(DesignSystem.Colors.secondaryBackground)
            }
            .frame(width: cardWidth, height: 100)
            .clipped()

            // Content
            VStack(alignment: .leading, spacing: DesignSystem.Spacing.xxs) {
                Text(recipe.title)
                    .font(DesignSystem.Typography.subheadline)
                    .fontWeight(.medium)
                    .lineLimit(2)
                    .foregroundColor(DesignSystem.Colors.text)

                Text("@\(recipe.userName)")
                    .font(DesignSystem.Typography.caption)
                    .foregroundColor(DesignSystem.Colors.secondaryText)
                    .lineLimit(1)
            }
            .padding(DesignSystem.Spacing.xs)
        }
        .frame(width: cardWidth, height: cardHeight)
        .background(DesignSystem.Colors.background)
        .cornerRadius(DesignSystem.CornerRadius.md)
        .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
    }
}

struct HorizontalLogCard: View {
    let log: RecentActivityItem

    private let cardWidth: CGFloat = 140
    private let cardHeight: CGFloat = 180

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Thumbnail
            AsyncImage(url: URL(string: log.thumbnailUrl ?? "")) { image in
                image.resizable().scaledToFill()
            } placeholder: {
                Rectangle().fill(DesignSystem.Colors.secondaryBackground)
            }
            .frame(width: cardWidth, height: 100)
            .clipped()

            // Content
            VStack(alignment: .leading, spacing: DesignSystem.Spacing.xxs) {
                StarRating(rating: log.rating)

                Text("@\(log.userName)")
                    .font(DesignSystem.Typography.caption)
                    .foregroundColor(DesignSystem.Colors.secondaryText)
                    .lineLimit(1)

                Text(log.recipeTitle)
                    .font(DesignSystem.Typography.caption2)
                    .foregroundColor(DesignSystem.Colors.tertiaryText)
                    .lineLimit(1)
            }
            .padding(DesignSystem.Spacing.xs)
        }
        .frame(width: cardWidth, height: cardHeight)
        .background(DesignSystem.Colors.background)
        .cornerRadius(DesignSystem.CornerRadius.md)
        .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
    }
}

// MARK: - Compact Cards for See All Views

struct RecipeCardCompactFromHome: View {
    let recipe: HomeRecipeItem

    var body: some View {
        HStack(spacing: DesignSystem.Spacing.sm) {
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

                HStack(spacing: DesignSystem.Spacing.xs) {
                    Text(recipe.foodName)
                        .font(DesignSystem.Typography.caption)
                        .foregroundColor(DesignSystem.Colors.secondaryText)
                    Text("by @\(recipe.userName)")
                        .font(DesignSystem.Typography.caption)
                        .foregroundColor(DesignSystem.Colors.tertiaryText)
                }

                HStack(spacing: DesignSystem.Spacing.md) {
                    if let time = recipe.cookingTimeRange {
                        HStack(spacing: 2) {
                            Image(systemName: AppIcon.timer)
                            Text(time.cookingTimeDisplayText)
                        }
                        .font(DesignSystem.Typography.caption)
                        .foregroundColor(DesignSystem.Colors.secondaryText)
                    }

                    HStack(spacing: 2) {
                        Image(systemName: AppIcon.log)
                        Text("\(recipe.logCount)")
                    }
                    .font(DesignSystem.Typography.caption)
                    .foregroundColor(DesignSystem.Colors.secondaryText)
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

struct LogCardCompactFromHome: View {
    let log: RecentActivityItem

    var body: some View {
        HStack(spacing: DesignSystem.Spacing.sm) {
            AsyncImage(url: URL(string: log.thumbnailUrl ?? "")) { img in
                img.resizable().scaledToFill()
            } placeholder: {
                Rectangle().fill(DesignSystem.Colors.secondaryBackground)
            }
            .frame(width: 80, height: 80)
            .cornerRadius(DesignSystem.CornerRadius.sm)
            .clipped()

            VStack(alignment: .leading, spacing: DesignSystem.Spacing.xxs) {
                Text(log.recipeTitle)
                    .font(DesignSystem.Typography.subheadline)
                    .fontWeight(.medium)
                    .lineLimit(2)
                    .foregroundColor(DesignSystem.Colors.text)

                Text("@\(log.userName)")
                    .font(DesignSystem.Typography.caption)
                    .foregroundColor(DesignSystem.Colors.secondaryText)

                StarRating(rating: log.rating)
            }
            Spacer()
        }
        .padding(DesignSystem.Spacing.sm)
        .background(DesignSystem.Colors.background)
        .cornerRadius(DesignSystem.CornerRadius.md)
        .contentShape(Rectangle())
    }
}

// MARK: - Supporting Views

struct UserRow: View {
    let user: UserSummary

    var body: some View {
        HStack {
            AvatarView(url: user.avatarUrl, size: DesignSystem.AvatarSize.sm)
            VStack(alignment: .leading) {
                Text(user.displayNameOrUsername)
                    .font(DesignSystem.Typography.subheadline)
                    .fontWeight(.medium)
                Text("@\(user.username)")
                    .font(DesignSystem.Typography.caption)
                    .foregroundColor(DesignSystem.Colors.secondaryText)
            }
            Spacer()
        }
        .contentShape(Rectangle())
    }
}

struct LogCardCompact: View {
    let log: CookingLogSummary

    var body: some View {
        HStack {
            AsyncImage(url: URL(string: log.images.first?.thumbnailUrl ?? "")) { img in
                img.resizable().scaledToFill()
            } placeholder: {
                Rectangle().fill(DesignSystem.Colors.secondaryBackground)
            }
            .frame(width: 60, height: 60)
            .cornerRadius(DesignSystem.CornerRadius.sm)
            .clipped()

            VStack(alignment: .leading) {
                Text(log.author.displayNameOrUsername)
                    .font(DesignSystem.Typography.subheadline)
                    .fontWeight(.medium)
                StarRating(rating: log.rating)
            }
            Spacer()
        }
        .contentShape(Rectangle())
    }
}

struct HashtagView: View {
    let hashtag: String
    @State private var selectedTab = 0

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 0) {
                HashtagTabButton(icon: AppIcon.recipe, isSelected: selectedTab == 0) {
                    selectedTab = 0
                }
                HashtagTabButton(icon: AppIcon.log, isSelected: selectedTab == 1) {
                    selectedTab = 1
                }
            }
            .padding(DesignSystem.Spacing.xs)
            .background(DesignSystem.Colors.background)
            .cornerRadius(DesignSystem.CornerRadius.md)
            .padding(.horizontal, DesignSystem.Spacing.md)
            .padding(.vertical, DesignSystem.Spacing.sm)

            Spacer()
        }
        .background(DesignSystem.Colors.secondaryBackground)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .principal) {
                HStack(spacing: DesignSystem.Spacing.xs) {
                    Image(systemName: "number")
                        .foregroundColor(DesignSystem.Colors.primary)
                    Text(hashtag)
                        .font(DesignSystem.Typography.headline)
                }
            }
        }
    }
}

struct HashtagTabButton: View {
    let icon: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: DesignSystem.Spacing.xxs) {
                Image(systemName: icon)
                    .font(.system(size: DesignSystem.IconSize.lg))
                    .foregroundColor(
                        isSelected
                            ? DesignSystem.Colors.primary
                            : DesignSystem.Colors.tertiaryText
                    )
                Circle()
                    .fill(isSelected ? DesignSystem.Colors.primary : Color.clear)
                    .frame(width: 4, height: 4)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, DesignSystem.Spacing.sm)
        }
    }
}

// MARK: - Flow Layout

struct FlowLayout: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let result = calculateLayout(proposal: proposal, subviews: subviews)
        return result.size
    }

    func placeSubviews(
        in bounds: CGRect,
        proposal: ProposedViewSize,
        subviews: Subviews,
        cache: inout ()
    ) {
        let result = calculateLayout(proposal: proposal, subviews: subviews)
        for (index, position) in result.positions.enumerated() {
            subviews[index].place(
                at: CGPoint(x: bounds.minX + position.x, y: bounds.minY + position.y),
                proposal: .unspecified
            )
        }
    }

    private func calculateLayout(
        proposal: ProposedViewSize,
        subviews: Subviews
    ) -> (size: CGSize, positions: [CGPoint]) {
        var positions: [CGPoint] = []
        var currentX: CGFloat = 0
        var currentY: CGFloat = 0
        var lineHeight: CGFloat = 0
        let maxWidth = proposal.width ?? .infinity

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if currentX + size.width > maxWidth && currentX > 0 {
                currentX = 0
                currentY += lineHeight + spacing
                lineHeight = 0
            }
            positions.append(CGPoint(x: currentX, y: currentY))
            lineHeight = max(lineHeight, size.height)
            currentX += size.width + spacing
        }

        return (CGSize(width: maxWidth, height: currentY + lineHeight), positions)
    }
}

#Preview { SearchView() }
