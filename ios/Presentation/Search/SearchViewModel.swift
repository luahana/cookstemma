import Foundation

struct UISearchResults {
    var topResult: SearchResult?
    var recipes: [RecipeSummary] = []
    var logs: [CookingLogSummary] = []
    var users: [UserSummary] = []
    var hashtags: [HashtagCount] = []

    static let empty = UISearchResults()
}

@MainActor
final class SearchViewModel: ObservableObject {
    @Published var query: String = ""
    @Published private(set) var results: UISearchResults = .empty
    @Published private(set) var isSearching = false
    @Published private(set) var nextCursor: String?
    @Published private(set) var recentSearches: [String] = []
    @Published private(set) var trendingHashtags: [HashtagCount] = []
    @Published private(set) var popularHashtags: [HashtagCount] = []

    // Home feed data for default view
    @Published private(set) var trendingRecipes: [HomeRecipeItem] = []
    @Published private(set) var recentLogs: [RecentActivityItem] = []
    @Published private(set) var isLoadingHomeFeed = false

    // "See All" view states
    @Published var showAllRecipes = false
    @Published var showAllLogs = false

    private let searchRepository: SearchRepositoryProtocol
    private let logRepository: CookingLogRepositoryProtocol
    private var searchTask: Task<Void, Never>?

    init(
        searchRepository: SearchRepositoryProtocol = SearchRepository(),
        logRepository: CookingLogRepositoryProtocol = CookingLogRepository()
    ) {
        self.searchRepository = searchRepository
        self.logRepository = logRepository
    }

    func loadRecentSearches() {
        recentSearches = UserDefaults.standard.stringArray(forKey: "recentSearches") ?? []
        loadTrendingHashtags()
    }

    private func loadTrendingHashtags() {
        Task {
            let result = await searchRepository.getTrendingHashtags()
            if case .success(let hashtags) = result {
                trendingHashtags = Array(hashtags.prefix(8))
                popularHashtags = Array(hashtags.prefix(10))
            }
        }
    }

    func loadHomeFeed() {
        guard !isLoadingHomeFeed else { return }
        isLoadingHomeFeed = true

        Task {
            await performLoadHomeFeed()
        }
    }

    func refreshHomeFeed() async {
        await performLoadHomeFeed()
    }

    private func performLoadHomeFeed() async {
        defer { isLoadingHomeFeed = false }

        let result = await logRepository.getHomeFeed()
        if case .success(let feed) = result {
            trendingRecipes = feed.recentRecipes
            recentLogs = feed.recentActivity
        }
    }

    func resetSeeAllState() {
        showAllRecipes = false
        showAllLogs = false
    }

    func search() {
        searchTask?.cancel()
        guard !query.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            results = .empty
            nextCursor = nil
            return
        }

        isSearching = true
        searchTask = Task {
            let result = await searchRepository.search(query: query, type: nil, cursor: nil, size: 20)

            guard !Task.isCancelled else { return }

            isSearching = false
            switch result {
            case .success(let response):
                results = transformResponse(response)
                nextCursor = response.nextCursor
                saveRecentSearch(query)
            case .failure:
                results = .empty
                nextCursor = nil
            }
        }
    }

    private func transformResponse(_ response: UnifiedSearchResponse) -> UISearchResults {
        var recipes: [RecipeSummary] = []
        var logs: [CookingLogSummary] = []
        var hashtags: [HashtagCount] = []

        for item in response.content {
            switch item.data {
            case .recipe(let recipe):
                recipes.append(recipe)
            case .log(let log):
                // Transform LogPostSummaryResponse to CookingLogSummary
                let recipe: RecipeSummary? = log.recipeTitle.map { title in
                    RecipeSummary(
                        id: "",
                        title: title,
                        description: nil,
                        foodName: log.foodName ?? "",
                        cookingStyle: nil,
                        userName: "",
                        thumbnail: nil,
                        variantCount: 0,
                        logCount: 0,
                        servings: nil,
                        cookingTimeRange: nil,
                        hashtags: [],
                        isPrivate: false
                    )
                }
                let logSummary = CookingLogSummary(
                    id: log.id,
                    rating: log.rating ?? 0,
                    content: log.content,
                    images: log.thumbnailUrl.map { [ImageInfo(id: log.id, url: $0, thumbnailUrl: $0, width: nil, height: nil)] } ?? [],
                    author: UserSummary(id: log.creatorPublicId ?? "", username: log.userName, displayName: nil, avatarUrl: nil, level: 0, isFollowing: nil),
                    recipe: recipe,
                    likeCount: 0,
                    commentCount: log.commentCount ?? 0,
                    isLiked: false,
                    isSaved: false,
                    createdAt: Date()
                )
                logs.append(logSummary)
            case .hashtag(let hashtag):
                hashtags.append(HashtagCount(id: hashtag.id, name: hashtag.name, postCount: hashtag.totalCount))
            case .user:
                break // Users handled separately in searchUsers
            case .unknown:
                break
            }
        }

        // Determine top result from first item
        let topResult: SearchResult? = response.content.first.flatMap { item in
            switch item.data {
            case .recipe(let recipe): return .recipe(recipe)
            case .log(let log):
                let recipe: RecipeSummary? = log.recipeTitle.map { title in
                    RecipeSummary(
                        id: "",
                        title: title,
                        description: nil,
                        foodName: log.foodName ?? "",
                        cookingStyle: nil,
                        userName: "",
                        thumbnail: nil,
                        variantCount: 0,
                        logCount: 0,
                        servings: nil,
                        cookingTimeRange: nil,
                        hashtags: [],
                        isPrivate: false
                    )
                }
                let logSummary = CookingLogSummary(
                    id: log.id,
                    rating: log.rating ?? 0,
                    content: log.content,
                    images: log.thumbnailUrl.map { [ImageInfo(id: log.id, url: $0, thumbnailUrl: $0, width: nil, height: nil)] } ?? [],
                    author: UserSummary(id: log.creatorPublicId ?? "", username: log.userName, displayName: nil, avatarUrl: nil, level: 0, isFollowing: nil),
                    recipe: recipe,
                    likeCount: 0,
                    commentCount: log.commentCount ?? 0,
                    isLiked: false,
                    isSaved: false,
                    createdAt: Date()
                )
                return .log(logSummary)
            case .hashtag(let hashtag):
                return .hashtag(HashtagCount(id: hashtag.id, name: hashtag.name, postCount: hashtag.totalCount))
            case .user(let user):
                return .user(user)
            case .unknown:
                return nil
            }
        }

        return UISearchResults(
            topResult: topResult,
            recipes: recipes,
            logs: logs,
            users: [],
            hashtags: hashtags
        )
    }

    private func saveRecentSearch(_ search: String) {
        var searches = recentSearches
        searches.removeAll { $0.lowercased() == search.lowercased() }
        searches.insert(search, at: 0)
        searches = Array(searches.prefix(10))
        recentSearches = searches
        UserDefaults.standard.set(searches, forKey: "recentSearches")
    }

    func clearSearch() {
        query = ""
        results = .empty
        nextCursor = nil
        searchTask?.cancel()
    }

    func removeRecentSearch(_ search: String) {
        recentSearches.removeAll { $0 == search }
        UserDefaults.standard.set(recentSearches, forKey: "recentSearches")
    }

    func clearRecentSearches() {
        recentSearches = []
        UserDefaults.standard.removeObject(forKey: "recentSearches")
    }
}
