import XCTest
@testable import Cookstemma

final class CommentRepositoryTests: XCTestCase {

    var sut: CommentRepository!
    var mockAPIClient: CommentTestAPIClient!

    override func setUp() {
        super.setUp()
        mockAPIClient = CommentTestAPIClient()
        sut = CommentRepository(apiClient: mockAPIClient)
    }

    override func tearDown() {
        sut = nil
        mockAPIClient = nil
        super.tearDown()
    }

    // MARK: - getComments Tests

    func testGetComments_success_returnsPaginatedResponse() async {
        // Given
        let commentResponse = MockFactory.commentResponse(
            publicId: "comment-1",
            content: "Great recipe!",
            creatorPublicId: "user-1",
            creatorUsername: "testuser"
        )
        let wrapper = MockFactory.commentWithReplies(comment: commentResponse)
        let sliceResponse = SliceResponse(
            content: [wrapper],
            last: false,
            first: true,
            empty: false,
            numberOfElements: 1,
            size: 20,
            number: 0
        )
        mockAPIClient.mockResponse = sliceResponse

        // When
        let result = await sut.getComments(logId: "log-123", cursor: nil)

        // Then
        switch result {
        case .success(let response):
            XCTAssertEqual(response.content.count, 1)
            XCTAssertEqual(response.content.first?.id, "comment-1")
            XCTAssertEqual(response.content.first?.content, "Great recipe!")
            XCTAssertEqual(response.content.first?.author.username, "testuser")
            XCTAssertTrue(response.hasMore)
            XCTAssertEqual(response.nextCursor, "1")
        case .failure(let error):
            XCTFail("Expected success, got error: \(error)")
        }
    }

    func testGetComments_withReplies_attachesReplies() async {
        // Given
        let parentComment = MockFactory.commentResponse(
            publicId: "parent-1",
            content: "Parent comment",
            replyCount: 2
        )
        let reply1 = MockFactory.commentResponse(publicId: "reply-1", content: "First reply")
        let reply2 = MockFactory.commentResponse(publicId: "reply-2", content: "Second reply")
        let wrapper = MockFactory.commentWithReplies(
            comment: parentComment,
            replies: [reply1, reply2],
            hasMoreReplies: false
        )
        let sliceResponse = SliceResponse(
            content: [wrapper],
            last: true,
            first: true,
            empty: false,
            numberOfElements: 1,
            size: 20,
            number: 0
        )
        mockAPIClient.mockResponse = sliceResponse

        // When
        let result = await sut.getComments(logId: "log-123", cursor: nil)

        // Then
        switch result {
        case .success(let response):
            XCTAssertEqual(response.content.count, 1)
            let comment = response.content.first!
            XCTAssertEqual(comment.replies?.count, 2)
            XCTAssertEqual(comment.replies?.first?.content, "First reply")
            XCTAssertFalse(response.hasMore)
        case .failure(let error):
            XCTFail("Expected success, got error: \(error)")
        }
    }

    func testGetComments_lastPage_hasMoreIsFalse() async {
        // Given
        let wrapper = MockFactory.commentWithReplies()
        let sliceResponse = SliceResponse(
            content: [wrapper],
            last: true,
            first: false,
            empty: false,
            numberOfElements: 1,
            size: 20,
            number: 1
        )
        mockAPIClient.mockResponse = sliceResponse

        // When
        let result = await sut.getComments(logId: "log-123", cursor: "1")

        // Then
        switch result {
        case .success(let response):
            XCTAssertFalse(response.hasMore)
            XCTAssertNil(response.nextCursor)
        case .failure(let error):
            XCTFail("Expected success, got error: \(error)")
        }
    }

    func testGetComments_networkError_returnsError() async {
        // Given
        mockAPIClient.mockError = APIError.networkError("Connection failed")

        // When
        let result = await sut.getComments(logId: "log-123", cursor: nil)

        // Then
        switch result {
        case .success:
            XCTFail("Expected error")
        case .failure(let error):
            XCTAssertEqual(error, .networkError("Connection failed"))
        }
    }

    func testGetComments_unauthorized_returnsError() async {
        // Given
        mockAPIClient.mockError = APIError.unauthorized

        // When
        let result = await sut.getComments(logId: "log-123", cursor: nil)

        // Then
        switch result {
        case .success:
            XCTFail("Expected error")
        case .failure(let error):
            XCTAssertEqual(error, .unauthorized)
        }
    }

    func testGetComments_decodingError_returnsError() async {
        // Given
        mockAPIClient.mockError = APIError.decodingError("Invalid response format")

        // When
        let result = await sut.getComments(logId: "log-123", cursor: nil)

        // Then
        switch result {
        case .success:
            XCTFail("Expected error")
        case .failure(let error):
            XCTAssertEqual(error, .decodingError("Invalid response format"))
        }
    }

    // MARK: - createComment Tests

    func testCreateComment_success_returnsComment() async {
        // Given
        let commentResponse = MockFactory.commentResponse(
            publicId: "new-comment",
            content: "My new comment"
        )
        mockAPIClient.mockResponse = commentResponse

        // When
        let result = await sut.createComment(logId: "log-123", content: "My new comment", parentId: nil)

        // Then
        switch result {
        case .success(let comment):
            XCTAssertEqual(comment.id, "new-comment")
            XCTAssertEqual(comment.content, "My new comment")
            XCTAssertTrue(mockAPIClient.requestCalled)
        case .failure(let error):
            XCTFail("Expected success, got error: \(error)")
        }
    }

