import Foundation
import Combine

/// Centralized manager for saved items state.
/// Uses Combine's @Published properties to notify all observers about save state changes.
/// This solves the issue of NotificationCenter userInfo not properly passing Swift structs.
@MainActor
final class SavedItemsManager: ObservableObject {
    static let shared = SavedItemsManager()

    // MARK: - Published Properties

    /// Set of currently saved recipe IDs for quick lookup
    @Published private(set) var savedRecipeIds: Set<String> = []

    /// Set of currently saved log IDs for quick lookup
    @Published private(set) var savedLogIds: Set<String> = []

    /// Array of saved recipes with full data (for display in profile)
    @Published private(set) var savedRecipes: [RecipeSummary] = []

    /// Array of saved logs with full data (for display in profile)
    @Published private(set) var savedLogs: [FeedLogItem] = []

    // MARK: - Dependencies

    private let recipeRepository: RecipeRepositoryProtocol
    private let logRepository: CookingLogRepositoryProtocol
    private let savedContentRepository: SavedContentRepositoryProtocol

    // MARK: - Private State

    private var hasFetchedRecipeIds = false
    private var hasFetchedLogIds = false

    // MARK: - Initialization

    private init(
        recipeRepository: RecipeRepositoryProtocol = RecipeRepository(),
        logRepository: CookingLogRepositoryProtocol = CookingLogRepository(),
        savedContentRepository: SavedContentRepositoryProtocol = SavedContentRepository()
    ) {
        self.recipeRepository = recipeRepository
        self.logRepository = logRepository
        self.savedContentRepository = savedContentRepository
    }

    /// For testing purposes only
    static func createForTesting(
        recipeRepository: RecipeRepositoryProtocol,
        logRepository: CookingLogRepositoryProtocol,
        savedContentRepository: SavedContentRepositoryProtocol
    ) -> SavedItemsManager {
        let manager = SavedItemsManager(
            recipeRepository: recipeRepository,
            logRepository: logRepository,
            savedContentRepository: savedContentRepository
        )
        return manager
    }

    // MARK: - Public Methods

    /// Toggle save state for a recipe
    /// - Parameters:
    ///   - id: Recipe public ID
    ///   - summary: Recipe summary to add optimistically (with thumbnail for immediate display)
    func toggleSaveRecipe(id: String, summary: RecipeSummary?) async {
        #if DEBUG
        print("========== [SavedItemsManager] TOGGLE SAVE RECIPE START ==========")
        print("[SavedItemsManager] Input id: \(id)")
        print("[SavedItemsManager] Input summary: \(summary != nil ? "PROVIDED" : "NIL")")
        if let s = summary {
            print("[SavedItemsManager] summary.id: \(s.id)")
            print("[SavedItemsManager] summary.thumbnail: \(s.thumbnail ?? "NIL")")
            print("[SavedItemsManager] summary.coverImageUrl: \(s.coverImageUrl ?? "NIL")")
        }
        print("[SavedItemsManager] BEFORE - savedRecipeIds: \(savedRecipeIds)")
        print("[SavedItemsManager] BEFORE - savedRecipes.count: \(savedRecipes.count)")
        #endif

        let wasSaved = savedRecipeIds.contains(id)

        // Optimistic update
        if wasSaved {
            savedRecipeIds.remove(id)
            savedRecipes = savedRecipes.filter { $0.id != id }
            #if DEBUG
            print("[SavedItemsManager] UNSAVING - removed from IDs and array")
            #endif
        } else {
            savedRecipeIds.insert(id)
            // Add to savedRecipes optimistically if we have the summary
            if let summary = summary {
                // Insert at the beginning (most recently saved first)
                savedRecipes.insert(summary, at: 0)
                #if DEBUG
                print("[SavedItemsManager] SAVING - Added to IDs and array")
                print("[SavedItemsManager] Inserted recipe with thumbnail: \(summary.coverImageUrl ?? "NIL")")
                #endif
            } else {
                #if DEBUG
                print("[SavedItemsManager] SAVING - Added to IDs only (no summary provided)")
                #endif
            }
        }

        #if DEBUG
        print("[SavedItemsManager] AFTER OPTIMISTIC - savedRecipeIds: \(savedRecipeIds)")
        print("[SavedItemsManager] AFTER OPTIMISTIC - savedRecipes.count: \(savedRecipes.count)")
        for (index, r) in savedRecipes.prefix(3).enumerated() {
            print("[SavedItemsManager]   [\(index)] \(r.id): \(r.coverImageUrl ?? "NIL")")
        }
        #endif

        // API call
        #if DEBUG
        print("[SavedItemsManager] Making API call - \(wasSaved ? "UNSAVE" : "SAVE")")
        #endif
        let result = wasSaved
            ? await recipeRepository.unsaveRecipe(id: id)
            : await recipeRepository.saveRecipe(id: id)

        switch result {
        case .success:
            #if DEBUG
            print("[SavedItemsManager] API SUCCESS! Now fetching saved recipes from server...")
            print("[SavedItemsManager] BEFORE FETCH - savedRecipes.count: \(savedRecipes.count)")
            #endif
            await fetchSavedRecipes()
            #if DEBUG
            print("[SavedItemsManager] AFTER FETCH - savedRecipes.count: \(savedRecipes.count)")
            for (index, r) in savedRecipes.prefix(5).enumerated() {
                print("[SavedItemsManager]   [\(index)] \(r.id): thumbnail=\(r.coverImageUrl ?? "NIL")")
            }
            print("========== [SavedItemsManager] TOGGLE SAVE RECIPE END ==========")
            #endif
        case .failure(let error):
            #if DEBUG
            print("[SavedItemsManager] toggleSaveRecipe failed: \(error), reverting")
            #endif
            // Revert on failure
            if wasSaved {
                savedRecipeIds.insert(id)
            } else {
                savedRecipeIds.remove(id)
                savedRecipes = savedRecipes.filter { $0.id != id }
            }
            // Refetch to restore correct state
            await fetchSavedRecipes()
        }
    }

