import SwiftUI

// MARK: - App Icons (SF Symbols)
enum AppIcon {
    // Tab Bar
    static let home = "house.fill"
    static let homeOutline = "house"
    static let recipes = "book.fill"
    static let recipesOutline = "book"
    static let create = "plus.circle.fill"
    static let createOutline = "plus.circle"
    static let saved = "bookmark.fill"
    static let savedOutline = "bookmark"
    static let profile = "person.fill"
    static let profileOutline = "person"

    // Actions
    static let like = "heart.fill"
    static let likeOutline = "heart"
    static let comment = "bubble.left.fill"
    static let commentOutline = "bubble.left"
    static let share = "square.and.arrow.up"
    static let save = "bookmark.fill"
    static let saveOutline = "bookmark"
    static let more = "ellipsis"

    // Navigation
    static let back = "chevron.left"
    static let forward = "chevron.right"
    static let close = "xmark"
    static let search = "magnifyingglass"
    static let filter = "line.3.horizontal.decrease.circle"
    static let sort = "arrow.up.arrow.down"
    static let notifications = "bell.fill"
    static let notificationsOutline = "bell"
    static let settings = "gearshape.fill"

    // Content
    static let recipe = "book.fill"
    static let log = "camera.fill"
    static let photo = "photo.fill"
    static let addPhoto = "photo.badge.plus"
    static let timer = "clock.fill"
    static let servings = "person.2.fill"
    static let star = "star.fill"
    static let starOutline = "star"
    static let fire = "flame.fill"
    static let chef = "fork.knife"
    static let ingredients = "list.bullet.clipboard"
    static let steps = "checklist"

    // Social
    static let follow = "person.badge.plus"
    static let following = "person.badge.checkmark"
    static let followers = "person.2.fill"
    static let block = "hand.raised.fill"
    static let report = "flag.fill"

    // Status
    static let success = "checkmark.circle.fill"
    static let error = "exclamationmark.triangle.fill"
    static let warning = "exclamationmark.circle.fill"
    static let info = "info.circle.fill"
    static let empty = "tray"
    static let loading = "arrow.2.circlepath"

    // Edit
    static let edit = "pencil"
    static let delete = "trash.fill"
    static let camera = "camera.fill"
    static let gallery = "photo.on.rectangle"

    // Search & Filter
    static let history = "clock.arrow.circlepath"
    static let trending = "flame"
    static let trash = "trash"
    static let checkmark = "checkmark"
    static let checkmarkAll = "checkmark.circle.fill"
    static let new = "sparkles"
    static let reset = "arrow.counterclockwise"
}

// MARK: - Icon Button (No Text)
struct IconActionButton: View {
    let icon: String
    let isActive: Bool
    var activeColor: Color = DesignSystem.Colors.primary
    var inactiveColor: Color = DesignSystem.Colors.secondaryText
    var size: CGFloat = DesignSystem.IconSize.md
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: size))
                .foregroundColor(isActive ? activeColor : inactiveColor)
        }
    }
}

// MARK: - Icon with Count (Compact)
struct IconWithCount: View {
    let icon: String
    let activeIcon: String
    let count: Int
    var isActive: Bool = false
    var activeColor: Color = DesignSystem.Colors.primary
    var size: CGFloat = DesignSystem.IconSize.md

    var body: some View {
        HStack(spacing: DesignSystem.Spacing.xxs) {
            Image(systemName: isActive ? activeIcon : icon)
                .font(.system(size: size))
                .foregroundColor(isActive ? activeColor : DesignSystem.Colors.secondaryText)
            if count > 0 {
                Text(count.abbreviated)
                    .font(DesignSystem.Typography.caption)
                    .foregroundColor(DesignSystem.Colors.secondaryText)
            }
        }
    }
}

// MARK: - Icon Badge (For Notifications)
struct IconBadge: View {
    let icon: String
    let count: Int
    var size: CGFloat = DesignSystem.IconSize.lg

    var body: some View {
        ZStack(alignment: .topTrailing) {
            Image(systemName: icon)
                .font(.system(size: size))
            if count > 0 {
                Text(count > 99 ? "99+" : "\(count)")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(.white)
                    .padding(.horizontal, 4)
                    .padding(.vertical, 2)
                    .background(Color.red)
                    .clipShape(Capsule())
                    .offset(x: 8, y: -8)
            }
        }
    }
}

// MARK: - Tab Bar Icon
struct TabIcon: View {
    let icon: String
    let activeIcon: String
    let isSelected: Bool
    var badge: Int = 0

    var body: some View {
        ZStack(alignment: .topTrailing) {
            Image(systemName: isSelected ? activeIcon : icon)
                .font(.system(size: DesignSystem.IconSize.lg))
                .foregroundColor(isSelected ? DesignSystem.Colors.primary : DesignSystem.Colors.secondaryText)
            if badge > 0 {
                Circle()
                    .fill(Color.red)
                    .frame(width: 8, height: 8)
                    .offset(x: 4, y: -4)
            }
        }
    }
}

// MARK: - Follow Icon Button
struct FollowIconButton: View {
    let isFollowing: Bool
    let action: () async -> Void
    @State private var isLoading = false

