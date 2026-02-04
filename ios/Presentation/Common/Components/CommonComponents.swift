import SwiftUI
import UIKit

// MARK: - Scroll Offset Preference Key
struct ScrollOffsetPreferenceKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}

// MARK: - Collapsible Header View
struct CollapsibleHeaderView<Content: View, Header: View>: View {
    let header: Header
    let content: Content
    @State private var headerVisible = true
    @State private var lastOffset: CGFloat = 0

    init(@ViewBuilder header: () -> Header, @ViewBuilder content: () -> Content) {
        self.header = header()
        self.content = content()
    }

    var body: some View {
        ZStack(alignment: .top) {
            // Content with scroll tracking
            ScrollView {
                VStack(spacing: 0) {
                    // Spacer for header
                    Color.clear
                        .frame(height: headerVisible ? 56 : 0)

                    // Scroll position tracker
                    GeometryReader { geo in
                        Color.clear.preference(
                            key: ScrollOffsetPreferenceKey.self,
                            value: geo.frame(in: .named("scroll")).minY
                        )
                    }
                    .frame(height: 0)

                    content
                }
            }
            .coordinateSpace(name: "scroll")
            .onPreferenceChange(ScrollOffsetPreferenceKey.self) { offset in
                let delta = offset - lastOffset

                // Only respond to significant changes
                if abs(delta) > 5 {
                    withAnimation(DesignSystem.Animation.quick) {
                        if delta < -10 && offset < -20 {
                            // Scrolling up (content moving down) - hide header
                            headerVisible = false
                        } else if delta > 10 || offset > -10 {
                            // Scrolling down or near top - show header
                            headerVisible = true
                        }
                    }
                    lastOffset = offset
                }
            }

            // Header overlay
            if headerVisible {
                header
                    .frame(height: 56)
                    .frame(maxWidth: .infinity)
                    .background(DesignSystem.Colors.background)
                    .transition(.move(edge: .top).combined(with: .opacity))
            }
        }
    }
}

