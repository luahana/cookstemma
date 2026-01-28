import SwiftUI

struct SettingsView: View {
    @EnvironmentObject private var authManager: AuthManager
    @AppStorage("appTheme") private var appTheme: AppTheme = .system
    @AppStorage("userMeasurement") private var measurementPreference: MeasurementPreference = .original
    @State private var showLogoutConfirmation = false
    @State private var showDeleteAccountConfirmation = false
    @State private var showEmailCopiedAlert = false

    var body: some View {
        List {
            // Account section
            Section("Account") {
                NavigationLink(destination: EditProfileView()) {
                    Label("Edit Profile", systemImage: "person.circle")
                }
                NavigationLink(destination: NotificationSettingsView()) {
                    Label("Notifications", systemImage: "bell")
                }
                NavigationLink(destination: PrivacySettingsView()) {
                    Label("Privacy", systemImage: "lock")
                }
            }

            // Preferences section
            Section("Preferences") {
                NavigationLink(destination: ThemeSettingsView()) {
                    HStack {
                        Label("Theme", systemImage: "circle.lefthalf.filled")
                        Spacer()
                        Text(appTheme.displayName).foregroundColor(DesignSystem.Colors.secondaryText)
                    }
                }
                NavigationLink(destination: LanguageSettingsView()) {
                    HStack {
                        Label("Language", systemImage: "globe")
                        Spacer()
                        Text("English").foregroundColor(DesignSystem.Colors.secondaryText)
                    }
                }
                NavigationLink(destination: UnitsSettingsView()) {
                    HStack {
                        Label("Units", systemImage: "ruler")
                        Spacer()
                        Text(measurementPreference.displayName).foregroundColor(DesignSystem.Colors.secondaryText)
                    }
                }
            }

            // Support section
            Section("Support") {
                Button {
                    sendFeedbackEmail()
                } label: {
                    Label("Send Feedback", systemImage: "envelope")
                }
                NavigationLink(destination: AboutView()) {
                    Label("About", systemImage: "info.circle")
                }
            }

            // Legal section
            Section("Legal") {
                Link(destination: URL(string: "https://cookstemma.com/terms")!) {
                    Label("Terms of Service", systemImage: "doc.text")
                }
                Link(destination: URL(string: "https://cookstemma.com/privacy")!) {
                    Label("Privacy Policy", systemImage: "hand.raised")
                }
            }

            // Account actions
            Section {
                Button(role: .destructive) {
                    showLogoutConfirmation = true
                } label: {
                    Label("Log Out", systemImage: "rectangle.portrait.and.arrow.right")
                }

                Button(role: .destructive) {
                    showDeleteAccountConfirmation = true
                } label: {
                    Label("Delete Account", systemImage: "trash")
                }
            }

            // Version info
            Section {
                HStack {
                    Text("Version")
                    Spacer()
                    Text(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0.0")
                        .foregroundColor(DesignSystem.Colors.secondaryText)
                }
            }
            .listRowBackground(Color.clear)
            .listSectionSpacing(.compact)
        }
        .listStyle(.insetGrouped)
        .contentMargins(.bottom, 80, for: .scrollContent)
        .navigationTitle("Settings")
        .alert("Log Out", isPresented: $showLogoutConfirmation) {
            Button("Cancel", role: .cancel) { }
            Button("Log Out", role: .destructive) {
                Task { await authManager.logout() }
            }
        } message: {
            Text("Are you sure you want to log out?")
        }
        .alert("Delete Account", isPresented: $showDeleteAccountConfirmation) {
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive) {
                // Delete account flow
            }
        } message: {
            Text("This action cannot be undone. All your data will be permanently deleted.")
        }
        .alert("Email Copied", isPresented: $showEmailCopiedAlert) {
            Button("OK", role: .cancel) { }
        } message: {
            Text("contact@cookstemma.com has been copied to your clipboard.")
        }
    }

    private func sendFeedbackEmail() {
        let email = "contact@cookstemma.com"
        let subject = "Cookstemma Feedback"
        let encodedSubject = subject.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? subject
        if let url = URL(string: "mailto:\(email)?subject=\(encodedSubject)"),
           UIApplication.shared.canOpenURL(url) {
            UIApplication.shared.open(url)
        } else {
            UIPasteboard.general.string = email
            showEmailCopiedAlert = true
        }
    }
}

// MARK: - App Theme
enum AppTheme: String, CaseIterable {
    case system
    case light
    case dark

    var displayName: String {
        switch self {
        case .system: return "System"
        case .light: return "Light"
        case .dark: return "Dark"
        }
    }

