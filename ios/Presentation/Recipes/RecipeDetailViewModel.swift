import Foundation
import Combine

enum RecipeDetailState: Equatable {
    case idle, loading, loaded(RecipeDetail), error(String)
}

@MainActor
final class RecipeDetailViewModel: ObservableObject {
    @Published private(set) var state: RecipeDetailState = .idle
    @Published private(set) var recipe: RecipeDetail?
    @Published private(set) var logs: [RecipeLogItem] = []
    @Published private(set) var isLoadingLogs = false
    @Published private(set) var hasMoreLogs = true
    @Published private(set) var isSaved = false

    private let recipeId: String
    private let recipeRepository: RecipeRepositoryProtocol
    private let logRepository: CookingLogRepositoryProtocol
    private let userRepository: UserRepositoryProtocol
    private var nextLogsCursor: String?
    private var cancellables = Set<AnyCancellable>()

    init(
        recipeId: String,
        recipeRepository: RecipeRepositoryProtocol = RecipeRepository(),
        logRepository: CookingLogRepositoryProtocol = CookingLogRepository(),
        userRepository: UserRepositoryProtocol = UserRepository()
    ) {
        self.recipeId = recipeId
        self.recipeRepository = recipeRepository
        self.logRepository = logRepository
        self.userRepository = userRepository
        setupSaveStateObserver()
    }

    private func setupSaveStateObserver() {
        NotificationCenter.default.publisher(for: .recipeSaveStateChanged)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] notification in
                guard let self = self,
                      let notificationRecipeId = notification.userInfo?["recipeId"] as? String,
                      notificationRecipeId == self.recipeId,
                      let newSavedState = notification.userInfo?["isSaved"] as? Bool else { return }
                self.isSaved = newSavedState
            }
            .store(in: &cancellables)
    }

    func loadRecipe() {
        state = .loading
        Task {
            #if DEBUG
            print("[RecipeDetail] Loading recipe: \(recipeId)")
            #endif
            let result = await recipeRepository.getRecipe(id: recipeId)
            switch result {
            case .success(let recipe):
                #if DEBUG
                print("[RecipeDetail] Success: \(recipe.title)")
                #endif
                self.recipe = recipe
                self.isSaved = recipe.isSaved
                state = .loaded(recipe)
                // Record view for history (syncs with web)
                await recipeRepository.recordRecipeView(id: recipeId)
                // Load logs separately
                await loadLogsInitial()
            case .failure(let error):
                #if DEBUG
                print("[RecipeDetail] Error: \(error.localizedDescription)")
                #endif
                state = .error(error.localizedDescription)
            }
        }
    }

    private func loadLogsInitial() async {
        isLoadingLogs = true
        defer { isLoadingLogs = false }
        let result = await recipeRepository.getRecipeLogs(recipeId: recipeId, cursor: nil)
        switch result {
        case .success(let response):
            #if DEBUG
            print("[RecipeDetail] Logs loaded: \(response.content.count) items")
            #endif
            logs = response.content
            nextLogsCursor = response.nextCursor
            hasMoreLogs = response.hasMore
        case .failure(let error):
            #if DEBUG
            print("[RecipeDetail] Failed to load logs: \(error)")
            #endif
        }
    }

    func loadMoreLogs() {
        guard !isLoadingLogs, hasMoreLogs else { return }
        Task {
            isLoadingLogs = true
            defer { isLoadingLogs = false }
            let result = await recipeRepository.getRecipeLogs(recipeId: recipeId, cursor: nextLogsCursor)
            if case .success(let response) = result {
                logs.append(contentsOf: response.content)
                nextLogsCursor = response.nextCursor
                hasMoreLogs = response.hasMore
            }
        }
    }

    func toggleSave() async {
        let wasSaved = isSaved
        isSaved = !wasSaved
        #if DEBUG
        print("[RecipeDetail] toggleSave: wasSaved=\(wasSaved), now isSaved=\(isSaved)")
        #endif

        let result = wasSaved
            ? await recipeRepository.unsaveRecipe(id: recipeId)
            : await recipeRepository.saveRecipe(id: recipeId)

        switch result {
        case .success:
            #if DEBUG
            print("[RecipeDetail] toggleSave: API success, isSaved=\(isSaved)")
            #endif
            var userInfo: [String: Any] = ["recipeId": recipeId, "isSaved": isSaved]
            // Include recipe summary when saving so profile can add it directly
            if isSaved, let summary = recipeSummary {
                userInfo["recipeSummary"] = summary
            }
            NotificationCenter.default.post(
                name: .recipeSaveStateChanged,
                object: nil,
                userInfo: userInfo
            )
        case .failure(let error):
            #if DEBUG
            print("[RecipeDetail] toggleSave: API failed with error: \(error), reverting to \(wasSaved)")
            #endif
            isSaved = wasSaved
        }
    }

    func shareRecipe() -> URL? {
        guard recipe != nil else { return nil }
        return URL(string: "https://cookstemma.com/recipes/\(recipeId)")
    }

    func blockUser() async {
        guard let authorId = recipe?.author.id else { return }
        let result = await userRepository.blockUser(userId: authorId)
        if case .success = result {
            #if DEBUG
            print("[RecipeDetail] Blocked user: \(authorId)")
            #endif
        }
    }

    func reportUser(reason: ReportReason) async {
        guard let authorId = recipe?.author.id else { return }
        let result = await userRepository.reportUser(userId: authorId, reason: reason)
        #if DEBUG
        if case .success = result {
            print("[RecipeDetail] Reported user \(authorId) for: \(reason.rawValue)")
        }
        #endif
    }

    var recipeSummary: RecipeSummary? {
        guard let recipe = recipe else { return nil }
        return RecipeSummary(
            id: recipe.id,
            title: recipe.title,
            description: recipe.description,
            foodName: recipe.foodName,
            cookingStyle: recipe.cookingStyle,
            userName: recipe.userName,
            thumbnail: recipe.thumbnail,
            variantCount: 0,
            logCount: recipe.cookCount,
            servings: recipe.servings,
            cookingTimeRange: recipe.cookingTimeRange,
            hashtags: recipe.hashtags ?? [],
            isPrivate: false,
            isSaved: recipe.isSaved
        )
    }
}