// MARK: - Loading View
struct LoadingView: View {
    var body: some View {
        VStack(spacing: DesignSystem.Spacing.md) {
            ProgressView()
            Text(String(localized: "common.loading"))
                .font(DesignSystem.Typography.subheadline)
                .foregroundColor(DesignSystem.Colors.secondaryText)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - Empty State View
struct EmptyStateView: View {
    let icon: String
    let title: String
    let message: String
    var actionTitle: String?
    var action: (() -> Void)?

    var body: some View {
        VStack(spacing: DesignSystem.Spacing.md) {
            Image(systemName: icon)
                .font(.system(size: DesignSystem.IconSize.xxl))
                .foregroundColor(DesignSystem.Colors.tertiaryText)
            Text(title).font(DesignSystem.Typography.title3)
            Text(message)
                .font(DesignSystem.Typography.body)
                .foregroundColor(DesignSystem.Colors.secondaryText)
                .multilineTextAlignment(.center)
            if let actionTitle = actionTitle, let action = action {
                Button(action: action) { Text(actionTitle).primaryButtonStyle() }
                    .padding(.top, DesignSystem.Spacing.sm)
            }
        }
        .padding(DesignSystem.Spacing.xl)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - Error State View
struct ErrorStateView: View {
    let message: String
    let retry: () -> Void

    var body: some View {
        VStack(spacing: DesignSystem.Spacing.md) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: DesignSystem.IconSize.xxl))
                .foregroundColor(DesignSystem.Colors.error)
            Text(String(localized: "common.somethingWentWrong")).font(DesignSystem.Typography.title3)
            Text(message)
                .font(DesignSystem.Typography.body)
                .foregroundColor(DesignSystem.Colors.secondaryText)
                .multilineTextAlignment(.center)
            Button(action: retry) { Text(String(localized: "common.tryAgain")).primaryButtonStyle() }
                .padding(.top, DesignSystem.Spacing.sm)
        }
        .padding(DesignSystem.Spacing.xl)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - Star Rating
struct StarRating: View {
    let rating: Int
    var maxRating: Int = 5
    var size: CGFloat = DesignSystem.IconSize.sm

    var body: some View {
        HStack(spacing: 2) {
            ForEach(1...maxRating, id: \.self) { index in
                Image(systemName: index <= rating ? "star.fill" : "star")
                    .font(.system(size: size))
                    .foregroundColor(index <= rating ? .yellow : DesignSystem.Colors.tertiaryText)
            }
        }
    }
}

// MARK: - Interactive Star Rating
struct InteractiveStarRating: View {
    @Binding var rating: Int
    var maxRating: Int = 5
    var size: CGFloat = DesignSystem.IconSize.lg

    var body: some View {
        HStack(spacing: DesignSystem.Spacing.xs) {
            ForEach(1...maxRating, id: \.self) { index in
                Image(systemName: index <= rating ? "star.fill" : "star")
                    .font(.system(size: size))
                    .foregroundColor(index <= rating ? .yellow : DesignSystem.Colors.tertiaryText)
                    .onTapGesture {
                        withAnimation(DesignSystem.Animation.quick) { rating = index }
                    }
            }
        }
    }
}

// MARK: - Photo Grid
struct PhotoGrid: View {
    let images: [ImageInfo]
    var maxImages: Int = 4

    private var displayImages: [ImageInfo] { Array(images.prefix(maxImages)) }
    private var remainingCount: Int { max(0, images.count - maxImages) }

    var body: some View {
        Group {
            switch displayImages.count {
            case 0: EmptyView()
            case 1: singleImage(displayImages[0])
            case 2: twoImages(displayImages)
            case 3: threeImages(displayImages)
            default: fourImages(displayImages)
            }
        }
        .cornerRadius(DesignSystem.CornerRadius.sm)
    }

    private func singleImage(_ image: ImageInfo) -> some View {
        AsyncImage(url: URL(string: image.url)) { img in img.resizable().scaledToFill() }
            placeholder: { Rectangle().fill(DesignSystem.Colors.secondaryBackground) }
            .frame(height: 300).clipped()
    }

    private func twoImages(_ images: [ImageInfo]) -> some View {
        HStack(spacing: 2) {
            ForEach(images) { image in
                AsyncImage(url: URL(string: image.url)) { img in img.resizable().scaledToFill() }
                    placeholder: { Rectangle().fill(DesignSystem.Colors.secondaryBackground) }
                    .frame(height: 200).clipped()
            }
        }
    }

    private func threeImages(_ images: [ImageInfo]) -> some View {
        HStack(spacing: 2) {
            AsyncImage(url: URL(string: images[0].url)) { img in img.resizable().scaledToFill() }
                placeholder: { Rectangle().fill(DesignSystem.Colors.secondaryBackground) }
                .frame(height: 200).clipped()
            VStack(spacing: 2) {
                ForEach(images.dropFirst()) { image in
                    AsyncImage(url: URL(string: image.url)) { img in img.resizable().scaledToFill() }
                        placeholder: { Rectangle().fill(DesignSystem.Colors.secondaryBackground) }
                        .frame(height: 99).clipped()
                }
            }
        }
    }

    private func fourImages(_ images: [ImageInfo]) -> some View {
        VStack(spacing: 2) {
            HStack(spacing: 2) {
                ForEach(images.prefix(2)) { image in
                    AsyncImage(url: URL(string: image.url)) { img in img.resizable().scaledToFill() }
                        placeholder: { Rectangle().fill(DesignSystem.Colors.secondaryBackground) }
                        .frame(height: 150).clipped()
                }
            }
            HStack(spacing: 2) {
                ForEach(Array(images.dropFirst(2).prefix(2))) { image in
                    ZStack {
                        AsyncImage(url: URL(string: image.url)) { img in img.resizable().scaledToFill() }
                            placeholder: { Rectangle().fill(DesignSystem.Colors.secondaryBackground) }
                            .frame(height: 150).clipped()
                        if image.id == images.last?.id && remainingCount > 0 {
                            Color.black.opacity(0.5)
                            Text("+\(remainingCount)").font(DesignSystem.Typography.title).foregroundColor(.white)
                        }
                    }
                }
            }
        }
    }
}

// MARK: - Avatar View
struct AvatarView: View {
    let url: String?
    var name: String? = nil
    var size: CGFloat = DesignSystem.AvatarSize.md

    /// Check if URL is valid (starts with http/https)
    private var isValidUrl: Bool {
        guard let url = url, !url.isEmpty else { return false }
        return url.hasPrefix("http://") || url.hasPrefix("https://")
    }

    /// Get the initial letter from name
    private var initial: String {
        guard let name = name, !name.isEmpty else { return "" }
        let cleanName = name.hasPrefix("@") ? String(name.dropFirst()) : name
        return String(cleanName.prefix(1)).uppercased()
    }

    var body: some View {
        Group {
            if isValidUrl {
                AsyncImage(url: URL(string: url!)) { phase in
                    switch phase {
                    case .success(let image):
                        image.resizable().scaledToFill()
                    case .failure:
                        fallbackView
                    case .empty:
                        ProgressView()
                    @unknown default:
                        fallbackView
                    }
                }
            } else {
                fallbackView
            }
        }
        .frame(width: size, height: size)
        .clipShape(Circle())
    }

    @ViewBuilder
    private var fallbackView: some View {
        if !initial.isEmpty {
            Circle()
                .fill(DesignSystem.Colors.primary.opacity(0.15))
                .overlay(
                    Text(initial)
                        .font(.system(size: size * 0.4, weight: .semibold))
                        .foregroundColor(DesignSystem.Colors.primary)
                )
        } else {
            Circle()
                .fill(DesignSystem.Colors.secondaryBackground)
                .overlay(
                    Image(systemName: "person.fill")
                        .font(.system(size: size * 0.4))
                        .foregroundColor(DesignSystem.Colors.tertiaryText)
                )
        }
    }
}

// MARK: - Follow Button
struct FollowButton: View {
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
                ProgressView().frame(width: 80, height: 32)
            } else {
                Text(isFollowing ? String(localized: "profile.following_button") : String(localized: "profile.follow"))
                    .font(DesignSystem.Typography.subheadline).fontWeight(.medium)
                    .foregroundColor(isFollowing ? DesignSystem.Colors.text : .white)
                    .padding(.horizontal, DesignSystem.Spacing.md)
                    .padding(.vertical, DesignSystem.Spacing.xs)
                    .background(isFollowing ? DesignSystem.Colors.secondaryBackground : DesignSystem.Colors.primary)
                    .cornerRadius(DesignSystem.CornerRadius.full)
            }
        }
        .disabled(isLoading)
    }
}

// MARK: - Date Extension
extension Date {
    func timeAgo() -> String {
        let now = Date()
        let components = Calendar.current.dateComponents([.year, .month, .weekOfYear, .day, .hour, .minute], from: self, to: now)

        if let years = components.year, years > 0 {
            return "\(years)y"
        } else if let months = components.month, months > 0 {
            return "\(months)mo"
        } else if let weeks = components.weekOfYear, weeks > 0 {
            return "\(weeks)w"
        } else if let days = components.day, days > 0 {
            return "\(days)d"
        } else if let hours = components.hour, hours > 0 {
            return "\(hours)h"
        } else if let minutes = components.minute, minutes > 0 {
            return "\(minutes)m"
        } else {
            return "now"
        }
    }
}

// MARK: - Custom Refresh Indicator
struct RefreshIndicator: View {
    let isRefreshing: Bool
    let pullProgress: CGFloat
    let threshold: CGFloat