    var colorScheme: ColorScheme? {
        switch self {
        case .system: return nil
        case .light: return .light
        case .dark: return .dark
        }
    }
}

struct ThemeSettingsView: View {
    @AppStorage("appTheme") private var appTheme: AppTheme = .system

    var body: some View {
        List {
            ForEach(AppTheme.allCases, id: \.self) { theme in
                Button {
                    appTheme = theme
                } label: {
                    HStack {
                        Label {
                            Text(theme.displayName)
                        } icon: {
                            Image(systemName: iconName(for: theme))
                        }
                        Spacer()
                        if appTheme == theme {
                            Image(systemName: "checkmark")
                                .foregroundColor(DesignSystem.Colors.primary)
                        }
                    }
                }
                .foregroundColor(DesignSystem.Colors.primaryText)
            }
        }
        .contentMargins(.bottom, 80, for: .scrollContent)
        .navigationTitle("Theme")
    }

    private func iconName(for theme: AppTheme) -> String {
        switch theme {
        case .system: return "circle.lefthalf.filled"
        case .light: return "sun.max"
        case .dark: return "moon"
        }
    }
}

// MARK: - Settings Subviews
struct EditProfileView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel = EditProfileViewModel()

    var body: some View {
        Form {
            profilePhotoSection
            informationSection
            socialLinksSection
        }
        .contentMargins(.bottom, 80, for: .scrollContent)
        .navigationTitle("Edit Profile")
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                saveButton
            }
        }
        .task {
            await viewModel.loadProfile()
        }
        .alert("Error", isPresented: .constant(viewModel.error != nil)) {
            Button("OK") { viewModel.resetError() }
        } message: {
            Text(viewModel.error ?? "")
        }
        .onChange(of: viewModel.saveSuccess) { _, success in
            if success { dismiss() }
        }
    }

    // MARK: - Profile Photo Section

    private var profilePhotoSection: some View {
        Section("Profile Photo") {
            HStack {
                Spacer()
                VStack {
                    Circle()
                        .fill(DesignSystem.Colors.secondaryBackground)
                        .frame(width: 100, height: 100)
                        .overlay(Image(systemName: "camera").font(.title))
                    Button("Change Photo") { }
                }
                Spacer()
            }
        }
    }

    // MARK: - Information Section

    private var informationSection: some View {
        Section {
            VStack(alignment: .leading, spacing: DesignSystem.Spacing.xs) {
                Text("Username")
                    .font(DesignSystem.Typography.caption)
                    .foregroundColor(DesignSystem.Colors.secondaryText)

                HStack(spacing: DesignSystem.Spacing.sm) {
                    HStack {
                        Text("@")
                            .foregroundColor(DesignSystem.Colors.secondaryText)
                        TextField("username", text: $viewModel.username)
                            .textInputAutocapitalization(.never)
                            .autocorrectionDisabled()
                    }
                    .padding(.horizontal, DesignSystem.Spacing.sm)
                    .padding(.vertical, DesignSystem.Spacing.xs)
                    .background(DesignSystem.Colors.secondaryBackground)
                    .cornerRadius(DesignSystem.CornerRadius.sm)

                    Button {
                        Task { await viewModel.checkUsernameAvailability() }
                    } label: {
                        if viewModel.isCheckingUsername {
                            ProgressView()
                                .frame(width: 60)
                        } else {
                            Text("Check")
                                .frame(width: 60)
                        }
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(!viewModel.canCheckUsername)
                }

                usernameValidationMessage

                HStack {
                    Spacer()
                    Text(viewModel.usernameCharacterCount)
                        .font(DesignSystem.Typography.caption)
                        .foregroundColor(DesignSystem.Colors.secondaryText)
                }
            }

            VStack(alignment: .leading, spacing: DesignSystem.Spacing.xs) {
                Text("Bio")
                    .font(DesignSystem.Typography.caption)
                    .foregroundColor(DesignSystem.Colors.secondaryText)

                TextField("Tell us about yourself", text: $viewModel.bio, axis: .vertical)
                    .lineLimit(3...6)
                    .onChange(of: viewModel.bio) { _, newValue in
                        // Limit bio to max length
                        if newValue.count > EditProfileViewModel.maxBioLength {
                            viewModel.bio = String(newValue.prefix(EditProfileViewModel.maxBioLength))
                        }
                    }

                HStack {
                    Spacer()
                    Text(viewModel.bioCharacterCount)
                        .font(DesignSystem.Typography.caption)
                        .foregroundColor(
                            viewModel.isBioOverLimit
                                ? .red
                                : DesignSystem.Colors.secondaryText
                        )
                }
            }
        } header: {
            Text("Information")
        } footer: {
            Text("Username: 5-30 characters, starts with letter. Allowed: a-z, 0-9, . _ -")
                .font(DesignSystem.Typography.caption)
        }
    }

    // MARK: - Username Validation Message

    @ViewBuilder
    private var usernameValidationMessage: some View {
        if let formatError = viewModel.usernameFormatError {
            Label(formatError, systemImage: "exclamationmark.triangle.fill")
                .font(DesignSystem.Typography.caption)
                .foregroundColor(.orange)
        } else if viewModel.usernameAvailable == true {
            Label("Username available", systemImage: "checkmark.circle.fill")
                .font(DesignSystem.Typography.caption)
                .foregroundColor(.green)
        } else if viewModel.usernameAvailable == false {
            Label("Username already taken", systemImage: "xmark.circle.fill")
                .font(DesignSystem.Typography.caption)
                .foregroundColor(.red)
        }
    }

    // MARK: - Social Links Section

    private var socialLinksSection: some View {
        Section("Social Links") {
            VStack(alignment: .leading, spacing: DesignSystem.Spacing.xs) {
                Text("YouTube URL")
                    .font(DesignSystem.Typography.caption)
                    .foregroundColor(DesignSystem.Colors.secondaryText)
                TextField("https://youtube.com/@channel", text: $viewModel.youtubeUrl)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                    .keyboardType(.URL)
            }

            VStack(alignment: .leading, spacing: DesignSystem.Spacing.xs) {
                Text("Instagram Handle")
                    .font(DesignSystem.Typography.caption)
                    .foregroundColor(DesignSystem.Colors.secondaryText)
                TextField("@username", text: $viewModel.instagramHandle)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
            }
        }
    }

    // MARK: - Save Button

    private var saveButton: some View {
        Group {
            if viewModel.isSubmitting {
                ProgressView()
            } else {
                Button("Save") {
                    Task { await viewModel.saveProfile() }
                }
                .disabled(!viewModel.canSave)
            }
        }
    }
}