    /// Toggle save state for a cooking log
    /// - Parameters:
    ///   - id: Log public ID
    ///   - logItem: Log item to add optimistically when saving
    func toggleSaveLog(id: String, logItem: FeedLogItem?) async {
        #if DEBUG
        print("========== [SavedItemsManager] TOGGLE SAVE LOG START ==========")
        print("[SavedItemsManager] Input id: \(id)")
        print("[SavedItemsManager] Input logItem: \(logItem != nil ? "PROVIDED" : "NIL")")
        if let item = logItem {
            print("[SavedItemsManager] logItem.id: \(item.id)")
            print("[SavedItemsManager] logItem.thumbnailUrl: \(item.thumbnailUrl ?? "NIL")")
        }
        print("[SavedItemsManager] BEFORE - savedLogIds: \(savedLogIds)")
        print("[SavedItemsManager] BEFORE - savedLogs.count: \(savedLogs.count)")
        #endif

        let wasSaved = savedLogIds.contains(id)

        // Optimistic update
        if wasSaved {
            savedLogIds.remove(id)
            savedLogs = savedLogs.filter { $0.id != id }
            #if DEBUG
            print("[SavedItemsManager] UNSAVING LOG - removed from IDs and array")
            #endif
        } else {
            savedLogIds.insert(id)
            // Add to savedLogs optimistically if we have the logItem
            if let logItem = logItem {
                // Insert at the beginning (most recently saved first)
                savedLogs.insert(logItem, at: 0)
                #if DEBUG
                print("[SavedItemsManager] SAVING LOG - Added to IDs and array")
                print("[SavedItemsManager] Inserted log with thumbnail: \(logItem.thumbnailUrl ?? "NIL")")
                #endif
            } else {
                #if DEBUG
                print("[SavedItemsManager] SAVING LOG - Added to IDs only (no logItem provided)")
                #endif
            }
        }

        #if DEBUG
        print("[SavedItemsManager] AFTER OPTIMISTIC - savedLogIds: \(savedLogIds)")
        print("[SavedItemsManager] AFTER OPTIMISTIC - savedLogs.count: \(savedLogs.count)")
        for (index, log) in savedLogs.prefix(3).enumerated() {
            print("[SavedItemsManager]   [\(index)] \(log.id): \(log.thumbnailUrl ?? "NIL")")
        }
        #endif

        // API call
        #if DEBUG
        print("[SavedItemsManager] Making API call - \(wasSaved ? "UNSAVE" : "SAVE") LOG")
        #endif
        let result = wasSaved
            ? await logRepository.unsaveLog(id: id)
            : await logRepository.saveLog(id: id)

        switch result {
        case .success:
            #if DEBUG
            print("[SavedItemsManager] LOG API SUCCESS! Now fetching saved logs from server...")
            print("[SavedItemsManager] BEFORE FETCH - savedLogs.count: \(savedLogs.count)")
            #endif
            await fetchSavedLogs()
            #if DEBUG
            print("[SavedItemsManager] AFTER FETCH - savedLogs.count: \(savedLogs.count)")
            for (index, log) in savedLogs.prefix(5).enumerated() {
                print("[SavedItemsManager]   [\(index)] \(log.id): thumbnail=\(log.thumbnailUrl ?? "NIL")")
            }
            print("========== [SavedItemsManager] TOGGLE SAVE LOG END ==========")
            #endif
        case .failure(let error):
            #if DEBUG
            print("[SavedItemsManager] toggleSaveLog failed: \(error), reverting")
            #endif
            // Revert on failure
            if wasSaved {
                savedLogIds.insert(id)
            } else {
                savedLogIds.remove(id)
                savedLogs = savedLogs.filter { $0.id != id }
            }
            // Refetch to restore correct state
            await fetchSavedLogs()
        }
    }

