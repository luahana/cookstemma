'use client';

import { useState, useEffect, useRef } from 'react';
import Image from 'next/image';
import { updateLog } from '@/lib/api/logs';
import { getImageUrl } from '@/lib/utils/image';
import { StarRatingSelector } from './StarRating';
import type { LogPostDetail, Rating } from '@/lib/types';

interface LogEditModalProps {
  log: LogPostDetail;
  isOpen: boolean;
  onClose: () => void;
  onSuccess: (updatedLog: LogPostDetail) => void;
}

export function LogEditModal({
  log,
  isOpen,
  onClose,
  onSuccess,
}: LogEditModalProps) {
  const dialogRef = useRef<HTMLDialogElement>(null);
  const [content, setContent] = useState(log.content);
  const [rating, setRating] = useState<number>(log.rating ?? 3);
  const [hashtags, setHashtags] = useState(log.hashtags.map((h) => h.name).join(', '));
  const [isSaving, setIsSaving] = useState(false);
  const [error, setError] = useState<string | null>(null);

  // Reset form when log changes
  useEffect(() => {
    setContent(log.content);
    setRating(log.rating ?? 3);
    setHashtags(log.hashtags.map((h) => h.name).join(', '));
    setError(null);
  }, [log]);

  // Handle dialog open/close
  useEffect(() => {
    const dialog = dialogRef.current;
    if (!dialog) return;

    if (isOpen) {
      dialog.showModal();
    } else {
      dialog.close();
    }
  }, [isOpen]);

  // Handle escape key
  useEffect(() => {
    const handleKeyDown = (e: KeyboardEvent) => {
      if (e.key === 'Escape' && isOpen && !isSaving) {
        onClose();
      }
    };
    document.addEventListener('keydown', handleKeyDown);
    return () => document.removeEventListener('keydown', handleKeyDown);
  }, [isOpen, isSaving, onClose]);

  const handleBackdropClick = (e: React.MouseEvent<HTMLDialogElement>) => {
    if (e.target === dialogRef.current && !isSaving) {
      onClose();
    }
  };

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();

    if (!content.trim()) {
      setError('Content is required');
      return;
    }

    setIsSaving(true);
    setError(null);

    try {
      const hashtagList = hashtags
        .split(',')
        .map((h) => h.trim().replace(/^#/, ''))
        .filter((h) => h.length > 0);

      const updatedLog = await updateLog(log.publicId, {
        content: content.trim(),
        rating: rating as Rating,
        hashtags: hashtagList,
      });

      onSuccess(updatedLog);
    } catch (err) {
      console.error('Failed to update log:', err);
      setError('Failed to save changes. Please try again.');
    } finally {
      setIsSaving(false);
    }
  };

  if (!isOpen) return null;

  return (
    <dialog
      ref={dialogRef}
      onClick={handleBackdropClick}
      className="fixed inset-0 z-50 bg-transparent p-4 backdrop:bg-black/50"
    >
      <div className="bg-[var(--surface)] rounded-2xl max-w-2xl w-full mx-auto shadow-xl border border-[var(--border)] max-h-[90vh] overflow-hidden flex flex-col">
        {/* Header */}
        <div className="flex items-center justify-between p-6 border-b border-[var(--border)]">
          <h2 className="text-xl font-semibold text-[var(--text-primary)]">
            Edit Cooking Log
          </h2>
          <button
            onClick={onClose}
            disabled={isSaving}
            className="p-2 rounded-lg hover:bg-[var(--background)] transition-colors disabled:opacity-50"
          >
            <svg className="w-5 h-5 text-[var(--text-secondary)]" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M6 18L18 6M6 6l12 12" />
            </svg>
          </button>
        </div>

        {/* Form */}
        <form onSubmit={handleSubmit} className="flex-1 overflow-y-auto p-6">
          {/* Images (read-only) */}
          {log.images.length > 0 && (
            <div className="mb-6">
              <label className="block text-sm font-medium text-[var(--text-primary)] mb-2">
                Photos (cannot be changed)
              </label>
              <div className="flex gap-2 overflow-x-auto pb-2">
                {log.images.map((img) => (
                  <div
                    key={img.imagePublicId}
                    className="relative w-20 h-20 flex-shrink-0 rounded-lg overflow-hidden bg-[var(--background)]"
                  >
                    <Image
                      src={getImageUrl(img.imageUrl) || ''}
                      alt="Log photo"
                      fill
                      className="object-cover opacity-75"
                      sizes="80px"
                    />
                    <div className="absolute inset-0 flex items-center justify-center">
                      <svg className="w-6 h-6 text-white/60" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                        <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M12 15v2m-6 4h12a2 2 0 002-2v-6a2 2 0 00-2-2H6a2 2 0 00-2 2v6a2 2 0 002 2zm10-10V7a4 4 0 00-8 0v4h8z" />
                      </svg>
                    </div>
                  </div>
                ))}
              </div>
            </div>
          )}

          {/* Rating */}
          <div className="mb-6">
            <label className="block text-sm font-medium text-[var(--text-primary)] mb-3">
              Rating
            </label>
            <div className="flex justify-center">
              <StarRatingSelector
                value={rating}
                onChange={setRating}
                size="lg"
              />
            </div>
            <p className="text-center text-sm text-[var(--text-secondary)] mt-2">
              {rating === 5 && 'Excellent!'}
              {rating === 4 && 'Great'}
              {rating === 3 && 'Good'}
              {rating === 2 && 'Fair'}
              {rating === 1 && 'Poor'}
            </p>
          </div>

          {/* Content */}
          <div className="mb-6">
            <label
              htmlFor="content"
              className="block text-sm font-medium text-[var(--text-primary)] mb-2"
            >
              Notes
            </label>
            <textarea
              id="content"
              value={content}
              onChange={(e) => setContent(e.target.value)}
              rows={6}
              className="w-full px-4 py-3 bg-[var(--background)] border border-[var(--border)] rounded-xl focus:outline-none focus:border-[var(--primary)] resize-none"
              placeholder="How did it go? Any tips or observations?"
            />
          </div>

          {/* Hashtags */}
          <div className="mb-6">
            <label
              htmlFor="hashtags"
              className="block text-sm font-medium text-[var(--text-primary)] mb-2"
            >
              Hashtags
            </label>
            <input
              id="hashtags"
              type="text"
              value={hashtags}
              onChange={(e) => setHashtags(e.target.value)}
              className="w-full px-4 py-3 bg-[var(--background)] border border-[var(--border)] rounded-xl focus:outline-none focus:border-[var(--primary)]"
              placeholder="homecooking, weeknight, spicy (comma separated)"
            />
            <p className="text-xs text-[var(--text-secondary)] mt-1">
              Separate hashtags with commas
            </p>
          </div>

          {/* Error */}
          {error && (
            <div className="mb-6 p-3 bg-[var(--error)]/10 border border-[var(--error)]/20 text-[var(--error)] rounded-lg text-sm">
              {error}
            </div>
          )}
        </form>

        {/* Footer */}
        <div className="flex gap-3 justify-end p-6 border-t border-[var(--border)]">
          <button
            type="button"
            onClick={onClose}
            disabled={isSaving}
            className="px-6 py-2.5 text-sm font-medium text-[var(--text-primary)] hover:bg-[var(--background)] rounded-xl transition-colors disabled:opacity-50"
          >
            Cancel
          </button>
          <button
            type="submit"
            onClick={handleSubmit}
            disabled={isSaving || !content.trim()}
            className="px-6 py-2.5 text-sm font-medium text-white bg-[var(--primary)] hover:bg-[var(--primary-dark)] rounded-xl transition-colors disabled:opacity-50 flex items-center gap-2"
          >
            {isSaving ? (
              <>
                <svg className="animate-spin w-4 h-4" fill="none" viewBox="0 0 24 24">
                  <circle className="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" strokeWidth="4" />
                  <path className="opacity-75" fill="currentColor" d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4z" />
                </svg>
                Saving...
              </>
            ) : (
              'Save Changes'
            )}
          </button>
        </div>
      </div>
    </dialog>
  );
}
