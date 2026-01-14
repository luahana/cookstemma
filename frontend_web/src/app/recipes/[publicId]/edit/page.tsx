'use client';

import { useState, useEffect } from 'react';
import { useRouter, useParams } from 'next/navigation';
import Link from 'next/link';
import Image from 'next/image';
import { useAuth } from '@/contexts/AuthContext';
import { getRecipeDetail, getRecipeModifiable, updateRecipe } from '@/lib/api/recipes';
import { getImageUrl } from '@/lib/utils/image';
import type {
  RecipeDetail,
  RecipeModifiable,
  IngredientDto,
  IngredientType,
  UpdateRecipeRequest,
} from '@/lib/types';

const INGREDIENT_TYPES: { value: IngredientType; label: string }[] = [
  { value: 'MAIN', label: 'Main' },
  { value: 'SUB', label: 'Additional' },
  { value: 'SAUCE', label: 'Sauce & Seasoning' },
  { value: 'GARNISH', label: 'Garnish' },
  { value: 'OPTIONAL', label: 'Optional' },
];

const COOKING_TIME_OPTIONS = [
  { value: 'MIN_0_TO_15', label: '0-15 min' },
  { value: 'MIN_15_TO_30', label: '15-30 min' },
  { value: 'MIN_30_TO_60', label: '30-60 min' },
  { value: 'MIN_60_TO_120', label: '1-2 hours' },
  { value: 'MIN_120_PLUS', label: '2+ hours' },
];

