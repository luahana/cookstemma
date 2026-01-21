import {
  getComments,
  createComment,
  getReplies,
  createReply,
  editComment,
  deleteComment,
  likeComment,
  unlikeComment,
} from './comments';

// Mock the client module
jest.mock('./client', () => ({
  apiFetch: jest.fn(),
  buildQueryString: jest.fn((params) => {
    const entries = Object.entries(params).filter(([, v]) => v !== undefined);
    if (entries.length === 0) return '';
    return '?' + entries.map(([k, v]) => `${k}=${encodeURIComponent(String(v))}`).join('&');
  }),
}));

import { apiFetch, buildQueryString } from './client';

const mockApiFetch = apiFetch as jest.Mock;
const mockBuildQueryString = buildQueryString as jest.Mock;

const mockComment = {
  publicId: 'comment-123',
  content: 'Test comment',
  creatorPublicId: 'user-123',
  creatorUsername: 'testuser',
  creatorProfileImageUrl: null,
  replyCount: 0,
  likeCount: 0,
  isLikedByCurrentUser: false,
  isEdited: false,
  isDeleted: false,
  createdAt: '2024-01-01T00:00:00Z',
};

const mockCommentsPage = {
  content: [
    {
      comment: mockComment,
      replies: [],
      hasMoreReplies: false,
    },
  ],
  totalElements: 1,
  totalPages: 1,
  number: 0,
  size: 20,
};

const mockRepliesPage = {
  content: [mockComment],
  totalElements: 1,
  totalPages: 1,
  number: 0,
  size: 20,
};

describe('comments API', () => {
  beforeEach(() => {
    jest.clearAllMocks();
  });

  describe('getComments', () => {
    it('should fetch comments with default pagination', async () => {
      mockApiFetch.mockResolvedValue(mockCommentsPage);

      const result = await getComments('log-123');

      expect(mockBuildQueryString).toHaveBeenCalledWith({
        page: 0,
        size: 20,
      });
      expect(mockApiFetch).toHaveBeenCalledWith(
        '/log_posts/log-123/comments?page=0&size=20',
        { cache: 'no-store' }
      );
      expect(result).toEqual(mockCommentsPage);
    });

    it('should fetch comments with custom pagination', async () => {
      mockApiFetch.mockResolvedValue(mockCommentsPage);

      await getComments('log-123', { page: 2, size: 10 });

      expect(mockBuildQueryString).toHaveBeenCalledWith({
        page: 2,
        size: 10,
      });
    });
  });

  describe('createComment', () => {
    it('should create a comment with content', async () => {
      mockApiFetch.mockResolvedValue(mockComment);

      const result = await createComment('log-123', 'New comment');

      expect(mockApiFetch).toHaveBeenCalledWith(
        '/log_posts/log-123/comments',
        {
          method: 'POST',
          body: JSON.stringify({ content: 'New comment' }),
          cache: 'no-store',
        }
      );
      expect(result).toEqual(mockComment);
    });
  });

  describe('getReplies', () => {
    it('should fetch replies with default pagination', async () => {
      mockApiFetch.mockResolvedValue(mockRepliesPage);

      const result = await getReplies('comment-123');

      expect(mockBuildQueryString).toHaveBeenCalledWith({
        page: 0,
        size: 20,
      });
      expect(mockApiFetch).toHaveBeenCalledWith(
        '/comments/comment-123/replies?page=0&size=20',
        { cache: 'no-store' }
      );
      expect(result).toEqual(mockRepliesPage);
    });

    it('should fetch replies with custom pagination', async () => {
      mockApiFetch.mockResolvedValue(mockRepliesPage);

      await getReplies('comment-123', { page: 1, size: 50 });

      expect(mockBuildQueryString).toHaveBeenCalledWith({
        page: 1,
        size: 50,
      });
    });
  });

  describe('createReply', () => {
    it('should create a reply with content', async () => {
      mockApiFetch.mockResolvedValue(mockComment);

      const result = await createReply('comment-123', 'New reply');

      expect(mockApiFetch).toHaveBeenCalledWith(
        '/comments/comment-123/replies',
        {
          method: 'POST',
          body: JSON.stringify({ content: 'New reply' }),
          cache: 'no-store',
        }
      );
      expect(result).toEqual(mockComment);
    });
  });

  describe('editComment', () => {
    it('should edit a comment with new content', async () => {
      const editedComment = { ...mockComment, content: 'Updated content', isEdited: true };
      mockApiFetch.mockResolvedValue(editedComment);

      const result = await editComment('comment-123', 'Updated content');

      expect(mockApiFetch).toHaveBeenCalledWith(
        '/comments/comment-123',
        {
          method: 'PUT',
          body: JSON.stringify({ content: 'Updated content' }),
          cache: 'no-store',
        }
      );
      expect(result.content).toBe('Updated content');
      expect(result.isEdited).toBe(true);
    });
  });

  describe('deleteComment', () => {
    it('should delete a comment', async () => {
      mockApiFetch.mockResolvedValue(undefined);

      await deleteComment('comment-123');

      expect(mockApiFetch).toHaveBeenCalledWith(
        '/comments/comment-123',
        {
          method: 'DELETE',
          cache: 'no-store',
        }
      );
    });
  });

  describe('likeComment', () => {
    it('should like a comment', async () => {
      mockApiFetch.mockResolvedValue(undefined);

      await likeComment('comment-123');

      expect(mockApiFetch).toHaveBeenCalledWith(
        '/comments/comment-123/like',
        {
          method: 'POST',
          cache: 'no-store',
        }
      );
    });
  });

  describe('unlikeComment', () => {
    it('should unlike a comment', async () => {
      mockApiFetch.mockResolvedValue(undefined);

      await unlikeComment('comment-123');

      expect(mockApiFetch).toHaveBeenCalledWith(
        '/comments/comment-123/like',
        {
          method: 'DELETE',
          cache: 'no-store',
        }
      );
    });
  });
});
