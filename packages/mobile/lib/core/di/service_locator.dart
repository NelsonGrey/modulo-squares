import 'package:get_it/get_it.dart';
import 'package:modulo/core/services/analytics_service.dart';
import 'package:modulo/core/services/ad_service.dart';
import 'package:modulo/core/services/consent_service.dart';
import 'package:modulo/core/services/purchase_service.dart';

/// Service locator for dependency injection
final getIt = GetIt.instance;

/// Setup all service dependencies
void setupServiceLocator() {
  // Register services as singletons
  getIt.registerLazySingleton<AnalyticsService>(() => AnalyticsService());
  getIt.registerLazySingleton<AdService>(() => AdService());
  getIt.registerLazySingleton<ConsentService>(() => ConsentService());
  getIt.registerLazySingleton<PurchaseService>(() => PurchaseService());
}
