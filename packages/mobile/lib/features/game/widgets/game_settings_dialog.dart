import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show Clipboard, ClipboardData;
import 'package:google_sign_in/google_sign_in.dart';
import 'package:modulo_squares/core/auth/apple_sign_in_nonce.dart';
import 'package:modulo_squares/core/di/service_locator.dart';
import 'package:modulo_squares/core/services/analytics_service.dart';
import 'package:modulo_squares/core/services/purchase_service.dart';
import 'package:modulo_squares/features/auth/change_password_screen.dart';
import 'package:modulo_squares/features/game/widgets/purchase_section.dart';
import 'package:modulo_squares/features/game/widgets/settings_section.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'package:url_launcher/url_launcher.dart';

// Android's play-services-auth SDK throws IllegalArgumentException
// ("requestedScopes cannot be null or empty") if this list is empty --
// see the matching constant in login_screen.dart.
const List<String> _googleAuthScopes = ['email'];

/// Opens the falling-mode Settings dialog: Gameplay, Purchases, Account
/// (including link-account / sign-out / delete-account) and Legal &
/// Support.
///
/// This owns the dialog's own presentation logic and the account-management
/// side effects it triggers (sign-out, delete-account, linking a guest
/// account to Google/Apple/Email). It does not own the game-loop timer or
/// core game state — those stay on [FallingModuloGameScreen] — so the
/// caller passes in the current visual-cues value, a live getter for the
/// high score (read fresh on every rebuild, since the score can keep
/// climbing in the game loop behind this dialog), plus a couple of
/// callbacks to report changes back up.
Future<void> showGameSettingsDialog({
  required BuildContext context,
  required bool visualCuesEnabled,
  required int Function() getHighScore,
  required PurchaseService? purchaseService,
  required ValueChanged<bool> onSaveVisualCues,
  required VoidCallback onHighScoreReset,
  required String highScorePrefKey,
}) async {
  var localVisualCues = visualCuesEnabled;
  var adsRemoved = purchaseService?.adsRemoved ?? false;
  bool isGuest = false;
  try {
    isGuest = FirebaseAuth.instance.currentUser?.isAnonymous ?? false;
  } catch (_) {
    // Firebase not initialized in test environment.
  }
  bool hasPasswordProvider = false;
  try {
    hasPasswordProvider =
        FirebaseAuth.instance.currentUser?.providerData.any(
          (info) => info.providerId == 'password',
        ) ??
        false;
  } catch (_) {
    // Firebase not initialized in test environment.
  }

  await showDialog<void>(
    context: context,
    builder: (dialogContext) {
      return StatefulBuilder(
        builder: (context, setLocalState) {
          return AlertDialog(
            title: const Text('Settings'),
            scrollable: true,
            contentPadding: const EdgeInsets.symmetric(vertical: 12),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // ── Gameplay ──────────────────────────────────────────
                SettingsSection(
                  title: 'Gameplay',
                  initiallyExpanded: true,
                  children: [
                    SwitchListTile(
                      value: localVisualCues,
                      onChanged:
                          (value) =>
                              setLocalState(() => localVisualCues = value),
                      title: const Text('Visual Cues'),
                      subtitle: const Text(
                        'Highlight buckets that divide the current number evenly',
                      ),
                    ),
                    ListTile(
                      title: const Text('Best Score'),
                      trailing: Text(
                        '${getHighScore()}',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),

                // ── Purchases ─────────────────────────────────────────
                if (purchaseService != null)
                  PurchaseSection(
                    purchaseService: purchaseService,
                    adsRemoved: adsRemoved,
                    onAdsRemovedChanged:
                        (value) => setLocalState(() => adsRemoved = value),
                  ),

                // ── Account ───────────────────────────────────────────
                SettingsSection(
                  title: 'Account',
                  children: [
                    if (isGuest)
                      ListTile(
                        leading: const Icon(Icons.link),
                        title: const Text('Link Account'),
                        subtitle: const Text(
                          'Save your progress with Google, Apple, or Email',
                        ),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () {
                          Navigator.of(dialogContext).pop();
                          _openLinkAccountDialog(context);
                        },
                      ),
                    if (isGuest)
                      ListTile(
                        leading: const Icon(Icons.badge_outlined),
                        title: const Text('Player ID'),
                        subtitle: Text(
                          'Guest accounts have no email — include this ID in a '
                          'support request if you need your account deleted and '
                          "can't reach the app.\n"
                          '${FirebaseAuth.instance.currentUser?.uid ?? ''}',
                        ),
                        trailing: const Icon(Icons.copy, size: 20),
                        onTap: () {
                          final uid = FirebaseAuth.instance.currentUser?.uid;
                          if (uid == null) return;
                          Clipboard.setData(ClipboardData(text: uid));
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Player ID copied')),
                          );
                        },
                      ),
                    if (hasPasswordProvider)
                      ListTile(
                        leading: const Icon(Icons.password),
                        title: const Text('Change Password'),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () {
                          Navigator.of(dialogContext).pop();
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const ChangePasswordScreen(),
                            ),
                          );
                        },
                      ),
                    ListTile(
                      leading: const Icon(Icons.logout, color: Colors.red),
                      title: const Text(
                        'Sign Out',
                        style: TextStyle(color: Colors.red),
                      ),
                      onTap: () => _signOut(context),
                    ),
                    ListTile(
                      leading: const Icon(
                        Icons.delete_forever,
                        color: Colors.red,
                      ),
                      title: const Text(
                        'Delete Account',
                        style: TextStyle(color: Colors.red),
                      ),
                      onTap:
                          () => _deleteAccount(
                            context,
                            highScorePrefKey: highScorePrefKey,
                            onHighScoreReset: onHighScoreReset,
                          ),
                    ),
                  ],
                ),

                // ── Legal & Support ──────────────────────────────────
                SettingsSection(
                  title: 'Legal & Support',
                  children: [
                    ListTile(
                      leading: const Icon(Icons.privacy_tip_outlined),
                      title: const Text('Privacy Policy'),
                      trailing: const Icon(Icons.open_in_new, size: 18),
                      onTap: () => _openLegalLink('privacy'),
                    ),
                    ListTile(
                      leading: const Icon(Icons.description_outlined),
                      title: const Text('Terms of Service'),
                      trailing: const Icon(Icons.open_in_new, size: 18),
                      onTap: () => _openLegalLink('terms'),
                    ),
                    ListTile(
                      leading: const Icon(Icons.help_outline),
                      title: const Text('Support'),
                      trailing: const Icon(Icons.open_in_new, size: 18),
                      onTap: () => _openLegalLink('support'),
                    ),
                  ],
                ),
              ],
            ),
            actions: [
              // A plain Row instead of relying on AlertDialog's default
              // OverflowBar: OverflowBar was stacking these three actions
              // vertically even though they comfortably fit on one line.
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.of(dialogContext).pop(),
                    child: const Text('Cancel'),
                  ),
                  FilledButton(
                    onPressed: () {
                      onSaveVisualCues(localVisualCues);
                      Navigator.of(dialogContext).pop();
                    },
                    child: const Text('Save'),
                  ),
                ],
              ),
            ],
          );
        },
      );
    },
  );
}

