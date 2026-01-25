'use client';

import { useEffect, useRef } from 'react';
import { useTranslations } from 'next-intl';

interface BlockConfirmDialogProps {
  isOpen: boolean;
  username: string;
  onConfirm: () => void;
  onCancel: () => void;
  isBlocking?: boolean;
}

export function BlockConfirmDialog({
  isOpen,
  username,
  onConfirm,
  onCancel,
  isBlocking = false,
}: BlockConfirmDialogProps) {
  const dialogRef = useRef<HTMLDialogElement>(null);
  const t = useTranslations('moderation');
  const tCommon = useTranslations('common');

  useEffect(() => {
    const dialog = dialogRef.current;
    if (!dialog) return;

    if (isOpen) {
      dialog.showModal();
    } else {
      dialog.close();
    }
  }, [isOpen]);

  const handleBackdropClick = (e: React.MouseEvent<HTMLDialogElement>) => {
    if (e.target === dialogRef.current && !isBlocking) {
      onCancel();
    }
  };

  useEffect(() => {
    const handleKeyDown = (e: KeyboardEvent) => {
      if (e.key === 'Escape' && isOpen && !isBlocking) {
        onCancel();
      }
    };
    document.addEventListener('keydown', handleKeyDown);
    return () => document.removeEventListener('keydown', handleKeyDown);
  }, [isOpen, isBlocking, onCancel]);

  if (!isOpen) return null;

  return (
    <dialog
      ref={dialogRef}
      onClick={handleBackdropClick}
      className="fixed inset-0 z-50 bg-transparent p-4 backdrop:bg-black/50"
    >
      <div className="bg-[var(--surface)] rounded-2xl p-6 max-w-sm w-full mx-auto shadow-xl border border-[var(--border)]">
        <h2 className="text-lg font-semibold text-[var(--text-primary)] mb-2">
          {t('blockConfirmTitle', { username })}
        </h2>
        <p className="text-[var(--text-secondary)] mb-6">
          {t('blockConfirmMessage')}
        </p>
        <div className="flex gap-3 justify-end">
          <button
            onClick={onCancel}
            disabled={isBlocking}
            className="px-4 py-2 text-sm font-medium text-[var(--text-primary)] hover:bg-[var(--background)] rounded-lg transition-colors disabled:opacity-50"
          >
            {tCommon('cancel')}
          </button>
          <button
            onClick={onConfirm}
            disabled={isBlocking}
            className="px-4 py-2 text-sm font-medium text-white bg-[var(--error)] hover:bg-red-600 rounded-lg transition-colors disabled:opacity-50 flex items-center gap-2"
          >
            {isBlocking ? (
              <>
                <svg
                  className="animate-spin w-4 h-4"
                  fill="none"
                  viewBox="0 0 24 24"
                >
                  <circle
                    className="opacity-25"
                    cx="12"
                    cy="12"
                    r="10"
                    stroke="currentColor"
                    strokeWidth="4"
                  />
                  <path
                    className="opacity-75"
                    fill="currentColor"
                    d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4z"
                  />
                </svg>
                {t('blocking')}
              </>
            ) : (
              t('block')
            )}
          </button>
        </div>
      </div>
    </dialog>
  );
}
