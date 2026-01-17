'use client';

import { useState, useRef, useCallback, useEffect, Suspense } from 'react';
import Image from 'next/image';
import Link from 'next/link';
import { useRouter, useSearchParams } from 'next/navigation';
import { useAuth } from '@/contexts/AuthContext';
import { createLog } from '@/lib/api/logs';
import { getRecipes, getRecipeDetail } from '@/lib/api/recipes';
import { uploadImage } from '@/lib/api/images';
import { getImageUrl } from '@/lib/utils/image';
import type { Outcome, RecipeSummary, RecipeDetail } from '@/lib/types';

const OUTCOME_OPTIONS: { value: Outcome; label: string; emoji: string }[] = [
  { value: 'SUCCESS', label: 'Success', emoji: '😊' },
  { value: 'PARTIAL', label: 'Partial', emoji: '😐' },
  { value: 'FAILED', label: 'Failed', emoji: '😢' },
];

interface UploadedImage {
  file: File;
  preview: string;
  publicId: string | null;
  uploading: boolean;
  error: string | null;
}

export default function CreateLogPage() {
  return (
    <Suspense fallback={
      <div className="min-h-screen flex items-center justify-center bg-[var(--background)]">
        <div className="animate-pulse">
          <div className="w-12 h-12 rounded-full bg-[var(--primary-light)]" />
        </div>
      </div>
    }>
      <CreateLogPageContent />
    </Suspense>
  );
}

