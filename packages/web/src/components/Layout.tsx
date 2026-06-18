import { ReactNode } from 'react';
import Navigation from './Navigation';
import Footer from './Footer';

const Layout = ({ children }: { children: ReactNode }) => (
  <div className="flex flex-col h-dvh">
    <Navigation />
    <main className="flex-1 overflow-y-auto">
      {children}
    </main>
    <Footer />
  </div>
);

export default Layout;
