import XCTest
@testable import Cookstemma

@MainActor
final class EditProfileViewModelTests: XCTestCase {

    var sut: EditProfileViewModel!
    var mockUserRepository: MockUserRepository!

    override func setUp() async throws {
        try await super.setUp()
        mockUserRepository = MockUserRepository()
        sut = EditProfileViewModel(userRepository: mockUserRepository)
    }

    override func tearDown() async throws {
        sut = nil
        mockUserRepository = nil
        try await super.tearDown()
    }

    // MARK: - Username Format Validation Tests

    func testValidateUsernameFormat_validUsername_returnsTrue() {
        // Given
        let username = "johndoe123"

        // When
        let result = sut.validateUsernameFormat(username)

        // Then
        XCTAssertTrue(result)
        XCTAssertNil(sut.usernameFormatError)
    }

    func testValidateUsernameFormat_tooShort_returnsFalse() {
        // Given
        let username = "john"

        // When
        let result = sut.validateUsernameFormat(username)

        // Then
        XCTAssertFalse(result)
        XCTAssertNotNil(sut.usernameFormatError)
        XCTAssertTrue(sut.usernameFormatError?.contains("at least") ?? false)
    }

    func testValidateUsernameFormat_tooLong_returnsFalse() {
        // Given
        let username = String(repeating: "a", count: 31)

        // When
        let result = sut.validateUsernameFormat(username)

        // Then
        XCTAssertFalse(result)
        XCTAssertNotNil(sut.usernameFormatError)
        XCTAssertTrue(sut.usernameFormatError?.contains("at most") ?? false)
    }

    func testValidateUsernameFormat_startsWithNumber_returnsFalse() {
        // Given
        let username = "1johndoe"

        // When
        let result = sut.validateUsernameFormat(username)

        // Then
        XCTAssertFalse(result)
        XCTAssertNotNil(sut.usernameFormatError)
        XCTAssertTrue(sut.usernameFormatError?.contains("start with a letter") ?? false)
    }

    func testValidateUsernameFormat_invalidChars_returnsFalse() {
        // Given
        let username = "john@doe"

        // When
        let result = sut.validateUsernameFormat(username)

        // Then
        XCTAssertFalse(result)
        XCTAssertNotNil(sut.usernameFormatError)
        XCTAssertTrue(sut.usernameFormatError?.contains("Only letters") ?? false)
    }

    func testValidateUsernameFormat_withUnderscore_returnsTrue() {
        // Given
        let username = "john_doe"

        // When
        let result = sut.validateUsernameFormat(username)

        // Then
        XCTAssertTrue(result)
        XCTAssertNil(sut.usernameFormatError)
    }

    func testValidateUsernameFormat_withPeriod_returnsTrue() {
        // Given
        let username = "john.doe"

        // When
        let result = sut.validateUsernameFormat(username)

        // Then
        XCTAssertTrue(result)
        XCTAssertNil(sut.usernameFormatError)
    }

    func testValidateUsernameFormat_withHyphen_returnsTrue() {
        // Given
        let username = "john-doe"

        // When
        let result = sut.validateUsernameFormat(username)

        // Then
        XCTAssertTrue(result)
        XCTAssertNil(sut.usernameFormatError)
    }

    func testValidateUsernameFormat_exactlyMinLength_returnsTrue() {
        // Given
        let username = "abcde"  // 5 characters

        // When
        let result = sut.validateUsernameFormat(username)

        // Then
        XCTAssertTrue(result)
        XCTAssertNil(sut.usernameFormatError)
    }

    func testValidateUsernameFormat_exactlyMaxLength_returnsTrue() {
        // Given
        let username = "a" + String(repeating: "b", count: 29)  // 30 characters

        // When
        let result = sut.validateUsernameFormat(username)

        // Then
        XCTAssertTrue(result)
        XCTAssertNil(sut.usernameFormatError)
    }

    // MARK: - Check Username Availability Tests

    func testCheckUsernameAvailability_available_setsTrue() async {
        // Given
        mockUserRepository.getMyProfileResult = .success(createMockMyProfile(username: "olduser"))
        await sut.loadProfile()
        sut.username = "newuser123"
        mockUserRepository.checkUsernameAvailabilityResult = .success(true)

        // When
        await sut.checkUsernameAvailability()

        // Then
        XCTAssertTrue(mockUserRepository.checkUsernameAvailabilityCalled)
        XCTAssertEqual(mockUserRepository.lastCheckedUsername, "newuser123")
        XCTAssertEqual(sut.usernameAvailable, true)
        XCTAssertFalse(sut.isCheckingUsername)
    }

