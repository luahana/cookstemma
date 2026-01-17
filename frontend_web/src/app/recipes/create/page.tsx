'use client';

import { useState, useRef, useEffect } from 'react';
import Image from 'next/image';
import Link from 'next/link';
import { useRouter } from 'next/navigation';
import { useAuth } from '@/contexts/AuthContext';
import { createRecipe } from '@/lib/api/recipes';
import { uploadImage } from '@/lib/api/images';
import type { IngredientType, CookingTimeRange, IngredientDto, MeasurementUnit } from '@/lib/types';
import { COOKING_TIME_RANGES } from '@/lib/types';
import { getDefaultCulinaryLocale } from '@/lib/utils/cookingStyle';
import { CookingStyleSelect, COOKING_STYLE_OPTIONS } from '@/components/common/CookingStyleSelect';

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

const INGREDIENT_CATEGORIES: { value: IngredientType; label: string; max: number }[] = [
  { value: 'MAIN', label: 'Main Ingredients', max: 5 },
  { value: 'SECONDARY', label: 'Secondary Ingredients', max: 8 },
  { value: 'SEASONING', label: 'Seasonings', max: 10 },
];

const MEASUREMENT_UNITS: { value: MeasurementUnit | ''; label: string }[] = [
  { value: '', label: 'Unit' },
  // Volume
  { value: 'CUP', label: 'Cup' },
  { value: 'TBSP', label: 'Tbsp' },
  { value: 'TSP', label: 'Tsp' },
  { value: 'ML', label: 'ml' },
  { value: 'L', label: 'L' },
  { value: 'FL_OZ', label: 'fl oz' },
  { value: 'PINT', label: 'Pint' },
  { value: 'QUART', label: 'Quart' },
  // Weight
  { value: 'G', label: 'g' },
  { value: 'KG', label: 'kg' },
  { value: 'OZ', label: 'oz' },
  { value: 'LB', label: 'lb' },
  // Count/Other
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

interface FormIngredient {
  id: string;
  name: string;
  quantity: string;  // Numeric quantity (max 4 chars)
  unit: MeasurementUnit | '';  // Measurement unit from dropdown
  type: IngredientType;
}

interface FormStep {
  id: string;
  description: string;
  image: UploadedImage | null;
}

export default function CreateRecipePage() {
  const { isAuthenticated, isLoading: authLoading } = useAuth();
  const router = useRouter();
  const recipeImageInputRef = useRef<HTMLInputElement>(null);
  const stepImageInputRefs = useRef<Map<string, HTMLInputElement>>(new Map());

  // Form state
  const [title, setTitle] = useState('');
  const [description, setDescription] = useState('');
  const [foodName, setFoodName] = useState('');
  const [culinaryLocale, setCulinaryLocale] = useState('');
  const [servings, setServings] = useState(2);
  const [cookingTimeRange, setCookingTimeRange] = useState<CookingTimeRange>('MIN_30_TO_60');
  const [hashtags, setHashtags] = useState<string[]>([]);
  const [hashtagInput, setHashtagInput] = useState('');
  const [recipeImages, setRecipeImages] = useState<UploadedImage[]>([]);
  const [ingredients, setIngredients] = useState<FormIngredient[]>([
    { id: crypto.randomUUID(), name: '', quantity: '', unit: '', type: 'MAIN' },
  ]);
  const [steps, setSteps] = useState<FormStep[]>([
    { id: crypto.randomUUID(), description: '', image: null },
  ]);

  // UI state
  const [isSubmitting, setIsSubmitting] = useState(false);
  const [error, setError] = useState<string | null>(null);

  // Redirect if not authenticated
  useEffect(() => {
    if (!authLoading && !isAuthenticated) {
      router.push('/login?redirect=/recipes/create');
    }
  }, [isAuthenticated, authLoading, router]);

  // Set default culinary locale based on browser locale
  useEffect(() => {
    if (!culinaryLocale) {
      const defaultLocale = getDefaultCulinaryLocale();
      // Check if the detected locale is in our list, otherwise use 'international'
      const isValid = COOKING_STYLE_OPTIONS.some((l) => l.value === defaultLocale);
      setCulinaryLocale(isValid ? defaultLocale : 'international');
    }
  }, [culinaryLocale]);

  // Handle recipe image selection
  const handleRecipeImageSelect = async (e: React.ChangeEvent<HTMLInputElement>) => {
    const files = Array.from(e.target.files || []);
    if (files.length === 0) return;

    const remaining = MAX_RECIPE_PHOTOS - recipeImages.length;
    const filesToAdd = files.slice(0, remaining);

    const newImages: UploadedImage[] = filesToAdd.map((file) => ({
      file,
      preview: URL.createObjectURL(file),
      publicId: null,
      uploading: true,
      error: null,
    }));

    setRecipeImages((prev) => [...prev, ...newImages]);

    for (const img of newImages) {
      try {
        const response = await uploadImage(img.file, 'RECIPE');
        setRecipeImages((prev) =>
          prev.map((p) =>
            p.preview === img.preview
              ? { ...p, publicId: response.imagePublicId, uploading: false }
              : p
          )
        );
      } catch {
        setRecipeImages((prev) =>
          prev.map((p) =>
            p.preview === img.preview
              ? { ...p, uploading: false, error: 'Upload failed' }
              : p
          )
        );
      }
    }

    if (recipeImageInputRef.current) {
      recipeImageInputRef.current.value = '';
    }
  };

  // Remove recipe image
  const removeRecipeImage = (preview: string) => {
    setRecipeImages((prev) => {
      const img = prev.find((p) => p.preview === preview);
      if (img) URL.revokeObjectURL(img.preview);
      return prev.filter((p) => p.preview !== preview);
    });
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
      const response = await uploadImage(file, 'RECIPE_STEP');
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
    setIngredients((prev) => prev.filter((ing) => ing.id !== id));
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
    if (steps.length <= 1) return;
    setSteps((prev) => {
      const step = prev.find((s) => s.id === id);
      if (step?.image) URL.revokeObjectURL(step.image.preview);
      return prev.filter((s) => s.id !== id);
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
    if (hashtags.length >= MAX_HASHTAGS) return;

    const normalized = normalizeHashtag(hashtagInput);
    if (!normalized) return;
    if (hashtags.includes(normalized)) {
      setHashtagInput('');
      return;
    }

    setHashtags((prev) => [...prev, normalized]);
    setHashtagInput('');
  };

  const handleHashtagKeyDown = (e: React.KeyboardEvent<HTMLInputElement>) => {
    if (e.key === 'Enter' || e.key === ',') {
      e.preventDefault();
      addHashtag();
    }
  };

  const removeHashtag = (tag: string) => {
    setHashtags((prev) => prev.filter((t) => t !== tag));
  };

  // Handle form submission
  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    setError(null);

    // Validation
    if (!title.trim()) {
      setError('Please enter a recipe title');
      return;
    }

    if (!foodName.trim()) {
      setError('Please enter a food name');
      return;
    }

    if (!culinaryLocale) {
      setError('Please select a cooking style');
      return;
    }

    if (recipeImages.length === 0) {
      setError('Please add at least one photo of your dish');
      return;
    }

    if (recipeImages.some((img) => img.uploading)) {
      setError('Please wait for images to finish uploading');
      return;
    }

    const failedRecipeImages = recipeImages.filter((img) => img.error);
    if (failedRecipeImages.length > 0) {
      setError('Some recipe images failed to upload. Please remove them and try again.');
      return;
    }

    const validIngredients = ingredients.filter((ing) => ing.name.trim());
    if (validIngredients.length === 0) {
      setError('Please add at least one ingredient');
      return;
    }

    const validSteps = steps.filter((step) => step.description.trim());
    if (validSteps.length === 0) {
      setError('Please add at least one cooking step');
      return;
    }

    // Check if any step images are uploading
    const uploadingStepImages = steps.some((step) => step.image?.uploading);
    if (uploadingStepImages) {
      setError('Please wait for step images to finish uploading');
      return;
    }

    const failedStepImages = steps.filter((step) => step.image?.error);
    if (failedStepImages.length > 0) {
      setError('Some step images failed to upload. Please remove them and try again.');
      return;
    }

    setIsSubmitting(true);

    try {
      const imagePublicIds = recipeImages
        .filter((img) => img.publicId)
        .map((img) => img.publicId!);

      const ingredientsData: IngredientDto[] = validIngredients.map((ing) => ({
        name: ing.name.trim(),
        amount: null,  // Legacy field, not used
        quantity: ing.quantity ? parseFloat(ing.quantity) : null,
        unit: (ing.unit || null) as IngredientDto['unit'],
        type: ing.type,
      }));

      const stepsData = validSteps.map((step, index) => ({
        stepNumber: index + 1,
        description: step.description.trim(),
        imagePublicId: step.image?.publicId || null,
      }));

      const recipe = await createRecipe({
        title: title.trim(),
        description: description.trim() || undefined,
        newFoodName: foodName.trim(),
        culinaryLocale,
        ingredients: ingredientsData,
        steps: stepsData,
        imagePublicIds,
        hashtags: hashtags.length > 0 ? hashtags : undefined,
        servings,
        cookingTimeRange,
      });

      router.push(`/recipes/${recipe.publicId}`);
    } catch (err) {
      console.error('Failed to create recipe:', err);
      setError('Failed to create recipe. Please try again.');
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
      <div className="max-w-3xl mx-auto px-4 py-8">
        {/* Header */}
        <div className="mb-8">
          <Link
            href="/recipes"
            className="text-[var(--text-secondary)] hover:text-[var(--primary)] inline-flex items-center gap-1 mb-4"
          >
            <svg className="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M15 19l-7-7 7-7" />
            </svg>
            Back to Recipes
          </Link>
          <h1 className="text-3xl font-bold text-[var(--text-primary)]">
            Create Recipe
          </h1>
          <p className="text-[var(--text-secondary)] mt-2">
            Share your culinary creation with the community
          </p>
        </div>

        <form onSubmit={handleSubmit} className="space-y-8">
          {/* Recipe Photos Section */}
          <section className="bg-[var(--surface)] rounded-2xl p-6 border border-[var(--border)]">
            <h2 className="text-lg font-semibold text-[var(--text-primary)] mb-4">
              Photos <span className="text-[var(--error)]">*</span>
            </h2>
            <p className="text-sm text-[var(--text-secondary)] mb-4">
              Add photos of your finished dish (at least 1, up to {MAX_RECIPE_PHOTOS})
            </p>
            <div className="flex gap-3 flex-wrap">
              {recipeImages.map((img) => (
                <div
                  key={img.preview}
                  className="relative w-28 h-28 rounded-lg overflow-hidden bg-[var(--background)]"
                >
                  <Image
                    src={img.preview}
                    alt="Recipe photo"
                    fill
                    className="object-cover"
                    sizes="112px"
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
                    onClick={() => removeRecipeImage(img.preview)}
                    className="absolute top-1 right-1 p-1 bg-black/50 rounded-full hover:bg-black/70 transition-colors"
                  >
                    <svg className="w-4 h-4 text-white" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                      <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M6 18L18 6M6 6l12 12" />
                    </svg>
                  </button>
                </div>
              ))}
              {recipeImages.length < MAX_RECIPE_PHOTOS && (
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
              Basic Information
            </h2>
            <div className="space-y-4">
              {/* Title */}
              <div>
                <label htmlFor="title" className="block text-sm font-medium text-[var(--text-primary)] mb-2">
                  Recipe Title <span className="text-[var(--error)]">*</span>
                </label>
                <input
                  id="title"
                  type="text"
                  value={title}
                  onChange={(e) => setTitle(e.target.value)}
                  maxLength={100}
                  className="w-full px-4 py-3 bg-[var(--background)] border border-[var(--border)] rounded-xl focus:outline-none focus:border-[var(--primary)]"
                  placeholder="e.g., Grandma's Secret Kimchi Fried Rice"
                />
                <p className="text-xs text-[var(--text-secondary)] mt-1 text-right">
                  {title.length}/100
                </p>
              </div>

              {/* Food Name */}
              <div>
                <label htmlFor="foodName" className="block text-sm font-medium text-[var(--text-primary)] mb-2">
                  Food Name <span className="text-[var(--error)]">*</span>
                </label>
                <input
                  id="foodName"
                  type="text"
                  value={foodName}
                  onChange={(e) => setFoodName(e.target.value)}
                  maxLength={50}
                  className="w-full px-4 py-3 bg-[var(--background)] border border-[var(--border)] rounded-xl focus:outline-none focus:border-[var(--primary)]"
                  placeholder="e.g., Kimchi Fried Rice"
                />
                <div className="flex justify-between mt-1">
                  <p className="text-xs text-[var(--text-secondary)]">
                    The general name of the dish (used for categorization)
                  </p>
                  <p className="text-xs text-[var(--text-secondary)]">
                    {foodName.length}/50
                  </p>
                </div>
              </div>

              {/* Description */}
              <div>
                <label htmlFor="description" className="block text-sm font-medium text-[var(--text-primary)] mb-2">
                  Description
                </label>
                <textarea
                  id="description"
                  value={description}
                  onChange={(e) => setDescription(e.target.value)}
                  maxLength={500}
                  rows={3}
                  className="w-full px-4 py-3 bg-[var(--background)] border border-[var(--border)] rounded-xl focus:outline-none focus:border-[var(--primary)] resize-none"
                  placeholder="Tell us about your recipe..."
                />
                <p className="text-xs text-[var(--text-secondary)] mt-1 text-right">
                  {description.length}/500
                </p>
              </div>

              {/* Culinary Locale & Servings Row */}
              <div className="grid grid-cols-2 gap-4">
                <div>
                  <label className="block text-sm font-medium text-[var(--text-primary)] mb-2">
                    Cooking Style <span className="text-[var(--error)]">*</span>
                  </label>
                  <CookingStyleSelect
                    value={culinaryLocale}
                    onChange={setCulinaryLocale}
                    options={COOKING_STYLE_OPTIONS}
                    placeholder="Select cooking style"
                  />
                </div>

                <div>
                  <label htmlFor="servings" className="block text-sm font-medium text-[var(--text-primary)] mb-2">
                    Servings
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
                  Cooking Time
                </label>
                <select
                  id="cookingTime"
                  value={cookingTimeRange}
                  onChange={(e) => setCookingTimeRange(e.target.value as CookingTimeRange)}
                  className="w-full px-4 py-3 bg-[var(--background)] border border-[var(--border)] rounded-xl focus:outline-none focus:border-[var(--primary)]"
                >
                  {Object.entries(COOKING_TIME_RANGES).map(([key, label]) => (
                    <option key={key} value={key}>
                      {label}
                    </option>
                  ))}
                </select>
              </div>
            </div>
          </section>

          {/* Ingredients Section */}
          <section className="bg-[var(--surface)] rounded-2xl p-6 border border-[var(--border)]">
            <h2 className="text-lg font-semibold text-[var(--text-primary)] mb-4">
              Ingredients <span className="text-[var(--error)]">*</span>
            </h2>
            <p className="text-sm text-[var(--text-secondary)] mb-4">
              Add ingredients by category. Each category has a maximum limit.
            </p>

            {/* Ingredient Categories */}
            <div className="space-y-6">
              {INGREDIENT_CATEGORIES.map((category) => {
                const categoryIngredients = ingredients.filter((ing) => ing.type === category.value);
                const count = categoryIngredients.length;
                const canAdd = count < category.max;

                return (
                  <div key={category.value} className="border border-[var(--border)] rounded-xl p-4">
                    <div className="flex justify-between items-center mb-3">
                      <h3 className="text-sm font-medium text-[var(--text-primary)]">
                        {category.label}
                      </h3>
                      <span className="text-xs text-[var(--text-secondary)]">
                        {count}/{category.max}
                      </span>
                    </div>

                    {/* Ingredient rows for this category */}
                    <div className="space-y-2">
                      {categoryIngredients.map((ing, index) => (
                        <div key={ing.id} className="flex gap-2 items-center">
                          <span className="text-xs text-[var(--text-secondary)] w-4">
                            {index + 1}.
                          </span>
                          <input
                            type="text"
                            value={ing.name}
                            onChange={(e) => updateIngredient(ing.id, 'name', e.target.value)}
                            maxLength={50}
                            className="flex-1 px-3 py-2 bg-[var(--background)] border border-[var(--border)] rounded-lg focus:outline-none focus:border-[var(--primary)] text-sm"
                            placeholder="Ingredient name"
                          />
                          <input
                            type="text"
                            inputMode="decimal"
                            value={ing.quantity}
                            onChange={(e) => updateIngredient(ing.id, 'quantity', e.target.value)}
                            className="w-16 px-2 py-2 bg-[var(--background)] border border-[var(--border)] rounded-lg focus:outline-none focus:border-[var(--primary)] text-sm text-center"
                            placeholder="Qty"
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
                        Add {category.label.replace(' Ingredients', '').replace('s', '')}
                      </button>
                    ) : (
                      <p className="mt-3 text-xs text-[var(--text-secondary)]">
                        Maximum {category.max} items reached
                      </p>
                    )}
                  </div>
                );
              })}
            </div>
          </section>

          {/* Steps Section */}
          <section className="bg-[var(--surface)] rounded-2xl p-6 border border-[var(--border)]">
            <div className="flex justify-between items-center mb-4">
              <h2 className="text-lg font-semibold text-[var(--text-primary)]">
                Cooking Steps <span className="text-[var(--error)]">*</span>
              </h2>
              <span className="text-sm text-[var(--text-secondary)]">
                {steps.length}/{MAX_STEPS}
              </span>
            </div>
            <div className="space-y-4">
              {steps.map((step, index) => (
                <div key={step.id} className="flex gap-3 items-start">
                  <div className="w-8 h-8 rounded-full bg-[var(--primary)] text-white flex items-center justify-center flex-shrink-0 text-sm font-medium">
                    {index + 1}
                  </div>
                  <div className="flex-1 space-y-2">
                    <div>
                      <textarea
                        value={step.description}
                        onChange={(e) => updateStep(step.id, e.target.value)}
                        maxLength={500}
                        rows={3}
                        className="w-full px-3 py-2 bg-[var(--background)] border border-[var(--border)] rounded-lg focus:outline-none focus:border-[var(--primary)] text-sm resize-none"
                        placeholder="Describe this step..."
                      />
                      <p className="text-xs text-[var(--text-secondary)] mt-1 text-right">
                        {step.description.length}/500
                      </p>
                    </div>
                    {/* Step Image */}
                    <div className="flex items-center gap-2">
                      {step.image ? (
                        <div className="relative w-16 h-16 rounded-lg overflow-hidden bg-[var(--background)]">
                          <Image
                            src={step.image.preview}
                            alt={`Step ${index + 1}`}
                            fill
                            className="object-cover"
                            sizes="64px"
                          />
                          {step.image.uploading && (
                            <div className="absolute inset-0 bg-black/50 flex items-center justify-center">
                              <div className="animate-spin w-4 h-4 border-2 border-white border-t-transparent rounded-full" />
                            </div>
                          )}
                          {step.image.error && (
                            <div className="absolute inset-0 bg-[var(--error)]/50 flex items-center justify-center">
                              <svg className="w-4 h-4 text-white" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                                <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M12 9v2m0 4h.01" />
                              </svg>
                            </div>
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
                          onClick={() => {
                            const input = stepImageInputRefs.current.get(step.id);
                            input?.click();
                          }}
                          className="px-3 py-1.5 text-xs text-[var(--text-secondary)] border border-[var(--border)] rounded-lg hover:border-[var(--primary)] hover:text-[var(--primary)] transition-colors inline-flex items-center gap-1"
                        >
                          <svg className="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                            <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M4 16l4.586-4.586a2 2 0 012.828 0L16 16m-2-2l1.586-1.586a2 2 0 012.828 0L20 14m-6-6h.01M6 20h12a2 2 0 002-2V6a2 2 0 00-2-2H6a2 2 0 00-2 2v12a2 2 0 002 2z" />
                          </svg>
                          Add photo
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
                    disabled={steps.length <= 1}
                    className="p-2 text-[var(--text-secondary)] hover:text-[var(--error)] transition-colors disabled:opacity-30 disabled:cursor-not-allowed"
                  >
                    <svg className="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                      <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M19 7l-.867 12.142A2 2 0 0116.138 21H7.862a2 2 0 01-1.995-1.858L5 7m5 4v6m4-6v6m1-10V4a1 1 0 00-1-1h-4a1 1 0 00-1 1v3M4 7h16" />
                    </svg>
                  </button>
                </div>
              ))}
            </div>
            {steps.length < MAX_STEPS ? (
              <button
                type="button"
                onClick={addStep}
                className="mt-4 px-4 py-2 text-sm text-[var(--primary)] hover:bg-[var(--primary-light)]/10 rounded-lg transition-colors inline-flex items-center gap-1"
              >
                <svg className="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                  <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M12 4v16m8-8H4" />
                </svg>
                Add Step
              </button>
            ) : (
              <p className="mt-4 text-sm text-[var(--text-secondary)]">
                Maximum {MAX_STEPS} steps reached
              </p>
            )}
          </section>

          {/* Hashtags Section */}
          <section className="bg-[var(--surface)] rounded-2xl p-6 border border-[var(--border)]">
            <div className="flex justify-between items-center mb-4">
              <h2 className="text-lg font-semibold text-[var(--text-primary)]">
                Hashtags
              </h2>
              <span className="text-sm text-[var(--text-secondary)]">
                {hashtags.length}/{MAX_HASHTAGS}
              </span>
            </div>

            {/* Tag chips */}
            {hashtags.length > 0 && (
              <div className="flex flex-wrap gap-2 mb-4">
                {hashtags.map((tag) => (
                  <span
                    key={tag}
                    className="inline-flex items-center gap-1 px-3 py-1.5 bg-[var(--primary-light)]/20 text-[var(--primary)] rounded-full text-sm"
                  >
                    #{tag}
                    <button
                      type="button"
                      onClick={() => removeHashtag(tag)}
                      className="hover:text-[var(--error)] transition-colors"
                    >
                      <svg className="w-3.5 h-3.5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                        <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M6 18L18 6M6 6l12 12" />
                      </svg>
                    </button>
                  </span>
                ))}
              </div>
            )}

            {/* Tag input */}
            {hashtags.length < MAX_HASHTAGS && (
              <div className="flex gap-2">
                <input
                  type="text"
                  value={hashtagInput}
                  onChange={(e) => setHashtagInput(e.target.value)}
                  onKeyDown={handleHashtagKeyDown}
                  maxLength={MAX_HASHTAG_LENGTH}
                  className="flex-1 px-4 py-3 bg-[var(--background)] border border-[var(--border)] rounded-xl focus:outline-none focus:border-[var(--primary)]"
                  placeholder="Type a tag and press Enter"
                />
                <button
                  type="button"
                  onClick={addHashtag}
                  disabled={!hashtagInput.trim()}
                  className="px-4 py-3 bg-[var(--primary)] text-white rounded-xl hover:bg-[var(--primary-dark)] transition-colors disabled:opacity-50 disabled:cursor-not-allowed"
                >
                  Add
                </button>
              </div>
            )}

            <p className="text-xs text-[var(--text-secondary)] mt-2">
              Help others find your recipe with relevant tags (max {MAX_HASHTAG_LENGTH} chars each)
            </p>
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
              href="/recipes"
              className="flex-1 py-3 text-center text-[var(--text-primary)] border border-[var(--border)] rounded-xl font-medium hover:bg-[var(--surface)] transition-colors"
            >
              Cancel
            </Link>
            <button
              type="submit"
              disabled={isSubmitting || recipeImages.some((img) => img.uploading) || steps.some((s) => s.image?.uploading)}
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
                'Create Recipe'
              )}
            </button>
          </div>
        </form>
      </div>
    </main>
  );
}
