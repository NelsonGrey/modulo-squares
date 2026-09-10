import { Link } from 'react-router';
import { SOCIAL_LINKS } from '../shared/socialLinks';

const Footer: React.FC = () => (
  <footer className="bg-gray-900 text-white border-t border-gray-700 shrink-0">
    <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-4">
      <div className="flex flex-col sm:flex-row sm:items-start sm:justify-between gap-3">
        {/* Brand */}
        <Link to="/" className="flex items-center gap-2.5 shrink-0">
          <img src="/icon-modulo-squares.png" alt="" className="w-6 h-6 rounded" />
          <span className="font-semibold text-sm text-white">Modulo Squares</span>
        </Link>

        {/* Main nav */}
        <nav className="flex flex-wrap gap-x-5 gap-y-1 text-sm text-gray-300">
          <Link to="/how-it-works" className="hover:text-white transition-colors">How It Works</Link>
          <Link to="/strategy-guide" className="hover:text-white transition-colors">Strategy Guide</Link>
          <Link to="/modular-arithmetic-explained" className="hover:text-white transition-colors">Modular Arithmetic</Link>
          <Link to="/download" className="hover:text-white transition-colors">Download</Link>
          <Link to="/pricing" className="hover:text-white transition-colors">Pricing</Link>
          <Link to="/leaderboard" className="hover:text-white transition-colors">Leaderboard</Link>
        </nav>

        {/* Legal + support */}
        <nav className="flex flex-wrap gap-x-4 gap-y-1 text-xs text-gray-400">
          <Link to="/privacy" className="hover:text-white transition-colors">Privacy</Link>
          <Link to="/terms" className="hover:text-white transition-colors">Terms</Link>
          <Link to="/cookies" className="hover:text-white transition-colors">Cookies</Link>
          <Link to="/support" className="hover:text-white transition-colors">Support</Link>
        </nav>
      </div>

      <div className="mt-3 pt-3 border-t border-gray-700 flex flex-wrap items-center justify-between gap-x-4 gap-y-2">
        <p className="text-xs text-gray-500">
          © {new Date().getFullYear()} Modulo Squares, a product of Nelson Grey LLC. All rights reserved.
        </p>
        <div className="flex flex-wrap items-center gap-3">
          {SOCIAL_LINKS.map(({ label, href, icon }) => {
            const isMail = href.startsWith('mailto:');
            return (
              <a
                key={label}
                href={href}
                {...(isMail
                  ? {}
                  : { target: '_blank', rel: 'noopener noreferrer' })}
                aria-label={label}
                className="text-gray-500 hover:text-white transition-colors"
              >
                {icon}
              </a>
            );
          })}
        </div>
      </div>
    </div>
  </footer>
);

export default Footer;
