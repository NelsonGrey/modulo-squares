import '../../domain/entities/user_profile.dart';
import '../../domain/repositories/profile_repository.dart';
import '../../domain/exceptions/auth_exceptions.dart';
import '../datasources/profile_remote_datasource.dart';
import '../../../../shared/models/user_profile_model.dart';

class ProfileRepositoryImpl implements ProfileRepository {
  final ProfileRemoteDataSource remoteDataSource;
  // final ProfileLocalDataSource localDataSource; // Optional: for caching

  ProfileRepositoryImpl({
    required this.remoteDataSource,
    // required this.localDataSource,
  });

  @override
  Future<UserProfile?> getUserProfile(String userId) async {
    try {
      // Optional: Check local cache first
      // final localProfile = await localDataSource.getUserProfile(userId);
      // if (localProfile != null) return localProfile.toEntity();

      final remoteProfileModel = await remoteDataSource.getUserProfile(userId);
      if (remoteProfileModel != null) {
        // Optional: Cache the fetched profile
        // await localDataSource.cacheUserProfile(remoteProfileModel);
        // If UserProfileModel is not a direct extension of UserProfile, map it:
        // return remoteProfileModel.toEntity();
        return remoteProfileModel as UserProfile; // Assuming UserProfileModel can be directly used as UserProfile
      }
      return null;
    } catch (e) {
      // Handle exceptions, map to domain-specific errors
      if (e.toString().contains('not-found') || e.toString().contains('404')) {
        throw ProfileNotFoundException('User profile not found for user: $userId');
      } else if (e.toString().contains('network') || e.toString().contains('connection')) {
        throw NetworkException('Failed to fetch user profile due to network issues');
      } else {
        throw AuthException('Failed to get user profile: ${e.toString()}');
      }
    }
  }

  @override
  Future<void> updateUserProfile(String userId, UserProfile profile) async {
    try {
      final profileModel = UserProfileModel(
          id: profile.id,
          displayName: profile.displayName,
          email: profile.email,
          photoUrl: profile.photoUrl,
          highScore: profile.highScore); // Map entity to model
      await remoteDataSource.updateUserProfile(userId, profileModel);
      // Optional: Update local cache
      // await localDataSource.cacheUserProfile(profileModel);
    } catch (e) {
      // Handle exceptions, map to domain-specific errors
      if (e.toString().contains('permission') || e.toString().contains('unauthorized')) {
        throw AuthException('Permission denied: Cannot update user profile');
      } else if (e.toString().contains('network') || e.toString().contains('connection')) {
        throw NetworkException('Failed to update user profile due to network issues');
      } else {
        throw AuthException('Failed to update user profile: ${e.toString()}');
      }
    }
  }
}
