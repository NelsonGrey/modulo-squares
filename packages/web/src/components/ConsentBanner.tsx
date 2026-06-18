import { useState } from 'react';
import { Link } from 'react-router-dom';
import {
  getStoredConsent,
  grantAllConsent,
  grantEssentialOnly,
} from '../utils/consent';

const ConsentBanner: React.FC = () => {
  const [visible, setVisible] = useState(() => getStoredConsent() === null);

  if (!visible) return null;

  const handleAccept = () => {
    grantAllConsent();
    setVisible(false);
  };

  const handleDecline = () => {
    grantEssentialOnly();
    setVisible(false);
  };

  return (
    <div
      role="dialog"
      aria-label="Cookie consent"
      aria-modal="false"
      className="fixed bottom-0 left-0 right-0 z-50 bg-white/95 backdrop-blur-sm border-t border-gray-200 shadow-lg"
    >
      <div className="container-max px-4 py-4 flex flex-col sm:flex-row sm:items-center gap-4">
        <p className="text-sm text-gray-600 flex-1">
          We use cookies and similar technologies to understand how visitors use
          this site and to show relevant ads. Read our{' '}
          <Link to="/privacy" className="text-primary-600 hover:underline">
            Privacy Policy
          </Link>{' '}
          for details.
        </p>

        <div className="flex gap-3 shrink-0">
          <button
            onClick={handleDecline}
            className="text-sm font-medium text-gray-600 hover:text-gray-900 transition-colors px-4 py-2 rounded-lg border border-gray-300 hover:border-gray-400"
          >
            Essential only
          </button>
          <button
            onClick={handleAccept}
            className="text-sm font-semibold text-white bg-primary-600 hover:bg-primary-700 transition-colors px-4 py-2 rounded-lg"
          >
            Accept all
          </button>
        </div>
      </div>
    </div>
  );
};

export default ConsentBanner;
