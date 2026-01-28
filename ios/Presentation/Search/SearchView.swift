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

// MARK: - Navigation Destinations
enum SearchNavDestination: Hashable {
    case recipe(id: String)
    case log(id: String)
    case user(id: String)
    case hashtag(name: String)
}

struct SearchView: View {
    @StateObject private var viewModel = SearchViewModel()
    @EnvironmentObject private var appState: AppState
    @State private var selectedTab: SearchTab = .all
    @State private var navigationPath = NavigationPath()
    @FocusState private var isSearchFocused: Bool

    var body: some View {
        NavigationStack(path: $navigationPath) {
            VStack(spacing: 0) {
                if !viewModel.showAllRecipes && !viewModel.showAllLogs {
                    searchBar
                }
                contentView
            }
            .frame(maxHeight: .infinity, alignment: .top)
            .navigationBarHidden(true)
            .navigationDestination(for: SearchNavDestination.self) { destination in
                switch destination {
                case .recipe(let id):
                    RecipeDetailView(recipeId: id)
                case .log(let id):
                    LogDetailView(logId: id)
                case .user(let id):
                    ProfileView(userId: id)
                case .hashtag(let name):
                    HashtagView(hashtag: name)
                }
            }
        }
        .onAppear {
            viewModel.loadRecentSearches()
            viewModel.loadHomeFeed()
        }
        .onReceive(appState.$searchScrollToTopTrigger.dropFirst()) { _ in
            handleScrollToTop()
        }
    }