void _showAccountError(BuildContext context, dynamic error) {
  if (!context.mounted) return;
  final message =
      error is FirebaseAuthException
          ? '${error.message ?? error.code}\n\n(code: ${error.code})'
          : error.toString();
  showDialog<void>(
    context: context,
    builder:
        (_) => AlertDialog(
          title: const Text('Account error'),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('OK'),
            ),
          ],
        ),
  );
}

Future<void> _openLegalLink(String path) async {
  final uri = Uri.parse('https://modulosquares.com/$path');
  await launchUrl(uri, mode: LaunchMode.externalApplication);
}

Future<void> _signOut(BuildContext context) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder:
        (ctx) => AlertDialog(
          title: const Text('Sign out?'),
          content: const Text(
            'You will be returned to the sign-in screen. '
            'Your progress is saved to your account.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(ctx).pop(true),
              child: const Text('Sign out'),
            ),
          ],
        ),
  );
  if (confirmed != true) return;
  if (context.mounted) Navigator.of(context).pop();
  // Best-effort cleanup — an Analytics SDK error must never block sign-out.
  try {
    await getIt<AnalyticsService>().clearUserId();
  } catch (_) {}
  await FirebaseAuth.instance.signOut();
}

Future<void> _deleteAccount(
  BuildContext context, {
  required String highScorePrefKey,
  required VoidCallback onHighScoreReset,
}) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder:
        (ctx) => AlertDialog(
          title: const Text('Delete account?'),
          content: const Text(
            'This permanently deletes your account, gamertag, saved progress, '
            'and purchase history. This cannot be undone.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(backgroundColor: Colors.red),
              onPressed: () => Navigator.of(ctx).pop(true),
              child: const Text('Delete account'),
            ),
          ],
        ),
  );
  if (confirmed != true) return;
  if (context.mounted) Navigator.of(context).pop();

  try {
    await FirebaseFunctions.instance.httpsCallable('deleteAccount').call();
  } catch (e) {
    if (context.mounted) _showAccountError(context, e);
    return;
  }

  // The account is deleted server-side past this point — everything below is
  // best-effort local cleanup and must never prevent sign-out.
  try {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(highScorePrefKey);
  } catch (_) {}
  onHighScoreReset();
  try {
    await getIt<AnalyticsService>().clearUserId();
  } catch (_) {}
  await FirebaseAuth.instance.signOut();
}

