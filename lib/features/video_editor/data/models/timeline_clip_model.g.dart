// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'timeline_clip_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class TimelineClipAdapter extends TypeAdapter<TimelineClip> {
  @override
  final int typeId = 22;

  @override
  TimelineClip read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return TimelineClip(
      id: fields[0] as String,
      projectId: fields[1] as String,
      mediaId: fields[2] as String,
      trackIndex: fields[3] as int,
      startTimeMs: fields[4] as int,
      endTimeMs: fields[5] as int,
      durationMs: fields[6] as int,
      positionMs: fields[7] as int,
      trimStartMs: fields[8] as int,
      trimEndMs: fields[9] as int,
      speed: fields[10] as double,
      isReversed: fields[11] as bool,
      effects: (fields[12] as Map?)?.cast<String, dynamic>(),
    );
  }

  @override
  void write(BinaryWriter writer, TimelineClip obj) {
    writer
      ..writeByte(13)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.projectId)
      ..writeByte(2)
      ..write(obj.mediaId)
      ..writeByte(3)
      ..write(obj.trackIndex)
      ..writeByte(4)
      ..write(obj.startTimeMs)
      ..writeByte(5)
      ..write(obj.endTimeMs)
      ..writeByte(6)
      ..write(obj.durationMs)
      ..writeByte(7)
      ..write(obj.positionMs)
      ..writeByte(8)
      ..write(obj.trimStartMs)
      ..writeByte(9)
      ..write(obj.trimEndMs)
      ..writeByte(10)
      ..write(obj.speed)
      ..writeByte(11)
      ..write(obj.isReversed)
      ..writeByte(12)
      ..write(obj.effects);
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
