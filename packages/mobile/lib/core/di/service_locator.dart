import 'package:get_it/get_it.dart';
import 'package:modulo_squares/core/services/ad_service.dart';
import 'package:modulo_squares/core/services/consent_service.dart';
import 'package:modulo_squares/core/services/purchase_service.dart';
import 'package:modulo_squares/gamecenter/game_center_services.dart';

/// Service locator for dependency injection
final getIt = GetIt.instance;

/// Setup all service dependencies
void setupServiceLocator() {
  // Register services as singletons
  getIt.registerLazySingleton<AdService>(() => AdService());
  getIt.registerLazySingleton<ConsentService>(() => ConsentService());
  getIt.registerLazySingleton<PurchaseService>(() => PurchaseService());
  getIt.registerLazySingleton<GameCenterServices>(() => GameCenterServices());
}