    var body: some View {
        let height = isRefreshing ? threshold : max(0, min(pullProgress, threshold))

        VStack {
            if isRefreshing || pullProgress > 10 {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle())
                    .scaleEffect(isRefreshing ? 1.0 : min(pullProgress / threshold, 1.0))
                    .opacity(isRefreshing ? 1.0 : min(pullProgress / threshold, 1.0))
            }
        }
        .frame(height: height)
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Custom Refreshable Scroll View
/// A scroll view with custom pull-to-refresh behavior (Instagram-like):
/// - When scrolling up: header scrolls with content
/// - When pulling down at top: header stays fixed, refresh indicator shows below
struct CustomRefreshableScrollView<Content: View>: View {
    let headerHeight: CGFloat
    let onRefresh: () async -> Void
    @ViewBuilder let content: () -> Content

    @Binding var headerScrollOffset: CGFloat
    @Binding var scrollToTopTrigger: Int
    @Binding var programmaticRefreshTrigger: Int
    @State private var isRefreshing = false
    @State private var pullDownAmount: CGFloat = 0
    @State private var hasTriggeredRefresh = false

    private let refreshThreshold: CGFloat = 60

    init(
        headerHeight: CGFloat = 56,
        headerScrollOffset: Binding<CGFloat>,
        scrollToTopTrigger: Binding<Int> = .constant(0),
        programmaticRefreshTrigger: Binding<Int> = .constant(0),
        onRefresh: @escaping () async -> Void,
        @ViewBuilder content: @escaping () -> Content
    ) {
        self.headerHeight = headerHeight
        self._headerScrollOffset = headerScrollOffset
        self._scrollToTopTrigger = scrollToTopTrigger
        self._programmaticRefreshTrigger = programmaticRefreshTrigger
        self.onRefresh = onRefresh
        self.content = content
    }

