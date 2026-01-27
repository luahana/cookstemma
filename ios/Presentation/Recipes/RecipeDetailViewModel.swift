import Foundation

enum RecipeDetailState: Equatable {
    case idle, loading, loaded(RecipeDetail), error(String)
}

@MainActor
final class RecipeDetailViewModel: ObservableObject {
    @Published private(set) var state: RecipeDetailState = .idle
    @Published private(set) var recipe: RecipeDetail?
    @Published private(set) var logs: [CookingLogSummary] = []
    @Published private(set) var isLoadingLogs = false
    @Published private(set) var hasMoreLogs = true
    @Published private(set) var isSaved = false

    private let recipeId: String
    private let recipeRepository: RecipeRepositoryProtocol
    private let logRepository: CookingLogRepositoryProtocol
    private var nextLogsCursor: String?

    init(recipeId: String, recipeRepository: RecipeRepositoryProtocol = RecipeRepository(), logRepository: CookingLogRepositoryProtocol = CookingLogRepository()) {
        self.recipeId = recipeId
        self.recipeRepository = recipeRepository
        self.logRepository = logRepository
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
        if case .success(let response) = result {
            logs = response.content
            nextLogsCursor = response.nextCursor
            hasMoreLogs = response.hasMore
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
        let result = wasSaved ? await recipeRepository.unsaveRecipe(id: recipeId) : await recipeRepository.saveRecipe(id: recipeId)
        if case .failure = result { isSaved = wasSaved }
    }

    func shareRecipe() -> URL? {
        guard recipe != nil else { return nil }
        return URL(string: "https://cookstemma.com/recipes/\(recipeId)")
    }
}