    private func handleScrollToTop() {
        // Pop to root if navigated
        if !navigationPath.isEmpty {
            navigationPath = NavigationPath()
        }

        // Reset "see all" views if active
        if viewModel.showAllRecipes || viewModel.showAllLogs {
            viewModel.resetSeeAllState()
        }

        // Clear search if active
        if !viewModel.query.isEmpty {
            viewModel.clearSearch()
        }

        // Refresh home feed
        viewModel.loadHomeFeed()
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
        .refreshable {
            viewModel.loadHomeFeed()
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
                            NavigationLink(value: SearchNavDestination.recipe(id: recipe.id)) {
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

            // Wrapping hashtag chips
            if viewModel.trendingHashtags.isEmpty {
                emptyStateCard(icon: "number", message: "No hashtags yet")
                    .padding(.horizontal, DesignSystem.Spacing.md)
            } else {
                FlowLayout(spacing: DesignSystem.Spacing.sm) {
                    ForEach(viewModel.trendingHashtags, id: \.id) { hashtag in
                        NavigationLink(value: SearchNavDestination.hashtag(name: hashtag.name)) {
                            Text("#\(hashtag.name)")
                                .font(DesignSystem.Typography.subheadline)
                                .fontWeight(.medium)
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
                    LogoIconView(size: DesignSystem.IconSize.lg)
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
                emptyStateCardWithLogo(message: "No cooking logs yet")
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: DesignSystem.Spacing.sm) {
                        ForEach(viewModel.recentLogs) { log in
                            NavigationLink(value: SearchNavDestination.log(id: log.id)) {
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

    private func emptyStateCardWithLogo(message: String) -> some View {
        HStack {
            Spacer()
            VStack(spacing: DesignSystem.Spacing.xs) {
                LogoIconView(size: DesignSystem.IconSize.xl)
                    .opacity(0.5)
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

    private func formatCount(_ count: Int) -> String {
        if count >= 1_000_000 {
            return String(format: "%.1fM", Double(count) / 1_000_000)
        } else if count >= 1_000 {
            return String(format: "%.1fK", Double(count) / 1_000)
        } else {
            return "\(count)"
        }
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
        List {
            // Back header as first row
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
            .listRowInsets(EdgeInsets(top: 0, leading: DesignSystem.Spacing.md, bottom: 0, trailing: DesignSystem.Spacing.md))
            .listRowSeparator(.hidden)

            ForEach(viewModel.trendingRecipes) { recipe in
                NavigationLink(value: SearchNavDestination.recipe(id: recipe.id)) {
                    RecipeCardCompactFromHome(recipe: recipe)
                }
            }
        }
        .listStyle(.plain)
        .contentMargins(.bottom, 80, for: .scrollContent)
        .refreshable {
            viewModel.loadHomeFeed()
        }
    }

    private var seeAllLogsView: some View {
        List {
            // Back header as first row
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
            .listRowInsets(EdgeInsets(top: 0, leading: DesignSystem.Spacing.md, bottom: 0, trailing: DesignSystem.Spacing.md))
            .listRowSeparator(.hidden)

            ForEach(viewModel.recentLogs) { log in
                NavigationLink(value: SearchNavDestination.log(id: log.id)) {
                    LogCardCompactFromHome(log: log)
                }
            }
        }
        .listStyle(.plain)
        .contentMargins(.bottom, 80, for: .scrollContent)
        .refreshable {
            viewModel.loadHomeFeed()
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
                            if tab == .logs {
                                LogoIconView(size: DesignSystem.IconSize.md)
                                    .opacity(selectedTab == tab ? 1.0 : 0.4)
                            } else {
                                Image(systemName: tab.icon)
                                    .font(.system(size: DesignSystem.IconSize.md))
                                    .foregroundColor(
                                        selectedTab == tab
                                            ? DesignSystem.Colors.primary
                                            : DesignSystem.Colors.tertiaryText
                                    )
                            }

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
            .contentMargins(.bottom, 80, for: .scrollContent)
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
                    NavigationLink(value: SearchNavDestination.recipe(id: recipe.id)) {
                        RecipeCardCompact(recipe: recipe)
                    }
                }
            }
        }

        if !viewModel.results.logs.isEmpty {
            Section("Cooking Logs (\(viewModel.results.logs.count))") {
                ForEach(viewModel.results.logs.prefix(3)) { log in
                    NavigationLink(value: SearchNavDestination.log(id: log.id)) {
                        LogCardCompact(log: log)
                    }
                }
            }
        }

        if !viewModel.results.users.isEmpty {
            Section("Users (\(viewModel.results.users.count))") {
                ForEach(viewModel.results.users.prefix(3)) { user in
                    NavigationLink(value: SearchNavDestination.user(id: user.id)) {
                        UserRow(user: user)
                    }
                }
            }
        }

        if !viewModel.results.hashtags.isEmpty {
            Section("Hashtags") {
                ForEach(viewModel.results.hashtags.prefix(3).map { $0 }, id: \.id) { (hashtag: HashtagCount) in
                    NavigationLink(value: SearchNavDestination.hashtag(name: hashtag.name)) {
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
            NavigationLink(value: SearchNavDestination.recipe(id: recipe.id)) {
                RecipeCardCompact(recipe: recipe)
            }
        }
    }

    private var logsResultsSection: some View {
        ForEach(viewModel.results.logs) { log in
            NavigationLink(value: SearchNavDestination.log(id: log.id)) {
                LogCardCompact(log: log)
            }
        }
    }

    private var usersResultsSection: some View {
        ForEach(viewModel.results.users) { user in
            NavigationLink(value: SearchNavDestination.user(id: user.id)) {
                UserRow(user: user)
            }
        }
    }

    private var hashtagsResultsSection: some View {
        ForEach(viewModel.results.hashtags) { hashtag in
            NavigationLink(value: SearchNavDestination.hashtag(name: hashtag.name)) {
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
            NavigationLink(value: SearchNavDestination.recipe(id: recipe.id)) {
                RecipeCardCompact(recipe: recipe)
            }
        case .log(let log):
            NavigationLink(value: SearchNavDestination.log(id: log.id)) {
                LogCardCompact(log: log)
            }
        case .user(let user):
            NavigationLink(value: SearchNavDestination.user(id: user.id)) {
                UserRow(user: user)
            }
        case .hashtag(let hashtag):
            NavigationLink(value: SearchNavDestination.hashtag(name: hashtag.name)) {
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
                        LogoIconView(size: 12)
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

enum HashtagContentFilter: String, CaseIterable {
    case all, recipes, logs

    var title: String {
        switch self {
        case .all: return "All"
        case .recipes: return "Recipes"
        case .logs: return "Logs"
        }
    }
}

@MainActor
final class HashtagContentViewModel: ObservableObject {
    @Published private(set) var items: [HashtagContentItem] = []
    @Published private(set) var isLoading = false
    @Published private(set) var cursor: String?
    @Published private(set) var hasNext = false
    @Published private(set) var totalElements: Int?
    @Published var contentFilter: HashtagContentFilter = .all

    private let searchRepository: SearchRepositoryProtocol
    private let hashtag: String

    var filteredItems: [HashtagContentItem] {
        switch contentFilter {
        case .all: return items
        case .recipes: return items.filter { $0.isRecipe }
        case .logs: return items.filter { $0.isLog }
        }
    }

    init(hashtag: String, searchRepository: SearchRepositoryProtocol = SearchRepository()) {
        self.hashtag = hashtag
        self.searchRepository = searchRepository
    }

    func loadContent() {
        guard !isLoading else { return }
        isLoading = true

        Task {
            defer { isLoading = false }
            let result = await searchRepository.getHashtagContent(hashtag: hashtag, type: nil, cursor: nil)
            if case .success(let response) = result {
                items = response.content
                cursor = response.nextCursor
                hasNext = response.hasNext
                totalElements = response.totalElements
            }
        }
    }
}

struct HashtagView: View {
    let hashtag: String
    @StateObject private var viewModel: HashtagContentViewModel

    private let gridColumns = [
        GridItem(.flexible(), spacing: DesignSystem.Spacing.sm),
        GridItem(.flexible(), spacing: DesignSystem.Spacing.sm)
    ]

    init(hashtag: String) {
        self.hashtag = hashtag
        self._viewModel = StateObject(wrappedValue: HashtagContentViewModel(hashtag: hashtag))
    }

    var body: some View {
        VStack(spacing: 0) {
            // Segmented filter picker
            Picker("Filter", selection: $viewModel.contentFilter) {
                ForEach(HashtagContentFilter.allCases, id: \.self) { filter in
                    Text(filter.title).tag(filter)
                }
            }
            .pickerStyle(.segmented)
            .padding(.horizontal, DesignSystem.Spacing.md)
            .padding(.vertical, DesignSystem.Spacing.sm)

            // Content
            if viewModel.isLoading {
                Spacer()
                ProgressView()
                Spacer()
            } else {
                contentGrid
            }
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
                    if !viewModel.items.isEmpty {
                        Text("(\(viewModel.items.count))")
                            .font(DesignSystem.Typography.subheadline)
                            .foregroundColor(DesignSystem.Colors.secondaryText)
                    }
                }
            }
        }
        .onAppear {
            if viewModel.items.isEmpty {
                viewModel.loadContent()
            }
        }
    }

    @ViewBuilder
    private var contentGrid: some View {
        // Calculate height to fill remaining space below picker
        let contentHeight = max(400, UIScreen.main.bounds.height - 200)

        TabView(selection: $viewModel.contentFilter) {
            ForEach(HashtagContentFilter.allCases, id: \.self) { filter in
                filterPageContent(for: filter)
                    .tag(filter)
            }
        }
        .tabViewStyle(.page(indexDisplayMode: .never))
        .frame(height: contentHeight)
    }

    @ViewBuilder
    private func filterPageContent(for filter: HashtagContentFilter) -> some View {
        let items = itemsForFilter(filter)
        if items.isEmpty {
            emptyStateForFilter(filter)
        } else {
            ScrollView {
                LazyVGrid(columns: gridColumns, spacing: DesignSystem.Spacing.md) {
                    ForEach(items) { item in
                        NavigationLink(value: item.isRecipe
                            ? SearchNavDestination.recipe(id: item.id)
                            : SearchNavDestination.log(id: item.id)
                        ) {
                            HashtagContentGridCard(item: item)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, DesignSystem.Spacing.md)
                .padding(.bottom, 100) // Extra padding for tab bar
            }
        }
    }

    private func itemsForFilter(_ filter: HashtagContentFilter) -> [HashtagContentItem] {
        switch filter {
        case .all: return viewModel.items
        case .recipes: return viewModel.items.filter { $0.isRecipe }
        case .logs: return viewModel.items.filter { $0.isLog }
        }
    }

    @ViewBuilder
    private func emptyStateForFilter(_ filter: HashtagContentFilter) -> some View {
        switch filter {
        case .all:
            emptyState(icon: "number", message: "No content with this hashtag")
        case .recipes:
            emptyState(icon: AppIcon.recipe, message: "No recipes with this hashtag")
        case .logs:
            emptyStateWithLogo(message: "No cooking logs with this hashtag")
        }
    }

    private func emptyState(icon: String, message: String) -> some View {
        VStack(spacing: DesignSystem.Spacing.sm) {
            Image(systemName: icon)
                .font(.system(size: DesignSystem.IconSize.xxl))
                .foregroundColor(DesignSystem.Colors.tertiaryText)
            Text(message)
                .font(DesignSystem.Typography.subheadline)
                .foregroundColor(DesignSystem.Colors.tertiaryText)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private func emptyStateWithLogo(message: String) -> some View {
        VStack(spacing: DesignSystem.Spacing.sm) {
            LogoIconView(size: DesignSystem.IconSize.xxl)
                .opacity(0.5)
            Text(message)
                .font(DesignSystem.Typography.subheadline)
                .foregroundColor(DesignSystem.Colors.tertiaryText)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

struct HashtagTabButton: View {
    let icon: String?
    var useLogoIcon: Bool = false
    let isSelected: Bool
    let action: () -> Void

    init(icon: String, isSelected: Bool, action: @escaping () -> Void) {
        self.icon = icon
        self.useLogoIcon = false
        self.isSelected = isSelected
        self.action = action
    }

    init(useLogoIcon: Bool, isSelected: Bool, action: @escaping () -> Void) {
        self.icon = nil
        self.useLogoIcon = useLogoIcon
        self.isSelected = isSelected
        self.action = action
    }

    var body: some View {
        Button(action: action) {
            VStack(spacing: DesignSystem.Spacing.xxs) {
                if useLogoIcon {
                    LogoIconView(size: DesignSystem.IconSize.lg)
                        .opacity(isSelected ? 1.0 : 0.4)
                } else if let icon = icon {
                    Image(systemName: icon)
                        .font(.system(size: DesignSystem.IconSize.lg))
                        .foregroundColor(
                            isSelected
                                ? DesignSystem.Colors.primary
                                : DesignSystem.Colors.tertiaryText
                        )
                }
                Circle()
                    .fill(isSelected ? DesignSystem.Colors.primary : Color.clear)
                    .frame(width: 4, height: 4)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, DesignSystem.Spacing.sm)
        }
    }
}

#Preview { SearchView().environmentObject(AppState()) }
