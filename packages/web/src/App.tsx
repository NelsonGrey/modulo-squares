import { Routes, Route } from 'react-router-dom';
import Navigation from './components/Navigation';
import Hero from './components/Hero';
import Features from './components/Features';
import Download from './components/Download';
import Footer from './components/Footer';
import ComingSoon from './components/ComingSoon';
import PrivacyPolicy from './pages/PrivacyPolicy';
import TermsOfService from './pages/TermsOfService';

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
        <Features />
        <Download />
      </main>
      <Footer />
    </div>
  );
}

function App() {
  return (
    <Routes>
      <Route path="/" element={<HomePage />} />
      <Route path="/privacy" element={<PrivacyPolicy />} />
      <Route path="/terms" element={<TermsOfService />} />
    </Routes>
  );
}

export default App;