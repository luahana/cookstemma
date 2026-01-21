'use client';

import { useAuth } from '@/contexts/AuthContext';
import { VisibilityFilter } from './VisibilityFilter';

interface ProfileVisibilityFilterProps {
  profilePublicId: string;
  currentTab: string;
  currentVisibility: 'all' | 'public' | 'private';
}

export function ProfileVisibilityFilter({
  profilePublicId,
  currentTab,
  currentVisibility,
}: ProfileVisibilityFilterProps) {
  const { user, isAuthenticated } = useAuth();

  // Only show visibility filter for own profile
  if (!isAuthenticated || !user || user.publicId !== profilePublicId) {
    return null;
  }

  return (
    <VisibilityFilter
      profilePublicId={profilePublicId}
      currentTab={currentTab}
      currentVisibility={currentVisibility}
    />
  );
}
