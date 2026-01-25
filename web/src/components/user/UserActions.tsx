'use client';

import { useState, useCallback } from 'react';
import { useTranslations } from 'next-intl';
import { useAuth } from '@/contexts/AuthContext';
import { ActionMenu, ActionMenuIcons } from '@/components/shared/ActionMenu';
import { BlockConfirmDialog } from '@/components/shared/BlockConfirmDialog';
import { ReportModal } from '@/components/shared/ReportModal';
import {
  blockUser,
  unblockUser,
  getBlockStatus,
  reportUser,
  type ReportReason,
} from '@/lib/api/moderation';

interface UserActionsProps {
  userPublicId: string;
  username: string;
}

export function UserActions({ userPublicId, username }: UserActionsProps) {
  const { user, isAuthenticated } = useAuth();
  const t = useTranslations('moderation');

  const [isBlocked, setIsBlocked] = useState<boolean | null>(null);
  const [showBlockDialog, setShowBlockDialog] = useState(false);
  const [showReportModal, setShowReportModal] = useState(false);
  const [isBlocking, setIsBlocking] = useState(false);
  const [isReporting, setIsReporting] = useState(false);
  const [toast, setToast] = useState<{
    type: 'success' | 'error';
    message: string;
  } | null>(null);

  // Fetch block status when menu opens
  const checkBlockStatus = useCallback(async () => {
    if (isBlocked !== null) return;
    try {
      const status = await getBlockStatus(userPublicId);
      setIsBlocked(status.isBlocked);
    } catch (err) {
      console.error('Failed to check block status:', err);
    }
  }, [userPublicId, isBlocked]);

  // Don't render if viewing own profile or not authenticated
  const isOwnProfile = user?.publicId === userPublicId;
  if (isOwnProfile || !isAuthenticated) {
    return null;
  }

  const handleBlockClick = () => {
    if (isBlocked) {
      handleUnblock();
    } else {
      setShowBlockDialog(true);
    }
  };

  const handleBlockConfirm = async () => {
    setIsBlocking(true);
    try {
      await blockUser(userPublicId);
      setIsBlocked(true);
      setToast({ type: 'success', message: t('blockSuccess', { username }) });
    } catch (err) {
      console.error('Failed to block user:', err);
      setToast({ type: 'error', message: t('blockFailed') });
    } finally {
      setIsBlocking(false);
      setShowBlockDialog(false);
    }
  };

  const handleUnblock = async () => {
    setIsBlocking(true);
    try {
      await unblockUser(userPublicId);
      setIsBlocked(false);
      setToast({ type: 'success', message: t('unblockSuccess', { username }) });
    } catch (err) {
      console.error('Failed to unblock user:', err);
      setToast({ type: 'error', message: t('unblockFailed') });
    } finally {
      setIsBlocking(false);
    }
  };

  const handleReportSubmit = async (
    reason: ReportReason,
    description?: string,
  ) => {
    setIsReporting(true);
    try {
      await reportUser(userPublicId, reason, description);
      setToast({ type: 'success', message: t('reportSuccess') });
    } catch (err) {
      console.error('Failed to report user:', err);
      setToast({ type: 'error', message: t('reportFailed') });
    } finally {
      setIsReporting(false);
      setShowReportModal(false);
    }
  };

  const menuItems = [
    {
      label: isBlocked ? t('unblock') : t('blockUser'),
      onClick: handleBlockClick,
      icon: ActionMenuIcons.block,
      isDestructive: !isBlocked,
    },
    {
      label: t('reportUser'),
      onClick: () => setShowReportModal(true),
      icon: ActionMenuIcons.report,
      isDestructive: true,
    },
  ];

  return (
    <>
      <div onMouseEnter={checkBlockStatus}>
        <ActionMenu items={menuItems} />
      </div>

      <BlockConfirmDialog
        isOpen={showBlockDialog}
        username={username}
        onConfirm={handleBlockConfirm}
        onCancel={() => setShowBlockDialog(false)}
        isBlocking={isBlocking}
      />

      <ReportModal
        isOpen={showReportModal}
        targetName={username}
        onSubmit={handleReportSubmit}
        onCancel={() => setShowReportModal(false)}
        isSubmitting={isReporting}
      />

      {/* Toast notification */}
      {toast && (
        <div
          className={`fixed bottom-4 right-4 z-50 px-4 py-3 rounded-lg shadow-lg max-w-sm animate-fade-in ${
            toast.type === 'success'
              ? 'bg-[var(--success)] text-white'
              : 'bg-[var(--error)] text-white'
          }`}
        >
          <div className="flex items-center gap-3">
            <span>{toast.message}</span>
            <button
              onClick={() => setToast(null)}
              className="text-white/80 hover:text-white"
            >
              <svg
                className="w-5 h-5"
                fill="none"
                stroke="currentColor"
                viewBox="0 0 24 24"
              >
                <path
                  strokeLinecap="round"
                  strokeLinejoin="round"
                  strokeWidth={2}
                  d="M6 18L18 6M6 6l12 12"
                />
              </svg>
            </button>
          </div>
        </div>
      )}
    </>
  );
}