    func testCheckUsernameAvailability_taken_setsFalse() async {
        // Given
        mockUserRepository.getMyProfileResult = .success(createMockMyProfile(username: "olduser"))
        await sut.loadProfile()
        sut.username = "takenuser"
        mockUserRepository.checkUsernameAvailabilityResult = .success(false)

        // When
        await sut.checkUsernameAvailability()

        // Then
        XCTAssertTrue(mockUserRepository.checkUsernameAvailabilityCalled)
        XCTAssertEqual(sut.usernameAvailable, false)
    }

    func testCheckUsernameAvailability_sameAsInitial_doesNotCallAPI() async {
        // Given
        mockUserRepository.getMyProfileResult = .success(createMockMyProfile(username: "testuser"))
        await sut.loadProfile()
        // Username is same as initial

        // When
        await sut.checkUsernameAvailability()

        // Then
        XCTAssertFalse(mockUserRepository.checkUsernameAvailabilityCalled)
    }

    func testCheckUsernameAvailability_invalidFormat_doesNotCallAPI() async {
        // Given
        mockUserRepository.getMyProfileResult = .success(createMockMyProfile(username: "olduser"))
        await sut.loadProfile()
        sut.username = "ab"  // Too short

        // When
        _ = sut.validateUsernameFormat(sut.username)
        await sut.checkUsernameAvailability()

        // Then
        XCTAssertFalse(mockUserRepository.checkUsernameAvailabilityCalled)
    }

    // MARK: - Save Profile Tests

    func testSaveProfile_validData_callsRepository() async {
        // Given
        let initialProfile = createMockMyProfile(username: "olduser")
        mockUserRepository.getMyProfileResult = .success(initialProfile)
        mockUserRepository.updateProfileResult = .success(createMockMyProfile(username: "newuser123"))
        await sut.loadProfile()
        sut.username = "newuser123"
        sut.bio = "New bio"
        mockUserRepository.checkUsernameAvailabilityResult = .success(true)
        await sut.checkUsernameAvailability()

        // When
        await sut.saveProfile()

        // Then
        XCTAssertTrue(mockUserRepository.updateProfileCalled)
        XCTAssertEqual(mockUserRepository.lastUpdateProfileRequest?.username, "newuser123")
        XCTAssertEqual(mockUserRepository.lastUpdateProfileRequest?.bio, "New bio")
        XCTAssertTrue(sut.saveSuccess)
    }

    func testSaveProfile_noUsernameChange_sendsNilUsername() async {
        // Given
        let profile = createMockMyProfile(username: "sameuser")
        mockUserRepository.getMyProfileResult = .success(profile)
        mockUserRepository.updateProfileResult = .success(profile)
        await sut.loadProfile()
        sut.bio = "Updated bio"

        // When
        await sut.saveProfile()

        // Then
        XCTAssertTrue(mockUserRepository.updateProfileCalled)
        XCTAssertNil(mockUserRepository.lastUpdateProfileRequest?.username)
        XCTAssertEqual(mockUserRepository.lastUpdateProfileRequest?.bio, "Updated bio")
    }

    func testSaveProfile_invalidUsername_doesNotSave() async {
        // Given
        mockUserRepository.getMyProfileResult = .success(createMockMyProfile(username: "olduser"))
        await sut.loadProfile()
        sut.username = "ab"  // Too short
        _ = sut.validateUsernameFormat(sut.username)

        // When
        await sut.saveProfile()

        // Then
        XCTAssertFalse(mockUserRepository.updateProfileCalled)
    }

    func testSaveProfile_takenUsername_doesNotSave() async {
        // Given
        mockUserRepository.getMyProfileResult = .success(createMockMyProfile(username: "olduser"))
        await sut.loadProfile()
        sut.username = "takenuser"
        mockUserRepository.checkUsernameAvailabilityResult = .success(false)
        await sut.checkUsernameAvailability()

        // When
        await sut.saveProfile()

        // Then
        XCTAssertFalse(mockUserRepository.updateProfileCalled)
    }

