import '../datasources/post_local_datasource.dart';
import '../models/post_document_model.dart';
import '../../domain/repositories/post_repository.dart';

/// 帖子仓库实现
class PostRepositoryImpl implements PostRepository {
  final PostLocalDataSource _localDataSource;

  PostRepositoryImpl({required PostLocalDataSource localDataSource})
      : _localDataSource = localDataSource;

  @override
  Future<List<PostDocumentModel>> getAllPosts() {
    return _localDataSource.getAllPosts();
  }

  @override
  Future<PostDocumentModel?> getPostById(String id) {
    return _localDataSource.getPostById(id);
  }

  @override
  Future<void> savePost(PostDocumentModel post) {
    return _localDataSource.savePost(post);
  }

  @override
  Future<void> deletePost(String id) {
    return _localDataSource.deletePost(id);
  }

  @override
  Future<List<PostDocumentModel>> getDrafts() {
    return _localDataSource.getDrafts();
  }

  @override
  Future<List<PostDocumentModel>> getPublished() {
    return _localDataSource.getPublished();
  }
}
