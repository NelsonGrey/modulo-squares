import { useEffect } from 'react';
import { useLocation } from 'react-router';
import { trackEvent } from '../utils/analytics';

/**
 * Emits a `page_view` dataLayer event for every view, including the initial
 * one — deferred one frame so react-helmet-async has flushed the route's
 * <title> first (a direct landing on /download would otherwise report the
 * generic index.html title).
 *
 * GTM must:
 *  - have a trigger on the `page_view` custom event (or History Change) wired
 *    to a GA4 event tag, and
 *  - have the GA4 config tag's automatic page_view DISABLED, so this component
 *    is the single source of page_view events (no double counting).
 */
const RouteAnalytics: React.FC = () => {
  const location = useLocation();

  useEffect(() => {
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
