import Foundation
import Combine

@MainActor
final class EditProfileViewModel: ObservableObject {
    // MARK: - Published State

    @Published var username = ""
    @Published var bio = ""
    @Published var youtubeUrl = ""
    @Published var instagramHandle = ""

    @Published var isCheckingUsername = false
    @Published var usernameAvailable: Bool?
    @Published var usernameFormatError: String?

    @Published var isSubmitting = false
    @Published var error: String?
    @Published var saveSuccess = false

    // MARK: - Constants

    static let minUsernameLength = 5
    static let maxUsernameLength = 30
    static let usernamePattern = "^[a-zA-Z][a-zA-Z0-9._-]{4,29}$"

    // MARK: - Private

    private let userRepository: UserRepositoryProtocol
    private var initialUsername = ""
    private var cancellables = Set<AnyCancellable>()
    private var checkUsernameTask: Task<Void, Never>?

    // MARK: - Init

    init(userRepository: UserRepositoryProtocol = UserRepository()) {
        self.userRepository = userRepository
        setupUsernameValidation()
    }

    // MARK: - Setup

    private func setupUsernameValidation() {
        $username
            .debounce(for: .milliseconds(300), scheduler: RunLoop.main)
            .removeDuplicates()
            .sink { [weak self] newUsername in
                self?.validateUsernameOnChange(newUsername)
            }
            .store(in: &cancellables)
    }

    private func validateUsernameOnChange(_ newUsername: String) {
        usernameAvailable = nil

        if newUsername.isEmpty {
            usernameFormatError = nil
            return
        }

        if !validateUsernameFormat(newUsername) {
            return
        }

        if newUsername == initialUsername {
            usernameAvailable = true
            return
        }
    }

    // MARK: - Load Profile

    func loadProfile() async {
        let result = await userRepository.getMyProfile()
        switch result {
        case .success(let profile):
            username = profile.username
            initialUsername = profile.username
            bio = profile.bio ?? ""
            youtubeUrl = profile.user.youtubeUrl ?? ""
            instagramHandle = profile.user.instagramHandle ?? ""
            usernameFormatError = nil
            usernameAvailable = nil
        case .failure(let error):
            self.error = error.localizedDescription
        }
    }

    // MARK: - Username Validation

    func validateUsernameFormat(_ username: String) -> Bool {
        usernameFormatError = nil

        if username.count < Self.minUsernameLength {
            usernameFormatError = "Username must be at least \(Self.minUsernameLength) characters"
            return false
        }

        if username.count > Self.maxUsernameLength {
            usernameFormatError = "Username must be at most \(Self.maxUsernameLength) characters"
            return false
        }

        guard let firstChar = username.first, firstChar.isLetter else {
            usernameFormatError = "Username must start with a letter"
            return false
        }

        let regex = try? NSRegularExpression(pattern: Self.usernamePattern)
        let range = NSRange(username.startIndex..., in: username)
        if regex?.firstMatch(in: username, range: range) == nil {
            usernameFormatError = "Only letters, numbers, and . _ - allowed"
            return false
        }

        return true
    }

    var usernameCharacterCount: String {
        "\(username.count)/\(Self.maxUsernameLength)"
    }

    var hasUsernameChanged: Bool {
        username != initialUsername
    }

    var canCheckUsername: Bool {
        !username.isEmpty &&
        usernameFormatError == nil &&
        hasUsernameChanged &&
        !isCheckingUsername
    }

    var canSave: Bool {
        !isSubmitting &&
        (usernameFormatError == nil) &&
        (!hasUsernameChanged || usernameAvailable == true)
    }

    // MARK: - Check Username Availability

    func checkUsernameAvailability() async {
        guard canCheckUsername else { return }

        checkUsernameTask?.cancel()

        isCheckingUsername = true
        usernameAvailable = nil

        let usernameToCheck = username
        let result = await userRepository.checkUsernameAvailability(usernameToCheck)

        guard username == usernameToCheck else {
            isCheckingUsername = false
            return
        }

        isCheckingUsername = false

        switch result {
        case .success(let available):
            usernameAvailable = available
        case .failure(let error):
            self.error = error.localizedDescription
            usernameAvailable = nil
        }
    }

    // MARK: - Save Profile

    func saveProfile() async {
        guard canSave else { return }

        isSubmitting = true
        error = nil

        let socialLinks = SocialLinks(
            youtube: youtubeUrl.isEmpty ? nil : youtubeUrl,
            instagram: instagramHandle.isEmpty ? nil : instagramHandle,
            twitter: nil,
            website: nil
        )

        let request = UpdateProfileRequest(
            username: hasUsernameChanged ? username : nil,
            bio: bio.isEmpty ? nil : bio,
            avatarImageId: nil,
            socialLinks: socialLinks,
            measurementPreference: nil
        )

        let result = await userRepository.updateProfile(request)

        isSubmitting = false

        switch result {
        case .success(let profile):
            initialUsername = profile.username
            usernameAvailable = nil
            saveSuccess = true
        case .failure(let error):
            self.error = error.localizedDescription
        }
    }

    // MARK: - Reset

    func resetError() {
        error = nil
    }
}
