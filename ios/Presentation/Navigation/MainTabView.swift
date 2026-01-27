import SwiftUI

// MARK: - Main Tab View (Icons Only)
struct MainTabView: View {
    @State private var selectedTab: Tab = .home
    @State private var previousTab: Tab = .home
    @State private var showCreateLog = false
    @EnvironmentObject private var appState: AppState
    @EnvironmentObject private var authManager: AuthManager

    enum Tab: Int, CaseIterable {
        case home, recipes, create, search, profile

        var icon: String {
            switch self {
            case .home: return AppIcon.homeOutline
            case .recipes: return AppIcon.recipesOutline
            case .create: return AppIcon.createOutline
            case .search: return AppIcon.search
            case .profile: return AppIcon.profileOutline
            }
        }

        var activeIcon: String {
            switch self {
            case .home: return AppIcon.home
            case .recipes: return AppIcon.recipes
            case .create: return AppIcon.create
            case .search: return AppIcon.search
            case .profile: return AppIcon.profile
            }
        }

        var requiresAuth: Bool {
            switch self {
            case .home, .recipes, .search: return false
            case .create, .profile: return true
            }
        }
    }

    var body: some View {
        ZStack(alignment: .bottom) {
            TabView(selection: $selectedTab) {
                HomeFeedView()
                    .tag(Tab.home)
                    .toolbar(.hidden, for: .tabBar)

                RecipesListView()
                    .tag(Tab.recipes)
                    .toolbar(.hidden, for: .tabBar)

                Color.clear // Placeholder for create tab
                    .tag(Tab.create)
                    .toolbar(.hidden, for: .tabBar)

                SearchView()
                    .tag(Tab.search)
                    .toolbar(.hidden, for: .tabBar)

                ProfileView()
                    .tag(Tab.profile)
                    .toolbar(.hidden, for: .tabBar)
            }

            // Custom Tab Bar
            CustomTabBar(selectedTab: $selectedTab, showCreateLog: $showCreateLog, onTabTapped: handleTabTap)
        }
        .sheet(isPresented: $showCreateLog) {
            CreateLogView()
        }
        .onChange(of: selectedTab) { _, newTab in
            if newTab == .create {
                // Create tab should show sheet, handled by handleTabTap
                selectedTab = previousTab
            }
        }
    }

    private func handleTabTap(_ tab: Tab) {
        if tab == .create {
            // Create always requires auth
            appState.requireAuth {
                showCreateLog = true
            }
            return
        }

        if tab.requiresAuth && !authManager.isAuthenticated {
            appState.requireAuth {
                previousTab = selectedTab
                selectedTab = tab
            }
        } else {
            // If tapping the same tab, trigger scroll to top and refresh
            if tab == selectedTab {
                switch tab {
                case .home:
                    appState.triggerHomeScrollToTop()
                case .recipes:
                    appState.triggerRecipesScrollToTop()
                case .search:
                    appState.triggerSearchScrollToTop()
                case .profile:
                    appState.triggerProfileScrollToTop()
                case .create:
                    break  // Create is a sheet, not a tab view
                }
            }
            previousTab = selectedTab
            selectedTab = tab
        }
    }
}

// MARK: - Custom Tab Bar (Icons Only)
struct CustomTabBar: View {
    @Binding var selectedTab: MainTabView.Tab
    @Binding var showCreateLog: Bool
    var onTabTapped: (MainTabView.Tab) -> Void
    @EnvironmentObject private var appState: AppState

    var body: some View {
        HStack(spacing: 0) {
            ForEach(MainTabView.Tab.allCases, id: \.rawValue) { tab in
                TabBarButton(
                    tab: tab,
                    isSelected: selectedTab == tab,
                    badge: badgeCount(for: tab)
                ) {
                    withAnimation(DesignSystem.Animation.quick) {
                        onTabTapped(tab)
                    }
                }
                .frame(maxWidth: .infinity)
            }
        }
        .padding(.horizontal, DesignSystem.Spacing.sm)
        .padding(.top, DesignSystem.Spacing.sm)
        .background(
            DesignSystem.Colors.background
                .shadow(color: .black.opacity(0.05), radius: 8, y: -4)
                .ignoresSafeArea(edges: .bottom)
        )
    }

