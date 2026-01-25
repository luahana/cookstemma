'use client';

import { useState, useCallback } from 'react';
import { useTranslations } from 'next-intl';
import { useAuth } from '@/contexts/AuthContext';
import { ActionMenu, ActionMenuIcons } from '@/components/shared/ActionMenu';
import { BlockConfirmDialog } from '@/components/shared/BlockConfirmDialog';
import { ReportModal } from '@/components/shared/ReportModal';
import {
  blockUser,
  getBlockStatus,
  reportUser,
  type ReportReason,
} from '@/lib/api/moderation';

type ContentType = 'recipe' | 'log';

interface ContentActionsProps {
  contentType: ContentType;
  contentTitle: string;
  authorPublicId: string | null;
  authorName: string | null;
}

export function ContentActions({
  contentType,
  contentTitle,
  authorPublicId,
  authorName,
}: ContentActionsProps) {
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
    if (isBlocked !== null || !authorPublicId) return;
    try {
      const status = await getBlockStatus(authorPublicId);
      setIsBlocked(status.isBlocked);
    } catch (err) {
      console.error('Failed to check block status:', err);
    }
  }, [authorPublicId, isBlocked]);

  // Don't render if viewing own content, not authenticated, or no author
  const isOwnContent = user?.publicId === authorPublicId;
  if (isOwnContent || !isAuthenticated || !authorPublicId) {
    return null;
  }

  const handleBlockConfirm = async () => {
    if (!authorPublicId) return;
    setIsBlocking(true);
    try {
      await blockUser(authorPublicId);
      setIsBlocked(true);
      setToast({
        type: 'success',
        message: t('blockSuccess', { username: authorName || 'User' }),
      });
    } catch (err) {
      console.error('Failed to block user:', err);
      setToast({ type: 'error', message: t('blockFailed') });
    } finally {
      setIsBlocking(false);
      setShowBlockDialog(false);
    }
  };

  const handleReportSubmit = async (
    reason: ReportReason,
    description?: string,
  ) => {
    if (!authorPublicId) return;
    setIsReporting(true);
    try {
      // Report the author (the API reports the user, not the content itself)
      await reportUser(authorPublicId, reason, description);
      setToast({ type: 'success', message: t('reportSuccess') });
    } catch (err) {
      console.error('Failed to report:', err);
      setToast({ type: 'error', message: t('reportFailed') });
    } finally {
      setIsReporting(false);
      setShowReportModal(false);
    }
  };

  const reportLabel =
    contentType === 'recipe' ? t('reportRecipe') : t('reportLog');

  const menuItems = [
    {
      label: reportLabel,
      onClick: () => setShowReportModal(true),
      icon: ActionMenuIcons.report,
      isDestructive: true,
    },
    {
      label: t('blockAuthor'),
      onClick: () => setShowBlockDialog(true),
      icon: ActionMenuIcons.block,
      isDestructive: true,
      disabled: isBlocked === true,
      tooltip: isBlocked ? t('alreadyBlocked') : undefined,
    },
  ];

  return (
    <>
      <div onMouseEnter={checkBlockStatus}>
        <ActionMenu items={menuItems} />
      </div>

      <BlockConfirmDialog
        isOpen={showBlockDialog}
        username={authorName || 'this user'}
        onConfirm={handleBlockConfirm}
        onCancel={() => setShowBlockDialog(false)}
        isBlocking={isBlocking}
      />

      <ReportModal
        isOpen={showReportModal}
        targetName={contentTitle}
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
