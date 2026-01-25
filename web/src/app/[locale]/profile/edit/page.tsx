'use client';

import { useState, useEffect } from 'react';
import { useRouter, usePathname, Link } from '@/i18n/navigation';
import { type Locale } from '@/i18n/routing';
import { useTranslations } from 'next-intl';
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
const MIN_USERNAME_LENGTH = 5;
const MAX_USERNAME_LENGTH = 30;
const USERNAME_PATTERN = /^[a-zA-Z][a-zA-Z0-9._-]{4,29}$/;
const MAX_BIO_LENGTH = 150;
const MAX_YOUTUBE_URL_LENGTH = 200;
const MAX_INSTAGRAM_HANDLE_LENGTH = 30;

// Gender options moved inside component for translations

// Short code locale options (matching Header.tsx)
const LOCALE_OPTIONS = [
  { value: 'en', label: 'English' },
  { value: 'zh', label: '中文' },
  { value: 'es', label: 'Español' },
  { value: 'ja', label: '日本語' },
  { value: 'de', label: 'Deutsch' },
  { value: 'fr', label: 'Français' },
  { value: 'pt', label: 'Português' },
  { value: 'ko', label: '한국어' },
  { value: 'it', label: 'Italiano' },
  { value: 'ar', label: 'العربية' },
  { value: 'ru', label: 'Русский' },
  { value: 'id', label: 'Bahasa Indonesia' },
  { value: 'vi', label: 'Tiếng Việt' },
  { value: 'hi', label: 'हिन्दी' },
  { value: 'th', label: 'ไทย' },
  { value: 'pl', label: 'Polski' },
  { value: 'tr', label: 'Türkçe' },
  { value: 'nl', label: 'Nederlands' },
  { value: 'sv', label: 'Svenska' },
  { value: 'fa', label: 'فارسی' },
];

// Helper to convert BCP47 format to short code (e.g., 'ko-KR' -> 'ko')
function bcp47ToShortCode(bcp47: string): string {
  if (!bcp47) return '';
  return bcp47.split('-')[0].toLowerCase();
}

// Measurement options moved inside component for translations

function getMaxBirthDate(): string {
  const today = new Date();
  today.setFullYear(today.getFullYear() - 13);
  return today.toISOString().split('T')[0];
}

function validateYoutubeUrl(value: string): string | null {
  if (!value) return null;
  const regex =
    /^(https?:\/\/)?(www\.)?(youtube\.com\/(channel\/|c\/|user\/|@)[\w-]+|youtu\.be\/[\w-]+)\/?$/;
  if (!regex.test(value)) return 'errorYoutube';
  return null;
}

function validateInstagramHandle(value: string): string | null {
  if (!value) return null;
  const handleRegex = /^@?[a-zA-Z0-9._]{1,30}$/;
  const urlRegex =
    /^(https?:\/\/)?(www\.)?instagram\.com\/[a-zA-Z0-9._]{1,30}\/?$/;
  if (!handleRegex.test(value) && !urlRegex.test(value)) {
    return 'errorInstagram';
  }
  return null;
}

function validateUsername(value: string): boolean {
  return USERNAME_PATTERN.test(value);
}

