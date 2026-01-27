import SwiftUI

enum FollowListTab: String, CaseIterable {
    case followers = "Followers"
    case following = "Following"
}

struct FollowersListView: View {
    let userId: String
    @State private var selectedTab: FollowListTab = .followers
    @StateObject private var viewModel: FollowersListViewModel

    init(userId: String, initialTab: FollowListTab = .followers) {
        self.userId = userId
        self._selectedTab = State(initialValue: initialTab)
        self._viewModel = StateObject(wrappedValue: FollowersListViewModel(userId: userId))
    }

    var body: some View {
        VStack(spacing: 0) {
            // Tab picker
            Picker("", selection: $selectedTab) {
                ForEach(FollowListTab.allCases, id: \.self) { tab in
                    Text(tab.rawValue).tag(tab)
                }
            }
            .pickerStyle(.segmented)
            .padding()

            // Search bar
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(DesignSystem.Colors.secondaryText)
                TextField("Search \(selectedTab.rawValue.lowercased())...", text: $viewModel.searchQuery)
            }
            .padding()
            .background(DesignSystem.Colors.secondaryBackground)
            .cornerRadius(DesignSystem.CornerRadius.md)
            .padding(.horizontal)

            // List
            List {
                ForEach(filteredUsers) { user in
                    NavigationLink(destination: ProfileView(userId: user.id)) {
                        FollowUserRow(user: user, onFollowToggle: {
                            Task { await viewModel.toggleFollow(user) }
                        })
                    }
                }

                if viewModel.hasMore {
                    ProgressView()
                        .onAppear { viewModel.loadMore(for: selectedTab) }
                }
            }
            .listStyle(.plain)
        }
        .navigationTitle(selectedTab.rawValue)
        .onChange(of: selectedTab) { newTab in
            viewModel.switchTab(to: newTab)
        }
        .onAppear { viewModel.loadInitial(for: selectedTab) }
    }

    private var filteredUsers: [FollowUser] {
        let users = selectedTab == .followers ? viewModel.followers : viewModel.following
        if viewModel.searchQuery.isEmpty {
            return users
        }
        return users.filter {
            $0.username.localizedCaseInsensitiveContains(viewModel.searchQuery) ||
            ($0.displayName?.localizedCaseInsensitiveContains(viewModel.searchQuery) ?? false)
        }
    }
}

struct FollowUserRow: View {
    let user: FollowUser
    let onFollowToggle: () -> Void

    var body: some View {
        HStack {
            AvatarView(url: user.avatarUrl, size: DesignSystem.AvatarSize.sm)

            VStack(alignment: .leading, spacing: 2) {
                Text(user.displayName ?? user.username)
                    .font(DesignSystem.Typography.subheadline)
                    .fontWeight(.medium)
                Text("@\(user.username)")
                    .font(DesignSystem.Typography.caption)
                    .foregroundColor(DesignSystem.Colors.secondaryText)
                if let level = user.level {
                    Text("Level \(level) · \(user.logCount ?? 0) logs")
                        .font(DesignSystem.Typography.caption)
                        .foregroundColor(DesignSystem.Colors.secondaryText)
                }
            }

            Spacer()

            if !user.isCurrentUser {
                FollowButton(isFollowing: user.isFollowing, action: onFollowToggle)
            }
        }
        .padding(.vertical, DesignSystem.Spacing.xs)
    }
}

// MARK: - FollowUser Model
struct FollowUser: Identifiable, Equatable {
    let id: String
    let username: String
    let displayName: String?
    let avatarUrl: String?
    let level: Int?
    let logCount: Int?
    var isFollowing: Bool
    let isCurrentUser: Bool
}

// MARK: - ViewModel
@MainActor
final class FollowersListViewModel: ObservableObject {
    @Published private(set) var followers: [FollowUser] = []
    @Published private(set) var following: [FollowUser] = []
    @Published private(set) var isLoading = false
    @Published private(set) var hasMore = true
    @Published var searchQuery = ""

