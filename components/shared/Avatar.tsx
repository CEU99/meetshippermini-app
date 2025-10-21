'use client';

import { useState } from 'react';
import Image from 'next/image';

interface AvatarProps {
  src?: string | null;
  alt: string;
  size?: number;
  className?: string;
}

/**
 * Avatar component with automatic fallback to initials
 * Handles image loading errors gracefully
 */
export function Avatar({ src, alt, size = 40, className = '' }: AvatarProps) {
  const [imageError, setImageError] = useState(false);

  // Get initials from alt text (username or display name)
  const getInitials = (name: string): string => {
    if (!name) return '?';
    const parts = name.trim().split(/\s+/);
    if (parts.length >= 2) {
      return (parts[0][0] + parts[parts.length - 1][0]).toUpperCase();
    }
    return name.slice(0, 2).toUpperCase();
  };

  // Generate consistent background color from name
  const getBackgroundColor = (name: string): string => {
    const colors = [
      'bg-purple-100 text-purple-600',
      'bg-blue-100 text-blue-600',
      'bg-green-100 text-green-600',
      'bg-yellow-100 text-yellow-600',
      'bg-pink-100 text-pink-600',
      'bg-indigo-100 text-indigo-600',
      'bg-red-100 text-red-600',
      'bg-orange-100 text-orange-600',
    ];
    const hash = name.split('').reduce((acc, char) => acc + char.charCodeAt(0), 0);
    return colors[hash % colors.length];
  };

  // If no src or image failed to load, show initials
  if (!src || imageError) {
    const initials = getInitials(alt);
    const colorClass = getBackgroundColor(alt);
    const fontSize = size >= 80 ? 'text-2xl' : size >= 48 ? 'text-lg' : 'text-sm';

    return (
      <div
        className={`rounded-full flex items-center justify-center font-medium ${colorClass} ${fontSize} ${className}`}
        style={{ width: size, height: size, minWidth: size, minHeight: size }}
        title={alt}
      >
        {initials}
      </div>
    );
  }

  // Try to render the image
  return (
    <Image
      src={src}
      alt={alt}
      width={size}
      height={size}
      className={`rounded-full ${className}`}
      onError={() => setImageError(true)}
      unoptimized={src.includes('picsum.photos')} // Bypass optimization for placeholders
    />
  );
}
