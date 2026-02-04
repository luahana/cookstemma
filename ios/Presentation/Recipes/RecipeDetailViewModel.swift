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
        // Observe SavedItemsManager for save state changes
        // Use dropFirst() to skip initial value - we use API value for initial state
        SavedItemsManager.shared.$savedRecipeIds
            .dropFirst()
            .receive(on: DispatchQueue.main)
            .sink { [weak self] savedIds in
                guard let self = self else { return }
                let newSavedState = savedIds.contains(self.recipeId)
                #if DEBUG
                print("[RecipeDetail] Save state observer: id=\(self.recipeId), inSet=\(newSavedState), current=\(self.isSaved)")
                #endif
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
        guard recipe != nil else { return }
        #if DEBUG
        print("========== [RecipeDetail] TOGGLE SAVE START ==========")
        print("[RecipeDetail] recipeId: \(recipeId)")
        if let summary = recipeSummary {
            print("[RecipeDetail] summary.id: \(summary.id)")
            print("[RecipeDetail] summary.title: \(summary.title)")
            print("[RecipeDetail] summary.thumbnail: \(summary.thumbnail ?? "NIL")")
            print("[RecipeDetail] summary.coverImageUrl: \(summary.coverImageUrl ?? "NIL")")
        } else {
            print("[RecipeDetail] recipeSummary is NIL!")
        }
        print("[RecipeDetail] Calling SavedItemsManager.toggleSaveRecipe...")
        #endif
        await SavedItemsManager.shared.toggleSaveRecipe(
            id: recipeId,
            summary: recipeSummary
        )
        #if DEBUG
        print("[RecipeDetail] SavedItemsManager.toggleSaveRecipe completed")
        print("[RecipeDetail] Current savedRecipeIds count: \(SavedItemsManager.shared.savedRecipeIds.count)")
        print("[RecipeDetail] Current savedRecipes count: \(SavedItemsManager.shared.savedRecipes.count)")
        print("========== [RecipeDetail] TOGGLE SAVE END ==========")
        #endif
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
