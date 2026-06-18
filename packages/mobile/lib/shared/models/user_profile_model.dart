import 'package:cloud_firestore/cloud_firestore.dart';
import '../../features/auth/domain/entities/user_profile.dart'; // For mapping

class UserProfileModel extends UserProfile {
  const UserProfileModel({
    required super.id,
    super.displayName,
    super.email,
    super.photoUrl,
    super.highScore,
  });

  factory UserProfileModel.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    return UserProfileModel(
      id: doc.id,
      displayName: data['displayName'] as String?,
      email: data['email'] as String?,
      photoUrl: data['photoUrl'] as String?,
      highScore: data['highScore'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      // id is the document ID, not part of the map usually
      if (displayName != null) 'displayName': displayName,
      if (email != null) 'email': email,
      if (photoUrl != null) 'photoUrl': photoUrl,
      'highScore': highScore,
    };
  }

  // Optional: If UserProfileModel needs to be distinct from UserProfile entity
  // factory UserProfileModel.fromEntity(UserProfile entity) {
  //   return UserProfileModel(
  //     id: entity.id,
  //     displayName: entity.displayName,
  //     email: entity.email,
  //     photoUrl: entity.photoUrl,
  //     highScore: entity.highScore,
  //   );
  // }

  // UserProfile toEntity() {
  //   return UserProfile(
  //     id: id,
  //     displayName: displayName,
  //     email: email,
  //     photoUrl: photoUrl,
  //     highScore: highScore,
  //   );
  // }
}
