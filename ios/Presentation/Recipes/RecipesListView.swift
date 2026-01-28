import SwiftUI

struct RecipesListView: View {
    @StateObject private var viewModel = RecipesListViewModel()
    @EnvironmentObject private var appState: AppState
    @State private var showFilters = false
    @State private var navigationPath = NavigationPath()

    var body: some View {
        NavigationStack(path: $navigationPath) {
            VStack(spacing: 0) {
                recipesHeader
                contentView
            }
            .frame(maxHeight: .infinity, alignment: .top)
            .background(DesignSystem.Colors.background)
            .navigationBarHidden(true)
            .navigationDestination(for: String.self) { recipeId in
                RecipeDetailView(recipeId: recipeId)
            }
            .sheet(isPresented: $showFilters) {
                RecipeFiltersView(filters: $viewModel.filters) { viewModel.loadRecipes() }
            }
        }
        .onAppear { if case .idle = viewModel.state { viewModel.loadRecipes() } }
        .onChange(of: appState.recipesScrollToTopTrigger) { _, _ in
            if !navigationPath.isEmpty {
                navigationPath = NavigationPath()
                return
            }
            Task { await viewModel.refresh() }
        }
    }

    private var recipesHeader: some View {
        HStack {
            Image(systemName: AppIcon.recipe)
                .font(.system(size: DesignSystem.IconSize.lg))
                .foregroundColor(DesignSystem.Colors.primary)

            Text("Recipes")
                .font(DesignSystem.Typography.headline)
                .foregroundColor(DesignSystem.Colors.text)

            Spacer()

            Button { showFilters = true } label: {
                Image(systemName: AppIcon.filter)
                    .font(.system(size: DesignSystem.IconSize.md))
                    .foregroundColor(viewModel.hasActiveFilters ? DesignSystem.Colors.primary : DesignSystem.Colors.text)
            }
        }
        .padding(.horizontal, DesignSystem.Spacing.md)
        .padding(.vertical, DesignSystem.Spacing.sm)
    }

    @ViewBuilder
    private var contentView: some View {
        switch viewModel.state {
        case .idle, .loading:
            Spacer()
            ProgressView()
            Spacer()
        case .loaded:
            ScrollView(.vertical, showsIndicators: false) {
                recipeContent
            }
            .refreshable {
                await viewModel.refresh()
            }
        case .empty:
            Spacer()
            IconEmptyState(icon: AppIcon.recipe)
            Spacer()
        case .error(let msg):
            Spacer()
            ErrorStateView(message: msg) { viewModel.loadRecipes() }
            Spacer()
        }
    }

    private var recipeContent: some View {
        LazyVStack(spacing: DesignSystem.Spacing.md) {
            ForEach(viewModel.recipes) { recipe in
                NavigationLink(value: recipe.id) {
                    RecipeCard(
                        recipe: recipe,
                        isSaved: viewModel.isRecipeSaved(recipe.id),
                        onSave: { await viewModel.saveRecipe(recipe) }
                    )
                }
                .buttonStyle(.plain)
                .onAppear {
                    if recipe.id == viewModel.recipes.suffix(3).first?.id {
                        viewModel.loadMore()
                    }
                }
            }

            if viewModel.isLoadingMore {
                ProgressView()
                    .padding(.vertical, DesignSystem.Spacing.md)
            }
        }
        .padding(.bottom, DesignSystem.Spacing.sm)
    }
}

// MARK: - Recipe Card (Icon-Focused)
struct RecipeCard: View {
    let recipe: RecipeSummary
    let isSaved: Bool
    let onSave: () async -> Void
    @State private var isSaving = false

