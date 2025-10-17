import React from 'react';
import Navigation from './components/Navigation';
import Hero from './components/Hero';
import Features from './components/Features';
import Download from './components/Download';
import Footer from './components/Footer';

function App() {
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