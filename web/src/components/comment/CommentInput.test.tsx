import { render, screen, fireEvent, waitFor } from '@testing-library/react';
import userEvent from '@testing-library/user-event';

// Mock next-intl
jest.mock('next-intl', () => ({
  useTranslations: () => (key: string) => {
    const translations: Record<string, string> = {
      placeholder: 'Write a comment...',
      post: 'Post',
      posting: 'Posting...',
      cancel: 'Cancel',
      loginToComment: 'Sign in to leave a comment',
    };
    return translations[key] || key;
  },
}));

// Mock the AuthContext
jest.mock('@/contexts/AuthContext', () => ({
  useAuth: jest.fn(() => ({
    isAuthenticated: true,
    user: { publicId: 'current-user-123', username: 'currentuser' },
  })),
}));

import { CommentInput } from './CommentInput';
import { useAuth } from '@/contexts/AuthContext';

const mockUseAuth = useAuth as jest.Mock;

describe('CommentInput', () => {
  const mockOnSubmit = jest.fn();

  beforeEach(() => {
    jest.clearAllMocks();
    mockUseAuth.mockReturnValue({
      isAuthenticated: true,
      user: { publicId: 'current-user-123', username: 'currentuser' },
    });
  });

  describe('Rendering', () => {
    it('should render input with default placeholder', () => {
      render(<CommentInput onSubmit={mockOnSubmit} />);

      expect(screen.getByPlaceholderText('Write a comment...')).toBeInTheDocument();
    });

    it('should render with custom placeholder', () => {
      render(<CommentInput onSubmit={mockOnSubmit} placeholder="Write a reply..." />);

      expect(screen.getByPlaceholderText('Write a reply...')).toBeInTheDocument();
    });

    it('should render submit button', () => {
      render(<CommentInput onSubmit={mockOnSubmit} />);

      expect(screen.getByRole('button', { name: /post/i })).toBeInTheDocument();
    });

    it('should render with custom button text', () => {
      render(<CommentInput onSubmit={mockOnSubmit} buttonText="Reply" />);

      expect(screen.getByRole('button', { name: /reply/i })).toBeInTheDocument();
    });

    it('should disable submit button when input is empty', () => {
      render(<CommentInput onSubmit={mockOnSubmit} />);

      const submitButton = screen.getByRole('button', { name: /post/i });
      expect(submitButton).toBeDisabled();
    });

    it('should show login message for unauthenticated user', () => {
      mockUseAuth.mockReturnValue({
        isAuthenticated: false,
        user: null,
      });

      render(<CommentInput onSubmit={mockOnSubmit} />);

      expect(screen.getByText('Sign in to leave a comment')).toBeInTheDocument();
    });
  });

  describe('User Interaction', () => {
    it('should enable submit button when text is entered', async () => {
      render(<CommentInput onSubmit={mockOnSubmit} />);

      const input = screen.getByPlaceholderText('Write a comment...');
      await userEvent.type(input, 'New comment');

      const submitButton = screen.getByRole('button', { name: /post/i });
      expect(submitButton).toBeEnabled();
    });

    it('should call onSubmit with content when form is submitted', async () => {
      mockOnSubmit.mockResolvedValue(undefined);

      render(<CommentInput onSubmit={mockOnSubmit} />);

      const input = screen.getByPlaceholderText('Write a comment...');
      await userEvent.type(input, 'New comment');

      const submitButton = screen.getByRole('button', { name: /post/i });
      fireEvent.click(submitButton);

      await waitFor(() => {
        expect(mockOnSubmit).toHaveBeenCalledWith('New comment');
      });
    });

    it('should clear input after successful submit', async () => {
      mockOnSubmit.mockResolvedValue(undefined);

      render(<CommentInput onSubmit={mockOnSubmit} />);

      const input = screen.getByPlaceholderText('Write a comment...');
      await userEvent.type(input, 'New comment');

      const submitButton = screen.getByRole('button', { name: /post/i });
      fireEvent.click(submitButton);

      await waitFor(() => {
        expect(input).toHaveValue('');
      });
    });

    it('should show loading state while submitting', async () => {
      mockOnSubmit.mockImplementation(
        () => new Promise((resolve) => setTimeout(resolve, 100))
      );

      render(<CommentInput onSubmit={mockOnSubmit} />);

      const input = screen.getByPlaceholderText('Write a comment...');
      await userEvent.type(input, 'New comment');

      const submitButton = screen.getByRole('button', { name: /post/i });
      fireEvent.click(submitButton);

      expect(screen.getByText('Posting...')).toBeInTheDocument();

      await waitFor(() => {
        expect(screen.getByRole('button', { name: /post/i })).toBeInTheDocument();
      });
    });

    it('should disable input and button while submitting', async () => {
      mockOnSubmit.mockImplementation(
        () => new Promise((resolve) => setTimeout(resolve, 100))
      );

      render(<CommentInput onSubmit={mockOnSubmit} />);

      const input = screen.getByPlaceholderText('Write a comment...');
      await userEvent.type(input, 'New comment');

      const submitButton = screen.getByRole('button', { name: /post/i });
      fireEvent.click(submitButton);

      expect(input).toBeDisabled();
      expect(screen.getByText('Posting...')).toBeDisabled();

      await waitFor(() => {
        expect(input).not.toBeDisabled();
      });
    });

    it('should not clear input if submit fails', async () => {
      mockOnSubmit.mockRejectedValue(new Error('Submit failed'));

      render(<CommentInput onSubmit={mockOnSubmit} />);

      const input = screen.getByPlaceholderText('Write a comment...');
      await userEvent.type(input, 'New comment');

      const submitButton = screen.getByRole('button', { name: /post/i });
      fireEvent.click(submitButton);

      await waitFor(() => {
        expect(input).toHaveValue('New comment');
      });
    });

    it('should trim whitespace from content', async () => {
      mockOnSubmit.mockResolvedValue(undefined);

      render(<CommentInput onSubmit={mockOnSubmit} />);

      const input = screen.getByPlaceholderText('Write a comment...');
      await userEvent.type(input, '  New comment  ');

      const submitButton = screen.getByRole('button', { name: /post/i });
      fireEvent.click(submitButton);

      await waitFor(() => {
        expect(mockOnSubmit).toHaveBeenCalledWith('New comment');
      });
    });

    it('should not submit if content is only whitespace', async () => {
      render(<CommentInput onSubmit={mockOnSubmit} />);

      const input = screen.getByPlaceholderText('Write a comment...');
      await userEvent.type(input, '   ');

      const submitButton = screen.getByRole('button', { name: /post/i });
      expect(submitButton).toBeDisabled();
    });
  });

  describe('Cancel Functionality', () => {
    it('should show cancel button when onCancel is provided', () => {
      const mockOnCancel = jest.fn();

      render(<CommentInput onSubmit={mockOnSubmit} onCancel={mockOnCancel} />);

      expect(screen.getByText('Cancel')).toBeInTheDocument();
    });

    it('should call onCancel when cancel button is clicked', () => {
      const mockOnCancel = jest.fn();

      render(<CommentInput onSubmit={mockOnSubmit} onCancel={mockOnCancel} />);

      fireEvent.click(screen.getByText('Cancel'));

      expect(mockOnCancel).toHaveBeenCalled();
    });

    it('should not show cancel button when onCancel is not provided', () => {
      render(<CommentInput onSubmit={mockOnSubmit} />);

      expect(screen.queryByText('Cancel')).not.toBeInTheDocument();
    });
  });
});
