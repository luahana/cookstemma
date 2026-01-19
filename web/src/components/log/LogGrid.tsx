'use client';

import { useTranslations } from 'next-intl';
import type { LogPostSummary } from '@/lib/types';
import { LogCard } from './LogCard';

interface LogGridProps {
  logs: LogPostSummary[];
  emptyMessage?: string;
}

export function LogGrid({
  logs,
  emptyMessage,
}: LogGridProps) {
  const t = useTranslations('logs');
  const finalEmptyMessage = emptyMessage ?? t('noLogs');
  if (logs.length === 0) {
    return (
      <div className="text-center py-12">
        <p className="text-[var(--text-secondary)]">{finalEmptyMessage}</p>
      </div>
    );
  }

  return (
    <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 gap-6">
      {logs.map((log) => (
        <LogCard key={log.publicId} log={log} />
      ))}
    </div>
  );
}
