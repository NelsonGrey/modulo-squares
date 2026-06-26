import { useEffect, useRef, useState } from 'react';
import { getStoredConsent } from '../utils/consent';

interface AdSlotProps {
  /** AdSense ad-slot ID from your AdSense account (e.g. "1234567890") */
  slot: string;
  format?: 'auto' | 'rectangle' | 'horizontal';
  className?: string;
}

declare global {
  interface Window {
    adsbygoogle: unknown[];
  }
}

const PUBLISHER_ID = import.meta.env.VITE_ADSENSE_PUBLISHER_ID as string | undefined;

const AdSlot: React.FC<AdSlotProps> = ({ slot, format = 'auto', className = '' }) => {
  const pushed = useRef(false);
  // Start with whatever consent the user already gave (returning visitors).
  // New visitors start as false; the ConsentBanner dispatches 'ms:consent'
  // when they make a choice, which flips this to true if they accept all.
  const [adConsented, setAdConsented] = useState(() => getStoredConsent() === 'all');

  useEffect(() => {
    const handler = () => setAdConsented(getStoredConsent() === 'all');
    window.addEventListener('ms:consent', handler);
    return () => window.removeEventListener('ms:consent', handler);
  }, []);

  useEffect(() => {
    if (!PUBLISHER_ID || !adConsented || pushed.current) return;
    pushed.current = true;
    try {
      (window.adsbygoogle = window.adsbygoogle || []).push({});
    } catch {
      // AdSense not loaded yet — script tag missing or blocked
    }
  }, [adConsented]);

  if (!PUBLISHER_ID || !adConsented) return null;

  return (
    <div className={`flex justify-center overflow-hidden ${className}`}>
      <ins
        className="adsbygoogle"
        style={{ display: 'block' }}
        data-ad-client={PUBLISHER_ID}
        data-ad-slot={slot}
        data-ad-format={format}
        data-full-width-responsive="true"
      />
    </div>
  );
};

export default AdSlot;
