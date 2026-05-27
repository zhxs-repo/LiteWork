import 'package:hive_flutter/hive_flutter.dart';
import '../models/post_document_model.dart';

/// 帖子本地数据源 - Hive 实现
class PostLocalDataSource {
  static const String _boxName = 'posts_box';
  late Box<Map> _postsBox;

  static const String _postsKey = 'posts';

  PostLocalDataSource();

  /// 初始化数据源
  void init() {
    _postsBox = Hive.box<Map>(_boxName);
  }

  /// 获取所有帖子
  Future<List<PostDocumentModel>> getAllPosts() async {
    return _postsBox.values.map((data) {
      return PostDocumentModel.fromJson(Map<String, dynamic>.from(data));
    }).toList();
  }

  /// 根据 ID 获取帖子
  Future<PostDocumentModel?> getPostById(String id) async {
    final data = _postsBox.get(id);
    if (data == null) return null;
    return PostDocumentModel.fromJson(Map<String, dynamic>.from(data));
  }

  /// 保存或更新帖子
  Future<void> savePost(PostDocumentModel post) async {
    await _postsBox.put(post.id, Map<String, dynamic>.from(post.toJson()));
  }

  /// 删除帖子
  Future<void> deletePost(String id) async {
    await _postsBox.delete(id);
  }

  /// 获取草稿列表
  Future<List<PostDocumentModel>> getDrafts() async {
    return getAllPosts().then((posts) =>
        posts.where((p) => p.status == PostStatus.draft).toList());
  }

  /// 获取已发布列表
  Future<List<PostDocumentModel>> getPublished() async {
    return getAllPosts().then((posts) =>
        posts.where((p) => p.status == PostStatus.published).toList());
  }
}
