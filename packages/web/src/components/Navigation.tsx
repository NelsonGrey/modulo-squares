import React, { useState } from 'react';

const Navigation: React.FC = () => {
  const [isMenuOpen, setIsMenuOpen] = useState(false);

  const scrollToSection = (sectionId: string) => {
    const element = document.getElementById(sectionId);
    if (element) {
      element.scrollIntoView({ behavior: 'smooth' });
    }
    setIsMenuOpen(false);
  };

  return (
    <nav className="fixed top-0 w-full bg-white/95 backdrop-blur-sm z-50 border-b border-gray-200">
      <div className="container-max">
        <div className="flex justify-between items-center h-16">
          {/* Logo */}
          <div className="flex items-center space-x-2">
            <div className="w-8 h-8 bg-primary-600 rounded-lg flex items-center justify-center">
              <span className="text-white font-bold text-sm">M</span>
            </div>
            <span className="font-bold text-xl text-gray-900">Modulo Squares</span>
          </div>

          {/* Desktop Navigation */}
          <div className="hidden md:flex items-center space-x-8">
            <button
              onClick={() => scrollToSection('features')}
              className="text-gray-700 hover:text-primary-600 transition-colors"
            >
              Features
            </button>
            <button
              onClick={() => scrollToSection('download')}
              className="text-gray-700 hover:text-primary-600 transition-colors"
            >
              Download
            </button>
            <button
              onClick={() => scrollToSection('about')}
              className="text-gray-700 hover:text-primary-600 transition-colors"
            >
              About
            </button>
          </div>

          {/* Mobile menu button */}
          <button
            className="md:hidden p-2"
            onClick={() => setIsMenuOpen(!isMenuOpen)}
            aria-label="Toggle menu"
          >
            <div className="w-6 h-6 flex flex-col justify-center items-center">
              <span className={`block w-5 h-0.5 bg-gray-700 transition-transform ${isMenuOpen ? 'rotate-45 translate-y-1' : '-translate-y-1'}`}></span>
              <span className={`block w-5 h-0.5 bg-gray-700 transition-opacity ${isMenuOpen ? 'opacity-0' : 'opacity-100'}`}></span>
              <span className={`block w-5 h-0.5 bg-gray-700 transition-transform ${isMenuOpen ? '-rotate-45 -translate-y-1' : 'translate-y-1'}`}></span>
            </div>
          </button>
        </div>

        {/* Mobile Navigation */}
        {isMenuOpen && (
          <div className="md:hidden py-4 border-t border-gray-200">
            <div className="flex flex-col space-y-4">
              <button
                onClick={() => scrollToSection('features')}
                className="text-left text-gray-700 hover:text-primary-600 transition-colors"
              >
                Features
              </button>
              <button
                onClick={() => scrollToSection('download')}
                className="text-left text-gray-700 hover:text-primary-600 transition-colors"
              >
                Download
              </button>
              <button
                onClick={() => scrollToSection('about')}
                className="text-left text-gray-700 hover:text-primary-600 transition-colors"
              >
                About
              </button>
            </div>
          </div>
        )}
      </div>
    </nav>
  );
};

export default Navigation;