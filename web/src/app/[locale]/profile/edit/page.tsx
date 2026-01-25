'use client';

import { useState, useEffect } from 'react';
import { useRouter } from 'next/navigation';
import { Link } from '@/i18n/navigation';
import { useAuth } from '@/contexts/AuthContext';
import { getMyProfile, updateUserProfile, checkUsernameAvailability } from '@/lib/api/users';
import {
  CookingStyleSelect,
  useCookingStyleOptions,
} from '@/components/common/CookingStyleSelect';
import { LoadingSpinner } from '@/components/common/LoadingSpinner';
import { revalidateProfile } from '@/app/actions/profile';
import type { MeasurementPreference, UpdateProfileRequest } from '@/lib/types';
import { MEASUREMENT_STORAGE_KEY } from '@/lib/utils/measurement';

// Character limits (matching database constraints)
const MAX_USERNAME_LENGTH = 50;
const MAX_BIO_LENGTH = 150;
const MAX_YOUTUBE_URL_LENGTH = 200;
const MAX_INSTAGRAM_HANDLE_LENGTH = 30;

const GENDER_OPTIONS = [
  { value: '', label: 'Select gender' },
  { value: 'MALE', label: 'Male' },
  { value: 'FEMALE', label: 'Female' },
  { value: 'OTHER', label: 'Other' },
];

const LOCALE_OPTIONS = [
  { value: 'ko-KR', label: '한국어' },
  { value: 'en-US', label: 'English' },
  { value: 'ja-JP', label: '日本語' },
  { value: 'zh-CN', label: '简体中文' },
  { value: 'zh-TW', label: '繁體中文' },
  { value: 'es-ES', label: 'Español' },
  { value: 'fr-FR', label: 'Français' },
  { value: 'de-DE', label: 'Deutsch' },
  { value: 'it-IT', label: 'Italiano' },
  { value: 'pt-BR', label: 'Português' },
  { value: 'vi-VN', label: 'Tiếng Việt' },
];

const MEASUREMENT_OPTIONS = [
  { value: 'ORIGINAL', label: 'Original (as entered)' },
  { value: 'METRIC', label: 'Metric (g, ml)' },
  { value: 'US', label: 'US (cups, oz)' },
];

function getMaxBirthDate(): string {
  const today = new Date();
  today.setFullYear(today.getFullYear() - 13);
  return today.toISOString().split('T')[0];
}

function validateYoutubeUrl(value: string): string | null {
  if (!value) return null;
  const regex =
    /^(https?:\/\/)?(www\.)?(youtube\.com\/(channel\/|c\/|user\/|@)[\w-]+|youtu\.be\/[\w-]+)\/?$/;
  if (!regex.test(value)) return 'Invalid YouTube URL format';
  return null;
}

function validateInstagramHandle(value: string): string | null {
  if (!value) return null;
  const handleRegex = /^@?[a-zA-Z0-9._]{1,30}$/;
  const urlRegex =
    /^(https?:\/\/)?(www\.)?instagram\.com\/[a-zA-Z0-9._]{1,30}\/?$/;
  if (!handleRegex.test(value) && !urlRegex.test(value)) {
    return 'Invalid Instagram handle format';
  }
  return null;
}

