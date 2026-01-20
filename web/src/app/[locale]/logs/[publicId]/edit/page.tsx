'use client';

import { useState, useEffect } from 'react';
import { useRouter, useParams } from 'next/navigation';
import Link from 'next/link';
import Image from 'next/image';
import { useTranslations } from 'next-intl';
import { useAuth } from '@/contexts/AuthContext';
import { getLogDetail, updateLog } from '@/lib/api/logs';
import { getImageUrl } from '@/lib/utils/image';
import { LoadingSpinner } from '@/components/common/LoadingSpinner';
import { StarRatingSelector } from '@/components/log/StarRating';
import type { LogPostDetail, Rating } from '@/lib/types';

const MAX_HASHTAGS = 10;
const MAX_HASHTAG_LENGTH = 30;

export default function LogEditPage() {
  const { publicId } = useParams<{ publicId: string }>();
  const router = useRouter();
  const { isAuthenticated, isLoading: authLoading, user } = useAuth();
  const t = useTranslations('logEdit');
  const tCommon = useTranslations('common');
  const tNav = useTranslations('nav');

  const [log, setLog] = useState<LogPostDetail | null>(null);
  const [isLoading, setIsLoading] = useState(true);
  const [isSaving, setIsSaving] = useState(false);
  const [error, setError] = useState<string | null>(null);

  // Form state
  const [content, setContent] = useState('');
  const [rating, setRating] = useState<number>(3);
  const [hashtags, setHashtags] = useState('');

  // Load log data
  useEffect(() => {
    async function loadLog() {
      if (!publicId) return;

      try {
        const logData = await getLogDetail(publicId);
        setLog(logData);

        // Initialize form state
        setContent(logData.content);
        setRating(logData.rating ?? 3);
        setHashtags(logData.hashtags.map((h) => h.name).join(', '));
      } catch (err) {
        console.error('Failed to load log:', err);
        setError(t('errorLoad'));
      } finally {
        setIsLoading(false);
      }
    }

    loadLog();
  }, [publicId, t]);

  // Redirect if not authenticated
  useEffect(() => {
    if (!authLoading && !isAuthenticated) {
      router.push(`/login?redirect=/logs/${publicId}/edit`);
    }
  }, [authLoading, isAuthenticated, publicId, router]);

  // Check ownership
  useEffect(() => {
    if (!authLoading && isAuthenticated && log && user) {
      if (user.publicId !== log.creatorPublicId) {
        setError(t('errorNotOwner'));
      }
    }
  }, [authLoading, isAuthenticated, log, user, t]);

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();

    if (!content.trim()) {
      setError(t('errorContent'));
      return;
    }

    setIsSaving(true);
    setError(null);

    try {
      const hashtagList = hashtags
        .split(',')
        .map((h) => h.trim().replace(/^#/, ''))
        .filter((h) => h.length > 0)
        .slice(0, MAX_HASHTAGS)
        .map((h) => h.slice(0, MAX_HASHTAG_LENGTH));

      await updateLog(publicId!, {
        content: content.trim(),
        rating: rating as Rating,
        hashtags: hashtagList,
      });

      router.push(`/logs/${publicId}`);
      router.refresh();
    } catch (err) {
      console.error('Failed to update log:', err);
      setError(t('errorSave'));
    } finally {
      setIsSaving(false);
    }
  };

  if (authLoading || isLoading) {
    return <LoadingSpinner />;
  }

  // Show error state if cannot edit
  if (error && !log) {
    return (
      <main className="min-h-screen bg-[var(--background)]">
        <div className="max-w-2xl mx-auto px-4 py-16 text-center">
          <div className="mb-8">
            <span className="text-6xl">🔒</span>
          </div>
          <h1 className="text-2xl font-bold text-[var(--text-primary)] mb-4">
            {t('cannotEdit')}
          </h1>
          <p className="text-[var(--text-secondary)] mb-8">{error}</p>
          <Link
            href={`/logs/${publicId}`}
            className="px-6 py-3 bg-[var(--primary)] text-white rounded-xl font-medium hover:bg-[var(--primary-dark)] transition-colors"
          >
            {t('backToLog')}
          </Link>
        </div>
      </main>
    );
  }

  // Show ownership error
  if (error === t('errorNotOwner')) {
    return (
      <main className="min-h-screen bg-[var(--background)]">
        <div className="max-w-2xl mx-auto px-4 py-16 text-center">
          <div className="mb-8">
            <span className="text-6xl">🔒</span>
          </div>
          <h1 className="text-2xl font-bold text-[var(--text-primary)] mb-4">
            {t('cannotEdit')}
          </h1>
          <p className="text-[var(--text-secondary)] mb-8">{t('errorNotOwner')}</p>
          <Link
            href={`/logs/${publicId}`}
            className="px-6 py-3 bg-[var(--primary)] text-white rounded-xl font-medium hover:bg-[var(--primary-dark)] transition-colors"
          >
            {t('backToLog')}
          </Link>
        </div>
      </main>
    );
  }

  if (!log) {
    return <LoadingSpinner />;
  }

  return (
    <main className="min-h-screen bg-[var(--background)]">
      <div className="max-w-2xl mx-auto px-4 py-8">
        {/* Header */}
        <div className="mb-8">
          <Link
            href={`/logs/${publicId}`}
            className="text-sm text-[var(--text-secondary)] hover:text-[var(--primary)] mb-2 inline-block"
          >
            ← {t('backToLog')}
          </Link>
          <h1 className="text-2xl font-bold text-[var(--text-primary)]">{t('title')}</h1>
        </div>

        <form onSubmit={handleSubmit} className="space-y-8">
          {/* Photos Section (read-only) */}
          {log.images.length > 0 && (
            <section className="bg-[var(--surface)] border border-[var(--border)] rounded-2xl p-6">
              <div className="flex items-center gap-2 mb-4">
                <h2 className="text-lg font-semibold text-[var(--text-primary)]">
                  {t('photosReadOnly')}
                </h2>
                <svg className="w-4 h-4 text-[var(--text-secondary)]" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                  <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M12 15v2m-6 4h12a2 2 0 002-2v-6a2 2 0 00-2-2H6a2 2 0 00-2 2v6a2 2 0 002 2zm10-10V7a4 4 0 00-8 0v4h8z" />
                </svg>
              </div>
              <div className="flex gap-3 overflow-x-auto pb-2">
                {log.images.map((img) => (
                  <div
                    key={img.imagePublicId}
                    className="relative w-24 h-24 flex-shrink-0 rounded-xl overflow-hidden bg-[var(--background)]"
                  >
                    <Image
                      src={getImageUrl(img.imageUrl) || ''}
                      alt="Log photo"
                      fill
                      className="object-cover opacity-75"
                      sizes="96px"
                    />
                    <div className="absolute inset-0 flex items-center justify-center">
                      <svg className="w-6 h-6 text-white/60" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                        <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M12 15v2m-6 4h12a2 2 0 002-2v-6a2 2 0 00-2-2H6a2 2 0 00-2 2v6a2 2 0 002 2zm10-10V7a4 4 0 00-8 0v4h8z" />
                      </svg>
                    </div>
                  </div>
                ))}
              </div>
            </section>
          )}

          {/* Rating Section */}
          <section className="bg-[var(--surface)] border border-[var(--border)] rounded-2xl p-6">
            <h2 className="text-lg font-semibold text-[var(--text-primary)] mb-4">
              {t('rating')}
            </h2>
            <div className="flex justify-center">
              <StarRatingSelector
                value={rating}
                onChange={setRating}
                size="lg"
              />
            </div>
            <p className="text-center text-sm text-[var(--text-secondary)] mt-3">
              {rating === 5 && t('ratingExcellent')}
              {rating === 4 && t('ratingGreat')}
              {rating === 3 && t('ratingGood')}
              {rating === 2 && t('ratingFair')}
              {rating === 1 && t('ratingPoor')}
            </p>
          </section>

          {/* Content Section */}
          <section className="bg-[var(--surface)] border border-[var(--border)] rounded-2xl p-6">
            <h2 className="text-lg font-semibold text-[var(--text-primary)] mb-4">
              {t('notes')} <span className="text-[var(--error)]">*</span>
            </h2>
            <textarea
              id="content"
              value={content}
              onChange={(e) => setContent(e.target.value)}
              rows={8}
              className="w-full px-4 py-3 bg-[var(--background)] border border-[var(--border)] rounded-xl focus:outline-none focus:border-[var(--primary)] resize-none"
              placeholder={t('notesPlaceholder')}
            />
          </section>

          {/* Hashtags Section */}
          <section className="bg-[var(--surface)] border border-[var(--border)] rounded-2xl p-6">
            <div className="flex items-center justify-between mb-4">
              <h2 className="text-lg font-semibold text-[var(--text-primary)]">
                {t('hashtags')}
              </h2>
              <span className="text-xs text-[var(--text-secondary)]">
                {t('hashtagsHelp')}
              </span>
            </div>
            <input
              id="hashtags"
              type="text"
              value={hashtags}
              onChange={(e) => setHashtags(e.target.value)}
              className="w-full px-4 py-3 bg-[var(--background)] border border-[var(--border)] rounded-xl focus:outline-none focus:border-[var(--primary)]"
              placeholder={t('hashtagsPlaceholder')}
            />
          </section>

          {/* Error */}
          {error && error !== t('errorNotOwner') && (
            <div className="p-4 bg-[var(--error)]/10 border border-[var(--error)]/20 text-[var(--error)] rounded-xl">
              {error}
            </div>
          )}

          {/* Actions */}
          <div className="flex gap-4 justify-end">
            <Link
              href={`/logs/${publicId}`}
              className="px-6 py-3 text-sm font-medium text-[var(--text-primary)] hover:bg-[var(--surface)] rounded-xl transition-colors"
            >
              {tCommon('cancel')}
            </Link>
            <button
              type="submit"
              disabled={isSaving || !content.trim()}
              className="px-8 py-3 text-sm font-medium text-white bg-[var(--primary)] hover:bg-[var(--primary-dark)] rounded-xl transition-colors disabled:opacity-50 flex items-center gap-2"
            >
              {isSaving ? (
                <>
                  <svg className="animate-spin w-4 h-4" fill="none" viewBox="0 0 24 24">
                    <circle className="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" strokeWidth="4" />
                    <path className="opacity-75" fill="currentColor" d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4z" />
                  </svg>
                  {t('saving')}
                </>
              ) : (
                t('saveChanges')
              )}
            </button>
          </div>
        </form>
      </div>
    </main>
  );
}
