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
import 'package:modulo_squares/features/game/models/falling_modulo_game_engine.dart';
import 'package:modulo_squares/features/game/models/game_theme.dart';
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
/// caller passes in the current difficulty, a live getter for the high
/// score (read fresh on every rebuild rather than captured once at open --
/// the game loop is paused behind this dialog, but the getter still needs
/// to reflect an in-dialog change like Delete Account resetting it), plus a
/// couple of callbacks to report changes back up.
Future<void> showGameSettingsDialog({
  required BuildContext context,
  required GameDifficulty difficulty,
  required int Function() getHighScore,
  required PurchaseService? purchaseService,
  required ValueChanged<GameDifficulty> onSaveDifficulty,
  required VoidCallback onHighScoreReset,
  required String highScorePrefKey,
  required GameThemeId themeId,
  required ValueChanged<GameThemeId> onSaveTheme,
}) async {
  var localDifficulty = difficulty;
  var localThemeId = themeId;
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
                    // A 3-segment SegmentedButton doesn't fit as a ListTile
                    // `trailing` widget at an AlertDialog's actual on-device
                    // width -- ListTile requires trailing to fit the space
                    // left over after title/subtitle, and it doesn't here,
                    // which throws a layout assertion ("Trailing widget
                    // consumes the entire tile width") that a widget-test's
                    // wider default surface never surfaces. Giving the
                    // control its own full-width row below the ListTile
                    // avoids that squeeze entirely.
                    const ListTile(
                      title: Text('Difficulty'),
                      subtitle: Text(
                        'Controls how fast the falling number speeds up',
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                      child: SegmentedButton<GameDifficulty>(
                        // No selected-icon: all three segments size to the
                        // widest one, and "Normal" plus a checkmark was
                        // exactly what didn't fit at an AlertDialog's
                        // on-device width, wrapping mid-word ("Norma"/"l").
                        // Each label is also scale-down-fitted rather than
                        // left to wrap, so this stays robust at larger
                        // accessibility text sizes too, not just today's
                        // default.
                        showSelectedIcon: false,
                        // Material 3's default selected-segment tint is a
                        // pale tonal tint barely different from an
                        // unselected segment -- especially now there's no
                        // selected-icon alongside it. A solid fill makes the
                        // active difficulty unmistakable at a glance.
                        style: SegmentedButton.styleFrom(
                          selectedBackgroundColor:
                              Theme.of(context).colorScheme.primary,
                          selectedForegroundColor:
                              Theme.of(context).colorScheme.onPrimary,
                        ),
                        segments: const [
                          ButtonSegment(
                            value: GameDifficulty.easy,
                            label: FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Text('Easy'),
                            ),
                          ),
                          ButtonSegment(
                            value: GameDifficulty.normal,
                            label: FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Text('Normal'),
                            ),
                          ),
                          ButtonSegment(
                            value: GameDifficulty.hard,
                            label: FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Text('Hard'),
                            ),
                          ),
                        ],
                        selected: {localDifficulty},
                        onSelectionChanged:
                            (selection) => setLocalState(
                              () => localDifficulty = selection.first,
                            ),
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

                // ── Appearance ────────────────────────────────────────
                SettingsSection(
                  title: 'Appearance',
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
                      child: _ThemePicker(
                        selected: localThemeId,
                        onSelected:
                            (id) => setLocalState(() => localThemeId = id),
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
                      onSaveDifficulty(localDifficulty);
                      onSaveTheme(localThemeId);
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
        await googleUser.authorizationClient.authorizeScopes(_googleAuthScopes);
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

/// A row of tappable swatches for picking the falling-mode color theme,
/// shown in the Settings dialog's Appearance section. Each swatch previews
/// its palette's board gradient so the choice is visual, not just a name.
class _ThemePicker extends StatelessWidget {
  const _ThemePicker({required this.selected, required this.onSelected});

  final GameThemeId selected;
  final ValueChanged<GameThemeId> onSelected;

  // Chunked Rows instead of a Wrap: a Wrap containing a swatch that
  // Align-centers its checkmark (see _ThemeSwatch) hits a real Flutter
  // rendering bug when it sits inside an AlertDialog's route transition
  // (flutter/flutter#169214) -- the dialog's barrier shows but its content
  // never paints. Rows/Columns use RenderFlex, which isn't affected.
  static const int _perRow = 4;

  @override
  Widget build(BuildContext context) {
    final swatches = [
      for (final id in gameThemeOrder)
        _ThemeSwatch(
          id: id,
          palette: gameThemePalettes[id]!,
          selected: id == selected,
          onTap: () => onSelected(id),
        ),
    ];

    final rows = <Widget>[];
    for (var i = 0; i < swatches.length; i += _perRow) {
      final rowSwatches = swatches.skip(i).take(_perRow).toList();
      rows.add(
        Padding(
          padding: EdgeInsets.only(top: i == 0 ? 0 : 12),
          child: Row(
            // Top-aligned: a one-line name (Deep Ocean, Candy Pop) and a
            // two-line one (Arcade Neon, Warm Sunset) give their columns
            // different total heights, and Row's default center alignment
            // was centering each column in the row -- sinking the one-line
            // swatches' color boxes below the two-line ones'. Top alignment
            // keeps every color box flush on the same line regardless of
            // how its name wraps.
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (var j = 0; j < rowSwatches.length; j++) ...[
                if (j > 0) const SizedBox(width: 12),
                // Expanded, not a fixed width: four swatches at a fixed
                // width risked overflowing a narrower AlertDialog than this
                // was tuned against -- sharing the row equally always fits.
                Expanded(child: rowSwatches[j]),
              ],
            ],
          ),
        ),
      );
    }
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: rows);
  }
}

class _ThemeSwatch extends StatelessWidget {
  const _ThemeSwatch({
    required this.id,
    required this.palette,
    required this.selected,
    required this.onTap,
  });

  final GameThemeId id;
  final GameThemePalette palette;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      key: Key('theme-swatch-${id.name}'),
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [palette.boardGradientFrom, palette.boardGradientTo],
              ),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color:
                    selected
                        ? Theme.of(context).colorScheme.primary
                        : Colors.black12,
                width: selected ? 3 : 1,
              ),
            ),
            // Centered via Column/Row flex, not Container's `alignment`
            // (Align/RenderPositionedBox) -- see the note on _ThemePicker
            // above for why that matters inside this dialog.
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                if (selected)
                  Container(
                    padding: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.35),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.check,
                      color: Colors.white,
                      size: 16,
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 6),
          Text(
            palette.name,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 11,
              fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
              color:
                  selected
                      ? Theme.of(context).colorScheme.primary
                      : Colors.grey.shade700,
            ),
          ),
        ],
      ),
    );
  }
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
