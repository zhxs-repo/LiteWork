import 'search_result_model.dart';

/// 全局搜索引擎核心类
class SearchEngine {
  final List<SearchResult> _index = [];

  /// 添加数据到索引
  void addDocument(SearchResult doc) {
    _index.add(doc);
  }

  /// 批量添加
  void addDocuments(List<SearchResult> docs) {
    _index.addAll(docs);
  }

  /// 移除文档
  void removeDocument(String id) {
    _index.removeWhere((doc) => doc.id == id);
  }

  /// 搜索核心逻辑
  List<SearchResult> search(String query, {String? typeFilter}) {
    if (query.isEmpty) return [];

    final lowerQuery = query.toLowerCase();
    final results = <SearchResult>[];

    for (final doc in _index) {
      // 类型过滤
      if (typeFilter != null && doc.type != typeFilter) continue;

      final lowerTitle = doc.title.toLowerCase();
      final lowerContent = doc.contentSnippet.toLowerCase();

      // 标题或内容包含关键词
      if (lowerTitle.contains(lowerQuery) || lowerContent.contains(lowerQuery)) {
        results.add(doc);
      }
    }

    // 按更新时间倒序
    results.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    return results;
  }

  /// 清空索引
  void clear() {
    _index.clear();
  }

  int get count => _index.length;
}