    var body: some View {
        ZStack(alignment: .top) {
            TrackableScrollView(
                contentInset: headerHeight,
                scrollToTopTrigger: $scrollToTopTrigger,
                pullDownOffset: $pullDownAmount,
                onScroll: { offset in
                    handleScrollOffsetChange(offset)
                }
            ) {
                // Actual content only - no refresh indicator inside scroll
                content()
            }

            // Refresh indicator as overlay - doesn't affect scroll content layout
            if isRefreshing || pullDownAmount > 0 {
                RefreshIndicator(
                    isRefreshing: isRefreshing,
                    pullProgress: pullDownAmount,
                    threshold: refreshThreshold
                )
                .offset(y: headerHeight)
            }
        }
        .onChange(of: programmaticRefreshTrigger) { _, _ in
            triggerRefreshWithAnimation()
        }
    }

    private func handleScrollOffsetChange(_ offset: CGFloat) {
        // offset = 0 at rest
        // offset < 0 when scrolled up (content moved up)
        // offset > 0 when pulling down at top (rubber-banding)

        if offset > 0 && !isRefreshing {
            // Pulling down at top - header stays fixed, show refresh indicator
            pullDownAmount = offset
            headerScrollOffset = 0

            // Check if should trigger refresh
            if offset >= refreshThreshold && !hasTriggeredRefresh {
                hasTriggeredRefresh = true
                triggerRefresh()
            }
        } else {
            // Normal scrolling or at rest - header moves with content
            pullDownAmount = 0
            headerScrollOffset = offset  // 0 at rest, negative when scrolled
            hasTriggeredRefresh = false
        }
    }

    private func triggerRefresh() {
        guard !isRefreshing else { return }

        isRefreshing = true

        Task {
            await onRefresh()
            await MainActor.run {
                withAnimation(DesignSystem.Animation.quick) {
                    isRefreshing = false
                    pullDownAmount = 0
                    hasTriggeredRefresh = false
                }
            }
        }
    }

    private func triggerRefreshWithAnimation() {
        guard !isRefreshing else { return }

        isRefreshing = true

        // Animate the pull-down indicator appearing and content moving down
        withAnimation(.easeOut(duration: 0.3)) {
            pullDownAmount = refreshThreshold
        }

        // Start refresh after pull-down animation
        Task {
            // Small delay to let pull-down animation complete
            try? await Task.sleep(nanoseconds: 300_000_000)

            await onRefresh()

            await MainActor.run {
                // Animate content back up
                withAnimation(.easeInOut(duration: 0.3)) {
                    isRefreshing = false
                    pullDownAmount = 0
                }
            }
        }
    }
}

// MARK: - Trackable Scroll View (UIKit-based)
struct TrackableScrollView<Content: View>: UIViewRepresentable {
    let contentInset: CGFloat  // This is headerHeight (56pt)
    @Binding var scrollToTopTrigger: Int
    @Binding var pullDownOffset: CGFloat
    let onScroll: (CGFloat) -> Void
    @ViewBuilder let content: () -> Content

    func makeCoordinator() -> Coordinator {
        Coordinator(onScroll: onScroll, contentInset: contentInset)
    }

    func makeUIView(context: Context) -> UIScrollView {
        let scrollView = UIScrollView()
        scrollView.delegate = context.coordinator
        scrollView.showsVerticalScrollIndicator = false
        scrollView.showsHorizontalScrollIndicator = false
        scrollView.alwaysBounceVertical = true
        scrollView.backgroundColor = .clear
        scrollView.contentInsetAdjustmentBehavior = .never

        // Content starts at screen top due to _disableSafeArea
        // Need: safe area (~59pt) + header height (contentInset = 56pt) = 115pt
        let totalInset = contentInset
        scrollView.contentInset = UIEdgeInsets(top: totalInset, left: 0, bottom: 0, right: 0)
        scrollView.contentOffset = CGPoint(x: 0, y: -totalInset)

        let hostingController = UIHostingController(rootView: AnyView(content()))
        hostingController.view.backgroundColor = .clear
        hostingController.view.translatesAutoresizingMaskIntoConstraints = false
        hostingController._disableSafeArea = true

        scrollView.addSubview(hostingController.view)

        NSLayoutConstraint.activate([
            hostingController.view.topAnchor.constraint(equalTo: scrollView.contentLayoutGuide.topAnchor),
            hostingController.view.leadingAnchor.constraint(equalTo: scrollView.frameLayoutGuide.leadingAnchor),
            hostingController.view.trailingAnchor.constraint(equalTo: scrollView.frameLayoutGuide.trailingAnchor),
            hostingController.view.bottomAnchor.constraint(equalTo: scrollView.contentLayoutGuide.bottomAnchor)
        ])

        context.coordinator.hostingController = hostingController
        context.coordinator.contentBuilder = { [content] in AnyView(content()) }
        context.coordinator.lastScrollToTopTrigger = scrollToTopTrigger
        context.coordinator.lastPullDownOffset = pullDownOffset
        return scrollView
    }

