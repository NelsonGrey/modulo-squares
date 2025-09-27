import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:modulo/l10n/app_localizations.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      appBar: AppBar(title: Text(AppLocalizations.of(context).profile)),
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
            Text('${AppLocalizations.of(context).name}: ${user?.displayName ?? "N/A"}'),
            Text('${AppLocalizations.of(context).email}: ${user?.email ?? "N/A"}'),
            Text('${AppLocalizations.of(context).uid}: ${user?.uid ?? "N/A"}'),
            ElevatedButton(
              child: Text(AppLocalizations.of(context).signOut),
              onPressed: () async {
                await FirebaseAuth.instance.signOut();
              },
            )
          ],
        ),
      ),
    );
  }
}