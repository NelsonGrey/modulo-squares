import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'package:modulo/core/services/error_handler.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  Future<void> _signInWithGoogle(BuildContext context) async {
    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();

      if (googleUser == null) {
        // User cancelled the sign-in
        return;
      }

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;

      final AuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      await FirebaseAuth.instance.signInWithCredential(credential);
    } catch (e) {
      if (context.mounted) {
        ErrorHandler().showErrorSnackBar(
          context,
          ErrorHandler().getAuthErrorMessage(e),
        );
      }
    }
  }

  Future<void> _signInWithApple(BuildContext context) async {
    try {
      final appleCredential = await SignInWithApple.getAppleIDCredential(
        scopes: [AppleIDAuthorizationScopes.email, AppleIDAuthorizationScopes.fullName],
      );

      if (appleCredential.identityToken == null) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Apple sign-in failed: No identity token')),
          );
        }
        return;
      }

      final oauthCredential = OAuthProvider("apple.com").credential(
        idToken: appleCredential.identityToken,
      );
      await FirebaseAuth.instance.signInWithCredential(oauthCredential);
    } catch (e) {
      if (context.mounted) {
        ErrorHandler().showErrorSnackBar(
          context,
          ErrorHandler().getAuthErrorMessage(e),
        );
      }
    }
  }

  Future<void> _signInAnonymously(BuildContext context) async {
    try {
      await FirebaseAuth.instance.signInAnonymously();
    } on FirebaseAuthException catch (e) {
      debugPrint('Anonymous sign-in failed: ${e.code} - ${e.message}');
      if (context.mounted) {
        ErrorHandler().showErrorSnackBar(
          context,
          ErrorHandler().getAuthErrorMessage(e),
          onRetry: () => _signInAnonymously(context),
        );
      }
    } catch (e) {
      debugPrint('Anonymous sign-in failed: $e');
      if (context.mounted) {
        ErrorHandler().showErrorSnackBar(
          context,
          'An unexpected error occurred during guest sign-in.',
          onRetry: () => _signInAnonymously(context),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(height: 20),
          const Text('Some static text'),
          ElevatedButton(
            onPressed: () => _signInWithGoogle(context),
            child: const Text('Sign in with Google'),
          ),
          const SizedBox(height: 12),
          ElevatedButton(
            onPressed: () => _signInWithApple(context),
            child: const Text('Sign in with Apple'),
          ),
          const SizedBox(height: 24),
          const Text('or'),
          const SizedBox(height: 12),
          OutlinedButton(
            onPressed: () => _signInAnonymously(context),
            child: const Text('Play as Guest'),
          ),
        ],
      ),
    );
  }
}
