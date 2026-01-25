'use client';

import { useState, useCallback } from 'react';
import { useTranslations } from 'next-intl';
import { useAuth } from '@/contexts/AuthContext';

interface CommentInputProps {
  onSubmit: (content: string) => Promise<void>;
  placeholder?: string;
  buttonText?: string;
  autoFocus?: boolean;
  onCancel?: () => void;
  className?: string;
}

export function CommentInput({
  onSubmit,
  placeholder,
  buttonText,
  autoFocus = false,
  onCancel,
  className = '',
}: CommentInputProps) {
  const t = useTranslations('comments');
  const { isAuthenticated } = useAuth();
  const [content, setContent] = useState('');
  const [isSubmitting, setIsSubmitting] = useState(false);

  const handleSubmit = useCallback(
    async (e: React.FormEvent) => {
      e.preventDefault();
      if (!isAuthenticated || !content.trim() || isSubmitting) return;

      setIsSubmitting(true);
      try {
        await onSubmit(content.trim());
        setContent('');
      } catch (error) {
        console.error('Failed to submit comment:', error);
      } finally {
        setIsSubmitting(false);
      }
    },
    [isAuthenticated, content, isSubmitting, onSubmit],
  );

  if (!isAuthenticated) {
    return (
      <div className={`text-center py-4 text-[var(--text-secondary)] ${className}`}>
        {t('loginToComment')}
      </div>
    );
  }

  return (
    <form onSubmit={handleSubmit} className={`flex gap-2 ${className}`}>
      <input
        type="text"
        value={content}
        onChange={(e) => setContent(e.target.value)}
        placeholder={placeholder || t('placeholder')}
        disabled={isSubmitting}
        autoFocus={autoFocus}
        maxLength={1000}
        className="flex-1 px-3 py-2 rounded-lg border border-[var(--border)] bg-[var(--surface)] text-[var(--text-primary)] placeholder-[var(--text-secondary)] focus:outline-none focus:ring-2 focus:ring-[var(--primary)] disabled:opacity-50"
      />
      {onCancel && (
        <button
          type="button"
          onClick={onCancel}
          disabled={isSubmitting}
          className="px-3 py-2 rounded-lg text-sm font-medium text-[var(--text-secondary)] hover:bg-[var(--border)] transition-colors disabled:opacity-50"
        >
          {t('cancel')}
        </button>
      )}
      <button
        type="submit"
        disabled={isSubmitting || !content.trim()}
        className="px-4 py-2 bg-[var(--primary)] text-white rounded-lg font-medium hover:bg-[var(--primary-dark)] disabled:opacity-50 disabled:cursor-not-allowed transition-colors"
      >
        {isSubmitting ? t('posting') : buttonText || t('post')}
      </button>
    </form>
  );
}
