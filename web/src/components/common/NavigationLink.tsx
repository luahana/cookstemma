'use client';

import { forwardRef, useCallback, type MouseEvent, type ComponentProps } from 'react';
import { usePathname } from 'next/navigation';
import { createNavigation } from 'next-intl/navigation';
import { routing } from '@/i18n/routing';
import { useNavigationProgress } from '@/contexts/NavigationProgressContext';

const { Link: I18nLink } = createNavigation(routing);

type LinkProps = ComponentProps<typeof I18nLink>;

export const NavigationLink = forwardRef<HTMLAnchorElement, LinkProps>(
  function NavigationLink({ onClick, href, target, ...props }, ref) {
    const { startLoading } = useNavigationProgress();
    const pathname = usePathname();

    const handleClick = useCallback(
      (e: MouseEvent<HTMLAnchorElement>) => {
        // Call original onClick if provided
        onClick?.(e);

        // Don't trigger progress for:
        // 1. Default prevented (e.g., by onClick handler)
        // 2. Modified clicks (cmd/ctrl + click for new tab)
        // 3. External links (target="_blank")
        // 4. Same-page anchors
        if (
          e.defaultPrevented ||
          e.metaKey ||
          e.ctrlKey ||
          e.shiftKey ||
          target === '_blank' ||
          (typeof href === 'string' && href.startsWith('#'))
        ) {
          return;
        }

        // Skip loading indicator if clicking same route (route won't change)
        const targetPath = typeof href === 'string' ? href : href?.pathname;
        if (targetPath && (pathname === targetPath || pathname.endsWith(targetPath))) {
          return;
        }

        startLoading();
      },
      [onClick, startLoading, target, href, pathname]
    );

    return (
      <I18nLink
        ref={ref}
        href={href}
        target={target}
        onClick={handleClick}
        {...props}
      />
    );
  }
);
