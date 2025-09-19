import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/api_models.dart';

class CacheService {
  static const String _keyPrefix = 'speech_to_email_';
  static const String _recordingHistoryKey = '${_keyPrefix}recording_history';
  static const String _appConfigKey = '${_keyPrefix}app_config';
  static const String _userPreferencesKey = '${_keyPrefix}user_preferences';

  static SharedPreferences? _prefs;

  /// Initialize the cache service
  static Future<void> initialize() async {
    _prefs ??= await SharedPreferences.getInstance();
  }

  /// Get SharedPreferences instance
  static Future<SharedPreferences> get _preferences async {
    return _prefs ??= await SharedPreferences.getInstance();
  }

  /// Cache recording history
  static Future<void> cacheRecordingHistory(List<RecordingHistoryItem> history) async {
    try {
      final prefs = await _preferences;
      final jsonList = history.map((item) => {
        'recordId': item.recordId,
        'status': item.status.toString(),
        'createdAt': item.createdAt.toIso8601String(),
        'transcriptionText': item.transcriptionText,
        'errorMessage': item.errorMessage,
      }).toList();
      
      await prefs.setString(_recordingHistoryKey, jsonEncode(jsonList));
      debugPrint('Cached ${history.length} recording history items');
    } catch (e) {
      debugPrint('Error caching recording history: $e');
    }
  }

  /// Get cached recording history
  static Future<List<RecordingHistoryItem>> getCachedRecordingHistory() async {
    try {
      final prefs = await _preferences;
      final jsonString = prefs.getString(_recordingHistoryKey);
      
      if (jsonString == null) return [];
      
      final jsonList = jsonDecode(jsonString) as List;
      return jsonList.map((json) => RecordingHistoryItem(
        recordId: json['recordId'] as String,
        status: _parseProcessingStatus(json['status'] as String),
        createdAt: DateTime.parse(json['createdAt'] as String),
        transcriptionText: json['transcriptionText'] as String?,
        errorMessage: json['errorMessage'] as String?,
      )).toList();
    } catch (e) {
      debugPrint('Error loading cached recording history: $e');
      return [];
    }
  }

  /// Cache app configuration
  static Future<void> cacheAppConfig(Map<String, dynamic> config) async {
    try {
      final prefs = await _preferences;
      await prefs.setString(_appConfigKey, jsonEncode(config));
    } catch (e) {
      debugPrint('Error caching app config: $e');
    }
  }

  /// Get cached app configuration
  static Future<Map<String, dynamic>?> getCachedAppConfig() async {
    try {
      final prefs = await _preferences;
      final jsonString = prefs.getString(_appConfigKey);
      
      if (jsonString == null) return null;
      
      return jsonDecode(jsonString) as Map<String, dynamic>;
    } catch (e) {
      debugPrint('Error loading cached app config: $e');
      return null;
    }
  }

  /// Cache user preferences
  static Future<void> cacheUserPreferences(Map<String, dynamic> preferences) async {
    try {
      final prefs = await _preferences;
      await prefs.setString(_userPreferencesKey, jsonEncode(preferences));
    } catch (e) {
      debugPrint('Error caching user preferences: $e');
    }
  }

  /// Get cached user preferences
  static Future<Map<String, dynamic>> getCachedUserPreferences() async {
    try {
      final prefs = await _preferences;
      final jsonString = prefs.getString(_userPreferencesKey);
      
      if (jsonString == null) return {};
      
      return jsonDecode(jsonString) as Map<String, dynamic>;
    } catch (e) {
      debugPrint('Error loading cached user preferences: $e');
      return {};
    }
  }

  /// Cache API response with TTL
  static Future<void> cacheApiResponse(String key, Map<String, dynamic> data, {Duration? ttl}) async {
    try {
      final prefs = await _preferences;
      final cacheData = {
        'data': data,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
        'ttl': ttl?.inMilliseconds,
      };
      
      await prefs.setString('${_keyPrefix}api_$key', jsonEncode(cacheData));
    } catch (e) {
      debugPrint('Error caching API response: $e');
    }
  }

  /// Get cached API response
  static Future<Map<String, dynamic>?> getCachedApiResponse(String key) async {
    try {
      final prefs = await _preferences;
      final jsonString = prefs.getString('${_keyPrefix}api_$key');
      
      if (jsonString == null) return null;
      
      final cacheData = jsonDecode(jsonString) as Map<String, dynamic>;
      final timestamp = cacheData['timestamp'] as int;
      final ttl = cacheData['ttl'] as int?;
      
      // Check if cache is expired
      if (ttl != null) {
        final expiryTime = timestamp + ttl;
        if (DateTime.now().millisecondsSinceEpoch > expiryTime) {
          await clearCachedApiResponse(key);
          return null;
        }
      }
      
      return cacheData['data'] as Map<String, dynamic>;
    } catch (e) {
      debugPrint('Error loading cached API response: $e');
      return null;
    }
  }

  /// Clear specific cached API response
  static Future<void> clearCachedApiResponse(String key) async {
    try {
      final prefs = await _preferences;
      await prefs.remove('${_keyPrefix}api_$key');
    } catch (e) {
      debugPrint('Error clearing cached API response: $e');
    }
  }

  /// Clear all cached data
  static Future<void> clearAllCache() async {
    try {
      final prefs = await _preferences;
      final keys = prefs.getKeys().where((key) => key.startsWith(_keyPrefix));
      
      for (final key in keys) {
        await prefs.remove(key);
      }
      
      debugPrint('Cleared all cached data');
    } catch (e) {
      debugPrint('Error clearing cache: $e');
    }
  }

  /// Get cache size (approximate)
  static Future<int> getCacheSize() async {
    try {
      final prefs = await _preferences;
      final keys = prefs.getKeys().where((key) => key.startsWith(_keyPrefix));
      
      int totalSize = 0;
      for (final key in keys) {
        final value = prefs.getString(key);
        if (value != null) {
          totalSize += value.length;
        }
      }
      
      return totalSize;
    } catch (e) {
      debugPrint('Error calculating cache size: $e');
      return 0;
    }
  }

  /// Helper method to parse ProcessingStatus from string
  static ProcessingStatus _parseProcessingStatus(String status) {
    switch (status.toLowerCase()) {
      case 'processingstatus.uploaded':
        return ProcessingStatus.uploaded;
      case 'processingstatus.transcribing':
        return ProcessingStatus.transcribing;
      case 'processingstatus.transcriptioncompleted':
        return ProcessingStatus.transcriptionCompleted;
      case 'processingstatus.emailsent':
        return ProcessingStatus.emailSent;
      case 'processingstatus.failed':
        return ProcessingStatus.failed;
      default:
        return ProcessingStatus.failed;
    }
  }
}