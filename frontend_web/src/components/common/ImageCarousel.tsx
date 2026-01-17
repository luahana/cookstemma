'use client';

import { useState } from 'react';
import Image from 'next/image';
import { getImageUrl } from '@/lib/utils/image';

interface ImageItem {
  imagePublicId: string;
  imageUrl: string;
}

interface ImageCarouselProps {
  images: ImageItem[];
  alt: string;
}

export function ImageCarousel({ images, alt }: ImageCarouselProps) {
  const [currentIndex, setCurrentIndex] = useState(0);

  if (images.length === 0) return null;

  // Single image - no carousel needed
  if (images.length === 1) {
    const imageUrl = getImageUrl(images[0].imageUrl);
    if (!imageUrl) return null;

    return (
      <div className="relative aspect-video rounded-2xl overflow-hidden mb-8">
        <Image
          src={imageUrl}
          alt={alt}
          fill
          className="object-cover"
          priority
          sizes="(max-width: 896px) 100vw, 896px"
        />
      </div>
    );
  }

  const goToSlide = (index: number) => {
    setCurrentIndex(index);
  };

  const goToPrevious = () => {
    setCurrentIndex((prev) => (prev === 0 ? images.length - 1 : prev - 1));
  };

  const goToNext = () => {
    setCurrentIndex((prev) => (prev === images.length - 1 ? 0 : prev + 1));
  };

  const currentImageUrl = getImageUrl(images[currentIndex].imageUrl);

  return (
    <div className="relative mb-8">
      {/* Main Image */}
      <div className="relative aspect-video rounded-2xl overflow-hidden">
        {currentImageUrl && (
          <Image
            src={currentImageUrl}
            alt={`${alt} - Image ${currentIndex + 1}`}
            fill
            className="object-cover"
            priority={currentIndex === 0}
            sizes="(max-width: 896px) 100vw, 896px"
          />
        )}

        {/* Navigation Arrows */}
        <button
          onClick={goToPrevious}
          className="absolute left-3 top-1/2 -translate-y-1/2 w-10 h-10 bg-black/50 hover:bg-black/70 rounded-full flex items-center justify-center text-white transition-colors"
          aria-label="Previous image"
        >
          <svg
            xmlns="http://www.w3.org/2000/svg"
            fill="none"
            viewBox="0 0 24 24"
            strokeWidth={2}
            stroke="currentColor"
            className="w-5 h-5"
          >
            <path
              strokeLinecap="round"
              strokeLinejoin="round"
              d="M15.75 19.5L8.25 12l7.5-7.5"
            />
          </svg>
        </button>
        <button
          onClick={goToNext}
          className="absolute right-3 top-1/2 -translate-y-1/2 w-10 h-10 bg-black/50 hover:bg-black/70 rounded-full flex items-center justify-center text-white transition-colors"
          aria-label="Next image"
        >
          <svg
            xmlns="http://www.w3.org/2000/svg"
            fill="none"
            viewBox="0 0 24 24"
            strokeWidth={2}
            stroke="currentColor"
            className="w-5 h-5"
          >
            <path
              strokeLinecap="round"
              strokeLinejoin="round"
              d="M8.25 4.5l7.5 7.5-7.5 7.5"
            />
          </svg>
        </button>

        {/* Image Counter */}
        <div className="absolute bottom-3 right-3 bg-black/60 text-white text-sm px-3 py-1 rounded-full">
          {currentIndex + 1} / {images.length}
        </div>
      </div>

      {/* Dots Indicator */}
      <div className="flex justify-center gap-2 mt-4">
        {images.map((_, index) => (
          <button
            key={index}
            onClick={() => goToSlide(index)}
            className={`w-2 h-2 rounded-full transition-colors ${
              index === currentIndex
                ? 'bg-[var(--primary)]'
                : 'bg-[var(--border)] hover:bg-[var(--text-secondary)]'
            }`}
            aria-label={`Go to image ${index + 1}`}
          />
        ))}
      </div>

      {/* Thumbnail Strip */}
      {images.length > 2 && (
        <div className="flex gap-2 mt-3 overflow-x-auto pb-2">
          {images.map((image, index) => {
            const thumbUrl = getImageUrl(image.imageUrl);
            if (!thumbUrl) return null;
            return (
              <button
                key={image.imagePublicId}
                onClick={() => goToSlide(index)}
                className={`relative w-16 h-16 flex-shrink-0 rounded-lg overflow-hidden border-2 transition-colors ${
                  index === currentIndex
                    ? 'border-[var(--primary)]'
                    : 'border-transparent hover:border-[var(--border)]'
                }`}
              >
                <Image
                  src={thumbUrl}
                  alt={`Thumbnail ${index + 1}`}
                  fill
                  className="object-cover"
                  sizes="64px"
                />
              </button>
            );
          })}
        </div>
      )}
    </div>
  );
}
