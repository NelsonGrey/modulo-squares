import 'package:firebase_auth/firebase_auth.dart';
// PasswordPolicy itself isn't re-exported by firebase_auth.dart's public
// barrel (only PasswordValidationStatus is); pull it from the platform
// interface package directly so a dummy instance can be built below.
import 'package:firebase_auth_platform_interface/firebase_auth_platform_interface.dart'
    show PasswordPolicy;
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:modulo_squares/core/auth/password_policy_service.dart';

// These tests exercise only the pure-logic pieces of PasswordPolicyService
// (hint / quickCheck / describeFailure), which don't touch FirebaseAuth.
// loadPolicy() and checkPassword() call FirebaseAuth.instance.validatePassword
// directly and aren't covered here -- there's no Firebase app available in
// the test environment (see login_screen_test.dart / falling_modulo_game_
// screen_test.dart, which follow the same convention).

// A bare Mockito mock, used only so PasswordPolicyService's constructor
// doesn't fall back to the real FirebaseAuth.instance (which throws without
// a live Firebase app). None of the methods under test here call through to
// it.
class _FakeFirebaseAuth extends Mock implements FirebaseAuth {}

void main() {
  const defaultPolicy = PasswordPolicyState();
  final service = PasswordPolicyService(_FakeFirebaseAuth());

  group('hint', () {
    test('lists every required character class plus the minimum length', () {
      expect(
        service.hint(const PasswordPolicyState(minLength: 8)),
        'Password must be 8+ characters with uppercase letter, lowercase '
        'letter, number, special character.',
      );
    });

    test('omits the character-class clause entirely when none are required', () {
      expect(
        service.hint(
          const PasswordPolicyState(
            minLength: 6,
            requiresUpper: false,
            requiresLower: false,
            requiresDigit: false,
            requiresSymbol: false,
          ),
        ),
        'Password must be 6+ characters.',
      );
    });

    test('lists only the character classes that are actually required', () {
      expect(
        service.hint(
          const PasswordPolicyState(
            minLength: 10,
            requiresUpper: true,
            requiresLower: false,
            requiresDigit: true,
            requiresSymbol: false,
          ),
        ),
        'Password must be 10+ characters with uppercase letter, number.',
      );
    });
  });

  group('quickCheck', () {
    test('rejects a password shorter than the minimum length', () {
      expect(
        service.quickCheck('Ab1!', defaultPolicy),
        'Password must be at least 8 characters.',
      );
    });

    test('rejects a password missing an uppercase letter', () {
      expect(
        service.quickCheck('abcdefg1!', defaultPolicy),
        'Password must include an uppercase letter.',
      );
    });

    test('rejects a password missing a lowercase letter', () {
      expect(
        service.quickCheck('ABCDEFG1!', defaultPolicy),
        'Password must include a lowercase letter.',
      );
    });

    test('rejects a password missing a digit', () {
      expect(
        service.quickCheck('Abcdefgh!', defaultPolicy),
        'Password must include a number.',
      );
    });

    test('rejects a password missing a special character', () {
      expect(
        service.quickCheck('Abcdefg1', defaultPolicy),
        'Password must include a special character.',
      );
    });

    test('accepts a password satisfying every requirement', () {
      expect(service.quickCheck('Abcdefg1!', defaultPolicy), isNull);
    });

    test('does not require unrequired character classes', () {
      const looserPolicy = PasswordPolicyState(
        minLength: 4,
        requiresUpper: false,
        requiresLower: false,
        requiresDigit: false,
        requiresSymbol: false,
      );
      expect(service.quickCheck('plain', looserPolicy), isNull);
    });
  });

  group('describeFailure', () {
    // PasswordValidationStatus's fields default to true (meaning "passes");
    // the second constructor arg is a required PasswordPolicy but
    // describeFailure() never reads it, so an empty one is a safe stand-in.
    PasswordValidationStatus buildStatus({
      bool meetsMinPasswordLength = true,
      bool meetsUppercaseRequirement = true,
      bool meetsLowercaseRequirement = true,
      bool meetsDigitsRequirement = true,
      bool meetsSymbolsRequirement = true,
    }) {
      final status = PasswordValidationStatus(false, PasswordPolicy({}))
        ..meetsMinPasswordLength = meetsMinPasswordLength
        ..meetsUppercaseRequirement = meetsUppercaseRequirement
        ..meetsLowercaseRequirement = meetsLowercaseRequirement
        ..meetsDigitsRequirement = meetsDigitsRequirement
        ..meetsSymbolsRequirement = meetsSymbolsRequirement;
      return status;
    }

    test('describes every failing requirement, using the policy min length', () {
      final status = buildStatus(
        meetsMinPasswordLength: false,
        meetsUppercaseRequirement: false,
      );
      expect(
        service.describeFailure(status, const PasswordPolicyState(minLength: 12)),
        'Password must be at least 12 characters, include an uppercase '
        'letter.',
      );
    });

    test('falls back to a generic message when nothing specific failed', () {
      final status = buildStatus();
      expect(
        service.describeFailure(status, defaultPolicy),
        'Password does not meet the requirements for this account.',
      );
    });
  });
}
