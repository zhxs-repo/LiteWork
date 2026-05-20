import '../../data/models/post_document_model.dart';

/// 帖子仓库接口
abstract class PostRepository {
  /// 获取所有帖子
  Future<List<PostDocumentModel>> getAllPosts();

  /// 根据 ID 获取帖子
  Future<PostDocumentModel?> getPostById(String id);

  /// 保存或更新帖子
  Future<void> savePost(PostDocumentModel post);

  /// 删除帖子
  Future<void> deletePost(String id);

  /// 获取草稿列表
  Future<List<PostDocumentModel>> getDrafts();

  /// 获取已发布列表
  Future<List<PostDocumentModel>> getPublished();
}
