'use client';

import { useState, useCallback } from 'react';
import { useRouter } from 'next/navigation';
import { useAuth } from '@/contexts/AuthContext';
import { ActionMenu, ActionMenuIcons } from '@/components/shared/ActionMenu';
import { DeleteConfirmDialog } from '@/components/shared/DeleteConfirmDialog';
import { getRecipeModifiable, deleteRecipe } from '@/lib/api/recipes';
import type { RecipeModifiable } from '@/lib/types';

interface RecipeActionsProps {
  recipePublicId: string;
  creatorPublicId: string | null;
  recipeTitle: string;
}

export function RecipeActions({
  recipePublicId,
  creatorPublicId,
  recipeTitle,
}: RecipeActionsProps) {
  const { user, isAuthenticated } = useAuth();
  const router = useRouter();
  const [modifiable, setModifiable] = useState<RecipeModifiable | null>(null);
  const [isLoading, setIsLoading] = useState(false);
  const [showDeleteDialog, setShowDeleteDialog] = useState(false);
  const [isDeleting, setIsDeleting] = useState(false);
  const [error, setError] = useState<string | null>(null);

  // Check if user is the owner
  const isOwner = isAuthenticated && user?.publicId === creatorPublicId;

  // Don't render anything if not the owner
  if (!isOwner) {
    return null;
  }

  // Fetch modifiable status when menu opens
  const checkModifiable = useCallback(async () => {
    if (modifiable) return; // Already fetched
    setIsLoading(true);
    try {
      const result = await getRecipeModifiable(recipePublicId);
      setModifiable(result);
    } catch (err) {
      console.error('Failed to check modifiable status:', err);
    } finally {
      setIsLoading(false);
    }
  }, [recipePublicId, modifiable]);

  const handleEdit = async () => {
    await checkModifiable();
    if (modifiable?.canModify) {
      router.push(`/recipes/${recipePublicId}/edit`);
    } else if (modifiable?.reason) {
      setError(modifiable.reason);
    }
  };

  const handleDeleteClick = async () => {
    await checkModifiable();
    if (modifiable?.canModify) {
      setShowDeleteDialog(true);
    } else if (modifiable?.reason) {
      setError(modifiable.reason);
    }
  };

  const handleDeleteConfirm = async () => {
    setIsDeleting(true);
    try {
      await deleteRecipe(recipePublicId);
      router.push('/recipes');
      router.refresh();
    } catch (err) {
      console.error('Failed to delete recipe:', err);
      setError('Failed to delete recipe. Please try again.');
    } finally {
      setIsDeleting(false);
      setShowDeleteDialog(false);
    }
  };

  const menuItems = [
    {
      label: 'Edit',
      onClick: handleEdit,
      icon: ActionMenuIcons.edit,
      disabled: modifiable ? !modifiable.canModify : false,
      tooltip: modifiable?.reason || undefined,
    },
    {
      label: 'Delete',
      onClick: handleDeleteClick,
      icon: ActionMenuIcons.delete,
      isDestructive: true,
      disabled: modifiable ? !modifiable.canModify : false,
      tooltip: modifiable?.reason || undefined,
    },
  ];

  return (
    <>
      <div onMouseEnter={checkModifiable}>
        <ActionMenu items={menuItems} disabled={isLoading} />
      </div>

      <DeleteConfirmDialog
        isOpen={showDeleteDialog}
        title="Delete Recipe"
        message={`Are you sure you want to delete "${recipeTitle}"? This action cannot be undone.`}
        onConfirm={handleDeleteConfirm}
        onCancel={() => setShowDeleteDialog(false)}
        isDeleting={isDeleting}
      />

      {/* Error toast */}
      {error && (
        <div className="fixed bottom-4 right-4 z-50 bg-[var(--error)] text-white px-4 py-3 rounded-lg shadow-lg max-w-sm animate-fade-in">
          <div className="flex items-start gap-3">
            <svg className="w-5 h-5 flex-shrink-0 mt-0.5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M12 9v2m0 4h.01m-6.938 4h13.856c1.54 0 2.502-1.667 1.732-3L13.732 4c-.77-1.333-2.694-1.333-3.464 0L3.34 16c-.77 1.333.192 3 1.732 3z" />
            </svg>
            <div className="flex-1">
              <p className="font-medium">Cannot modify recipe</p>
              <p className="text-sm opacity-90">{error}</p>
            </div>
            <button
              onClick={() => setError(null)}
              className="text-white/80 hover:text-white"
            >
              <svg className="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M6 18L18 6M6 6l12 12" />
              </svg>
            </button>
          </div>
        </div>
      )}
    </>
  );
}
