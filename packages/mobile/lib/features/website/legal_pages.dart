import 'package:flutter/material.dart';

class LegalPage extends StatelessWidget {
  final String title;
  final String content;
  final VoidCallback? onHomePressed;

  const LegalPage({
    super.key,
    required this.title,
    required this.content,
    this.onHomePressed,
  });

  // Public constants for content
  static const String privacyPolicyContent = '''
Privacy Policy for Modulo Squares

Last updated: October 12, 2025

This Privacy Policy describes how Modulo Squares ("we", "us", or "our") collects, uses, and protects your information when you use our mobile application.

Information We Collect

1. Personal Information
   - Name and email address (if provided through feedback forms)
   - User-generated content (feedback, suggestions)

2. Usage Information
   - App usage statistics and analytics
   - Device information (device type, operating system)
   - Game progress and scores

3. Firebase Analytics
   - We use Firebase Analytics to understand how users interact with our app
   - This includes information about app crashes, usage patterns, and performance

How We Use Your Information

- To provide and maintain our game service
- To communicate with you about updates and features
- To analyze usage patterns and improve the app
- To respond to your feedback and support requests

Information Sharing

We do not sell, trade, or otherwise transfer your personal information to third parties, except:
- As required by law
- To protect our rights and safety
- With your explicit consent

Data Security

We implement appropriate security measures to protect your personal information against unauthorized access, alteration, disclosure, or destruction.

Children's Privacy

Our app is not intended for children under 13. We do not knowingly collect personal information from children under 13.

Changes to This Policy

We may update this Privacy Policy from time to time. We will notify you of any changes by posting the new policy on this page.

Contact Us

If you have any questions about this Privacy Policy, please contact us through the feedback form in the app.
''';

  static const String termsOfServiceContent = '''
Terms of Service for Modulo Squares

Last updated: October 12, 2025

These Terms of Service ("Terms") govern your use of Modulo Squares, a mobile puzzle game developed by our team.

Acceptance of Terms

By downloading, installing, or using Modulo Squares, you agree to be bound by these Terms. If you do not agree to these Terms, please do not use our app.

Description of Service

Modulo Squares is a puzzle game that combines tile-matching mechanics with mathematical operations. The game is available for free with optional in-app purchases and advertisements.

User Accounts

Some features may require user accounts through Firebase Authentication. You are responsible for maintaining the confidentiality of your account information.

In-App Purchases

- All purchases are final and non-refundable
- Virtual items purchased have no monetary value
- We reserve the right to modify or discontinue any virtual items

Advertisements

Our app contains advertisements provided by third-party ad networks. These networks may collect information as described in their respective privacy policies.

User Conduct

You agree not to:
- Use the app for any illegal purposes
- Attempt to reverse engineer or modify the app
- Distribute the app without permission
- Harass or abuse other users

Intellectual Property

All content, features, and functionality of Modulo Squares are owned by us and are protected by copyright, trademark, and other intellectual property laws.

Disclaimer of Warranties

The app is provided "as is" without warranties of any kind. We do not guarantee that the app will be error-free or uninterrupted.

Limitation of Liability

To the maximum extent permitted by law, we shall not be liable for any indirect, incidental, special, or consequential damages.

Termination

We reserve the right to terminate or suspend your access to the app at our discretion.

Governing Law

These Terms shall be governed by the laws of the jurisdiction in which our company is incorporated.

Changes to Terms

We may modify these Terms at any time. Continued use of the app after changes constitutes acceptance of the new Terms.

Contact Information

For questions about these Terms, please use the feedback form within the app.
''';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Theme.of(context).colorScheme.onPrimary,
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.displayMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    content,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          height: 1.6,
                        ),
                  ),
                  const SizedBox(height: 48),
                ],
              ),
            ),
          ),
          // Footer with navigation
          Container(
            padding: const EdgeInsets.all(24.0),
            color: Theme.of(context).colorScheme.primary,
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    TextButton(
                      onPressed: onHomePressed ?? () => Navigator.of(context).pop(),
                      child: Text(
                        'Back to Home',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onPrimary,
                          fontSize: 16,
                        ),
                      ),
                    ),
                    const SizedBox(width: 32),
                    TextButton(
                      onPressed: () {
                        // Navigate to privacy policy
                        Navigator.of(context).pushReplacement(
                          MaterialPageRoute(
                            builder: (context) => LegalPage(
                              title: 'Privacy Policy',
                              content: LegalPage.privacyPolicyContent,
                              onHomePressed: onHomePressed,
                            ),
                          ),
                        );
                      },
                      child: Text(
                        'Privacy Policy',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onPrimary.withValues(alpha: 0.8),
                          fontSize: 14,
                        ),
                      ),
                    ),
                    const SizedBox(width: 32),
                    TextButton(
                      onPressed: () {
                        // Navigate to terms of service
                        Navigator.of(context).pushReplacement(
                          MaterialPageRoute(
                            builder: (context) => LegalPage(
                              title: 'Terms of Service',
                              content: LegalPage.termsOfServiceContent,
                              onHomePressed: onHomePressed,
                            ),
                          ),
                        );
                      },
                      child: Text(
                        'Terms of Service',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onPrimary.withValues(alpha: 0.8),
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  '© 2025 Modulo Squares. All rights reserved.',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onPrimary.withValues(alpha: 0.7),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
