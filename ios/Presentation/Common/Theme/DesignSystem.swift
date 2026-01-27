import SwiftUI

enum DesignSystem {
    // MARK: - Colors
    enum Colors {
        // Brand orange colors (hex values)
        static let primary = Color(hex: "FF6B35")         // Cookstemma orange
        static let primaryLight = Color(hex: "FF8A5C")    // Lighter orange
        static let primaryDark = Color(hex: "E55A2B")     // Darker orange

        static let background = Color(uiColor: .systemBackground)
        static let secondaryBackground = Color(uiColor: .secondarySystemBackground)
        static let tertiaryBackground = Color(uiColor: .tertiarySystemBackground)

        static let text = Color(uiColor: .label)
        static let secondaryText = Color(uiColor: .secondaryLabel)
        static let tertiaryText = Color(uiColor: .tertiaryLabel)

        static let separator = Color(uiColor: .separator)
        static let border = Color(uiColor: .opaqueSeparator)

        static let success = Color.green
        static let warning = Color.orange
        static let error = Color.red
        static let like = Color.red
        static let bookmark = Color.yellow
        static let share = Color.blue
        static let rating = Color.yellow
        static let primaryText = Color(uiColor: .label)
    }

    // MARK: - Typography
    enum Typography {
        static let largeTitle = Font.largeTitle.weight(.bold)
        static let title = Font.title.weight(.semibold)
        static let title2 = Font.title2.weight(.semibold)
        static let title3 = Font.title3.weight(.medium)
        static let headline = Font.headline
        static let body = Font.body
        static let callout = Font.callout
        static let subheadline = Font.subheadline
        static let footnote = Font.footnote
        static let caption = Font.caption
        static let caption2 = Font.caption2
    }

    // MARK: - Spacing
    enum Spacing {
        static let xxxs: CGFloat = 2
        static let xxs: CGFloat = 4
        static let xs: CGFloat = 8
        static let sm: CGFloat = 12
        static let md: CGFloat = 16
        static let lg: CGFloat = 24
        static let xl: CGFloat = 32
        static let xxl: CGFloat = 48
        static let xxxl: CGFloat = 64
    }

    // MARK: - Corner Radius
    enum CornerRadius {
        static let xs: CGFloat = 4
        static let sm: CGFloat = 8
        static let md: CGFloat = 12
        static let lg: CGFloat = 16
        static let xl: CGFloat = 24
        static let full: CGFloat = 999
    }

    // MARK: - Icon Sizes
    enum IconSize {
        static let xs: CGFloat = 12
        static let sm: CGFloat = 16
        static let md: CGFloat = 20
        static let lg: CGFloat = 24
        static let xl: CGFloat = 32
        static let xxl: CGFloat = 48
    }

    // MARK: - Avatar Sizes
    enum AvatarSize {
        static let xs: CGFloat = 24
        static let sm: CGFloat = 32
        static let md: CGFloat = 40
        static let lg: CGFloat = 56
        static let xl: CGFloat = 80
        static let xxl: CGFloat = 120
    }

    // MARK: - Animation
    enum Animation {
        static let quick = SwiftUI.Animation.easeInOut(duration: 0.15)
        static let standard = SwiftUI.Animation.easeInOut(duration: 0.25)
        static let slow = SwiftUI.Animation.easeInOut(duration: 0.4)
        static let spring = SwiftUI.Animation.spring(response: 0.35, dampingFraction: 0.7)
    }
}

// MARK: - View Modifiers
extension View {
    func cardStyle() -> some View {
        self.background(DesignSystem.Colors.background)
            .cornerRadius(DesignSystem.CornerRadius.md)
            .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
    }

    func primaryButtonStyle() -> some View {
        self.font(DesignSystem.Typography.headline)
            .foregroundColor(.white)
            .padding(.horizontal, DesignSystem.Spacing.lg)
            .padding(.vertical, DesignSystem.Spacing.sm)
            .background(DesignSystem.Colors.primary)
            .cornerRadius(DesignSystem.CornerRadius.md)
    }

    func secondaryButtonStyle() -> some View {
        self.font(DesignSystem.Typography.headline)
            .foregroundColor(DesignSystem.Colors.primary)
            .padding(.horizontal, DesignSystem.Spacing.lg)
            .padding(.vertical, DesignSystem.Spacing.sm)
            .background(DesignSystem.Colors.primary.opacity(0.1))
            .cornerRadius(DesignSystem.CornerRadius.md)
    }
}

// MARK: - Color Hex Init
extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default: (a, r, g, b) = (1, 1, 1, 0)
        }
        self.init(.sRGB, red: Double(r) / 255, green: Double(g) / 255, blue: Double(b) / 255, opacity: Double(a) / 255)
    }
}
