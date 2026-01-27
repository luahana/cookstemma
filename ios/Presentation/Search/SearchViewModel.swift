import Foundation
import Combine

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
    private var cancellables = Set<AnyCancellable>()
    private let debounceInterval: TimeInterval = 0.3

    init(
        searchRepository: SearchRepositoryProtocol = SearchRepository(),
        logRepository: CookingLogRepositoryProtocol = CookingLogRepository()
    ) {
        self.searchRepository = searchRepository
        self.logRepository = logRepository
        setupDebounce()
    }

    private func setupDebounce() {
        $query
            .debounce(for: .seconds(debounceInterval), scheduler: DispatchQueue.main)
            .removeDuplicates()
            .sink { [weak self] query in
                guard let self = self, !query.isEmpty else { return }
                self.search()
            }
            .store(in: &cancellables)
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
            defer { isLoadingHomeFeed = false }

            let result = await logRepository.getHomeFeed()
            if case .success(let feed) = result {
                trendingRecipes = feed.recentRecipes
                recentLogs = feed.recentActivity
            }
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
            return
        }

        isSearching = true
        searchTask = Task {
            let result = await searchRepository.search(query: query, type: nil, cursor: nil)

            guard !Task.isCancelled else { return }

            isSearching = false
            switch result {
            case .success(let response):
                results = UISearchResults(
                    topResult: determineTopResult(response),
                    recipes: response.recipes,
                    logs: response.logs,
                    users: response.users,
                    hashtags: response.hashtags
                )
                saveRecentSearch(query)
            case .failure:
                results = .empty
            }
        }
    }

    private func determineTopResult(_ response: SearchResponse) -> SearchResult? {
        // Return the most relevant result based on type and relevance
        if let recipe = response.recipes.first {
            return .recipe(recipe)
        } else if let log = response.logs.first {
            return .log(log)
        } else if let user = response.users.first {
            return .user(user)
        }
        return nil
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