    var body: some View {
        Button {
            Task {
                isLoading = true
                await action()
                isLoading = false
            }
        } label: {
            if isLoading {
                ProgressView()
                    .frame(width: 36, height: 36)
            } else {
                Image(systemName: isFollowing ? AppIcon.following : AppIcon.follow)
                    .font(.system(size: DesignSystem.IconSize.lg))
                    .foregroundColor(isFollowing ? DesignSystem.Colors.success : DesignSystem.Colors.primary)
                    .frame(width: 36, height: 36)
                    .background(
                        Circle()
                            .fill(isFollowing ? DesignSystem.Colors.success.opacity(0.1) : DesignSystem.Colors.primary.opacity(0.1))
                    )
            }
        }
        .disabled(isLoading)
    }
}

// MARK: - Stat Icon (Number + Icon)
struct StatIcon: View {
    let icon: String
    let value: Int
    var size: CGFloat = DesignSystem.IconSize.sm

    var body: some View {
        HStack(spacing: DesignSystem.Spacing.xxs) {
            Image(systemName: icon)
                .font(.system(size: size))
                .foregroundColor(DesignSystem.Colors.secondaryText)
            Text(value.abbreviated)
                .font(DesignSystem.Typography.caption)
                .foregroundColor(DesignSystem.Colors.text)
        }
    }
}

// MARK: - Rating Badge (Compact)
struct RatingBadge: View {
    let rating: Double

    var body: some View {
        HStack(spacing: 2) {
            Image(systemName: AppIcon.star)
                .font(.system(size: DesignSystem.IconSize.xs))
                .foregroundColor(.yellow)
            Text(String(format: "%.1f", rating))
                .font(DesignSystem.Typography.caption)
                .fontWeight(.medium)
        }
        .padding(.horizontal, DesignSystem.Spacing.xs)
        .padding(.vertical, DesignSystem.Spacing.xxxs)
        .background(DesignSystem.Colors.secondaryBackground)
        .cornerRadius(DesignSystem.CornerRadius.xs)
    }
}

// MARK: - Time Badge
struct TimeBadge: View {
    let minutes: Int

    var body: some View {
        HStack(spacing: 2) {
            Image(systemName: AppIcon.timer)
                .font(.system(size: DesignSystem.IconSize.xs))
            Text(minutes < 60 ? "\(minutes)m" : "\(minutes/60)h")
                .font(DesignSystem.Typography.caption)
        }
        .foregroundColor(DesignSystem.Colors.secondaryText)
    }
}

// MARK: - Servings Badge
struct ServingsBadge: View {
    let count: Int

    var body: some View {
        HStack(spacing: 2) {
            Image(systemName: AppIcon.servings)
                .font(.system(size: DesignSystem.IconSize.xs))
            Text("\(count)")
                .font(DesignSystem.Typography.caption)
        }
        .foregroundColor(DesignSystem.Colors.secondaryText)
    }
}

// MARK: - Cook Count Badge
struct CookCountBadge: View {
    let count: Int

    var body: some View {
        HStack(spacing: 2) {
            Image(systemName: AppIcon.chef)
                .font(.system(size: DesignSystem.IconSize.xs))
            Text(count.abbreviated)
                .font(DesignSystem.Typography.caption)
        }
        .foregroundColor(DesignSystem.Colors.secondaryText)
    }
}

// MARK: - Empty State (Icon-Focused)
struct IconEmptyState: View {
    let icon: String
    var subtitle: String? = nil

    var body: some View {
        VStack(spacing: DesignSystem.Spacing.md) {
            Image(systemName: icon)
                .font(.system(size: DesignSystem.IconSize.xxl))
                .foregroundColor(DesignSystem.Colors.tertiaryText)
            if let subtitle = subtitle {
                Text(subtitle)
                    .font(DesignSystem.Typography.caption)
                    .foregroundColor(DesignSystem.Colors.tertiaryText)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - Action Row (Icons Only)
struct ActionRow: View {
    let likeCount: Int
    let commentCount: Int
    let isLiked: Bool
    let isSaved: Bool
    let onLike: () -> Void
    let onComment: () -> Void
    let onShare: () -> Void
    let onSave: () -> Void

    var body: some View {
        HStack(spacing: DesignSystem.Spacing.lg) {
            // Like
            Button(action: onLike) {
                IconWithCount(
                    icon: AppIcon.likeOutline,
                    activeIcon: AppIcon.like,
                    count: likeCount,
                    isActive: isLiked,
                    activeColor: DesignSystem.Colors.like
                )
            }

            // Comment
            Button(action: onComment) {
                IconWithCount(
                    icon: AppIcon.commentOutline,
                    activeIcon: AppIcon.comment,
                    count: commentCount
                )
            }

            // Share
            Button(action: onShare) {
                Image(systemName: AppIcon.share)
                    .font(.system(size: DesignSystem.IconSize.md))
                    .foregroundColor(DesignSystem.Colors.secondaryText)
            }

            Spacer()

            // Save
            Button(action: onSave) {
                Image(systemName: isSaved ? AppIcon.save : AppIcon.saveOutline)
                    .font(.system(size: DesignSystem.IconSize.md))
                    .foregroundColor(isSaved ? DesignSystem.Colors.bookmark : DesignSystem.Colors.secondaryText)
            }
        }
    }
}

// MARK: - Number Extension for Abbreviation
extension Int {
    var abbreviated: String {
        if self < 1000 { return "\(self)" }
        if self < 10000 { return String(format: "%.1fK", Double(self) / 1000).replacingOccurrences(of: ".0K", with: "K") }
        if self < 1000000 { return "\(self / 1000)K" }
        return String(format: "%.1fM", Double(self) / 1000000)
    }
}
