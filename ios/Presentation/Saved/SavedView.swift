import SwiftUI

enum SavedTab {
    case recipes
    case logs
}

struct SavedView: View {
    @State private var selectedTab: SavedTab = .recipes
    @EnvironmentObject private var authManager: AuthManager
    @EnvironmentObject private var appState: AppState

    var body: some View {
        NavigationStack {
            Group {
                if authManager.isAuthenticated {
                    authenticatedContent
                } else {
                    loginPromptView
                }
            }
            .background(DesignSystem.Colors.secondaryBackground)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    // Icon header
                    Image(systemName: AppIcon.save)
                        .font(.system(size: DesignSystem.IconSize.lg))
                        .foregroundColor(DesignSystem.Colors.primary)
                }
            }
        }
    }

    private var authenticatedContent: some View {
        VStack(spacing: 0) {
            // Icon Tab Selector (icons only with indicator dot)
            HStack(spacing: 0) {
                SavedTabIconButton(
                    icon: AppIcon.recipe,
                    isSelected: selectedTab == .recipes,
                    action: { selectedTab = .recipes }
                )
                SavedTabIconButton(
                    useLogoIcon: true,
                    isSelected: selectedTab == .logs,
                    action: { selectedTab = .logs }
                )
            }
            .padding(DesignSystem.Spacing.xs)
            .background(DesignSystem.Colors.background)
            .cornerRadius(DesignSystem.CornerRadius.md)
            .padding(.horizontal, DesignSystem.Spacing.md)
            .padding(.vertical, DesignSystem.Spacing.sm)

            // Content
            switch selectedTab {
            case .recipes:
                SavedRecipesView()
            case .logs:
                SavedLogsView()
            }
        }
    }

    private var loginPromptView: some View {
        VStack(spacing: DesignSystem.Spacing.lg) {
            Spacer()
            Image(systemName: AppIcon.saveOutline)
                .font(.system(size: DesignSystem.IconSize.xxl))
                .foregroundColor(DesignSystem.Colors.tertiaryText)
            Text("Sign in to see your saved items")
                .font(DesignSystem.Typography.body)
                .foregroundColor(DesignSystem.Colors.secondaryText)
            Button {
                appState.showLoginSheet = true
            } label: {
                Text("Sign In")
                    .font(DesignSystem.Typography.headline)
                    .foregroundColor(.white)
                    .padding(.horizontal, DesignSystem.Spacing.xl)
                    .padding(.vertical, DesignSystem.Spacing.sm)
                    .background(DesignSystem.Colors.primary)
                    .cornerRadius(DesignSystem.CornerRadius.md)
            }
            Spacer()
        }
    }
}

// MARK: - Tab Icon Button
struct SavedTabIconButton: View {
    let icon: String?
    var useLogoIcon: Bool = false
    let isSelected: Bool
    let action: () -> Void

    init(icon: String, isSelected: Bool, action: @escaping () -> Void) {
        self.icon = icon
        self.useLogoIcon = false
        self.isSelected = isSelected
        self.action = action
    }

    init(useLogoIcon: Bool, isSelected: Bool, action: @escaping () -> Void) {
        self.icon = nil
        self.useLogoIcon = useLogoIcon
        self.isSelected = isSelected
        self.action = action
    }

    var body: some View {
        Button(action: action) {
            VStack(spacing: DesignSystem.Spacing.xxs) {
                if useLogoIcon {
                    LogoIconView(size: DesignSystem.IconSize.lg)
                        .opacity(isSelected ? 1.0 : 0.4)
                } else if let icon = icon {
                    Image(systemName: icon)
                        .font(.system(size: DesignSystem.IconSize.lg))
                        .foregroundColor(isSelected ? DesignSystem.Colors.primary : DesignSystem.Colors.tertiaryText)
                }

                // Selection indicator
                Circle()
                    .fill(isSelected ? DesignSystem.Colors.primary : Color.clear)
                    .frame(width: 4, height: 4)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, DesignSystem.Spacing.sm)
        }
    }
}

// MARK: - Saved Recipes View
struct SavedRecipesView: View {
    @StateObject private var viewModel = SavedRecipesViewModel()