Future<void> _linkWithGoogle(BuildContext context) async {
  try {
    final googleSignIn = GoogleSignIn.instance;
    await googleSignIn.initialize();
    final googleUser = await googleSignIn.authenticate();
    final auth = googleUser.authentication;
    final idToken = auth.idToken;
    if (idToken == null) {
      _showAccountError(context, 'No ID token returned from Google.');
      return;
    }
    final authorization =
        await googleUser.authorizationClient.authorizationForScopes(
          _googleAuthScopes,
        ) ??
        await googleUser.authorizationClient.authorizeScopes(
          _googleAuthScopes,
        );
    final credential = GoogleAuthProvider.credential(
      accessToken: authorization.accessToken,
      idToken: idToken,
    );
    await FirebaseAuth.instance.currentUser?.linkWithCredential(credential);
    if (context.mounted) {
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Account linked with Google.')),
      );
    }
  } catch (e) {
    _showAccountError(context, e);
  }
}

Future<void> _linkWithApple(BuildContext context) async {
  try {
    final rawNonce = generateAppleSignInNonce();
    final appleCredential = await SignInWithApple.getAppleIDCredential(
      scopes: [
        AppleIDAuthorizationScopes.email,
        AppleIDAuthorizationScopes.fullName,
      ],
      nonce: sha256OfString(rawNonce),
    );
    if (appleCredential.identityToken == null) {
      _showAccountError(context, 'Apple did not return an identity token.');
      return;
    }
    final credential = OAuthProvider('apple.com').credential(
      idToken: appleCredential.identityToken,
      rawNonce: rawNonce,
      accessToken: appleCredential.authorizationCode,
    );
    await FirebaseAuth.instance.currentUser?.linkWithCredential(credential);
    if (context.mounted) {
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Account linked with Apple.')),
      );
    }
  } catch (e) {
    _showAccountError(context, e);
  }
}

Future<void> _linkWithEmail(BuildContext context) async {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  await showDialog<void>(
    context: context,
    builder:
        (dialogContext) => StatefulBuilder(
          builder:
              (localContext, setLocalState) => AlertDialog(
                title: const Text('Create account with email'),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: emailController,
                      keyboardType: TextInputType.emailAddress,
                      autocorrect: false,
                      enableSuggestions: false,
                      decoration: const InputDecoration(labelText: 'Email'),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: passwordController,
                      obscureText: true,
                      autocorrect: false,
                      enableSuggestions: false,
                      decoration: const InputDecoration(labelText: 'Password'),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Password must be 8+ characters with uppercase, '
                      'lowercase, a number, and a special character.',
                      style: TextStyle(fontSize: 11, color: Colors.grey),
                    ),
                  ],
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(dialogContext).pop(),
                    child: const Text('Cancel'),
                  ),
                  FilledButton(
                    onPressed: () async {
                      final email = emailController.text.trim();
                      final password = passwordController.text;
                      if (email.isEmpty || password.isEmpty) return;
                      try {
                        final credential = EmailAuthProvider.credential(
                          email: email,
                          password: password,
                        );
                        await FirebaseAuth.instance.currentUser
                            ?.linkWithCredential(credential);
                        if (dialogContext.mounted) {
                          Navigator.of(dialogContext).pop();
                        }
                        if (context.mounted) {
                          Navigator.of(context).pop();
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Account linked with email.'),
                            ),
                          );
                        }
                      } catch (e) {
                        if (dialogContext.mounted) {
                          Navigator.of(dialogContext).pop();
                        }
                        _showAccountError(context, e);
                      }
                    },
                    child: const Text('Link account'),
                  ),
                ],
              ),
        ),
  );

  emailController.dispose();
  passwordController.dispose();
}

Future<void> _openLinkAccountDialog(BuildContext context) async {
  await showDialog<void>(
    context: context,
    builder:
        (dialogContext) => AlertDialog(
          title: const Text('Link your account'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Choose a sign-in method to link to your guest account. '
                'Your gamertag and progress will be preserved.',
              ),
              const SizedBox(height: 16),
              _LinkButton(
                label: 'Link with Google',
                icon: Icons.g_mobiledata,
                onPressed: () {
                  Navigator.of(dialogContext).pop();
                  _linkWithGoogle(context);
                },
              ),
              const SizedBox(height: 8),
              _LinkButton(
                label: 'Link with Apple',
                icon: Icons.apple,
                onPressed: () {
                  Navigator.of(dialogContext).pop();
                  _linkWithApple(context);
                },
              ),
              const SizedBox(height: 8),
              _LinkButton(
                label: 'Link with Email',
                icon: Icons.email_outlined,
                onPressed: () {
                  Navigator.of(dialogContext).pop();
                  _linkWithEmail(context);
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Cancel'),
            ),
          ],
        ),
  );
}

class _LinkButton extends StatelessWidget {
  const _LinkButton({
    required this.label,
    required this.icon,
    required this.onPressed,
  });

  final String label;
  final IconData icon;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, size: 20),
        label: Text(label),
        style: OutlinedButton.styleFrom(
          alignment: Alignment.centerLeft,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
      ),
    );
  }
}