function CreateLogPageContent() {
  const { isAuthenticated, isLoading: authLoading } = useAuth();
  const router = useRouter();
  const searchParams = useSearchParams();
  const fileInputRef = useRef<HTMLInputElement>(null);

  // Form state
  const [selectedRecipe, setSelectedRecipe] = useState<RecipeDetail | null>(null);
  const [content, setContent] = useState('');
  const [outcome, setOutcome] = useState<Outcome>('SUCCESS');
  const [hashtags, setHashtags] = useState('');
  const [images, setImages] = useState<UploadedImage[]>([]);

  // UI state
  const [isSubmitting, setIsSubmitting] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [showRecipeSearch, setShowRecipeSearch] = useState(false);
  const [recipeSearchQuery, setRecipeSearchQuery] = useState('');
  const [searchResults, setSearchResults] = useState<RecipeSummary[]>([]);
  const [isSearching, setIsSearching] = useState(false);

  // Load recipe from URL parameter if provided
  useEffect(() => {
    const recipeId = searchParams.get('recipeId');
    if (recipeId && !selectedRecipe) {
      getRecipeDetail(recipeId)
        .then(setSelectedRecipe)
        .catch(console.error);
    }
  }, [searchParams, selectedRecipe]);

  // Redirect if not authenticated
  useEffect(() => {
    if (!authLoading && !isAuthenticated) {
      router.push('/login?redirect=/logs/create');
    }
  }, [isAuthenticated, authLoading, router]);

  // Search recipes
  const searchRecipes = useCallback(async (query: string) => {
    if (query.length < 2) {
      setSearchResults([]);
      return;
    }

    setIsSearching(true);
    try {
      const result = await getRecipes({ q: query, size: 10 });
      setSearchResults(result.content);
    } catch {
      console.error('Failed to search recipes');
    } finally {
      setIsSearching(false);
    }
  }, []);

  // Debounced recipe search
  useEffect(() => {
    const timer = setTimeout(() => {
      if (recipeSearchQuery) {
        searchRecipes(recipeSearchQuery);
      }
    }, 300);
    return () => clearTimeout(timer);
  }, [recipeSearchQuery, searchRecipes]);

  // Handle recipe selection
  const handleSelectRecipe = async (recipe: RecipeSummary) => {
    try {
      const detail = await getRecipeDetail(recipe.publicId);
      setSelectedRecipe(detail);
      setShowRecipeSearch(false);
      setRecipeSearchQuery('');
      setSearchResults([]);
    } catch {
      setError('Failed to load recipe details');
    }
  };

  // Handle image selection
  const handleImageSelect = async (e: React.ChangeEvent<HTMLInputElement>) => {
    const files = Array.from(e.target.files || []);
    if (files.length === 0) return;

    // Limit to 3 images total
    const remaining = 3 - images.length;
    const filesToAdd = files.slice(0, remaining);

    // Add images to state with preview
    const newImages: UploadedImage[] = filesToAdd.map((file) => ({
      file,
      preview: URL.createObjectURL(file),
      publicId: null,
      uploading: true,
      error: null,
    }));

    setImages((prev) => [...prev, ...newImages]);

    // Upload each image
    for (let i = 0; i < newImages.length; i++) {
      const img = newImages[i];
      try {
        const response = await uploadImage(img.file, 'LOG_POST');
        setImages((prev) =>
          prev.map((p) =>
            p.preview === img.preview
              ? { ...p, publicId: response.imagePublicId, uploading: false }
              : p
          )
        );
      } catch {
        setImages((prev) =>
          prev.map((p) =>
            p.preview === img.preview
              ? { ...p, uploading: false, error: 'Upload failed' }
              : p
          )
        );
      }
    }

    // Reset input
    if (fileInputRef.current) {
      fileInputRef.current.value = '';
    }
  };

  // Remove image
  const removeImage = (preview: string) => {
    setImages((prev) => {
      const img = prev.find((p) => p.preview === preview);
      if (img) {
        URL.revokeObjectURL(img.preview);
      }
      return prev.filter((p) => p.preview !== preview);
    });
  };

  // Handle form submission
  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    setError(null);

    // Validation
    if (!selectedRecipe) {
      setError('Please select a recipe');
      return;
    }

    if (!content.trim()) {
      setError('Please enter your cooking notes');
      return;
    }

    // Check if any images are still uploading
    if (images.some((img) => img.uploading)) {
      setError('Please wait for images to finish uploading');
      return;
    }

    // Check for failed uploads
    const failedImages = images.filter((img) => img.error);
    if (failedImages.length > 0) {
      setError('Some images failed to upload. Please remove them and try again.');
      return;
    }

    setIsSubmitting(true);

    try {
      const hashtagList = hashtags
        .split(',')
        .map((h) => h.trim().replace(/^#/, ''))
        .filter((h) => h.length > 0);

      const imagePublicIds = images
        .filter((img) => img.publicId)
        .map((img) => img.publicId!);

      const log = await createLog({
        recipePublicId: selectedRecipe.publicId,
        content: content.trim(),
        outcome,
        imagePublicIds,
        hashtags: hashtagList.length > 0 ? hashtagList : undefined,
      });

      // Redirect to the new log
      router.push(`/logs/${log.publicId}`);
    } catch (err) {
      console.error('Failed to create log:', err);
      setError('Failed to create cooking log. Please try again.');
    } finally {
      setIsSubmitting(false);
    }
  };

  // Show loading state while auth is loading or redirecting to login
  if (authLoading || !isAuthenticated) {
    return (
      <div className="min-h-screen flex items-center justify-center bg-[var(--background)]">
        <div className="animate-pulse">
          <div className="w-12 h-12 rounded-full bg-[var(--primary-light)]" />
        </div>
      </div>
    );
  }

  return (
    <main className="min-h-screen bg-[var(--background)]">
      <div className="max-w-2xl mx-auto px-4 py-8">
        {/* Header */}
        <div className="mb-8">
          <Link
            href="/logs"
            className="text-[var(--text-secondary)] hover:text-[var(--primary)] inline-flex items-center gap-1 mb-4"
          >
            <svg className="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M15 19l-7-7 7-7" />
            </svg>
            Back to Logs
          </Link>
          <h1 className="text-3xl font-bold text-[var(--text-primary)]">
            New Cooking Log
          </h1>
          <p className="text-[var(--text-secondary)] mt-2">
            Share your cooking experience with the community
          </p>
        </div>

        <form onSubmit={handleSubmit} className="space-y-6">
          {/* Recipe Selection */}
          <div>
            <label className="block text-sm font-medium text-[var(--text-primary)] mb-2">
              Recipe <span className="text-[var(--error)]">*</span>
            </label>
            {selectedRecipe ? (
              <div className="flex items-center gap-4 p-4 bg-[var(--surface)] rounded-xl border border-[var(--border)]">
                {selectedRecipe.images[0] && (
                  <div className="relative w-16 h-16 rounded-lg overflow-hidden flex-shrink-0">
                    <Image
                      src={getImageUrl(selectedRecipe.images[0].imageUrl) || ''}
                      alt={selectedRecipe.title}
                      fill
                      className="object-cover"
                      sizes="64px"
                    />
                  </div>
                )}
                <div className="flex-1 min-w-0">
                  <p className="font-medium text-[var(--text-primary)] truncate">
                    {selectedRecipe.title}
                  </p>
                  <p className="text-sm text-[var(--text-secondary)] truncate">
                    {selectedRecipe.foodName}
                  </p>
                </div>
                <button
                  type="button"
                  onClick={() => setSelectedRecipe(null)}
                  className="p-2 text-[var(--text-secondary)] hover:text-[var(--error)] transition-colors"
                >
                  <svg className="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                    <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M6 18L18 6M6 6l12 12" />
                  </svg>
                </button>
              </div>
            ) : (
              <div className="relative">
                <button
                  type="button"
                  onClick={() => setShowRecipeSearch(true)}
                  className="w-full p-4 bg-[var(--surface)] rounded-xl border border-[var(--border)] border-dashed text-[var(--text-secondary)] hover:border-[var(--primary)] hover:text-[var(--primary)] transition-colors text-left"
                >
                  Click to select a recipe you cooked...
                </button>

                {/* Recipe Search Modal */}
                {showRecipeSearch && (
                  <div className="fixed inset-0 z-50 bg-black/50 flex items-start justify-center pt-20 px-4">
                    <div className="bg-[var(--surface)] rounded-2xl w-full max-w-lg shadow-xl max-h-[70vh] overflow-hidden flex flex-col">
                      <div className="p-4 border-b border-[var(--border)]">
                        <div className="flex items-center justify-between mb-3">
                          <h3 className="text-lg font-semibold text-[var(--text-primary)]">
                            Select Recipe
                          </h3>
                          <button
                            type="button"
                            onClick={() => {
                              setShowRecipeSearch(false);
                              setRecipeSearchQuery('');
                              setSearchResults([]);
                            }}
                            className="p-1 hover:bg-[var(--background)] rounded-lg transition-colors"
                          >
                            <svg className="w-5 h-5 text-[var(--text-secondary)]" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                              <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M6 18L18 6M6 6l12 12" />
                            </svg>
                          </button>
                        </div>
                        <input
                          type="text"
                          value={recipeSearchQuery}
                          onChange={(e) => setRecipeSearchQuery(e.target.value)}
                          placeholder="Search recipes..."
                          className="w-full px-4 py-2 bg-[var(--background)] border border-[var(--border)] rounded-lg focus:outline-none focus:border-[var(--primary)]"
                          autoFocus
                        />
                      </div>
                      <div className="flex-1 overflow-y-auto p-2">
                        {isSearching ? (
                          <div className="flex justify-center py-8">
                            <div className="animate-spin w-6 h-6 border-2 border-[var(--primary)] border-t-transparent rounded-full" />
                          </div>
                        ) : searchResults.length > 0 ? (
                          <div className="space-y-1">
                            {searchResults.map((recipe) => (
                              <button
                                key={recipe.publicId}
                                type="button"
                                onClick={() => handleSelectRecipe(recipe)}
                                className="w-full flex items-center gap-3 p-3 hover:bg-[var(--background)] rounded-lg transition-colors text-left"
                              >
                                {recipe.thumbnail ? (
                                  <div className="relative w-12 h-12 rounded-lg overflow-hidden flex-shrink-0">
                                    <Image
                                      src={getImageUrl(recipe.thumbnail) || ''}
                                      alt={recipe.title}
                                      fill
                                      className="object-cover"
                                      sizes="48px"
                                    />
                                  </div>
                                ) : (
                                  <div className="w-12 h-12 rounded-lg bg-[var(--background)] flex items-center justify-center flex-shrink-0">
                                    <span className="text-2xl">🍳</span>
                                  </div>
                                )}
                                <div className="min-w-0">
                                  <p className="font-medium text-[var(--text-primary)] truncate">
                                    {recipe.title}
                                  </p>
                                  <p className="text-sm text-[var(--text-secondary)] truncate">
                                    {recipe.foodName}
                                  </p>
                                </div>
                              </button>
                            ))}
                          </div>
                        ) : recipeSearchQuery.length >= 2 ? (
                          <p className="text-center text-[var(--text-secondary)] py-8">
                            No recipes found
                          </p>
                        ) : (
                          <p className="text-center text-[var(--text-secondary)] py-8">
                            Type at least 2 characters to search
                          </p>
                        )}
                      </div>
                    </div>
                  </div>
                )}
              </div>
            )}
          </div>

          {/* Outcome Selection */}
          <div>
            <label className="block text-sm font-medium text-[var(--text-primary)] mb-2">
              How did it go? <span className="text-[var(--error)]">*</span>
            </label>
            <div className="flex gap-2">
              {OUTCOME_OPTIONS.map((option) => (
                <button
                  key={option.value}
                  type="button"
                  onClick={() => setOutcome(option.value)}
                  className={`flex-1 py-3 px-4 rounded-xl border-2 transition-colors ${
                    outcome === option.value
                      ? option.value === 'SUCCESS'
                        ? 'border-[var(--success)] bg-[var(--diff-added-bg)]'
                        : option.value === 'PARTIAL'
                          ? 'border-[var(--diff-modified)] bg-[var(--diff-modified-bg)]'
                          : 'border-[var(--error)] bg-[var(--diff-removed-bg)]'
                      : 'border-[var(--border)] hover:border-[var(--primary-light)]'
                  }`}
                >
                  <span className="text-2xl">{option.emoji}</span>
                  <span className="block text-sm mt-1 text-[var(--text-primary)]">
                    {option.label}
                  </span>
                </button>
              ))}
            </div>
          </div>

          {/* Content */}
          <div>
            <label
              htmlFor="content"
              className="block text-sm font-medium text-[var(--text-primary)] mb-2"
            >
              Cooking Notes <span className="text-[var(--error)]">*</span>
            </label>
            <textarea
              id="content"
              value={content}
              onChange={(e) => setContent(e.target.value)}
              rows={6}
              className="w-full px-4 py-3 bg-[var(--surface)] border border-[var(--border)] rounded-xl focus:outline-none focus:border-[var(--primary)] resize-none"
              placeholder="How did it turn out? Share your experience, tips, or modifications..."
            />
          </div>

          {/* Images */}
          <div>
            <label className="block text-sm font-medium text-[var(--text-primary)] mb-2">
              Photos (up to 3)
            </label>
            <div className="flex gap-3 flex-wrap">
              {images.map((img) => (
                <div
                  key={img.preview}
                  className="relative w-24 h-24 rounded-lg overflow-hidden bg-[var(--background)]"
                >
                  <Image
                    src={img.preview}
                    alt="Upload preview"
                    fill
                    className="object-cover"
                    sizes="96px"
                  />
                  {img.uploading && (
                    <div className="absolute inset-0 bg-black/50 flex items-center justify-center">
                      <div className="animate-spin w-6 h-6 border-2 border-white border-t-transparent rounded-full" />
                    </div>
                  )}
                  {img.error && (
                    <div className="absolute inset-0 bg-[var(--error)]/50 flex items-center justify-center">
                      <svg className="w-6 h-6 text-white" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                        <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M12 9v2m0 4h.01m-6.938 4h13.856c1.54 0 2.502-1.667 1.732-3L13.732 4c-.77-1.333-2.694-1.333-3.464 0L3.34 16c-.77 1.333.192 3 1.732 3z" />
                      </svg>
                    </div>
                  )}
                  <button
                    type="button"
                    onClick={() => removeImage(img.preview)}
                    className="absolute top-1 right-1 p-1 bg-black/50 rounded-full hover:bg-black/70 transition-colors"
                  >
                    <svg className="w-4 h-4 text-white" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                      <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M6 18L18 6M6 6l12 12" />
                    </svg>
                  </button>
                </div>
              ))}
              {images.length < 3 && (
                <button
                  type="button"
                  onClick={() => fileInputRef.current?.click()}
                  className="w-24 h-24 rounded-lg border-2 border-dashed border-[var(--border)] hover:border-[var(--primary)] transition-colors flex items-center justify-center"
                >
                  <svg className="w-8 h-8 text-[var(--text-secondary)]" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                    <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M12 4v16m8-8H4" />
                  </svg>
                </button>
              )}
            </div>
            <input
              ref={fileInputRef}
              type="file"
              accept="image/*"
              multiple
              onChange={handleImageSelect}
              className="hidden"
            />
          </div>

          {/* Hashtags */}
          <div>
            <label
              htmlFor="hashtags"
              className="block text-sm font-medium text-[var(--text-primary)] mb-2"
            >
              Hashtags (optional)
            </label>
            <input
              id="hashtags"
              type="text"
              value={hashtags}
              onChange={(e) => setHashtags(e.target.value)}
              className="w-full px-4 py-3 bg-[var(--surface)] border border-[var(--border)] rounded-xl focus:outline-none focus:border-[var(--primary)]"
              placeholder="homecooking, weeknight, spicy (comma separated)"
            />
            <p className="text-xs text-[var(--text-secondary)] mt-1">
              Separate hashtags with commas
            </p>
          </div>

          {/* Error */}
          {error && (
            <div className="p-3 bg-[var(--error)]/10 border border-[var(--error)]/20 text-[var(--error)] rounded-lg text-sm">
              {error}
            </div>
          )}

          {/* Submit */}
          <div className="flex gap-3 pt-4">
            <Link
              href="/logs"
              className="flex-1 py-3 text-center text-[var(--text-primary)] border border-[var(--border)] rounded-xl font-medium hover:bg-[var(--surface)] transition-colors"
            >
              Cancel
            </Link>
            <button
              type="submit"
              disabled={isSubmitting || images.some((img) => img.uploading)}
              className="flex-1 py-3 bg-[var(--primary)] text-white rounded-xl font-medium hover:bg-[var(--primary-dark)] transition-colors disabled:opacity-50 disabled:cursor-not-allowed flex items-center justify-center gap-2"
            >
              {isSubmitting ? (
                <>
                  <svg className="animate-spin w-5 h-5" fill="none" viewBox="0 0 24 24">
                    <circle className="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" strokeWidth="4" />
                    <path className="opacity-75" fill="currentColor" d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4z" />
                  </svg>
                  Creating...
                </>
              ) : (
                'Create Log'
              )}
            </button>
          </div>
        </form>
      </div>
    </main>
  );
}
