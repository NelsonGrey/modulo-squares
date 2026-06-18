import { Link } from 'react-router-dom';

const Footer: React.FC = () => {
  return (
    <footer id="about" className="bg-gray-900 text-white">
      <div className="container-max section-padding">
        <div className="grid md:grid-cols-3 gap-8">
          {/* Brand */}
          <div>
            <div className="flex items-center space-x-2 mb-4">
              <div className="w-8 h-8 bg-primary-600 rounded-lg flex items-center justify-center">
                <span className="text-white font-bold text-sm">M</span>
              </div>
              <span className="font-bold text-xl">Modulo Squares</span>
            </div>
            <p className="text-gray-300 mb-4">
              A fast-paced falling-number puzzle where divisibility is the key. Guide each number into the right bucket and climb the global leaderboard.
            </p>
          </div>

          {/* Links */}
          <div>
            <h3 className="font-semibold text-lg mb-4">Quick Links</h3>
            <ul className="space-y-2">
              <li>
                <button
                  onClick={() => document.getElementById('features')?.scrollIntoView({ behavior: 'smooth' })}
                  className="text-gray-300 hover:text-white transition-colors"
                >
                  How It Works
                </button>
              </li>
              <li>
                <button
                  onClick={() => document.getElementById('download')?.scrollIntoView({ behavior: 'smooth' })}
                  className="text-gray-300 hover:text-white transition-colors"
                >
                  Download
                </button>
              </li>
              <li>
                <Link to="/leaderboard" className="text-gray-300 hover:text-white transition-colors">
                  Leaderboard
                </Link>
              </li>
              <li>
                <Link to="/privacy" className="text-gray-300 hover:text-white transition-colors">
                  Privacy Policy
                </Link>
              </li>
              <li>
                <Link to="/terms" className="text-gray-300 hover:text-white transition-colors">
                  Terms of Service
                </Link>
              </li>
            </ul>
          </div>

          {/* Support */}
          <div>
            <h3 className="font-semibold text-lg mb-4">Support</h3>
            <p className="text-gray-300 mb-4">
              Questions, feedback, or bug reports — we'd love to hear from you.
            </p>
            <a
              href="mailto:support@modulosquares.com"
              className="text-primary-400 hover:text-primary-300 transition-colors"
            >
              support@modulosquares.com
            </a>
          </div>
        </div>

        <div className="border-t border-gray-800 mt-12 pt-8 text-center">
          <p className="text-gray-400">© 2026 Modulo Squares. All rights reserved.</p>
        </div>
      </div>
    </footer>
  );
};

export default Footer;
