import XCTest
@testable import Cookstemma

@MainActor
final class CommentsViewModelTests: XCTestCase {

    var sut: CommentsViewModel!
    var mockRepository: MockCommentRepository!

    override func setUp() {
        super.setUp()
        mockRepository = MockCommentRepository()
        sut = CommentsViewModel(logId: "log-123", commentRepository: mockRepository)
    }

    override func tearDown() {
        sut = nil
        mockRepository = nil
        super.tearDown()
    }

    // MARK: - loadComments Tests

    func testLoadComments_success_updatesComments() async {
        // Given
        let comments = [
            MockFactory.comment(id: "c1", content: "First comment"),
            MockFactory.comment(id: "c2", content: "Second comment")
        ]
        mockRepository.getCommentsResult = .success(
            PaginatedResponse(content: comments, nextCursor: "next", hasNext: true)
        )

        // When
        sut.loadComments()
        // Wait for async task
        try? await Task.sleep(nanoseconds: 100_000_000)

        // Then
        XCTAssertEqual(sut.comments.count, 2)
        XCTAssertEqual(sut.comments.first?.content, "First comment")
        XCTAssertTrue(sut.hasMore)
        XCTAssertFalse(sut.isLoading)
    }

    func testLoadComments_failure_keepsEmptyComments() async {
        // Given
        mockRepository.getCommentsResult = .failure(.networkError("No connection"))

        // When
        sut.loadComments()
        // Wait for async task
        try? await Task.sleep(nanoseconds: 100_000_000)

        // Then
        XCTAssertTrue(sut.comments.isEmpty)
        XCTAssertFalse(sut.isLoading)
    }

    func testLoadComments_whileLoading_doesNothing() async {
        // Given
        mockRepository.getCommentsResult = .success(
            PaginatedResponse(content: [], nextCursor: nil, hasNext: false)
        )
        sut.loadComments() // Start loading

        // When
        sut.loadComments() // Try to load again while loading

        // Then - Only one load should happen
        try? await Task.sleep(nanoseconds: 100_000_000)
        XCTAssertFalse(sut.isLoading)
    }

    // MARK: - loadMore Tests

    func testLoadMore_success_appendsComments() async {
        // Given - First load some comments
        let initialComments = [MockFactory.comment(id: "c1", content: "Initial")]
        mockRepository.getCommentsResult = .success(
            PaginatedResponse(content: initialComments, nextCursor: "page-1", hasNext: true)
        )
        sut.loadComments()
        try? await Task.sleep(nanoseconds: 100_000_000)

        // Setup for loadMore
        let moreComments = [MockFactory.comment(id: "c2", content: "More")]
        mockRepository.getCommentsResult = .success(
            PaginatedResponse(content: moreComments, nextCursor: nil, hasNext: false)
        )

        // When
        sut.loadMore()
        try? await Task.sleep(nanoseconds: 100_000_000)

        // Then
        XCTAssertEqual(sut.comments.count, 2)
        XCTAssertEqual(sut.comments.last?.content, "More")
        XCTAssertFalse(sut.hasMore)
    }

    func testLoadMore_whenNoMore_doesNothing() async {
        // Given
        mockRepository.getCommentsResult = .success(
            PaginatedResponse(content: [], nextCursor: nil, hasNext: false)
        )
        sut.loadComments()
        try? await Task.sleep(nanoseconds: 100_000_000)

        // When
        sut.loadMore()
        try? await Task.sleep(nanoseconds: 100_000_000)

        // Then - hasMore should still be false
        XCTAssertFalse(sut.hasMore)
    }

    // MARK: - postComment Tests

    func testPostComment_success_insertsAtBeginning() async {
        // Given
        let newComment = MockFactory.comment(id: "new", content: "New comment")
        mockRepository.createCommentResult = .success(newComment)
        sut.newCommentText = "New comment"

        // When
        await sut.postComment()

        // Then
        XCTAssertEqual(sut.comments.first?.content, "New comment")
        XCTAssertEqual(sut.newCommentText, "")
    }

    func testPostComment_emptyText_doesNotPost() async {
        // Given
        sut.newCommentText = "   "

        // When
        await sut.postComment()

        // Then
        XCTAssertTrue(sut.comments.isEmpty)
    }

    func testPostComment_failure_doesNotInsert() async {
        // Given
        mockRepository.createCommentResult = .failure(.serverError("Failed"))
        sut.newCommentText = "Test comment"

        // When
        await sut.postComment()

        // Then
        XCTAssertTrue(sut.comments.isEmpty)
        XCTAssertEqual(sut.newCommentText, "")
    }

    // MARK: - likeComment Tests

    func testLikeComment_success_updatesState() async {
        // Given
        let comment = MockFactory.comment(id: "c1", isLiked: false)
        mockRepository.getCommentsResult = .success(
            PaginatedResponse(content: [comment], nextCursor: nil, hasNext: false)
        )
        sut.loadComments()
        try? await Task.sleep(nanoseconds: 100_000_000)

        // When
        await sut.likeComment(sut.comments.first!)

        // Then
        XCTAssertTrue(sut.comments.first?.isLiked ?? false)
        XCTAssertTrue(mockRepository.likeCommentCalled)
    }

    func testUnlikeComment_success_updatesState() async {
        // Given
        let comment = MockFactory.comment(id: "c1", isLiked: true)
        mockRepository.getCommentsResult = .success(
            PaginatedResponse(content: [comment], nextCursor: nil, hasNext: false)
        )
        sut.loadComments()
        try? await Task.sleep(nanoseconds: 100_000_000)

        // When
        await sut.likeComment(sut.comments.first!)

        // Then
        XCTAssertFalse(sut.comments.first?.isLiked ?? true)
        XCTAssertTrue(mockRepository.unlikeCommentCalled)
    }

    func testLikeComment_failure_revertsState() async {
        // Given
        let comment = MockFactory.comment(id: "c1", isLiked: false)
        mockRepository.getCommentsResult = .success(
            PaginatedResponse(content: [comment], nextCursor: nil, hasNext: false)
        )
        sut.loadComments()
        try? await Task.sleep(nanoseconds: 100_000_000)

        // Setup failure for like
        mockRepository.likeCommentResult = .failure(.serverError("Failed"))

        // When
        await sut.likeComment(sut.comments.first!)

        // Then - Should revert to original state
        XCTAssertFalse(sut.comments.first?.isLiked ?? true)
    }
}
