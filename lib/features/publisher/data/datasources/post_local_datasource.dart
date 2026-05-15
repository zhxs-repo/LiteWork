import 'package:quill_delta/quill_delta.dart';
import '../../../../core/storage/storage_manager.dart';
import '../models/post_document_model.dart';

/// 帖子本地数据源
class PostLocalDataSource {
  final StorageManager _storageManager;
  static const String _postsKey = 'posts';

  PostLocalDataSource({required StorageManager storageManager})
      : _storageManager = storageManager;

  /// 获取所有帖子
  Future<List<PostDocumentModel>> getAllPosts() async {
    final postsJson = await _storageManager.get<List>(_postsKey);
    if (postsJson == null) return [];
    
    return (postsJson as List)
        .map((json) => PostDocumentModel.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  /// 根据 ID 获取帖子
  Future<PostDocumentModel?> getPostById(String id) async {
    final posts = await getAllPosts();
    try {
      return posts.firstWhere((post) => post.id == id);
    } catch (e) {
      return null;
    }
  }

  /// 保存或更新帖子
  Future<void> savePost(PostDocumentModel post) async {
    final posts = await getAllPosts();
    final index = posts.indexWhere((p) => p.id == post.id);
    
    if (index >= 0) {
      posts[index] = post;
    } else {
      posts.add(post);
    }
    
    await _storageManager.save(_postsKey, posts.map((p) => p.toJson()).toList());
  }

  /// 删除帖子
  Future<void> deletePost(String id) async {
    final posts = await getAllPosts();
    posts.removeWhere((post) => post.id == id);
    await _storageManager.save(_postsKey, posts.map((p) => p.toJson()).toList());
  }

  /// 获取草稿列表
  Future<List<PostDocumentModel>> getDrafts() async {
    final posts = await getAllPosts();
    return posts.where((p) => p.status == PostStatus.draft).toList();
  }

  /// 获取已发布列表
  Future<List<PostDocumentModel>> getPublished() async {
    final posts = await getAllPosts();
    return posts.where((p) => p.status == PostStatus.published).toList();
  }
}
