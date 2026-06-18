import { Routes, Route } from 'react-router-dom';
import Navigation from './components/Navigation';
import Hero from './components/Hero';
import Features from './components/Features';
import Download from './components/Download';
import Footer from './components/Footer';
import ComingSoon from './components/ComingSoon';
import AdSlot from './components/AdSlot';
import ConsentBanner from './components/ConsentBanner';
import PrivacyPolicy from './pages/PrivacyPolicy';
import TermsOfService from './pages/TermsOfService';
import Leaderboard from './pages/Leaderboard';

// Ad slot IDs — replace with real IDs from your AdSense account once approved.
// These are ignored when VITE_ADSENSE_PUBLISHER_ID is not set.
const AD_SLOT_BETWEEN_HERO_FEATURES = '1111111111';
const AD_SLOT_BETWEEN_FEATURES_DOWNLOAD = '2222222222';

function HomePage() {
  const showComingSoon = import.meta.env.VITE_SHOW_COMING_SOON === 'true';

  if (showComingSoon) {
    return <ComingSoon />;
  }

  return (
    <div className="min-h-screen bg-white">
      <Navigation />
      <main>
        <Hero />
        <AdSlot slot={AD_SLOT_BETWEEN_HERO_FEATURES} format="horizontal" className="py-4 bg-white" />
        <Features />
        <AdSlot slot={AD_SLOT_BETWEEN_FEATURES_DOWNLOAD} format="rectangle" className="py-6 bg-gray-50" />
        <Download />
      </main>
      <Footer />
    </div>
  );
}

function App() {
  return (
    <>
      <Routes>
        <Route path="/" element={<HomePage />} />
        <Route path="/leaderboard" element={<Leaderboard />} />
        <Route path="/privacy" element={<PrivacyPolicy />} />
        <Route path="/terms" element={<TermsOfService />} />
      </Routes>
      <ConsentBanner />
    </>
  );
}

export default App;