export default function RecipeEditPage() {
  const { publicId } = useParams<{ publicId: string }>();
  const router = useRouter();
  const { isAuthenticated, isLoading: authLoading } = useAuth();

  const [recipe, setRecipe] = useState<RecipeDetail | null>(null);
  const [modifiable, setModifiable] = useState<RecipeModifiable | null>(null);
  const [isLoading, setIsLoading] = useState(true);
  const [isSaving, setIsSaving] = useState(false);
  const [error, setError] = useState<string | null>(null);

  // Form state
  const [title, setTitle] = useState('');
  const [description, setDescription] = useState('');
  const [ingredients, setIngredients] = useState<IngredientDto[]>([]);
  const [steps, setSteps] = useState<{ stepNumber: number; description: string; imagePublicId: string | null }[]>([]);
  const [hashtags, setHashtags] = useState('');
  const [servings, setServings] = useState(2);
  const [cookingTimeRange, setCookingTimeRange] = useState('MIN_30_TO_60');

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

        // Initialize form state
        setTitle(recipeData.title);
        setDescription(recipeData.description || '');
        setIngredients(recipeData.ingredients);
        setSteps(recipeData.steps.map((s) => ({
          stepNumber: s.stepNumber,
          description: s.description,
          imagePublicId: s.imagePublicId,
        })));
        setHashtags(recipeData.hashtags.map((h) => h.name).join(', '));
        setServings(recipeData.servings);
        setCookingTimeRange(recipeData.cookingTimeRange);
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

  const handleAddIngredient = () => {
    setIngredients([
      ...ingredients,
      { name: '', amount: '', quantity: null, unit: null, type: 'MAIN' },
    ]);
  };

  const handleRemoveIngredient = (index: number) => {
    setIngredients(ingredients.filter((_, i) => i !== index));
  };

  const handleIngredientChange = (index: number, field: keyof IngredientDto, value: string) => {
    const updated = [...ingredients];
    updated[index] = { ...updated[index], [field]: value };
    setIngredients(updated);
  };

  const handleAddStep = () => {
    setSteps([
      ...steps,
      { stepNumber: steps.length + 1, description: '', imagePublicId: null },
    ]);
  };

  const handleRemoveStep = (index: number) => {
    const updated = steps.filter((_, i) => i !== index);
    // Renumber steps
    setSteps(updated.map((s, i) => ({ ...s, stepNumber: i + 1 })));
  };

  const handleStepChange = (index: number, description: string) => {
    const updated = [...steps];
    updated[index] = { ...updated[index], description };
    setSteps(updated);
  };

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();

    if (!title.trim()) {
      setError('Title is required');
      return;
    }

    if (ingredients.filter((i) => i.name.trim()).length === 0) {
      setError('At least one ingredient is required');
      return;
    }

    if (steps.filter((s) => s.description.trim()).length === 0) {
      setError('At least one step is required');
      return;
    }

    setIsSaving(true);
    setError(null);

    try {
      const hashtagList = hashtags
        .split(',')
        .map((h) => h.trim().replace(/^#/, ''))
        .filter((h) => h.length > 0);

      const data: UpdateRecipeRequest = {
        title: title.trim(),
        description: description.trim() || undefined,
        ingredients: ingredients.filter((i) => i.name.trim()),
        steps: steps.filter((s) => s.description.trim()).map((s, i) => ({
          stepNumber: i + 1,
          description: s.description.trim(),
          imagePublicId: s.imagePublicId,
        })),
        imagePublicIds: recipe?.images.map((img) => img.imagePublicId) || [],
        hashtags: hashtagList,
        servings,
        cookingTimeRange,
      };

      await updateRecipe(publicId!, data);
      router.push(`/recipes/${publicId}`);
      router.refresh();
    } catch (err) {
      console.error('Failed to update recipe:', err);
      setError('Failed to save changes. Please try again.');
    } finally {
      setIsSaving(false);
    }
  };

  if (authLoading || isLoading) {
    return (
      <div className="min-h-screen flex items-center justify-center bg-[var(--background)]">
        <div className="animate-pulse">
          <div className="w-12 h-12 rounded-full bg-[var(--primary-light)]" />
        </div>
      </div>
    );
  }

  if (error && !recipe) {
    return (
      <main className="min-h-screen bg-[var(--background)]">
        <div className="max-w-2xl mx-auto px-4 py-16 text-center">
          <div className="mb-8">
            <span className="text-6xl">🔒</span>
          </div>
          <h1 className="text-2xl font-bold text-[var(--text-primary)] mb-4">
            Cannot Edit Recipe
          </h1>
          <p className="text-[var(--text-secondary)] mb-8">
            {error}
          </p>
          <Link
            href={`/recipes/${publicId}`}
            className="px-6 py-3 bg-[var(--primary)] text-white rounded-xl font-medium hover:bg-[var(--primary-dark)] transition-colors"
          >
            Back to Recipe
          </Link>
        </div>
      </main>
    );
  }

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
              ← Back to recipe
            </Link>
            <h1 className="text-2xl font-bold text-[var(--text-primary)]">
              Edit Recipe
            </h1>
          </div>
        </div>

        <form onSubmit={handleSubmit} className="space-y-8">
          {/* Basic Info */}
          <section className="bg-[var(--surface)] border border-[var(--border)] rounded-2xl p-6">
            <h2 className="text-lg font-semibold text-[var(--text-primary)] mb-4">
              Basic Information
            </h2>

            <div className="space-y-4">
              <div>
                <label htmlFor="title" className="block text-sm font-medium text-[var(--text-primary)] mb-2">
                  Title *
                </label>
                <input
                  id="title"
                  type="text"
                  value={title}
                  onChange={(e) => setTitle(e.target.value)}
                  className="w-full px-4 py-3 bg-[var(--background)] border border-[var(--border)] rounded-xl focus:outline-none focus:border-[var(--primary)]"
                  placeholder="Give your recipe a name"
                />
              </div>

              <div>
                <label htmlFor="description" className="block text-sm font-medium text-[var(--text-primary)] mb-2">
                  Description
                </label>
                <textarea
                  id="description"
                  value={description}
                  onChange={(e) => setDescription(e.target.value)}
                  rows={3}
                  className="w-full px-4 py-3 bg-[var(--background)] border border-[var(--border)] rounded-xl focus:outline-none focus:border-[var(--primary)] resize-none"
                  placeholder="Describe your recipe"
                />
              </div>

              <div className="grid grid-cols-2 gap-4">
                <div>
                  <label htmlFor="servings" className="block text-sm font-medium text-[var(--text-primary)] mb-2">
                    Servings
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
                    Cooking Time
                  </label>
                  <select
                    id="cookingTime"
                    value={cookingTimeRange}
                    onChange={(e) => setCookingTimeRange(e.target.value)}
                    className="w-full px-4 py-3 bg-[var(--background)] border border-[var(--border)] rounded-xl focus:outline-none focus:border-[var(--primary)]"
                  >
                    {COOKING_TIME_OPTIONS.map((option) => (
                      <option key={option.value} value={option.value}>
                        {option.label}
                      </option>
                    ))}
                  </select>
                </div>
              </div>

              <div>
                <label htmlFor="hashtags" className="block text-sm font-medium text-[var(--text-primary)] mb-2">
                  Hashtags
                </label>
                <input
                  id="hashtags"
                  type="text"
                  value={hashtags}
                  onChange={(e) => setHashtags(e.target.value)}
                  className="w-full px-4 py-3 bg-[var(--background)] border border-[var(--border)] rounded-xl focus:outline-none focus:border-[var(--primary)]"
                  placeholder="easy, weeknight, vegetarian (comma separated)"
                />
              </div>
            </div>
          </section>

          {/* Images (read-only) */}
          {recipe && recipe.images.length > 0 && (
            <section className="bg-[var(--surface)] border border-[var(--border)] rounded-2xl p-6">
              <h2 className="text-lg font-semibold text-[var(--text-primary)] mb-4">
                Photos (cannot be changed)
              </h2>
              <div className="flex gap-3 overflow-x-auto pb-2">
                {recipe.images.map((img) => (
                  <div
                    key={img.imagePublicId}
                    className="relative w-24 h-24 flex-shrink-0 rounded-xl overflow-hidden bg-[var(--background)]"
                  >
                    <Image
                      src={getImageUrl(img.imageUrl) || ''}
                      alt="Recipe photo"
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

          {/* Ingredients */}
          <section className="bg-[var(--surface)] border border-[var(--border)] rounded-2xl p-6">
            <div className="flex items-center justify-between mb-4">
              <h2 className="text-lg font-semibold text-[var(--text-primary)]">
                Ingredients *
              </h2>
              <button
                type="button"
                onClick={handleAddIngredient}
                className="text-sm text-[var(--primary)] hover:underline"
              >
                + Add ingredient
              </button>
            </div>

            <div className="space-y-3">
              {ingredients.map((ing, index) => (
                <div key={index} className="flex gap-2 items-start">
                  <input
                    type="text"
                    value={ing.amount || ''}
                    onChange={(e) => handleIngredientChange(index, 'amount', e.target.value)}
                    placeholder="Amount"
                    className="w-24 px-3 py-2 bg-[var(--background)] border border-[var(--border)] rounded-lg focus:outline-none focus:border-[var(--primary)] text-sm"
                  />
                  <input
                    type="text"
                    value={ing.name}
                    onChange={(e) => handleIngredientChange(index, 'name', e.target.value)}
                    placeholder="Ingredient name"
                    className="flex-1 px-3 py-2 bg-[var(--background)] border border-[var(--border)] rounded-lg focus:outline-none focus:border-[var(--primary)] text-sm"
                  />
                  <select
                    value={ing.type}
                    onChange={(e) => handleIngredientChange(index, 'type', e.target.value)}
                    className="w-32 px-3 py-2 bg-[var(--background)] border border-[var(--border)] rounded-lg focus:outline-none focus:border-[var(--primary)] text-sm"
                  >
                    {INGREDIENT_TYPES.map((type) => (
                      <option key={type.value} value={type.value}>
                        {type.label}
                      </option>
                    ))}
                  </select>
                  <button
                    type="button"
                    onClick={() => handleRemoveIngredient(index)}
                    className="p-2 text-[var(--text-secondary)] hover:text-[var(--error)]"
                  >
                    <svg className="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                      <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M6 18L18 6M6 6l12 12" />
                    </svg>
                  </button>
                </div>
              ))}
            </div>
          </section>

          {/* Steps */}
          <section className="bg-[var(--surface)] border border-[var(--border)] rounded-2xl p-6">
            <div className="flex items-center justify-between mb-4">
              <h2 className="text-lg font-semibold text-[var(--text-primary)]">
                Instructions *
              </h2>
              <button
                type="button"
                onClick={handleAddStep}
                className="text-sm text-[var(--primary)] hover:underline"
              >
                + Add step
              </button>
            </div>

            <div className="space-y-4">
              {steps.map((step, index) => (
                <div key={index} className="flex gap-3 items-start">
                  <span className="flex-shrink-0 w-8 h-8 bg-[var(--primary)] text-white rounded-full flex items-center justify-center font-bold text-sm">
                    {index + 1}
                  </span>
                  <textarea
                    value={step.description}
                    onChange={(e) => handleStepChange(index, e.target.value)}
                    placeholder={`Step ${index + 1}`}
                    rows={2}
                    className="flex-1 px-3 py-2 bg-[var(--background)] border border-[var(--border)] rounded-lg focus:outline-none focus:border-[var(--primary)] text-sm resize-none"
                  />
                  <button
                    type="button"
                    onClick={() => handleRemoveStep(index)}
                    className="p-2 text-[var(--text-secondary)] hover:text-[var(--error)]"
                  >
                    <svg className="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                      <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M6 18L18 6M6 6l12 12" />
                    </svg>
                  </button>
                </div>
              ))}
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
              Cancel
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
                  Saving...
                </>
              ) : (
                'Save Changes'
              )}
            </button>
          </div>
        </form>
      </div>
    </main>
  );
}
