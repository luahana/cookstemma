import Foundation
import Combine

enum HomeFeedState: Equatable {
    case idle, loading, loaded, error(String), empty
}

@MainActor
final class HomeFeedViewModel: ObservableObject {
    @Published private(set) var state: HomeFeedState = .idle
    @Published private(set) var feedItems: [FeedLogItem] = []
    @Published private(set) var isLoadingMore = false

    private let logRepository: CookingLogRepositoryProtocol
    private var loadTask: Task<Void, Never>?
    private var nextCursor: String?
    private var hasMore = true
    private let pageSize = 20

    init(logRepository: CookingLogRepositoryProtocol = CookingLogRepository()) {
        self.logRepository = logRepository
    }

    func loadFeed() {
        guard state != .loading else { return }
        loadTask?.cancel()
        state = .loading
        feedItems = []
        nextCursor = nil
        hasMore = true
        loadTask = Task { await performLoad(isRefresh: true) }
    }

    func refresh() async {
        // Don't clear feedItems here - keep showing existing content during refresh
        // Items will be replaced when new data arrives in performLoad
        nextCursor = nil
        hasMore = true
        await performLoad(isRefresh: true)
    }

    func loadMoreIfNeeded(currentItem: FeedLogItem) {
        guard !isLoadingMore, hasMore else { return }

        // Load more when reaching the last 3 items
        let thresholdIndex = feedItems.index(feedItems.endIndex, offsetBy: -3, limitedBy: feedItems.startIndex) ?? feedItems.startIndex
        if let currentIndex = feedItems.firstIndex(where: { $0.id == currentItem.id }),
           currentIndex >= thresholdIndex {
            Task { await loadMore() }
        }
    }

    private func loadMore() async {
        guard !isLoadingMore, hasMore else { return }
        isLoadingMore = true
        await performLoad(isRefresh: false)
        isLoadingMore = false
    }

    private func performLoad(isRefresh: Bool) async {
        guard !Task.isCancelled else { return }

        let cursor = isRefresh ? nil : nextCursor
        let result = await logRepository.getFeed(cursor: cursor, size: pageSize)
        guard !Task.isCancelled else { return }

        switch result {
        case .success(let response):
            #if DEBUG
            print("[HomeFeed] Success: \(response.content.count) items, hasMore: \(response.hasMore)")
            #endif
            if isRefresh {
                feedItems = response.content
            } else {
                feedItems.append(contentsOf: response.content)
            }
            nextCursor = response.nextCursor
            hasMore = response.hasMore

            if feedItems.isEmpty {
                state = .empty
            } else {
                state = .loaded
            }
        case .failure(let error):
            #if DEBUG
            print("[HomeFeed] Error: \(error)")
            #endif
            if isRefresh {
                state = .error(error.localizedDescription)
            }
        }
    }
}