    func updateUIView(_ scrollView: UIScrollView, context: Context) {
        if let contentBuilder = context.coordinator.contentBuilder {
            context.coordinator.hostingController?.rootView = AnyView(contentBuilder())
        }

        let totalInset = contentInset

        // Handle scroll to top trigger
        if scrollToTopTrigger != context.coordinator.lastScrollToTopTrigger {
            context.coordinator.lastScrollToTopTrigger = scrollToTopTrigger
            let topOffset = CGPoint(x: 0, y: -totalInset)

            // Animate scroll with display link for smooth updates
            context.coordinator.animateScrollToTop(scrollView: scrollView, targetOffset: topOffset)
        }

        // Handle programmatic pull-down offset (for refresh animation)
        if pullDownOffset != context.coordinator.lastPullDownOffset {
            let oldOffset = context.coordinator.lastPullDownOffset
            context.coordinator.lastPullDownOffset = pullDownOffset

            // Only animate if this is a programmatic change (not from user scroll)
            if !context.coordinator.isUserScrolling {
                let targetY = -totalInset - pullDownOffset
                UIView.animate(withDuration: 0.3, delay: 0, options: [.curveEaseOut]) {
                    scrollView.contentOffset = CGPoint(x: 0, y: targetY)
                }
            }
        }
    }

    class Coordinator: NSObject, UIScrollViewDelegate {
        let onScroll: (CGFloat) -> Void
        let contentInset: CGFloat
        var hostingController: UIHostingController<AnyView>?
        var contentBuilder: (() -> AnyView)?
        var lastScrollToTopTrigger: Int = 0
        var lastPullDownOffset: CGFloat = 0
        var isUserScrolling: Bool = false
        private var displayLink: CADisplayLink?
        private var animationStartTime: CFTimeInterval = 0
        private var animationStartOffset: CGPoint = .zero
        private var animationTargetOffset: CGPoint = .zero
        private weak var animatingScrollView: UIScrollView?
        private let animationDuration: CFTimeInterval = 0.4

        init(onScroll: @escaping (CGFloat) -> Void, contentInset: CGFloat) {
            self.onScroll = onScroll
            self.contentInset = contentInset
        }

        func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
            isUserScrolling = true
        }

        func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
            if !decelerate {
                isUserScrolling = false
            }
        }

        func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
            isUserScrolling = false
        }

        func scrollViewDidScroll(_ scrollView: UIScrollView) {
            // At rest: contentOffset.y = -contentInset.top, offset = 0
            // Scrolled up: contentOffset.y increases, offset decreases (negative)
            // Pulled down: contentOffset.y decreases further, offset increases (positive)
            let restPosition = -scrollView.contentInset.top
            let offset = restPosition - scrollView.contentOffset.y
            onScroll(offset)
        }

        func animateScrollToTop(scrollView: UIScrollView, targetOffset: CGPoint) {
            // Stop any existing animation
            displayLink?.invalidate()

            animatingScrollView = scrollView
            animationStartOffset = scrollView.contentOffset
            animationTargetOffset = targetOffset
            animationStartTime = CACurrentMediaTime()

            displayLink = CADisplayLink(target: self, selector: #selector(updateScrollAnimation))
            displayLink?.add(to: .main, forMode: .common)
        }

        @objc private func updateScrollAnimation() {
            guard let scrollView = animatingScrollView else {
                displayLink?.invalidate()
                return
            }

            let elapsed = CACurrentMediaTime() - animationStartTime
            let progress = min(elapsed / animationDuration, 1.0)

            // Ease out curve
            let easedProgress = 1 - pow(1 - progress, 3)

            let newY = animationStartOffset.y + (animationTargetOffset.y - animationStartOffset.y) * easedProgress
            scrollView.contentOffset = CGPoint(x: 0, y: newY)

            // Report offset change
            let restPosition = -scrollView.contentInset.top
            let offset = restPosition - newY
            onScroll(offset)

            if progress >= 1.0 {
                displayLink?.invalidate()
                displayLink = nil
            }
        }
    }
}

// MARK: - Recipe Grid Card
/// Compact card for displaying recipes in a 2-column grid
struct RecipeGridCard: View {
    let recipe: RecipeSummary
    var showSavedBadge: Bool = false

