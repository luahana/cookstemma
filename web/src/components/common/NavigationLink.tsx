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
        if (targetPath) {
          // Handle root path: /en, /ko etc. should match href="/"
          const isRootPath = targetPath === '/' && /^\/[a-z]{2}(\/)?$/.test(pathname);
          // Handle other paths: /en/recipes should match href="/recipes"
          const isSamePath = pathname === targetPath || pathname.endsWith(targetPath);
          if (isRootPath || isSamePath) {
            return;
          }
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
