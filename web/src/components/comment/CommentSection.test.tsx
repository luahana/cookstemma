import { render, screen, waitFor, fireEvent } from '@testing-library/react';

// Mock next-intl
jest.mock('next-intl', () => ({
  useTranslations: () => (key: string, params?: { count?: number }) => {
    const translations: Record<string, string> = {
      title: 'Comments',
      placeholder: 'Write a comment...',
      replyPlaceholder: 'Write a reply...',
      post: 'Post',
      posting: 'Posting...',
      reply: 'Reply',
      edit: 'Edit',
      save: 'Save',
      delete: 'Delete',
      deleting: 'Deleting...',
      cancel: 'Cancel',
      edited: 'edited',
      deleted: 'This comment has been deleted',
      noComments: 'No comments yet. Be the first to comment!',
      loadMore: 'Load more comments',
      viewReplies: `View ${params?.count || 0} more replies`,
      hideReplies: 'Hide replies',
      loadError: 'Failed to load comments',
      deleteConfirm: 'Are you sure you want to delete this comment?',
      loginToComment: 'Sign in to leave a comment',
    };
    return translations[key] || key;
  },
}));

// Mock @/i18n/navigation
jest.mock('@/i18n/navigation', () => ({
  Link: ({ children, href }: { children: React.ReactNode; href: string }) => (
    <a href={href}>{children}</a>
  ),
}));

import { CommentSection } from './CommentSection';

// Mock the API functions
jest.mock('@/lib/api/comments', () => ({
  getComments: jest.fn(),
  createComment: jest.fn(),
  createReply: jest.fn(),
  getReplies: jest.fn(),
}));

// Mock the AuthContext
jest.mock('@/contexts/AuthContext', () => ({
  useAuth: jest.fn(() => ({
    isAuthenticated: true,
    user: { publicId: 'current-user-123', username: 'currentuser' },
  })),
}));

import { getComments, createComment, createReply, getReplies } from '@/lib/api/comments';
import { useAuth } from '@/contexts/AuthContext';

const mockGetComments = getComments as jest.Mock;
const mockCreateComment = createComment as jest.Mock;
const mockCreateReply = createReply as jest.Mock;
const mockGetReplies = getReplies as jest.Mock;
const mockUseAuth = useAuth as jest.Mock;

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
  createdAt: new Date().toISOString(),
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

const emptyCommentsPage = {
  content: [],
  totalElements: 0,
  totalPages: 0,
  number: 0,
  size: 20,
};

describe('CommentSection', () => {
  beforeEach(() => {
    jest.clearAllMocks();
    mockGetComments.mockResolvedValue(emptyCommentsPage);
    mockUseAuth.mockReturnValue({
      isAuthenticated: true,
      user: { publicId: 'current-user-123', username: 'currentuser' },
    });
  });

  describe('Rendering', () => {
    it('should render the comment section with title', async () => {
      render(
        <CommentSection logPublicId="log-123" />
      );

      expect(screen.getByText('Comments')).toBeInTheDocument();
    });

    it('should show loading state initially', () => {
      mockGetComments.mockImplementation(() => new Promise(() => {})); // Never resolves

      render(
        <CommentSection logPublicId="log-123" />
      );

      // Look for spinner
      expect(document.querySelector('.animate-spin')).toBeInTheDocument();
    });

    it('should show no comments message when empty', async () => {
      mockGetComments.mockResolvedValue(emptyCommentsPage);

      render(
        <CommentSection logPublicId="log-123" />
      );

      await waitFor(() => {
        expect(screen.getByText('No comments yet. Be the first to comment!')).toBeInTheDocument();
      });
    });

    it('should render comments when available', async () => {
      mockGetComments.mockResolvedValue(mockCommentsPage);

      render(
        <CommentSection logPublicId="log-123" />
      );

      await waitFor(() => {
        expect(screen.getByText('Test comment')).toBeInTheDocument();
      });
    });

    it('should show comment count in title', async () => {
      mockGetComments.mockResolvedValue(mockCommentsPage);

      render(
        <CommentSection logPublicId="log-123" initialCommentCount={5} />
      );

      await waitFor(() => {
        expect(screen.getByText('(1)')).toBeInTheDocument();
      });
    });
  });

  describe('Creating Comments', () => {
    it('should create a comment when form is submitted', async () => {
      mockGetComments.mockResolvedValue(emptyCommentsPage);
      const newComment = {
        ...mockComment,
        publicId: 'new-comment-123',
        content: 'New comment content',
      };
      mockCreateComment.mockResolvedValue(newComment);

      render(
        <CommentSection logPublicId="log-123" />
      );

      await waitFor(() => {
        expect(screen.queryByText('No comments yet. Be the first to comment!')).toBeInTheDocument();
      });

      const textarea = screen.getByPlaceholderText('Write a comment...');
      fireEvent.change(textarea, { target: { value: 'New comment content' } });

      const submitButton = screen.getByText('Post');
      fireEvent.click(submitButton);

      await waitFor(() => {
        expect(mockCreateComment).toHaveBeenCalledWith('log-123', 'New comment content');
      });
    });
  });

  describe('Error Handling', () => {
    it('should show error message when loading fails', async () => {
      mockGetComments.mockRejectedValue(new Error('Network error'));

      render(
        <CommentSection logPublicId="log-123" />
      );

      await waitFor(() => {
        expect(screen.getByText('Failed to load comments')).toBeInTheDocument();
      });
    });
  });

  describe('Load More', () => {
    it('should show load more button when there are more pages', async () => {
      const pageWithMore = {
        ...mockCommentsPage,
        totalPages: 2,
        number: 0,
      };
      mockGetComments.mockResolvedValue(pageWithMore);

      render(
        <CommentSection logPublicId="log-123" />
      );

      await waitFor(() => {
        expect(screen.getByText('Load more comments')).toBeInTheDocument();
      });
    });

    it('should not show load more button when on last page', async () => {
      mockGetComments.mockResolvedValue(mockCommentsPage);

      render(
        <CommentSection logPublicId="log-123" />
      );

      await waitFor(() => {
        expect(screen.getByText('Test comment')).toBeInTheDocument();
      });

      expect(screen.queryByText('Load more comments')).not.toBeInTheDocument();
    });
  });

  describe('Replies', () => {
    it('should render replies under comments', async () => {
      const commentWithReplies = {
        content: [
          {
            comment: mockComment,
            replies: [
              {
                ...mockComment,
                publicId: 'reply-123',
                content: 'Test reply',
                creatorPublicId: 'user-456',
                creatorUsername: 'replier',
              },
            ],
            hasMoreReplies: false,
          },
        ],
        totalElements: 1,
        totalPages: 1,
        number: 0,
        size: 20,
      };
      mockGetComments.mockResolvedValue(commentWithReplies);

      render(
        <CommentSection logPublicId="log-123" />
      );

      await waitFor(() => {
        expect(screen.getByText('Test comment')).toBeInTheDocument();
        expect(screen.getByText('Test reply')).toBeInTheDocument();
      });
    });
  });
});
