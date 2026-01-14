import type { Outcome } from '@/lib/types';
import { OUTCOME_CONFIG } from '@/lib/types';

interface OutcomeBadgeProps {
  outcome: Outcome;
  size?: 'sm' | 'md' | 'lg';
}

export function OutcomeBadge({ outcome, size = 'md' }: OutcomeBadgeProps) {
  const config = OUTCOME_CONFIG[outcome];

  const sizeClasses = {
    sm: 'text-xs px-2 py-0.5',
    md: 'text-sm px-2.5 py-1',
    lg: 'text-base px-3 py-1.5',
  };

  return (
    <span
      className={`inline-flex items-center font-medium rounded-full ${sizeClasses[size]}`}
      style={{
        backgroundColor: config.bgColor,
        color: config.color,
      }}
    >
      {config.label}
    </span>
  );
}
