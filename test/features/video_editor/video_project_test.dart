import 'package:flutter_test/flutter_test.dart';

import 'package:litework/features/video_editor/domain/models.dart';

void main() {
  group('VideoProject Model Tests', () {
    test('should create VideoProject with correct properties', () {
      final project = VideoProject(
        id: 'proj-1',
        title: 'Test Project',
        clips: [],
        createdAt: DateTime(2024, 1, 1),
        updatedAt: DateTime(2024, 1, 1),
        status: ProjectStatus.draft,
      );

      expect(project.id, equals('proj-1'));
      expect(project.title, equals('Test Project'));
      expect(project.clips, isEmpty);
      expect(project.status, equals(ProjectStatus.draft));
    });

    test('should create VideoProject with clips', () {
      final project = VideoProject(
        id: 'proj-2',
        title: 'Clip Test',
        clips: [
          VideoClip(
            id: 'clip-1',
            sourcePath: '/path/to/video.mp4',
            duration: const Duration(seconds: 30),
            startTime: const Duration(seconds: 0),
            endTime: const Duration(seconds: 30),
          ),
        ],
        createdAt: DateTime(2024, 1, 1),
        updatedAt: DateTime(2024, 1, 1),
        status: ProjectStatus.completed,
      );

      expect(project.clips.length, equals(1));
      expect(project.clips.first.sourcePath, equals('/path/to/video.mp4'));
      expect(project.status, equals(ProjectStatus.completed));
    });

    test('should copyWith VideoProject', () {
      final project = VideoProject(
        id: 'proj-3',
        title: 'Original',
        clips: [],
        createdAt: DateTime(2024, 1, 1),
        updatedAt: DateTime(2024, 1, 1),
        status: ProjectStatus.draft,
      );

      final updated = project.copyWith(
        title: 'Updated Title',
        status: ProjectStatus.completed,
      );

      expect(updated.title, equals('Updated Title'));
      expect(updated.status, equals(ProjectStatus.completed));
      expect(updated.id, equals(project.id));
    });

    test('should create VideoClip with correct properties', () {
      final clip = VideoClip(
        id: 'clip-1',
        sourcePath: '/path/to/video.mp4',
        duration: const Duration(seconds: 30),
        startTime: const Duration(seconds: 0),
        endTime: const Duration(seconds: 30),
        volume: 1.0,
        effects: [],
      );

      expect(clip.id, equals('clip-1'));
      expect(clip.sourcePath, equals('/path/to/video.mp4'));
      expect(clip.duration, equals(const Duration(seconds: 30)));
    });

    test('should create VideoEffect', () {
      final effect = VideoEffect(
        type: EffectType.filter,
        parameters: {'intensity': 0.5},
      );

      expect(effect.type, equals(EffectType.filter));
      expect(effect.parameters['intensity'], equals(0.5));
    });

    test('should have all ProjectStatus values', () {
      expect(ProjectStatus.values.length, equals(5));
      expect(ProjectStatus.draft.name, equals('draft'));
      expect(ProjectStatus.editing.name, equals('editing'));
      expect(ProjectStatus.rendering.name, equals('rendering'));
      expect(ProjectStatus.completed.name, equals('completed'));
      expect(ProjectStatus.failed.name, equals('failed'));
    });
  });
}
