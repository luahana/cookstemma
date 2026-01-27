import Foundation

enum ProfileState: Equatable { case idle, loading, loaded, error(String) }
enum ProfileTab: String, CaseIterable { case recipes, logs, saved }
enum VisibilityFilter: String, CaseIterable {
    case all, publicOnly, privateOnly

    var title: String {
        switch self {
        case .all: return "All"
        case .publicOnly: return "Public"
        case .privateOnly: return "Private"
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
    @Published private(set) var logs: [CookingLogSummary] = []
    @Published private(set) var savedRecipes: [RecipeSummary] = []
    @Published private(set) var savedLogs: [CookingLogSummary] = []
    @Published private(set) var isLoadingContent = false
    @Published private(set) var hasMoreRecipes = true
    @Published private(set) var hasMoreLogs = true
    @Published private(set) var hasMoreSavedRecipes = true
    @Published private(set) var hasMoreSavedLogs = true
    @Published var selectedTab: ProfileTab = .recipes
    @Published var visibilityFilter: VisibilityFilter = .all

    private let userId: String?
    private let userRepository: UserRepositoryProtocol
    private let logRepository: CookingLogRepositoryProtocol
    private let savedContentRepository: SavedContentRepositoryProtocol
    private var recipesNextCursor: String?
    private var logsNextCursor: String?
    private var savedRecipesNextCursor: String?
    private var savedLogsNextCursor: String?

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
    }

    func loadProfile() {
        state = .loading
        Task {
            if isOwnProfile { await loadMyProfile() }
            else if let id = userId { await loadUserProfile(id) }
        }
    }

    func loadContent() {
        Task {
            switch selectedTab {
            case .recipes: await loadRecipes(refresh: true)
            case .logs: await loadLogs(refresh: true)
            case .saved: await loadSavedContent(refresh: true)
            }
        }
    }

    var savedCount: Int {
        myProfile?.savedCount ?? 0
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
            self.profile = UserProfile(id: profile.id, username: profile.username, displayName: profile.displayName, avatarUrl: profile.avatarUrl,
                bio: profile.bio, level: profile.level, recipeCount: profile.recipeCount, logCount: profile.logCount,
                followerCount: profile.followerCount, followingCount: profile.followingCount, socialLinks: profile.socialLinks,
                isFollowing: false, isFollowedBy: profile.isFollowedBy, isBlocked: true, createdAt: profile.createdAt)
        }
    }

    private func loadMyProfile() async {
        let result = await userRepository.getMyProfile()
        switch result {
        case .success(let profile): myProfile = profile; state = .loaded; loadContent()
        case .failure(let error): state = .error(error.localizedDescription)
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
        profile = UserProfile(id: p.id, username: p.username, displayName: p.displayName, avatarUrl: p.avatarUrl,
            bio: p.bio, level: p.level, recipeCount: p.recipeCount, logCount: p.logCount,
            followerCount: p.followerCount + (isFollowing ? 1 : -1), followingCount: p.followingCount, socialLinks: p.socialLinks,
            isFollowing: isFollowing, isFollowedBy: p.isFollowedBy, isBlocked: p.isBlocked, createdAt: p.createdAt)
    }

    private func loadSavedContent(refresh: Bool) async {
        guard isOwnProfile else { return }
        isLoadingContent = true
        defer { isLoadingContent = false }

        // Load both saved recipes and logs in parallel
        async let recipesTask = savedContentRepository.getSavedRecipes(
            cursor: refresh ? nil : savedRecipesNextCursor
        )
        async let logsTask = savedContentRepository.getSavedLogs(
            cursor: refresh ? nil : savedLogsNextCursor
        )

        let recipesResult = await recipesTask
        let logsResult = await logsTask

        if case .success(let response) = recipesResult {
            savedRecipes = refresh ? response.content : savedRecipes + response.content
            savedRecipesNextCursor = response.nextCursor
            hasMoreSavedRecipes = response.hasMore
        }

        if case .success(let response) = logsResult {
            savedLogs = refresh ? response.content : savedLogs + response.content
            savedLogsNextCursor = response.nextCursor
            hasMoreSavedLogs = response.hasMore
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
}
