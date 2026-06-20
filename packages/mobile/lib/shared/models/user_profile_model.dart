import 'package:cloud_firestore/cloud_firestore.dart';
import '../../features/auth/domain/entities/user_profile.dart';

class UserProfileModel extends UserProfile {
  const UserProfileModel({
    required super.id,
    super.displayName,
    super.email,
    super.photoUrl,
    super.highScore,
    super.gamertag,
  });

  factory UserProfileModel.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    return UserProfileModel(
      id: doc.id,
      displayName: data['displayName'] as String?,
      email: data['email'] as String?,
      photoUrl: data['photoUrl'] as String?,
      highScore: data['highScore'] as int? ?? 0,
      gamertag: data['gamertag'] as String?,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      if (displayName != null) 'displayName': displayName,
      if (email != null) 'email': email,
      if (photoUrl != null) 'photoUrl': photoUrl,
      'highScore': highScore,
      if (gamertag != null) 'gamertag': gamertag,
    };
  }
}
