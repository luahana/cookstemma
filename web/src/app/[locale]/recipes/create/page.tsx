'use client';

import { useState, useRef, useEffect, useCallback, Suspense } from 'react';
import Image from 'next/image';
import { Link } from '@/i18n/navigation';
import { useRouter, useSearchParams, useParams } from 'next/navigation';
import { useTranslations } from 'next-intl';
import { useAuth } from '@/contexts/AuthContext';
import { createRecipe, getRecipeDetail } from '@/lib/api/recipes';
import type { RecipeDetail } from '@/lib/types';
import { uploadImage } from '@/lib/api/images';
import type { IngredientType, CookingTimeRange, IngredientDto, MeasurementUnit } from '@/lib/types';
import { COOKING_TIME_TRANSLATION_KEYS } from '@/lib/types';
import { getDefaultCookingStyle } from '@/lib/utils/cookingStyle';
import { CookingStyleSelect, useCookingStyleOptions, COOKING_STYLE_CODES } from '@/components/common/CookingStyleSelect';
import { LoadingSpinner } from '@/components/common/LoadingSpinner';
import { getImageUrl } from '@/lib/utils/image';

// Loading fallback component
function CreateRecipeLoading() {
  return <LoadingSpinner />;
}

// Wrapper component with Suspense for useSearchParams
export default function CreateRecipePage() {
  return (
    <Suspense fallback={<CreateRecipeLoading />}>
      <CreateRecipeContent />
    </Suspense>
  );
}

// Limits matching Flutter app
const MAX_RECIPE_PHOTOS = 3;
const MAX_STEPS = 12;
const MAX_HASHTAGS = 5;
const MAX_HASHTAG_LENGTH = 30;

const INGREDIENT_LIMITS: Record<IngredientType, number> = {
  MAIN: 5,
  SECONDARY: 8,
  SEASONING: 10,
};

// Ingredient category config (labels are translated inside component)
interface IngredientCategoryConfig {
  value: IngredientType;
  labelKey: 'categoryMain' | 'categorySecondary' | 'categorySeasoning';
  addButtonKey: 'addMain' | 'addSecondary' | 'addSeasoning';
  max: number;
  icon: string;
  color: string;
  bgColor: string;
  borderColor: string;
}

const INGREDIENT_CATEGORY_CONFIGS: IngredientCategoryConfig[] = [
  {
    value: 'MAIN',
    labelKey: 'categoryMain',
    addButtonKey: 'addMain',
    max: 5,
    icon: '🍲',
    color: 'var(--primary)',
    bgColor: 'var(--primary-light)',
    borderColor: 'var(--primary)',
  },
  {
    value: 'SECONDARY',
    labelKey: 'categorySecondary',
    addButtonKey: 'addSecondary',
    max: 8,
    icon: '🥕',
    color: 'var(--success)',
    bgColor: '#E8F5E9',
    borderColor: 'var(--success)',
  },
  {
    value: 'SEASONING',
    labelKey: 'categorySeasoning',
    addButtonKey: 'addSeasoning',
    max: 10,
    icon: '🧂',
    color: 'var(--secondary)',
    bgColor: '#EFEBE9',
    borderColor: 'var(--secondary)',
  },
];

// Measurement unit config (labels are translated inside component using tUnits)
// The labelKey maps to keys in the 'units' translation namespace
type UnitLabelKey = 'cup' | 'tbsp' | 'tsp' | 'ml' | 'l' | 'flOz' | 'pint' | 'quart' | 'g' | 'kg' | 'oz' | 'lb' | 'piece' | 'clove' | 'bunch' | 'can' | 'package' | 'pinch' | 'dash' | 'toTaste';

interface MeasurementUnitConfig {
  value: MeasurementUnit | '';
  labelKey: UnitLabelKey | null; // null for the "Unit" placeholder which uses t('unit')
}

const MEASUREMENT_UNIT_CONFIGS: MeasurementUnitConfig[] = [
  { value: '', labelKey: null }, // Uses t('unit') for placeholder
  // Volume
  { value: 'CUP', labelKey: 'cup' },
  { value: 'TBSP', labelKey: 'tbsp' },
  { value: 'TSP', labelKey: 'tsp' },
  { value: 'ML', labelKey: 'ml' },
  { value: 'L', labelKey: 'l' },
  { value: 'FL_OZ', labelKey: 'flOz' },
  { value: 'PINT', labelKey: 'pint' },
  { value: 'QUART', labelKey: 'quart' },
  // Weight
  { value: 'G', labelKey: 'g' },
  { value: 'KG', labelKey: 'kg' },
  { value: 'OZ', labelKey: 'oz' },
  { value: 'LB', labelKey: 'lb' },
  // Count/Other
  { value: 'PIECE', labelKey: 'piece' },
  { value: 'CLOVE', labelKey: 'clove' },
  { value: 'BUNCH', labelKey: 'bunch' },
  { value: 'CAN', labelKey: 'can' },
  { value: 'PACKAGE', labelKey: 'package' },
  { value: 'PINCH', labelKey: 'pinch' },
  { value: 'DASH', labelKey: 'dash' },
  { value: 'TO_TASTE', labelKey: 'toTaste' },
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
  type: 'inherited' | 'uploaded';
  // For inherited photos
  inheritedUrl?: string;
  inheritedPublicId?: string; // The image public ID from parent recipe
  // For uploaded photos
  uploadedImage?: UploadedImage;
}

interface FormIngredient {
  id: string;
  name: string;
  quantity: string;  // Numeric quantity (max 4 chars)
  unit: MeasurementUnit | '';  // Measurement unit from dropdown
  type: IngredientType;
  isOriginal?: boolean; // True if inherited from parent recipe
  isDeleted?: boolean;  // True if marked for removal (soft delete)
}

interface FormStep {
  id: string;
  description: string;
  image: UploadedImage | null;
  inheritedImageUrl?: string | null; // Image URL from parent recipe (for display)
  inheritedImagePublicId?: string | null; // Image public ID from parent recipe (for submission)
  isOriginal?: boolean; // True if inherited from parent recipe
  isDeleted?: boolean;  // True if marked for removal (soft delete)
}

interface FormHashtag {
  id: string;
  name: string;
  isOriginal?: boolean; // True if inherited from parent recipe
  isDeleted?: boolean;  // True if marked for removal (soft delete)
}

