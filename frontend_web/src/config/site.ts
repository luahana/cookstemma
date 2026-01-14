export const siteConfig = {
  name: 'Pairing Planet',
  description: 'Share recipes, create variations, and track your cooking journey',
  url: process.env.NEXT_PUBLIC_SITE_URL || 'https://pairingplanet.com',
  apiUrl: process.env.NEXT_PUBLIC_API_URL || 'http://localhost:4001/api/v1',
  ogImage: '/images/og-default.png',
  links: {
    appStore: '#', // TODO: Add real App Store link
    playStore: '#', // TODO: Add real Play Store link
    terms: '/terms',
    privacy: '/privacy',
  },
};
