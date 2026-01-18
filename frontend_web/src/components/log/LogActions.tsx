'use client';

import { useState } from 'react';
import { useRouter } from 'next/navigation';
import { useTranslations } from 'next-intl';
import { useAuth } from '@/contexts/AuthContext';
import { ActionMenu, ActionMenuIcons } from '@/components/shared/ActionMenu';
import { DeleteConfirmDialog } from '@/components/shared/DeleteConfirmDialog';
import { deleteLog } from '@/lib/api/logs';
import { getErrorMessage } from '@/lib/utils/errors';
import type { LogPostDetail } from '@/lib/types';

interface LogActionsProps {
  log: LogPostDetail;
  onEditClick: () => void;
}

export function LogActions({ log, onEditClick }: LogActionsProps) {
  const { user, isAuthenticated } = useAuth();
  const router = useRouter();
  const t = useTranslations('errors');
  const [showDeleteDialog, setShowDeleteDialog] = useState(false);
  const [isDeleting, setIsDeleting] = useState(false);
  const [error, setError] = useState<string | null>(null);

  // Check if user is the owner
  const isOwner = isAuthenticated && user?.publicId === log.creatorPublicId;

  // Don't render anything if not the owner
  if (!isOwner) {
    return null;
  }

  const handleDeleteConfirm = async () => {
    setIsDeleting(true);
    try {
      await deleteLog(log.publicId);
      router.push('/logs');
      router.refresh();
    } catch (err) {
      console.error('Failed to delete log:', err);
      setError(getErrorMessage(err));
    } finally {
      setIsDeleting(false);
      setShowDeleteDialog(false);
    }
  };

  const menuItems = [
    {
      label: 'Edit',
      onClick: onEditClick,
      icon: ActionMenuIcons.edit,
    },
    {
      label: 'Delete',
      onClick: () => setShowDeleteDialog(true),
      icon: ActionMenuIcons.delete,
      isDestructive: true,
    },
  ];

  return (
    <>
      <ActionMenu items={menuItems} />

      <DeleteConfirmDialog
        isOpen={showDeleteDialog}
        title="Delete Cooking Log"
        message={`Are you sure you want to delete "${log.title}"? This action cannot be undone.`}
        onConfirm={handleDeleteConfirm}
        onCancel={() => setShowDeleteDialog(false)}
        isDeleting={isDeleting}
      />

      {/* Error toast */}
      {error && (
        <div className="fixed bottom-4 right-4 z-50 bg-[var(--error)] text-white px-4 py-3 rounded-lg shadow-lg max-w-sm animate-fade-in">
          <div className="flex items-start gap-3">
            <svg className="w-5 h-5 flex-shrink-0 mt-0.5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M12 9v2m0 4h.01m-6.938 4h13.856c1.54 0 2.502-1.667 1.732-3L13.732 4c-.77-1.333-2.694-1.333-3.464 0L3.34 16c-.77 1.333.192 3 1.732 3z" />
            </svg>
            <div className="flex-1">
              <p className="font-medium">{t('title')}</p>
              <p className="text-sm opacity-90">{error}</p>
            </div>
            <button
              onClick={() => setError(null)}
              className="text-white/80 hover:text-white"
            >
              <svg className="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M6 18L18 6M6 6l12 12" />
              </svg>
            </button>
          </div>
        </div>
      )}
    </>
  );
}
