'use client';

import { useEffect, useState, useRef } from 'react';
import { usePathname, useSearchParams } from 'next/navigation';
import { useNavigationProgress } from '@/contexts/NavigationProgressContext';

export function NavigationProgress() {
  const { isLoading, stopLoading } = useNavigationProgress();
  const pathname = usePathname();
  const searchParams = useSearchParams();
  const [progress, setProgress] = useState(0);
  const [visible, setVisible] = useState(false);
  const timeoutsRef = useRef<NodeJS.Timeout[]>([]);

  // Stop loading when route changes (navigation completed)
  useEffect(() => {
    stopLoading();
  }, [pathname, searchParams, stopLoading]);

  useEffect(() => {
    // Clear previous timeouts
    timeoutsRef.current.forEach(clearTimeout);
    timeoutsRef.current = [];

    if (isLoading) {
      // Use setTimeout to avoid synchronous setState in effect
      timeoutsRef.current.push(
        setTimeout(() => {
          setVisible(true);
          setProgress(0);
        }, 0)
      );

      // Animate progress: fast at start, slow down as it approaches 90%
      const intervals = [
        { delay: 10, value: 30 },
        { delay: 50, value: 50 },
        { delay: 150, value: 70 },
        { delay: 300, value: 80 },
        { delay: 500, value: 85 },
        { delay: 1000, value: 90 },
      ];

      intervals.forEach(({ delay, value }) => {
        timeoutsRef.current.push(setTimeout(() => setProgress(value), delay));
      });
    } else if (visible) {
      // Complete the progress bar
      timeoutsRef.current.push(setTimeout(() => setProgress(100), 0));

      // Hide after animation completes
      timeoutsRef.current.push(
        setTimeout(() => {
          setVisible(false);
          setProgress(0);
        }, 300)
      );
    }

    return () => {
      timeoutsRef.current.forEach(clearTimeout);
      timeoutsRef.current = [];
    };
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
