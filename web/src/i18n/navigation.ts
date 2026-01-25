import { createNavigation } from 'next-intl/navigation';
import { routing } from './routing';

const navigation = createNavigation(routing);

// Keep original exports
export const { redirect, usePathname, useRouter, getPathname } = navigation;

// Export enhanced Link with progress support
export { NavigationLink as Link } from '@/components/common/NavigationLink';
