import 'package:flutter/material.dart';

class AvatarWidget extends StatelessWidget {
  final String? photoURL;

  const AvatarWidget({super.key, this.photoURL});

  @override
  Widget build(BuildContext context) {
    return CircleAvatar(
      radius: 40,
      backgroundImage: photoURL != null ? NetworkImage(photoURL!) : null,
      child: photoURL == null ? const Icon(Icons.person, size: 40) : null,
    );
  }
}
