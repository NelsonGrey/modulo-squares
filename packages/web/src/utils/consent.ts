const CONSENT_KEY = 'ms_consent_v1';

export type ConsentChoice = 'all' | 'essential';

declare global {
  interface Window {
    gtag?: (...args: unknown[]) => void;
  }
}

export function getStoredConsent(): ConsentChoice | null {
  try {
    const val = localStorage.getItem(CONSENT_KEY);
    if (val === 'all' || val === 'essential') return val;
    return null;
  } catch {
    return null;
  }
}

function updateGtag(granted: boolean): void {
  const state = granted ? 'granted' : 'denied';
  window.gtag?.('consent', 'update', {
    analytics_storage:  state,
    ad_storage:         state,
    ad_user_data:       state,
    ad_personalization: state,
  });
}

export function grantAllConsent(): void {
  try { localStorage.setItem(CONSENT_KEY, 'all'); } catch { /* quota/private mode */ }
  updateGtag(true);
}

export function grantEssentialOnly(): void {
  try { localStorage.setItem(CONSENT_KEY, 'essential'); } catch { /* quota/private mode */ }
  updateGtag(false);
}