export default function ProfileEditPage() {
  const router = useRouter();
  const pathname = usePathname();
  const { user: authUser, isLoading: authLoading } = useAuth();
  const cookingStyleOptions = useCookingStyleOptions();
  const tUsernameValidation = useTranslations('usernameValidation');
  const t = useTranslations('profileEdit');

  // Options with translations
  const genderOptions = [
    { value: '', label: t('genderSelect') },
    { value: 'MALE', label: t('genderMale') },
    { value: 'FEMALE', label: t('genderFemale') },
    { value: 'OTHER', label: t('genderOther') },
  ];

  const measurementOptions = [
    { value: 'ORIGINAL', label: t('measurementOriginal') },
    { value: 'METRIC', label: t('measurementMetric') },
    { value: 'US', label: t('measurementUS') },
  ];

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
  const [usernameFormatError, setUsernameFormatError] = useState<string | null>(null);

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
          locale: bcp47ToShortCode(profile.locale) || '',  // Convert BCP47 to short code
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
        setError(t('errorLoad'));
      } finally {
        setIsLoading(false);
      }
    }

    loadProfile();
  }, [authUser, authLoading, router, t]);

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

  // Handle username change - reset availability check and validate format
  const handleUsernameChange = (value: string) => {
    setUsername(value);
    setUsernameAvailable(null);

    // Clear format error when typing, will be validated on check/submit
    if (value.trim() && !validateUsername(value)) {
      setUsernameFormatError(tUsernameValidation('rules'));
    } else {
      setUsernameFormatError(null);
    }
  };

  // Check username availability
  const handleCheckUsername = async () => {
    if (!username.trim() || username === initialValues.username) {
      // Skip check if empty or same as initial
      if (username === initialValues.username) {
        setUsernameAvailable(true);
        setUsernameFormatError(null);
      }
      return;
    }

    // Validate format first
    if (!validateUsername(username)) {
      setUsernameFormatError(tUsernameValidation('rules'));
      setUsernameAvailable(null);
      return;
    }

    setUsernameFormatError(null);
    setIsCheckingUsername(true);
    try {
      const available = await checkUsernameAvailability(username);
      setUsernameAvailable(available);
      if (!available) {
        setUsernameFormatError(tUsernameValidation('taken'));
      }
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
      setError(t('errorBio', { max: MAX_BIO_LENGTH }));
      return;
    }

    // Validate username
    if (!username.trim()) {
      setError(t('errorUsername'));
      return;
    }
    if (username.length < MIN_USERNAME_LENGTH || username.length > MAX_USERNAME_LENGTH) {
      setError(t('errorUsernameTooLong', { max: MAX_USERNAME_LENGTH }));
      return;
    }
    if (!validateUsername(username)) {
      setUsernameFormatError(tUsernameValidation('rules'));
      setError(tUsernameValidation('rules'));
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

      // Sync locale change with URL and localStorage (like navbar does)
      if (locale !== initialValues.locale && locale) {
        localStorage.setItem('userLocale', locale);
        // Navigate with new locale - this will change the URL locale
        if (authUser?.publicId) {
          router.replace(`/users/${authUser.publicId}`, { locale: locale as Locale });
        } else {
          router.replace(pathname, { locale: locale as Locale });
        }
        return; // Let the locale change handle the navigation
      }

      setSuccessMessage(t('successUpdate'));

      // Redirect after success
      setTimeout(() => {
        if (authUser?.publicId) {
          router.push(`/users/${authUser.publicId}`);
        }
      }, 1500);
    } catch (err) {
      console.error('Failed to update profile:', err);
      setError(t('errorSave'));
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
          {t('title')}
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
            {t('username')}
          </label>
          <div className="flex gap-2">
            <input
              type="text"
              value={username}
              onChange={(e) => handleUsernameChange(e.target.value)}
              placeholder={t('usernamePlaceholder')}
              maxLength={MAX_USERNAME_LENGTH}
              className="flex-1 px-4 py-3 bg-[var(--background)] border border-[var(--border)] rounded-xl focus:outline-none focus:border-[var(--primary)]"
            />
            <button
              type="button"
              onClick={handleCheckUsername}
              disabled={isCheckingUsername || !username.trim() || username === initialValues.username}
              className="px-4 py-3 bg-[var(--highlight-bg)] text-[var(--text-primary)] rounded-xl font-medium hover:bg-[var(--border)] disabled:opacity-50 disabled:cursor-not-allowed transition-colors whitespace-nowrap"
            >
              {isCheckingUsername ? t('checkingUsername') : t('checkUsername')}
            </button>
          </div>
          {/* Username availability feedback */}
          {usernameAvailable !== null && !usernameFormatError && (
            <p className={`text-xs mt-2 flex items-center gap-1 ${usernameAvailable ? 'text-green-600' : 'text-red-500'}`}>
              {usernameAvailable ? (
                <>
                  <svg className="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                    <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M5 13l4 4L19 7" />
                  </svg>
                  {t('usernameAvailable')}
                </>
              ) : (
                <>
                  <svg className="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                    <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M6 18L18 6M6 6l12 12" />
                  </svg>
                  {tUsernameValidation('taken')}
                </>
              )}
            </p>
          )}
          {/* Format error feedback */}
          {usernameFormatError && (
            <p className="text-xs mt-2 text-red-500 flex items-center gap-1">
              <svg className="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M12 9v2m0 4h.01m-6.938 4h13.856c1.54 0 2.502-1.667 1.732-3L13.732 4c-.77-1.333-2.694-1.333-3.464 0L3.34 16c-.77 1.333.192 3 1.732 3z" />
              </svg>
              {usernameFormatError}
            </p>
          )}
          <div className="flex justify-between items-center mt-1">
            <p className="text-xs text-[var(--text-secondary)]">
              {tUsernameValidation('rules')}
            </p>
            <p
              className={`text-xs ${
                username.length > MAX_USERNAME_LENGTH || username.length < MIN_USERNAME_LENGTH
                  ? 'text-red-500'
                  : 'text-[var(--text-secondary)]'
              }`}
            >
              {username.length}/{MAX_USERNAME_LENGTH}
            </p>
          </div>
        </div>

        {/* Birthday Section */}
        <div className="bg-[var(--surface)] rounded-2xl border border-[var(--border)] p-6">
          <label className="block text-sm font-medium text-[var(--text-primary)] mb-2">
            {t('birthday')}
          </label>
          <input
            type="date"
            value={birthday}
            onChange={(e) => setBirthday(e.target.value)}
            max={getMaxBirthDate()}
            className="w-full px-4 py-3 bg-[var(--background)] border border-[var(--border)] rounded-xl focus:outline-none focus:border-[var(--primary)]"
          />
          <p className="text-xs text-[var(--text-secondary)] mt-1">
            {t('birthdayHelp')}
          </p>
        </div>

        {/* Gender Section */}
        <div className="bg-[var(--surface)] rounded-2xl border border-[var(--border)] p-6">
          <label className="block text-sm font-medium text-[var(--text-primary)] mb-2">
            {t('gender')}
          </label>
          <select
            value={gender}
            onChange={(e) => setGender(e.target.value)}
            className="w-full px-4 py-3 bg-[var(--background)] border border-[var(--border)] rounded-xl focus:outline-none focus:border-[var(--primary)]"
          >
            {genderOptions.map((opt) => (
              <option key={opt.value} value={opt.value}>
                {opt.label}
              </option>
            ))}
          </select>
        </div>

        {/* Language Section */}
        <div className="bg-[var(--surface)] rounded-2xl border border-[var(--border)] p-6">
          <label className="block text-sm font-medium text-[var(--text-primary)] mb-2">
            {t('language')}
          </label>
          <select
            value={locale}
            onChange={(e) => setLocale(e.target.value)}
            className="w-full px-4 py-3 bg-[var(--background)] border border-[var(--border)] rounded-xl focus:outline-none focus:border-[var(--primary)]"
          >
            <option value="">{t('languageSelect')}</option>
            {LOCALE_OPTIONS.map((opt) => (
              <option key={opt.value} value={opt.value}>
                {opt.label}
              </option>
            ))}
          </select>
          <p className="text-xs text-[var(--text-secondary)] mt-1">
            {t('languageHelp')}
          </p>
        </div>

        {/* Default Food Style Section */}
        <div className="bg-[var(--surface)] rounded-2xl border border-[var(--border)] p-6">
          <label className="block text-sm font-medium text-[var(--text-primary)] mb-2">
            {t('defaultFoodStyle')}
          </label>
          <CookingStyleSelect
            value={foodStyle}
            onChange={setFoodStyle}
            options={cookingStyleOptions}
            placeholder={t('foodStylePlaceholder')}
          />
          <p className="text-xs text-[var(--text-secondary)] mt-1">
            {t('foodStyleHelp')}
          </p>
        </div>

        {/* Measurement Units Section */}
        <div className="bg-[var(--surface)] rounded-2xl border border-[var(--border)] p-6">
          <label className="block text-sm font-medium text-[var(--text-primary)] mb-2">
            {t('measurementUnits')}
          </label>
          <select
            value={measurementPref}
            onChange={(e) => setMeasurementPref(e.target.value)}
            className="w-full px-4 py-3 bg-[var(--background)] border border-[var(--border)] rounded-xl focus:outline-none focus:border-[var(--primary)]"
          >
            {measurementOptions.map((opt) => (
              <option key={opt.value} value={opt.value}>
                {opt.label}
              </option>
            ))}
          </select>
          <p className="text-xs text-[var(--text-secondary)] mt-1">
            {t('measurementHelp')}
          </p>
        </div>

        {/* Bio Section */}
        <div className="bg-[var(--surface)] rounded-2xl border border-[var(--border)] p-6">
          <label className="block text-sm font-medium text-[var(--text-primary)] mb-2">
            {t('bio')}
          </label>
          <textarea
            value={bio}
            onChange={(e) => setBio(e.target.value.slice(0, MAX_BIO_LENGTH))}
            placeholder={t('bioPlaceholder')}
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
            {t('socialLinks')}
          </h3>

          {/* YouTube URL */}
          <div>
            <label className="block text-xs text-[var(--text-secondary)] mb-1">
              {t('youtubeUrl')}
            </label>
            <input
              type="text"
              value={youtubeUrl}
              onChange={(e) => handleYoutubeChange(e.target.value)}
              placeholder={t('youtubePlaceholder')}
              maxLength={MAX_YOUTUBE_URL_LENGTH}
              className={`w-full px-4 py-3 bg-[var(--background)] border rounded-xl focus:outline-none ${
                youtubeError
                  ? 'border-red-500 focus:border-red-500'
                  : 'border-[var(--border)] focus:border-[var(--primary)]'
              }`}
            />
            {youtubeError ? (
              <p className="text-xs text-red-500 mt-1">{youtubeError && t(youtubeError as 'errorYoutube')}</p>
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
              {t('instagramHandle')}
            </label>
            <input
              type="text"
              value={instagramHandle}
              onChange={(e) => handleInstagramChange(e.target.value)}
              placeholder={t('instagramPlaceholder')}
              maxLength={MAX_INSTAGRAM_HANDLE_LENGTH}
              className={`w-full px-4 py-3 bg-[var(--background)] border rounded-xl focus:outline-none ${
                instagramError
                  ? 'border-red-500 focus:border-red-500'
                  : 'border-[var(--border)] focus:border-[var(--primary)]'
              }`}
            />
            {instagramError ? (
              <p className="text-xs text-red-500 mt-1">{instagramError && t(instagramError as 'errorInstagram')}</p>
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
          disabled={!hasChanges || isSubmitting || !!youtubeError || !!instagramError || !!usernameFormatError}
          className="w-full py-3 bg-[var(--primary)] text-white rounded-xl font-medium hover:opacity-90 disabled:opacity-50 disabled:cursor-not-allowed transition-opacity"
        >
          {isSubmitting ? t('saving') : t('saveChanges')}
        </button>
      </form>
    </div>
  );
}
