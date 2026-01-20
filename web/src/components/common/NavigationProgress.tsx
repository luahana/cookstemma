'use client';

import { useEffect, useState } from 'react';
import { usePathname, useSearchParams } from 'next/navigation';
import { useNavigationProgress } from '@/contexts/NavigationProgressContext';

export function NavigationProgress() {
  const { isLoading, stopLoading } = useNavigationProgress();
  const pathname = usePathname();
  const searchParams = useSearchParams();

  // Stop loading when route changes (navigation completed)
  useEffect(() => {
    stopLoading();
  }, [pathname, searchParams, stopLoading]);
  const [progress, setProgress] = useState(0);
  const [visible, setVisible] = useState(false);

  useEffect(() => {
    if (isLoading) {
      setVisible(true);
      setProgress(0);

      // Animate progress: fast at start, slow down as it approaches 90%
      const intervals = [
        { delay: 0, value: 30 },
        { delay: 100, value: 50 },
        { delay: 300, value: 70 },
        { delay: 600, value: 80 },
        { delay: 1000, value: 85 },
        { delay: 2000, value: 90 },
      ];

      const timeouts: NodeJS.Timeout[] = [];

      intervals.forEach(({ delay, value }) => {
        const timeout = setTimeout(() => {
          setProgress(value);
        }, delay);
        timeouts.push(timeout);
      });

      return () => {
        timeouts.forEach(clearTimeout);
      };
    } else if (visible) {
      // Complete the progress bar
      setProgress(100);

      // Hide after animation completes
      const hideTimeout = setTimeout(() => {
        setVisible(false);
        setProgress(0);
      }, 300);

      return () => clearTimeout(hideTimeout);
    }
  }, [isLoading, visible]);

  if (!visible) return null;

  return (
    <div className="fixed top-0 left-0 right-0 z-[9999] h-1 bg-transparent pointer-events-none">
      <div
        className="h-full bg-[var(--primary)] transition-all duration-300 ease-out shadow-[0_0_10px_var(--primary),0_0_5px_var(--primary)]"
        style={{ width: `${progress}%` }}
      />
    </div>
  );
}