export default function ProfileEditPage() {
  const router = useRouter();
  const { user: authUser, isLoading: authLoading } = useAuth();
  const cookingStyleOptions = useCookingStyleOptions();

  // Form state
  const [username, setUsername] = useState('');
  const [birthday, setBirthday] = useState('');
  const [gender, setGender] = useState('');
  const [locale, setLocale] = useState('');
  const [foodStyle, setFoodStyle] = useState('international');
  const [measurementPref, setMeasurementPref] = useState('ORIGINAL');
  const [bio, setBio] = useState('');
  const [youtubeUrl, setYoutubeUrl] = useState('');
  const [instagramHandle, setInstagramHandle] = useState('');

  // Initial values for change tracking
  const [initialValues, setInitialValues] = useState({
    username: '',
    birthday: '',
    gender: '',
    locale: '',
    foodStyle: 'international',
    measurementPref: 'ORIGINAL',
    bio: '',
    youtubeUrl: '',
    instagramHandle: '',
  });

  // UI state
  const [isLoading, setIsLoading] = useState(true);
  const [isSubmitting, setIsSubmitting] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [successMessage, setSuccessMessage] = useState<string | null>(null);

  // Validation errors
  const [youtubeError, setYoutubeError] = useState<string | null>(null);
  const [instagramError, setInstagramError] = useState<string | null>(null);

  // Username availability check
  const [isCheckingUsername, setIsCheckingUsername] = useState(false);
  const [usernameAvailable, setUsernameAvailable] = useState<boolean | null>(null);

  // Load profile data
  useEffect(() => {
    if (authLoading) return;

    if (!authUser) {
      router.push('/login');
      return;
    }

    async function loadProfile() {
      try {
        const response = await getMyProfile();
        const profile = response.user;

        const values = {
          username: profile.username || '',
          birthday: profile.birthDate || '',
          gender: profile.gender || '',
          locale: profile.locale || '',
          foodStyle: profile.defaultCookingStyle || 'international',
          measurementPref: profile.measurementPreference || 'ORIGINAL',
          bio: profile.bio || '',
          youtubeUrl: profile.youtubeUrl || '',
          instagramHandle: profile.instagramHandle || '',
        };

        setUsername(values.username);
        setBirthday(values.birthday);
        setGender(values.gender);
        setLocale(values.locale);
        setFoodStyle(values.foodStyle);
        setMeasurementPref(values.measurementPref);
        setBio(values.bio);
        setYoutubeUrl(values.youtubeUrl);
        setInstagramHandle(values.instagramHandle);
        setInitialValues(values);
      } catch (err) {
        console.error('Failed to load profile:', err);
        setError('Failed to load profile data');
      } finally {
        setIsLoading(false);
      }
    }

    loadProfile();
  }, [authUser, authLoading, router]);

  // Check for changes
  const hasChanges =
    username !== initialValues.username ||
    birthday !== initialValues.birthday ||
    gender !== initialValues.gender ||
    locale !== initialValues.locale ||
    foodStyle !== initialValues.foodStyle ||
    measurementPref !== initialValues.measurementPref ||
    bio !== initialValues.bio ||
    youtubeUrl !== initialValues.youtubeUrl ||
    instagramHandle !== initialValues.instagramHandle;

  // Handle YouTube URL change with validation
  const handleYoutubeChange = (value: string) => {
    setYoutubeUrl(value);
    setYoutubeError(validateYoutubeUrl(value));
  };

  // Handle Instagram handle change with validation
  const handleInstagramChange = (value: string) => {
    setInstagramHandle(value);
    setInstagramError(validateInstagramHandle(value));
  };

  // Handle username change - reset availability check
  const handleUsernameChange = (value: string) => {
    setUsername(value);
    setUsernameAvailable(null);
  };

  // Check username availability
  const handleCheckUsername = async () => {
    if (!username.trim() || username === initialValues.username) {
      // Skip check if empty or same as initial
      if (username === initialValues.username) {
        setUsernameAvailable(true);
      }
      return;
    }

    setIsCheckingUsername(true);
    try {
      const available = await checkUsernameAvailability(username);
      setUsernameAvailable(available);
    } catch (err) {
      console.error('Failed to check username:', err);
      setUsernameAvailable(null);
    } finally {
      setIsCheckingUsername(false);
    }
  };

  // Handle form submission
  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();

    // Validate before submit
    const ytError = validateYoutubeUrl(youtubeUrl);
    const igError = validateInstagramHandle(instagramHandle);

    if (ytError || igError) {
      setYoutubeError(ytError);
      setInstagramError(igError);
      return;
    }

    if (bio.length > MAX_BIO_LENGTH) {
      setError(`Bio cannot exceed ${MAX_BIO_LENGTH} characters`);
      return;
    }

    // Validate username
    if (!username.trim()) {
      setError('Username is required');
      return;
    }
    if (username.length > MAX_USERNAME_LENGTH) {
      setError(`Username cannot exceed ${MAX_USERNAME_LENGTH} characters`);
      return;
    }

    setIsSubmitting(true);
    setError(null);
    setSuccessMessage(null);

    try {
      const updateData: UpdateProfileRequest = {};

      // Only include changed fields
      if (username !== initialValues.username) {
        updateData.username = username;
      }
      if (birthday !== initialValues.birthday) {
        updateData.birthDate = birthday || null;
      }
      if (gender !== initialValues.gender) {
        updateData.gender = gender || null;
      }
      if (locale !== initialValues.locale) {
        updateData.locale = locale || null;
      }
      if (foodStyle !== initialValues.foodStyle) {
        // Convert 'international' back to null for API
        updateData.defaultCookingStyle = foodStyle === 'international' ? null : foodStyle;
      }
      if (measurementPref !== initialValues.measurementPref) {
        updateData.measurementPreference =
          (measurementPref as MeasurementPreference) || null;
      }
      if (bio !== initialValues.bio) {
        updateData.bio = bio || null;
      }
      if (youtubeUrl !== initialValues.youtubeUrl) {
        updateData.youtubeUrl = youtubeUrl || null;
      }
      if (instagramHandle !== initialValues.instagramHandle) {
        updateData.instagramHandle = instagramHandle || null;
      }

      await updateUserProfile(updateData);

      // Sync measurement preference to localStorage for instant effect on recipe pages
      if (measurementPref !== initialValues.measurementPref) {
        localStorage.setItem(MEASUREMENT_STORAGE_KEY, measurementPref);
      }

      // Revalidate the user's public profile page to clear cache
      if (authUser?.publicId) {
        await revalidateProfile(authUser.publicId);
      }

      // Update initial values to new values
      setInitialValues({
        username,
        birthday,
        gender,
        locale,
        foodStyle,
        measurementPref,
        bio,
        youtubeUrl,
        instagramHandle,
      });

      setSuccessMessage('Profile updated successfully!');

      // If locale changed, suggest page refresh
      if (locale !== initialValues.locale) {
        setSuccessMessage(
          'Profile updated! Language change will take effect after refreshing the page.',
        );
      }

      // Redirect after success
      setTimeout(() => {
        if (authUser?.publicId) {
          router.push(`/users/${authUser.publicId}`);
        }
      }, 1500);
    } catch (err) {
      console.error('Failed to update profile:', err);
      setError('Failed to update profile. Please try again.');
    } finally {
      setIsSubmitting(false);
    }
  };

  if (authLoading || isLoading) {
    return <LoadingSpinner />;
  }

  return (
    <div className="max-w-2xl mx-auto px-4 py-8">
      {/* Header */}
      <div className="flex items-center gap-4 mb-8">
        <Link
          href={authUser?.publicId ? `/users/${authUser.publicId}` : '/'}
          className="p-2 hover:bg-[var(--highlight-bg)] rounded-lg transition-colors"
        >
          <svg
            className="w-6 h-6 text-[var(--text-primary)]"
            fill="none"
            stroke="currentColor"
            viewBox="0 0 24 24"
          >
            <path
              strokeLinecap="round"
              strokeLinejoin="round"
              strokeWidth={2}
              d="M15 19l-7-7 7-7"
            />
          </svg>
        </Link>
        <h1 className="text-2xl font-bold text-[var(--text-primary)]">
          Edit Profile
        </h1>
      </div>

      {/* Error/Success messages */}
      {error && (
        <div className="mb-6 p-4 bg-red-100 border border-red-300 text-red-700 rounded-xl">
          {error}
        </div>
      )}
      {successMessage && (
        <div className="mb-6 p-4 bg-green-100 border border-green-300 text-green-700 rounded-xl">
          {successMessage}
        </div>
      )}

      <form onSubmit={handleSubmit} className="space-y-6">
        {/* Username Section */}
        <div className="bg-[var(--surface)] rounded-2xl border border-[var(--border)] p-6">
          <label className="block text-sm font-medium text-[var(--text-primary)] mb-2">
            Username
          </label>
          <div className="flex gap-2">
            <input
              type="text"
              value={username}
              onChange={(e) => handleUsernameChange(e.target.value)}
              placeholder="Enter your username"
              maxLength={MAX_USERNAME_LENGTH}
              className="flex-1 px-4 py-3 bg-[var(--background)] border border-[var(--border)] rounded-xl focus:outline-none focus:border-[var(--primary)]"
            />
            <button
              type="button"
              onClick={handleCheckUsername}
              disabled={isCheckingUsername || !username.trim() || username === initialValues.username}
              className="px-4 py-3 bg-[var(--highlight-bg)] text-[var(--text-primary)] rounded-xl font-medium hover:bg-[var(--border)] disabled:opacity-50 disabled:cursor-not-allowed transition-colors whitespace-nowrap"
            >
              {isCheckingUsername ? 'Checking...' : 'Check'}
            </button>
          </div>
          {/* Username availability feedback */}
          {usernameAvailable !== null && (
            <p className={`text-xs mt-2 flex items-center gap-1 ${usernameAvailable ? 'text-green-600' : 'text-red-500'}`}>
              {usernameAvailable ? (
                <>
                  <svg className="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                    <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M5 13l4 4L19 7" />
                  </svg>
                  Username is available
                </>
              ) : (
                <>
                  <svg className="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                    <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M6 18L18 6M6 6l12 12" />
                  </svg>
                  Username is already taken
                </>
              )}
            </p>
          )}
          <p
            className={`text-xs mt-1 text-right ${
              username.length >= MAX_USERNAME_LENGTH
                ? 'text-red-500'
                : 'text-[var(--text-secondary)]'
            }`}
          >
            {username.length}/{MAX_USERNAME_LENGTH}
          </p>
        </div>

        {/* Birthday Section */}
        <div className="bg-[var(--surface)] rounded-2xl border border-[var(--border)] p-6">
          <label className="block text-sm font-medium text-[var(--text-primary)] mb-2">
            Birthday
          </label>
          <input
            type="date"
            value={birthday}
            onChange={(e) => setBirthday(e.target.value)}
            max={getMaxBirthDate()}
            className="w-full px-4 py-3 bg-[var(--background)] border border-[var(--border)] rounded-xl focus:outline-none focus:border-[var(--primary)]"
          />
          <p className="text-xs text-[var(--text-secondary)] mt-1">
            You must be at least 13 years old
          </p>
        </div>

        {/* Gender Section */}
        <div className="bg-[var(--surface)] rounded-2xl border border-[var(--border)] p-6">
          <label className="block text-sm font-medium text-[var(--text-primary)] mb-2">
            Gender
          </label>
          <select
            value={gender}
            onChange={(e) => setGender(e.target.value)}
            className="w-full px-4 py-3 bg-[var(--background)] border border-[var(--border)] rounded-xl focus:outline-none focus:border-[var(--primary)]"
          >
            {GENDER_OPTIONS.map((opt) => (
              <option key={opt.value} value={opt.value}>
                {opt.label}
              </option>
            ))}
          </select>
        </div>

        {/* Language Section */}
        <div className="bg-[var(--surface)] rounded-2xl border border-[var(--border)] p-6">
          <label className="block text-sm font-medium text-[var(--text-primary)] mb-2">
            Language
          </label>
          <select
            value={locale}
            onChange={(e) => setLocale(e.target.value)}
            className="w-full px-4 py-3 bg-[var(--background)] border border-[var(--border)] rounded-xl focus:outline-none focus:border-[var(--primary)]"
          >
            <option value="">Select language</option>
            {LOCALE_OPTIONS.map((opt) => (
              <option key={opt.value} value={opt.value}>
                {opt.label}
              </option>
            ))}
          </select>
          <p className="text-xs text-[var(--text-secondary)] mt-1">
            Language changes may require a page refresh
          </p>
        </div>

        {/* Default Food Style Section */}
        <div className="bg-[var(--surface)] rounded-2xl border border-[var(--border)] p-6">
          <label className="block text-sm font-medium text-[var(--text-primary)] mb-2">
            Default Food Style
          </label>
          <CookingStyleSelect
            value={foodStyle}
            onChange={setFoodStyle}
            options={cookingStyleOptions}
            placeholder="Select food style"
          />
          <p className="text-xs text-[var(--text-secondary)] mt-1">
            Your preferred cuisine style for recipes
          </p>
        </div>

        {/* Measurement Units Section */}
        <div className="bg-[var(--surface)] rounded-2xl border border-[var(--border)] p-6">
          <label className="block text-sm font-medium text-[var(--text-primary)] mb-2">
            Measurement Units
          </label>
          <select
            value={measurementPref}
            onChange={(e) => setMeasurementPref(e.target.value)}
            className="w-full px-4 py-3 bg-[var(--background)] border border-[var(--border)] rounded-xl focus:outline-none focus:border-[var(--primary)]"
          >
            {MEASUREMENT_OPTIONS.map((opt) => (
              <option key={opt.value} value={opt.value}>
                {opt.label}
              </option>
            ))}
          </select>
          <p className="text-xs text-[var(--text-secondary)] mt-1">
            How measurements are displayed in recipes
          </p>
        </div>

        {/* Bio Section */}
        <div className="bg-[var(--surface)] rounded-2xl border border-[var(--border)] p-6">
          <label className="block text-sm font-medium text-[var(--text-primary)] mb-2">
            Bio
          </label>
          <textarea
            value={bio}
            onChange={(e) => setBio(e.target.value.slice(0, MAX_BIO_LENGTH))}
            placeholder="Tell others about yourself..."
            rows={3}
            maxLength={MAX_BIO_LENGTH}
            className="w-full px-4 py-3 bg-[var(--background)] border border-[var(--border)] rounded-xl focus:outline-none focus:border-[var(--primary)] resize-none"
          />
          <p
            className={`text-xs mt-1 text-right ${
              bio.length >= MAX_BIO_LENGTH
                ? 'text-red-500'
                : 'text-[var(--text-secondary)]'
            }`}
          >
            {bio.length}/{MAX_BIO_LENGTH}
          </p>
        </div>

        {/* Social Links Section */}
        <div className="bg-[var(--surface)] rounded-2xl border border-[var(--border)] p-6 space-y-4">
          <h3 className="text-sm font-medium text-[var(--text-primary)]">
            Social Links
          </h3>

          {/* YouTube URL */}
          <div>
            <label className="block text-xs text-[var(--text-secondary)] mb-1">
              YouTube Channel URL
            </label>
            <input
              type="text"
              value={youtubeUrl}
              onChange={(e) => handleYoutubeChange(e.target.value)}
              placeholder="https://youtube.com/@yourchannel"
              maxLength={MAX_YOUTUBE_URL_LENGTH}
              className={`w-full px-4 py-3 bg-[var(--background)] border rounded-xl focus:outline-none ${
                youtubeError
                  ? 'border-red-500 focus:border-red-500'
                  : 'border-[var(--border)] focus:border-[var(--primary)]'
              }`}
            />
            {youtubeError ? (
              <p className="text-xs text-red-500 mt-1">{youtubeError}</p>
            ) : (
              <p
                className={`text-xs mt-1 text-right ${
                  youtubeUrl.length >= MAX_YOUTUBE_URL_LENGTH
                    ? 'text-red-500'
                    : 'text-[var(--text-secondary)]'
                }`}
              >
                {youtubeUrl.length}/{MAX_YOUTUBE_URL_LENGTH}
              </p>
            )}
          </div>

          {/* Instagram Handle */}
          <div>
            <label className="block text-xs text-[var(--text-secondary)] mb-1">
              Instagram Handle
            </label>
            <input
              type="text"
              value={instagramHandle}
              onChange={(e) => handleInstagramChange(e.target.value)}
              placeholder="@yourusername"
              maxLength={MAX_INSTAGRAM_HANDLE_LENGTH}
              className={`w-full px-4 py-3 bg-[var(--background)] border rounded-xl focus:outline-none ${
                instagramError
                  ? 'border-red-500 focus:border-red-500'
                  : 'border-[var(--border)] focus:border-[var(--primary)]'
              }`}
            />
            {instagramError ? (
              <p className="text-xs text-red-500 mt-1">{instagramError}</p>
            ) : (
              <p
                className={`text-xs mt-1 text-right ${
                  instagramHandle.length >= MAX_INSTAGRAM_HANDLE_LENGTH
                    ? 'text-red-500'
                    : 'text-[var(--text-secondary)]'
                }`}
              >
                {instagramHandle.length}/{MAX_INSTAGRAM_HANDLE_LENGTH}
              </p>
            )}
          </div>
        </div>

        {/* Submit Button */}
        <button
          type="submit"
          disabled={!hasChanges || isSubmitting || !!youtubeError || !!instagramError}
          className="w-full py-3 bg-[var(--primary)] text-white rounded-xl font-medium hover:opacity-90 disabled:opacity-50 disabled:cursor-not-allowed transition-opacity"
        >
          {isSubmitting ? 'Saving...' : 'Save Changes'}
        </button>
      </form>
    </div>
  );
}
