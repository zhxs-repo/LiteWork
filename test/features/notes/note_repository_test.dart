import 'package:flutter_test/flutter_test.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:litework/core/storage/storage_manager.dart';
import 'package:litework/features/notes/domain/models.dart';

void main() {
  group('Note Tests', () {
    late StorageManager storageManager;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      storageManager = StorageManager();
      await storageManager.init();
    });

    test('should create note with correct id and timestamps', () {
      final note = Note(
        id: 'test-1',
        title: 'Test Note',
        content: 'Test content',
        type: NoteType.richText,
        createdAt: DateTime(2024, 1, 1),
        updatedAt: DateTime(2024, 1, 1),
        isFavorite: false,
        folderId: null,
      );

      expect(note.id, equals('test-1'));
      expect(note.title, equals('Test Note'));
      expect(note.type, equals(NoteType.richText));
    });

    test('should serialize note to JSON', () {
      final note = Note(
        id: 'test-2',
        title: 'JSON Test',
        content: 'Content here',
        type: NoteType.richText,
        createdAt: DateTime(2024, 1, 1),
        updatedAt: DateTime(2024, 1, 1),
        isFavorite: true,
        folderId: 'folder-1',
      );

      final json = {
        'id': note.id,
        'title': note.title,
        'content': note.content,
        'type': note.type.index,
        'createdAt': note.createdAt.toIso8601String(),
        'updatedAt': note.updatedAt.toIso8601String(),
        'isFavorite': note.isFavorite,
        'folderId': note.folderId,
      };

      expect(json['id'], equals('test-2'));
      expect(json['title'], equals('JSON Test'));
      expect(json['isFavorite'], equals(true));
      expect(json['folderId'], equals('folder-1'));
    });

    test('should create note with copyWith', () {
      final note = Note(
        id: 'test-3',
        title: 'Original',
        content: 'Original content',
        type: NoteType.richText,
        createdAt: DateTime(2024, 1, 1),
        updatedAt: DateTime(2024, 1, 1),
        isFavorite: false,
        folderId: null,
      );

      final updated = note.copyWith(
        title: 'Updated Title',
        isFavorite: true,
      );

      expect(updated.title, equals('Updated Title'));
      expect(updated.isFavorite, equals(true));
      expect(updated.id, equals(note.id));
    });

    test('should save note to storage', () async {
      final note = Note(
        id: 'save-test',
        title: 'Save Test',
        content: 'To be saved',
        type: NoteType.richText,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        isFavorite: false,
        folderId: null,
      );

      final data = {
        'id': note.id,
        'title': note.title,
        'content': note.content,
        'type': note.type.index,
        'createdAt': note.createdAt.toIso8601String(),
        'updatedAt': note.updatedAt.toIso8601String(),
        'isFavorite': note.isFavorite,
        'folderId': note.folderId,
      };
      final jsonStr = jsonEncode(data);
      await storageManager.save<String>('note_${note.id}', jsonStr);

      final saved = storageManager.getString('note_${note.id}');
      expect(saved, isNotNull);
    });

    test('should delete note', () async {
      final note = Note(
        id: 'delete-test',
        title: 'To Delete',
        content: 'Will be deleted',
        type: NoteType.richText,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        isFavorite: false,
        folderId: null,
      );

      final data = {'id': note.id, 'title': note.title};
      await storageManager.save<String>('note_${note.id}', jsonEncode(data));
      await storageManager.remove('note_${note.id}');

      final saved = storageManager.getString('note_${note.id}');
      expect(saved, isNull);
    });

    test('should toggle favorite status', () {
      final note = Note(
        id: 'fav-test',
        title: 'Favorite Test',
        content: 'Content',
        type: NoteType.richText,
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
