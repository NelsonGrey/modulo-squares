import SEOHead from '../components/SEOHead';

const CookiePolicy: React.FC = () => (
  <>
    <SEOHead
      title="Cookie Policy"
      description="Information about how Modulo Squares uses cookies and similar tracking technologies on its website."
      path="/cookies"
    />
    <div className="bg-white">
      <main className="max-w-4xl mx-auto px-6 py-12">
        <h1 className="text-3xl font-bold text-gray-900 mb-2">Cookie Policy</h1>
        <p className="text-gray-500 mb-8">Last updated: June 24, 2026</p>

        <div className="prose prose-gray max-w-none space-y-8">

          <section>
            <h2 className="text-xl font-semibold text-gray-900 mb-3">1. What Are Cookies?</h2>
            <p className="text-gray-700 leading-relaxed">
              Cookies are small pieces of data stored on your device when you visit a website. They help
              the site remember information about your visit — such as your preferences — making your
              next visit easier and the site more useful to you.
            </p>
          </section>

          <section>
            <h2 className="text-xl font-semibold text-gray-900 mb-3">2. How We Use Cookies</h2>
            <p className="text-gray-700 leading-relaxed mb-4">
              The Modulo Squares website uses cookies for the following purposes:
            </p>
            <div className="space-y-4">
              <div>
                <h3 className="text-base font-medium text-gray-800">Essential Cookies</h3>
                <p className="text-gray-700 leading-relaxed mt-1">
                  Required for the website to function correctly. These cannot be disabled and are set
                  in response to your actions, such as authentication sessions.
                </p>
              </div>
              <div>
                <h3 className="text-base font-medium text-gray-800">Analytics Cookies</h3>
                <p className="text-gray-700 leading-relaxed mt-1">
                  Set by Firebase Analytics to help us understand how visitors interact with the site —
                  for example, which pages are most visited and how long sessions last. All data is
                  aggregated and anonymized.
                </p>
              </div>
              <div>
                <h3 className="text-base font-medium text-gray-800">Advertising Cookies</h3>
                <p className="text-gray-700 leading-relaxed mt-1">
                  The Modulo Squares mobile app uses Google AdMob, which may set advertising identifiers
                  on your device (subject to your App Tracking Transparency consent on iOS). The website
                  itself does not serve ads.
                </p>
              </div>
            </div>
          </section>

          <section>
            <h2 className="text-xl font-semibold text-gray-900 mb-3">3. Types of Cookies We Use</h2>
            <div className="space-y-4">
              <div>
                <h3 className="text-base font-medium text-gray-800">Session Cookies</h3>
                <p className="text-gray-700 leading-relaxed mt-1">
                  Temporary cookies that expire when you close your browser.
                </p>
              </div>
              <div>
                <h3 className="text-base font-medium text-gray-800">Persistent Cookies</h3>
                <p className="text-gray-700 leading-relaxed mt-1">
                  Remain on your device for a fixed period or until you delete them. Used to remember
                  your preferences across visits.
                </p>
              </div>
              <div>
                <h3 className="text-base font-medium text-gray-800">Third-Party Cookies</h3>
                <p className="text-gray-700 leading-relaxed mt-1">
                  Set by services we use, including Firebase (Google) for authentication and analytics.
                  These are subject to Google's own privacy and cookie policies.
                </p>
              </div>
            </div>
          </section>

          <section>
            <h2 className="text-xl font-semibold text-gray-900 mb-3">4. Your Cookie Choices</h2>
            <p className="text-gray-700 leading-relaxed">
              Most browsers let you refuse or delete cookies via their settings. Disabling essential
              cookies may affect site functionality, such as staying signed in. For mobile app tracking,
              you can manage your preferences at any time through your device's privacy settings
              (iOS: Settings → Privacy & Security → Tracking).
            </p>
          </section>

          <section>
            <h2 className="text-xl font-semibold text-gray-900 mb-3">5. Contact</h2>
            <p className="text-gray-700 leading-relaxed">
              If you have questions about this Cookie Policy, please{' '}
              <a href="/support" className="text-green-700 hover:text-green-800 underline">contact us</a>.
            </p>
          </section>

        </div>
      </main>
    </div>
  </>
);

export default CookiePolicy;
