'use client';

import { LogActions } from './LogActions';
import type { LogPostDetail } from '@/lib/types';

interface LogDetailClientProps {
  log: LogPostDetail;
}

export function LogDetailClient({ log }: LogDetailClientProps) {
  return <LogActions log={log} />;
}