    var body: some View {
        #if DEBUG
        let _ = print("[RecipeGridCard] Rendering: id=\(recipe.id), showSavedBadge=\(showSavedBadge), coverImageUrl=\(recipe.coverImageUrl ?? "NIL")")
        #endif
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.xs) {
            // Thumbnail with optional saved badge
            ZStack(alignment: .topTrailing) {
                AsyncImage(url: URL(string: recipe.coverImageUrl ?? "")) { phase in
                    #if DEBUG
                    let _ = print("[RecipeGridCard] AsyncImage phase: \(String(describing: phase))")
                    #endif
                    switch phase {
                    case .empty:
                        ProgressView()
                    case .success(let img):
                        img
                            .resizable()
                            .scaledToFill()
                    case .failure(let error):
                        #if DEBUG
                        let _ = print("[RecipeGridCard] Image load FAILED: \(error)")
                        #endif
                        Image(systemName: AppIcon.recipe)
                            .font(.system(size: 24))
                            .foregroundColor(DesignSystem.Colors.secondaryText.opacity(0.5))
                    @unknown default:
                        EmptyView()
                    }
                }
                .frame(minWidth: 0, maxWidth: .infinity)
                .aspectRatio(1, contentMode: .fit)
                .background(DesignSystem.Colors.tertiaryBackground)
                .clipped()
                .clipShape(RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.sm))

                // Saved indicator
                if showSavedBadge {
                    Image(systemName: AppIcon.save)
                        .font(.system(size: 12))
                        .foregroundColor(.white)
                        .padding(6)
                        .background(Color.black.opacity(0.5))
                        .clipShape(Circle())
                        .padding(8)
                }
            }

            // Title
            Text(recipe.title)
                .font(DesignSystem.Typography.subheadline)
                .fontWeight(.medium)
                .lineLimit(1)
                .foregroundColor(DesignSystem.Colors.text)

            // Subtitle (food name + cooking time)
            HStack(spacing: 4) {
                Text(recipe.foodName)
                    .lineLimit(1)

                if let time = recipe.cookingTimeRange {
                    Text("·")
                    Image(systemName: AppIcon.timer)
                        .font(.system(size: 10))
                    Text(time.cookingTimeDisplayText)
                }
            }
            .font(DesignSystem.Typography.caption)
            .foregroundColor(DesignSystem.Colors.secondaryText)
            .lineLimit(1)
        }
    }
}

// MARK: - Log Grid Card
/// Compact card for displaying cooking logs in a 2-column grid
struct LogGridCard: View {
    let log: FeedLogItem
    var showSavedBadge: Bool = false
    var onUsernameTap: (() -> Void)?

    var body: some View {
        #if DEBUG
        let _ = print("[LogGridCard] Rendering: id=\(log.id), showSavedBadge=\(showSavedBadge), thumbnailUrl=\(log.thumbnailUrl ?? "NIL")")
        #endif
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.xs) {
            // Thumbnail with rating overlay and saved badge
            ZStack(alignment: .topTrailing) {
                AsyncImage(url: URL(string: log.thumbnailUrl ?? "")) { phase in
                    #if DEBUG
                    let _ = print("[LogGridCard] AsyncImage phase: \(String(describing: phase))")
                    #endif
                    switch phase {
                    case .empty:
                        ProgressView()
                    case .success(let img):
                        img
                            .resizable()
                            .scaledToFill()
                    case .failure(let error):
                        #if DEBUG
                        let _ = print("[LogGridCard] Image load FAILED: \(error)")
                        #endif
                        LogoIconView(
                            size: 24,
                            color: DesignSystem.Colors.secondaryText.opacity(0.5),
                            useOriginalColors: false
                        )
                    @unknown default:
                        EmptyView()
                    }
                }
                .frame(minWidth: 0, maxWidth: .infinity)
                .aspectRatio(1, contentMode: .fit)
                .background(DesignSystem.Colors.tertiaryBackground)
                .clipped()
                .clipShape(RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.sm))

                // Saved indicator (top right)
                if showSavedBadge {
                    Image(systemName: AppIcon.save)
                        .font(.system(size: 12))
                        .foregroundColor(.white)
                        .padding(6)
                        .background(Color.black.opacity(0.5))
                        .clipShape(Circle())
                        .padding(8)
                }

                // Rating stars (bottom left)
                if let rating = log.rating, rating > 0 {
                    VStack {
                        Spacer()
                        HStack {
                            HStack(spacing: 2) {
                                ForEach(0..<rating, id: \.self) { _ in
                                    Image(systemName: AppIcon.star)
                                        .font(.system(size: 10))
                                }
                            }
                            .foregroundColor(DesignSystem.Colors.rating)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 4)
                            .background(Color.black.opacity(0.6))
                            .cornerRadius(4)
                            Spacer()
                        }
                        .padding(8)
                    }
                }
            }

            // Food name
            if let foodName = log.foodName {
                Text(foodName)
                    .font(DesignSystem.Typography.subheadline)
                    .fontWeight(.medium)
                    .lineLimit(1)
                    .foregroundColor(DesignSystem.Colors.text)
            } else if let recipeTitle = log.recipeTitle {
                Text(recipeTitle)
                    .font(DesignSystem.Typography.subheadline)
                    .fontWeight(.medium)
                    .lineLimit(1)
                    .foregroundColor(DesignSystem.Colors.text)
            }

            // Username
            if let onTap = onUsernameTap {
                Button {
                    onTap()
                } label: {
                    Text("@\(log.userName)")
                        .font(DesignSystem.Typography.caption)
                        .foregroundColor(DesignSystem.Colors.secondaryText)
                        .lineLimit(1)
                }
                .buttonStyle(.plain)
            } else {
                Text("@\(log.userName)")
                    .font(DesignSystem.Typography.caption)
                    .foregroundColor(DesignSystem.Colors.secondaryText)
                    .lineLimit(1)
            }
        }
    }
}

