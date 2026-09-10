// Thin wrapper over the GTM dataLayer. GTM (see index.html) owns GA4; this only
// pushes events for GTM triggers/tags to pick up. Safe to call before GTM loads.

type EventParams = Record<string, string | number | boolean | undefined>;

interface DataLayerWindow extends Window {
  dataLayer?: Array<Record<string, unknown>>;
}

/**
 * Push a named event onto the dataLayer.
 *
 * Wire the corresponding trigger + GA4 event tag in GTM
 * (account 6359833234 / container GTM-TR4PP272):
 * - `page_view` — SPA route changes (Custom Event or History Change trigger)
 * - `app_store_click` / `cta_click` — mark as a GA4 conversion
 */
export function trackEvent(event: string, params: EventParams = {}): void {
  try {
    const w = window as DataLayerWindow;
    w.dataLayer = w.dataLayer || [];
    w.dataLayer.push({ event, ...params });
  } catch {
    // dataLayer unavailable (SSR/prerender, blocked storage) — no-op.
  }
}
