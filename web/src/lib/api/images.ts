import Cookies from 'js-cookie';
import { getApiUrl } from '@/config/site';
import type { ImageUploadResponse, ImageType } from '@/lib/types';

/**
 * Upload an image to the server
 * @param file - The file to upload
 * @param type - The type of image (LOG_POST, RECIPE, RECIPE_STEP)
 * @returns The uploaded image's publicId and URL
 */
export async function uploadImage(
  file: File,
  type: ImageType
): Promise<ImageUploadResponse> {
  const formData = new FormData();
  formData.append('file', file);
  formData.append('type', type);

  const response = await fetch(`${getApiUrl()}/images/upload`, {
    method: 'POST',
    credentials: 'include',
    headers: {
      'X-CSRF-Token': Cookies.get('csrf_token') || '',
    },
    body: formData,
  });

  if (!response.ok) {
    const errorData = await response.json().catch(() => ({}));
    throw new Error(errorData.message || 'Failed to upload image');
  }

  return response.json();
}

/**
 * Upload multiple images
 * @param files - Array of files to upload
 * @param type - The type of images
 * @returns Array of uploaded image responses
 */
export async function uploadImages(
  files: File[],
  type: ImageType
): Promise<ImageUploadResponse[]> {
  const uploadPromises = files.map((file) => uploadImage(file, type));
  return Promise.all(uploadPromises);
}
