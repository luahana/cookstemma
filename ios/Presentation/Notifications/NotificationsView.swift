import SwiftUI

struct NotificationsView: View {
    @StateObject private var viewModel = NotificationsViewModel()
    @EnvironmentObject private var appState: AppState

    var body: some View {
        NavigationStack {
            Group {
                switch viewModel.state {
                case .idle, .loading:
                    LoadingView()
                case .loaded:
                    if viewModel.notifications.isEmpty {
                        // Empty state (icon only)
                        IconEmptyState(icon: AppIcon.notificationsOutline)
                    } else {
                        notificationsList
                    }
                case .error(let message):
                    ErrorStateView(message: message) { viewModel.loadNotifications() }
                }
            }
            .background(DesignSystem.Colors.secondaryBackground)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    // Icon header
                    Image(systemName: AppIcon.notifications)
                        .font(.system(size: DesignSystem.IconSize.lg))
                        .foregroundColor(DesignSystem.Colors.primary)
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    if !viewModel.notifications.isEmpty {
                        // Mark all button (icon only)
                        Button {
                            Task { await viewModel.markAllAsRead() }
                        } label: {
                            Image(systemName: AppIcon.checkmarkAll)
                                .foregroundColor(DesignSystem.Colors.primary)
                        }
                    }
                }
            }
            .refreshable { viewModel.loadNotifications() }
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
    }

    private func handleNotificationTap(_ notification: AppNotification) {
        Task { await viewModel.markAsRead(notification) }

        guard let targetId = notification.targetId else { return }

        switch notification.type {
        case .newFollower:
            appState.deepLinkDestination = .user(id: notification.actor?.id ?? targetId)
        case .logComment, .commentReply, .logLike:
            appState.deepLinkDestination = .log(id: targetId, commentId: nil)
        case .recipeCooked, .recipeSaved:
            if notification.targetType == .log {
                appState.deepLinkDestination = .log(id: targetId)
            } else {
                appState.deepLinkDestination = .recipe(id: targetId)
            }
        case .commentLike:
            appState.deepLinkDestination = .log(id: targetId)
        case .weeklyDigest:
            break // No navigation for weekly digest
        }
    }
}

struct NotificationRow: View {
    let notification: AppNotification

    var body: some View {
        HStack(alignment: .top, spacing: DesignSystem.Spacing.sm) {
            // Icon or avatar
            if let avatarUrl = notification.actor?.avatarUrl {
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

                Text(notification.createdAt, style: .relative)
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

#Preview { NotificationsView().environmentObject(AppState()) }