    func testCreateComment_withParentId_callsAPI() async {
        // Given
        let commentResponse = MockFactory.commentResponse(publicId: "reply-1", content: "This is a reply")
        mockAPIClient.mockResponse = commentResponse

        // When
        let result = await sut.createComment(logId: "log-123", content: "This is a reply", parentId: "parent-1")

        // Then
        switch result {
        case .success(let comment):
            XCTAssertEqual(comment.content, "This is a reply")
            XCTAssertTrue(mockAPIClient.requestCalled)
        case .failure(let error):
            XCTFail("Expected success, got error: \(error)")
        }
    }

    func testCreateComment_serverError_returnsError() async {
        // Given
        mockAPIClient.mockError = APIError.serverError(400, "Content too long")

        // When
        let result = await sut.createComment(logId: "log-123", content: "x", parentId: nil)

        // Then
        switch result {
        case .success:
            XCTFail("Expected error")
        case .failure(let error):
            XCTAssertEqual(error, .serverError("Content too long"))
        }
    }

    // MARK: - updateComment Tests

    func testUpdateComment_success_returnsUpdatedComment() async {
        // Given
        let commentResponse = MockFactory.commentResponse(
            publicId: "comment-1",
            content: "Updated content",
            isEdited: true
        )
        mockAPIClient.mockResponse = commentResponse

        // When
        let result = await sut.updateComment(id: "comment-1", content: "Updated content")

        // Then
        switch result {
        case .success(let comment):
            XCTAssertEqual(comment.content, "Updated content")
            XCTAssertTrue(comment.isEdited)
            XCTAssertTrue(mockAPIClient.requestCalled)
        case .failure(let error):
            XCTFail("Expected success, got error: \(error)")
        }
    }

    func testUpdateComment_notFound_returnsError() async {
        // Given
        mockAPIClient.mockError = APIError.notFound

        // When
        let result = await sut.updateComment(id: "non-existent", content: "New content")

        // Then
        switch result {
        case .success:
            XCTFail("Expected error")
        case .failure(let error):
            XCTAssertEqual(error, .notFound)
        }
    }

    // MARK: - deleteComment Tests

    func testDeleteComment_success_returnsVoid() async {
        // Given
        mockAPIClient.mockResponse = VoidResponse()

        // When
        let result = await sut.deleteComment(id: "comment-1")

        // Then
        switch result {
        case .success:
            XCTAssertTrue(mockAPIClient.requestCalled)
        case .failure(let error):
            XCTFail("Expected success, got error: \(error)")
        }
    }

    func testDeleteComment_notFound_returnsError() async {
        // Given
        mockAPIClient.mockError = APIError.notFound

        // When
        let result = await sut.deleteComment(id: "non-existent")

        // Then
        switch result {
        case .success:
            XCTFail("Expected error")
        case .failure(let error):
            XCTAssertEqual(error, .notFound)
        }
    }

    // MARK: - likeComment Tests

    func testLikeComment_success_returnsVoid() async {
        // Given
        mockAPIClient.mockResponse = VoidResponse()

        // When
        let result = await sut.likeComment(id: "comment-1")

        // Then
        switch result {
        case .success:
            XCTAssertTrue(mockAPIClient.requestCalled)
        case .failure(let error):
            XCTFail("Expected success, got error: \(error)")
        }
    }

    // MARK: - unlikeComment Tests

    func testUnlikeComment_success_returnsVoid() async {
        // Given
        mockAPIClient.mockResponse = VoidResponse()

        // When
        let result = await sut.unlikeComment(id: "comment-1")

        // Then
        switch result {
        case .success:
            XCTAssertTrue(mockAPIClient.requestCalled)
        case .failure(let error):
            XCTFail("Expected success, got error: \(error)")
        }
    }

    // MARK: - Error Mapping Tests

    func testErrorMapping_unknownError() async {
        // Given
        mockAPIClient.mockError = NSError(domain: "test", code: -1)

        // When
        let result = await sut.getComments(logId: "log-123", cursor: nil)

        // Then
        switch result {
        case .success:
            XCTFail("Expected error")
        case .failure(let error):
            XCTAssertEqual(error, .unknown)
        }
    }
}

// MARK: - Test Helpers

private struct VoidResponse: Decodable {}

final class CommentTestAPIClient: APIClientProtocol {
    var mockResponse: Any?
    var mockError: Error?
    var requestCalled = false

    func request<T: Decodable>(_ endpoint: any APIEndpoint) async throws -> T {
        requestCalled = true

        if let error = mockError {
            throw error
        }

        guard let response = mockResponse as? T else {
            throw APIError.decodingError("Mock response type mismatch")
        }

        return response
    }

    func upload<T: Decodable>(_ endpoint: any APIEndpoint, data: Data, mimeType: String) async throws -> T {
        requestCalled = true

        if let error = mockError {
            throw error
        }

        guard let response = mockResponse as? T else {
            throw APIError.decodingError("Mock response type mismatch")
        }

        return response
    }
}