// MARK: - Log Grid Card (CookingLogSummary variant)
struct LogGridCardFromSummary: View {
    let log: CookingLogSummary
    var showSavedBadge: Bool = false
    var onUsernameTap: (() -> Void)?

    var body: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.xs) {
            // Thumbnail with rating overlay and saved badge
            ZStack(alignment: .topTrailing) {
                AsyncImage(url: URL(string: log.images.first?.thumbnailUrl ?? "")) { phase in
                    switch phase {
                    case .empty:
                        ProgressView()
                    case .success(let img):
                        img
                            .resizable()
                            .scaledToFill()
                    case .failure:
                        LogoIconView(
                            size: 24,
                            color: DesignSystem.Colors.secondaryText.opacity(0.5),
                            useOriginalColors: false
                        )
                    @unknown default:
                        EmptyView()
                    }
                }
                .frame(minWidth: 0, maxWidth: .infinity)
                .aspectRatio(1, contentMode: .fit)
                .background(DesignSystem.Colors.tertiaryBackground)
                .clipped()
                .clipShape(RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.sm))

                // Saved indicator (top right)
                if showSavedBadge {
                    Image(systemName: AppIcon.save)
                        .font(.system(size: 12))
                        .foregroundColor(.white)
                        .padding(6)
                        .background(Color.black.opacity(0.5))
                        .clipShape(Circle())
                        .padding(8)
                }

                // Rating stars (bottom left)
                if log.rating > 0 {
                    VStack {
                        Spacer()
                        HStack {
                            HStack(spacing: 2) {
                                ForEach(0..<log.rating, id: \.self) { _ in
                                    Image(systemName: AppIcon.star)
                                        .font(.system(size: 10))
                                }
                            }
                            .foregroundColor(DesignSystem.Colors.rating)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 4)
                            .background(Color.black.opacity(0.6))
                            .cornerRadius(4)
                            Spacer()
                        }
                        .padding(8)
                    }
                }
            }

            // Recipe title
            if let recipeTitle = log.recipe?.title {
                Text(recipeTitle)
                    .font(DesignSystem.Typography.subheadline)
                    .fontWeight(.medium)
                    .lineLimit(1)
                    .foregroundColor(DesignSystem.Colors.text)
            }

            // Username
            if let onTap = onUsernameTap {
                Button {
                    onTap()
                } label: {
                    Text("@\(log.author.username)")
                        .font(DesignSystem.Typography.caption)
                        .foregroundColor(DesignSystem.Colors.secondaryText)
                        .lineLimit(1)
                }
                .buttonStyle(.plain)
            } else {
                Text("@\(log.author.username)")
                    .font(DesignSystem.Typography.caption)
                    .foregroundColor(DesignSystem.Colors.secondaryText)
                    .lineLimit(1)
            }
        }
    }
}

// MARK: - Hashtag Content Grid Card
struct HashtagContentGridCard: View {
    let item: HashtagContentItem

