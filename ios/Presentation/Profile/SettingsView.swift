import SwiftUI

struct SettingsView: View {
    @EnvironmentObject private var authManager: AuthManager
    @State private var showLogoutConfirmation = false
    @State private var showDeleteAccountConfirmation = false

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
                        Text("Metric").foregroundColor(DesignSystem.Colors.secondaryText)
                    }
                }
            }

            // Support section
            Section("Support") {
                Link(destination: URL(string: "https://cookstemma.com/help")!) {
                    Label("Help Center", systemImage: "questionmark.circle")
                }
                Link(destination: URL(string: "https://cookstemma.com/feedback")!) {
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
        }
        .navigationTitle("Settings")
        .confirmationDialog("Log Out", isPresented: $showLogoutConfirmation) {
            Button("Log Out", role: .destructive) {
                Task { await authManager.logout() }
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("Are you sure you want to log out?")
        }
        .confirmationDialog("Delete Account", isPresented: $showDeleteAccountConfirmation) {
            Button("Delete Account", role: .destructive) {
                // Delete account flow
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("This action cannot be undone. All your data will be permanently deleted.")
        }
    }
}

// MARK: - Settings Subviews
struct EditProfileView: View {
    @State private var displayName = ""
    @State private var username = ""
    @State private var bio = ""

    var body: some View {
        Form {
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

            Section("Information") {
                TextField("Display Name", text: $displayName)
                TextField("Username", text: $username)
                TextField("Bio", text: $bio, axis: .vertical)
                    .lineLimit(3...6)
            }

            Section("Social Links") {
                TextField("YouTube URL", text: .constant(""))
                TextField("Instagram Handle", text: .constant(""))
            }
        }
        .navigationTitle("Edit Profile")
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("Save") { }
            }
        }
    }
}

struct NotificationSettingsView: View {
    @State private var commentsEnabled = true
    @State private var followersEnabled = true
    @State private var recipeActivityEnabled = true
    @State private var likesEnabled = false
    @State private var weeklyDigestEnabled = true
    @State private var quietHoursEnabled = false

    var body: some View {
        Form {
            Section("Push Notifications") {
                Toggle("Comments & Replies", isOn: $commentsEnabled)
                Toggle("New Followers", isOn: $followersEnabled)
                Toggle("Recipe Activity", isOn: $recipeActivityEnabled)
                Toggle("Likes", isOn: $likesEnabled)
                Toggle("Weekly Digest", isOn: $weeklyDigestEnabled)
            }

            Section("Quiet Hours") {
                Toggle("Enable Quiet Hours", isOn: $quietHoursEnabled)
                if quietHoursEnabled {
                    DatePicker("Start", selection: .constant(Date()), displayedComponents: .hourAndMinute)
                    DatePicker("End", selection: .constant(Date()), displayedComponents: .hourAndMinute)
                }
            }
        }
        .navigationTitle("Notifications")
    }
}

struct PrivacySettingsView: View {
    @State private var privateAccount = false
    @State private var showActivityStatus = true

    var body: some View {
        Form {
            Section {
                Toggle("Private Account", isOn: $privateAccount)
            } footer: {
                Text("When enabled, only approved followers can see your content.")
            }

            Section {
                Toggle("Show Activity Status", isOn: $showActivityStatus)
            } footer: {
                Text("Let others see when you were last active.")
            }

            Section("Blocked Users") {
                NavigationLink("Manage Blocked Users") {
                    BlockedUsersView()
                }
            }
        }
        .navigationTitle("Privacy")
    }
}

struct BlockedUsersView: View {
    @State private var blockedUsers: [UserSummary] = []

    var body: some View {
        Group {
            if blockedUsers.isEmpty {
                EmptyStateView(icon: "hand.raised", title: "No blocked users", message: "Users you block will appear here")
            } else {
                List(blockedUsers) { user in
                    HStack {
                        AvatarView(url: user.avatarUrl, size: DesignSystem.AvatarSize.sm)
                        Text("@\(user.username)")
                        Spacer()
                        Button("Unblock") { }
                            .foregroundColor(DesignSystem.Colors.primary)
                    }
                }
            }
        }
        .navigationTitle("Blocked Users")
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
        .navigationTitle("Language")
    }
}

struct UnitsSettingsView: View {
    @State private var useMetric = true

    var body: some View {
        List {
            Button {
                useMetric = true
            } label: {
                HStack {
                    VStack(alignment: .leading) {
                        Text("Metric")
                        Text("grams, milliliters, celsius").font(DesignSystem.Typography.caption).foregroundColor(DesignSystem.Colors.secondaryText)
                    }
                    Spacer()
                    if useMetric { Image(systemName: "checkmark").foregroundColor(DesignSystem.Colors.primary) }
                }
            }
            .foregroundColor(DesignSystem.Colors.primaryText)

            Button {
                useMetric = false
            } label: {
                HStack {
                    VStack(alignment: .leading) {
                        Text("Imperial")
                        Text("ounces, cups, fahrenheit").font(DesignSystem.Typography.caption).foregroundColor(DesignSystem.Colors.secondaryText)
                    }
                    Spacer()
                    if !useMetric { Image(systemName: "checkmark").foregroundColor(DesignSystem.Colors.primary) }
                }
            }
            .foregroundColor(DesignSystem.Colors.primaryText)
        }
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
                Link(destination: URL(string: "https://twitter.com/cookstemma")!) {
                    Label("Twitter", systemImage: "at")
                }
                Link(destination: URL(string: "https://instagram.com/cookstemma")!) {
                    Label("Instagram", systemImage: "camera")
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
        .navigationTitle("About")
    }
}

#Preview { NavigationStack { SettingsView().environmentObject(AuthManager.shared) } }
