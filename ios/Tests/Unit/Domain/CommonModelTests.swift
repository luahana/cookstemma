import XCTest
@testable import Cookstemma

final class CommonModelTests: XCTestCase {

    private var decoder: JSONDecoder {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return decoder
    }

    // MARK: - PaginatedResponse Tests

    func testPaginatedResponse_parsesWithContent() throws {
        // Given
        let json = """
        {
            "content": [
                {"publicId": "user-1", "username": "user1", "displayName": "User 1", "avatarUrl": null, "level": 1, "isFollowing": null},
                {"publicId": "user-2", "username": "user2", "displayName": "User 2", "avatarUrl": null, "level": 2, "isFollowing": true}
            ],
            "nextCursor": "cursor123",
            "hasMore": true
        }
        """.data(using: .utf8)!

        // When
        let response = try decoder.decode(PaginatedResponse<UserSummary>.self, from: json)

        // Then
        XCTAssertEqual(response.content.count, 2)
        XCTAssertEqual(response.content[0].username, "user1")
        XCTAssertEqual(response.nextCursor, "cursor123")
        XCTAssertTrue(response.hasMore)
    }

    func testPaginatedResponse_lastPage() throws {
        // Given
        let json = """
        {
            "content": [
                {"publicId": "user-1", "username": "user1", "displayName": null, "avatarUrl": null, "level": 1, "isFollowing": null}
            ],
            "nextCursor": null,
            "hasMore": false
        }
        """.data(using: .utf8)!

        // When
        let response = try decoder.decode(PaginatedResponse<UserSummary>.self, from: json)

        // Then
        XCTAssertEqual(response.content.count, 1)
        XCTAssertNil(response.nextCursor)
        XCTAssertFalse(response.hasMore)
    }

    func testPaginatedResponse_emptyContent() throws {
        // Given
        let json = """
        {
            "content": [],
            "nextCursor": null,
            "hasMore": false
        }
        """.data(using: .utf8)!

        // When
        let response = try decoder.decode(PaginatedResponse<UserSummary>.self, from: json)

        // Then
        XCTAssertTrue(response.content.isEmpty)
        XCTAssertFalse(response.hasMore)
    }

    // MARK: - RepositoryError Tests

    func testRepositoryError_networkError() {
        // Given
        let error = RepositoryError.networkError("Connection failed")

        // Then
        XCTAssertEqual(error.localizedDescription, "Network error: Connection failed")
    }

    func testRepositoryError_unauthorized() {
        // Given
        let error = RepositoryError.unauthorized

        // Then
        XCTAssertEqual(error.localizedDescription, "Please log in again")
    }

    func testRepositoryError_notFound() {
        // Given
        let error = RepositoryError.notFound

        // Then
        XCTAssertEqual(error.localizedDescription, "Not found")
    }

    func testRepositoryError_serverError() {
        // Given
        let error = RepositoryError.serverError("Internal server error")

        // Then
        XCTAssertEqual(error.localizedDescription, "Server error: Internal server error")
    }

    func testRepositoryError_decodingError() {
        // Given
        let error = RepositoryError.decodingError("Invalid JSON")

        // Then
        XCTAssertEqual(error.localizedDescription, "Data error: Invalid JSON")
    }

    func testRepositoryError_unknown() {
        // Given
        let error = RepositoryError.unknown

        // Then
        XCTAssertEqual(error.localizedDescription, "An unknown error occurred")
    }

    func testRepositoryError_equatable() {
        // Then
        XCTAssertEqual(RepositoryError.unauthorized, RepositoryError.unauthorized)
        XCTAssertEqual(RepositoryError.notFound, RepositoryError.notFound)
        XCTAssertEqual(RepositoryError.unknown, RepositoryError.unknown)
        XCTAssertEqual(RepositoryError.networkError("test"), RepositoryError.networkError("test"))
        XCTAssertNotEqual(RepositoryError.networkError("test1"), RepositoryError.networkError("test2"))
    }

    // MARK: - RepositoryResult Tests

    func testRepositoryResult_success() {
        // Given
        let result: RepositoryResult<String> = .success("test data")

        // Then
        switch result {
        case .success(let data):
            XCTAssertEqual(data, "test data")
        case .failure:
            XCTFail("Expected success")
        }
    }

    func testRepositoryResult_failure() {
        // Given
        let result: RepositoryResult<String> = .failure(.unauthorized)

        // Then
        switch result {
        case .success:
            XCTFail("Expected failure")
        case .failure(let error):
            XCTAssertEqual(error, .unauthorized)
        }
    }

    func testRepositoryResult_mapSuccess() {
        // Given
        let result: RepositoryResult<Int> = .success(5)

        // When
        let mapped = result.map { $0 * 2 }

        // Then
        switch mapped {
        case .success(let value):
            XCTAssertEqual(value, 10)
        case .failure:
            XCTFail("Expected success")
        }
    }

    func testRepositoryResult_mapPreservesFailure() {
        // Given
        let result: RepositoryResult<Int> = .failure(.notFound)

        // When
        let mapped = result.map { $0 * 2 }

        // Then
        switch mapped {
        case .success:
            XCTFail("Expected failure")
        case .failure(let error):
            XCTAssertEqual(error, .notFound)
        }
    }

    func testRepositoryResult_getOrNil() {
        // Given
        let successResult: RepositoryResult<String> = .success("value")
        let failureResult: RepositoryResult<String> = .failure(.unknown)

        // Then
        XCTAssertEqual(try? successResult.get(), "value")
        XCTAssertNil(try? failureResult.get())
    }

    // MARK: - Result Handling Pattern Tests

    func testResultHandling_switchPattern() {
        // Given
        let result: RepositoryResult<Int> = .success(42)

        // When
        var handledValue: Int?
        switch result {
        case .success(let value):
            handledValue = value
        case .failure:
            handledValue = nil
        }

        // Then
        XCTAssertEqual(handledValue, 42)
    }

    func testResultHandling_ifCasePattern() {
        // Given
        let successResult: RepositoryResult<String> = .success("test")
        let failureResult: RepositoryResult<String> = .failure(.unauthorized)

        // Then
        if case .success(let value) = successResult {
            XCTAssertEqual(value, "test")
        } else {
            XCTFail("Expected success")
        }

        if case .failure(let error) = failureResult {
            XCTAssertEqual(error, .unauthorized)
        } else {
            XCTFail("Expected failure")
        }
    }
}