    var body: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.xs) {
            // Thumbnail with optional rating overlay (for logs)
            ZStack(alignment: .bottomLeading) {
                AsyncImage(url: URL(string: item.thumbnailUrl ?? "")) { phase in
                    switch phase {
                    case .empty:
                        ProgressView()
                    case .success(let img):
                        img
                            .resizable()
                            .scaledToFill()
                    case .failure:
                        Group {
                            if item.isRecipe {
                                Image(systemName: AppIcon.recipe)
                                    .font(.system(size: 24))
                                    .foregroundColor(DesignSystem.Colors.secondaryText.opacity(0.5))
                            } else {
                                LogoIconView(
                                    size: 24,
                                    color: DesignSystem.Colors.secondaryText.opacity(0.5),
                                    useOriginalColors: false
                                )
                            }
                        }
                    @unknown default:
                        EmptyView()
                    }
                }
                .frame(minWidth: 0, maxWidth: .infinity)
                .aspectRatio(1, contentMode: .fit)
                .background(DesignSystem.Colors.tertiaryBackground)
                .clipped()
                .clipShape(RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.sm))

                // Rating overlay for logs
                if item.isLog, let rating = item.rating, rating > 0 {
                    HStack(spacing: 2) {
                        ForEach(0..<rating, id: \.self) { _ in
                            Image(systemName: AppIcon.star)
                                .font(.system(size: 10))
                        }
                    }
                    .foregroundColor(DesignSystem.Colors.rating)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 4)
                    .background(Color.black.opacity(0.6))
                    .cornerRadius(4)
                    .padding(8)
                }
            }

            // Title (recipe title or food name for recipes, recipe title for logs)
            if item.isRecipe {
                Text(item.title ?? item.foodName ?? "")
                    .font(DesignSystem.Typography.subheadline)
                    .fontWeight(.medium)
                    .lineLimit(1)
                    .foregroundColor(DesignSystem.Colors.text)
            } else if let recipeTitle = item.recipeTitle {
                Text(recipeTitle)
                    .font(DesignSystem.Typography.subheadline)
                    .fontWeight(.medium)
                    .lineLimit(1)
                    .foregroundColor(DesignSystem.Colors.text)
            }

            // Username
            Text("@\(item.userName)")
                .font(DesignSystem.Typography.caption)
                .foregroundColor(DesignSystem.Colors.secondaryText)
                .lineLimit(1)
        }
    }
}

// MARK: - Content Grid
/// Reusable 2-column grid layout for content cards
struct ContentGrid<Content: View>: View {
    let content: () -> Content

    init(@ViewBuilder content: @escaping () -> Content) {
        self.content = content
    }

    private let columns = [
        GridItem(.flexible(), spacing: DesignSystem.Spacing.sm),
        GridItem(.flexible(), spacing: DesignSystem.Spacing.sm)
    ]

    var body: some View {
        LazyVGrid(columns: columns, spacing: DesignSystem.Spacing.md) {
            content()
        }
        .padding(.horizontal, DesignSystem.Spacing.md)
    }
}

// MARK: - Flow Layout
/// A layout that arranges views in a flowing, wrapping manner
struct FlowLayout: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let result = calculateLayout(proposal: proposal, subviews: subviews)
        return result.size
    }

    func placeSubviews(
        in bounds: CGRect,
        proposal: ProposedViewSize,
        subviews: Subviews,
        cache: inout ()
    ) {
        let result = calculateLayout(proposal: proposal, subviews: subviews)
        for (index, position) in result.positions.enumerated() {
            subviews[index].place(
                at: CGPoint(x: bounds.minX + position.x, y: bounds.minY + position.y),
                proposal: .unspecified
            )
        }
    }

    private func calculateLayout(
        proposal: ProposedViewSize,
        subviews: Subviews
    ) -> (size: CGSize, positions: [CGPoint]) {
        var positions: [CGPoint] = []
        var currentX: CGFloat = 0
        var currentY: CGFloat = 0
        var lineHeight: CGFloat = 0
        let maxWidth = proposal.width ?? .infinity

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if currentX + size.width > maxWidth && currentX > 0 {
                currentX = 0
                currentY += lineHeight + spacing
                lineHeight = 0
            }
            positions.append(CGPoint(x: currentX, y: currentY))
            lineHeight = max(lineHeight, size.height)
            currentX += size.width + spacing
        }

        return (CGSize(width: maxWidth, height: currentY + lineHeight), positions)
    }
}

// MARK: - Swipe Back Gesture Enabler
/// Enables the interactive pop gesture (swipe from left edge to go back) when navigation bar is hidden
struct SwipeBackGestureEnabler: UIViewControllerRepresentable {
    func makeUIViewController(context: Context) -> UIViewController {
        SwipeBackGestureViewController()
    }

    func updateUIViewController(_ uiViewController: UIViewController, context: Context) {}
}

private class SwipeBackGestureViewController: UIViewController {
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        navigationController?.interactivePopGestureRecognizer?.isEnabled = true
        navigationController?.interactivePopGestureRecognizer?.delegate = nil
    }
}

extension View {
    /// Enables swipe back gesture when navigation bar is hidden
    func enableSwipeBack() -> some View {
        background(SwipeBackGestureEnabler())
    }
}
