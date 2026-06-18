import { Link } from 'react-router-dom';

const Footer: React.FC = () => (
  <footer className="bg-gray-900 text-white border-t border-gray-700 py-4 px-4 shrink-0">
    <div className="container-max flex flex-col sm:flex-row items-center justify-between gap-3 text-sm">
      <Link to="/" className="flex items-center space-x-2 shrink-0">
        <img src="/icon-modulo-squares.png" alt="" className="w-6 h-6 rounded" />
        <span className="font-semibold text-white">Modulo Squares</span>
      </Link>

      <nav className="flex flex-wrap justify-center gap-x-5 gap-y-1 text-gray-300">
        <Link to="/how-it-works" className="hover:text-white transition-colors">How It Works</Link>
        <Link to="/download" className="hover:text-white transition-colors">Download</Link>
        <Link to="/leaderboard" className="hover:text-white transition-colors">Leaderboard</Link>
        <Link to="/privacy" className="hover:text-white transition-colors">Privacy</Link>
        <Link to="/terms" className="hover:text-white transition-colors">Terms</Link>
        <a href="mailto:support@modulosquares.com" className="hover:text-white transition-colors">Support</a>
      </nav>

      <p className="text-gray-400 shrink-0">© 2026 Modulo Squares</p>
    </div>
  </footer>
);

export default Footer;
