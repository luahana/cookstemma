import Foundation
import SwiftUI
import Combine

enum ProfileState: Equatable { case idle, loading, loaded, error(String) }
enum ProfileTab: String, CaseIterable { case recipes, logs, saved }
enum VisibilityFilter: String, CaseIterable {
    case all, publicOnly, privateOnly

    var title: String {
        switch self {
        case .all: return String(localized: "filter.all")
        case .publicOnly: return String(localized: "filter.public")
        case .privateOnly: return String(localized: "filter.private")
        }
    }
}

enum SavedContentFilter: String, CaseIterable {
    case all, recipes, logs

    var title: String {
        switch self {
        case .all: return String(localized: "filter.all")
        case .recipes: return String(localized: "profile.recipes")
        case .logs: return String(localized: "profile.logs")
        }
    }
}

@MainActor
final class ProfileViewModel: ObservableObject {
    @Published private(set) var state: ProfileState = .idle
    @Published private(set) var profile: UserProfile?
    @Published private(set) var myProfile: MyProfile?
    @Published private(set) var isOwnProfile: Bool
    @Published private(set) var recipes: [RecipeSummary] = []
    @Published private(set) var logs: [FeedLogItem] = []
    @Published private(set) var savedRecipes: [RecipeSummary] = []
    @Published private(set) var savedLogs: [FeedLogItem] = []
    @Published private(set) var isLoadingContent = false
    @Published private(set) var hasMoreRecipes = true
    @Published private(set) var hasMoreLogs = true
    @Published private(set) var hasMoreSavedRecipes = true
    @Published private(set) var hasMoreSavedLogs = true
    @Published var selectedTab: ProfileTab = .recipes
    @Published var visibilityFilter: VisibilityFilter = .all
    @Published var savedContentFilter: SavedContentFilter = .all

    private let userId: String?
    private let userRepository: UserRepositoryProtocol
    private let logRepository: CookingLogRepositoryProtocol
    private let savedContentRepository: SavedContentRepositoryProtocol
    private var recipesNextCursor: String?
    private var logsNextCursor: String?
    private var savedRecipesNextCursor: String?
    private var savedLogsNextCursor: String?
    private var cancellables = Set<AnyCancellable>()
    private var savedContentNeedsRefresh = false
    @Published private var savedCountAdjustment = 0

    init(
        userId: String? = nil,
        userRepository: UserRepositoryProtocol = UserRepository(),
        logRepository: CookingLogRepositoryProtocol = CookingLogRepository(),
        savedContentRepository: SavedContentRepositoryProtocol = SavedContentRepository()
    ) {
        self.userId = userId
        self.userRepository = userRepository
        self.logRepository = logRepository
        self.savedContentRepository = savedContentRepository
        self.isOwnProfile = userId == nil
        setupSaveStateObserver()
    }

    private func setupSaveStateObserver() {
        // Listen for recipe save state changes
        NotificationCenter.default.publisher(for: .recipeSaveStateChanged)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] notification in
                guard let self = self, self.isOwnProfile else { return }
                guard let recipeId = notification.userInfo?["recipeId"] as? String,
                      let isSaved = notification.userInfo?["isSaved"] as? Bool else { return }

                #if DEBUG
                print("[Profile] Recipe save state changed: \(recipeId), isSaved=\(isSaved)")
                #endif

