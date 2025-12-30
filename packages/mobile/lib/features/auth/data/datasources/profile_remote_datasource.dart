import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../../../../shared/models/user_profile_model.dart';

abstract class ProfileRemoteDataSource {
  Future<UserProfileModel?> getUserProfile(String userId);
  Future<void> updateUserProfile(String userId, UserProfileModel profile);
}

class ProfileRemoteDataSourceImpl implements ProfileRemoteDataSource {
  final FirebaseFirestore _firestore;

  ProfileRemoteDataSourceImpl({FirebaseFirestore? firestore}) : _firestore = firestore ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _usersCollection => _firestore.collection('users');

  @override
  Future<UserProfileModel?> getUserProfile(String userId) async {
    try {
      final docSnapshot = await _usersCollection.doc(userId).get();
      if (docSnapshot.exists) {
        return UserProfileModel.fromFirestore(docSnapshot);
      }
      return null;
    } catch (e) {
      // Log error or rethrow as a custom domain exception
      debugPrint('Error getting user profile from remote: $e');
      rethrow;
    }
  }

  @override
  Future<void> updateUserProfile(String userId, UserProfileModel profile) async {
    try {
      await _usersCollection.doc(userId).set(profile.toFirestore(), SetOptions(merge: true));
    } catch (e) {
      // Log error or rethrow
      debugPrint('Error updating user profile to remote: $e');
      rethrow;
    }
  }
}
