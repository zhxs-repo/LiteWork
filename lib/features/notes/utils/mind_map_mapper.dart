import '../models.dart';

/// Mapper utility for MindMapData serialization/deserialization
class MindMapMapper {
  /// Converts Map<String, dynamic> to MindMapData object
  static MindMapData mapToMindMap(Map<String, dynamic> data) {
    return MindMapData(
      nodes: (data['nodes'] as List)
          .map((node) => MindMapNode.fromJson(node))
          .toList(),
      connections: (data['connections'] as List)
          .map((conn) => MindMapConnection.fromJson(conn))
          .toList(),
      layout: MindMapLayout.values.firstWhere(
        (e) => e.name == data['layout'],
        orElse: () => MindMapLayout.right,
      ),
    );
  }

  /// Converts MindMapData object to Map<String, dynamic>
  static Map<String, dynamic> mindMapToMap(MindMapData mindMap) {
    return {
      'nodes': mindMap.nodes.map((node) => node.toJson()).toList(),
      'connections':
          mindMap.connections.map((conn) => conn.toJson()).toList(),
      'layout': mindMap.layout.name,
    };
  }
}
