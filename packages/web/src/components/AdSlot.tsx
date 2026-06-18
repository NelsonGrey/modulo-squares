import { useEffect, useRef } from 'react';

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
  const ref = useRef<HTMLModElement>(null);
  const pushed = useRef(false);

  useEffect(() => {
    if (!PUBLISHER_ID || pushed.current) return;
    pushed.current = true;
    try {
      (window.adsbygoogle = window.adsbygoogle || []).push({});
    } catch {
      // AdSense not loaded yet — script tag missing or blocked
    }
  }, []);

  if (!PUBLISHER_ID) return null;

  return (
    <div className={`flex justify-center overflow-hidden ${className}`}>
      <ins
        ref={ref}
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
