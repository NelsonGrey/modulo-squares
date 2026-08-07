import 'package:firebase_auth/firebase_auth.dart';

/// A snapshot of the live Firebase password policy, or the sensible
/// defaults used before that policy has been fetched (or if the fetch
/// fails, e.g. offline).
///
/// A `false`/unset requirement flag means the character class is not
/// enforced -- callers must not tighten these defaults themselves, or they
/// may reject passwords the server actually accepts.
class PasswordPolicyState {
  const PasswordPolicyState({
    this.minLength = 8,
    this.requiresUpper = true,
    this.requiresLower = true,
    this.requiresDigit = true,
    this.requiresSymbol = true,
  });

  final int minLength;
  final bool requiresUpper;
  final bool requiresLower;
  final bool requiresDigit;
  final bool requiresSymbol;
}

/// Centralizes password-policy logic shared by every screen that collects a
/// new password (sign-up, change-password, ...): fetching the live Firebase
/// policy, describing it to the user, a cheap client-side pre-check, and the
/// authoritative server-backed check that must gate any actual submission.
class PasswordPolicyService {
  PasswordPolicyService([this._injectedAuth]);

  final FirebaseAuth? _injectedAuth;

  // Resolved lazily (rather than in the constructor's initializer list) so
  // that constructing this service -- and calling the pure hint/quickCheck/
  // describeFailure methods below -- never requires FirebaseAuth.instance
  // to be reachable. Only loadPolicy() and checkPassword() actually read
  // this getter, and both already run inside error handling that tolerates
  // Firebase being unavailable (e.g. no app initialized yet, as in widget
  // tests that don't call Firebase.initializeApp()).
  FirebaseAuth get _auth => _injectedAuth ?? FirebaseAuth.instance;

  /// Fetches the live Firebase password policy. Falls back to
  /// [PasswordPolicyState]'s defaults on any failure (e.g. offline) --
  /// [checkPassword] still authoritatively re-verifies against the real
  /// policy regardless of whether this fetch succeeded.
  Future<PasswordPolicyState> loadPolicy() async {
    try {
      final status = await _auth.validatePassword(_auth, ' ');
      final policy = status.passwordPolicy;
      return PasswordPolicyState(
        minLength: policy.minPasswordLength,
        // A null field means Firebase doesn't enforce that character class
        // for this policy -- default to not-required, or the client would
        // reject passwords the server actually accepts.
        requiresUpper: policy.containsUppercaseCharacter ?? false,
        requiresLower: policy.containsLowercaseCharacter ?? false,
        requiresDigit: policy.containsNumericCharacter ?? false,
        requiresSymbol: policy.containsNonAlphanumericCharacter ?? false,
      );
    } catch (_) {
      return const PasswordPolicyState();
    }
  }

  /// A human-readable description of [policy], e.g. for a hint under a
  /// password field.
  String hint(PasswordPolicyState policy) {
    final requirements = <String>[
      if (policy.requiresUpper) 'uppercase letter',
      if (policy.requiresLower) 'lowercase letter',
      if (policy.requiresDigit) 'number',
      if (policy.requiresSymbol) 'special character',
    ];
    if (requirements.isEmpty) {
      return 'Password must be ${policy.minLength}+ characters.';
    }
    return 'Password must be ${policy.minLength}+ characters with '
        '${requirements.join(', ')}.';
  }

  /// Quick pass using the cached live [policy], so users get immediate
  /// feedback without a network round-trip. [checkPassword] re-validates
  /// authoritatively against Firebase itself before submitting, so this
  /// never needs to be the last word on whether a password is accepted.
  String? quickCheck(String password, PasswordPolicyState policy) {
    if (password.length < policy.minLength) {
      return 'Password must be at least ${policy.minLength} characters.';
    }
    if (policy.requiresUpper && !password.contains(RegExp(r'[A-Z]'))) {
      return 'Password must include an uppercase letter.';
    }
    if (policy.requiresLower && !password.contains(RegExp(r'[a-z]'))) {
      return 'Password must include a lowercase letter.';
    }
    if (policy.requiresDigit && !password.contains(RegExp(r'[0-9]'))) {
      return 'Password must include a number.';
    }
    if (policy.requiresSymbol && !password.contains(RegExp(r'[^A-Za-z0-9]'))) {
      return 'Password must include a special character.';
    }
    return null;
  }

  /// Authoritative check against the live Firebase policy -- catches drift
  /// between a cached [PasswordPolicyState] and the real policy (e.g. it
  /// changed after this screen loaded, or the initial fetch failed) before
  /// spending a round-trip on account creation or a password change.
  Future<PasswordValidationStatus> checkPassword(String password) =>
      _auth.validatePassword(_auth, password);

  /// Describes why [status] failed, using [policy] for the minimum-length
  /// figure (the [PasswordValidationStatus] itself doesn't carry it back).
  String describeFailure(
    PasswordValidationStatus status,
    PasswordPolicyState policy,
  ) {
    final missing = <String>[
      if (!status.meetsMinPasswordLength)
        'be at least ${policy.minLength} characters',
      if (!status.meetsUppercaseRequirement) 'include an uppercase letter',
      if (!status.meetsLowercaseRequirement) 'include a lowercase letter',
      if (!status.meetsDigitsRequirement) 'include a number',
      if (!status.meetsSymbolsRequirement) 'include a special character',
    ];
    if (missing.isEmpty) {
      return 'Password does not meet the requirements for this account.';
    }
    return 'Password must ${missing.join(', ')}.';
  }
}