    /// Check if a recipe is currently saved
    func isRecipeSaved(_ id: String) -> Bool {
        savedRecipeIds.contains(id)
    }

    /// Check if a log is currently saved
    func isLogSaved(_ id: String) -> Bool {
        savedLogIds.contains(id)
    }

    /// Fetch all saved recipes from API and populate state
    func fetchSavedRecipes() async {
        #if DEBUG
        print("[SavedItemsManager] Fetching saved recipes")
        #endif

        let result = await savedContentRepository.getSavedRecipes(cursor: nil)
        switch result {
        case .success(let response):
            savedRecipes = response.content
            savedRecipeIds = Set(response.content.map { $0.id })
            hasFetchedRecipeIds = true
            #if DEBUG
            print("[SavedItemsManager] Fetched \(response.content.count) saved recipes")
            #endif
        case .failure(let error):
            #if DEBUG
            print("[SavedItemsManager] Failed to fetch saved recipes: \(error)")
            #endif
        }
    }

    /// Fetch all saved logs from API and populate state
    func fetchSavedLogs() async {
        #if DEBUG
        print("[SavedItemsManager] Fetching saved logs")
        #endif

        let result = await savedContentRepository.getSavedLogs(cursor: nil)
        switch result {
        case .success(let response):
            savedLogs = response.content
            savedLogIds = Set(response.content.map { $0.id })
            hasFetchedLogIds = true
            #if DEBUG
            print("[SavedItemsManager] Fetched \(response.content.count) saved logs")
            #endif
        case .failure(let error):
            #if DEBUG
            print("[SavedItemsManager] Failed to fetch saved logs: \(error)")
            #endif
        }
    }

    /// Fetch all saved content (recipes and logs) in parallel
    func fetchAllSavedContent() async {
        async let recipesTask: () = fetchSavedRecipes()
        async let logsTask: () = fetchSavedLogs()
        _ = await (recipesTask, logsTask)
    }

    /// Reset all state (call on logout)
    func reset() {
        #if DEBUG
        print("[SavedItemsManager] Resetting state")
        #endif
        savedRecipeIds = []
        savedLogIds = []
        savedRecipes = []
        savedLogs = []
        hasFetchedRecipeIds = false
        hasFetchedLogIds = false
    }

    /// Update saved recipes list with fresh data from API
    /// This is called by ProfileViewModel when loading saved content
    /// Merges with any optimistically added items not yet in API response
    func updateSavedRecipes(_ recipes: [RecipeSummary]) {
        let apiRecipeIds = Set(recipes.map { $0.id })

        // Keep any optimistically added recipes that aren't in the API response yet
        let pendingRecipes = savedRecipes.filter { !apiRecipeIds.contains($0.id) && savedRecipeIds.contains($0.id) }

        #if DEBUG
        if !pendingRecipes.isEmpty {
            print("[SavedItemsManager] Preserving \(pendingRecipes.count) pending saved recipes")
        }
        #endif

        // Merge: pending items first (newest), then API results
        savedRecipes = pendingRecipes + recipes
        savedRecipeIds = Set(savedRecipes.map { $0.id })
    }

    /// Update saved logs list with fresh data from API
    /// This is called by ProfileViewModel when loading saved content
    /// Merges with any optimistically added items not yet in API response
    func updateSavedLogs(_ logs: [FeedLogItem]) {
        #if DEBUG
        print("[SavedItemsManager] updateSavedLogs called with \(logs.count) API logs")
        print("[SavedItemsManager] Current savedLogs.count=\(savedLogs.count), savedLogIds.count=\(savedLogIds.count)")
        #endif

        let apiLogIds = Set(logs.map { $0.id })

        // Keep any optimistically added logs that aren't in the API response yet
        let pendingLogs = savedLogs.filter { !apiLogIds.contains($0.id) && savedLogIds.contains($0.id) }

        #if DEBUG
        print("[SavedItemsManager] Found \(pendingLogs.count) pending saved logs to preserve")
        for log in pendingLogs {
            print("[SavedItemsManager]   - pending: \(log.id), thumbnailUrl=\(log.thumbnailUrl ?? "nil")")
        }
        #endif

        // Merge: pending items first (newest), then API results
        savedLogs = pendingLogs + logs
        savedLogIds = Set(savedLogs.map { $0.id })

        #if DEBUG
        print("[SavedItemsManager] After merge: savedLogs.count=\(savedLogs.count)")
        #endif
    }
}
