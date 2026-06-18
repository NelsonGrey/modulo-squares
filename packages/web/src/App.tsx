import { Routes, Route } from 'react-router-dom';
import Layout from './components/Layout';
import Hero from './components/Hero';
import Features from './components/Features';
import Download from './components/Download';
import ComingSoon from './components/ComingSoon';
import ConsentBanner from './components/ConsentBanner';
import PrivacyPolicy from './pages/PrivacyPolicy';
import TermsOfService from './pages/TermsOfService';
import Leaderboard from './pages/Leaderboard';

function App() {
  const showComingSoon = import.meta.env.VITE_SHOW_COMING_SOON === 'true';

  if (showComingSoon) {
    return <ComingSoon />;
  }

  return (
    <>
      <Routes>
        <Route path="/" element={<Layout><Hero /></Layout>} />
        <Route path="/how-it-works" element={<Layout><Features /></Layout>} />
        <Route path="/download" element={<Layout><Download /></Layout>} />
        <Route path="/leaderboard" element={<Layout><Leaderboard /></Layout>} />
        <Route path="/privacy" element={<Layout><PrivacyPolicy /></Layout>} />
        <Route path="/terms" element={<Layout><TermsOfService /></Layout>} />
      </Routes>
      <ConsentBanner />
    </>
  );
}

export default App;
