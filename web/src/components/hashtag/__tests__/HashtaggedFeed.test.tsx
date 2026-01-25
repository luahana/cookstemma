import { render, screen, fireEvent } from '@testing-library/react';
import { useRouter } from 'next/navigation';

// Mock next/navigation
jest.mock('next/navigation', () => ({
  useRouter: jest.fn(),
}));

// Mock next-intl
jest.mock('next-intl', () => ({
  useTranslations: (namespace: string) => (key: string) => {
    const translations: Record<string, Record<string, string>> = {
      hashtagsPage: {
        noContent: 'No content found',
      },
      card: {
        recipe: 'Recipe',
        cookingLog: 'Cooking Log',
        private: 'Private',
      },
    };

    return translations[namespace]?.[key] || key;
  },
}));

// Mock @/i18n/navigation
jest.mock('@/i18n/navigation', () => ({
  Link: ({ children, href, onClick, ...props }: {
    children: React.ReactNode;
    href: string;
    onClick?: (e: React.MouseEvent) => void;
    className?: string;
  }) => (
    <a href={href} onClick={onClick} {...props}>{children}</a>
  ),
}));

// Mock next/image
jest.mock('next/image', () => ({
  __esModule: true,
  default: ({ src, alt }: { src: string; alt: string }) => <img src={src} alt={alt} />,
}));

// Mock StarRating
jest.mock('@/components/log/StarRating', () => ({
  StarRating: ({ rating }: { rating: number }) => <div data-testid="star-rating">{rating} stars</div>,
}));

// Mock image utility
jest.mock('@/lib/utils/image', () => ({
  getImageUrl: (url: string | null) => url,
}));

import { HashtaggedFeed } from '../HashtaggedFeed';
import type { HashtaggedContentItem } from '@/lib/types';

const mockPush = jest.fn();

const mockRecipeItem: HashtaggedContentItem = {
  type: 'recipe',
  publicId: 'recipe-123',
  title: 'Test Recipe',
  thumbnailUrl: 'https://example.com/recipe.jpg',
  userName: 'TestUser',
  foodName: 'Test Food',
  hashtags: ['cooking', 'test', 'food'],
  isPrivate: false,
  rating: null,
  recipeTitle: null,
};

const mockLogItem: HashtaggedContentItem = {
  type: 'log',
  publicId: 'log-123',
  title: 'Test Log',
  thumbnailUrl: 'https://example.com/log.jpg',
  userName: 'TestUser',
  foodName: null,
  hashtags: ['delicious', 'homemade'],
  isPrivate: false,
  rating: 4,
  recipeTitle: 'Parent Recipe',
};

describe('HashtaggedFeed - Clickable Hashtags', () => {
  beforeEach(() => {
    jest.clearAllMocks();
    (useRouter as jest.Mock).mockReturnValue({
      push: mockPush,
    });
  });

  it('renders hashtags as clickable buttons for recipe items', () => {
    render(<HashtaggedFeed items={[mockRecipeItem]} />);

    const hashtagButton = screen.getByRole('button', { name: '#cooking' });
    expect(hashtagButton).toBeInTheDocument();
  });

  it('renders hashtags as clickable buttons for log items', () => {
    render(<HashtaggedFeed items={[mockLogItem]} />);

    const hashtagButton = screen.getByRole('button', { name: '#delicious' });
    expect(hashtagButton).toBeInTheDocument();
  });

  it('navigates to hashtag page when clicked', () => {
    render(<HashtaggedFeed items={[mockRecipeItem]} />);

    const hashtagButton = screen.getByRole('button', { name: '#cooking' });
    fireEvent.click(hashtagButton);

    expect(mockPush).toHaveBeenCalledWith('/hashtags/cooking');
  });

  it('encodes special characters in hashtag navigation', () => {
    const itemWithSpecialHashtag = {
      ...mockRecipeItem,
      hashtags: ['Korean BBQ', 'test'],
    };
    render(<HashtaggedFeed items={[itemWithSpecialHashtag]} />);

    const hashtagButton = screen.getByRole('button', { name: '#Korean BBQ' });
    fireEvent.click(hashtagButton);

    expect(mockPush).toHaveBeenCalledWith('/hashtags/Korean%20BBQ');
  });

  it('stops propagation when hashtag is clicked', () => {
    render(<HashtaggedFeed items={[mockRecipeItem]} />);

    const hashtagButton = screen.getByRole('button', { name: '#cooking' });
    const clickEvent = new MouseEvent('click', { bubbles: true, cancelable: true });
    const stopPropagationSpy = jest.spyOn(clickEvent, 'stopPropagation');

    fireEvent(hashtagButton, clickEvent);

    expect(stopPropagationSpy).toHaveBeenCalled();
  });

  it('displays only first 3 hashtags', () => {
    const itemWithManyHashtags = {
      ...mockRecipeItem,
      hashtags: ['one', 'two', 'three', 'four', 'five'],
    };
    render(<HashtaggedFeed items={[itemWithManyHashtags]} />);

    expect(screen.getByRole('button', { name: '#one' })).toBeInTheDocument();
    expect(screen.getByRole('button', { name: '#two' })).toBeInTheDocument();
    expect(screen.getByRole('button', { name: '#three' })).toBeInTheDocument();
    expect(screen.queryByRole('button', { name: '#four' })).not.toBeInTheDocument();
    expect(screen.queryByRole('button', { name: '#five' })).not.toBeInTheDocument();
  });

  it('does not render hashtag section when hashtags array is empty', () => {
    const itemWithNoHashtags = {
      ...mockRecipeItem,
      hashtags: [],
    };
    render(<HashtaggedFeed items={[itemWithNoHashtags]} />);

    expect(screen.queryByRole('button', { name: /^#/ })).not.toBeInTheDocument();
  });

  it('renders card link to recipe detail page', () => {
    render(<HashtaggedFeed items={[mockRecipeItem]} />);

    const cardLink = screen.getByRole('link', { name: /Test Recipe/i });
    expect(cardLink).toHaveAttribute('href', '/recipes/recipe-123');
  });

  it('renders card link to log detail page', () => {
    render(<HashtaggedFeed items={[mockLogItem]} />);

    const cardLink = screen.getByRole('link', { name: /Test Log/i });
    expect(cardLink).toHaveAttribute('href', '/logs/log-123');
  });

  it('shows empty message when items array is empty', () => {
    render(<HashtaggedFeed items={[]} />);

    expect(screen.getByText('No content found')).toBeInTheDocument();
  });
});
