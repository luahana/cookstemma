import '@testing-library/jest-dom';

// Mock next/navigation
jest.mock('next/navigation', () => ({
  useRouter: () => ({
    push: jest.fn(),
    replace: jest.fn(),
    prefetch: jest.fn(),
    back: jest.fn(),
  }),
  useSearchParams: () => ({
    get: jest.fn(),
  }),
  usePathname: () => '/',
}));

// Mock js-cookie
jest.mock('js-cookie', () => ({
  get: jest.fn(),
  set: jest.fn(),
  remove: jest.fn(),
}));

// Mock fetch globally
global.fetch = jest.fn();

// Mock @/i18n/routing (prevents ESM import of next-intl/routing)
jest.mock('@/i18n/routing', () => ({
  routing: {
    locales: ['en', 'ko'],
    defaultLocale: 'en',
  },
  isRtlLocale: () => false,
  rtlLocales: [],
}));

// Reset mocks before each test
beforeEach(() => {
  jest.clearAllMocks();
});
