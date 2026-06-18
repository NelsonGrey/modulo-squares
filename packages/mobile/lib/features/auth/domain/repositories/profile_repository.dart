// Example: /Users/marknelson/Circus/Repositories/modulo_flutter_project/lib/src/features/profile/domain/repositories/profile_repository.dart
import '../entities/user_profile.dart'; // Or use the model directly if entities are skipped

abstract class ProfileRepository {
  Future<UserProfile?> getUserProfile(String userId); // UserProfile could be UserProfileModel
  Future<void> updateUserProfile(String userId, UserProfile profile);
}