function CreateRecipeContent() {
  const { isAuthenticated, isLoading: authLoading } = useAuth();
  const router = useRouter();
  const searchParams = useSearchParams();
  const params = useParams();
  const locale = params.locale as string;
  const cookingStyleOptions = useCookingStyleOptions();
  const tFilters = useTranslations('filters');
  const t = useTranslations('recipeCreate');
  const tUnits = useTranslations('units');
  const recipeImageInputRef = useRef<HTMLInputElement>(null);

  const stepImageInputRefs = useRef<Map<string, HTMLInputElement>>(new Map());

  // Variant mode state
  const parentPublicId = searchParams.get('parent');
  const [parentRecipe, setParentRecipe] = useState<RecipeDetail | null>(null);
  const [isLoadingParent, setIsLoadingParent] = useState(!!parentPublicId);
  const [changeReason, setChangeReason] = useState('');

  const isVariantMode = !!parentRecipe;

  // Form state
  const [title, setTitle] = useState('');
  const [description, setDescription] = useState('');
  const [foodName, setFoodName] = useState('');
  const [cookingStyle, setCookingStyle] = useState('');
  const [servings, setServings] = useState(2);
  const [cookingTimeRange, setCookingTimeRange] = useState<CookingTimeRange>('MIN_30_TO_60');
  const [hashtags, setHashtags] = useState<FormHashtag[]>([]);
  const [hashtagInput, setHashtagInput] = useState('');
  const [photos, setPhotos] = useState<FormPhoto[]>([]);
  const [ingredients, setIngredients] = useState<FormIngredient[]>([
    { id: crypto.randomUUID(), name: '', quantity: '', unit: '', type: 'MAIN' },
  ]);
  const [steps, setSteps] = useState<FormStep[]>([
    { id: crypto.randomUUID(), description: '', image: null },
  ]);
  const [isPrivate, setIsPrivate] = useState(false);

  // UI state
  const [isSubmitting, setIsSubmitting] = useState(false);
  const [error, setError] = useState<string | null>(null);

  // Redirect if not authenticated
  useEffect(() => {
    if (!authLoading && !isAuthenticated) {
      const redirectUrl = parentPublicId
        ? `/recipes/create?parent=${parentPublicId}`
        : '/recipes/create';
      router.push(`/login?redirect=${encodeURIComponent(redirectUrl)}`);
    }
  }, [isAuthenticated, authLoading, router, parentPublicId]);

  // Fetch parent recipe for variant mode
  useEffect(() => {
    if (!parentPublicId || !isAuthenticated) return;

    const fetchParent = async () => {
      try {
        setIsLoadingParent(true);
        const parent = await getRecipeDetail(parentPublicId, locale);
        setParentRecipe(parent);

        // Pre-populate form fields from parent
        setDescription(parent.description);
        setFoodName(parent.foodName);
        setCookingStyle(parent.cookingStyle);
        setServings(parent.servings);
        setCookingTimeRange(parent.cookingTimeRange as CookingTimeRange);

        // Pre-populate ingredients (marked as original/inherited)
        const inheritedIngredients: FormIngredient[] = parent.ingredients.map((ing) => ({
          id: crypto.randomUUID(),
          name: ing.name,
          quantity: ing.quantity?.toString() ?? '',
          unit: (ing.unit ?? '') as MeasurementUnit | '',
          type: ing.type,
          isOriginal: true,
          isDeleted: false,
        }));
        setIngredients(inheritedIngredients);

        // Pre-populate steps (marked as original/inherited)
        const inheritedSteps: FormStep[] = parent.steps.map((step) => ({
          id: crypto.randomUUID(),
          description: step.description,
          image: null, // New uploaded image (null until user uploads)
          inheritedImageUrl: step.imageUrl, // Show parent's image
          inheritedImagePublicId: step.imagePublicId, // For submission
          isOriginal: true,
          isDeleted: false,
        }));
        setSteps(inheritedSteps);

        // Pre-populate hashtags (marked as original/inherited)
        const inheritedHashtags: FormHashtag[] = parent.hashtags.map((h) => ({
          id: crypto.randomUUID(),
          name: h.name,
          isOriginal: true,
          isDeleted: false,
        }));
        setHashtags(inheritedHashtags);

        // Pre-populate photos from parent recipe (as inherited)
        const inheritedPhotos: FormPhoto[] = parent.images.map((img) => ({
          id: crypto.randomUUID(),
          type: 'inherited' as const,
          inheritedUrl: img.imageUrl,
          inheritedPublicId: img.imagePublicId,
        }));
        setPhotos(inheritedPhotos);
      } catch (err) {
        console.error('Failed to fetch parent recipe:', err);
        setError(t('errorLoadParent'));
      } finally {
        setIsLoadingParent(false);
      }
    };

    fetchParent();
  }, [parentPublicId, isAuthenticated, t, locale]);

  // Set default cooking style based on browser locale (only for non-variant mode)
  useEffect(() => {
    if (!cookingStyle && !parentPublicId) {
      const defaultStyle = getDefaultCookingStyle();
      // Check if the detected style is in our list, otherwise use 'international'
      const isValid = COOKING_STYLE_CODES.includes(defaultStyle as typeof COOKING_STYLE_CODES[number]);
      setCookingStyle(isValid ? defaultStyle : 'international');
    }
  }, [cookingStyle, parentPublicId]);

  // Handle recipe image selection
  const handleRecipeImageSelect = async (e: React.ChangeEvent<HTMLInputElement>) => {
    const files = Array.from(e.target.files || []);
    if (files.length === 0) return;

    // Calculate remaining slots based on current photos count
    const remaining = MAX_RECIPE_PHOTOS - photos.length;
    const filesToAdd = files.slice(0, remaining);

    // Create new photo entries with uploading state
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

    // Upload each image
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

  // Handle step image selection
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
      prev.map((s) => (s.id === stepId ? { ...s, image: newImage } : s))
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

  // Remove step image
  const removeStepImage = (stepId: string) => {
    setSteps((prev) =>
      prev.map((s) => {
        if (s.id === stepId && s.image) {
          URL.revokeObjectURL(s.image.preview);
          return { ...s, image: null };
        }
        return s;
      })
    );
  };

  // Get count of ingredients by type
  const getIngredientCountByType = (type: IngredientType) => {
    return ingredients.filter((ing) => ing.type === type).length;
  };

  // Ingredient handlers
  const addIngredient = (type: IngredientType) => {
    const currentCount = getIngredientCountByType(type);
    if (currentCount >= INGREDIENT_LIMITS[type]) return;

    setIngredients((prev) => [
      ...prev,
      { id: crypto.randomUUID(), name: '', quantity: '', unit: '', type },
    ]);
  };

  const updateIngredient = (id: string, field: keyof FormIngredient, value: string) => {
    setIngredients((prev) =>
      prev.map((ing) => {
        if (ing.id !== id) return ing;
        // For quantity field, only allow numeric input (digits and decimal)
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
        // Soft delete: mark as deleted but keep in list
        return prev.map((ing) =>
          ing.id === id ? { ...ing, isDeleted: true } : ing
        );
      } else {
        // Hard delete: remove from list
        return prev.filter((ing) => ing.id !== id);
      }
    });
  };

  // Step handlers
  const addStep = () => {
    if (steps.length >= MAX_STEPS) return;
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
    // Count non-deleted steps to check if we can remove
    const nonDeletedCount = steps.filter((s) => !s.isDeleted).length;
    if (nonDeletedCount <= 1) return;

    setSteps((prev) => {
      const step = prev.find((s) => s.id === id);
      if (step?.isOriginal) {
        // Soft delete: mark as deleted but keep in list
        // Revoke image URL if present
        if (step.image) URL.revokeObjectURL(step.image.preview);
        return prev.map((s) =>
          s.id === id ? { ...s, isDeleted: true, image: null } : s
        );
      } else {
        // Hard delete: remove from list
        if (step?.image) URL.revokeObjectURL(step.image.preview);
        return prev.filter((s) => s.id !== id);
      }
    });
  };

  // Restore functions for soft-deleted items
  const restoreIngredient = (id: string) => {
    setIngredients((prev) =>
      prev.map((ing) =>
        ing.id === id ? { ...ing, isDeleted: false } : ing
      )
    );
  };

  const restoreStep = (id: string) => {
    setSteps((prev) =>
      prev.map((step) =>
        step.id === id ? { ...step, isDeleted: false } : step
      )
    );
  };

  // Drag and drop state for steps
  const [draggedStepId, setDraggedStepId] = useState<string | null>(null);
  const [dragOverStepId, setDragOverStepId] = useState<string | null>(null);

  const handleStepDragStart = (e: React.DragEvent, stepId: string) => {
    setDraggedStepId(stepId);
    e.dataTransfer.effectAllowed = 'move';
    e.dataTransfer.setData('text/plain', stepId);
  };

  const handleStepDragOver = (e: React.DragEvent, stepId: string) => {
    e.preventDefault();
    e.dataTransfer.dropEffect = 'move';
    if (stepId !== draggedStepId) {
      setDragOverStepId(stepId);
    }
  };

  const handleStepDragLeave = () => {
    setDragOverStepId(null);
  };

  const handleStepDrop = (e: React.DragEvent, targetStepId: string) => {
    e.preventDefault();
    if (!draggedStepId || draggedStepId === targetStepId) {
      setDraggedStepId(null);
      setDragOverStepId(null);
      return;
    }

    setSteps((prev) => {
      // Work with non-deleted steps only for reordering
      const activeSteps = prev.filter((s) => !s.isDeleted);
      const deletedSteps = prev.filter((s) => s.isDeleted);

      const draggedIndex = activeSteps.findIndex((s) => s.id === draggedStepId);
      const targetIndex = activeSteps.findIndex((s) => s.id === targetStepId);

      if (draggedIndex === -1 || targetIndex === -1) return prev;

      // Remove dragged item and insert at target position
      const newActiveSteps = [...activeSteps];
      const [removed] = newActiveSteps.splice(draggedIndex, 1);
      newActiveSteps.splice(targetIndex, 0, removed);

      // Combine back with deleted steps (keep deleted at end)
      return [...newActiveSteps, ...deletedSteps];
    });

    setDraggedStepId(null);
    setDragOverStepId(null);
  };

  const handleStepDragEnd = () => {
    setDraggedStepId(null);
    setDragOverStepId(null);
  };

  // Drag and drop state for photos
  const [draggedPhotoId, setDraggedPhotoId] = useState<string | null>(null);
  const [dragOverPhotoId, setDragOverPhotoId] = useState<string | null>(null);

  const handlePhotoDragStart = (e: React.DragEvent, photoId: string) => {
    setDraggedPhotoId(photoId);
    e.dataTransfer.effectAllowed = 'move';
    e.dataTransfer.setData('text/plain', photoId);
  };

  const handlePhotoDragOver = (e: React.DragEvent, photoId: string) => {
    e.preventDefault();
    e.dataTransfer.dropEffect = 'move';
    if (photoId !== draggedPhotoId) {
      setDragOverPhotoId(photoId);
    }
  };

  const handlePhotoDragLeave = () => {
    setDragOverPhotoId(null);
  };

  const handlePhotoDrop = (e: React.DragEvent, targetPhotoId: string) => {
    e.preventDefault();
    if (!draggedPhotoId || draggedPhotoId === targetPhotoId) {
      setDraggedPhotoId(null);
      setDragOverPhotoId(null);
      return;
    }

    setPhotos((prev) => {
      const draggedIndex = prev.findIndex((p) => p.id === draggedPhotoId);
      const targetIndex = prev.findIndex((p) => p.id === targetPhotoId);

      if (draggedIndex === -1 || targetIndex === -1) return prev;

      const newPhotos = [...prev];
      const [removed] = newPhotos.splice(draggedIndex, 1);
      newPhotos.splice(targetIndex, 0, removed);

      return newPhotos;
    });

    setDraggedPhotoId(null);
    setDragOverPhotoId(null);
  };

  const handlePhotoDragEnd = () => {
    setDraggedPhotoId(null);
    setDragOverPhotoId(null);
  };

  // Remove photo handler
  const removePhoto = (photoId: string) => {
    setPhotos((prev) => {
      const photo = prev.find((p) => p.id === photoId);
      if (photo?.type === 'uploaded' && photo.uploadedImage) {
        URL.revokeObjectURL(photo.uploadedImage.preview);
      }
      return prev.filter((p) => p.id !== photoId);
    });
  };

  // Hashtag handlers
  const normalizeHashtag = (tag: string): string => {
    return tag
      .toLowerCase()
      .trim()
      .replace(/^#/, '')  // Remove leading #
      .replace(/\s+/g, '-')  // Replace spaces with hyphens
      .slice(0, MAX_HASHTAG_LENGTH);
  };

  const addHashtag = () => {
    if (!hashtagInput.trim()) return;
    // Count active (non-deleted) hashtags
    const activeCount = hashtags.filter((h) => !h.isDeleted).length;
    if (activeCount >= MAX_HASHTAGS) return;

    const normalized = normalizeHashtag(hashtagInput);
    if (!normalized) return;
    // Check if hashtag already exists (and is not deleted)
    if (hashtags.some((h) => h.name === normalized && !h.isDeleted)) {
      setHashtagInput('');
      return;
    }

    // Check if it was previously deleted - restore it instead of adding new
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
        // Soft delete: mark as deleted but keep in list
        return prev.map((h) => (h.id === id ? { ...h, isDeleted: true } : h));
      } else {
        // Hard delete: remove from list
        return prev.filter((h) => h.id !== id);
      }
    });
  };

  const restoreHashtag = (id: string) => {
    setHashtags((prev) =>
      prev.map((h) => (h.id === id ? { ...h, isDeleted: false } : h))
    );
  };

  // Compute change diff for variant mode using isOriginal/isDeleted flags
  const computeChangeDiff = useCallback(() => {
    if (!isVariantMode) return null;

    // Removed = original items marked as deleted
    const removedIngredients = ingredients
      .filter((ing) => ing.isOriginal && ing.isDeleted)
      .map((ing) => ing.name.trim());

    // Added = non-original items that are not deleted (with valid names)
    const addedIngredients = ingredients
      .filter((ing) => !ing.isOriginal && !ing.isDeleted && ing.name.trim())
      .map((ing) => ing.name.trim());

    // Same logic for steps
    const removedSteps = steps
      .filter((step) => step.isOriginal && step.isDeleted)
      .map((step) => step.description.trim());

    const addedSteps = steps
      .filter((step) => !step.isOriginal && !step.isDeleted && step.description.trim())
      .map((step) => step.description.trim());

    return {
      ingredients: {
        removed: removedIngredients,
        added: addedIngredients,
      },
      steps: {
        removed: removedSteps,
        added: addedSteps,
      },
    };
  }, [isVariantMode, ingredients, steps]);

  // Handle form submission
  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    setError(null);

    // Validation
    if (!title.trim()) {
      setError(t('errorTitle'));
      return;
    }

    if (!foodName.trim()) {
      setError(t('errorFoodName'));
      return;
    }

    if (!cookingStyle) {
      setError(t('errorCookingStyle'));
      return;
    }

    // Variant-specific validation
    if (isVariantMode && !changeReason.trim()) {
      setError(t('errorChangeReason'));
      return;
    }

    // Validate photos
    if (photos.length === 0) {
      setError(t('errorPhoto'));
      return;
    }

    // Check if any uploaded photos are still uploading
    const uploadingPhotos = photos.filter(
      (p) => p.type === 'uploaded' && p.uploadedImage?.uploading
    );
    if (uploadingPhotos.length > 0) {
      setError(t('errorUploading'));
      return;
    }

    // Check for failed uploads
    const failedPhotos = photos.filter(
      (p) => p.type === 'uploaded' && p.uploadedImage?.error
    );
    if (failedPhotos.length > 0) {
      setError(t('errorUploadFailed'));
      return;
    }

    // Filter out deleted items and validate
    const validIngredients = ingredients.filter((ing) => ing.name.trim() && !ing.isDeleted);
    if (validIngredients.length === 0) {
      setError(t('errorIngredients'));
      return;
    }

    const validSteps = steps.filter((step) => step.description.trim() && !step.isDeleted);
    if (validSteps.length === 0) {
      setError(t('errorSteps'));
      return;
    }

    // Check if any active step images are uploading
    const uploadingStepImages = validSteps.some((step) => step.image?.uploading);
    if (uploadingStepImages) {
      setError(t('errorStepUploading'));
      return;
    }

    const failedStepImages = validSteps.filter((step) => step.image?.error);
    if (failedStepImages.length > 0) {
      setError(t('errorStepUploadFailed'));
      return;
    }

    setIsSubmitting(true);

    try {
      // Get image public IDs from all photos (inherited + uploaded) in order
      const imagePublicIds = photos
        .map((p) => {
          if (p.type === 'inherited' && p.inheritedPublicId) {
            return p.inheritedPublicId;
          }
          if (p.type === 'uploaded' && p.uploadedImage?.publicId) {
            return p.uploadedImage.publicId;
          }
          return null;
        })
        .filter((id): id is string => id !== null);

      const ingredientsData: IngredientDto[] = validIngredients.map((ing) => ({
        name: ing.name.trim(),
        quantity: ing.quantity ? parseFloat(ing.quantity) : null,
        unit: (ing.unit || null) as IngredientDto['unit'],
        type: ing.type,
      }));

      const stepsData = validSteps.map((step, index) => ({
        stepNumber: index + 1,
        description: step.description.trim(),
        imagePublicId: step.image?.publicId || step.inheritedImagePublicId || null,
      }));

      const recipe = await createRecipe({
        title: title.trim(),
        description: description.trim() || undefined,
        // For variants, use the parent's food; for new recipes, create new food
        newFoodName: isVariantMode ? undefined : foodName.trim(),
        food1MasterPublicId: isVariantMode ? parentRecipe?.foodMasterPublicId : undefined,
        cookingStyle,
        ingredients: ingredientsData,
        steps: stepsData,
        imagePublicIds,
        hashtags: (() => {
          const activeHashtags = hashtags.filter((h) => !h.isDeleted).map((h) => h.name);
          return activeHashtags.length > 0 ? activeHashtags : undefined;
        })(),
        servings,
        cookingTimeRange,
        isPrivate,
        // Variant-specific fields
        parentPublicId: isVariantMode ? parentRecipe?.publicId : undefined,
        rootPublicId: isVariantMode
          ? (parentRecipe?.rootInfo?.publicId ?? parentRecipe?.publicId)
          : undefined,
        changeReason: isVariantMode ? changeReason.trim() : undefined,
        changeDiff: computeChangeDiff() ?? undefined,
      });

      router.push(`/recipes/${recipe.publicId}`);
    } catch (err) {
      console.error('Failed to create recipe:', err);
      setError(t('errorCreate'));
    } finally {
      setIsSubmitting(false);
    }
  };

  // Show loading state while auth is loading, redirecting to login, or loading parent
  if (authLoading || !isAuthenticated || isLoadingParent) {
    return <LoadingSpinner />;
  }

  return (
    <main className="min-h-screen bg-[var(--background)]">
      <div className="max-w-3xl mx-auto px-4 py-8">
        {/* Header */}
        <div className="mb-8">
          <Link
            href={isVariantMode ? `/recipes/${parentRecipe.publicId}` : '/recipes'}
            className="text-[var(--text-secondary)] hover:text-[var(--primary)] inline-flex items-center gap-1 mb-4"
          >
            <svg className="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M15 19l-7-7 7-7" />
            </svg>
            {isVariantMode ? t('backToRecipe') : t('backToRecipes')}
          </Link>
          <h1 className="text-3xl font-bold text-[var(--text-primary)]">
            {isVariantMode ? t('titleVariant') : t('title')}
          </h1>
          <p className="text-[var(--text-secondary)] mt-2">
            {isVariantMode ? t('subtitleVariant') : t('subtitle')}
          </p>
        </div>

        {/* Variant Mode Banner */}
        {isVariantMode && (
          <div className="bg-[var(--highlight-bg)] border border-[var(--primary-light)] rounded-xl p-4 mb-8">
            <div className="flex items-center gap-2 text-[var(--primary)]">
              <svg className="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M7 8h10M7 12h4m1 8l-4-4H5a2 2 0 01-2-2V6a2 2 0 012-2h14a2 2 0 012 2v8a2 2 0 01-2 2h-3l-4 4z" />
              </svg>
              <span className="font-medium">{t('variationOf')}</span>
            </div>
            <Link
              href={`/recipes/${parentRecipe.publicId}`}
              className="text-lg font-semibold text-[var(--text-primary)] hover:text-[var(--primary)] mt-1 block"
            >
              {parentRecipe.title}
            </Link>
            <p className="text-sm text-[var(--text-secondary)] mt-1">
              {t('variationHelp')}
            </p>
          </div>
        )}

        <form onSubmit={handleSubmit} className="space-y-8">
          {/* Recipe Photos Section */}
          <section className="bg-[var(--surface)] rounded-2xl p-6 border border-[var(--border)]">
            <h2 className="text-lg font-semibold text-[var(--text-primary)] mb-2">
              {t('photos')} <span className="text-[var(--error)]">*</span>
            </h2>
            <p className="text-sm text-[var(--text-secondary)] mb-2">
              {isVariantMode && photos.some((p) => p.type === 'inherited')
                ? t('photosInherited', { max: MAX_RECIPE_PHOTOS })
                : t('photosRequired', { max: MAX_RECIPE_PHOTOS })}
            </p>
            <p className="text-xs text-[var(--text-secondary)] mb-4 flex items-center gap-1">
              <svg className="w-3.5 h-3.5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M4 8h16M4 16h16" />
              </svg>
              {t('dragToReorder')}
            </p>
            <div className="flex gap-3 flex-wrap">
              {photos.map((photo, index) => {
                const isDragging = draggedPhotoId === photo.id;
                const isDragOver = dragOverPhotoId === photo.id;
                const isInherited = photo.type === 'inherited';
                const imageUrl = isInherited ? photo.inheritedUrl : photo.uploadedImage?.preview;
                const isUploading = !isInherited && photo.uploadedImage?.uploading;
                const hasError = !isInherited && photo.uploadedImage?.error;

                return (
                  <div
                    key={photo.id}
                    draggable
                    onDragStart={(e) => handlePhotoDragStart(e, photo.id)}
                    onDragOver={(e) => handlePhotoDragOver(e, photo.id)}
                    onDragLeave={handlePhotoDragLeave}
                    onDrop={(e) => handlePhotoDrop(e, photo.id)}
                    onDragEnd={handlePhotoDragEnd}
                    className={`relative w-28 h-28 rounded-lg overflow-hidden bg-[var(--background)] cursor-grab active:cursor-grabbing transition-all ${
                      isDragging ? 'opacity-50' : ''
                    } ${isDragOver ? 'ring-2 ring-[var(--primary)] ring-offset-2' : ''}`}
                  >
                    <Image
                      src={imageUrl!}
                      alt={`Photo ${index + 1}`}
                      fill
                      className="object-cover pointer-events-none"
                      sizes="112px"
                      unoptimized
                    />
                    {/* Original badge for inherited images */}
                    {isInherited && (
                      <span className="absolute bottom-1 left-1 text-[8px] px-1.5 py-0.5 bg-[var(--primary-light)]/30 text-[var(--primary)] rounded border border-[var(--primary-light)] font-medium">
                        {t('original')}
                      </span>
                    )}
                    {/* Uploading indicator */}
                    {isUploading && (
                      <div className="absolute inset-0 bg-black/50 flex items-center justify-center">
                        <div className="animate-spin w-6 h-6 border-2 border-white border-t-transparent rounded-full" />
                      </div>
                    )}
                    {/* Error indicator */}
                    {hasError && (
                      <div className="absolute inset-0 bg-[var(--error)]/50 flex items-center justify-center">
                        <svg className="w-6 h-6 text-white" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                          <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M12 9v2m0 4h.01m-6.938 4h13.856c1.54 0 2.502-1.667 1.732-3L13.732 4c-.77-1.333-2.694-1.333-3.464 0L3.34 16c-.77 1.333.192 3 1.732 3z" />
                        </svg>
                      </div>
                    )}
                    {/* Remove button */}
                    <button
                      type="button"
                      onClick={() => removePhoto(photo.id)}
                      className="absolute top-1 right-1 p-1 bg-black/50 rounded-full hover:bg-black/70 transition-colors"
                    >
                      <svg className="w-4 h-4 text-white" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                        <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M6 18L18 6M6 6l12 12" />
                      </svg>
                    </button>
                  </div>
                );
              })}
              {/* Add button */}
              {photos.length < MAX_RECIPE_PHOTOS && (
                <button
                  type="button"
                  onClick={() => recipeImageInputRef.current?.click()}
                  className="w-28 h-28 rounded-lg border-2 border-dashed border-[var(--border)] hover:border-[var(--primary)] transition-colors flex items-center justify-center"
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
              onChange={handleRecipeImageSelect}
              className="hidden"
            />
          </section>

          {/* Basic Info Section */}
          <section className="bg-[var(--surface)] rounded-2xl p-6 border border-[var(--border)]">
            <h2 className="text-lg font-semibold text-[var(--text-primary)] mb-4">
              {t('basicInfo')}
            </h2>
            <div className="space-y-4">
              {/* Food Name */}
              <div>
                <label htmlFor="foodName" className="block text-sm font-medium text-[var(--text-primary)] mb-2">
                  {t('foodName')} <span className="text-[var(--error)]">*</span>
                  {isVariantMode && (
                    <span className="ml-2 text-xs font-normal text-[var(--text-secondary)]">
                      {t('inheritedFromOriginal')}
                    </span>
                  )}
                </label>
                <input
                  id="foodName"
                  type="text"
                  value={foodName}
                  onChange={(e) => !isVariantMode && setFoodName(e.target.value)}
                  maxLength={50}
                  readOnly={isVariantMode}
                  className={`w-full px-4 py-3 border rounded-xl focus:outline-none ${
                    isVariantMode
                      ? 'bg-[var(--surface)] border-[var(--border)] text-[var(--text-secondary)] cursor-not-allowed'
                      : 'bg-[var(--background)] border-[var(--border)] focus:border-[var(--primary)]'
                  }`}
                  placeholder={t('foodNamePlaceholder')}
                />
                <div className="flex justify-between mt-1">
                  <p className="text-xs text-[var(--text-secondary)]">
                    {isVariantMode ? t('foodNameInheritedHelp') : t('foodNameHelp')}
                  </p>
                  {!isVariantMode && (
                    <p className="text-xs text-[var(--text-secondary)]">
                      {foodName.length}/50
                    </p>
                  )}
                </div>
              </div>

              {/* Recipe Title (non-variant mode only) */}
              {!isVariantMode && (
                <div>
                  <label htmlFor="title" className="block text-sm font-medium text-[var(--text-primary)] mb-2">
                    {t('recipeTitle')} <span className="text-[var(--error)]">*</span>
                  </label>
                  <input
                    id="title"
                    type="text"
                    value={title}
                    onChange={(e) => setTitle(e.target.value)}
                    maxLength={200}
                    className="w-full px-4 py-3 bg-[var(--background)] border border-[var(--border)] rounded-xl focus:outline-none focus:border-[var(--primary)]"
                    placeholder={t('recipeTitlePlaceholder')}
                  />
                  <div className="flex justify-between mt-1">
                    <p className="text-xs text-[var(--text-secondary)]">
                      {t('recipeTitleHelp')}
                    </p>
                    <p className="text-xs text-[var(--text-secondary)]">
                      {title.length}/200
                    </p>
                  </div>
                </div>
              )}

              {/* Description */}
              <div>
                <label htmlFor="description" className="block text-sm font-medium text-[var(--text-primary)] mb-2">
                  {t('description')}
                  {isVariantMode && (
                    <span className="ml-2 text-xs font-normal text-[var(--text-secondary)]">
                      {t('inheritedFromOriginal')}
                    </span>
                  )}
                </label>
                <textarea
                  id="description"
                  value={description}
                  onChange={(e) => !isVariantMode && setDescription(e.target.value)}
                  maxLength={2000}
                  rows={3}
                  readOnly={isVariantMode}
                  className={`w-full px-4 py-3 border rounded-xl focus:outline-none resize-none ${
                    isVariantMode
                      ? 'bg-[var(--surface)] border-[var(--border)] text-[var(--text-secondary)] cursor-not-allowed'
                      : 'bg-[var(--background)] border-[var(--border)] focus:border-[var(--primary)]'
                  }`}
                  placeholder={t('descriptionPlaceholder')}
                />
                {!isVariantMode && (
                  <p className="text-xs text-[var(--text-secondary)] mt-1 text-right">
                    {description.length}/2000
                  </p>
                )}
              </div>

              {/* Culinary Locale & Servings Row */}
              <div className="grid grid-cols-2 gap-4">
                <div>
                  <label className="block text-sm font-medium text-[var(--text-primary)] mb-2">
                    {t('cookingStyle')} <span className="text-[var(--error)]">*</span>
                  </label>
                  <CookingStyleSelect
                    value={cookingStyle}
                    onChange={setCookingStyle}
                    options={cookingStyleOptions}
                    placeholder={t('selectCookingStyle')}
                  />
                </div>

                <div>
                  <label htmlFor="servings" className="block text-sm font-medium text-[var(--text-primary)] mb-2">
                    {t('servings')}
                  </label>
                  <input
                    id="servings"
                    type="number"
                    min={1}
                    max={50}
                    value={servings}
                    onChange={(e) => setServings(parseInt(e.target.value) || 1)}
                    className="w-full px-4 py-3 bg-[var(--background)] border border-[var(--border)] rounded-xl focus:outline-none focus:border-[var(--primary)]"
                  />
                </div>
              </div>

              {/* Cooking Time */}
              <div>
                <label htmlFor="cookingTime" className="block text-sm font-medium text-[var(--text-primary)] mb-2">
                  {t('cookingTime')}
                </label>
                <select
                  id="cookingTime"
                  value={cookingTimeRange}
                  onChange={(e) => setCookingTimeRange(e.target.value as CookingTimeRange)}
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
          </section>

          {/* Ingredients Section */}
          <section className="bg-[var(--surface)] rounded-2xl p-6 border border-[var(--border)]">
            <h2 className="text-lg font-semibold text-[var(--text-primary)] mb-4">
              {t('ingredients')} <span className="text-[var(--error)]">*</span>
            </h2>
            <p className="text-sm text-[var(--text-secondary)] mb-4">
              {t('ingredientsHelp')}
            </p>

            {/* Ingredient Categories */}
            <div className="space-y-6">
              {INGREDIENT_CATEGORY_CONFIGS.map((category) => {
                const categoryIngredients = ingredients.filter((ing) => ing.type === category.value);
                const activeIngredients = categoryIngredients.filter((ing) => !ing.isDeleted);
                const deletedIngredients = categoryIngredients.filter((ing) => ing.isDeleted);
                const activeCount = activeIngredients.length;
                const canAdd = activeCount < category.max;

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
                      <h3 className="text-sm font-semibold flex items-center gap-2" style={{ color: category.color }}>
                        <span className="text-base">{category.icon}</span>
                        {t(category.labelKey)}
                      </h3>
                      <span
                        className="text-xs font-medium px-2 py-0.5 rounded-full"
                        style={{ backgroundColor: category.bgColor, color: category.color }}
                      >
                        {activeCount}/{category.max}
                      </span>
                    </div>

                    {/* Active ingredient rows for this category */}
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
                              {t('inherited')}
                            </span>
                          )}
                          <input
                            type="text"
                            value={ing.name}
                            onChange={(e) => !ing.isOriginal && updateIngredient(ing.id, 'name', e.target.value)}
                            maxLength={50}
                            readOnly={ing.isOriginal}
                            className={`flex-1 px-3 py-2 border rounded-lg text-sm ${
                              ing.isOriginal
                                ? 'bg-[var(--surface)] border-[var(--border)] text-[var(--text-secondary)] cursor-not-allowed'
                                : 'bg-[var(--background)] border-[var(--border)] focus:outline-none focus:border-[var(--primary)]'
                            }`}
                            placeholder={t('ingredientName')}
                          />
                          <input
                            type="text"
                            inputMode="decimal"
                            value={ing.quantity}
                            onChange={(e) => !ing.isOriginal && updateIngredient(ing.id, 'quantity', e.target.value)}
                            readOnly={ing.isOriginal}
                            className={`w-16 px-2 py-2 border rounded-lg text-sm text-center ${
                              ing.isOriginal
                                ? 'bg-[var(--surface)] border-[var(--border)] text-[var(--text-secondary)] cursor-not-allowed'
                                : 'bg-[var(--background)] border-[var(--border)] focus:outline-none focus:border-[var(--primary)]'
                            }`}
                            placeholder={t('qty')}
                          />
                          <select
                            value={ing.unit}
                            onChange={(e) => !ing.isOriginal && updateIngredient(ing.id, 'unit', e.target.value)}
                            disabled={ing.isOriginal}
                            className={`w-24 px-2 py-2 border rounded-lg text-sm ${
                              ing.isOriginal
                                ? 'bg-[var(--surface)] border-[var(--border)] text-[var(--text-secondary)] cursor-not-allowed'
                                : 'bg-[var(--background)] border-[var(--border)] focus:outline-none focus:border-[var(--primary)]'
                            }`}
                          >
                            {MEASUREMENT_UNIT_CONFIGS.map((unit) => (
                              <option key={unit.value} value={unit.value}>
                                {unit.labelKey ? tUnits(unit.labelKey) : t('unit')}
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

                    {/* Deleted ingredients section (only in variant mode) */}
                    {isVariantMode && deletedIngredients.length > 0 && (
                      <div className="mt-3 border border-dashed border-[var(--border)] rounded-lg p-3 bg-[var(--background)]">
                        <div className="flex items-center gap-2 text-xs text-[var(--text-secondary)] mb-2">
                          <svg className="w-3.5 h-3.5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                            <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M19 7l-.867 12.142A2 2 0 0116.138 21H7.862a2 2 0 01-1.995-1.858L5 7m5 4v6m4-6v6m1-10V4a1 1 0 00-1-1h-4a1 1 0 00-1 1v3M4 7h16" />
                          </svg>
                          <span>{t('removed')} ({deletedIngredients.length})</span>
                        </div>
                        <div className="space-y-1.5">
                          {deletedIngredients.map((ing) => {
                            const unitConfig = MEASUREMENT_UNIT_CONFIGS.find((u) => u.value === ing.unit);
                            const unitLabel = unitConfig?.labelKey ? tUnits(unitConfig.labelKey) : '';
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
                                  className="text-xs px-2 py-1 text-[var(--primary)] hover:bg-[var(--primary-light)]/10 rounded transition-colors inline-flex items-center gap-1"
                                >
                                  <svg className="w-3 h-3" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                                    <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M3 10h10a8 8 0 018 8v2M3 10l6 6m-6-6l6-6" />
                                  </svg>
                                  {t('restore')}
                                </button>
                              </div>
                            );
                          })}
                        </div>
                      </div>
                    )}

                    {/* Add button for this category */}
                    {canAdd ? (
                      <button
                        type="button"
                        onClick={() => addIngredient(category.value)}
                        className="mt-3 px-3 py-1.5 text-xs text-[var(--primary)] hover:bg-[var(--primary-light)]/10 rounded-lg transition-colors inline-flex items-center gap-1"
                      >
                        <svg className="w-3 h-3" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                          <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M12 4v16m8-8H4" />
                        </svg>
                        {t(category.addButtonKey)}
                      </button>
                    ) : (
                      <p className="mt-3 text-xs text-[var(--text-secondary)]">
                        {t('maxItemsReached', { max: category.max })}
                      </p>
                    )}
                  </div>
                );
              })}
            </div>
          </section>

          {/* Steps Section */}
          <section className="bg-[var(--surface)] rounded-2xl p-6 border border-[var(--border)]">
            {(() => {
              const activeSteps = steps.filter((s) => !s.isDeleted);
              const deletedSteps = steps.filter((s) => s.isDeleted);
              const activeCount = activeSteps.length;
              const canAdd = activeCount < MAX_STEPS;
              const canDelete = activeCount > 1;

              return (
                <>
                  <div className="flex justify-between items-center mb-2">
                    <h2 className="text-lg font-semibold text-[var(--text-primary)]">
                      {t('cookingSteps')} <span className="text-[var(--error)]">*</span>
                    </h2>
                    <span className="text-sm text-[var(--text-secondary)]">
                      {activeCount}/{MAX_STEPS}
                    </span>
                  </div>
                  <p className="text-xs text-[var(--text-secondary)] mb-4 flex items-center gap-1">
                    <svg className="w-3.5 h-3.5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                      <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M4 8h16M4 16h16" />
                    </svg>
                    {t('dragStepsToReorder')}
                  </p>
                  <div className="space-y-4">
                    {activeSteps.map((step, index) => {
                      const isDragging = draggedStepId === step.id;
                      const isDragOver = dragOverStepId === step.id;
                      // Show inherited image if no new uploaded image exists
                      const displayImageUrl = step.image?.preview || (step.inheritedImageUrl ? getImageUrl(step.inheritedImageUrl) : null);
                      const isInheritedImage = !step.image && !!step.inheritedImageUrl;

                      return (
                        <div
                          key={step.id}
                          draggable
                          onDragStart={(e) => handleStepDragStart(e, step.id)}
                          onDragOver={(e) => handleStepDragOver(e, step.id)}
                          onDragLeave={handleStepDragLeave}
                          onDrop={(e) => handleStepDrop(e, step.id)}
                          onDragEnd={handleStepDragEnd}
                          className={`flex gap-3 items-start p-3 rounded-lg transition-all ${
                            step.isOriginal ? 'border-l-2 border-dashed border-[var(--primary-light)]' : ''
                          } ${isDragging ? 'opacity-50 bg-[var(--background)]' : ''} ${
                            isDragOver ? 'bg-[var(--primary-light)]/10 border-2 border-dashed border-[var(--primary)]' : 'border-2 border-transparent'
                          }`}
                        >
                          {/* Drag Handle */}
                          <div className="flex flex-col items-center gap-1 cursor-grab active:cursor-grabbing">
                            <svg className="w-5 h-5 text-[var(--text-secondary)]" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                              <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M4 8h16M4 16h16" />
                            </svg>
                            <div className="w-8 h-8 rounded-full bg-[var(--primary)] text-white flex items-center justify-center flex-shrink-0 text-sm font-medium">
                              {index + 1}
                            </div>
                          </div>
                          <div className="flex-1 space-y-2">
                            {step.isOriginal && (
                              <span className="text-[10px] px-1.5 py-0.5 bg-[var(--primary-light)]/20 text-[var(--primary)] rounded inline-block mb-1">
                                {t('inherited')}
                              </span>
                            )}
                            <div>
                              <textarea
                                value={step.description}
                                onChange={(e) => !step.isOriginal && updateStep(step.id, e.target.value)}
                                maxLength={2000}
                                rows={3}
                                readOnly={step.isOriginal}
                                className={`w-full px-3 py-2 border rounded-lg text-sm resize-none ${
                                  step.isOriginal
                                    ? 'bg-[var(--surface)] border-[var(--border)] text-[var(--text-secondary)] cursor-not-allowed'
                                    : 'bg-[var(--background)] border-[var(--border)] focus:outline-none focus:border-[var(--primary)]'
                                }`}
                                placeholder={t('describeStep')}
                              />
                              <p className="text-xs text-[var(--text-secondary)] mt-1 text-right">
                                {step.description.length}/2000
                              </p>
                            </div>
                            {/* Step Image */}
                            <div className="flex items-center gap-2">
                              {displayImageUrl ? (
                                <div className="relative">
                                  <div className="relative w-16 h-16 rounded-lg overflow-hidden bg-[var(--background)]">
                                    <Image
                                      src={displayImageUrl}
                                      alt={`Step ${index + 1}`}
                                      fill
                                      className="object-cover"
                                      sizes="64px"
                                      unoptimized
                                    />
                                    {step.image?.uploading && (
                                      <div className="absolute inset-0 bg-black/50 flex items-center justify-center">
                                        <div className="animate-spin w-4 h-4 border-2 border-white border-t-transparent rounded-full" />
                                      </div>
                                    )}
                                    {step.image?.error && (
                                      <div className="absolute inset-0 bg-[var(--error)]/50 flex items-center justify-center">
                                        <svg className="w-4 h-4 text-white" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                                          <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M12 9v2m0 4h.01" />
                                        </svg>
                                      </div>
                                    )}
                                    {/* Only show remove button for uploaded images, not inherited */}
                                    {step.image && (
                                      <button
                                        type="button"
                                        onClick={() => removeStepImage(step.id)}
                                        className="absolute top-0.5 right-0.5 p-0.5 bg-black/50 rounded-full hover:bg-black/70 transition-colors"
                                      >
                                        <svg className="w-3 h-3 text-white" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                                          <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M6 18L18 6M6 6l12 12" />
                                        </svg>
                                      </button>
                                    )}
                                  </div>
                                  {/* Badge for inherited image */}
                                  {isInheritedImage && (
                                    <span className="absolute -bottom-1 -right-1 text-[8px] px-1 py-0.5 bg-[var(--primary-light)]/30 text-[var(--primary)] rounded border border-[var(--primary-light)]">
                                      {t('original')}
                                    </span>
                                  )}
                                </div>
                              ) : null}
                              {/* Always show add photo button to allow replacing inherited image */}
                              <button
                                type="button"
                                onClick={() => {
                                  const input = stepImageInputRefs.current.get(step.id);
                                  input?.click();
                                }}
                                className="px-3 py-1.5 text-xs text-[var(--text-secondary)] border border-[var(--border)] rounded-lg hover:border-[var(--primary)] hover:text-[var(--primary)] transition-colors inline-flex items-center gap-1"
                              >
                                <svg className="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                                  <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M4 16l4.586-4.586a2 2 0 012.828 0L16 16m-2-2l1.586-1.586a2 2 0 012.828 0L20 14m-6-6h.01M6 20h12a2 2 0 002-2V6a2 2 0 00-2-2H6a2 2 0 00-2 2v12a2 2 0 002 2z" />
                                </svg>
                                {displayImageUrl ? t('changePhoto') : t('addPhoto')}
                              </button>
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
                            disabled={!canDelete}
                            className="p-2 text-[var(--text-secondary)] hover:text-[var(--error)] transition-colors disabled:opacity-30 disabled:cursor-not-allowed"
                          >
                            <svg className="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                              <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M19 7l-.867 12.142A2 2 0 0116.138 21H7.862a2 2 0 01-1.995-1.858L5 7m5 4v6m4-6v6m1-10V4a1 1 0 00-1-1h-4a1 1 0 00-1 1v3M4 7h16" />
                            </svg>
                          </button>
                        </div>
                      );
                    })}
                  </div>

                  {/* Deleted steps section (only in variant mode) */}
                  {isVariantMode && deletedSteps.length > 0 && (
                    <div className="mt-4 border border-dashed border-[var(--border)] rounded-lg p-3 bg-[var(--background)]">
                      <div className="flex items-center gap-2 text-xs text-[var(--text-secondary)] mb-2">
                        <svg className="w-3.5 h-3.5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                          <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M19 7l-.867 12.142A2 2 0 0116.138 21H7.862a2 2 0 01-1.995-1.858L5 7m5 4v6m4-6v6m1-10V4a1 1 0 00-1-1h-4a1 1 0 00-1 1v3M4 7h16" />
                        </svg>
                        <span>{t('removedSteps')} ({deletedSteps.length})</span>
                      </div>
                      <div className="space-y-2">
                        {deletedSteps.map((step) => (
                          <div
                            key={step.id}
                            className="flex items-start justify-between py-2 px-3 bg-[var(--surface)] rounded"
                          >
                            <p className="text-sm text-[var(--text-secondary)] line-through flex-1 pr-3">
                              {step.description.length > 100
                                ? `${step.description.slice(0, 100)}...`
                                : step.description}
                            </p>
                            <button
                              type="button"
                              onClick={() => restoreStep(step.id)}
                              className="text-xs px-2 py-1 text-[var(--primary)] hover:bg-[var(--primary-light)]/10 rounded transition-colors inline-flex items-center gap-1 flex-shrink-0"
                            >
                              <svg className="w-3 h-3" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                                <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M3 10h10a8 8 0 018 8v2M3 10l6 6m-6-6l6-6" />
                              </svg>
                              {t('restore')}
                            </button>
                          </div>
                        ))}
                      </div>
                    </div>
                  )}

                  {canAdd ? (
                    <button
                      type="button"
                      onClick={addStep}
                      className="mt-4 px-4 py-2 text-sm text-[var(--primary)] hover:bg-[var(--primary-light)]/10 rounded-lg transition-colors inline-flex items-center gap-1"
                    >
                      <svg className="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                        <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M12 4v16m8-8H4" />
                      </svg>
                      {t('addStep')}
                    </button>
                  ) : (
                    <p className="mt-4 text-sm text-[var(--text-secondary)]">
                      {t('maxStepsReached', { max: MAX_STEPS })}
                    </p>
                  )}
                </>
              );
            })()}
          </section>

          {/* Hashtags Section */}
          <section className="bg-[var(--surface)] rounded-2xl p-6 border border-[var(--border)]">
            {(() => {
              const activeHashtags = hashtags.filter((h) => !h.isDeleted);
              const deletedHashtags = hashtags.filter((h) => h.isDeleted);
              const activeCount = activeHashtags.length;

              return (
                <>
                  <div className="flex justify-between items-center mb-4">
                    <h2 className="text-lg font-semibold text-[var(--text-primary)]">
                      {t('hashtags')}
                    </h2>
                    <span className="text-sm text-[var(--text-secondary)]">
                      {activeCount}/{MAX_HASHTAGS}
                    </span>
                  </div>

                  {/* Active tag chips */}
                  {activeHashtags.length > 0 && (
                    <div className="flex flex-wrap gap-2 mb-4">
                      {activeHashtags.map((hashtag) => (
                        <span
                          key={hashtag.id}
                          className={`inline-flex items-center gap-1 px-3 py-1.5 rounded-full text-sm text-hashtag ${
                            hashtag.isOriginal
                              ? 'border border-dashed'
                              : ''
                          }`}
                          style={hashtag.isOriginal ? { borderColor: 'rgba(76, 175, 80, 0.4)' } : undefined}
                        >
                          {hashtag.isOriginal && (
                            <span
                              className="text-[10px] px-1 py-0.5 rounded mr-1 text-hashtag"
                              style={{ backgroundColor: 'rgba(76, 175, 80, 0.1)' }}
                            >
                              {t('inherited')}
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

                  {/* Deleted hashtags section (only in variant mode) */}
                  {isVariantMode && deletedHashtags.length > 0 && (
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
                            className="inline-flex items-center gap-1 px-2 py-1 bg-[var(--surface)] rounded text-sm text-[var(--text-secondary)] line-through"
                          >
                            #{hashtag.name}
                            <button
                              type="button"
                              onClick={() => restoreHashtag(hashtag.id)}
                              className="text-xs px-1.5 py-0.5 text-[var(--primary)] hover:bg-[var(--primary-light)]/10 rounded transition-colors inline-flex items-center gap-0.5 ml-1"
                            >
                              <svg className="w-3 h-3" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                                <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M3 10h10a8 8 0 018 8v2M3 10l6 6m-6-6l6-6" />
                              </svg>
                              {t('restore')}
                            </button>
                          </span>
                        ))}
                      </div>
                    </div>
                  )}

                  {/* Tag input */}
                  {activeCount < MAX_HASHTAGS && (
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
                        className="px-4 py-3 bg-[var(--primary)] dark:bg-[var(--secondary)] text-white rounded-xl hover:bg-[var(--primary-dark)] dark:hover:bg-[#6D4C41] transition-colors disabled:opacity-50 disabled:cursor-not-allowed"
                      >
                        {t('add')}
                      </button>
                    </div>
                  )}

                  <p className="text-xs text-[var(--text-secondary)] mt-2">
                    {t('hashtagHelp', { max: MAX_HASHTAG_LENGTH })}
                  </p>
                </>
              );
            })()}
          </section>

          {/* Finish Your Variation Section (Variant Mode Only) */}
          {isVariantMode && (
            <section className="bg-[var(--surface)] rounded-2xl p-6 border border-[var(--border)]">
              <h2 className="text-lg font-semibold text-[var(--text-primary)] mb-4">
                {t('finishVariation')}
              </h2>
              <div className="space-y-4">
                {/* Recipe Title */}
                <div>
                  <label htmlFor="variantTitle" className="block text-sm font-medium text-[var(--text-primary)] mb-2">
                    {t('recipeTitle')} <span className="text-[var(--error)]">*</span>
                  </label>
                  <input
                    id="variantTitle"
                    type="text"
                    value={title}
                    onChange={(e) => setTitle(e.target.value)}
                    maxLength={200}
                    className="w-full px-4 py-3 bg-[var(--background)] border border-[var(--border)] rounded-xl focus:outline-none focus:border-[var(--primary)]"
                    placeholder={t('recipeTitlePlaceholder')}
                  />
                  <p className="text-xs text-[var(--text-secondary)] mt-1 text-right">
                    {title.length}/200
                  </p>
                </div>

                {/* What did you change? */}
                <div>
                  <label htmlFor="changeReason" className="block text-sm font-medium text-[var(--text-primary)] mb-2">
                    {t('whatDidYouChange')} <span className="text-[var(--error)]">*</span>
                  </label>
                  <textarea
                    id="changeReason"
                    value={changeReason}
                    onChange={(e) => setChangeReason(e.target.value)}
                    maxLength={2000}
                    rows={3}
                    className="w-full px-4 py-3 bg-[var(--background)] border border-[var(--border)] rounded-xl focus:outline-none focus:border-[var(--primary)] resize-none"
                    placeholder={t('whatDidYouChangePlaceholder')}
                  />
                  <div className="flex justify-between mt-1">
                    <p className="text-xs text-[var(--text-secondary)]">
                      {t('whatDidYouChangeHelp')}
                    </p>
                    <p className="text-xs text-[var(--text-secondary)]">
                      {changeReason.length}/2000
                    </p>
                  </div>
                </div>
              </div>
            </section>
          )}

          {/* Visibility Section */}
          <section className="bg-[var(--surface)] rounded-2xl p-6 border border-[var(--border)]">
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
            <div className="p-4 bg-[var(--error)]/10 border border-[var(--error)]/20 text-[var(--error)] rounded-xl text-sm">
              {error}
            </div>
          )}

          {/* Submit */}
          <div className="flex gap-3 pt-4">
            <Link
              href={isVariantMode ? `/recipes/${parentRecipe.publicId}` : '/recipes'}
              className="flex-1 py-3 text-center text-[var(--text-primary)] border border-[var(--border)] rounded-xl font-medium hover:bg-[var(--surface)] transition-colors"
            >
              {t('cancel')}
            </Link>
            <button
              type="submit"
              disabled={isSubmitting || photos.some((p) => p.type === 'uploaded' && p.uploadedImage?.uploading) || steps.some((s) => s.image?.uploading)}
              className="flex-1 py-3 bg-[var(--primary)] dark:bg-[var(--secondary)] text-white rounded-xl font-medium hover:bg-[var(--primary-dark)] dark:hover:bg-[#6D4C41] transition-colors disabled:opacity-50 disabled:cursor-not-allowed flex items-center justify-center gap-2"
            >
              {isSubmitting ? (
                <>
                  <svg className="animate-spin w-5 h-5" fill="none" viewBox="0 0 24 24">
                    <circle className="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" strokeWidth="4" />
                    <path className="opacity-75" fill="currentColor" d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4z" />
                  </svg>
                  {isVariantMode ? t('creatingVariation') : t('creating')}
                </>
              ) : (
                isVariantMode ? t('createVariation') : t('createRecipe')
              )}
            </button>
          </div>
        </form>
      </div>
    </main>
  );
}