                if isSaved {
                    // Recipe was saved - update count and add to list directly if data provided
                    self.savedCountAdjustment += 1
                    if let summary = notification.userInfo?["recipeSummary"] as? RecipeSummary {
                        // Add directly to the list (prepend since it's the newest)
                        if !self.savedRecipes.contains(where: { $0.id == summary.id }) {
                            self.savedRecipes.insert(summary, at: 0)
                        }
                    } else {
                        // Fallback: mark for refresh on next tab visit
                        self.savedContentNeedsRefresh = true
                    }
                } else {
                    // Recipe was unsaved - update count and remove from list immediately
                    self.savedCountAdjustment -= 1
                    self.savedRecipes = self.savedRecipes.filter { $0.id != recipeId }
                }
            }
            .store(in: &cancellables)

        // Listen for log save state changes
        NotificationCenter.default.publisher(for: .logSaveStateChanged)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] notification in
                guard let self = self, self.isOwnProfile else { return }
                guard let logId = notification.userInfo?["logId"] as? String,
                      let isSaved = notification.userInfo?["isSaved"] as? Bool else { return }

                #if DEBUG
                print("[Profile] Log save state changed: \(logId), isSaved=\(isSaved)")
                #endif

                if isSaved {
                    // Log was saved - update count and add to list directly if data provided
                    self.savedCountAdjustment += 1
                    if let feedLogItem = notification.userInfo?["feedLogItem"] as? FeedLogItem {
                        // Add directly to the list (prepend since it's the newest)
                        if !self.savedLogs.contains(where: { $0.id == feedLogItem.id }) {
                            self.savedLogs.insert(feedLogItem, at: 0)
                        }
                    } else {
                        // Fallback: mark for refresh on next tab visit
                        self.savedContentNeedsRefresh = true
                    }
                } else {
                    // Log was unsaved - update count and remove from list immediately
                    self.savedCountAdjustment -= 1
                    self.savedLogs = self.savedLogs.filter { $0.id != logId }
                }
            }
            .store(in: &cancellables)
    }

    func loadProfile() {
        state = .loading
        Task {
            if isOwnProfile { await loadMyProfile() }
            else if let id = userId { await loadUserProfile(id) }
        }
    }

    func loadContent() {
        #if DEBUG
        print("[Profile] loadContent called for tab: \(selectedTab), needsRefresh=\(savedContentNeedsRefresh)")
        #endif
        Task {
            switch selectedTab {
            case .recipes: await loadRecipes(refresh: true)
            case .logs: await loadLogs(refresh: true)
            case .saved:
                await loadSavedContent(refresh: true)
                savedContentNeedsRefresh = false
            }
        }
    }

    var savedCount: Int {
        max(0, (myProfile?.savedCount ?? 0) + savedCountAdjustment)
    }

    func toggleFollow() async {
        guard let profile = profile, !isOwnProfile else { return }
        let wasFollowing = profile.isFollowing
        updateFollowState(!wasFollowing)
        let result = wasFollowing ? await userRepository.unfollow(userId: profile.id) : await userRepository.follow(userId: profile.id)
        if case .failure = result { updateFollowState(wasFollowing) }
    }

    func blockUser() async {
        guard let profile = profile else { return }
        let result = await userRepository.blockUser(userId: profile.id)
        if case .success = result {
            self.profile = UserProfile(
                id: profile.id,
                username: profile.username,
                displayName: profile.displayName,
                avatarUrl: profile.avatarUrl,
                bio: profile.bio,
                level: profile.level,
                levelName: profile.levelName,
                recipeCount: profile.recipeCount,
                logCount: profile.logCount,
                followerCount: profile.followerCount,
                followingCount: profile.followingCount,
                youtubeUrl: profile.youtubeUrl,
                instagramHandle: profile.instagramHandle,
                isFollowing: false,
                isFollowedBy: profile.isFollowedBy,
                isBlocked: true,
                createdAt: profile.createdAt
            )
        }
    }

    func reportUser(reason: ReportReason) async {
        guard let profile = profile else { return }
        let result = await userRepository.reportUser(userId: profile.id, reason: reason)
        #if DEBUG
        if case .success = result {
            print("[Profile] Reported user \(profile.id) for: \(reason.rawValue)")
        }
        #endif
    }

    private func loadMyProfile() async {
        let result = await userRepository.getMyProfile()
        switch result {
        case .success(let profile):
            myProfile = profile
            savedCountAdjustment = 0  // Reset adjustment since API has accurate count
            state = .loaded
            loadContent()
        case .failure(let error):
            state = .error(error.localizedDescription)
        }
    }

    private func loadUserProfile(_ id: String) async {
        let result = await userRepository.getUserProfile(id: id)
        switch result {
        case .success(let profile): self.profile = profile; state = .loaded; loadContent()
        case .failure(let error): state = .error(error.localizedDescription)
        }
    }

    private func loadRecipes(refresh: Bool) async {
        guard let id = userId ?? myProfile?.id else { return }
        isLoadingContent = true
        defer { isLoadingContent = false }
        let result = await userRepository.getUserRecipes(userId: id, cursor: refresh ? nil : recipesNextCursor)
        if case .success(let response) = result {
            recipes = refresh ? response.content : recipes + response.content
            recipesNextCursor = response.nextCursor
            hasMoreRecipes = response.hasMore
        }
    }

    private func loadLogs(refresh: Bool) async {
        guard let id = userId ?? myProfile?.id else { return }
        isLoadingContent = true
        defer { isLoadingContent = false }
        let result = await logRepository.getUserLogs(userId: id, cursor: refresh ? nil : logsNextCursor)
        if case .success(let response) = result {
            logs = refresh ? response.content : logs + response.content
            logsNextCursor = response.nextCursor
            hasMoreLogs = response.hasMore
        }
    }

    private func updateFollowState(_ isFollowing: Bool) {
        guard let p = profile else { return }
        profile = UserProfile(
            id: p.id,
            username: p.username,
            displayName: p.displayName,
            avatarUrl: p.avatarUrl,
            bio: p.bio,
            level: p.level,
            levelName: p.levelName,
            recipeCount: p.recipeCount,
            logCount: p.logCount,
            followerCount: p.followerCount + (isFollowing ? 1 : -1),
            followingCount: p.followingCount,
            youtubeUrl: p.youtubeUrl,
            instagramHandle: p.instagramHandle,
            isFollowing: isFollowing,
            isFollowedBy: p.isFollowedBy,
            isBlocked: p.isBlocked,
            createdAt: p.createdAt
        )
    }

    private func loadSavedContent(refresh: Bool) async {
        guard isOwnProfile else { return }
        isLoadingContent = true
        defer { isLoadingContent = false }

        #if DEBUG
        print("[Profile] Loading saved content, refresh=\(refresh)")
        #endif

        // Load both saved recipes and logs in parallel
        async let recipesTask = savedContentRepository.getSavedRecipes(
            cursor: refresh ? nil : savedRecipesNextCursor
        )
        async let logsTask = savedContentRepository.getSavedLogs(
            cursor: refresh ? nil : savedLogsNextCursor
        )

        let recipesResult = await recipesTask
        let logsResult = await logsTask

        switch recipesResult {
        case .success(let response):
            #if DEBUG
            print("[Profile] Saved recipes loaded: \(response.content.count) items")
            for recipe in response.content.prefix(3) {
                print("[Profile]   - \(recipe.title): thumbnail=\(recipe.thumbnail ?? "nil")")
            }
            #endif
            savedRecipes = refresh ? response.content : savedRecipes + response.content
            savedRecipesNextCursor = response.nextCursor
            hasMoreSavedRecipes = response.hasMore
        case .failure(let error):
            #if DEBUG
            print("[Profile] Failed to load saved recipes: \(error)")
            #endif
        }

        switch logsResult {
        case .success(let response):
            #if DEBUG
            print("[Profile] Saved logs loaded: \(response.content.count) items")
            for log in response.content.prefix(3) {
                print("[Profile]   - \(log.id): thumbnail=\(log.thumbnailUrl ?? "nil")")
            }
            #endif
            savedLogs = refresh ? response.content : savedLogs + response.content
            savedLogsNextCursor = response.nextCursor
            hasMoreSavedLogs = response.hasMore
        case .failure(let error):
            #if DEBUG
            print("[Profile] Failed to load saved logs: \(error)")
            #endif
        }
    }

    func loadMoreContent() {
        Task {
            switch selectedTab {
            case .recipes: await loadRecipes(refresh: false)
            case .logs: await loadLogs(refresh: false)
            case .saved: await loadSavedContent(refresh: false)
            }
        }
    }

    /// Refresh saved content (called when saved tab appears)
    func refreshSavedContentIfNeeded() async {
        guard isOwnProfile, !isLoadingContent else { return }
        
        #if DEBUG
        print("[Profile] refreshSavedContentIfNeeded: forcing refresh")
        #endif
        
        // Always refresh to ensure we have the latest saved content
        await loadSavedContent(refresh: true)
        savedContentNeedsRefresh = false
    }

    /// Reset all state (called when user changes)
    func reset() {
        #if DEBUG
        print("[Profile] Resetting profile state")
        #endif
        state = .idle
        profile = nil
        myProfile = nil
        recipes = []
        logs = []
        savedRecipes = []
        savedLogs = []
        recipesNextCursor = nil
        logsNextCursor = nil
        savedRecipesNextCursor = nil
        savedLogsNextCursor = nil
        hasMoreRecipes = true
        hasMoreLogs = true
        hasMoreSavedRecipes = true
        hasMoreSavedLogs = true
        selectedTab = .recipes
        savedCountAdjustment = 0
        savedContentNeedsRefresh = false
    }
}
