'use client';

import { useState, useEffect, useRef } from 'react';
import { useRouter, useParams } from 'next/navigation';
import { Link } from '@/i18n/navigation';
import Image from 'next/image';
import { useTranslations } from 'next-intl';
import { useAuth } from '@/contexts/AuthContext';
import { getRecipeDetail, getRecipeModifiable, updateRecipe } from '@/lib/api/recipes';
import { uploadImage } from '@/lib/api/images';
import { getImageUrl } from '@/lib/utils/image';
import { LoadingSpinner } from '@/components/common/LoadingSpinner';
import type {
  RecipeDetail,
  RecipeModifiable,
  IngredientType,
  MeasurementUnit,
  UpdateRecipeRequest,
} from '@/lib/types';
import { COOKING_TIME_TRANSLATION_KEYS } from '@/lib/types';

const MAX_RECIPE_PHOTOS = 5;
const MAX_HASHTAGS = 5;
const MAX_HASHTAG_LENGTH = 30;
const MAX_STEPS = 20;

const INGREDIENT_CATEGORIES: {
  value: IngredientType;
  label: string;
  max: number;
  icon: string;
  color: string;
  bgColor: string;
  borderColor: string;
}[] = [
  {
    value: 'MAIN',
    label: 'Main',
    max: 5,
    icon: '🍲',
    color: 'var(--primary)',
    bgColor: 'var(--primary-light)',
    borderColor: 'var(--primary)',
  },
  {
    value: 'SECONDARY',
    label: 'Secondary',
    max: 8,
    icon: '🥕',
    color: 'var(--success)',
    bgColor: '#E8F5E9',
    borderColor: 'var(--success)',
  },
  {
    value: 'SEASONING',
    label: 'Sauce & Seasoning',
    max: 10,
    icon: '🧂',
    color: 'var(--secondary)',
    bgColor: '#EFEBE9',
    borderColor: 'var(--secondary)',
  },
];

const MEASUREMENT_UNITS: { value: MeasurementUnit | ''; label: string }[] = [
  { value: '', label: 'Unit' },
  { value: 'CUP', label: 'Cup' },
  { value: 'TBSP', label: 'Tbsp' },
  { value: 'TSP', label: 'Tsp' },
  { value: 'ML', label: 'ml' },
  { value: 'L', label: 'L' },
  { value: 'FL_OZ', label: 'fl oz' },
  { value: 'PINT', label: 'Pint' },
  { value: 'QUART', label: 'Quart' },
  { value: 'G', label: 'g' },
  { value: 'KG', label: 'kg' },
  { value: 'OZ', label: 'oz' },
  { value: 'LB', label: 'lb' },
  { value: 'PIECE', label: 'Piece' },
  { value: 'CLOVE', label: 'Clove' },
  { value: 'BUNCH', label: 'Bunch' },
  { value: 'CAN', label: 'Can' },
  { value: 'PACKAGE', label: 'Package' },
  { value: 'PINCH', label: 'Pinch' },
  { value: 'DASH', label: 'Dash' },
  { value: 'TO_TASTE', label: 'To Taste' },
];

interface UploadedImage {
  file: File;
  preview: string;
  publicId: string | null;
  uploading: boolean;
  error: string | null;
}

interface FormPhoto {
  id: string;
  type: 'original' | 'uploaded';
  originalUrl?: string;
  originalPublicId?: string;
  uploadedImage?: UploadedImage;
}

interface FormIngredient {
  id: string;
  name: string;
  quantity: string;
  unit: MeasurementUnit | '';
  type: IngredientType;
  isOriginal?: boolean;
  isDeleted?: boolean;
}

interface FormStep {
  id: string;
  description: string;
  image: UploadedImage | null;
  originalImageUrl?: string | null;
  originalImagePublicId?: string | null;
  isOriginal?: boolean;
  isDeleted?: boolean;
}

interface FormHashtag {
  id: string;
  name: string;
  isOriginal?: boolean;
  isDeleted?: boolean;
}