    private func badgeCount(for tab: MainTabView.Tab) -> Int {
        switch tab {
        case .home: return 0
        case .recipes: return 0
        case .create: return 0
        case .search: return 0
        case .profile: return appState.unreadNotificationCount
        }
    }
}

// MARK: - Tab Bar Button
struct TabBarButton: View {
    let tab: MainTabView.Tab
    let isSelected: Bool
    var badge: Int = 0
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: DesignSystem.Spacing.xxxs) {
                ZStack(alignment: .topTrailing) {
                    Image(systemName: isSelected ? tab.activeIcon : tab.icon)
                        .font(.system(size: DesignSystem.IconSize.lg))
                        .foregroundColor(isSelected ? DesignSystem.Colors.primary : DesignSystem.Colors.secondaryText)

                    if badge > 0 {
                        Circle()
                            .fill(Color.red)
                            .frame(width: 8, height: 8)
                            .offset(x: 4, y: -4)
                    }
                }

                // Small indicator dot for selected state
                Circle()
                    .fill(isSelected ? DesignSystem.Colors.primary : Color.clear)
                    .frame(width: 4, height: 4)
            }
        }
    }
}

// MARK: - Navigation Bar (Icon-Based)
struct IconNavigationBar<Leading: View, Trailing: View>: View {
    let leading: Leading
    let trailing: Trailing
    var showDivider: Bool = false

    init(
        @ViewBuilder leading: () -> Leading,
        @ViewBuilder trailing: () -> Trailing,
        showDivider: Bool = false
    ) {
        self.leading = leading()
        self.trailing = trailing()
        self.showDivider = showDivider
    }

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                leading
                Spacer()
                trailing
            }
            .padding(.horizontal, DesignSystem.Spacing.md)
            .padding(.vertical, DesignSystem.Spacing.sm)

            if showDivider {
                Divider()
            }
        }
        .background(DesignSystem.Colors.background)
    }
}

// Convenience init for common patterns
extension IconNavigationBar where Leading == EmptyView {
    init(@ViewBuilder trailing: () -> Trailing, showDivider: Bool = false) {
        self.leading = EmptyView()
        self.trailing = trailing()
        self.showDivider = showDivider
    }
}

extension IconNavigationBar where Trailing == EmptyView {
    init(@ViewBuilder leading: () -> Leading, showDivider: Bool = false) {
        self.leading = leading()
        self.trailing = EmptyView()
        self.showDivider = showDivider
    }
}

// MARK: - Back Button
struct BackButton: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        Button { dismiss() } label: {
            Image(systemName: AppIcon.back)
                .font(.system(size: DesignSystem.IconSize.md, weight: .medium))
                .foregroundColor(DesignSystem.Colors.text)
        }
    }
}

// MARK: - Close Button
struct CloseButton: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        Button { dismiss() } label: {
            Image(systemName: AppIcon.close)
                .font(.system(size: DesignSystem.IconSize.md, weight: .medium))
                .foregroundColor(DesignSystem.Colors.text)
                .frame(width: 32, height: 32)
                .background(DesignSystem.Colors.secondaryBackground)
                .clipShape(Circle())
        }
    }
}

// MARK: - More Options Button
struct MoreOptionsButton: View {
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: AppIcon.more)
                .font(.system(size: DesignSystem.IconSize.md))
                .foregroundColor(DesignSystem.Colors.text)
        }
    }
}

#Preview {
    MainTabView()
        .environmentObject(AppState())
        .environmentObject(AuthManager.shared)
}