    func testSaveProfile_failure_setsError() async {
        // Given
        mockUserRepository.getMyProfileResult = .success(createMockMyProfile(username: "testuser"))
        mockUserRepository.updateProfileResult = .failure(.serverError("Server error"))
        await sut.loadProfile()
        sut.bio = "New bio"

        // When
        await sut.saveProfile()

        // Then
        XCTAssertNotNil(sut.error)
        XCTAssertFalse(sut.saveSuccess)
    }

    // MARK: - Load Profile Tests

    func testLoadProfile_success_populatesFields() async {
        // Given
        let profile = createMockMyProfile(
            username: "testuser",
            bio: "Test bio",
            youtubeUrl: "https://youtube.com/@test",
            instagramHandle: "@testinsta"
        )
        mockUserRepository.getMyProfileResult = .success(profile)

        // When
        await sut.loadProfile()

        // Then
        XCTAssertEqual(sut.username, "testuser")
        XCTAssertEqual(sut.bio, "Test bio")
        XCTAssertEqual(sut.youtubeUrl, "https://youtube.com/@test")
        XCTAssertEqual(sut.instagramHandle, "@testinsta")
    }

    func testLoadProfile_failure_setsError() async {
        // Given
        mockUserRepository.getMyProfileResult = .failure(.networkError("Network error"))

        // When
        await sut.loadProfile()

        // Then
        XCTAssertNotNil(sut.error)
    }

    // MARK: - Computed Properties Tests

    func testCanCheckUsername_validNewUsername_returnsTrue() async {
        // Given
        mockUserRepository.getMyProfileResult = .success(createMockMyProfile(username: "olduser"))
        await sut.loadProfile()
        sut.username = "newuser123"

        // Then
        XCTAssertTrue(sut.canCheckUsername)
    }

    func testCanCheckUsername_sameAsInitial_returnsFalse() async {
        // Given
        mockUserRepository.getMyProfileResult = .success(createMockMyProfile(username: "testuser"))
        await sut.loadProfile()

        // Then
        XCTAssertFalse(sut.canCheckUsername)
    }

    func testCanSave_noChangesNoErrors_returnsTrue() async {
        // Given
        mockUserRepository.getMyProfileResult = .success(createMockMyProfile(username: "testuser"))
        await sut.loadProfile()

        // Then
        XCTAssertTrue(sut.canSave)
    }

    func testCanSave_usernameChangedButNotChecked_returnsFalse() async {
        // Given
        mockUserRepository.getMyProfileResult = .success(createMockMyProfile(username: "olduser"))
        await sut.loadProfile()
        sut.username = "newuser123"

        // Then
        XCTAssertFalse(sut.canSave)
    }

    func testCanSave_usernameChangedAndAvailable_returnsTrue() async {
        // Given
        mockUserRepository.getMyProfileResult = .success(createMockMyProfile(username: "olduser"))
        await sut.loadProfile()
        sut.username = "newuser123"
        mockUserRepository.checkUsernameAvailabilityResult = .success(true)
        await sut.checkUsernameAvailability()

        // Then
        XCTAssertTrue(sut.canSave)
    }

    func testUsernameCharacterCount_displaysCorrectly() {
        // Given
        sut.username = "test123"

        // Then
        XCTAssertEqual(sut.usernameCharacterCount, "7/30")
    }

    // MARK: - Helpers

    private func createMockMyProfile(
        username: String = "testuser",
        bio: String? = nil,
        youtubeUrl: String? = nil,
        instagramHandle: String? = nil
    ) -> MyProfile {
        MyProfile(
            user: UserInfo(
                id: "user-me",
                username: username,
                role: "USER",
                profileImageUrl: nil,
                gender: nil,
                locale: "en",
                defaultCookingStyle: nil,
                measurementPreference: "METRIC",
                followerCount: 100,
                followingCount: 50,
                recipeCount: 15,
                logCount: 89,
                level: 12,
                levelName: "Home Cook",
                totalXp: 2450,
                xpForCurrentLevel: 450,
                xpForNextLevel: 1000,
                levelProgress: 0.45,
                bio: bio,
                youtubeUrl: youtubeUrl,
                instagramHandle: instagramHandle
            ),
            recipeCount: 15,
            logCount: 89,
            savedCount: 10
        )
    }
}
