'use client';

// Yellow color for filled stars
const STAR_YELLOW = '#facc15';
const STAR_GRAY = '#d1d5db';

interface StarRatingProps {
  rating: number | null;
  size?: 'sm' | 'md' | 'lg';
  showLabel?: boolean;
}

/**
 * Star icon SVG component
 */
function StarIcon({ size, filled, color }: { size: number; filled: boolean; color: string }) {
  return (
    <svg
      width={size}
      height={size}
      viewBox="0 0 24 24"
      fill={filled ? 'currentColor' : 'none'}
      stroke="currentColor"
      strokeWidth="2"
      strokeLinecap="round"
      strokeLinejoin="round"
      style={{ color }}
    >
      <polygon points="12 2 15.09 8.26 22 9.27 17 14.14 18.18 21.02 12 17.77 5.82 21.02 7 14.14 2 9.27 8.91 8.26 12 2" />
    </svg>
  );
}

/**
 * Display component for 1-5 star rating
 * Replaces OutcomeBadge
 */
export function StarRating({ rating, size = 'md', showLabel = false }: StarRatingProps) {
  if (rating === null) return null;

  const iconSizes = {
    sm: 14,
    md: 18,
    lg: 24,
  };

  const iconSize = iconSizes[size];

  return (
    <span className="inline-flex items-center gap-0.5">
      {[1, 2, 3, 4, 5].map((star) => (
        <StarIcon
          key={star}
          size={iconSize}
          filled={star <= rating}
          color={star <= rating ? STAR_YELLOW : STAR_GRAY}
        />
      ))}
      {showLabel && (
        <span className="ml-1 text-sm text-muted-foreground">{rating}/5</span>
      )}
    </span>
  );
}

interface StarRatingSelectorProps {
  value: number | null;
  onChange: (rating: number) => void;
  size?: 'sm' | 'md' | 'lg';
}

/**
 * Interactive star rating selector for forms
 */
export function StarRatingSelector({ value, onChange, size = 'md' }: StarRatingSelectorProps) {
  const iconSizes = {
    sm: 24,
    md: 32,
    lg: 40,
  };

  const iconSize = iconSizes[size];

  return (
    <div className="inline-flex items-center gap-1">
      {[1, 2, 3, 4, 5].map((star) => {
        const isFilled = value !== null && star <= value;
        return (
          <button
            key={star}
            type="button"
            onClick={() => onChange(star)}
            className="transition-transform hover:scale-110 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-primary rounded"
            aria-label={`Rate ${star} star${star > 1 ? 's' : ''}`}
          >
            <StarIcon
              size={iconSize}
              filled={isFilled}
              color={isFilled ? '#facc15' : '#d1d5db'}
            />
          </button>
        );
      })}
    </div>
  );
}
