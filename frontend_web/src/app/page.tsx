import Link from 'next/link';

export default function Home() {
  return (
    <div className="min-h-screen bg-gradient-to-b from-orange-50 to-white">
      {/* Header */}
      <header className="border-b border-gray-100 bg-white/80 backdrop-blur-sm sticky top-0">
        <div className="max-w-6xl mx-auto px-4 py-4 flex items-center justify-between">
          <div className="flex items-center gap-2">
            <span className="text-3xl">🍳</span>
            <span className="font-bold text-2xl text-gray-900">Pairing Planet</span>
          </div>
          <nav className="flex gap-6 text-sm font-medium">
            <Link href="/terms" className="text-gray-600 hover:text-orange-600 transition">
              Terms
            </Link>
            <Link href="/privacy" className="text-gray-600 hover:text-orange-600 transition">
              Privacy
            </Link>
          </nav>
        </div>
      </header>

      {/* Hero Section */}
      <main className="max-w-6xl mx-auto px-4 py-16">
        <div className="text-center">
          <h1 className="text-5xl font-bold text-gray-900 mb-6">
            Your Recipes, <span className="text-orange-600">Evolved</span>
          </h1>
          <p className="text-xl text-gray-600 max-w-2xl mx-auto mb-8">
            Share your recipes, create variations, and track your cooking journey.
            Join a community of home cooks discovering new flavors together.
          </p>

          {/* App Store Buttons Placeholder */}
          <div className="flex justify-center gap-4 mb-12">
            <div className="bg-black text-white px-6 py-3 rounded-xl flex items-center gap-2 opacity-50 cursor-not-allowed">
              <span className="text-2xl">🍎</span>
              <div className="text-left">
                <div className="text-xs">Download on the</div>
                <div className="font-semibold">App Store</div>
              </div>
            </div>
            <div className="bg-black text-white px-6 py-3 rounded-xl flex items-center gap-2 opacity-50 cursor-not-allowed">
              <span className="text-2xl">▶️</span>
              <div className="text-left">
                <div className="text-xs">Get it on</div>
                <div className="font-semibold">Google Play</div>
              </div>
            </div>
          </div>
          <p className="text-sm text-gray-400">Coming soon to iOS and Android</p>
        </div>

        {/* Features */}
        <div className="grid md:grid-cols-3 gap-8 mt-20">
          <div className="bg-white p-6 rounded-2xl shadow-sm border border-gray-100">
            <div className="text-4xl mb-4">📖</div>
            <h3 className="text-lg font-semibold text-gray-900 mb-2">Share Recipes</h3>
            <p className="text-gray-600">
              Create and share your favorite recipes with photos and step-by-step instructions.
            </p>
          </div>
          <div className="bg-white p-6 rounded-2xl shadow-sm border border-gray-100">
            <div className="text-4xl mb-4">🔄</div>
            <h3 className="text-lg font-semibold text-gray-900 mb-2">Create Variations</h3>
            <p className="text-gray-600">
              Put your own spin on recipes and see how dishes evolve across the community.
            </p>
          </div>
          <div className="bg-white p-6 rounded-2xl shadow-sm border border-gray-100">
            <div className="text-4xl mb-4">📝</div>
            <h3 className="text-lg font-semibold text-gray-900 mb-2">Track Your Cooking</h3>
            <p className="text-gray-600">
              Log your cooking sessions, note what worked, and improve over time.
            </p>
          </div>
        </div>
      </main>

      {/* Footer */}
      <footer className="border-t border-gray-100 mt-20">
        <div className="max-w-6xl mx-auto px-4 py-8">
          <div className="flex flex-col md:flex-row justify-between items-center gap-4">
            <div className="flex items-center gap-2">
              <span className="text-xl">🍳</span>
              <span className="font-semibold text-gray-900">Pairing Planet</span>
            </div>
            <div className="flex gap-6 text-sm text-gray-600">
              <Link href="/terms" className="hover:text-orange-600 transition">
                Terms of Service
              </Link>
              <Link href="/privacy" className="hover:text-orange-600 transition">
                Privacy Policy
              </Link>
              <a href="mailto:support@pairingplanet.com" className="hover:text-orange-600 transition">
                Contact
              </a>
            </div>
          </div>
          <p className="text-center text-sm text-gray-400 mt-6">
            &copy; {new Date().getFullYear()} Pairing Planet. All rights reserved.
          </p>
        </div>
      </footer>
    </div>
  );
}
