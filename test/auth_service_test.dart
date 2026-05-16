import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../../data/services/auth_service.dart';

@GenerateMocks([http.Client, FlutterSecureStorage])
void main() {
  group('AuthService Tests', () {
    late AuthService authService;
    late MockClient mockClient;
    late MockFlutterSecureStorage mockStorage;

    setUp(() {
      mockClient = MockClient();
      mockStorage = MockFlutterSecureStorage();
      authService = AuthService(
        client: mockClient,
        storage: mockStorage,
      );
    });

    test('login should succeed with valid credentials', () async {
      // Arrange
      final mockResponse = http.Response(
        '{"access_token": "test_token", "refresh_token": "test_refresh", "user_id": "123"}',
        200,
      );
      when(mockClient.post(any, body: anyNamed('body'), headers: anyNamed('headers')))
          .thenAnswer((_) async => mockResponse);
      when(mockStorage.write(key: anyNamed('key'), value: anyNamed('value')))
          .thenAnswer((_) async => {});

      // Act
      final result = await authService.login('test@example.com', 'password123');

      // Assert
      expect(result.accessToken, 'test_token');
      expect(result.refreshToken, 'test_refresh');
      expect(result.userId, '123');
      verify(mockStorage.write(key: 'auth_token', value: 'test_token')).called(1);
    });

    test('login should throw AuthException with invalid credentials', () async {
      // Arrange
      final mockResponse = http.Response('{"error": "Invalid credentials"}', 401);
      when(mockClient.post(any, body: anyNamed('body'), headers: anyNamed('headers')))
          .thenAnswer((_) async => mockResponse);

      // Act & Assert
      expect(
        () => authService.login('test@example.com', 'wrong_password'),
        throwsA(isA<AuthException>()),
      );
    });

    test('register should succeed with valid data', () async {
      // Arrange
      final mockResponse = http.Response(
        '{"access_token": "test_token", "refresh_token": "test_refresh", "user_id": "123"}',
        201,
      );
      when(mockClient.post(any, body: anyNamed('body'), headers: anyNamed('headers')))
          .thenAnswer((_) async => mockResponse);
      when(mockStorage.write(key: anyNamed('key'), value: anyNamed('value')))
          .thenAnswer((_) async => {});

      // Act
      final result = await authService.register('test@example.com', 'password123', 'TestUser');

      // Assert
      expect(result.accessToken, 'test_token');
      verify(mockStorage.write(key: 'auth_token', value: 'test_token')).called(1);
    });

    test('isLoggedIn should return true when token exists', () async {
      // Arrange
      when(mockStorage.read(key: 'auth_token')).thenAnswer((_) async => 'valid_token');

      // Act
      final result = await authService.isLoggedIn();

      // Assert
      expect(result, isTrue);
    });

    test('isLoggedIn should return false when token does not exist', () async {
      // Arrange
      when(mockStorage.read(key: 'auth_token')).thenAnswer((_) async => null);

      // Act
      final result = await authService.isLoggedIn();

      // Assert
      expect(result, isFalse);
    });

    test('logout should clear all tokens', () async {
      // Arrange
      when(mockStorage.read(key: 'auth_token')).thenAnswer((_) async => 'valid_token');
      when(mockClient.post(any, headers: anyNamed('headers'))).thenAnswer((_) async => http.Response('', 200));
      when(mockStorage.delete(key: anyNamed('key'))).thenAnswer((_) async => {});

      // Act
      await authService.logout();

      // Assert
      verify(mockStorage.delete(key: 'auth_token')).called(1);
      verify(mockStorage.delete(key: 'refresh_token')).called(1);
      verify(mockStorage.delete(key: 'user_id')).called(1);
    });
  });
}
