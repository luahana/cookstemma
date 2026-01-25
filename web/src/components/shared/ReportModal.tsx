'use client';

import { useEffect, useRef, useState } from 'react';
import { useTranslations } from 'next-intl';
import type { ReportReason } from '@/lib/api/moderation';

const REPORT_REASONS: ReportReason[] = [
  'SPAM',
  'HARASSMENT',
  'INAPPROPRIATE_CONTENT',
  'IMPERSONATION',
  'OTHER',
];

interface ReportModalProps {
  isOpen: boolean;
  targetName: string;
  onSubmit: (reason: ReportReason, description?: string) => void;
  onCancel: () => void;
  isSubmitting?: boolean;
}

export function ReportModal({
  isOpen,
  targetName,
  onSubmit,
  onCancel,
  isSubmitting = false,
}: ReportModalProps) {
  const dialogRef = useRef<HTMLDialogElement>(null);
  const prevIsOpenRef = useRef(false);
  const t = useTranslations('moderation');
  const tCommon = useTranslations('common');
  const [selectedReason, setSelectedReason] = useState<ReportReason | null>(
    null,
  );
  const [description, setDescription] = useState('');

  useEffect(() => {
    const dialog = dialogRef.current;
    if (!dialog) return;

    if (isOpen) {
      // Reset state when opening (only on transition from closed to open)
      if (!prevIsOpenRef.current) {
        // eslint-disable-next-line react-hooks/set-state-in-effect
        setSelectedReason(null);
        // eslint-disable-next-line react-hooks/set-state-in-effect
        setDescription('');
      }
      prevIsOpenRef.current = true;
      dialog.showModal();
    } else {
      prevIsOpenRef.current = false;
      dialog.close();
    }
  }, [isOpen]);

  const handleBackdropClick = (e: React.MouseEvent<HTMLDialogElement>) => {
    if (e.target === dialogRef.current && !isSubmitting) {
      onCancel();
    }
  };

  useEffect(() => {
    const handleKeyDown = (e: KeyboardEvent) => {
      if (e.key === 'Escape' && isOpen && !isSubmitting) {
        onCancel();
      }
    };
    document.addEventListener('keydown', handleKeyDown);
    return () => document.removeEventListener('keydown', handleKeyDown);
  }, [isOpen, isSubmitting, onCancel]);

  const handleSubmit = () => {
    if (!selectedReason) return;
    onSubmit(selectedReason, description.trim() || undefined);
  };

  if (!isOpen) return null;

  return (
    <dialog
      ref={dialogRef}
      onClick={handleBackdropClick}
      className="fixed inset-0 z-50 bg-transparent p-4 backdrop:bg-black/50"
    >
      <div className="bg-[var(--surface)] rounded-2xl p-6 max-w-md w-full mx-auto shadow-xl border border-[var(--border)]">
        <h2 className="text-lg font-semibold text-[var(--text-primary)] mb-4">
          {t('reportTitle', { target: targetName })}
        </h2>

        <p className="text-sm text-[var(--text-secondary)] mb-4">
          {t('reportReasonLabel')}
        </p>

        <div className="space-y-2 mb-4">
          {REPORT_REASONS.map((reason) => (
            <label
              key={reason}
              className={`flex items-center gap-3 p-3 rounded-lg border cursor-pointer transition-colors ${
                selectedReason === reason
                  ? 'border-[var(--primary)] bg-[var(--primary-light)]'
                  : 'border-[var(--border)] hover:bg-[var(--background)]'
              }`}
            >
              <input
                type="radio"
                name="reportReason"
                value={reason}
                checked={selectedReason === reason}
                onChange={() => setSelectedReason(reason)}
                className="w-4 h-4 text-[var(--primary)]"
              />
              <span className="text-sm text-[var(--text-primary)]">
                {t(`reasons.${reason}`)}
              </span>
            </label>
          ))}
        </div>

        {selectedReason === 'OTHER' && (
          <textarea
            value={description}
            onChange={(e) => setDescription(e.target.value)}
            placeholder={t('descriptionPlaceholder')}
            maxLength={500}
            rows={3}
            className="w-full p-3 rounded-lg border border-[var(--border)] bg-[var(--background)] text-[var(--text-primary)] placeholder:text-[var(--text-secondary)] text-sm resize-none focus:outline-none focus:ring-2 focus:ring-[var(--primary)] mb-4"
          />
        )}

        <div className="flex gap-3 justify-end">
          <button
            onClick={onCancel}
            disabled={isSubmitting}
            className="px-4 py-2 text-sm font-medium text-[var(--text-primary)] hover:bg-[var(--background)] rounded-lg transition-colors disabled:opacity-50"
          >
            {tCommon('cancel')}
          </button>
          <button
            onClick={handleSubmit}
            disabled={isSubmitting || !selectedReason}
            className="px-4 py-2 text-sm font-medium text-white bg-[var(--error)] hover:bg-red-600 rounded-lg transition-colors disabled:opacity-50 flex items-center gap-2"
          >
            {isSubmitting ? (
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
                {t('submitting')}
              </>
            ) : (
              tCommon('submit')
            )}
          </button>
        </div>
      </div>
    </dialog>
  );
}
