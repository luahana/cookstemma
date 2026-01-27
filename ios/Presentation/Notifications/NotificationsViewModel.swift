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
                body: notification.body, isRead: true, actor: notification.actor,
                targetId: notification.targetId, targetType: notification.targetType,
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
                body: notification.body, isRead: true, actor: notification.actor,
                targetId: notification.targetId, targetType: notification.targetType,
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
}