    var body: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.sm) {
            // Cover image
            GeometryReader { geometry in
                AsyncImage(url: URL(string: recipe.coverImageUrl ?? "")) { img in
                    img.resizable().scaledToFill()
                } placeholder: {
                    Rectangle().fill(DesignSystem.Colors.tertiaryBackground)
                }
                .frame(width: geometry.size.width, height: 180)
                .clipped()
            }
            .frame(height: 180)
            .cornerRadius(DesignSystem.CornerRadius.md)

            // Title
            Text(recipe.title)
                .font(DesignSystem.Typography.headline)
                .foregroundColor(DesignSystem.Colors.text)
                .lineLimit(2)

            // Stats row (Icons with minimal text)
            HStack(spacing: DesignSystem.Spacing.md) {
                // Cooking time
                if let time = recipe.cookingTimeRange {
                    HStack(spacing: DesignSystem.Spacing.xxs) {
                        Image(systemName: AppIcon.timer)
                        Text(time.cookingTimeDisplayText)
                    }
                    .font(DesignSystem.Typography.caption)
                    .foregroundColor(DesignSystem.Colors.secondaryText)
                }

                // Cooking style badge
                if let style = recipe.cookingStyle, !style.isEmpty {
                    HStack(spacing: 2) {
                        Text(style.flagEmoji)
                        Text(style.cookingStyleName)
                    }
                    .font(DesignSystem.Typography.caption)
                    .foregroundColor(DesignSystem.Colors.secondaryText)
                }

                // Cook count
                HStack(spacing: DesignSystem.Spacing.xxs) {
                    Image(systemName: AppIcon.chef)
                    Text("\(recipe.cookCount.abbreviated)")
                }
                .font(DesignSystem.Typography.caption)
                .foregroundColor(DesignSystem.Colors.secondaryText)

                Spacer()

                // Save button (icon only)
                Button {
                    Task {
                        isSaving = true
                        await onSave()
                        isSaving = false
                    }
                } label: {
                    Image(systemName: isSaved ? AppIcon.save : AppIcon.saveOutline)
                        .font(.system(size: DesignSystem.IconSize.md))
                        .foregroundColor(isSaved ? DesignSystem.Colors.bookmark : DesignSystem.Colors.tertiaryText)
                }
                .disabled(isSaving)
            }
        }
        .padding(DesignSystem.Spacing.md)
        .background(DesignSystem.Colors.background)
        .contentShape(Rectangle())
    }
}

// MARK: - Recipe Filters View (Icon Headers)
struct RecipeFiltersView: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var filters: RecipeFilters
    let onApply: () -> Void

    var body: some View {
        NavigationStack {
            List {
                // Cooking Time Section (icon header)
                Section {
                    ForEach(CookingTimeRange.allCases, id: \.self) { range in
                        Button {
                            filters.cookingTimeRange = filters.cookingTimeRange == range ? nil : range
                        } label: {
                            HStack {
                                Text(range.displayText)
                                Spacer()
                                if filters.cookingTimeRange == range {
                                    Image(systemName: AppIcon.checkmark)
                                        .foregroundColor(DesignSystem.Colors.primary)
                                }
                            }
                        }
                        .foregroundColor(DesignSystem.Colors.text)
                    }
                } header: {
                    HStack(spacing: DesignSystem.Spacing.xs) {
                        Image(systemName: AppIcon.timer)
                            .foregroundColor(DesignSystem.Colors.primary)
                    }
                }

                // Sort Section (icon header)
                Section {
                    ForEach(RecipeSortOption.allCases, id: \.self) { option in
                        Button {
                            filters.sortBy = option
                        } label: {
                            HStack {
                                Image(systemName: option.iconName)
                                    .foregroundColor(DesignSystem.Colors.secondaryText)
                                    .frame(width: 20)
                                Text(option.displayText)
                                Spacer()
                                if filters.sortBy == option {
                                    Image(systemName: AppIcon.checkmark)
                                        .foregroundColor(DesignSystem.Colors.primary)
                                }
                            }
                        }
                        .foregroundColor(DesignSystem.Colors.text)
                    }
                } header: {
                    HStack(spacing: DesignSystem.Spacing.xs) {
                        Image(systemName: AppIcon.sort)
                            .foregroundColor(DesignSystem.Colors.primary)
                    }
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    // Reset button (icon)
                    Button {
                        filters = RecipeFilters()
                    } label: {
                        Image(systemName: AppIcon.reset)
                            .foregroundColor(DesignSystem.Colors.text)
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    // Apply button (icon)
                    Button {
                        onApply()
                        dismiss()
                    } label: {
                        Image(systemName: AppIcon.checkmark)
                            .foregroundColor(DesignSystem.Colors.primary)
                    }
                }
            }
        }
    }
}

// Extension for sort option icons
extension RecipeSortOption {
    var iconName: String {
        switch self {
        case .trending: return "flame"
        case .mostCooked: return "person.2"
        case .highestRated: return "star"
        case .newest: return "clock"
        }
    }
}

#Preview { RecipesListView() }
