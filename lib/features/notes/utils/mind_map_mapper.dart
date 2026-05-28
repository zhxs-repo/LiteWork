import '../models.dart';

/// Mapper utility for MindMapData serialization/deserialization
class MindMapMapper {
  /// Converts Map<String, dynamic> to MindMapData object
  static MindMapData mapToMindMap(Map<String, dynamic> data) {
    return MindMapData.fromJson(data);
  }

  /// Converts MindMapData object to Map<String, dynamic>
  static Map<String, dynamic> mindMapToMap(MindMapData mindMap) {
    return mindMap.toJson();
  }
}
