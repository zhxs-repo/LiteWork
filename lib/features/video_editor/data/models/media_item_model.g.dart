// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'media_item_model.dart';

// **************************************************************************
// HiveGenerator
// **************************************************************************

class MediaItemTypeAdapter extends TypeAdapter<MediaType> {
  @override
  final int typeId = 20;

  @override
  MediaType read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0: return MediaType.video;
      case 1: return MediaType.image;
      case 2: return MediaType.audio;
      default: throw Exception('Unknown MediaType value');
    }
  }

  @override
  void write(BinaryWriter writer, MediaType obj) {
    switch (obj) {
      case MediaType.video: writer.writeByte(0); break;
      case MediaType.image: writer.writeByte(1); break;
      case MediaType.audio: writer.writeByte(2); break;
    }
  }
}

class MediaItemAdapter extends TypeAdapter<MediaItem> {
  @override
  final int typeId = 21;

  @override
  MediaItem read(BinaryReader reader) {
    return MediaItem(
      id: reader.read(0) as String,
      path: reader.read(1) as String,
      type: reader.read(2) as MediaType,
      durationMs: reader.read(3) as int? ?? 0,
      sizeBytes: reader.read(4) as int? ?? 0,
      createdAt: reader.read(5) as DateTime,
      thumbnailPath: reader.read(6) as String?,
      width: reader.read(7) as int?,
      height: reader.read(8) as int?,
    );
  }

  @override
  void write(BinaryWriter writer, MediaItem obj) {
    writer.writeString(0, obj.id);
    writer.writeString(1, obj.path);
    writer.write(2, obj.type);
    writer.writeInt(3, obj.durationMs);
    writer.writeInt(4, obj.sizeBytes);
    writer.write(5, obj.createdAt);
    if (obj.thumbnailPath != null) {
      writer.writeString(6, obj.thumbnailPath!);
    }
    if (obj.width != null) {
      writer.writeInt(7, obj.width!);
    }
    if (obj.height != null) {
      writer.writeInt(8, obj.height!);
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MediaItemAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
