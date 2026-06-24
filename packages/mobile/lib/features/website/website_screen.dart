import 'package:flutter/material.dart';
import 'legal_pages.dart';

void _launchUrl(String url) {
  // URL launching is handled at the platform level
  // This is a placeholder for web-specific URL opening
}

class WebsiteScreen extends StatefulWidget {
  const WebsiteScreen({super.key});

  @override
  State<WebsiteScreen> createState() => _WebsiteScreenState();
}

class _WebsiteScreenState extends State<WebsiteScreen> {
  final _feedbackController = TextEditingController();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _scrollController = ScrollController();

  // Current page state
  String _currentPage = 'home'; // 'home', 'privacy', 'terms'

  // Global keys for section navigation
  final _homeKey = GlobalKey();
  final _downloadKey = GlobalKey();
  final _rulesKey = GlobalKey();
  final _feedbackKey = GlobalKey();

  @override
  void dispose() {
    _feedbackController.dispose();
    _nameController.dispose();
    _emailController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _launchAppStore() {
    _launchUrl('https://apps.apple.com/app/modulo-squares/id1234567890');
  }

  void _launchPlayStore() {
    _launchUrl('https://play.google.com/store/apps/details?id=com.modulosquares.app');
  }

  void _launchPrivacyPolicy() {
    setState(() {
      _currentPage = 'privacy';
    });
  }

  void _launchTermsOfService() {
    setState(() {
      _currentPage = 'terms';
    });
  }

  void _scrollToSection(GlobalKey key) {
    final context = key.currentContext;
    if (context != null) {
      Scrollable.ensureVisible(
        context,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
        alignment: 0.0, // Align to top
      );
    }
  }

  void _launchContact() {
    setState(() {
      _currentPage = 'home';
    });
    // Scroll to feedback section after state update
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToSection(_feedbackKey);
    });
  }

  void _launchAbout() {
    setState(() {
      _currentPage = 'home';
    });
    // Scroll to hero section after state update
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToSection(_homeKey);
    });
  }

  void _goHome() {
    setState(() {
      _currentPage = 'home';
    });
  }

  void _submitFeedback() {
    final name = _nameController.text.trim();
    final feedback = _feedbackController.text.trim();

    if (name.isEmpty || feedback.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill in your name and feedback')),
      );
      return;
    }

    // Here you would typically send the feedback to a backend service
    // For now, just show a success message
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Thank you for your feedback!')),
    );

    // Clear the form
    _nameController.clear();
    _emailController.clear();
    _feedbackController.clear();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildAppBar(),
      body: _buildBody(),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    if (_currentPage != 'home') {
      // Legal pages have a simple app bar with back button
      return AppBar(
        title: Text(_currentPage == 'privacy' ? 'Privacy Policy' : 'Terms of Service'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Theme.of(context).colorScheme.onPrimary,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: _goHome,
        ),
      );
    }

    // Home page has full navigation
    return AppBar(
      title: const Text('Modulo Squares'),
      backgroundColor: Theme.of(context).colorScheme.primary,
      foregroundColor: Theme.of(context).colorScheme.onPrimary,
      actions: [
        TextButton(
          onPressed: () => _scrollToSection(_homeKey),
          child: Text(
            'Home',
            style: TextStyle(color: Theme.of(context).colorScheme.onPrimary),
          ),
        ),
        TextButton(
          onPressed: () => _scrollToSection(_downloadKey),
          child: Text(
            'Download',
            style: TextStyle(color: Theme.of(context).colorScheme.onPrimary),
          ),
        ),
        TextButton(
          onPressed: () => _scrollToSection(_rulesKey),
          child: Text(
            'Rules',
            style: TextStyle(color: Theme.of(context).colorScheme.onPrimary),
          ),
        ),
        TextButton(
          onPressed: () => _scrollToSection(_feedbackKey),
          child: Text(
            'Feedback',
            style: TextStyle(color: Theme.of(context).colorScheme.onPrimary),
          ),
        ),
      ],
    );
  }

  Widget _buildBody() {
    switch (_currentPage) {
      case 'privacy':
        return LegalPage(
          title: 'Privacy Policy',
          content: LegalPage.privacyPolicyContent,
          onHomePressed: _goHome,
        );
      case 'terms':
        return LegalPage(
          title: 'Terms of Service',
          content: LegalPage.termsOfServiceContent,
          onHomePressed: _goHome,
        );
      case 'home':
      default:
        return SingleChildScrollView(
          controller: _scrollController,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(key: _homeKey, child: _buildHeroSection()),
              Container(key: _downloadKey, child: _buildDownloadSection()),
              Container(key: _rulesKey, child: _buildGameRulesSection()),
              Container(key: _feedbackKey, child: _buildFeedbackSection()),
              _buildFooter(),
            ],
          ),
        );
    }
  }

  Widget _buildHeroSection() {
    return Container(
      constraints: BoxConstraints(minHeight: MediaQuery.of(context).size.height * 0.8),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Theme.of(context).colorScheme.primary,
            Theme.of(context).colorScheme.secondary,
          ],
        ),
      ),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.grid_4x4,
                size: 120,
                color: Theme.of(context).colorScheme.onPrimary,
              ),
              const SizedBox(height: 24),
              Text(
                'Modulo Squares',
                style: Theme.of(context).textTheme.displayLarge?.copyWith(
                      color: Theme.of(context).colorScheme.onPrimary,
                      fontWeight: FontWeight.bold,
                    ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Text(
                'Master the art of modulo arithmetic in this addictive puzzle game. '
                'Move tiles, apply mathematical operations, and clear the board to win!',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onPrimary.withValues(alpha: 0.9),
                    ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ElevatedButton.icon(
                    onPressed: _launchAppStore,
                    icon: const Icon(Icons.apple),
                    label: const Text('Download for iOS'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.black,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    ),
                  ),
                  const SizedBox(width: 16),
                  ElevatedButton.icon(
                    onPressed: _launchPlayStore,
                    icon: const Icon(Icons.android),
                    label: const Text('Download for Android'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDownloadSection() {
    return Container(
      padding: const EdgeInsets.all(64.0),
      color: Theme.of(context).colorScheme.surface,
      child: Column(
        children: [
          Text(
            'Download Modulo Squares',
            style: Theme.of(context).textTheme.displayMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 32),
          Row(
            children: [
              Expanded(
                child: _buildDownloadCard(
                  title: 'iOS App Store',
                  description: 'Download from the Apple App Store for iPhone and iPad',
                  icon: Icons.apple,
                  buttonText: 'Get on App Store',
                  onPressed: _launchAppStore,
                  color: Colors.black,
                ),
              ),
              const SizedBox(width: 32),
              Expanded(
                child: _buildDownloadCard(
                  title: 'Google Play Store',
                  description: 'Download from Google Play for Android devices',
                  icon: Icons.android,
                  buttonText: 'Get on Play Store',
                  onPressed: _launchPlayStore,
                  color: Colors.green,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDownloadCard({
    required String title,
    required String description,
    required IconData icon,
    required String buttonText,
    required VoidCallback onPressed,
    required Color color,
  }) {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            Icon(icon, size: 48, color: color),
            const SizedBox(height: 16),
            Text(
              title,
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              description,
              style: Theme.of(context).textTheme.bodyLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: onPressed,
              style: ElevatedButton.styleFrom(
                backgroundColor: color,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
              child: Text(buttonText),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGameRulesSection() {
    return Container(
      padding: const EdgeInsets.all(64.0),
      color: Theme.of(context).colorScheme.surface,
      child: Column(
        children: [
          Text(
            'How to Play',
            style: Theme.of(context).textTheme.displayMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 32),
          Text(
            'Modulo Squares is a strategic puzzle game that combines tile-matching mechanics with mathematical operations.',
            style: Theme.of(context).textTheme.headlineMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 48),
          _buildRuleCard(
            number: '1',
            title: 'The Grid',
            description: 'Play on a 4x4 grid filled with numbered tiles. Your goal is to clear all tiles from the board.',
          ),
          _buildRuleCard(
            number: '2',
            title: 'Tile Movement',
            description: 'Tap a tile to select it, then tap an adjacent tile (up, down, left, or right) to move it.',
          ),
          _buildRuleCard(
            number: '3',
            title: 'Modulo Operation',
            description:
                'When moving a tile onto another tile, the modulo operation occurs: target = target % source. If the result is 0, the target tile disappears.',
          ),
          _buildRuleCard(
            number: '4',
            title: 'Empty Spaces',
            description: 'Moving a tile into an empty space simply transfers the tile to the new location.',
          ),
          _buildRuleCard(
            number: '5',
            title: 'Winning',
            description: 'Clear the entire board of all numbered tiles to complete the level and advance to the next challenge.',
          ),
          const SizedBox(height: 32),
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primaryContainer,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                Text(
                  'Example',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Moving an 8 onto a 6: 6 % 8 = 6 (since 8 > 6, no change)\n'
                  'Moving a 3 onto a 9: 9 % 3 = 0 (tile disappears!)',
                  style: Theme.of(context).textTheme.bodyLarge,
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRuleCard({
    required String number,
    required String title,
    required String description,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleAvatar(
              radius: 20,
              backgroundColor: Theme.of(context).colorScheme.primary,
              child: Text(
                number,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onPrimary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    description,
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeedbackSection() {
    return Container(
      padding: const EdgeInsets.all(64.0),
      color: Theme.of(context).colorScheme.surface,
      child: Column(
        children: [
          Text(
            'Share Your Thoughts',
            style: Theme.of(context).textTheme.displayMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 16),
          Text(
            'We love hearing from our players! Share your suggestions, bug reports, or general feedback.',
            style: Theme.of(context).textTheme.headlineMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 48),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 600),
            child: Column(
              children: [
                TextField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: 'Your Name',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _emailController,
                  decoration: const InputDecoration(
                    labelText: 'Email (optional)',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.emailAddress,
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _feedbackController,
                  decoration: const InputDecoration(
                    labelText: 'Your Feedback',
                    border: OutlineInputBorder(),
                    alignLabelWithHint: true,
                  ),
                  maxLines: 5,
                  maxLength: 1000,
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: _submitFeedback,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 16),
                  ),
                  child: const Text('Submit Feedback'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFooter() {
    return Container(
      padding: const EdgeInsets.all(48.0),
      color: Theme.of(context).colorScheme.primary,
      child: Column(
        children: [
          // Main footer content
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Company info
              Expanded(
                flex: 2,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Modulo Squares',
                      style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                            color: Theme.of(context).colorScheme.onPrimary,
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Master the art of modulo arithmetic in this addictive puzzle game. '
                      'Challenge your mind with strategic tile movements and mathematical operations.',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onPrimary.withValues(alpha: 0.8),
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 24),
                    Row(
                      children: [
                        IconButton(
                          onPressed: _launchAppStore,
                          icon: const Icon(Icons.apple),
                          color: Theme.of(context).colorScheme.onPrimary,
                          tooltip: 'Download on App Store',
                        ),
                        IconButton(
                          onPressed: _launchPlayStore,
                          icon: const Icon(Icons.android),
                          color: Theme.of(context).colorScheme.onPrimary,
                          tooltip: 'Download on Google Play',
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 48),
              // Links section
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Links',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            color: Theme.of(context).colorScheme.onPrimary,
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 16),
                    _buildFooterLink('About', _launchAbout),
                    _buildFooterLink('Contact', _launchContact),
                    _buildFooterLink('Privacy Policy', _launchPrivacyPolicy),
                    _buildFooterLink('Terms of Service', _launchTermsOfService),
                  ],
                ),
              ),
              const SizedBox(width: 48),
              // Legal section
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Legal',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            color: Theme.of(context).colorScheme.onPrimary,
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      '© 2025 Modulo Squares. All rights reserved.',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onPrimary.withValues(alpha: 0.8),
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Built with Flutter • Available on iOS and Android',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onPrimary.withValues(alpha: 0.6),
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'This game contains advertisements and in-app purchases.',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onPrimary.withValues(alpha: 0.6),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 32),
          // Bottom divider
          Divider(
            color: Theme.of(context).colorScheme.onPrimary.withValues(alpha: 0.2),
            thickness: 1,
          ),
          const SizedBox(height: 16),
          // Bottom text
          Text(
            'Educational puzzle game designed to make learning modulo arithmetic fun and engaging.',
            style: TextStyle(
              color: Theme.of(context).colorScheme.onPrimary.withValues(alpha: 0.7),
              fontSize: 12,
              fontStyle: FontStyle.italic,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildFooterLink(String text, VoidCallback onPressed) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: TextButton(
        onPressed: onPressed,
        style: TextButton.styleFrom(
          padding: EdgeInsets.zero,
          minimumSize: Size.zero,
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          alignment: Alignment.centerLeft,
        ),
        child: Text(
          text,
          style: TextStyle(
            color: Theme.of(context).colorScheme.onPrimary.withValues(alpha: 0.8),
            fontSize: 14,
          ),
        ),
      ),
    );
  }
}
