import { useEffect, useRef } from 'react';
import { useLocation } from 'react-router';
import { trackEvent } from '../utils/analytics';

/**
 * Emits a `page_view` dataLayer event on every client-side route change.
 *
 * The GA4 config tag in GTM already sends the page_view for the initial HTML
 * load, so the first render here is skipped to avoid a duplicate. GTM needs a
 * trigger on the `page_view` custom event (or History Change) wired to a GA4
 * event tag for these to reach GA4.
 */
const RouteAnalytics: React.FC = () => {
  const location = useLocation();
  const isFirst = useRef(true);

  useEffect(() => {
    if (isFirst.current) {
      isFirst.current = false;
      return;
    }
    // Defer one frame so react-helmet-async has flushed the new <title>.
    const id = requestAnimationFrame(() => {
      trackEvent('page_view', {
        page_path: location.pathname + location.search,
        page_location: window.location.href,
        page_title: document.title,
      });
    });
    return () => cancelAnimationFrame(id);
  }, [location]);

  return null;
};

export default RouteAnalytics;
