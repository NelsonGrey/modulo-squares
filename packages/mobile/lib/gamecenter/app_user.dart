/// The signed-in Game Center player.
class AppUser {
  const AppUser({required this.uid, this.displayName});

  final String uid;
  final String? displayName;
}
