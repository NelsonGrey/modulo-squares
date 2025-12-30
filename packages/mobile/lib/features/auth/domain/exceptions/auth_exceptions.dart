/// Domain-specific exceptions for the authentication feature
class AuthException implements Exception {
  final String message;
  final String? code;

  const AuthException(this.message, {this.code});

  @override
  String toString() => 'AuthException: $message${code != null ? ' (code: $code)' : ''}';
}

class NetworkException extends AuthException {
  const NetworkException([super.message = 'Network error occurred']) : super(code: 'network_error');
}

class UserNotFoundException extends AuthException {
  const UserNotFoundException([super.message = 'User not found']) : super(code: 'user_not_found');
}

class InvalidCredentialsException extends AuthException {
  const InvalidCredentialsException([super.message = 'Invalid credentials provided']) : super(code: 'invalid_credentials');
}

class ProfileNotFoundException extends AuthException {
  const ProfileNotFoundException([super.message = 'User profile not found']) : super(code: 'profile_not_found');
}
