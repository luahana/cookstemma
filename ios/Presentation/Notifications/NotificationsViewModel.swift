import Foundation

enum NotificationsState: Equatable { case idle, loading, loaded, error(String) }

@MainActor
final class NotificationsViewModel: ObservableObject {
    @Published private(set) var state: NotificationsState = .idle
    @Published private(set) var notifications: [AppNotification] = []
    @Published private(set) var unreadCount: Int = 0
    @Published private(set) var hasMore = true

    private let notificationRepository: NotificationRepositoryProtocol
    private var nextCursor: String?

    var newNotifications: [AppNotification] {
        notifications.filter { !$0.isRead }
    }

    var earlierNotifications: [AppNotification] {
        notifications.filter { $0.isRead }
    }

    init(notificationRepository: NotificationRepositoryProtocol = NotificationRepository()) {
        self.notificationRepository = notificationRepository
    }

    func loadNotifications() {
        state = .loading
        Task {
            async let notificationsResult = notificationRepository.getNotifications(cursor: nil)
            async let countResult = notificationRepository.getUnreadCount()

            let (notifications, count) = await (notificationsResult, countResult)

            switch notifications {
            case .success(let response):
                self.notifications = response.content
                self.nextCursor = response.nextCursor
                self.hasMore = response.hasMore
                state = .loaded
            case .failure(let error):
                state = .error(error.localizedDescription)
            }

            if case .success(let count) = count {
                self.unreadCount = count
            }
        }
    }

    func loadMore() {
        guard hasMore, state == .loaded else { return }
        Task {
            let result = await notificationRepository.getNotifications(cursor: nextCursor)
            if case .success(let response) = result {
                notifications.append(contentsOf: response.content)
                nextCursor = response.nextCursor
                hasMore = response.hasMore
            }
        }
    }

    func markAsRead(_ notification: AppNotification) async {
        guard !notification.isRead else { return }

        // Optimistic update
        if let index = notifications.firstIndex(where: { $0.id == notification.id }) {
            notifications[index] = AppNotification(
                id: notification.id, type: notification.type, title: notification.title,
                body: notification.body, isRead: true,
                logId: notification.logId, recipeId: notification.recipeId,
                senderUsername: notification.senderUsername,
                senderProfileImageUrl: notification.senderProfileImageUrl,
                thumbnailUrl: notification.thumbnailUrl, createdAt: notification.createdAt
            )
            unreadCount = max(0, unreadCount - 1)
        }

        let result = await notificationRepository.markAsRead(id: notification.id)
        if case .failure = result {
            // Revert on failure
            if let index = notifications.firstIndex(where: { $0.id == notification.id }) {
                notifications[index] = notification
                unreadCount += 1
            }
        }
    }

    func markAllAsRead() async {
        let unreadNotifications = notifications.filter { !$0.isRead }
        guard !unreadNotifications.isEmpty else { return }

        // Optimistic update
        notifications = notifications.map { notification in
            AppNotification(
                id: notification.id, type: notification.type, title: notification.title,
                body: notification.body, isRead: true,
                logId: notification.logId, recipeId: notification.recipeId,
                senderUsername: notification.senderUsername,
                senderProfileImageUrl: notification.senderProfileImageUrl,
                thumbnailUrl: notification.thumbnailUrl, createdAt: notification.createdAt
            )
        }
        let previousUnreadCount = unreadCount
        unreadCount = 0

        let result = await notificationRepository.markAllAsRead()
        if case .failure = result {
            // Revert on failure - reload to get correct state
            unreadCount = previousUnreadCount
            loadNotifications()
        }
    }

    func deleteNotification(_ notification: AppNotification) async {
        // Optimistic update
        let wasUnread = !notification.isRead
        notifications.removeAll { $0.id == notification.id }
        if wasUnread {
            unreadCount = max(0, unreadCount - 1)
        }

        let result = await notificationRepository.deleteNotification(id: notification.id)
        if case .failure(let error) = result {
            #if DEBUG
            print("[Notifications] Delete failed: \(error)")
            #endif
            // Revert on failure - reload to get correct state
            loadNotifications()
        }
    }

    func deleteNotifications(at offsets: IndexSet, from list: [AppNotification]) {
        Task {
            for index in offsets {
                await deleteNotification(list[index])
            }
        }
    }

    func deleteAllNotifications() async {
        guard !notifications.isEmpty else {
            #if DEBUG
            print("[Notifications] Delete all: no notifications to delete")
            #endif
            return
        }

        #if DEBUG
        print("[Notifications] Delete all: starting with \(notifications.count) notifications")
        #endif

        // Optimistic update
        let previousNotifications = notifications
        let previousUnreadCount = unreadCount
        notifications = []
        unreadCount = 0

        let result = await notificationRepository.deleteAllNotifications()
        switch result {
        case .success:
            #if DEBUG
            print("[Notifications] Delete all: success")
            #endif
        case .failure(let error):
            #if DEBUG
            print("[Notifications] Delete all failed: \(error)")
            #endif
            // Revert on failure
            notifications = previousNotifications
            unreadCount = previousUnreadCount
        }
    }
}