    private let userId: String
    private let userRepository: UserRepositoryProtocol
    private var followersCursor: String?
    private var followingCursor: String?
    private var currentTab: FollowListTab = .followers

    init(userId: String, userRepository: UserRepositoryProtocol = UserRepository()) {
        self.userId = userId
        self.userRepository = userRepository
    }

    func switchTab(to tab: FollowListTab) {
        currentTab = tab
        if tab == .followers && followers.isEmpty {
            loadInitial(for: tab)
        } else if tab == .following && following.isEmpty {
            loadInitial(for: tab)
        }
    }

    func loadInitial(for tab: FollowListTab) {
        guard !isLoading else { return }
        isLoading = true
        Task {
            let result = tab == .followers
                ? await userRepository.getFollowers(userId: userId, cursor: nil)
                : await userRepository.getFollowing(userId: userId, cursor: nil)

            isLoading = false
            if case .success(let response) = result {
                let users = response.content.map { mapToFollowUser($0) }
                if tab == .followers {
                    followers = users
                    followersCursor = response.nextCursor
                } else {
                    following = users
                    followingCursor = response.nextCursor
                }
                hasMore = response.hasMore
            }
        }
    }

    func loadMore(for tab: FollowListTab) {
        guard !isLoading, hasMore else { return }
        let cursor = tab == .followers ? followersCursor : followingCursor
        guard cursor != nil else { return }

        isLoading = true
        Task {
            let result = tab == .followers
                ? await userRepository.getFollowers(userId: userId, cursor: cursor)
                : await userRepository.getFollowing(userId: userId, cursor: cursor)

            isLoading = false
            if case .success(let response) = result {
                let users = response.content.map { mapToFollowUser($0) }
                if tab == .followers {
                    followers.append(contentsOf: users)
                    followersCursor = response.nextCursor
                } else {
                    following.append(contentsOf: users)
                    followingCursor = response.nextCursor
                }
                hasMore = response.hasMore
            }
        }
    }

    func toggleFollow(_ user: FollowUser) async {
        let wasFollowing = user.isFollowing

        // Optimistic update
        updateFollowState(for: user.id, isFollowing: !wasFollowing)

        let result = wasFollowing
            ? await userRepository.unfollow(userId: user.id)
            : await userRepository.follow(userId: user.id)

        if case .failure = result {
            // Revert on failure
            updateFollowState(for: user.id, isFollowing: wasFollowing)
        }
    }

    private func updateFollowState(for userId: String, isFollowing: Bool) {
        if let index = followers.firstIndex(where: { $0.id == userId }) {
            followers[index] = FollowUser(
                id: followers[index].id,
                username: followers[index].username,
                displayName: followers[index].displayName,
                avatarUrl: followers[index].avatarUrl,
                level: followers[index].level,
                logCount: followers[index].logCount,
                isFollowing: isFollowing,
                isCurrentUser: followers[index].isCurrentUser
            )
        }
        if let index = following.firstIndex(where: { $0.id == userId }) {
            following[index] = FollowUser(
                id: following[index].id,
                username: following[index].username,
                displayName: following[index].displayName,
                avatarUrl: following[index].avatarUrl,
                level: following[index].level,
                logCount: following[index].logCount,
                isFollowing: isFollowing,
                isCurrentUser: following[index].isCurrentUser
            )
        }
    }

    private func mapToFollowUser(_ summary: UserSummary) -> FollowUser {
        FollowUser(
            id: summary.id,
            username: summary.username,
            displayName: summary.displayName,
            avatarUrl: summary.avatarUrl,
            level: nil, // Would come from extended API response
            logCount: nil,
            isFollowing: false, // Would need to be populated from API
            isCurrentUser: false // Would check against current user ID
        )
    }
}

#Preview { NavigationStack { FollowersListView(userId: "preview") } }
