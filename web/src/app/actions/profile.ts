'use server';

import { revalidatePath } from 'next/cache';

export async function revalidateProfile(publicId: string) {
  revalidatePath(`/en/users/${publicId}`);
  revalidatePath(`/ko/users/${publicId}`);
}