    var body: some View {
        Group {
            if viewModel.isLoading && viewModel.recipes.isEmpty {
                LoadingView()
            } else if viewModel.recipes.isEmpty {
                IconEmptyState(icon: AppIcon.saveOutline)
            } else {
                ScrollView {
                    ContentGrid {
                        ForEach(viewModel.recipes) { recipe in
                            NavigationLink(destination: RecipeDetailView(recipeId: recipe.id)) {
                                RecipeGridCard(recipe: recipe, showSavedBadge: true)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.vertical, DesignSystem.Spacing.md)

                    if viewModel.hasMore && !viewModel.isLoading {
                        ProgressView()
                            .padding()
                            .onAppear {
                                viewModel.loadMore()
                            }
                    }
                }
                .refreshable {
                    await viewModel.refresh()
                }
            }
        }
        .task {
            await viewModel.loadInitial()
        }
    }
}

// MARK: - Saved Logs View
struct SavedLogsView: View {
    @StateObject private var viewModel = SavedLogsViewModel()

    var body: some View {
        Group {
            if viewModel.isLoading && viewModel.logs.isEmpty {
                LoadingView()
            } else if viewModel.logs.isEmpty {
                IconEmptyState(icon: AppIcon.saveOutline)
            } else {
                ScrollView {
                    ContentGrid {
                        ForEach(viewModel.logs) { log in
                            NavigationLink(destination: LogDetailView(logId: log.id)) {
                                LogGridCard(log: log, showSavedBadge: true)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.vertical, DesignSystem.Spacing.md)

                    if viewModel.hasMore && !viewModel.isLoading {
                        ProgressView()
                            .padding()
                            .onAppear {
                                viewModel.loadMore()
                            }
                    }
                }
                .refreshable {
                    await viewModel.refresh()
                }
            }
        }
        .task {
            await viewModel.loadInitial()
        }
    }
}

// MARK: - Saved Recipes ViewModel
@MainActor
final class SavedRecipesViewModel: ObservableObject {
    @Published private(set) var recipes: [RecipeSummary] = []
    @Published private(set) var isLoading = false
    @Published private(set) var hasMore = true

    private let repository: SavedContentRepositoryProtocol
    private var nextCursor: String?

    init(repository: SavedContentRepositoryProtocol = SavedContentRepository()) {
        self.repository = repository
    }

    func loadInitial() async {
        guard recipes.isEmpty else { return }
        await load(refresh: true)
    }

    func refresh() async {
        await load(refresh: true)
    }

    func loadMore() {
        guard !isLoading, hasMore else { return }
        Task {
            await load(refresh: false)
        }
    }

    private func load(refresh: Bool) async {
        isLoading = true
        defer { isLoading = false }

        let cursor = refresh ? nil : nextCursor
        let result = await repository.getSavedRecipes(cursor: cursor)

        switch result {
        case .success(let response):
            if refresh {
                recipes = response.content
            } else {
                recipes.append(contentsOf: response.content)
            }
            nextCursor = response.nextCursor
            hasMore = response.hasMore
        case .failure(let error):
            #if DEBUG
            print("[SavedRecipes] Error: \(error)")
            #endif
        }
    }
}

// MARK: - Saved Logs ViewModel
@MainActor
final class SavedLogsViewModel: ObservableObject {
    @Published private(set) var logs: [FeedLogItem] = []
    @Published private(set) var isLoading = false
    @Published private(set) var hasMore = true

    private let repository: SavedContentRepositoryProtocol
    private var nextCursor: String?

    init(repository: SavedContentRepositoryProtocol = SavedContentRepository()) {
        self.repository = repository
    }

    func loadInitial() async {
        guard logs.isEmpty else { return }
        await load(refresh: true)
    }

    func refresh() async {
        await load(refresh: true)
    }

    func loadMore() {
        guard !isLoading, hasMore else { return }
        Task {
            await load(refresh: false)
        }
    }

    private func load(refresh: Bool) async {
        isLoading = true
        defer { isLoading = false }

        let cursor = refresh ? nil : nextCursor
        let result = await repository.getSavedLogs(cursor: cursor)

        switch result {
        case .success(let response):
            if refresh {
                logs = response.content
            } else {
                logs.append(contentsOf: response.content)
            }
            nextCursor = response.nextCursor
            hasMore = response.hasMore
        case .failure(let error):
            #if DEBUG
            print("[SavedLogs] Error: \(error)")
            #endif
        }
    }
}

#Preview {
    SavedView()
        .environmentObject(AuthManager.shared)
        .environmentObject(AppState())
}
