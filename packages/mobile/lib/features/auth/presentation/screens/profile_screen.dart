import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:modulo_squares/l10n/app_localizations.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(title: Text(l10n?.profile ?? 'Profile')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (user?.photoURL != null)
              CircleAvatar(
                backgroundImage: NetworkImage(user!.photoURL!),
                radius: 40,
              ),
            const SizedBox(height: 10),
            Text('${l10n?.name ?? 'Name'}: ${user?.displayName ?? "N/A"}'),
            Text('${l10n?.email ?? 'Email'}: ${user?.email ?? "N/A"}'),
            Text('${l10n?.uid ?? 'UID'}: ${user?.uid ?? "N/A"}'),
            ElevatedButton(
              child: Text(l10n?.signOut ?? 'Sign Out'),
              onPressed: () async {
                await FirebaseAuth.instance.signOut();
              },
            ),
          ],
        ),
      ),
    );
  }
}
