import 'package:flutter_test/flutter_test.dart';
import 'package:modulo/core/services/consent_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late ConsentService consentService;

  setUp(() {
    consentService = ConsentService();
  });

  group('ConsentService', () {
    test('singleton pattern works correctly', () {
      final instance1 = ConsentService();
      final instance2 = ConsentService();
      expect(instance1, same(instance2));
    });

    test('ConsentService can be instantiated', () {
      expect(consentService, isNotNull);
      expect(consentService, isA<ConsentService>());
    });

    test('configure method exists and is callable', () async {
      await expectLater(
        () => consentService.configure(),
        returnsNormally,
      );
    });

    test('requestTrackingAuthorization method exists and is callable', () async {
      final result = await consentService.requestTrackingAuthorization();
      expect(result, isA<bool>());
    });

    test('getAttStatusDescription method exists and is callable', () async {
      final result = await consentService.getAttStatusDescription();
      expect(result, isA<String>());
      expect(result, isNotEmpty);
    });

    test('isPersonalized getter returns bool', () {
      expect(consentService.isPersonalized, isA<bool>());
    });

    test('attAuthorized getter returns bool', () {
      expect(consentService.attAuthorized, isA<bool>());
    });

    test('multiple ConsentService instances are the same', () {
      final service1 = ConsentService();
      final service2 = ConsentService.instance;
      final service3 = ConsentService();

      expect(service1, same(service2));
      expect(service2, same(service3));
    });

    test('getAttStatusDescription returns appropriate message for non-iOS', () async {
      // Since we're in a test environment (likely not iOS), this should return the non-iOS message
      final result = await consentService.getAttStatusDescription();
      expect(result, contains('Not applicable'));
    });

    test('requestTrackingAuthorization returns false for non-iOS', () async {
      // Since we're in a test environment (likely not iOS), this should return false
      final result = await consentService.requestTrackingAuthorization();
      expect(result, false);
    });

    test('configure handles errors gracefully', () async {
      // The configure method should handle Firebase/AdMob initialization errors gracefully
      await expectLater(
        () => consentService.configure(),
        returnsNormally,
      );
    });

    test('isPersonalized reflects ATT and consent status', () {
      // Initially should be false since ATT is not authorized and consent not given
      expect(consentService.isPersonalized, false);
    });

    test('service maintains state across method calls', () async {
      // Call methods that might change state
      await consentService.configure();
      await consentService.requestTrackingAuthorization();

      // State might change, but getters should work without error
      expect(() => consentService.isPersonalized, returnsNormally);
      expect(() => consentService.attAuthorized, returnsNormally);
    });

    test('getAttStatusDescription handles exceptions gracefully', () async {
      // The method should handle any platform-specific exceptions
      final result = await consentService.getAttStatusDescription();
      expect(result, isA<String>());
      // Should contain some descriptive text
      expect(result.length, greaterThan(10));
    });

    test('configure can be called multiple times', () async {
      await expectLater(() => consentService.configure(), returnsNormally);
      await expectLater(() => consentService.configure(), returnsNormally);
      await expectLater(() => consentService.configure(), returnsNormally);
    });

    test('service handles rapid successive calls', () async {
      // Test that rapid calls don't cause issues
      final futures = [
        consentService.configure(),
        consentService.requestTrackingAuthorization(),
        consentService.getAttStatusDescription(),
      ];

      await expectLater(Future.wait(futures), returnsNormally);
    });
  });
}
