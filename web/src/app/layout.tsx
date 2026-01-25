import type { ReactNode } from 'react';

type Props = {
  children: ReactNode;
};

// Since this file doesn't have dynamic behavior, we can
// mark it as static. This allows Next.js to pre-render
// the layout shell for improved performance.
export default function RootLayout({ children }: Props) {
  return children;
}
