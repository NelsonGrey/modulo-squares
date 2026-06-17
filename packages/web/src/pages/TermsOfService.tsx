import { Link } from 'react-router-dom';

const TermsOfService: React.FC = () => {
  return (
    <div className="min-h-screen bg-white">
      <header className="bg-gray-900 text-white py-4 px-6">
        <div className="max-w-4xl mx-auto flex items-center justify-between">
          <Link to="/" className="flex items-center space-x-2 hover:opacity-80 transition-opacity">
            <div className="w-8 h-8 bg-primary-600 rounded-lg flex items-center justify-center">
              <span className="text-white font-bold text-sm">M</span>
            </div>
            <span className="font-bold text-xl">Modulo Squares</span>
          </Link>
        </div>
      </header>

      <main className="max-w-4xl mx-auto px-6 py-12">
        <h1 className="text-3xl font-bold text-gray-900 mb-2">Terms of Service</h1>
        <p className="text-gray-500 mb-8">Last updated: June 17, 2026</p>

        <div className="prose prose-gray max-w-none space-y-8">

          <section>
            <h2 className="text-xl font-semibold text-gray-900 mb-3">1. Acceptance of Terms</h2>
            <p className="text-gray-700 leading-relaxed">
              By downloading, installing, or using Modulo Squares ("the App"), you agree to be bound
              by these Terms of Service ("Terms"). If you do not agree to these Terms, do not use
              the App.
            </p>
            <p className="text-gray-700 leading-relaxed mt-3">
              These Terms constitute a legally binding agreement between you and Modulo Squares
              ("we," "our," or "us"). We reserve the right to update these Terms at any time.
              Continued use of the App after updates constitutes acceptance.
            </p>
          </section>

          <section>
            <h2 className="text-xl font-semibold text-gray-900 mb-3">2. Use of the App</h2>

            <h3 className="text-lg font-medium text-gray-800 mb-2">2.1 Eligibility</h3>
            <p className="text-gray-700 leading-relaxed">
              You must be at least 4 years old to use the App. If you are under 13, you must have
              parental or guardian consent. By using the App, you represent that you meet these
              requirements.
            </p>

            <h3 className="text-lg font-medium text-gray-800 mt-4 mb-2">2.2 License</h3>
            <p className="text-gray-700 leading-relaxed">
              We grant you a limited, non-exclusive, non-transferable, revocable license to use
              the App for personal, non-commercial entertainment purposes. This license does not
              include any right to modify, distribute, sell, or sublicense the App or its content.
            </p>

            <h3 className="text-lg font-medium text-gray-800 mt-4 mb-2">2.3 Prohibited Conduct</h3>
            <p className="text-gray-700 leading-relaxed">You agree not to:</p>
            <ul className="list-disc list-inside text-gray-700 mt-2 space-y-1">
              <li>Reverse engineer, decompile, or disassemble the App</li>
              <li>Modify, adapt, or create derivative works based on the App</li>
              <li>Use cheats, bots, automation, or exploits that affect game integrity or leaderboards</li>
              <li>Impersonate another person or entity</li>
              <li>Attempt to gain unauthorized access to the App's systems or other users' accounts</li>
              <li>Use the App for any unlawful purpose or in violation of any applicable laws</li>
            </ul>
          </section>

          <section>
            <h2 className="text-xl font-semibold text-gray-900 mb-3">3. Accounts</h2>
            <p className="text-gray-700 leading-relaxed">
              The App requires a Google or Apple account to play. You are responsible for
              maintaining the security of your account credentials. You must notify us immediately
              at{' '}
              <a href="mailto:support@modulosquares.com" className="text-primary-600 hover:text-primary-700 underline">
                support@modulosquares.com
              </a>{' '}
              if you suspect unauthorized access to your account.
            </p>
            <p className="text-gray-700 leading-relaxed mt-3">
              We reserve the right to terminate or suspend accounts that violate these Terms or
              engage in fraudulent, abusive, or disruptive behavior.
            </p>
          </section>

          <section>
            <h2 className="text-xl font-semibold text-gray-900 mb-3">4. In-App Purchases</h2>
            <p className="text-gray-700 leading-relaxed">
              The App offers a one-time "Remove Ads" purchase at $2.99 USD (or local equivalent),
              processed by Apple App Store or Google Play. All purchases are subject to the
              payment terms of the applicable platform.
            </p>
            <p className="text-gray-700 leading-relaxed mt-3">
              <strong>All purchases are final.</strong> We do not issue refunds except where required
              by applicable law or platform policy. Refund requests must be submitted directly to
              Apple or Google through their respective support channels.
            </p>
            <p className="text-gray-700 leading-relaxed mt-3">
              Purchased entitlements (e.g., "Remove Ads") are tied to your account and can be
              restored on other devices using the same account via the "Restore Purchases" option.
              Entitlements are non-transferable between accounts or platforms.
            </p>
          </section>

          <section>
            <h2 className="text-xl font-semibold text-gray-900 mb-3">5. Leaderboards and User Content</h2>
            <p className="text-gray-700 leading-relaxed">
              Game scores submitted to the leaderboard must be achieved through legitimate gameplay.
              We reserve the right to remove scores or accounts that appear to have been achieved
              through cheating, hacking, or exploitation of bugs.
            </p>
            <p className="text-gray-700 leading-relaxed mt-3">
              The leaderboard displays your account display name (as provided by your sign-in
              provider). You are responsible for ensuring your display name does not violate
              any third-party rights or applicable laws.
            </p>
          </section>

          <section>
            <h2 className="text-xl font-semibold text-gray-900 mb-3">6. Intellectual Property</h2>
            <p className="text-gray-700 leading-relaxed">
              All content in the App — including but not limited to graphics, audio, game mechanics,
              code, and text — is owned by or licensed to Modulo Squares and is protected by
              copyright, trademark, and other intellectual property laws.
            </p>
            <p className="text-gray-700 leading-relaxed mt-3">
              You may not reproduce, distribute, or create derivative works from any App content
              without our prior written consent.
            </p>
          </section>

          <section>
            <h2 className="text-xl font-semibold text-gray-900 mb-3">7. Disclaimers</h2>
            <p className="text-gray-700 leading-relaxed">
              THE APP IS PROVIDED "AS IS" AND "AS AVAILABLE" WITHOUT WARRANTIES OF ANY KIND,
              EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO WARRANTIES OF MERCHANTABILITY,
              FITNESS FOR A PARTICULAR PURPOSE, OR NON-INFRINGEMENT.
            </p>
            <p className="text-gray-700 leading-relaxed mt-3">
              We do not warrant that the App will be uninterrupted, error-free, or free of
              viruses or other harmful components. We do not warrant that leaderboard data,
              game progress, or other user data will be preserved indefinitely.
            </p>
          </section>

          <section>
            <h2 className="text-xl font-semibold text-gray-900 mb-3">8. Limitation of Liability</h2>
            <p className="text-gray-700 leading-relaxed">
              TO THE MAXIMUM EXTENT PERMITTED BY APPLICABLE LAW, WE SHALL NOT BE LIABLE FOR
              ANY INDIRECT, INCIDENTAL, SPECIAL, CONSEQUENTIAL, OR PUNITIVE DAMAGES ARISING
              FROM YOUR USE OF OR INABILITY TO USE THE APP, INCLUDING BUT NOT LIMITED TO LOSS
              OF DATA, LOST PROFITS, OR LOSS OF GAME PROGRESS.
            </p>
            <p className="text-gray-700 leading-relaxed mt-3">
              OUR TOTAL LIABILITY TO YOU FOR ANY CLAIMS ARISING UNDER THESE TERMS SHALL NOT
              EXCEED THE AMOUNT YOU PAID FOR THE APP OR IN-APP PURCHASES IN THE TWELVE MONTHS
              PRECEDING THE CLAIM.
            </p>
          </section>

          <section>
            <h2 className="text-xl font-semibold text-gray-900 mb-3">9. Service Changes and Termination</h2>
            <p className="text-gray-700 leading-relaxed">
              We reserve the right to modify, suspend, or discontinue the App (or any part thereof)
              at any time without notice. We will not be liable to you or any third party for any
              modification, suspension, or discontinuation of the Service.
            </p>
            <p className="text-gray-700 leading-relaxed mt-3">
              We reserve the right to terminate your access to the App for violation of these Terms.
              Upon termination, your right to use the App immediately ceases.
            </p>
          </section>

          <section>
            <h2 className="text-xl font-semibold text-gray-900 mb-3">10. Governing Law</h2>
            <p className="text-gray-700 leading-relaxed">
              These Terms shall be governed by and construed in accordance with the laws of the
              jurisdiction in which Modulo Squares operates, without regard to its conflict of
              law provisions.
            </p>
          </section>

          <section>
            <h2 className="text-xl font-semibold text-gray-900 mb-3">11. Contact</h2>
            <p className="text-gray-700 leading-relaxed">
              For questions about these Terms, contact us at:
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
      </main>

      <footer className="bg-gray-100 border-t border-gray-200 py-6 px-6 mt-12">
        <div className="max-w-4xl mx-auto flex flex-col sm:flex-row items-center justify-between gap-4">
          <p className="text-gray-500 text-sm">© 2026 Modulo Squares. All rights reserved.</p>
          <div className="flex space-x-6 text-sm">
            <Link to="/privacy" className="text-gray-500 hover:text-gray-700 transition-colors">Privacy Policy</Link>
            <Link to="/terms" className="text-gray-500 hover:text-gray-700 transition-colors">Terms of Service</Link>
          </div>
        </div>
      </footer>
    </div>
  );
};

export default TermsOfService;
