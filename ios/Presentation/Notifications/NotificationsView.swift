import SwiftUI

struct NotificationsView: View {
    @Binding var navigationPath: NavigationPath
    @StateObject private var viewModel = NotificationsViewModel()
    @EnvironmentObject private var appState: AppState
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        Group {
            switch viewModel.state {
            case .idle, .loading:
                ProgressView()
            case .loaded:
                if viewModel.notifications.isEmpty {
                    IconEmptyState(icon: AppIcon.notificationsOutline)
                } else {
                    notificationsList
                }
            case .error(let message):
                ErrorStateView(message: message) { viewModel.loadNotifications() }
            }
        }
        .navigationTitle(String(localized: "settings.notifications"))
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                if !viewModel.notifications.isEmpty {
                    Button {
                        Task { await viewModel.markAllAsRead() }
                    } label: {
                        Image(systemName: AppIcon.checkmarkAll)
                            .foregroundColor(DesignSystem.Colors.primary)
                    }
                }
            }
        }
        .onAppear {
            if case .idle = viewModel.state { viewModel.loadNotifications() }
        }
        .onChange(of: viewModel.unreadCount) { count in
            appState.unreadNotificationCount = count
        }
    }

    private var notificationsList: some View {
        List {
            // New notifications section (icon header)
            if !viewModel.newNotifications.isEmpty {
                Section {
                    ForEach(viewModel.newNotifications) { notification in
                        NotificationRow(notification: notification)
                            .onTapGesture { handleNotificationTap(notification) }
                    }
                    .onDelete { offsets in
                        viewModel.deleteNotifications(at: offsets, from: viewModel.newNotifications)
                    }
                } header: {
                    HStack(spacing: DesignSystem.Spacing.xs) {
                        Image(systemName: AppIcon.new)
                            .foregroundColor(DesignSystem.Colors.primary)
                        // Unread indicator dot
                        Circle()
                            .fill(DesignSystem.Colors.error)
                            .frame(width: 6, height: 6)
                    }
                }
            }

            // Earlier notifications section (icon header)
            if !viewModel.earlierNotifications.isEmpty {
                Section {
                    ForEach(viewModel.earlierNotifications) { notification in
                        NotificationRow(notification: notification)
                            .onTapGesture { handleNotificationTap(notification) }
                    }
                    .onDelete { offsets in
                        viewModel.deleteNotifications(at: offsets, from: viewModel.earlierNotifications)
                    }
                } header: {
                    Image(systemName: AppIcon.history)
                        .foregroundColor(DesignSystem.Colors.secondaryText)
                }
            }

            if viewModel.hasMore {
                ProgressView()
                    .onAppear { viewModel.loadMore() }
            }
        }
        .listStyle(.plain)
        .contentMargins(.bottom, 80, for: .scrollContent)
    }

    private func handleNotificationTap(_ notification: AppNotification) {
        Task { await viewModel.markAsRead(notification) }

        switch notification.type {
        case .newFollower:
            // For followers, navigate to the sender's profile
            if let username = notification.senderUsername {
                // We need sender's user ID - for now use username as workaround
                // TODO: Backend should provide sender's publicId
                navigationPath.append(HomeDestination.user(username))
            }
        case .logComment, .commentReply, .logLike, .commentLike:
            // For all comment-related notifications, use logId directly
            if let logId = notification.logId {
                navigationPath.append(HomeDestination.log(logId))
            }
        case .recipeCooked, .recipeSaved:
            // Prefer logId if available (user cooked and created a log)
            // Otherwise navigate to the recipe
            if let logId = notification.logId {
                navigationPath.append(HomeDestination.log(logId))
            } else if let recipeId = notification.recipeId {
                navigationPath.append(HomeDestination.recipe(recipeId))
            }
        case .weeklyDigest, .unknown:
            break
        }
    }
}

struct NotificationRow: View {
    let notification: AppNotification

    var body: some View {
        HStack(alignment: .top, spacing: DesignSystem.Spacing.sm) {
            // Icon or avatar
            if let avatarUrl = notification.senderProfileImageUrl {
                AvatarView(url: avatarUrl, size: DesignSystem.AvatarSize.sm)
            } else {
                Image(systemName: notification.type.iconName)
                    .font(.title3)
                    .frame(width: 40, height: 40)
                    .foregroundColor(DesignSystem.Colors.primary)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(notification.title)
                    .font(DesignSystem.Typography.subheadline)
                    .fontWeight(notification.isRead ? .regular : .semibold)

                if !notification.body.isEmpty {
                    Text(notification.body)
                        .font(DesignSystem.Typography.body)
                        .foregroundColor(DesignSystem.Colors.secondaryText)
                        .lineLimit(2)
                }

                Text(notification.createdAt.timeAgo())
                    .font(DesignSystem.Typography.caption)
                    .foregroundColor(DesignSystem.Colors.secondaryText)
            }

            Spacer()

            if let thumbnailUrl = notification.thumbnailUrl {
                AsyncImage(url: URL(string: thumbnailUrl)) { img in
                    img.resizable().scaledToFill()
                } placeholder: {
                    Rectangle().fill(DesignSystem.Colors.secondaryBackground)
                }
                .frame(width: 50, height: 50)
                .cornerRadius(DesignSystem.CornerRadius.xs)
                .clipped()
            }

            if !notification.isRead {
                Circle()
                    .fill(DesignSystem.Colors.primary)
                    .frame(width: 8, height: 8)
            }
        }
        .padding(.vertical, DesignSystem.Spacing.xs)
        .background(notification.isRead ? Color.clear : DesignSystem.Colors.primary.opacity(0.05))
    }
}

#Preview {
    NavigationStack {
        NotificationsView(navigationPath: .constant(NavigationPath()))
    }
    .environmentObject(AppState())
}
