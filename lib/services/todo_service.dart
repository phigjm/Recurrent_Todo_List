import 'dart:convert';
import 'dart:typed_data';
import 'package:crypto/crypto.dart';
import 'package:encrypt/encrypt.dart' as enc;
import 'package:flutter/foundation.dart';
import '../models/todo.dart';
import 'storage_service.dart';

class EncryptionService {
  late final enc.Encrypter _encrypter;
  late final enc.IV _iv;

  EncryptionService._();

  static EncryptionService? _instance;
  static EncryptionService get instance {
    _instance ??= EncryptionService._();
    return _instance!;
  }

  void initialize(String password) {
    // Generate or retrieve salt
    final salt = _generateSalt();

    // Derive key from password
    final key = _deriveKey(password, salt);

    _encrypter = enc.Encrypter(enc.AES(key));
    // Derive IV from password for consistency
    _iv = _deriveIV(password, salt);
  }

  enc.Key _deriveKey(String password, Uint8List salt) {
    const int iterations = 10000;
    final passwordBytes = utf8.encode(password);

    var hash = passwordBytes + salt;
    for (int i = 0; i < iterations; i++) {
      hash = sha256.convert(hash).bytes;
    }

    return enc.Key(Uint8List.fromList(hash));
  }

  enc.IV _deriveIV(String password, Uint8List salt) {
    const int iterations = 5000;
    final passwordBytes = utf8.encode(password + 'iv');

    var hash = passwordBytes + salt;
    for (int i = 0; i < iterations; i++) {
      hash = sha256.convert(hash).bytes;
    }

    // Take first 16 bytes for IV
    return enc.IV(Uint8List.fromList(hash.take(16).toList()));
  }

  Uint8List _generateSalt() {
    // In a real app, you'd want to generate and store a unique salt
    // For simplicity, we're using a fixed salt here
    return Uint8List.fromList([
      0x12,
      0x34,
      0x56,
      0x78,
      0x9A,
      0xBC,
      0xDE,
      0xF0,
      0x12,
      0x34,
      0x56,
      0x78,
      0x9A,
      0xBC,
      0xDE,
      0xF0,
    ]);
  }

  String encrypt(String plainText) {
    final encrypted = _encrypter.encrypt(plainText, iv: _iv);
    return encrypted.base64;
  }

  String decrypt(String encryptedText) {
    final encrypted = enc.Encrypted.fromBase64(encryptedText);
    return _encrypter.decrypt(encrypted, iv: _iv);
  }
}

class TodoService {
  static const String _todosKey = 'encrypted_todos';
  static const String _passwordHashKey = 'password_hash';

  final EncryptionService _encryption = EncryptionService.instance;

  // Verify password on app start
  Future<bool> verifyPassword(String password) async {
    final storedHash = await _getStoredPasswordHash();

    if (storedHash == null) {
      // First time setup - store the password hash
      final hash = sha256.convert(utf8.encode(password)).toString();
      await _storePasswordHash(hash);
      _encryption.initialize(password);
      return true;
    }

    // Verify password
    final inputHash = sha256.convert(utf8.encode(password)).toString();
    if (inputHash == storedHash) {
      _encryption.initialize(password);
      return true;
    }

    return false;
  }

  Future<String?> _getStoredPasswordHash() async {
    return await StorageService.getString(_passwordHashKey);
  }

  Future<void> _storePasswordHash(String hash) async {
    await StorageService.setString(_passwordHashKey, hash);
  }

  Future<List<Todo>> getTodos() async {
    final encryptedData = await StorageService.getString(_todosKey);

    if (encryptedData == null || encryptedData.isEmpty) {
      return [];
    }

    try {
      final decryptedData = _encryption.decrypt(encryptedData);
      final List<dynamic> todoList = json.decode(decryptedData);

      return todoList.map((todoMap) => Todo.fromMap(todoMap)).toList();
    } catch (e) {
      // If decryption fails, return empty list
      return [];
    }
  }

  Future<void> saveTodos(List<Todo> todos) async {
    final todoMaps = todos.map((todo) => todo.toMap()).toList();
    final jsonData = json.encode(todoMaps);
    final encryptedData = _encryption.encrypt(jsonData);

    await StorageService.setString(_todosKey, encryptedData);
  }