struct NotificationSettingsView: View {
    @State private var commentsEnabled = true
    @State private var followersEnabled = true
    @State private var newSavedEnabled = true
    @State private var newCookingLogsEnabled = true
    @State private var newVariantRecipesEnabled = true

    var body: some View {
        Form {
            Section("Push Notifications") {
                Toggle("Comments & Replies", isOn: $commentsEnabled)
                Toggle("New Followers", isOn: $followersEnabled)
                Toggle("New Saved", isOn: $newSavedEnabled)
                Toggle("New Cooking Logs", isOn: $newCookingLogsEnabled)
                Toggle("New Variant Recipes", isOn: $newVariantRecipesEnabled)
            }
        }
        .contentMargins(.bottom, 80, for: .scrollContent)
        .navigationTitle("Notifications")
    }
}

struct PrivacySettingsView: View {
    var body: some View {
        Form {
            Section("Blocked Users") {
                NavigationLink("Manage Blocked Users") {
                    BlockedUsersView()
                }
            }
        }
        .contentMargins(.bottom, 80, for: .scrollContent)
        .navigationTitle("Privacy")
    }
}

struct BlockedUsersView: View {
    @StateObject private var viewModel = BlockedUsersViewModel()

    var body: some View {
        Group {
            switch viewModel.state {
            case .idle, .loading:
                LoadingView()
            case .loaded:
                if viewModel.blockedUsers.isEmpty {
                    EmptyStateView(icon: "hand.raised", title: "No blocked users", message: "Users you block will appear here")
                } else {
                    List {
                        ForEach(viewModel.blockedUsers) { user in
                            HStack {
                                AvatarView(url: user.avatarUrl, size: DesignSystem.AvatarSize.sm)
                                Text("@\(user.username)")
                                    .font(DesignSystem.Typography.subheadline)
                                Spacer()
                                Button("Unblock") {
                                    Task { await viewModel.unblockUser(user) }
                                }
                                .font(DesignSystem.Typography.subheadline)
                                .foregroundColor(DesignSystem.Colors.primary)
                            }
                        }
                        if viewModel.hasMore && !viewModel.isLoadingMore {
                            Button("Load more") {
                                Task { await viewModel.loadMore() }
                            }
                            .frame(maxWidth: .infinity)
                        }
                        if viewModel.isLoadingMore {
                            ProgressView()
                                .frame(maxWidth: .infinity)
                        }
                    }
                }
            case .error(let message):
                ErrorStateView(message: message) {
                    Task { await viewModel.loadBlockedUsers() }
                }
            }
        }
        .navigationTitle("Blocked Users")
        .onAppear {
            if case .idle = viewModel.state {
                Task { await viewModel.loadBlockedUsers() }
            }
        }
    }
}

