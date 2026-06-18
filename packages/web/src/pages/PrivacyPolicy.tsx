import { Link } from 'react-router-dom';

const PrivacyPolicy: React.FC = () => {
  return (
    <div className="bg-white">
      <main className="max-w-4xl mx-auto px-6 py-12">
        <h1 className="text-3xl font-bold text-gray-900 mb-2">Privacy Policy</h1>
        <p className="text-gray-500 mb-8">Last updated: June 17, 2026</p>

        <div className="prose prose-gray max-w-none space-y-8">

          <section>
            <h2 className="text-xl font-semibold text-gray-900 mb-3">1. Introduction</h2>
            <p className="text-gray-700 leading-relaxed">
              Modulo Squares ("we," "our," or "us") is committed to protecting your privacy.
              This Privacy Policy explains how we collect, use, and safeguard information when
              you use our mobile game application and website (collectively, the "Service").
            </p>
            <p className="text-gray-700 leading-relaxed mt-3">
              By using the Service, you agree to the collection and use of information as described
              in this policy. If you do not agree, please do not use the Service.
            </p>
          </section>

          <section>
            <h2 className="text-xl font-semibold text-gray-900 mb-3">2. Information We Collect</h2>

            <h3 className="text-lg font-medium text-gray-800 mb-2">2.1 Account Information</h3>
            <p className="text-gray-700 leading-relaxed">
              When you sign in, we collect authentication data through Google Sign-In or Sign in with Apple.
              We receive a unique user identifier and, where permitted, your email address. We do not store
              your password — authentication is handled entirely by Google or Apple.
            </p>

            <h3 className="text-lg font-medium text-gray-800 mt-4 mb-2">2.2 Gameplay Data</h3>
            <p className="text-gray-700 leading-relaxed">
              We store your game progress, scores, level completions, and leaderboard rankings in
              Firebase Firestore, linked to your account identifier. This data is necessary to
              provide the game experience, including global leaderboards.
            </p>

            <h3 className="text-lg font-medium text-gray-800 mt-4 mb-2">2.3 Analytics</h3>
            <p className="text-gray-700 leading-relaxed">
              We use Firebase Analytics to collect anonymized usage data, including:
            </p>
            <ul className="list-disc list-inside text-gray-700 mt-2 space-y-1">
              <li>App opens and session duration</li>
              <li>Level starts and completions</li>
              <li>In-app purchase events</li>
              <li>Ad interactions</li>
              <li>Device type, OS version, and country (aggregated, not precise location)</li>
            </ul>
            <p className="text-gray-700 leading-relaxed mt-3">
              Analytics data is used solely to improve the game experience and understand player engagement.
              Firebase Analytics data is subject to{' '}
              <a href="https://firebase.google.com/support/privacy" target="_blank" rel="noopener noreferrer"
                className="text-primary-600 hover:text-primary-700 underline">
                Google's Privacy Policy
              </a>.
            </p>

            <h3 className="text-lg font-medium text-gray-800 mt-4 mb-2">2.4 Advertising</h3>
            <p className="text-gray-700 leading-relaxed">
              Modulo Squares uses Google AdMob to display interstitial advertisements between levels.
              AdMob may collect and use your advertising identifier (IDFA on iOS, GAID on Android)
              to serve personalized ads.
            </p>
            <p className="text-gray-700 leading-relaxed mt-3">
              On iOS, we display the App Tracking Transparency (ATT) prompt before collecting any
              advertising identifier. You may decline tracking, in which case only non-personalized
              ads will be shown.
            </p>
            <p className="text-gray-700 leading-relaxed mt-3">
              For users in the European Economic Area (EEA), we display a consent form pursuant to
              the IAB Transparency and Consent Framework before serving any ads. Ads will only be
              personalized where consent is granted.
            </p>
            <p className="text-gray-700 leading-relaxed mt-3">
              AdMob's data practices are governed by{' '}
              <a href="https://policies.google.com/privacy" target="_blank" rel="noopener noreferrer"
                className="text-primary-600 hover:text-primary-700 underline">
                Google's Privacy Policy
              </a>.
              You can opt out of personalized advertising at any time via your device settings
              (iOS: Settings → Privacy &amp; Security → Tracking; Android: Settings → Google → Ads).
            </p>

            <h3 className="text-lg font-medium text-gray-800 mt-4 mb-2">2.5 In-App Purchases</h3>
            <p className="text-gray-700 leading-relaxed">
              If you purchase "Remove Ads," the transaction is processed entirely by Apple (iOS) or
              Google (Android). We do not collect or store any payment card information.
              We receive only a confirmation of the purchase to unlock the ad-free experience.
            </p>

            <h3 className="text-lg font-medium text-gray-800 mt-4 mb-2">2.6 Crash Reports</h3>
            <p className="text-gray-700 leading-relaxed">
              We use Firebase Crashlytics to automatically collect crash reports when the app
              experiences an unhandled error. Crash reports include device information, OS version,
              and a stack trace. No personally identifiable information is intentionally included
              in crash reports.
            </p>
          </section>

          <section>
            <h2 className="text-xl font-semibold text-gray-900 mb-3">3. How We Use Your Information</h2>
            <ul className="list-disc list-inside text-gray-700 space-y-2">
              <li>To provide and maintain the game service, including leaderboards and progress sync</li>
              <li>To process in-app purchases and restore entitlements</li>
              <li>To serve advertisements (for users who have not purchased "Remove Ads")</li>
              <li>To analyze usage patterns and improve the game</li>
              <li>To diagnose and fix crashes and technical issues</li>
            </ul>
            <p className="text-gray-700 leading-relaxed mt-3">
              We do not sell your personal data to third parties. We do not use your data for
              purposes other than those listed above.
            </p>
          </section>

          <section>
            <h2 className="text-xl font-semibold text-gray-900 mb-3">4. Data Retention</h2>
            <p className="text-gray-700 leading-relaxed">
              Account and gameplay data is retained for as long as your account is active.
              You may request deletion of your account data at any time (see Section 6).
              Analytics and crash data is retained per the default Firebase retention policies
              (typically 60–90 days for raw event data).
            </p>
          </section>

          <section>
            <h2 className="text-xl font-semibold text-gray-900 mb-3">5. Children's Privacy (COPPA)</h2>
            <p className="text-gray-700 leading-relaxed">
              Modulo Squares is rated 4+ and is not directed at children under 13. We do not
              knowingly collect personal information from children under 13. If you are a parent
              or guardian and believe your child has provided us with personal information, please
              contact us at{' '}
              <a href="mailto:support@modulosquares.com" className="text-primary-600 hover:text-primary-700 underline">
                support@modulosquares.com
              </a>{' '}
              and we will promptly delete any such information.
            </p>
          </section>

          <section>
            <h2 className="text-xl font-semibold text-gray-900 mb-3">6. Your Rights</h2>
            <p className="text-gray-700 leading-relaxed">
              Depending on your jurisdiction, you may have the following rights with respect
              to your personal data:
            </p>
            <ul className="list-disc list-inside text-gray-700 mt-2 space-y-2">
              <li><strong>Access:</strong> Request a copy of the personal data we hold about you</li>
              <li><strong>Correction:</strong> Request correction of inaccurate data</li>
              <li><strong>Deletion:</strong> Request deletion of your account and associated data</li>
              <li><strong>Portability:</strong> Request your data in a machine-readable format</li>
              <li><strong>Objection:</strong> Object to processing of your data for direct marketing</li>
            </ul>
            <p className="text-gray-700 leading-relaxed mt-3">
              To exercise any of these rights, email us at{' '}
              <a href="mailto:support@modulosquares.com" className="text-primary-600 hover:text-primary-700 underline">
                support@modulosquares.com
              </a>.
              We will respond within 30 days.
            </p>
          </section>

          <section>
            <h2 className="text-xl font-semibold text-gray-900 mb-3">7. Security</h2>
            <p className="text-gray-700 leading-relaxed">
              We implement commercially reasonable measures to protect your information, including
              Firebase Security Rules that prevent unauthorized access to your game data.
              However, no method of transmission or storage is 100% secure. We cannot guarantee
              absolute security.
            </p>
          </section>

          <section>
            <h2 className="text-xl font-semibold text-gray-900 mb-3">8. Third-Party Services</h2>
            <p className="text-gray-700 leading-relaxed">
              The Service integrates with the following third-party services, each governed by
              their own privacy policies:
            </p>
            <ul className="list-disc list-inside text-gray-700 mt-2 space-y-2">
              <li>
                <a href="https://firebase.google.com/support/privacy" target="_blank" rel="noopener noreferrer"
                  className="text-primary-600 hover:text-primary-700 underline">
                  Google Firebase
                </a>{' '}(Authentication, Firestore, Analytics, Crashlytics, Cloud Functions)
              </li>
              <li>
                <a href="https://policies.google.com/privacy" target="_blank" rel="noopener noreferrer"
                  className="text-primary-600 hover:text-primary-700 underline">
                  Google AdMob
                </a>{' '}(Advertising)
              </li>
              <li>
                <a href="https://www.apple.com/legal/privacy/" target="_blank" rel="noopener noreferrer"
                  className="text-primary-600 hover:text-primary-700 underline">
                  Apple
                </a>{' '}(Sign in with Apple, App Store purchases)
              </li>
              <li>
                <a href="https://policies.google.com/privacy" target="_blank" rel="noopener noreferrer"
                  className="text-primary-600 hover:text-primary-700 underline">
                  Google
                </a>{' '}(Sign in with Google, Google Play purchases)
              </li>
            </ul>
          </section>

          <section>
            <h2 className="text-xl font-semibold text-gray-900 mb-3">9. Changes to This Policy</h2>
            <p className="text-gray-700 leading-relaxed">
              We may update this Privacy Policy from time to time. We will notify you of material
              changes by updating the "Last updated" date at the top of this page. Continued use
              of the Service after changes are posted constitutes acceptance of the updated policy.
            </p>
          </section>

          <section>
            <h2 className="text-xl font-semibold text-gray-900 mb-3">10. Contact Us</h2>
            <p className="text-gray-700 leading-relaxed">
              If you have questions or concerns about this Privacy Policy, please contact us:
            </p>
            <div className="mt-3 text-gray-700">
              <p><strong>Email:</strong>{' '}
                <a href="mailto:support@modulosquares.com" className="text-primary-600 hover:text-primary-700 underline">
                  support@modulosquares.com
                </a>
              </p>
            </div>
          </section>

        </div>

        <div className="mt-12 pt-6 border-t border-gray-200">
          <Link to="/" className="text-primary-600 hover:text-primary-700 text-sm">
            ← Back to home
          </Link>
        </div>
      </main>
    </div>
  );
};

export default PrivacyPolicy;
