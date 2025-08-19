import 'dart:convert';
import 'dart:html' as html;

class WebStorageService {
  static const String _todosKey = 'encrypted_todos';
  static const String _passwordHashKey = 'password_hash';

  static Future<String?> getString(String key) async {
    try {
      return html.window.localStorage[key];
    } catch (e) {
      return null;
    }
  }

  static Future<void> setString(String key, String value) async {
    try {
      html.window.localStorage[key] = value;
    } catch (e) {
      // Handle storage error
      print('Storage error: $e');
    }
  }

  static Future<void> remove(String key) async {
    try {
      html.window.localStorage.remove(key);
    } catch (e) {
      // Handle storage error
      print('Storage error: $e');
    }
  }
}
