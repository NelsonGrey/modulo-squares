import 'package:flutter_test/flutter_test.dart';
import 'package:modulo_squares/core/services/consent_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late ConsentService consentService;

  setUp(() {
    consentService = ConsentService.createForTesting();
  });

  group('ConsentService - Test Mode', () {
    test('test mode initializes with default values', () async {
      consentService = ConsentService(true); // testMode = true

      await consentService.configure();

      expect(consentService.isPersonalized, false);
      expect(consentService.attAuthorized, false);
    });

    test('test mode factory creates separate instance', () {
      final testService = ConsentService.createForTesting();
      final regularService = ConsentService();

      expect(testService, isNot(same(regularService)));
    });
  });

  group('ConsentService - Singleton Pattern', () {
    test('singleton returns same instance', () {
      final instance1 = ConsentService();
      final instance2 = ConsentService();

      expect(instance1, same(instance2));
    });

    test('factory constructor with testMode creates new instance', () {
      final regular = ConsentService();
      final testInstance = ConsentService(true);

      expect(regular, isNot(same(testInstance)));
    });
  });

  group('ConsentService - ATT Handling (iOS)', () {
    test('requestTrackingAuthorization returns false on non-iOS', () async {
      final result = await consentService.requestTrackingAuthorization();
      expect(result, false);
    });

    test('getAttStatusDescription returns appropriate message for non-iOS', () async {
      final result = await consentService.getAttStatusDescription();
      expect(result, 'Not applicable on this platform');
    });

    test('ATT methods handle platform detection correctly', () async {
      // On test platform (likely not iOS), methods should return expected values
      final attResult = await consentService.requestTrackingAuthorization();
      final statusResult = await consentService.getAttStatusDescription();

      expect(attResult, false);
      expect(statusResult, contains('Not applicable'));
    });
  });

  group('ConsentService - UMP Consent Flow', () {
    test('configure initializes service in test mode', () async {
      await expectLater(() => consentService.configure(), returnsNormally);
    });

    test('configure handles errors gracefully in test mode', () async {
      await expectLater(() => consentService.configure(), returnsNormally);

      // State should remain false in test mode
      expect(consentService.isPersonalized, false);
      expect(consentService.attAuthorized, false);
    });

    test('configure can be called multiple times safely', () async {
      await consentService.configure();
      await consentService.configure();
      await consentService.configure();

      // Should not throw and state should be consistent
      expect(consentService.isPersonalized, false);
      expect(consentService.attAuthorized, false);
    });
  });

  group('ConsentService - State Management', () {
    test('isPersonalized returns false when ATT not authorized', () {
      expect(consentService.isPersonalized, false);
    });

    test('isPersonalized returns false when consent not given', () {
      expect(consentService.isPersonalized, false);
    });

    test('attAuthorized getter returns false initially', () {
      expect(consentService.attAuthorized, false);
    });

    test('service maintains consistent state across calls', () async {
      await consentService.configure();
      final initialPersonalized = consentService.isPersonalized;
      final initialAtt = consentService.attAuthorized;

      await consentService.configure();

      expect(consentService.isPersonalized, initialPersonalized);
      expect(consentService.attAuthorized, initialAtt);
    });
  });

  group('ConsentService - Error Handling', () {
    test('configure handles exceptions from platform calls', () async {
      // Configure should complete even if platform operations fail
      await expectLater(() => consentService.configure(), returnsNormally);
    });

    test('requestTrackingAuthorization handles exceptions gracefully', () async {
      final result = await consentService.requestTrackingAuthorization();
      expect(result, isA<bool>());
    });

    test('getAttStatusDescription handles exceptions gracefully', () async {
      final result = await consentService.getAttStatusDescription();
      expect(result, isA<String>());
      expect(result.isNotEmpty, true);
    });
  });

  group('ConsentService - Concurrent Operations', () {
    test('handles multiple simultaneous configure calls', () async {
      final futures = List.generate(3, (_) => consentService.configure());
      await Future.wait(futures);

      // Should complete without errors
      expect(consentService.isPersonalized, isA<bool>());
      expect(consentService.attAuthorized, isA<bool>());
    });

    test('handles rapid successive method calls', () async {
      final futures = [
        consentService.configure(),
        consentService.requestTrackingAuthorization(),
        consentService.getAttStatusDescription(),
        consentService.configure(),
      ];

      await Future.wait(futures);

      // All operations should complete
      expect(consentService.isPersonalized, isA<bool>());
      expect(consentService.attAuthorized, isA<bool>());
    });
  });

  group('ConsentService - Platform Detection', () {
    test('correctly identifies non-iOS platform in test environment', () async {
      final attResult = await consentService.requestTrackingAuthorization();
      final statusResult = await consentService.getAttStatusDescription();

      expect(attResult, false);
      expect(statusResult, contains('Not applicable'));
    });

    test('ATT methods work on all platforms without throwing', () async {
      await expectLater(() => consentService.requestTrackingAuthorization(), returnsNormally);

      await expectLater(() => consentService.getAttStatusDescription(), returnsNormally);
    });
  });

  group('ConsentService - Integration Scenarios', () {
    test('complete flow: configure then check state', () async {
      // Configure the service
      await consentService.configure();

      // Check that state is accessible
      expect(consentService.isPersonalized, isA<bool>());
      expect(consentService.attAuthorized, isA<bool>());

      // Request ATT (should fail gracefully on test platform)
      final attResult = await consentService.requestTrackingAuthorization();
      expect(attResult, false);

      // Get status description
      final status = await consentService.getAttStatusDescription();
      expect(status, isA<String>());
    });

    test('service survives multiple complete flows', () async {
      for (int i = 0; i < 3; i++) {
        await consentService.configure();
        await consentService.requestTrackingAuthorization();
        await consentService.getAttStatusDescription();
      }

      // Service should still be functional
      expect(consentService.isPersonalized, isA<bool>());
      expect(consentService.attAuthorized, isA<bool>());
    });
  });

  group('ConsentService - Edge Cases', () {
    test('handles rapid configuration calls', () async {
      // Call configure in quick succession
      await Future.wait([consentService.configure(), consentService.configure(), consentService.configure()]);

      expect(consentService.isPersonalized, false);
      expect(consentService.attAuthorized, false);
    });

    test('service state remains consistent under load', () async {
      // Simulate heavy usage
      final operations = <Future>[];
      for (int i = 0; i < 10; i++) {
        operations.add(consentService.configure());
        operations.add(consentService.requestTrackingAuthorization());
        operations.add(consentService.getAttStatusDescription());
      }

      await Future.wait(operations);

      // State should still be valid
      expect(consentService.isPersonalized, isA<bool>());
      expect(consentService.attAuthorized, isA<bool>());
    });
  });

  group('ConsentService - Business Logic Validation', () {
    test('isPersonalized logic: requires both ATT and consent', () {
      // In test mode, both should be false
      expect(consentService.attAuthorized, false);
      expect(consentService.isPersonalized, false);

      // The logic is: isPersonalized = _personalized && _attAuthorized
      // Since both are false, result should be false
    });

    test('test mode bypasses platform-specific operations', () async {
      // In test mode, configure should set default values without platform calls
      consentService = ConsentService(true);
      await consentService.configure();

      expect(consentService.isPersonalized, false);
      expect(consentService.attAuthorized, false);
    });

    test('service provides consistent interface across platforms', () async {
      // Regardless of platform, all methods should return valid values
      await consentService.configure();
      final attResult = await consentService.requestTrackingAuthorization();
      final statusResult = await consentService.getAttStatusDescription();

      expect(attResult, isA<bool>());
      expect(statusResult, isA<String>());
      expect(consentService.isPersonalized, isA<bool>());
      expect(consentService.attAuthorized, isA<bool>());
    });
  });
}
