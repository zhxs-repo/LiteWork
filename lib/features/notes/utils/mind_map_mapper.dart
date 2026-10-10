import '../domain/models.dart';

/// Mapper utility for MindMapData serialization/deserialization
class MindMapMapper {
  /// Converts Map<String, dynamic> to MindMapData object
  static MindMapData mapToMindMap(Map<dynamic, dynamic> data) {
    return MindMapData.fromJson(Map<String, dynamic>.from(data));
  }

  /// Converts MindMapData object to Map<String, dynamic>
  static Map<String, dynamic> mindMapToMap(MindMapData mindMap) {
    return mindMap.toJson();
  }
}
