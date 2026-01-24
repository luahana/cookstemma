import { render, screen, fireEvent } from '@testing-library/react';
import { useRouter } from 'next/navigation';

// Mock next/navigation
jest.mock('next/navigation', () => ({
  useRouter: jest.fn(),
}));

// Mock next-intl
jest.mock('next-intl', () => ({
  useTranslations: (namespace: string) => (key: string, args?: { count?: number }) => {
    const translations: Record<string, Record<string, string>> = {
      common: {
        by: 'by',
      },
      card: {
        variant: 'Variant',
        recipe: 'Recipe',
        cookingLog: 'Cooking Log',
        private: 'Private',
      },
      comments: {
        count: `${args?.count || 0} comments`,
        countSingular: '1 comment',
      },
    };

    const namespaceTranslations = translations[namespace] || {};
    const result = namespaceTranslations[key] || key;

    if (args && typeof result === 'string' && result.includes('{count}')) {
      return result.replace('{count}', String(args.count));
    }

    return result;
  },
}));

// Mock @/i18n/navigation
jest.mock('@/i18n/navigation', () => ({
  Link: ({ children, href, ...props }: { children: React.ReactNode; href: string; className?: string }) => (
    <a href={href} {...props}>{children}</a>
  ),
}));

// Mock next/image
jest.mock('next/image', () => ({
  __esModule: true,
  default: ({ src, alt }: { src: string; alt: string }) => <img src={src} alt={alt} />,
}));

// Mock BookmarkButton
jest.mock('@/components/common/BookmarkButton', () => ({
  BookmarkButton: () => <button data-testid="bookmark-button">Bookmark</button>,
}));

// Mock StarRating
jest.mock('../StarRating', () => ({
  StarRating: ({ rating }: { rating: number }) => <div data-testid="star-rating">{rating} stars</div>,
}));

// Mock image utility
jest.mock('@/lib/utils/image', () => ({
  getImageUrl: (url: string | null) => url,
}));

import { LogCard } from '../LogCard';
import type { LogPostSummary } from '@/lib/types';

const mockPush = jest.fn();

const mockLog: LogPostSummary = {
  publicId: 'test-log-123',
  title: 'Test Log',
  content: 'Test cooking notes',
  rating: 4,
  thumbnailUrl: 'https://example.com/image.jpg',
  creatorPublicId: 'creator-123',
  userName: 'TestUser',
  foodName: 'Test Food',
  recipeTitle: 'Test Recipe',
  hashtags: ['cooking', 'test', 'food'],
  isVariant: false,
  isPrivate: false,
  commentCount: 0,
};

describe('LogCard - Comment Count', () => {
  beforeEach(() => {
    jest.clearAllMocks();
    (useRouter as jest.Mock).mockReturnValue({
      push: mockPush,
    });
  });

  it('shows comment count when count > 0', () => {
    const log = { ...mockLog, commentCount: 5 };
    render(<LogCard log={log} />);

    expect(screen.getByText('5')).toBeInTheDocument();
    expect(screen.getByLabelText('5 comments')).toBeInTheDocument();
  });

  it('hides comment count when count is 0', () => {
    const log = { ...mockLog, commentCount: 0 };
    render(<LogCard log={log} />);

    expect(screen.queryByLabelText('0 comments')).not.toBeInTheDocument();
  });

  it('navigates to log detail with #comments hash on click', () => {
    const log = { ...mockLog, commentCount: 3 };
    render(<LogCard log={log} />);

    const commentButton = screen.getByLabelText('3 comments');
    fireEvent.click(commentButton);

    expect(mockPush).toHaveBeenCalledWith('/logs/test-log-123#comments');
  });

  it('prevents event propagation to card link', () => {
    const log = { ...mockLog, commentCount: 2 };
    render(<LogCard log={log} />);

    const commentButton = screen.getByLabelText('2 comments');
    const clickEvent = new MouseEvent('click', { bubbles: true, cancelable: true });
    const preventDefaultSpy = jest.spyOn(clickEvent, 'preventDefault');
    const stopPropagationSpy = jest.spyOn(clickEvent, 'stopPropagation');

    fireEvent(commentButton, clickEvent);

    expect(preventDefaultSpy).toHaveBeenCalled();
    expect(stopPropagationSpy).toHaveBeenCalled();
  });

  it('shows correct singular text for 1 comment', () => {
    const log = { ...mockLog, commentCount: 1 };
    render(<LogCard log={log} />);

    expect(screen.getByLabelText('1 comment')).toBeInTheDocument();
  });

  it('shows correct plural text for multiple comments', () => {
    const log = { ...mockLog, commentCount: 24 };
    render(<LogCard log={log} />);

    expect(screen.getByLabelText('24 comments')).toBeInTheDocument();
  });

  it('displays comment count in engagement metrics section', () => {
    const log = { ...mockLog, commentCount: 10 };
    render(<LogCard log={log} />);

    // Check that the comment count button exists within the engagement metrics section
    const button = screen.getByLabelText('10 comments');
    expect(button).toBeInTheDocument();
    expect(button.tagName).toBe('BUTTON');

    // Check that the SVG icon is present
    const svg = button.querySelector('svg');
    expect(svg).toBeInTheDocument();
    expect(svg).toHaveClass('w-4', 'h-4');
  });

  it('applies hover styles to comment button', () => {
    const log = { ...mockLog, commentCount: 5 };
    render(<LogCard log={log} />);

    const button = screen.getByLabelText('5 comments');
    expect(button).toHaveClass('hover:text-[var(--primary)]');
    expect(button).toHaveClass('transition-colors');
  });

  it('handles large comment counts correctly', () => {
    const log = { ...mockLog, commentCount: 999 };
    render(<LogCard log={log} />);

    expect(screen.getByText('999')).toBeInTheDocument();
    expect(screen.getByLabelText('999 comments')).toBeInTheDocument();
  });

  it('renders all card elements correctly with comment count', () => {
    const log = { ...mockLog, commentCount: 7 };
    render(<LogCard log={log} />);

    // Check that other card elements are still present
    expect(screen.getByText('Test Recipe')).toBeInTheDocument();
    expect(screen.getByText('Test Food')).toBeInTheDocument();
    expect(screen.getByText('Test cooking notes')).toBeInTheDocument();
    expect(screen.getByText('TestUser')).toBeInTheDocument();
    expect(screen.getByText('#cooking')).toBeInTheDocument();
    expect(screen.getByTestId('bookmark-button')).toBeInTheDocument();
    expect(screen.getByTestId('star-rating')).toBeInTheDocument();

    // Check that comment count is also present
    expect(screen.getByLabelText('7 comments')).toBeInTheDocument();
  });
});

