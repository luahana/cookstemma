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
                // Search bar
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(DesignSystem.Colors.secondaryText)
                    TextField("Search recipes, logs, users", text: $viewModel.query)
                        .focused($isSearchFocused)
                        .submitLabel(.search)
                        .onSubmit { viewModel.search() }
                    if !viewModel.query.isEmpty {
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

                if viewModel.query.isEmpty {
                    // Pre-search content
                    preSearchContent
                } else if viewModel.isSearching {
                    LoadingView()
                } else {
                    // Search results
                    searchResults
                }
            }
            .navigationTitle("Search")
            .navigationBarTitleDisplayMode(.inline)
        }
        .onAppear { viewModel.loadRecentSearches() }
    }

    private var preSearchContent: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: DesignSystem.Spacing.lg) {
                // Recent searches (icon header)
                if !viewModel.recentSearches.isEmpty {
                    VStack(alignment: .leading, spacing: DesignSystem.Spacing.sm) {
                        HStack {
                            // Icon header
                            Image(systemName: AppIcon.history)
                                .font(.system(size: DesignSystem.IconSize.md))
                                .foregroundColor(DesignSystem.Colors.primary)
                            Spacer()
                            // Clear button (icon)
                            Button { viewModel.clearRecentSearches() } label: {
                                Image(systemName: AppIcon.trash)
                                    .foregroundColor(DesignSystem.Colors.tertiaryText)
                            }
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
                                        .foregroundColor(DesignSystem.Colors.text)
                                    Spacer()
                                    Button { viewModel.removeRecentSearch(search) } label: {
                                        Image(systemName: AppIcon.close)
                                            .font(.system(size: DesignSystem.IconSize.sm))
                                            .foregroundColor(DesignSystem.Colors.tertiaryText)
                                    }
                                }
                            }
                        }
                    }
                    .padding(DesignSystem.Spacing.md)
                    .background(DesignSystem.Colors.background)
                    .cornerRadius(DesignSystem.CornerRadius.md)
                    .padding(.horizontal)
                }

                // Trending hashtags (icon header)
                VStack(alignment: .leading, spacing: DesignSystem.Spacing.sm) {
                    // Icon header
                    Image(systemName: AppIcon.trending)
                        .font(.system(size: DesignSystem.IconSize.lg))
                        .foregroundColor(DesignSystem.Colors.primary)

                    FlowLayout(spacing: DesignSystem.Spacing.sm) {
                        ForEach(viewModel.trendingHashtags, id: \.name) { hashtag in
                            NavigationLink(destination: HashtagView(hashtag: hashtag.name)) {
                                Text("#\(hashtag.name)")
                                    .font(DesignSystem.Typography.subheadline)
                                    .padding(.horizontal, DesignSystem.Spacing.sm)
                                    .padding(.vertical, DesignSystem.Spacing.xs)
                                    .background(DesignSystem.Colors.primary.opacity(0.1))
                                    .cornerRadius(DesignSystem.CornerRadius.sm)
                            }
                        }
                    }
                }
                .padding(DesignSystem.Spacing.md)
                .background(DesignSystem.Colors.background)
                .cornerRadius(DesignSystem.CornerRadius.md)
                .padding(.horizontal)

                // Popular hashtags (icon header)
                VStack(alignment: .leading, spacing: DesignSystem.Spacing.sm) {
                    // Icon header
                    Image(systemName: "number")
                        .font(.system(size: DesignSystem.IconSize.lg))
                        .foregroundColor(DesignSystem.Colors.primary)

                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: DesignSystem.Spacing.sm) {
                        ForEach(viewModel.popularHashtags, id: \.name) { hashtag in
                            NavigationLink(destination: HashtagView(hashtag: hashtag.name)) {
                                HStack {
                                    Text("#\(hashtag.name)")
                                        .fontWeight(.medium)
                                    Spacer()
                                    Text("\(hashtag.postCount.abbreviated)")
                                        .foregroundColor(DesignSystem.Colors.secondaryText)
                                }
                                .font(DesignSystem.Typography.subheadline)
                                .padding(DesignSystem.Spacing.sm)
                                .background(DesignSystem.Colors.tertiaryBackground)
                                .cornerRadius(DesignSystem.CornerRadius.sm)
                            }
                        }
                    }
                }
                .padding(DesignSystem.Spacing.md)
                .background(DesignSystem.Colors.background)
                .cornerRadius(DesignSystem.CornerRadius.md)
                .padding(.horizontal)
            }
            .padding(.vertical)
            .safeAreaPadding(.bottom)
        }
    }

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
                                .foregroundColor(selectedTab == tab ? DesignSystem.Colors.primary : DesignSystem.Colors.tertiaryText)

                            // Selection indicator
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

            // Results
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
                            Text("\(hashtag.postCount) posts").foregroundColor(DesignSystem.Colors.secondaryText)
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
                    Text("\(hashtag.postCount) posts").foregroundColor(DesignSystem.Colors.secondaryText)
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
                    Text("\(hashtag.postCount) posts").foregroundColor(DesignSystem.Colors.secondaryText)
                }
            }
        }
    }
}

// MARK: - Supporting Views
struct UserRow: View {
    let user: UserSummary

    var body: some View {
        HStack {
            AvatarView(url: user.avatarUrl, size: DesignSystem.AvatarSize.sm)
            VStack(alignment: .leading) {
                Text(user.displayNameOrUsername).font(DesignSystem.Typography.subheadline).fontWeight(.medium)
                Text("@\(user.username)").font(DesignSystem.Typography.caption).foregroundColor(DesignSystem.Colors.secondaryText)
            }
            Spacer()
        }
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
                Text(log.author.displayNameOrUsername).font(DesignSystem.Typography.subheadline).fontWeight(.medium)
                StarRating(rating: log.rating)
            }
            Spacer()
        }
    }
}

struct HashtagView: View {
    let hashtag: String
    @State private var selectedTab = 0

    var body: some View {
        VStack(spacing: 0) {
            // Icon tab selector
            HStack(spacing: 0) {
                HashtagTabButton(icon: AppIcon.recipe, isSelected: selectedTab == 0) { selectedTab = 0 }
                HashtagTabButton(icon: AppIcon.log, isSelected: selectedTab == 1) { selectedTab = 1 }
            }
            .padding(DesignSystem.Spacing.xs)
            .background(DesignSystem.Colors.background)
            .cornerRadius(DesignSystem.CornerRadius.md)
            .padding(.horizontal, DesignSystem.Spacing.md)
            .padding(.vertical, DesignSystem.Spacing.sm)

            // Content would be loaded here
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
                    .foregroundColor(isSelected ? DesignSystem.Colors.primary : DesignSystem.Colors.tertiaryText)
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

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = calculateLayout(proposal: proposal, subviews: subviews)
        for (index, position) in result.positions.enumerated() {
            subviews[index].place(at: CGPoint(x: bounds.minX + position.x, y: bounds.minY + position.y), proposal: .unspecified)
        }
    }

    private func calculateLayout(proposal: ProposedViewSize, subviews: Subviews) -> (size: CGSize, positions: [CGPoint]) {
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
