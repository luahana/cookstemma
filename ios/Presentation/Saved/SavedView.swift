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
    @State private var recipes: [RecipeSummary] = []
    @State private var isLoading = true

    var body: some View {
        Group {
            if isLoading {
                LoadingView()
            } else if recipes.isEmpty {
                // Empty state (icon only)
                IconEmptyState(icon: AppIcon.saveOutline)
            } else {
                ScrollView {
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: DesignSystem.Spacing.sm) {
                        ForEach(recipes) { recipe in
                            NavigationLink(destination: RecipeDetailView(recipeId: recipe.id)) {
                                SavedGridItem(imageUrl: recipe.coverImageUrl)
                            }
                        }
                    }
                    .padding(DesignSystem.Spacing.md)
                    .safeAreaPadding(.bottom)
                }
            }
        }
    }
}

// MARK: - Saved Logs View
struct SavedLogsView: View {
    @State private var logs: [CookingLogSummary] = []
    @State private var isLoading = true

    var body: some View {
        Group {
            if isLoading {
                LoadingView()
            } else if logs.isEmpty {
                // Empty state (icon only)
                IconEmptyState(icon: AppIcon.saveOutline)
            } else {
                ScrollView {
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: DesignSystem.Spacing.sm) {
                        ForEach(logs) { log in
                            NavigationLink(destination: LogDetailView(logId: log.id)) {
                                ZStack(alignment: .bottomLeading) {
                                    SavedGridItem(imageUrl: log.images.first?.thumbnailUrl)

                                    // Rating overlay (stars only)
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
                    }
                    .padding(DesignSystem.Spacing.md)
                    .safeAreaPadding(.bottom)
                }
            }
        }
    }
}

// MARK: - Saved Grid Item
struct SavedGridItem: View {
    let imageUrl: String?

    var body: some View {
        AsyncImage(url: URL(string: imageUrl ?? "")) { img in
            img.resizable().scaledToFill()
        } placeholder: {
            Rectangle().fill(DesignSystem.Colors.tertiaryBackground)
        }
        .frame(height: 120)
        .cornerRadius(DesignSystem.CornerRadius.sm)
        .clipped()
        .contentShape(Rectangle())
    }
}

#Preview {
    SavedView()
        .environmentObject(AuthManager.shared)
        .environmentObject(AppState())
}
