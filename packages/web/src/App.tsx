import Navigation from './components/Navigation';
import Hero from './components/Hero';
import Features from './components/Features';
import Download from './components/Download';
import Footer from './components/Footer';
import ComingSoon from './components/ComingSoon';

function App() {
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

export default App;