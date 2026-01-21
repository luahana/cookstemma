import { render, screen, fireEvent, waitFor } from '@testing-library/react';

// Mock next-intl
jest.mock('next-intl', () => ({
  useTranslations: () => (key: string) => {
    const translations: Record<string, string> = {
      reply: 'Reply',
      edit: 'Edit',
      save: 'Save',
      delete: 'Delete',
      deleting: 'Deleting...',
      cancel: 'Cancel',
      edited: 'edited',
      deleted: 'This comment has been deleted',
      placeholder: 'Write a comment...',
      replyPlaceholder: 'Write a reply...',
      post: 'Post',
      posting: 'Posting...',
      deleteConfirm: 'Are you sure you want to delete this comment?',
      loginToComment: 'Sign in to leave a comment',
      justNow: 'just now',
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

import { CommentCard } from './CommentCard';

// Mock the API functions
jest.mock('@/lib/api/comments', () => ({
  editComment: jest.fn(),
  deleteComment: jest.fn(),
  likeComment: jest.fn(),
  unlikeComment: jest.fn(),
}));

// Mock the AuthContext
jest.mock('@/contexts/AuthContext', () => ({
  useAuth: jest.fn(() => ({
    isAuthenticated: true,
    user: { publicId: 'current-user-123', username: 'currentuser' },
  })),
}));

import { editComment, deleteComment, likeComment, unlikeComment } from '@/lib/api/comments';
import { useAuth } from '@/contexts/AuthContext';

const mockEditComment = editComment as jest.Mock;
const mockDeleteComment = deleteComment as jest.Mock;
const mockLikeComment = likeComment as jest.Mock;
const mockUnlikeComment = unlikeComment as jest.Mock;
const mockUseAuth = useAuth as jest.Mock;

const mockComment = {
  publicId: 'comment-123',
  content: 'Test comment content',
  creatorPublicId: 'user-123',
  creatorUsername: 'testuser',
  creatorProfileImageUrl: null,
  replyCount: 0,
  likeCount: 5,
  isLikedByCurrentUser: false,
  isEdited: false,
  isDeleted: false,
  createdAt: new Date().toISOString(),
};

describe('CommentCard', () => {
  const mockOnReply = jest.fn();
  const mockOnUpdate = jest.fn();
  const mockOnDelete = jest.fn();

  beforeEach(() => {
    jest.clearAllMocks();
    mockUseAuth.mockReturnValue({
      isAuthenticated: true,
      user: { publicId: 'current-user-123', username: 'currentuser' },
    });
  });

  describe('Rendering', () => {
    it('should render comment content', () => {
      render(
        <CommentCard
          comment={mockComment}
          onReply={mockOnReply}
          onUpdate={mockOnUpdate}
          onDelete={mockOnDelete}
        />
      );

      expect(screen.getByText('Test comment content')).toBeInTheDocument();
    });

    it('should render username', () => {
      render(
        <CommentCard
          comment={mockComment}
          onReply={mockOnReply}
          onUpdate={mockOnUpdate}
          onDelete={mockOnDelete}
        />
      );

      expect(screen.getByText('testuser')).toBeInTheDocument();
    });

    it('should render like count', () => {
      render(
        <CommentCard
          comment={mockComment}
          onReply={mockOnReply}
          onUpdate={mockOnUpdate}
          onDelete={mockOnDelete}
        />
      );

      expect(screen.getByText('5')).toBeInTheDocument();
    });

    it('should show edited label when comment is edited', () => {
      const editedComment = { ...mockComment, isEdited: true };

      render(
        <CommentCard
          comment={editedComment}
          onReply={mockOnReply}
          onUpdate={mockOnUpdate}
          onDelete={mockOnDelete}
        />
      );

      expect(screen.getByText('(edited)')).toBeInTheDocument();
    });

    it('should show deleted message when comment is deleted', () => {
      const deletedComment = { ...mockComment, isDeleted: true, content: null };

      render(
        <CommentCard
          comment={deletedComment}
          onReply={mockOnReply}
          onUpdate={mockOnUpdate}
          onDelete={mockOnDelete}
        />
      );

      expect(screen.getByText('This comment has been deleted')).toBeInTheDocument();
    });

    it('should show reply button when authenticated and onReply provided', () => {
      render(
        <CommentCard
          comment={mockComment}
          onReply={mockOnReply}
          onUpdate={mockOnUpdate}
          onDelete={mockOnDelete}
        />
      );

      expect(screen.getByText('Reply')).toBeInTheDocument();
    });

    it('should hide reply button when showReplyButton is false', () => {
      render(
        <CommentCard
          comment={mockComment}
          onReply={mockOnReply}
          onUpdate={mockOnUpdate}
          onDelete={mockOnDelete}
          showReplyButton={false}
        />
      );

      expect(screen.queryByText('Reply')).not.toBeInTheDocument();
    });
  });

  describe('Owner Actions', () => {
    it('should show more options button for owner', () => {
      const ownComment = { ...mockComment, creatorPublicId: 'current-user-123' };

      render(
        <CommentCard
          comment={ownComment}
          onReply={mockOnReply}
          onUpdate={mockOnUpdate}
          onDelete={mockOnDelete}
        />
      );

      // The more options button (three dots)
      const moreButton = screen.getAllByRole('button').find(
        btn => btn.querySelector('svg path[d*="M12 5v.01"]')
      );
      expect(moreButton).toBeInTheDocument();
    });

    it('should not show more options button for non-owner', () => {
      render(
        <CommentCard
          comment={mockComment}
          onReply={mockOnReply}
          onUpdate={mockOnUpdate}
          onDelete={mockOnDelete}
        />
      );

      // Should not find the three-dots button with edit/delete
      const buttons = screen.getAllByRole('button');
      const moreButton = buttons.find(
        btn => btn.querySelector('svg path[d*="M12 5v.01"]')
      );
      expect(moreButton).toBeUndefined();
    });
  });

  describe('Like Functionality', () => {
    it('should call likeComment when like button is clicked', async () => {
      mockLikeComment.mockResolvedValue(undefined);

      render(
        <CommentCard
          comment={mockComment}
          onReply={mockOnReply}
          onUpdate={mockOnUpdate}
          onDelete={mockOnDelete}
        />
      );

      // Find the like button (it contains the heart SVG and like count)
      const buttons = screen.getAllByRole('button');
      const likeButton = buttons.find(btn => btn.textContent?.includes('5'));
      expect(likeButton).toBeInTheDocument();

      fireEvent.click(likeButton!);

      await waitFor(() => {
        expect(mockLikeComment).toHaveBeenCalledWith('comment-123');
      });
    });

    it('should call unlikeComment when already liked', async () => {
      const likedComment = { ...mockComment, isLikedByCurrentUser: true };
      mockUnlikeComment.mockResolvedValue(undefined);

      render(
        <CommentCard
          comment={likedComment}
          onReply={mockOnReply}
          onUpdate={mockOnUpdate}
          onDelete={mockOnDelete}
        />
      );

      const buttons = screen.getAllByRole('button');
      const likeButton = buttons.find(btn => btn.textContent?.includes('5'));
      expect(likeButton).toBeInTheDocument();

      fireEvent.click(likeButton!);

      await waitFor(() => {
        expect(mockUnlikeComment).toHaveBeenCalledWith('comment-123');
      });
    });
  });

  describe('Edit Functionality', () => {
    it('should show edit form when edit is clicked from menu', async () => {
      const ownComment = { ...mockComment, creatorPublicId: 'current-user-123' };

      render(
        <CommentCard
          comment={ownComment}
          onReply={mockOnReply}
          onUpdate={mockOnUpdate}
          onDelete={mockOnDelete}
        />
      );

      // Click the more options button first
      const buttons = screen.getAllByRole('button');
      const moreButton = buttons.find(
        btn => btn.querySelector('svg path[d*="M12 5v.01"]')
      );
      fireEvent.click(moreButton!);

      // Now click Edit from the dropdown
      await waitFor(() => {
        expect(screen.getByText('Edit')).toBeInTheDocument();
      });
      fireEvent.click(screen.getByText('Edit'));

      // Should show edit form with Save and Cancel buttons
      await waitFor(() => {
        expect(screen.getByText('Save')).toBeInTheDocument();
        expect(screen.getByText('Cancel')).toBeInTheDocument();
      });
    });
  });

  describe('Delete Functionality', () => {
    it('should call deleteComment when delete is confirmed', async () => {
      const ownComment = { ...mockComment, creatorPublicId: 'current-user-123' };
      mockDeleteComment.mockResolvedValue(undefined);

      // Mock window.confirm
      const confirmSpy = jest.spyOn(window, 'confirm').mockReturnValue(true);

      render(
        <CommentCard
          comment={ownComment}
          onReply={mockOnReply}
          onUpdate={mockOnUpdate}
          onDelete={mockOnDelete}
        />
      );

      // Click the more options button first
      const buttons = screen.getAllByRole('button');
      const moreButton = buttons.find(
        btn => btn.querySelector('svg path[d*="M12 5v.01"]')
      );
      fireEvent.click(moreButton!);

      // Now click Delete from the dropdown
      await waitFor(() => {
        expect(screen.getByText('Delete')).toBeInTheDocument();
      });
      fireEvent.click(screen.getByText('Delete'));

      await waitFor(() => {
        expect(mockDeleteComment).toHaveBeenCalledWith('comment-123');
        expect(mockOnDelete).toHaveBeenCalled();
      });

      confirmSpy.mockRestore();
    });

    it('should not delete when confirm is cancelled', async () => {
      const ownComment = { ...mockComment, creatorPublicId: 'current-user-123' };

      // Mock window.confirm
      const confirmSpy = jest.spyOn(window, 'confirm').mockReturnValue(false);

      render(
        <CommentCard
          comment={ownComment}
          onReply={mockOnReply}
          onUpdate={mockOnUpdate}
          onDelete={mockOnDelete}
        />
      );

      // Click the more options button first
      const buttons = screen.getAllByRole('button');
      const moreButton = buttons.find(
        btn => btn.querySelector('svg path[d*="M12 5v.01"]')
      );
      fireEvent.click(moreButton!);

      // Now click Delete from the dropdown
      await waitFor(() => {
        expect(screen.getByText('Delete')).toBeInTheDocument();
      });
      fireEvent.click(screen.getByText('Delete'));

      expect(mockDeleteComment).not.toHaveBeenCalled();
      expect(mockOnDelete).not.toHaveBeenCalled();

      confirmSpy.mockRestore();
    });
  });

  describe('Reply Functionality', () => {
    it('should show reply form when reply button is clicked', async () => {
      render(
        <CommentCard
          comment={mockComment}
          onReply={mockOnReply}
          onUpdate={mockOnUpdate}
          onDelete={mockOnDelete}
        />
      );

      fireEvent.click(screen.getByText('Reply'));

      await waitFor(() => {
        expect(screen.getByPlaceholderText('Write a reply...')).toBeInTheDocument();
      });
    });
  });

  describe('Unauthenticated User', () => {
    beforeEach(() => {
      mockUseAuth.mockReturnValue({
        isAuthenticated: false,
        user: null,
      });
    });

    it('should not show reply button for unauthenticated user', () => {
      render(
        <CommentCard
          comment={mockComment}
          onReply={mockOnReply}
          onUpdate={mockOnUpdate}
          onDelete={mockOnDelete}
        />
      );

      expect(screen.queryByText('Reply')).not.toBeInTheDocument();
    });

    it('should disable like button for unauthenticated user', () => {
      render(
        <CommentCard
          comment={mockComment}
          onReply={mockOnReply}
          onUpdate={mockOnUpdate}
          onDelete={mockOnDelete}
        />
      );

      const buttons = screen.getAllByRole('button');
      const likeButton = buttons.find(btn => btn.textContent?.includes('5'));
      expect(likeButton).toBeDisabled();
    });
  });
});
