import { ImageResponse } from 'next/og';

export const runtime = 'edge';

export const alt = 'Cookstemma - Your Personal Cooking Log';
export const size = {
  width: 1200,
  height: 630,
};
export const contentType = 'image/png';

export default async function Image() {
  return new ImageResponse(
    (
      <div
        style={{
          fontSize: 48,
          background: 'linear-gradient(135deg, #ff7852 0%, #ff5a36 100%)',
          width: '100%',
          height: '100%',
          display: 'flex',
          flexDirection: 'column',
          alignItems: 'center',
          justifyContent: 'center',
          color: 'white',
          padding: '40px',
        }}
      >
        {/* Fork and spoon icon */}
        <div
          style={{
            display: 'flex',
            alignItems: 'center',
            justifyContent: 'center',
            marginBottom: '24px',
          }}
        >
          <svg
            width="80"
            height="80"
            viewBox="0 0 100 100"
            fill="white"
          >
            {/* Fork */}
            <path d="M25 10 L25 40 Q25 50 30 50 L30 90 Q30 95 35 95 Q40 95 40 90 L40 50 Q45 50 45 40 L45 10 Q45 5 42 10 L42 35 Q42 38 40 38 L40 10 Q40 5 37 10 L37 35 Q37 38 35 38 L35 10 Q35 5 32 10 L32 35 Q32 38 30 38 L30 10 Q30 5 25 10 Z" />
            {/* Spoon */}
            <path d="M65 10 Q50 10 50 30 Q50 50 65 50 L65 90 Q65 95 70 95 Q75 95 75 90 L75 50 Q90 50 90 30 Q90 10 75 10 Q70 10 65 10 Z M65 20 Q58 20 58 30 Q58 40 65 42 L75 42 Q82 40 82 30 Q82 20 75 20 Q70 20 65 20 Z" />
          </svg>
        </div>

        {/* Site name */}
        <div
          style={{
            fontSize: 72,
            fontWeight: 'bold',
            marginBottom: '16px',
            textShadow: '2px 2px 4px rgba(0,0,0,0.2)',
          }}
        >
          Cookstemma
        </div>

        {/* Tagline */}
        <div
          style={{
            fontSize: 32,
            opacity: 0.9,
            textAlign: 'center',
            maxWidth: '800px',
          }}
        >
          Log every recipe you try and become a better cook
        </div>

        {/* Bottom decoration */}
        <div
          style={{
            position: 'absolute',
            bottom: '40px',
            display: 'flex',
            alignItems: 'center',
            gap: '16px',
            fontSize: 24,
            opacity: 0.8,
          }}
        >
          <span>🍳</span>
          <span>Discover</span>
          <span>•</span>
          <span>Cook</span>
          <span>•</span>
          <span>Share</span>
          <span>🥘</span>
        </div>
      </div>
    ),
    {
      ...size,
    }
  );
}
