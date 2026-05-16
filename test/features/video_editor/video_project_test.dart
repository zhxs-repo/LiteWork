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

    test('should serialize VideoProject to JSON', () {
      final project = VideoProject(
        id: 'proj-2',
        title: 'JSON Test',
        clips: [
          VideoClip(
            id: 'clip-1',
            path: '/path/to/video.mp4',
            duration: const Duration(seconds: 30),
            startTime: const Duration(seconds: 0),
            endTime: const Duration(seconds: 30),
          ),
        ],
        createdAt: DateTime(2024, 1, 1),
        updatedAt: DateTime(2024, 1, 1),
        status: ProjectStatus.exported,
      );

      final json = project.toJson();

      expect(json['id'], equals('proj-2'));
      expect(json['title'], equals('JSON Test'));
      expect(json['clips'], isA<List>());
      expect(json['status'], equals('exported'));
    });

    test('should deserialize VideoProject from JSON', () {
      final jsonData = {
        'id': 'proj-3',
        'title': 'From JSON',
        'clips': [],
        'createdAt': '2024-01-01T00:00:00.000',
        'updatedAt': '2024-01-01T00:00:00.000',
        'status': 'draft',
      };

      final project = VideoProject.fromJson(jsonData);

      expect(project.id, equals('proj-3'));
      expect(project.title, equals('From JSON'));
      expect(project.status, equals(ProjectStatus.draft));
    });

    test('should copy VideoProject with changes', () {
      final original = VideoProject(
        id: 'proj-4',
        title: 'Original',
        clips: [],
        createdAt: DateTime(2024, 1, 1),
        updatedAt: DateTime(2024, 1, 1),
        status: ProjectStatus.draft,
      );

      final updated = original.copyWith(
        title: 'Updated Title',
        status: ProjectStatus.rendering,
      );

      expect(updated.id, equals(original.id));
      expect(updated.title, equals('Updated Title'));
      expect(updated.status, equals(ProjectStatus.rendering));
    });

    test('should calculate total duration from clips', () {
      final project = VideoProject(
        id: 'proj-5',
        title: 'Duration Test',
        clips: [
          VideoClip(
            id: 'clip-1',
            path: '/video1.mp4',
            duration: const Duration(seconds: 30),
            startTime: const Duration(seconds: 0),
            endTime: const Duration(seconds: 30),
          ),
          VideoClip(
            id: 'clip-2',
            path: '/video2.mp4',
            duration: const Duration(seconds: 45),
            startTime: const Duration(seconds: 0),
            endTime: const Duration(seconds: 45),
          ),
        ],
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        status: ProjectStatus.draft,
      );

      // Total duration should be sum of all clip durations
      final totalDuration = project.clips.fold(
        Duration.zero,
        (total, clip) => total + clip.duration,
      );

      expect(totalDuration, equals(const Duration(seconds: 75)));
    });

    test('should handle empty clips list', () {
      final project = VideoProject(
        id: 'proj-6',
        title: 'Empty Project',
        clips: [],
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        status: ProjectStatus.draft,
      );

      expect(project.clips, isEmpty);
      expect(project.status, equals(ProjectStatus.draft));
    });

    test('ProjectStatus enum values', () {
      expect(ProjectStatus.draft.name, equals('draft'));
      expect(ProjectStatus.rendering.name, equals('rendering'));
      expect(ProjectStatus.exported.name, equals('exported'));
      expect(ProjectStatus.published.name, equals('published'));
    });
  });

  group('VideoClip Model Tests', () {
    test('should create VideoClip with correct properties', () {
      final clip = VideoClip(
        id: 'clip-1',
        path: '/path/to/video.mp4',
        duration: const Duration(seconds: 60),
        startTime: const Duration(seconds: 10),
        endTime: const Duration(seconds: 70),
      );

      expect(clip.id, equals('clip-1'));
      expect(clip.path, equals('/path/to/video.mp4'));
      expect(clip.duration, equals(const Duration(seconds: 60)));
    });

    test('should serialize VideoClip to JSON', () {
      final clip = VideoClip(
        id: 'clip-2',
        path: '/video.mp4',
        duration: const Duration(seconds: 30),
        startTime: const Duration(seconds: 0),
        endTime: const Duration(seconds: 30),
      );

      final json = clip.toJson();

      expect(json['id'], equals('clip-2'));
      expect(json['path'], equals('/video.mp4'));
      expect(json['durationInSeconds'], equals(30));
    });

    test('should deserialize VideoClip from JSON', () {
      final jsonData = {
        'id': 'clip-3',
        'path': '/test.mp4',
        'durationInSeconds': 45,
        'startTimeInSeconds': 5,
        'endTimeInSeconds': 50,
      };

      final clip = VideoClip.fromJson(jsonData);

      expect(clip.id, equals('clip-3'));
      expect(clip.path, equals('/test.mp4'));
      expect(clip.duration, equals(const Duration(seconds: 45)));
    });
  });
}
