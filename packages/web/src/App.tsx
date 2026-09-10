import { Routes, Route } from 'react-router';
import Layout from './components/Layout';
import Hero from './components/Hero';
import Features from './components/Features';
import Download from './components/Download';
import ComingSoon from './components/ComingSoon';
import EnvironmentGate from './components/EnvironmentGate';
import RouteAnalytics from './components/RouteAnalytics';
import PrivacyPolicy from './pages/PrivacyPolicy';
import TermsOfService from './pages/TermsOfService';
import Leaderboard from './pages/Leaderboard';
import Support from './pages/Support';
import CookiePolicy from './pages/CookiePolicy';
import Pricing from './pages/Pricing';
import StrategyGuide from './pages/StrategyGuide';
import ModularArithmeticExplained from './pages/ModularArithmeticExplained';
import { appEnvironment } from './shared/environment';

function App() {
  const showComingSoon = import.meta.env.VITE_SHOW_COMING_SOON === 'true';

  const content = showComingSoon ? (
    <ComingSoon />
  ) : (
    <Routes>
      <Route path="/" element={<Layout><Hero /></Layout>} />
      <Route path="/how-it-works" element={<Layout><Features /></Layout>} />
      <Route path="/download" element={<Layout><Download /></Layout>} />
      <Route path="/pricing" element={<Layout><Pricing /></Layout>} />
      <Route path="/strategy-guide" element={<Layout><StrategyGuide /></Layout>} />
      <Route path="/modular-arithmetic-explained" element={<Layout><ModularArithmeticExplained /></Layout>} />
      <Route path="/leaderboard" element={<Layout><Leaderboard /></Layout>} />
      <Route path="/privacy" element={<Layout><PrivacyPolicy /></Layout>} />
      <Route path="/terms" element={<Layout><TermsOfService /></Layout>} />
      <Route path="/cookies" element={<Layout><CookiePolicy /></Layout>} />
      <Route path="/support" element={<Layout><Support /></Layout>} />
    </Routes>
  );

  return (
    <EnvironmentGate environment={appEnvironment}>
      <RouteAnalytics />
      {content}
    </EnvironmentGate>
  );
}

export default App;
