import 'package:flutter_test/flutter_test.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:litework/core/storage/storage_manager.dart';
import 'package:litework/features/notes/domain/models.dart';

void main() {
  group('NoteRepository Tests', () {
    late StorageManager storageManager;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      storageManager = StorageManager();
      await storageManager.init();
    });

    test('should create note with correct id and timestamps', () {
      final note = NoteModel(
        id: 'test-1',
        title: 'Test Note',
        content: 'Test content',
        type: NoteType.text,
        createdAt: DateTime(2024, 1, 1),
        updatedAt: DateTime(2024, 1, 1),
        isFavorite: false,
        folderId: null,
      );

      expect(note.id, equals('test-1'));
      expect(note.title, equals('Test Note'));
      expect(note.type, equals(NoteType.text));
    });

    test('should serialize note to JSON', () {
      final note = NoteModel(
        id: 'test-2',
        title: 'JSON Test',
        content: 'Content here',
        type: NoteType.text,
        createdAt: DateTime(2024, 1, 1),
        updatedAt: DateTime(2024, 1, 1),
        isFavorite: true,
        folderId: 'folder-1',
      );

      final json = note.toJson();

      expect(json['id'], equals('test-2'));
      expect(json['title'], equals('JSON Test'));
      expect(json['isFavorite'], equals(true));
      expect(json['folderId'], equals('folder-1'));
    });

    test('should deserialize note from JSON', () {
      final jsonData = {
        'id': 'test-3',
        'title': 'From JSON',
        'content': 'Deserialized content',
        'type': 'text',
        'createdAt': '2024-01-01T00:00:00.000',
        'updatedAt': '2024-01-01T00:00:00.000',
        'isFavorite': false,
        'folderId': null,
      };

      final note = NoteModel.fromJson(jsonData);

      expect(note.id, equals('test-3'));
      expect(note.title, equals('From JSON'));
      expect(note.isFavorite, equals(false));
    });

    test('should save note to storage', () async {
      final note = NoteModel(
        id: 'save-test',
        title: 'Save Test',
        content: 'To be saved',
        type: NoteType.text,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        isFavorite: false,
        folderId: null,
      );

      final jsonStr = jsonEncode(note.toJson());
      await storageManager.save<String>('note_${note.id}', jsonStr);

      final saved = storageManager.getString('note_${note.id}');
      expect(saved, isNotNull);
      
      final restored = NoteModel.fromJson(jsonDecode(saved!) as Map<String, dynamic>);
      expect(restored.id, equals(note.id));
      expect(restored.title, equals(note.title));
    });

    test('should update note', () async {
      final note = NoteModel(
        id: 'update-test',
        title: 'Original',
        content: 'Original content',
        type: NoteType.text,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        isFavorite: false,
        folderId: null,
      );

      // Save initial
      await storageManager.save<String>('note_${note.id}', jsonEncode(note.toJson()));

      // Update
      final updatedNote = note.copyWith(
        title: 'Updated Title',
        updatedAt: DateTime.now(),
      );

      await storageManager.save<String>('note_${updatedNote.id}', jsonEncode(updatedNote.toJson()));

      final saved = storageManager.getString('note_${updatedNote.id}');
      final restored = NoteModel.fromJson(jsonDecode(saved!) as Map<String, dynamic>);
      
      expect(restored.title, equals('Updated Title'));
    });

    test('should delete note', () async {
      final note = NoteModel(
        id: 'delete-test',
        title: 'To Delete',
        content: 'Will be deleted',
        type: NoteType.text,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        isFavorite: false,
        folderId: null,
      );

      // Save then delete
      await storageManager.save<String>('note_${note.id}', jsonEncode(note.toJson()));
      await storageManager.remove('note_${note.id}');

      final saved = storageManager.getString('note_${note.id}');
      expect(saved, isNull);
    });

    test('should toggle favorite status', () {
      final note = NoteModel(
        id: 'fav-test',
        title: 'Favorite Test',
        content: 'Content',
        type: NoteType.text,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        isFavorite: false,
        folderId: null,
      );

      final toggled = note.copyWith(isFavorite: true);
      expect(toggled.isFavorite, equals(true));
    });
  });
}
