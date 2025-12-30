import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:modulo_squares/core/services/error_handler.dart';

/// Cache entry with timestamp for expiration tracking
class CacheEntry {
  final dynamic data;
  final DateTime timestamp;

  CacheEntry(this.data, this.timestamp);

  /// Check if cache entry is expired
  bool isExpired(Duration maxAge) {
    return DateTime.now().difference(timestamp) > maxAge;
  }

  /// Convert to JSON for storage
  Map<String, dynamic> toJson() {
    return {
      'data': data,
      'timestamp': timestamp.toIso8601String(),
    };
  }

  /// Create from JSON
  factory CacheEntry.fromJson(Map<String, dynamic> json) {
    return CacheEntry(
      json['data'],
      DateTime.parse(json['timestamp']),
    );
  }
}

/// Intelligent caching service for app data
class CacheService {
  CacheService._();
  static final CacheService instance = CacheService._();

  factory CacheService() => instance;

  static const String _leaderboardCacheKey = 'leaderboard_cache';
  static const String _gameAssetsCacheKey = 'game_assets_cache';

  SharedPreferences? _prefs;

  /// Initialize the cache service
  Future<void> initialize() async {
    try {
      _prefs = await SharedPreferences.getInstance();
    } catch (e) {
      ErrorHandler().logError('Cache initialization', e);
    }
  }

  /// Cache leaderboard data with expiration
  Future<void> cacheLeaderboardData(List<Map<String, dynamic>> data) async {
    if (_prefs == null) return;

    try {
      final entry = CacheEntry(data, DateTime.now());
      final jsonString = jsonEncode(entry.toJson());
      await _prefs!.setString(_leaderboardCacheKey, jsonString);
    } catch (e) {
      ErrorHandler().logError('Cache leaderboard data', e);
    }
  }

  /// Get cached leaderboard data if available and not expired
  List<Map<String, dynamic>>? getCachedLeaderboardData({
    Duration maxAge = const Duration(minutes: 5),
  }) {
    if (_prefs == null) return null;

    try {
      final jsonString = _prefs!.getString(_leaderboardCacheKey);
      if (jsonString == null) return null;

      final entry = CacheEntry.fromJson(jsonDecode(jsonString));
      if (entry.isExpired(maxAge)) return null;

      return List<Map<String, dynamic>>.from(entry.data);
    } catch (e) {
      ErrorHandler().logError('Get cached leaderboard data', e);
      return null;
    }
  }

  /// Clear leaderboard cache
  Future<void> clearLeaderboardCache() async {
    if (_prefs == null) return;

    try {
      await _prefs!.remove(_leaderboardCacheKey);
    } catch (e) {
      ErrorHandler().logError('Clear leaderboard cache', e);
    }
  }

  /// Cache game assets data
  Future<void> cacheGameAssets(Map<String, dynamic> assets) async {
    if (_prefs == null) return;

    try {
      final entry = CacheEntry(assets, DateTime.now());
      final jsonString = jsonEncode(entry.toJson());
      await _prefs!.setString(_gameAssetsCacheKey, jsonString);
    } catch (e) {
      ErrorHandler().logError('Cache game assets', e);
    }
  }

  /// Get cached game assets
  Map<String, dynamic>? getCachedGameAssets({
    Duration maxAge = const Duration(hours: 24),
  }) {
    if (_prefs == null) return null;

    try {
      final jsonString = _prefs!.getString(_gameAssetsCacheKey);
      if (jsonString == null) return null;

      final entry = CacheEntry.fromJson(jsonDecode(jsonString));
      if (entry.isExpired(maxAge)) return null;

      return Map<String, dynamic>.from(entry.data);
    } catch (e) {
      ErrorHandler().logError('Get cached game assets', e);
      return null;
    }
  }

  /// Clear all caches
  Future<void> clearAllCaches() async {
    if (_prefs == null) return;

    try {
      await _prefs!.remove(_leaderboardCacheKey);
      await _prefs!.remove(_gameAssetsCacheKey);
    } catch (e) {
      ErrorHandler().logError('Clear all caches', e);
    }
  }

  /// Get cache statistics
  Map<String, dynamic> getCacheStats() {
    if (_prefs == null) return {};

    try {
      final leaderboardCache = _prefs!.getString(_leaderboardCacheKey);
      final gameAssetsCache = _prefs!.getString(_gameAssetsCacheKey);

      return {
        'leaderboard_cached': leaderboardCache != null,
        'game_assets_cached': gameAssetsCache != null,
        'cache_size_bytes': (leaderboardCache?.length ?? 0) + (gameAssetsCache?.length ?? 0),
      };
    } catch (e) {
      ErrorHandler().logError('Get cache stats', e);
      return {};
    }
  }
}
