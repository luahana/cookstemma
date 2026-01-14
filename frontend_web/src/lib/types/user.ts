/**
 * Gender type
 */
export type Gender = 'MALE' | 'FEMALE' | 'OTHER' | 'PREFER_NOT_TO_SAY';

/**
 * User profile data
 */
export interface UserProfile {
  id: string; // publicId
  username: string;
  profileImageUrl: string | null;
  gender: Gender | null;
  birthDate: string | null;
  locale: string | null;
  defaultFoodStyle: string | null;
  followerCount: number;
  followingCount: number;
  recipeCount: number;
  logCount: number;
  level: number;
  levelName: string;
  bio: string | null;
  youtubeUrl: string | null;
  instagramHandle: string | null;
}

/**
 * Level name display mapping
 */
export const LEVEL_NAMES: Record<string, string> = {
  beginner: 'Beginner',
  homeCook: 'Home Cook',
  apprentice: 'Apprentice',
  lineCook: 'Line Cook',
  sousChef: 'Sous Chef',
  chef: 'Chef',
  headChef: 'Head Chef',
  executiveChef: 'Executive Chef',
  masterChef: 'Master Chef',
};
