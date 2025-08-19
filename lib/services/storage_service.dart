import 'package:flutter/foundation.dart';

// Simple storage service that works for both web and mobile
class StorageService {
  static const String _storagePrefix = 'private_todo_';

  // Simple in-memory storage for web fallback
  static final Map<String, String> _memoryStorage = {};

  static Future<String?> getString(String key) async {
    if (kIsWeb) {
      // For web, use a simple in-memory storage
      return _memoryStorage[_storagePrefix + key];
    } else {
      // For mobile, we'll use shared_preferences (handled elsewhere)
      return _memoryStorage[_storagePrefix + key];
    }
  }

  static Future<void> setString(String key, String value) async {
    if (kIsWeb) {
      // For web, use in-memory storage
      _memoryStorage[_storagePrefix + key] = value;
    } else {
      // For mobile, use in-memory storage as fallback
      _memoryStorage[_storagePrefix + key] = value;
    }
  }

  static Future<void> remove(String key) async {
    if (kIsWeb) {
      _memoryStorage.remove(_storagePrefix + key);
    } else {
      _memoryStorage.remove(_storagePrefix + key);
    }
  }
}
