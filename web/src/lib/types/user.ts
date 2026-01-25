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
  defaultCookingStyle: string | null;
  measurementPreference: MeasurementPreference | null;
  followerCount: number;
  followingCount: number;
  recipeCount: number;
  logCount: number;
  level: number;
  levelName: string;
  // XP Progress fields for profile display
  totalXp: number | null;
  xpForCurrentLevel: number | null;
  xpForNextLevel: number | null;
  levelProgress: number | null; // 0.0-1.0
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
  defaultCookingStyle?: string | null;
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
 * Level name display mapping (100-level, 12-tier system)
 * All tiers end with "Cook" or "Chef" (except Beginner).
 * Cook tiers (1-6): Learning and hobbyist levels
 * Chef tiers (7-12): Professional levels
 *
 * Tier 1: Levels 1-8 (Beginner)
 * Tier 2: Levels 9-16 (Novice Cook)
 * Tier 3: Levels 17-25 (Home Cook)
 * Tier 4: Levels 26-34 (Hobby Cook)
 * Tier 5: Levels 35-44 (Skilled Cook)
 * Tier 6: Levels 45-54 (Expert Cook)
 * Tier 7: Levels 55-64 (Junior Chef)
 * Tier 8: Levels 65-74 (Sous Chef)
 * Tier 9: Levels 75-84 (Chef)
 * Tier 10: Levels 85-92 (Head Chef)
 * Tier 11: Levels 93-99 (Executive Chef)
 * Tier 12: Level 100 (Master Chef)
 */
export const LEVEL_NAMES: Record<string, string> = {
  beginner: 'Beginner',
  noviceCook: 'Novice Cook',
  homeCook: 'Home Cook',
  hobbyCook: 'Hobby Cook',
  skilledCook: 'Skilled Cook',
  expertCook: 'Expert Cook',
  juniorChef: 'Junior Chef',
  sousChef: 'Sous Chef',
  chef: 'Chef',
  headChef: 'Head Chef',
  executiveChef: 'Executive Chef',
  masterChef: 'Master Chef',
};

/**
 * Tier thresholds (XP required to reach end of each tier)
 */
const TIER_THRESHOLDS = {
  8: 800, // End of Beginner
  16: 2000, // End of Kitchen Helper
  25: 4500, // End of Home Cook
  34: 8000, // End of Cooking Enthusiast
  44: 14000, // End of Skilled Cook
  54: 22000, // End of Amateur Chef
  64: 32000, // End of Home Chef
  74: 45000, // End of Sous Chef
  84: 62000, // End of Chef
  92: 80000, // End of Head Chef
  99: 99000, // End of Executive Chef
  100: 100000, // Master Chef
};

/**
 * Get the next tier key based on current level (for translation lookup)
 */
export function getNextTierKey(level: number): string | null {
  if (level <= 8) return 'noviceCook';
  if (level <= 16) return 'homeCook';
  if (level <= 25) return 'hobbyCook';
  if (level <= 34) return 'skilledCook';
  if (level <= 44) return 'expertCook';
  if (level <= 54) return 'juniorChef';
  if (level <= 64) return 'sousChef';
  if (level <= 74) return 'chef';
  if (level <= 84) return 'headChef';
  if (level <= 92) return 'executiveChef';
  if (level < 100) return 'masterChef';
  return null; // Already at max
}

/**
 * Get XP needed to reach next tier
 */
export function getXpToNextTier(level: number, totalXp: number): number | null {
  if (level <= 8) return TIER_THRESHOLDS[8] - totalXp;
  if (level <= 16) return TIER_THRESHOLDS[16] - totalXp;
  if (level <= 25) return TIER_THRESHOLDS[25] - totalXp;
  if (level <= 34) return TIER_THRESHOLDS[34] - totalXp;
  if (level <= 44) return TIER_THRESHOLDS[44] - totalXp;
  if (level <= 54) return TIER_THRESHOLDS[54] - totalXp;
  if (level <= 64) return TIER_THRESHOLDS[64] - totalXp;
  if (level <= 74) return TIER_THRESHOLDS[74] - totalXp;
  if (level <= 84) return TIER_THRESHOLDS[84] - totalXp;
  if (level <= 92) return TIER_THRESHOLDS[92] - totalXp;
  if (level < 100) return TIER_THRESHOLDS[100] - totalXp; // Master Chef at 100k
  return null; // Already at max
}
