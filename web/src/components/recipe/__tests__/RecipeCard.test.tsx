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
      recipes: {
        servingsCount: `${args?.count || 0} servings`,
      },
      common: {},
      card: {
        variant: 'Variant',
        recipe: 'Recipe',
        private: 'Private',
      },
      filters: {
        under30: 'Under 30 min',
        '30to60': '30-60 min',
        over60: 'Over 60 min',
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

// Mock BookmarkButton
jest.mock('@/components/common/BookmarkButton', () => ({
  BookmarkButton: () => <button data-testid="bookmark-button">Bookmark</button>,
}));

// Mock CookingStyleBadge
jest.mock('@/components/common/CookingStyleBadge', () => ({
  CookingStyleBadge: ({ localeCode }: { localeCode: string }) => (
    <span data-testid="cooking-style-badge">{localeCode}</span>
  ),
}));

// Mock image utility
jest.mock('@/lib/utils/image', () => ({
  getImageUrl: (url: string | null) => url,
}));

import { RecipeCard } from '../RecipeCard';
import type { RecipeSummary } from '@/lib/types';

const mockPush = jest.fn();

const mockRecipe: RecipeSummary = {
  publicId: 'test-recipe-123',
  title: 'Test Recipe',
  description: 'Test description',
  foodPublicId: 'food-123',
  foodName: 'Test Food',
  thumbnail: 'https://example.com/image.jpg',
  cookingTimeRange: 'UNDER_30',
  servings: 4,
  cookingStyle: 'Korean',
  creatorPublicId: 'creator-123',
  userName: 'TestUser',
  hashtags: ['cooking', 'test', 'food'],
  rootPublicId: null,
  isPrivate: false,
  variantCount: 0,
  logCount: 0,
};

describe('RecipeCard - Clickable Hashtags', () => {
  beforeEach(() => {
    jest.clearAllMocks();
    (useRouter as jest.Mock).mockReturnValue({
      push: mockPush,
    });
  });

  it('renders hashtags as clickable buttons', () => {
    render(<RecipeCard recipe={mockRecipe} />);

    const hashtagButton = screen.getByRole('button', { name: '#cooking' });
    expect(hashtagButton).toBeInTheDocument();
  });

  it('navigates to hashtag page when clicked', () => {
    render(<RecipeCard recipe={mockRecipe} />);

    const hashtagButton = screen.getByRole('button', { name: '#cooking' });
    fireEvent.click(hashtagButton);

    expect(mockPush).toHaveBeenCalledWith('/hashtags/cooking');
  });

  it('encodes special characters in hashtag navigation', () => {
    const recipeWithSpecialHashtag = {
      ...mockRecipe,
      hashtags: ['Korean BBQ', 'test'],
    };
    render(<RecipeCard recipe={recipeWithSpecialHashtag} />);

    const hashtagButton = screen.getByRole('button', { name: '#Korean BBQ' });
    fireEvent.click(hashtagButton);

    expect(mockPush).toHaveBeenCalledWith('/hashtags/Korean%20BBQ');
  });

  it('stops propagation when hashtag is clicked', () => {
    render(<RecipeCard recipe={mockRecipe} />);

    const hashtagButton = screen.getByRole('button', { name: '#cooking' });
    const clickEvent = new MouseEvent('click', { bubbles: true, cancelable: true });
    const stopPropagationSpy = jest.spyOn(clickEvent, 'stopPropagation');

    fireEvent(hashtagButton, clickEvent);

    expect(stopPropagationSpy).toHaveBeenCalled();
  });

  it('displays only first 3 hashtags', () => {
    const recipeWithManyHashtags = {
      ...mockRecipe,
      hashtags: ['one', 'two', 'three', 'four', 'five'],
    };
    render(<RecipeCard recipe={recipeWithManyHashtags} />);

    expect(screen.getByRole('button', { name: '#one' })).toBeInTheDocument();
    expect(screen.getByRole('button', { name: '#two' })).toBeInTheDocument();
    expect(screen.getByRole('button', { name: '#three' })).toBeInTheDocument();
    expect(screen.queryByRole('button', { name: '#four' })).not.toBeInTheDocument();
    expect(screen.queryByRole('button', { name: '#five' })).not.toBeInTheDocument();
  });

  it('does not render hashtag section when hashtags array is empty', () => {
    const recipeWithNoHashtags = {
      ...mockRecipe,
      hashtags: [],
    };
    render(<RecipeCard recipe={recipeWithNoHashtags} />);

    expect(screen.queryByRole('button', { name: /^#/ })).not.toBeInTheDocument();
  });

  it('renders card link to recipe detail page', () => {
    render(<RecipeCard recipe={mockRecipe} />);

    const cardLink = screen.getByRole('link', { name: /Test Recipe/i });
    expect(cardLink).toHaveAttribute('href', '/recipes/test-recipe-123');
  });
});
