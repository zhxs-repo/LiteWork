// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'timeline_clip_model.dart';

// **************************************************************************
// HiveGenerator
// **************************************************************************

class TimelineClipAdapter extends TypeAdapter<TimelineClip> {
  @override
  final int typeId = 22;

  @override
  TimelineClip read(BinaryReader reader) {
    return TimelineClip(
      id: reader.read(0) as String,
      projectId: reader.read(1) as String,
      mediaId: reader.read(2) as String,
      trackIndex: reader.read(3) as int,
      startTimeMs: reader.read(4) as int,
      endTimeMs: reader.read(5) as int,
      durationMs: reader.read(6) as int,
      positionMs: reader.read(7) as int,
      trimStartMs: reader.read(8) as int? ?? 0,
      trimEndMs: reader.read(9) as int? ?? 0,
      speed: (reader.read(10) as num?)?.toDouble() ?? 1.0,
      isReversed: reader.read(11) as bool? ?? false,
      effects: reader.read(12) as Map<String, dynamic>?,
    );
  }

  @override
  void write(BinaryWriter writer, TimelineClip obj) {
    writer.writeString(0, obj.id);
    writer.writeString(1, obj.projectId);
    writer.writeString(2, obj.mediaId);
    writer.writeInt(3, obj.trackIndex);
    writer.writeInt(4, obj.startTimeMs);
    writer.writeInt(5, obj.endTimeMs);
    writer.writeInt(6, obj.durationMs);
    writer.writeInt(7, obj.positionMs);
    writer.writeInt(8, obj.trimStartMs);
    writer.writeInt(9, obj.trimEndMs);
    writer.writeDouble(10, obj.speed);
    writer.writeBool(11, obj.isReversed);
    if (obj.effects != null) {
      writer.write(12, obj.effects!);
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TimelineClipAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
