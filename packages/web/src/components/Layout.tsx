import { ReactNode } from 'react';
import Navigation from './Navigation';
import Footer from './Footer';
import AdSlot from './AdSlot';
import ConsentBanner from './ConsentBanner';

// AdSense slot IDs — create these units in your AdSense dashboard and set them here.
// Also set VITE_ADSENSE_PUBLISHER_ID in .env and uncomment the AdSense script in index.html.
const AD_BELOW_HEADER_SLOT = import.meta.env.VITE_ADSENSE_SLOT_BELOW_HEADER as string ?? '';
const AD_ABOVE_FOOTER_SLOT = import.meta.env.VITE_ADSENSE_SLOT_ABOVE_FOOTER as string ?? '';

const Layout = ({ children }: { children: ReactNode }) => (
  <div className="flex h-dvh flex-col overflow-hidden">
    <Navigation />
    {AD_BELOW_HEADER_SLOT && (
      <AdSlot slot={AD_BELOW_HEADER_SLOT} format="auto" className="shrink-0 bg-white" />
    )}
    <main className="flex-1 overflow-y-auto bg-white">
      {children}
    </main>
    {AD_ABOVE_FOOTER_SLOT && (
      <AdSlot slot={AD_ABOVE_FOOTER_SLOT} format="auto" className="shrink-0 bg-white" />
    )}
    <Footer />
    <ConsentBanner />
  </div>
);

export default Layout;
