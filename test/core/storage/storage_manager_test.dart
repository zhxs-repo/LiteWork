import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:litework/core/storage/storage_manager.dart';

@GenerateMocks([SharedPreferences])
void main() {
  group('StorageManager Tests', () {
    late StorageManager storageManager;
    late SharedPreferences sharedPreferences;

    setUp(() async {
      // 使用真实的 SharedPreferences 实例进行测试
      SharedPreferences.setMockInitialValues({});
      sharedPreferences = await SharedPreferences.getInstance();
      storageManager = StorageManager();
      await storageManager.init();
    });

    test('should save and retrieve string value', () async {
      const key = 'test_string';
      const value = 'Hello World';

      await storageManager.save<String>(key, value);
      final result = storageManager.get<String>(key);

      expect(result, equals(value));
    });

    test('should save and retrieve int value', () async {
      const key = 'test_int';
      const value = 42;

      await storageManager.save<int>(key, value);
      final result = storageManager.get<int>(key);

      expect(result, equals(value));
    });

    test('should save and retrieve bool value', () async {
      const key = 'test_bool';
      const value = true;

      await storageManager.save<bool>(key, value);
      final result = storageManager.get<bool>(key);

      expect(result, equals(value));
    });

    test('should save and retrieve double value', () async {
      const key = 'test_double';
      const value = 3.14;

      await storageManager.save<double>(key, value);
      final result = storageManager.get<double>(key);

      expect(result, equals(value));
    });

    test('should save and retrieve string list', () async {
      const key = 'test_list';
      const value = ['item1', 'item2', 'item3'];

      await storageManager.save<List<String>>(key, value);
      final result = storageManager.get<List<String>>(key);

      expect(result, equals(value));
    });

    test('should return defaultValue when key not found', () async {
      const key = 'nonexistent_key';
      const defaultValue = 'default';

      final result = storageManager.get<String>(key, defaultValue: defaultValue);

      expect(result, equals(defaultValue));
    });

    test('should remove key', () async {
      const key = 'to_remove';
      const value = 'value';

      await storageManager.save<String>(key, value);
      await storageManager.remove(key);
      final result = storageManager.get<String>(key);

      expect(result, isNull);
    });

    test('should clear all data', () async {
      await storageManager.save<String>('key1', 'value1');
      await storageManager.save<int>('key2', 100);

      await storageManager.clear();

      expect(storageManager.get<String>('key1'), isNull);
      expect(storageManager.get<int>('key2'), isNull);
    });

    test('should check if key exists', () async {
      const key = 'exists_key';
      await storageManager.save<String>(key, 'value');

      expect(storageManager.containsKey(key), isTrue);
      expect(storageManager.containsKey('nonexistent'), isFalse);
    });

    test('should serialize and deserialize complex object', () async {
      const key = 'complex_object';
      final data = {'name': 'Test', 'count': 5, 'active': true};

      await storageManager.save<Map<String, dynamic>>(key, data);
      final result = storageManager.get<Map<String, dynamic>>(key);

      expect(result?['name'], equals('Test'));
      expect(result?['count'], equals(5));
      expect(result?['active'], equals(true));
    });
  });
}