describe('LogCard - Clickable Hashtags', () => {
  beforeEach(() => {
    jest.clearAllMocks();
    (useRouter as jest.Mock).mockReturnValue({
      push: mockPush,
    });
  });

  it('renders hashtags as clickable buttons', () => {
    render(<LogCard log={mockLog} />);

    const hashtagButton = screen.getByRole('button', { name: '#cooking' });
    expect(hashtagButton).toBeInTheDocument();
  });

  it('navigates to hashtag page when clicked', () => {
    render(<LogCard log={mockLog} />);

    const hashtagButton = screen.getByRole('button', { name: '#cooking' });
    fireEvent.click(hashtagButton);

    expect(mockPush).toHaveBeenCalledWith('/hashtags/cooking');
  });

  it('encodes special characters in hashtag navigation', () => {
    const logWithSpecialHashtag = {
      ...mockLog,
      hashtags: ['Korean BBQ', 'test'],
    };
    render(<LogCard log={logWithSpecialHashtag} />);

    const hashtagButton = screen.getByRole('button', { name: '#Korean BBQ' });
    fireEvent.click(hashtagButton);

    expect(mockPush).toHaveBeenCalledWith('/hashtags/Korean%20BBQ');
  });

  it('stops propagation when hashtag is clicked', () => {
    render(<LogCard log={mockLog} />);

    const hashtagButton = screen.getByRole('button', { name: '#cooking' });
    const clickEvent = new MouseEvent('click', { bubbles: true, cancelable: true });
    const stopPropagationSpy = jest.spyOn(clickEvent, 'stopPropagation');

    fireEvent(hashtagButton, clickEvent);

    expect(stopPropagationSpy).toHaveBeenCalled();
  });

  it('displays only first 3 hashtags', () => {
    const logWithManyHashtags = {
      ...mockLog,
      hashtags: ['one', 'two', 'three', 'four', 'five'],
    };
    render(<LogCard log={logWithManyHashtags} />);

    expect(screen.getByRole('button', { name: '#one' })).toBeInTheDocument();
    expect(screen.getByRole('button', { name: '#two' })).toBeInTheDocument();
    expect(screen.getByRole('button', { name: '#three' })).toBeInTheDocument();
    expect(screen.queryByRole('button', { name: '#four' })).not.toBeInTheDocument();
    expect(screen.queryByRole('button', { name: '#five' })).not.toBeInTheDocument();
  });

  it('does not render hashtag section when hashtags array is empty', () => {
    const logWithNoHashtags = {
      ...mockLog,
      hashtags: [],
    };
    render(<LogCard log={logWithNoHashtags} />);

    // Only check that hashtag buttons are not present (exclude bookmark and comment buttons)
    expect(screen.queryByRole('button', { name: /^#/ })).not.toBeInTheDocument();
  });
});