  Future<void> addTodo(Todo todo) async {
    final todos = await getTodos();
    todos.add(todo);
    await saveTodos(todos);
  }

  Future<void> updateTodo(Todo updatedTodo) async {
    final todos = await getTodos();
    final index = todos.indexWhere((todo) => todo.id == updatedTodo.id);

    if (index != -1) {
      todos[index] = updatedTodo;
      await saveTodos(todos);
    }
  }

  Future<void> deleteTodo(String todoId) async {
    final todos = await getTodos();
    todos.removeWhere((todo) => todo.id == todoId);
    await saveTodos(todos);
  }

  Future<void> markTodoAsCompleted(String todoId, {String? note}) async {
    final todos = await getTodos();
    final index = todos.indexWhere((todo) => todo.id == todoId);

    if (index != -1) {
      final updatedTodo = todos[index].markAsCompleted(note: note);
      todos[index] = updatedTodo;
      await saveTodos(todos);
    }
  }

  Future<void> snoozeTodo(String todoId) async {
    final todos = await getTodos();
    final index = todos.indexWhere((todo) => todo.id == todoId);

    if (index != -1) {
      final updatedTodo = todos[index].snooze();
      todos[index] = updatedTodo;
      await saveTodos(todos);
    }
  }

  Future<void> hideTodo(String todoId) async {
    final todos = await getTodos();
    final index = todos.indexWhere((todo) => todo.id == todoId);

    if (index != -1) {
      final updatedTodo = todos[index].copyWith(
        isHidden: true,
        lastUpdated: DateTime.now(),
      );
      todos[index] = updatedTodo;
      await saveTodos(todos);
    }
  }

  Future<void> unhideTodo(String todoId) async {
    final todos = await getTodos();
    final index = todos.indexWhere((todo) => todo.id == todoId);

    if (index != -1) {
      final updatedTodo = todos[index].copyWith(
        isHidden: false,
        lastUpdated: DateTime.now(),
      );
      todos[index] = updatedTodo;
      await saveTodos(todos);
    }
  }

  List<Todo> getVisibleTodos(List<Todo> todos, {bool showHidden = false}) {
    if (showHidden) return todos;

    return todos.where((todo) => !todo.shouldBeHidden).toList();
  }

  List<Todo> getHiddenTodos(List<Todo> todos) {
    return todos.where((todo) => todo.shouldBeHidden).toList();
  }

  List<Todo> sortTodosByReminder(List<Todo> todos, {bool showHidden = false}) {
    final visibleTodos = showHidden ? todos : getVisibleTodos(todos);

    // Separate overdue, due today, future reminders, and no reminders
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final tomorrow = today.add(const Duration(days: 1));

    final overdueTodos = <Todo>[];
    final dueTodayTodos = <Todo>[];
    final futureTodos = <Todo>[];
    final noReminderTodos = <Todo>[];

    for (final todo in visibleTodos) {
      if (todo.isCompleted && todo.reminderType == ReminderType.none) {
        continue; // Skip completed non-recurring todos
      }

      if (todo.nextReminder == null || todo.reminderType == ReminderType.none) {
        noReminderTodos.add(todo);
      } else if (todo.nextReminder!.isBefore(today)) {
        overdueTodos.add(todo);
      } else if (todo.nextReminder!.isBefore(tomorrow)) {
        dueTodayTodos.add(todo);
      } else {
        futureTodos.add(todo);
      }
    }

    // Sort each category
    overdueTodos.sort((a, b) => a.nextReminder!.compareTo(b.nextReminder!));
    dueTodayTodos.sort((a, b) => a.nextReminder!.compareTo(b.nextReminder!));
    futureTodos.sort((a, b) => a.nextReminder!.compareTo(b.nextReminder!));
    noReminderTodos.sort((a, b) => b.createdAt.compareTo(a.createdAt));

    return [
      ...overdueTodos,
      ...dueTodayTodos,
      ...futureTodos,
      ...noReminderTodos,
    ];
  }
}
