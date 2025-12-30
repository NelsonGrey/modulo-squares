import 'package:flutter/services.dart';
import 'package:modulo_squares/core/services/cache_service.dart';
import 'package:modulo_squares/core/services/error_handler.dart';

/// Service for managing game assets with caching
class AssetService {
  AssetService._();
  static final AssetService instance = AssetService._();

  factory AssetService() => instance;

  /// Preload and cache commonly used assets
  Future<void> preloadAssets() async {
    try {
      // For now, this is a placeholder for when assets are added
      // Example usage:
      // final soundData = await rootBundle.load('assets/sounds/move.wav');
      // await CacheService().cacheGameAssets({'move_sound': soundData});

      // Cache asset metadata
      final assetManifest = await AssetManifest.loadFromAssetBundle(rootBundle);
      final assets = <String, dynamic>{};

      // Store asset paths for quick access
      assets['manifest'] = assetManifest.listAssets().toList();

      await CacheService().cacheGameAssets(assets);
    } catch (e) {
      ErrorHandler().logError('Preload assets', e);
    }
  }

  /// Get cached asset data
  Future<ByteData?> getCachedAsset(String assetPath) async {
    try {
      final cachedAssets = CacheService().getCachedGameAssets();
      if (cachedAssets != null && cachedAssets.containsKey(assetPath)) {
        return cachedAssets[assetPath] as ByteData?;
      }

      // Load from bundle if not cached
      final data = await rootBundle.load(assetPath);

      // Cache for future use
      final updatedCache = CacheService().getCachedGameAssets() ?? {};
      updatedCache[assetPath] = data;
      await CacheService().cacheGameAssets(updatedCache);

      return data;
    } catch (e) {
      ErrorHandler().logError('Get cached asset: $assetPath', e);
      return null;
    }
  }

  /// Check if asset is available
  Future<bool> assetExists(String assetPath) async {
    try {
      await rootBundle.load(assetPath);
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Get asset manifest from cache
  List<String>? getAssetManifest() {
    final cachedAssets = CacheService().getCachedGameAssets();
    return cachedAssets?['manifest'] as List<String>?;
  }

  /// Clear asset cache
  Future<void> clearAssetCache() async {
    await CacheService().clearAllCaches();
  }
}
