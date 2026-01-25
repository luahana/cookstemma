interface LoadingSpinnerProps {
  /** Full screen centered (default) or inline */
  fullScreen?: boolean;
  /** Size of the spinner: 'sm' | 'md' | 'lg' */
  size?: 'sm' | 'md' | 'lg';
}

export function LoadingSpinner({ fullScreen = true, size = 'md' }: LoadingSpinnerProps) {
  const sizeClasses = {
    sm: 'w-6 h-6',
    md: 'w-12 h-12',
    lg: 'w-16 h-16',
  };

  const spinner = (
    <div className="animate-pulse">
      <div className={`${sizeClasses[size]} rounded-full bg-[var(--primary-light)]`} />
    </div>
  );

  if (fullScreen) {
    return (
      <div className="min-h-screen flex items-center justify-center bg-[var(--background)]">
        {spinner}
      </div>
    );
  }

  return spinner;
}
