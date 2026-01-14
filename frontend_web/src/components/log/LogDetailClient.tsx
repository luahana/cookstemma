'use client';

import { useState } from 'react';
import { useRouter } from 'next/navigation';
import { LogActions } from './LogActions';
import { LogEditModal } from './LogEditModal';
import type { LogPostDetail } from '@/lib/types';

interface LogDetailClientProps {
  log: LogPostDetail;
}

export function LogDetailClient({ log }: LogDetailClientProps) {
  const [isEditModalOpen, setIsEditModalOpen] = useState(false);
  const [currentLog, setCurrentLog] = useState(log);
  const router = useRouter();

  const handleEditSuccess = (updatedLog: LogPostDetail) => {
    setCurrentLog(updatedLog);
    setIsEditModalOpen(false);
    router.refresh(); // Refresh server data
  };

  return (
    <>
      <LogActions
        log={currentLog}
        onEditClick={() => setIsEditModalOpen(true)}
      />

      <LogEditModal
        log={currentLog}
        isOpen={isEditModalOpen}
        onClose={() => setIsEditModalOpen(false)}
        onSuccess={handleEditSuccess}
      />
    </>
  );
}
