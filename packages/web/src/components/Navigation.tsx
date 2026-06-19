import { useState } from 'react';
import { Link, useLocation } from 'react-router-dom';

const ROUTE_BG: Record<string, string> = {
  '/':              'bg-primary-600',
  '/how-it-works':  'bg-secondary-600',
  '/download':      'bg-gray-900',
  '/leaderboard':   'bg-linear-to-r from-primary-600 to-secondary-600',
  '/privacy':       'bg-gray-600',
  '/terms':         'bg-gray-600',
  '/support':       'bg-gray-600',
};

const Navigation: React.FC = () => {
  const [isMenuOpen, setIsMenuOpen] = useState(false);
  const { pathname } = useLocation();
  const bgClass = ROUTE_BG[pathname] ?? 'bg-primary-600';

  return (
    <nav className={`${bgClass} shrink-0`}>
      <div className="container-max">
        <div className="flex justify-between items-center h-16">
          {/* Logo */}
          <Link to="/" className="flex items-center space-x-2">
            <img src="/icon-modulo-squares.png" alt="" className="w-8 h-8 rounded-lg" />
            <span className="font-bold text-xl text-white">Modulo Squares</span>
          </Link>

          {/* Desktop nav */}
          <div className="hidden md:flex items-center space-x-8">
            <Link to="/how-it-works" className="text-white/80 hover:text-white transition-colors">
              How It Works
            </Link>
            <Link to="/download" className="text-white/80 hover:text-white transition-colors">
              Download
            </Link>
            <Link to="/leaderboard" className="text-white/80 hover:text-white transition-colors font-medium">
              Leaderboard
            </Link>
          </div>

          {/* Mobile menu toggle */}
          <button
            className="md:hidden p-2"
            onClick={() => setIsMenuOpen(!isMenuOpen)}
            aria-label="Toggle menu"
          >
            <div className="w-6 h-6 flex flex-col justify-center items-center">
              <span className={`block w-5 h-0.5 bg-white transition-transform ${isMenuOpen ? 'rotate-45 translate-y-1' : '-translate-y-1'}`} />
              <span className={`block w-5 h-0.5 bg-white transition-opacity ${isMenuOpen ? 'opacity-0' : 'opacity-100'}`} />
              <span className={`block w-5 h-0.5 bg-white transition-transform ${isMenuOpen ? '-rotate-45 -translate-y-1' : 'translate-y-1'}`} />
            </div>
          </button>
        </div>

        {/* Mobile menu */}
        {isMenuOpen && (
          <div className="md:hidden py-4 border-t border-white/20">
            <div className="flex flex-col space-y-4">
              <Link
                to="/how-it-works"
                onClick={() => setIsMenuOpen(false)}
                className="text-white/80 hover:text-white transition-colors"
              >
                How It Works
              </Link>
              <Link
                to="/download"
                onClick={() => setIsMenuOpen(false)}
                className="text-white/80 hover:text-white transition-colors"
              >
                Download
              </Link>
              <Link
                to="/leaderboard"
                onClick={() => setIsMenuOpen(false)}
                className="text-white/80 hover:text-white transition-colors font-medium"
              >
                Leaderboard
              </Link>
            </div>
          </div>
        )}
      </div>
    </nav>
  );
};

export default Navigation;
