import SwiftUI

struct RecipeDetailView: View {
    let recipeId: String
    @StateObject private var viewModel: RecipeDetailViewModel
    @EnvironmentObject private var authManager: AuthManager
    @EnvironmentObject private var appState: AppState

    init(recipeId: String) {
        self.recipeId = recipeId
        self._viewModel = StateObject(wrappedValue: RecipeDetailViewModel(recipeId: recipeId))
    }

    var body: some View {
        ScrollView {
            switch viewModel.state {
            case .idle, .loading: LoadingView()
            case .loaded(let recipe): recipeContent(recipe)
            case .error(let msg): ErrorStateView(message: msg) { viewModel.loadRecipe() }
            }
        }
        .background(DesignSystem.Colors.secondaryBackground)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                HStack(spacing: DesignSystem.Spacing.sm) {
                    // Save button (icon only) - requires auth
                    Button {
                        appState.requireAuth {
                            Task { await viewModel.toggleSave() }
                        }
                    } label: {
                        Image(systemName: viewModel.isSaved ? AppIcon.save : AppIcon.saveOutline)
                            .foregroundColor(viewModel.isSaved ? DesignSystem.Colors.bookmark : DesignSystem.Colors.secondaryText)
                    }

                    // Share button (icon only)
                    if let url = viewModel.shareRecipe() {
                        ShareLink(item: url) {
                            Image(systemName: AppIcon.share)
                                .foregroundColor(DesignSystem.Colors.text)
                        }
                    }

                    // More options (icon only)
                    Menu {
                        Button { } label: { Label("", systemImage: AppIcon.report) }
                    } label: {
                        Image(systemName: AppIcon.more)
                            .foregroundColor(DesignSystem.Colors.text)
                    }
                }
            }
        }
        .onAppear { if case .idle = viewModel.state { viewModel.loadRecipe() } }
    }

    @ViewBuilder
    private func recipeContent(_ recipe: RecipeDetail) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            // Image carousel
            TabView {
                ForEach(recipe.images) { image in
                    AsyncImage(url: URL(string: image.url)) { img in
                        img.resizable().scaledToFill()
                    } placeholder: {
                        Rectangle().fill(DesignSystem.Colors.tertiaryBackground)
                    }
                }
            }
            .tabViewStyle(.page)
            .frame(height: 300)

            // Content Card
            VStack(alignment: .leading, spacing: DesignSystem.Spacing.md) {
                // Title
                Text(recipe.title)
                    .font(DesignSystem.Typography.title)
                    .foregroundColor(DesignSystem.Colors.text)

                // Author row (icon-focused)
                HStack(spacing: DesignSystem.Spacing.sm) {
                    AvatarView(url: recipe.author.avatarUrl, size: DesignSystem.AvatarSize.xs)
                    Text("@\(recipe.author.username)")
                        .font(DesignSystem.Typography.caption)
                        .foregroundColor(DesignSystem.Colors.secondaryText)
                }

                // Stats row (Icons with minimal text)
                HStack(spacing: DesignSystem.Spacing.lg) {
                    // Time
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

                    // Servings
                    if let servings = recipe.servings {
                        HStack(spacing: DesignSystem.Spacing.xxs) {
                            Image(systemName: AppIcon.servings)
                            Text("\(servings)")
                        }
                        .font(DesignSystem.Typography.caption)
                        .foregroundColor(DesignSystem.Colors.secondaryText)
                    }

                    // Food name
                    Text(recipe.foodName)
                        .font(DesignSystem.Typography.caption)
                        .foregroundColor(DesignSystem.Colors.secondaryText)
                }

                // Description
                if let desc = recipe.description {
                    Text(desc)
                        .font(DesignSystem.Typography.body)
                        .foregroundColor(DesignSystem.Colors.secondaryText)
                }
            }
            .padding(DesignSystem.Spacing.md)
            .background(DesignSystem.Colors.background)
            .cornerRadius(DesignSystem.CornerRadius.lg)
            .padding(.horizontal, DesignSystem.Spacing.md)
            .offset(y: -20)

            // Ingredients Section (Icon header)
            ingredientsSectionCard(recipe)

            // Steps Section (Icon header)
            stepsSectionCard(recipe)

            // Cooking Logs Section (Icon header)
            cookingLogsSectionCard(recipe)

            // Hashtags
            if let hashtags = recipe.hashtags, !hashtags.isEmpty {
                FlowLayout(spacing: DesignSystem.Spacing.xs) {
                    ForEach(hashtags, id: \.self) { tag in
                        Text("#\(tag)")
                            .font(DesignSystem.Typography.caption)
                            .padding(.horizontal, DesignSystem.Spacing.xs)
                            .padding(.vertical, DesignSystem.Spacing.xxs)
                            .background(DesignSystem.Colors.tertiaryBackground)
                            .cornerRadius(DesignSystem.CornerRadius.xs)
                    }
                }
                .padding(.horizontal, DesignSystem.Spacing.md)
                .padding(.top, DesignSystem.Spacing.md)
                .padding(.bottom, DesignSystem.Spacing.md)
            }

        }
        .padding(.bottom, DesignSystem.Spacing.xl)
        .safeAreaPadding(.bottom)
    }

    // MARK: - Ingredients Section Card
    private func ingredientsSectionCard(_ recipe: RecipeDetail) -> some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.md) {
            // Icon header
            Image(systemName: AppIcon.ingredients)
                .font(.system(size: DesignSystem.IconSize.lg))
                .foregroundColor(DesignSystem.Colors.primary)

            // Ingredient groups with icons
            if !recipe.mainIngredients.isEmpty {
                ingredientGroup(recipe.mainIngredients, icon: "star.fill")
            }
            if !recipe.secondaryIngredients.isEmpty {
                ingredientGroup(recipe.secondaryIngredients, icon: "leaf.fill")
            }
            if !recipe.seasonings.isEmpty {
                ingredientGroup(recipe.seasonings, icon: "drop.fill")
            }
        }
        .padding(DesignSystem.Spacing.md)
        .background(DesignSystem.Colors.background)
        .cornerRadius(DesignSystem.CornerRadius.md)
        .padding(.horizontal, DesignSystem.Spacing.md)
        .padding(.top, DesignSystem.Spacing.sm)
    }

    private func ingredientGroup(_ ingredients: [Ingredient], icon: String) -> some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.xs) {
            // Group header icon
            Image(systemName: icon)
                .font(.system(size: 14))
                .foregroundColor(DesignSystem.Colors.primary)
                .padding(.bottom, DesignSystem.Spacing.xxs)

            ForEach(ingredients) { ing in
                HStack {
                    Text(ing.name)
                        .font(DesignSystem.Typography.body)
                    Spacer()
                    if let amount = ing.quantity {
                        Text("\(String(format: "%.1f", amount)) \(ing.displayUnit)")
                            .font(DesignSystem.Typography.caption)
                            .foregroundColor(DesignSystem.Colors.secondaryText)
                    }
                }
                .padding(.leading, DesignSystem.Spacing.md)
            }
        }
    }

    // MARK: - Steps Section Card
    private func stepsSectionCard(_ recipe: RecipeDetail) -> some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.sm) {
            // Icon header
            Image(systemName: AppIcon.steps)
                .font(.system(size: DesignSystem.IconSize.lg))
                .foregroundColor(DesignSystem.Colors.primary)

            ForEach(recipe.steps) { step in
                HStack(alignment: .top, spacing: DesignSystem.Spacing.sm) {
                    // Step number badge
                    Text("\(step.stepNumber)")
                        .font(DesignSystem.Typography.caption)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                        .frame(width: 24, height: 24)
                        .background(Circle().fill(DesignSystem.Colors.primary))

                    Text(step.instruction)
                        .font(DesignSystem.Typography.body)
                        .foregroundColor(DesignSystem.Colors.text)
                }
            }
        }
        .padding(DesignSystem.Spacing.md)
        .background(DesignSystem.Colors.background)
        .cornerRadius(DesignSystem.CornerRadius.md)
        .padding(.horizontal, DesignSystem.Spacing.md)
        .padding(.top, DesignSystem.Spacing.sm)
    }

    // MARK: - Cooking Logs Section Card
    private func cookingLogsSectionCard(_ recipe: RecipeDetail) -> some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.sm) {
            // Header with icon and count
            HStack {
                Image(systemName: AppIcon.log)
                    .font(.system(size: DesignSystem.IconSize.lg))
                    .foregroundColor(DesignSystem.Colors.primary)
                Spacer()
                Text("\(viewModel.logs.count)")
                    .font(DesignSystem.Typography.caption)
                    .foregroundColor(DesignSystem.Colors.secondaryText)
                NavigationLink(destination: LogsListView(recipeId: recipeId)) {
                    Image(systemName: AppIcon.forward)
                        .foregroundColor(DesignSystem.Colors.tertiaryText)
                }
            }

            if viewModel.logs.isEmpty {
                // Empty state (icon only)
                VStack(spacing: DesignSystem.Spacing.sm) {
                    Image(systemName: AppIcon.addPhoto)
                        .font(.system(size: DesignSystem.IconSize.xxl))
                        .foregroundColor(DesignSystem.Colors.tertiaryText)
                    Text("+")
                        .font(DesignSystem.Typography.caption)
                        .foregroundColor(DesignSystem.Colors.tertiaryText)
                }
                .frame(maxWidth: .infinity)
                .frame(height: 80)
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: DesignSystem.Spacing.sm) {
                        ForEach(viewModel.logs) { log in
                            NavigationLink(destination: LogDetailView(logId: log.id)) {
                                ZStack(alignment: .bottomLeading) {
                                    AsyncImage(url: URL(string: log.images.first?.thumbnailUrl ?? "")) { img in
                                        img.resizable().scaledToFill()
                                    } placeholder: {
                                        Rectangle().fill(DesignSystem.Colors.tertiaryBackground)
                                    }
                                    .frame(width: 80, height: 80)
                                    .cornerRadius(DesignSystem.CornerRadius.sm)
                                    .clipped()

                                    // Rating stars overlay
                                    HStack(spacing: 1) {
                                        ForEach(0..<log.rating, id: \.self) { _ in
                                            Image(systemName: AppIcon.star)
                                                .font(.system(size: 8))
                                                .foregroundColor(DesignSystem.Colors.rating)
                                        }
                                    }
                                    .padding(4)
                                    .background(Color.black.opacity(0.5))
                                    .cornerRadius(4)
                                    .padding(4)
                                }
                            }
                        }

                        // Add log button
                        NavigationLink(destination: CreateLogView()) {
                            VStack {
                                Image(systemName: "plus")
                                    .font(.system(size: DesignSystem.IconSize.lg))
                                    .foregroundColor(DesignSystem.Colors.tertiaryText)
                            }
                            .frame(width: 80, height: 80)
                            .background(DesignSystem.Colors.tertiaryBackground)
                            .cornerRadius(DesignSystem.CornerRadius.sm)
                        }
                    }
                }
            }
        }
        .padding(DesignSystem.Spacing.md)
        .background(DesignSystem.Colors.background)
        .cornerRadius(DesignSystem.CornerRadius.md)
        .padding(.horizontal, DesignSystem.Spacing.md)
        .padding(.top, DesignSystem.Spacing.sm)
    }
}

#Preview { RecipeDetailView(recipeId: "test").environmentObject(AppState()) }