// MARK: - Blocked Users ViewModel
@MainActor
final class BlockedUsersViewModel: ObservableObject {
    enum State: Equatable { case idle, loading, loaded, error(String) }

    @Published private(set) var state: State = .idle
    @Published private(set) var blockedUsers: [BlockedUser] = []
    @Published private(set) var hasMore = false
    @Published private(set) var isLoadingMore = false

    private let userRepository: UserRepositoryProtocol
    private var currentPage = 0

    init(userRepository: UserRepositoryProtocol = UserRepository()) {
        self.userRepository = userRepository
    }

    func loadBlockedUsers() async {
        state = .loading
        currentPage = 0
        let result = await userRepository.getBlockedUsers(page: 0)
        switch result {
        case .success(let response):
            blockedUsers = response.content
            hasMore = response.hasMore
            currentPage = response.page
            state = .loaded
        case .failure(let error):
            state = .error(error.localizedDescription)
        }
    }

    func loadMore() async {
        guard !isLoadingMore, hasMore else { return }
        isLoadingMore = true
        defer { isLoadingMore = false }

        let nextPage = currentPage + 1
        let result = await userRepository.getBlockedUsers(page: nextPage)
        if case .success(let response) = result {
            blockedUsers.append(contentsOf: response.content)
            hasMore = response.hasMore
            currentPage = response.page
        }
    }

    func unblockUser(_ user: BlockedUser) async {
        let result = await userRepository.unblockUser(userId: user.id)
        if case .success = result {
            blockedUsers.removeAll { $0.id == user.id }
        }
    }
}

struct LanguageSettingsView: View {
    @State private var selectedLanguage = "en"

    let languages = [
        ("en", "English"),
        ("ko", "한국어"),
        ("ja", "日本語"),
        ("zh", "中文")
    ]

    var body: some View {
        List {
            ForEach(languages, id: \.0) { code, name in
                Button {
                    selectedLanguage = code
                } label: {
                    HStack {
                        Text(name)
                        Spacer()
                        if selectedLanguage == code {
                            Image(systemName: "checkmark").foregroundColor(DesignSystem.Colors.primary)
                        }
                    }
                }
                .foregroundColor(DesignSystem.Colors.primaryText)
            }
        }
        .contentMargins(.bottom, 80, for: .scrollContent)
        .navigationTitle("Language")
    }
}

struct UnitsSettingsView: View {
    @AppStorage("userMeasurement") private var measurementPreference: MeasurementPreference = .original

    var body: some View {
        List {
            ForEach(MeasurementPreference.allCases, id: \.self) { preference in
                Button {
                    measurementPreference = preference
                } label: {
                    HStack {
                        VStack(alignment: .leading) {
                            Text(preference.displayName)
                            Text(preference.description)
                                .font(DesignSystem.Typography.caption)
                                .foregroundColor(DesignSystem.Colors.secondaryText)
                        }
                        Spacer()
                        if measurementPreference == preference {
                            Image(systemName: "checkmark")
                                .foregroundColor(DesignSystem.Colors.primary)
                        }
                    }
                }
                .foregroundColor(DesignSystem.Colors.primaryText)
            }
        }
        .contentMargins(.bottom, 80, for: .scrollContent)
        .navigationTitle("Units")
    }
}

struct AboutView: View {
    var body: some View {
        List {
            Section {
                VStack(spacing: DesignSystem.Spacing.md) {
                    Image(systemName: "fork.knife.circle.fill")
                        .font(.system(size: 60))
                        .foregroundColor(DesignSystem.Colors.primary)
                    Text("Cookstemma")
                        .font(.title2)
                        .fontWeight(.bold)
                    Text("Share your cooking journey")
                        .foregroundColor(DesignSystem.Colors.secondaryText)
                }
                .frame(maxWidth: .infinity)
                .padding()
            }

            Section {
                Link(destination: URL(string: "https://cookstemma.com")!) {
                    Label("Website", systemImage: "globe")
                }
            }

            Section {
                HStack {
                    Text("Version")
                    Spacer()
                    Text(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0.0")
                        .foregroundColor(DesignSystem.Colors.secondaryText)
                }
                HStack {
                    Text("Build")
                    Spacer()
                    Text(Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1")
                        .foregroundColor(DesignSystem.Colors.secondaryText)
                }
            }
        }
        .contentMargins(.bottom, 80, for: .scrollContent)
        .navigationTitle("About")
    }
}

#Preview { NavigationStack { SettingsView().environmentObject(AuthManager.shared) } }
