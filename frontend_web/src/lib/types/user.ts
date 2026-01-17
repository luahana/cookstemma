/**
 * Gender type
 */
export type Gender = 'MALE' | 'FEMALE' | 'OTHER' | 'PREFER_NOT_TO_SAY';

/**
 * Measurement preference type
 */
export type MeasurementPreference = 'METRIC' | 'US' | 'ORIGINAL';

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
  measurementPreference: MeasurementPreference | null;
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
 * Update profile request data
 */
export interface UpdateProfileRequest {
  username?: string | null;
  gender?: string | null;
  birthDate?: string | null;
  locale?: string | null;
  defaultFoodStyle?: string | null;
  measurementPreference?: MeasurementPreference | null;
  bio?: string | null;
  youtubeUrl?: string | null;
  instagramHandle?: string | null;
}

/**
 * My profile response data
 */
export interface MyProfileResponse {
  user: UserProfile;
  recipeCount: number;
  logCount: number;
  savedCount: number;
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