export default function RecipeEditPage() {
  const { publicId } = useParams<{ publicId: string }>();
  const router = useRouter();
  const { isAuthenticated, isLoading: authLoading } = useAuth();
  const t = useTranslations('recipeEdit');
  const tFilters = useTranslations('filters');
  const recipeImageInputRef = useRef<HTMLInputElement>(null);
  const stepImageInputRefs = useRef<Map<string, HTMLInputElement>>(new Map());

  const [recipe, setRecipe] = useState<RecipeDetail | null>(null);
  const [modifiable, setModifiable] = useState<RecipeModifiable | null>(null);
  const [isLoading, setIsLoading] = useState(true);
  const [isSaving, setIsSaving] = useState(false);
  const [error, setError] = useState<string | null>(null);

  // Form state
  const [title, setTitle] = useState('');
  const [description, setDescription] = useState('');
  const [photos, setPhotos] = useState<FormPhoto[]>([]);
  const [ingredients, setIngredients] = useState<FormIngredient[]>([]);
  const [steps, setSteps] = useState<FormStep[]>([]);
  const [hashtags, setHashtags] = useState<FormHashtag[]>([]);
  const [hashtagInput, setHashtagInput] = useState('');
  const [servings, setServings] = useState(2);
  const [cookingTimeRange, setCookingTimeRange] = useState('MIN_30_TO_60');
  const [isPrivate, setIsPrivate] = useState(false);

  // Load recipe data
  useEffect(() => {
    async function loadRecipe() {
      if (!publicId) return;

      try {
        const [recipeData, modifiableData] = await Promise.all([
          getRecipeDetail(publicId),
          getRecipeModifiable(publicId),
        ]);

        if (!modifiableData.canModify) {
          setError(modifiableData.reason || 'Cannot edit this recipe');
          setModifiable(modifiableData);
          setIsLoading(false);
          return;
        }

        setRecipe(recipeData);
        setModifiable(modifiableData);

        // Initialize form state with original markers
        setTitle(recipeData.title);
        setDescription(recipeData.description || '');
        setServings(recipeData.servings);
        setCookingTimeRange(recipeData.cookingTimeRange);
        setIsPrivate(recipeData.isPrivate);

        // Photos as original
        setPhotos(
          recipeData.images.map((img) => ({
            id: crypto.randomUUID(),
            type: 'original' as const,
            originalUrl: img.imageUrl,
            originalPublicId: img.imagePublicId,
          }))
        );

        // Ingredients as original
        setIngredients(
          recipeData.ingredients.map((ing) => ({
            id: crypto.randomUUID(),
            name: ing.name,
            quantity: ing.quantity?.toString() || '',
            unit: ing.unit || '',
            type: ing.type || 'MAIN',
            isOriginal: true,
            isDeleted: false,
          }))
        );

        // Steps as original
        setSteps(
          recipeData.steps.map((s) => ({
            id: crypto.randomUUID(),
            description: s.description,
            image: null,
            originalImageUrl: s.imageUrl,
            originalImagePublicId: s.imagePublicId,
            isOriginal: true,
            isDeleted: false,
          }))
        );

        // Hashtags as original
        setHashtags(
          recipeData.hashtags.map((h) => ({
            id: crypto.randomUUID(),
            name: h.name,
            isOriginal: true,
            isDeleted: false,
          }))
        );
      } catch (err) {
        console.error('Failed to load recipe:', err);
        setError('Failed to load recipe');
      } finally {
        setIsLoading(false);
      }
    }

    loadRecipe();
  }, [publicId]);

  // Redirect if not authenticated
  useEffect(() => {
    if (!authLoading && !isAuthenticated) {
      router.push(`/login?redirect=/recipes/${publicId}/edit`);
    }
  }, [authLoading, isAuthenticated, publicId, router]);

  // Photo handlers
  const handlePhotoSelect = async (e: React.ChangeEvent<HTMLInputElement>) => {
    const files = Array.from(e.target.files || []);
    if (files.length === 0) return;

    const remaining = MAX_RECIPE_PHOTOS - photos.length;
    const filesToAdd = files.slice(0, remaining);

    const newPhotos: FormPhoto[] = filesToAdd.map((file) => ({
      id: crypto.randomUUID(),
      type: 'uploaded' as const,
      uploadedImage: {
        file,
        preview: URL.createObjectURL(file),
        publicId: null,
        uploading: true,
        error: null,
      },
    }));

    setPhotos((prev) => [...prev, ...newPhotos]);

    for (const photo of newPhotos) {
      try {
        const response = await uploadImage(photo.uploadedImage!.file, 'COVER');
        setPhotos((prev) =>
          prev.map((p) =>
            p.id === photo.id && p.uploadedImage
              ? {
                  ...p,
                  uploadedImage: {
                    ...p.uploadedImage,
                    publicId: response.imagePublicId,
                    uploading: false,
                  },
                }
              : p
          )
        );
      } catch {
        setPhotos((prev) =>
          prev.map((p) =>
            p.id === photo.id && p.uploadedImage
              ? {
                  ...p,
                  uploadedImage: {
                    ...p.uploadedImage,
                    uploading: false,
                    error: 'Upload failed',
                  },
                }
              : p
          )
        );
      }
    }

    if (recipeImageInputRef.current) {
      recipeImageInputRef.current.value = '';
    }
  };

  const removePhoto = (photoId: string) => {
    setPhotos((prev) => {
      const photo = prev.find((p) => p.id === photoId);
      if (photo?.type === 'uploaded' && photo.uploadedImage) {
        URL.revokeObjectURL(photo.uploadedImage.preview);
      }
      return prev.filter((p) => p.id !== photoId);
    });
  };

  // Ingredient handlers
  const addIngredient = (type: IngredientType) => {
    const categoryIngredients = ingredients.filter((ing) => ing.type === type && !ing.isDeleted);
    const max = INGREDIENT_CATEGORIES.find((c) => c.value === type)?.max || 5;
    if (categoryIngredients.length >= max) return;

    setIngredients((prev) => [
      ...prev,
      { id: crypto.randomUUID(), name: '', quantity: '', unit: '', type },
    ]);
  };

  const updateIngredient = (id: string, field: keyof FormIngredient, value: string) => {
    setIngredients((prev) =>
      prev.map((ing) => {
        if (ing.id !== id) return ing;
        if (field === 'quantity') {
          const sanitized = value.replace(/[^0-9.]/g, '').slice(0, 4);
          return { ...ing, [field]: sanitized };
        }
        return { ...ing, [field]: value };
      })
    );
  };

  const removeIngredient = (id: string) => {
    setIngredients((prev) => {
      const item = prev.find((ing) => ing.id === id);
      if (item?.isOriginal) {
        return prev.map((ing) => (ing.id === id ? { ...ing, isDeleted: true } : ing));
      } else {
        return prev.filter((ing) => ing.id !== id);
      }
    });
  };

  const restoreIngredient = (id: string) => {
    setIngredients((prev) =>
      prev.map((ing) => (ing.id === id ? { ...ing, isDeleted: false } : ing))
    );
  };

  // Step handlers
  const addStep = () => {
    const activeSteps = steps.filter((s) => !s.isDeleted);
    if (activeSteps.length >= MAX_STEPS) return;
    setSteps((prev) => [
      ...prev,
      { id: crypto.randomUUID(), description: '', image: null },
    ]);
  };

  const updateStep = (id: string, description: string) => {
    setSteps((prev) =>
      prev.map((step) => (step.id === id ? { ...step, description } : step))
    );
  };

  const removeStep = (id: string) => {
    const nonDeletedCount = steps.filter((s) => !s.isDeleted).length;
    if (nonDeletedCount <= 1) return;

    setSteps((prev) => {
      const step = prev.find((s) => s.id === id);
      if (step?.isOriginal) {
        if (step.image) URL.revokeObjectURL(step.image.preview);
        return prev.map((s) =>
          s.id === id ? { ...s, isDeleted: true, image: null } : s
        );
      } else {
        if (step?.image) URL.revokeObjectURL(step.image.preview);
        return prev.filter((s) => s.id !== id);
      }
    });
  };

  const restoreStep = (id: string) => {
    setSteps((prev) =>
      prev.map((step) => (step.id === id ? { ...step, isDeleted: false } : step))
    );
  };

  // Step image handlers
  const handleStepImageSelect = async (stepId: string, e: React.ChangeEvent<HTMLInputElement>) => {
    const file = e.target.files?.[0];
    if (!file) return;

    const newImage: UploadedImage = {
      file,
      preview: URL.createObjectURL(file),
      publicId: null,
      uploading: true,
      error: null,
    };

    setSteps((prev) =>
      prev.map((s) => (s.id === stepId ? { ...s, image: newImage, originalImageUrl: null, originalImagePublicId: null } : s))
    );

    try {
      const response = await uploadImage(file, 'STEP');
      setSteps((prev) =>
        prev.map((s) =>
          s.id === stepId && s.image?.preview === newImage.preview
            ? { ...s, image: { ...s.image, publicId: response.imagePublicId, uploading: false } }
            : s
        )
      );
    } catch {
      setSteps((prev) =>
        prev.map((s) =>
          s.id === stepId && s.image?.preview === newImage.preview
            ? { ...s, image: { ...s.image, uploading: false, error: 'Upload failed' } }
            : s
        )
      );
    }

    const input = stepImageInputRefs.current.get(stepId);
    if (input) input.value = '';
  };

  const removeStepImage = (stepId: string) => {
    setSteps((prev) =>
      prev.map((s) => {
        if (s.id === stepId) {
          if (s.image) URL.revokeObjectURL(s.image.preview);
          return { ...s, image: null, originalImageUrl: null, originalImagePublicId: null };
        }
        return s;
      })
    );
  };

  // Hashtag handlers
  const normalizeHashtag = (tag: string): string => {
    return tag
      .toLowerCase()
      .trim()
      .replace(/^#/, '')
      .replace(/\s+/g, '-')
      .slice(0, MAX_HASHTAG_LENGTH);
  };

  const addHashtag = () => {
    if (!hashtagInput.trim()) return;
    const activeCount = hashtags.filter((h) => !h.isDeleted).length;
    if (activeCount >= MAX_HASHTAGS) return;

    const normalized = normalizeHashtag(hashtagInput);
    if (!normalized) return;
    if (hashtags.some((h) => h.name === normalized && !h.isDeleted)) {
      setHashtagInput('');
      return;
    }

    const existingDeleted = hashtags.find((h) => h.name === normalized && h.isDeleted);
    if (existingDeleted) {
      setHashtags((prev) =>
        prev.map((h) => (h.id === existingDeleted.id ? { ...h, isDeleted: false } : h))
      );
      setHashtagInput('');
      return;
    }

    setHashtags((prev) => [
      ...prev,
      { id: crypto.randomUUID(), name: normalized, isOriginal: false, isDeleted: false },
    ]);
    setHashtagInput('');
  };

  const handleHashtagKeyDown = (e: React.KeyboardEvent<HTMLInputElement>) => {
    if (e.key === 'Enter' || e.key === ',') {
      e.preventDefault();
      addHashtag();
    }
  };

  const removeHashtag = (id: string) => {
    setHashtags((prev) => {
      const hashtag = prev.find((h) => h.id === id);
      if (hashtag?.isOriginal) {
        return prev.map((h) => (h.id === id ? { ...h, isDeleted: true } : h));
      } else {
        return prev.filter((h) => h.id !== id);
      }
    });
  };

  const restoreHashtag = (id: string) => {
    setHashtags((prev) =>
      prev.map((h) => (h.id === id ? { ...h, isDeleted: false } : h))
    );
  };

  // Form submission
  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();

    if (!title.trim()) {
      setError(t('errorTitle'));
      return;
    }

    const activeIngredients = ingredients.filter((i) => !i.isDeleted && i.name.trim());
    if (activeIngredients.length === 0) {
      setError(t('errorIngredients'));
      return;
    }

    const activeSteps = steps.filter((s) => !s.isDeleted && s.description.trim());
    if (activeSteps.length === 0) {
      setError(t('errorSteps'));
      return;
    }

    if (photos.length === 0) {
      setError(t('errorPhoto'));
      return;
    }

    if (photos.some((p) => p.type === 'uploaded' && p.uploadedImage?.uploading)) {
      setError(t('errorUploading'));
      return;
    }

    setIsSaving(true);
    setError(null);

    try {
      const activeHashtags = hashtags.filter((h) => !h.isDeleted);

      // Collect all image public IDs (original + uploaded)
      const imagePublicIds: string[] = [];
      for (const photo of photos) {
        if (photo.type === 'original' && photo.originalPublicId) {
          imagePublicIds.push(photo.originalPublicId);
        } else if (photo.type === 'uploaded' && photo.uploadedImage?.publicId) {
          imagePublicIds.push(photo.uploadedImage.publicId);
        }
      }

      const data: UpdateRecipeRequest = {
        title: title.trim(),
        description: description.trim() || undefined,
        ingredients: activeIngredients.map((ing) => ({
          name: ing.name.trim(),
          quantity: ing.quantity ? parseFloat(ing.quantity) : null,
          unit: ing.unit || null,
          type: ing.type,
        })),
        steps: activeSteps.map((s, i) => ({
          stepNumber: i + 1,
          description: s.description.trim(),
          imagePublicId: s.image?.publicId || s.originalImagePublicId || null,
        })),
        imagePublicIds,
        hashtags: activeHashtags.map((h) => h.name),
        servings,
        cookingTimeRange,
        isPrivate,
      };

      await updateRecipe(publicId!, data);
      router.push(`/recipes/${publicId}`);
      router.refresh();
    } catch (err) {
      console.error('Failed to update recipe:', err);
      setError(t('errorSave'));
    } finally {
      setIsSaving(false);
    }
  };

  if (authLoading || isLoading) {
    return <LoadingSpinner />;
  }

  if (error && !recipe) {
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
            href={`/recipes/${publicId}`}
            className="px-6 py-3 bg-[var(--primary)] text-white rounded-xl font-medium hover:bg-[var(--primary-dark)] transition-colors"
          >
            {t('backToRecipe')}
          </Link>
        </div>
      </main>
    );
  }

  const activeHashtags = hashtags.filter((h) => !h.isDeleted);
  const deletedHashtags = hashtags.filter((h) => h.isDeleted);
  const activeSteps = steps.filter((s) => !s.isDeleted);
  const deletedSteps = steps.filter((s) => s.isDeleted);

  return (
    <main className="min-h-screen bg-[var(--background)]">
      <div className="max-w-3xl mx-auto px-4 py-8">
        {/* Header */}
        <div className="flex items-center justify-between mb-8">
          <div>
            <Link
              href={`/recipes/${publicId}`}
              className="text-sm text-[var(--text-secondary)] hover:text-[var(--primary)] mb-2 inline-block"
            >
              ← {t('backToRecipe')}
            </Link>
            <h1 className="text-2xl font-bold text-[var(--text-primary)]">{t('title')}</h1>
          </div>
        </div>

        <form onSubmit={handleSubmit} className="space-y-8">
          {/* Photos Section */}
          <section className="bg-[var(--surface)] border border-[var(--border)] rounded-2xl p-6">
            <h2 className="text-lg font-semibold text-[var(--text-primary)] mb-4">
              {t('photos')} <span className="text-[var(--error)]">*</span>
            </h2>
            <p className="text-sm text-[var(--text-secondary)] mb-4">
              {t('photosCount', { count: photos.length, max: MAX_RECIPE_PHOTOS })}
            </p>

            <div className="flex gap-3 flex-wrap">
              {photos.map((photo) => (
                <div
                  key={photo.id}
                  className="relative w-24 h-24 rounded-xl overflow-hidden bg-[var(--background)]"
                >
                  <Image
                    src={
                      photo.type === 'original'
                        ? getImageUrl(photo.originalUrl) || ''
                        : photo.uploadedImage?.preview || ''
                    }
                    alt="Recipe photo"
                    fill
                    className="object-cover"
                    sizes="96px"
                  />
                  {photo.type === 'original' && (
                    <span className="absolute bottom-1 left-1 text-[8px] px-1 py-0.5 bg-black/60 text-white rounded">
                      {t('original')}
                    </span>
                  )}
                  {photo.type === 'uploaded' && photo.uploadedImage?.uploading && (
                    <div className="absolute inset-0 bg-black/50 flex items-center justify-center">
                      <div className="animate-spin w-6 h-6 border-2 border-white border-t-transparent rounded-full" />
                    </div>
                  )}
                  <button
                    type="button"
                    onClick={() => removePhoto(photo.id)}
                    className="absolute top-1 right-1 p-1 bg-black/50 rounded-full hover:bg-black/70 transition-colors"
                  >
                    <svg className="w-3 h-3 text-white" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                      <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M6 18L18 6M6 6l12 12" />
                    </svg>
                  </button>
                </div>
              ))}
              {photos.length < MAX_RECIPE_PHOTOS && (
                <button
                  type="button"
                  onClick={() => recipeImageInputRef.current?.click()}
                  className="w-24 h-24 rounded-xl border-2 border-dashed border-[var(--border)] hover:border-[var(--primary)] transition-colors flex items-center justify-center"
                >
                  <svg className="w-8 h-8 text-[var(--text-secondary)]" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                    <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M12 4v16m8-8H4" />
                  </svg>
                </button>
              )}
            </div>
            <input
              ref={recipeImageInputRef}
              type="file"
              accept="image/*"
              multiple
              onChange={handlePhotoSelect}
              className="hidden"
            />
          </section>

          {/* Basic Info */}
          <section className="bg-[var(--surface)] border border-[var(--border)] rounded-2xl p-6">
            <h2 className="text-lg font-semibold text-[var(--text-primary)] mb-4">
              {t('basicInfo')}
            </h2>

            <div className="space-y-4">
              <div>
                <label htmlFor="title" className="block text-sm font-medium text-[var(--text-primary)] mb-2">
                  {t('titleLabel')} <span className="text-[var(--error)]">*</span>
                </label>
                <input
                  id="title"
                  type="text"
                  value={title}
                  onChange={(e) => setTitle(e.target.value)}
                  className="w-full px-4 py-3 bg-[var(--background)] border border-[var(--border)] rounded-xl focus:outline-none focus:border-[var(--primary)]"
                  placeholder={t('titlePlaceholder')}
                />
              </div>

              <div>
                <label htmlFor="description" className="block text-sm font-medium text-[var(--text-primary)] mb-2">
                  {t('descriptionLabel')}
                </label>
                <textarea
                  id="description"
                  value={description}
                  onChange={(e) => setDescription(e.target.value)}
                  rows={3}
                  className="w-full px-4 py-3 bg-[var(--background)] border border-[var(--border)] rounded-xl focus:outline-none focus:border-[var(--primary)] resize-none"
                  placeholder={t('descriptionPlaceholder')}
                />
              </div>

              <div className="grid grid-cols-2 gap-4">
                <div>
                  <label htmlFor="servings" className="block text-sm font-medium text-[var(--text-primary)] mb-2">
                    {t('servings')}
                  </label>
                  <input
                    id="servings"
                    type="number"
                    min="1"
                    max="100"
                    value={servings}
                    onChange={(e) => setServings(parseInt(e.target.value) || 1)}
                    className="w-full px-4 py-3 bg-[var(--background)] border border-[var(--border)] rounded-xl focus:outline-none focus:border-[var(--primary)]"
                  />
                </div>

                <div>
                  <label htmlFor="cookingTime" className="block text-sm font-medium text-[var(--text-primary)] mb-2">
                    {t('cookingTime')}
                  </label>
                  <select
                    id="cookingTime"
                    value={cookingTimeRange}
                    onChange={(e) => setCookingTimeRange(e.target.value)}
                    className="w-full px-4 py-3 bg-[var(--background)] border border-[var(--border)] rounded-xl focus:outline-none focus:border-[var(--primary)]"
                  >
                    {Object.entries(COOKING_TIME_TRANSLATION_KEYS).map(([enumValue, translationKey]) => (
                      <option key={enumValue} value={enumValue}>
                        {tFilters(translationKey)}
                      </option>
                    ))}
                  </select>
                </div>
              </div>
            </div>
          </section>

          {/* Ingredients */}
          <section className="bg-[var(--surface)] border border-[var(--border)] rounded-2xl p-6">
            <h2 className="text-lg font-semibold text-[var(--text-primary)] mb-4">
              {t('ingredients')} <span className="text-[var(--error)]">*</span>
            </h2>
            <p className="text-sm text-[var(--text-secondary)] mb-4">
              {t('ingredientsHelp')}
            </p>

            <div className="space-y-6">
              {INGREDIENT_CATEGORIES.map((category) => {
                const categoryIngredients = ingredients.filter((ing) => ing.type === category.value);
                const activeIngredients = categoryIngredients.filter((ing) => !ing.isDeleted);
                const deletedIngredients = categoryIngredients.filter((ing) => ing.isDeleted);
                const canAdd = activeIngredients.length < category.max;

                return (
                  <div
                    key={category.value}
                    className="rounded-xl p-4 border-2"
                    style={{
                      borderColor: category.borderColor,
                      backgroundColor: `color-mix(in srgb, ${category.bgColor} 30%, transparent)`,
                    }}
                  >
                    <div className="flex justify-between items-center mb-3">
                      <h3
                        className="text-sm font-semibold flex items-center gap-2"
                        style={{ color: category.color }}
                      >
                        <span className="text-base">{category.icon}</span>
                        {category.label}
                      </h3>
                      <span
                        className="text-xs font-medium px-2 py-0.5 rounded-full"
                        style={{ backgroundColor: category.bgColor, color: category.color }}
                      >
                        {activeIngredients.length}/{category.max}
                      </span>
                    </div>

                    <div className="space-y-2">
                      {activeIngredients.map((ing, index) => (
                        <div
                          key={ing.id}
                          className={`flex gap-2 items-center ${
                            ing.isOriginal ? 'pl-2 border-l-2 border-dashed border-[var(--primary-light)]' : ''
                          }`}
                        >
                          <span className="text-xs text-[var(--text-secondary)] w-4">
                            {index + 1}.
                          </span>
                          {ing.isOriginal && (
                            <span className="text-[10px] px-1.5 py-0.5 bg-[var(--primary-light)]/20 text-[var(--primary)] rounded">
                              {t('original')}
                            </span>
                          )}
                          <input
                            type="text"
                            value={ing.name}
                            onChange={(e) => updateIngredient(ing.id, 'name', e.target.value)}
                            placeholder={t('ingredientPlaceholder')}
                            className="flex-1 px-3 py-2 bg-[var(--background)] border border-[var(--border)] rounded-lg focus:outline-none focus:border-[var(--primary)] text-sm"
                          />
                          <input
                            type="text"
                            inputMode="decimal"
                            value={ing.quantity}
                            onChange={(e) => updateIngredient(ing.id, 'quantity', e.target.value)}
                            placeholder={t('qty')}
                            className="w-16 px-2 py-2 bg-[var(--background)] border border-[var(--border)] rounded-lg focus:outline-none focus:border-[var(--primary)] text-sm text-center"
                          />
                          <select
                            value={ing.unit}
                            onChange={(e) => updateIngredient(ing.id, 'unit', e.target.value)}
                            className="w-24 px-2 py-2 bg-[var(--background)] border border-[var(--border)] rounded-lg focus:outline-none focus:border-[var(--primary)] text-sm"
                          >
                            {MEASUREMENT_UNITS.map((unit) => (
                              <option key={unit.value} value={unit.value}>
                                {unit.label}
                              </option>
                            ))}
                          </select>
                          <button
                            type="button"
                            onClick={() => removeIngredient(ing.id)}
                            className="p-1.5 text-[var(--text-secondary)] hover:text-[var(--error)] transition-colors"
                          >
                            <svg className="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                              <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M6 18L18 6M6 6l12 12" />
                            </svg>
                          </button>
                        </div>
                      ))}
                    </div>

                    {/* Deleted ingredients */}
                    {deletedIngredients.length > 0 && (
                      <div className="mt-3 border border-dashed border-[var(--border)] rounded-lg p-3 bg-[var(--background)]">
                        <div className="flex items-center gap-2 text-xs text-[var(--text-secondary)] mb-2">
                          <svg className="w-3.5 h-3.5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                            <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M19 7l-.867 12.142A2 2 0 0116.138 21H7.862a2 2 0 01-1.995-1.858L5 7m5 4v6m4-6v6m1-10V4a1 1 0 00-1-1h-4a1 1 0 00-1 1v3M4 7h16" />
                          </svg>
                          <span>{t('removed')} ({deletedIngredients.length})</span>
                        </div>
                        <div className="space-y-1.5">
                          {deletedIngredients.map((ing) => {
                            const unitLabel = MEASUREMENT_UNITS.find((u) => u.value === ing.unit)?.label || '';
                            const displayText = `${ing.name}${ing.quantity ? ` - ${ing.quantity}` : ''}${unitLabel ? ` ${unitLabel}` : ''}`;
                            return (
                              <div
                                key={ing.id}
                                className="flex items-center justify-between py-1.5 px-2 bg-[var(--surface)] rounded"
                              >
                                <span className="text-sm text-[var(--text-secondary)] line-through">
                                  {displayText}
                                </span>
                                <button
                                  type="button"
                                  onClick={() => restoreIngredient(ing.id)}
                                  className="text-xs text-[var(--primary)] hover:underline"
                                >
                                  {t('restore')}
                                </button>
                              </div>
                            );
                          })}
                        </div>
                      </div>
                    )}

                    {canAdd && (
                      <button
                        type="button"
                        onClick={() => addIngredient(category.value)}
                        className="mt-3 w-full py-2 border border-dashed border-[var(--border)] rounded-lg text-sm text-[var(--text-secondary)] hover:border-[var(--primary)] hover:text-[var(--primary)] transition-colors"
                      >
                        + {t('addIngredient', { category: category.label })}
                      </button>
                    )}
                  </div>
                );
              })}
            </div>
          </section>

          {/* Steps */}
          <section className="bg-[var(--surface)] border border-[var(--border)] rounded-2xl p-6">
            <div className="flex items-center justify-between mb-4">
              <h2 className="text-lg font-semibold text-[var(--text-primary)]">
                {t('instructions')} <span className="text-[var(--error)]">*</span>
              </h2>
              <button
                type="button"
                onClick={addStep}
                className="text-sm text-[var(--primary)] hover:underline"
              >
                + {t('addStep')}
              </button>
            </div>

            <div className="space-y-4">
              {activeSteps.map((step, index) => {
                const hasImage = step.image || step.originalImageUrl;
                const imageUrl = step.image?.preview || (step.originalImageUrl ? getImageUrl(step.originalImageUrl) : null);

                return (
                  <div
                    key={step.id}
                    className={`flex gap-3 items-start ${
                      step.isOriginal ? 'pl-2 border-l-2 border-dashed border-[var(--primary-light)]' : ''
                    }`}
                  >
                    <span className="flex-shrink-0 w-8 h-8 bg-[var(--primary)] text-white rounded-full flex items-center justify-center font-bold text-sm">
                      {index + 1}
                    </span>
                    <div className="flex-1">
                      {step.isOriginal && (
                        <span className="inline-block text-[10px] px-1.5 py-0.5 bg-[var(--primary-light)]/20 text-[var(--primary)] rounded mb-2">
                          {t('original')}
                        </span>
                      )}
                      <textarea
                        value={step.description}
                        onChange={(e) => updateStep(step.id, e.target.value)}
                        placeholder={t('stepPlaceholder', { number: index + 1 })}
                        rows={2}
                        className="w-full px-3 py-2 bg-[var(--background)] border border-[var(--border)] rounded-lg focus:outline-none focus:border-[var(--primary)] text-sm resize-none"
                      />

                      {/* Step image */}
                      <div className="mt-2">
                        {hasImage && imageUrl ? (
                          <div className="relative w-20 h-20 rounded-lg overflow-hidden bg-[var(--background)]">
                            <Image
                              src={imageUrl}
                              alt={`Step ${index + 1} image`}
                              fill
                              className="object-cover"
                              sizes="80px"
                            />
                            {step.image?.uploading && (
                              <div className="absolute inset-0 bg-black/50 flex items-center justify-center">
                                <div className="animate-spin w-5 h-5 border-2 border-white border-t-transparent rounded-full" />
                              </div>
                            )}
                            {step.originalImageUrl && !step.image && (
                              <span className="absolute bottom-0.5 left-0.5 text-[7px] px-1 py-0.5 bg-black/60 text-white rounded">
                                {t('original')}
                              </span>
                            )}
                            <button
                              type="button"
                              onClick={() => removeStepImage(step.id)}
                              className="absolute top-0.5 right-0.5 p-0.5 bg-black/50 rounded-full hover:bg-black/70 transition-colors"
                            >
                              <svg className="w-3 h-3 text-white" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                                <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M6 18L18 6M6 6l12 12" />
                              </svg>
                            </button>
                          </div>
                        ) : (
                          <button
                            type="button"
                            onClick={() => stepImageInputRefs.current.get(step.id)?.click()}
                            className="flex items-center gap-1.5 text-xs text-[var(--text-secondary)] hover:text-[var(--primary)] transition-colors"
                          >
                            <svg className="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                              <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M4 16l4.586-4.586a2 2 0 012.828 0L16 16m-2-2l1.586-1.586a2 2 0 012.828 0L20 14m-6-6h.01M6 20h12a2 2 0 002-2V6a2 2 0 00-2-2H6a2 2 0 00-2 2v12a2 2 0 002 2z" />
                            </svg>
                            {t('addPhoto')}
                          </button>
                        )}
                        <input
                          ref={(el) => {
                            if (el) stepImageInputRefs.current.set(step.id, el);
                          }}
                          type="file"
                          accept="image/*"
                          onChange={(e) => handleStepImageSelect(step.id, e)}
                          className="hidden"
                        />
                      </div>
                    </div>
                    <button
                      type="button"
                      onClick={() => removeStep(step.id)}
                      className="p-2 text-[var(--text-secondary)] hover:text-[var(--error)]"
                    >
                      <svg className="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                        <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M6 18L18 6M6 6l12 12" />
                      </svg>
                    </button>
                  </div>
                );
              })}
            </div>

            {/* Deleted steps */}
            {deletedSteps.length > 0 && (
              <div className="mt-4 border border-dashed border-[var(--border)] rounded-lg p-3 bg-[var(--background)]">
                <div className="flex items-center gap-2 text-xs text-[var(--text-secondary)] mb-2">
                  <svg className="w-3.5 h-3.5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                    <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M19 7l-.867 12.142A2 2 0 0116.138 21H7.862a2 2 0 01-1.995-1.858L5 7m5 4v6m4-6v6m1-10V4a1 1 0 00-1-1h-4a1 1 0 00-1 1v3M4 7h16" />
                  </svg>
                  <span>{t('removedSteps')} ({deletedSteps.length})</span>
                </div>
                <div className="space-y-1.5">
                  {deletedSteps.map((step) => (
                    <div
                      key={step.id}
                      className="flex items-center justify-between py-1.5 px-2 bg-[var(--surface)] rounded"
                    >
                      <span className="text-sm text-[var(--text-secondary)] line-through truncate max-w-[80%]">
                        {step.description}
                      </span>
                      <button
                        type="button"
                        onClick={() => restoreStep(step.id)}
                        className="text-xs text-[var(--primary)] hover:underline"
                      >
                        {t('restore')}
                      </button>
                    </div>
                  ))}
                </div>
              </div>
            )}
          </section>

          {/* Hashtags */}
          <section className="bg-[var(--surface)] border border-[var(--border)] rounded-2xl p-6">
            <div className="flex items-center justify-between mb-4">
              <h2 className="text-lg font-semibold text-[var(--text-primary)]">{t('hashtags')}</h2>
              <span className="text-xs text-[var(--text-secondary)]">
                {activeHashtags.length}/{MAX_HASHTAGS}
              </span>
            </div>

            {/* Active hashtags */}
            {activeHashtags.length > 0 && (
              <div className="flex flex-wrap gap-2 mb-4">
                {activeHashtags.map((hashtag) => (
                  <span
                    key={hashtag.id}
                    className={`inline-flex items-center gap-1 px-3 py-1.5 rounded-full text-sm text-hashtag ${
                      hashtag.isOriginal ? 'border border-dashed' : ''
                    }`}
                    style={hashtag.isOriginal ? { borderColor: 'rgba(76, 175, 80, 0.4)' } : undefined}
                  >
                    {hashtag.isOriginal && (
                      <span
                        className="text-[10px] px-1 py-0.5 rounded mr-1 text-hashtag"
                        style={{ backgroundColor: 'rgba(76, 175, 80, 0.1)' }}
                      >
                        {t('original')}
                      </span>
                    )}
                    #{hashtag.name}
                    <button
                      type="button"
                      onClick={() => removeHashtag(hashtag.id)}
                      className="hover:text-[var(--error)] transition-colors ml-1"
                    >
                      <svg className="w-3.5 h-3.5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                        <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M6 18L18 6M6 6l12 12" />
                      </svg>
                    </button>
                  </span>
                ))}
              </div>
            )}

            {/* Deleted hashtags */}
            {deletedHashtags.length > 0 && (
              <div className="mb-4 border border-dashed border-[var(--border)] rounded-lg p-3 bg-[var(--background)]">
                <div className="flex items-center gap-2 text-xs text-[var(--text-secondary)] mb-2">
                  <svg className="w-3.5 h-3.5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                    <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M19 7l-.867 12.142A2 2 0 0116.138 21H7.862a2 2 0 01-1.995-1.858L5 7m5 4v6m4-6v6m1-10V4a1 1 0 00-1-1h-4a1 1 0 00-1 1v3M4 7h16" />
                  </svg>
                  <span>{t('removed')} ({deletedHashtags.length})</span>
                </div>
                <div className="flex flex-wrap gap-2">
                  {deletedHashtags.map((hashtag) => (
                    <span
                      key={hashtag.id}
                      className="inline-flex items-center gap-2 px-2 py-1 bg-[var(--surface)] rounded text-sm"
                    >
                      <span className="text-[var(--text-secondary)] line-through">
                        #{hashtag.name}
                      </span>
                      <button
                        type="button"
                        onClick={() => restoreHashtag(hashtag.id)}
                        className="text-xs text-hashtag hover:underline"
                      >
                        {t('restore')}
                      </button>
                    </span>
                  ))}
                </div>
              </div>
            )}

            {/* Input */}
            {activeHashtags.length < MAX_HASHTAGS && (
              <div className="flex gap-2">
                <input
                  type="text"
                  value={hashtagInput}
                  onChange={(e) => setHashtagInput(e.target.value)}
                  onKeyDown={handleHashtagKeyDown}
                  maxLength={MAX_HASHTAG_LENGTH}
                  className="flex-1 px-4 py-3 bg-[var(--background)] border border-[var(--border)] rounded-xl focus:outline-none focus:border-[var(--primary)]"
                  placeholder={t('hashtagPlaceholder')}
                />
                <button
                  type="button"
                  onClick={addHashtag}
                  disabled={!hashtagInput.trim()}
                  className="px-4 py-3 bg-[var(--primary)] text-white rounded-xl font-medium hover:bg-[var(--primary-dark)] transition-colors disabled:opacity-50 disabled:cursor-not-allowed"
                >
                  {t('add')}
                </button>
              </div>
            )}
          </section>

          {/* Visibility Section */}
          <section className="bg-[var(--surface)] border border-[var(--border)] rounded-2xl p-6">
            <h2 className="text-lg font-semibold text-[var(--text-primary)] mb-4">
              {t('visibility')}
            </h2>
            <div className="flex items-center justify-between">
              <div>
                <p className="text-sm font-medium text-[var(--text-primary)]">
                  {isPrivate ? t('privateRecipe') : t('publicRecipe')}
                </p>
                <p className="text-xs text-[var(--text-secondary)] mt-1">
                  {isPrivate ? t('privateHint') : t('publicHint')}
                </p>
              </div>
              <button
                type="button"
                onClick={() => setIsPrivate(!isPrivate)}
                className={`relative inline-flex h-6 w-11 items-center rounded-full transition-colors ${
                  isPrivate ? 'bg-[var(--primary)]' : 'bg-[var(--border)]'
                }`}
              >
                <span
                  className={`inline-block h-4 w-4 transform rounded-full bg-white transition-transform ${
                    isPrivate ? 'translate-x-6' : 'translate-x-1'
                  }`}
                />
              </button>
            </div>
          </section>

          {/* Error */}
          {error && (
            <div className="p-4 bg-[var(--error)]/10 border border-[var(--error)]/20 text-[var(--error)] rounded-xl">
              {error}
            </div>
          )}

          {/* Actions */}
          <div className="flex gap-4 justify-end">
            <Link
              href={`/recipes/${publicId}`}
              className="px-6 py-3 text-sm font-medium text-[var(--text-primary)] hover:bg-[var(--surface)] rounded-xl transition-colors"
            >
              {t('cancel')}
            </Link>
            <button
              type="submit"
              disabled={isSaving}
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
