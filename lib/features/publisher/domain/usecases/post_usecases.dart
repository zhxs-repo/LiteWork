import '../models/post_document_model.dart';
import '../repositories/post_repository.dart';

/// 获取所有帖子用例
class GetAllPostsUseCase {
  final PostRepository _repository;

  GetAllPostsUseCase(this._repository);

  Future<List<PostDocumentModel>> call() => _repository.getAllPosts();
}

/// 根据 ID 获取帖子用例
class GetPostByIdUseCase {
  final PostRepository _repository;

  GetPostByIdUseCase(this._repository);

  Future<PostDocumentModel?> call(String id) => _repository.getPostById(id);
}

/// 保存帖子用例
class SavePostUseCase {
  final PostRepository _repository;

  SavePostUseCase(this._repository);

  Future<void> call(PostDocumentModel post) => _repository.savePost(post);
}

/// 删除帖子用例
class DeletePostUseCase {
  final PostRepository _repository;

  DeletePostUseCase(this._repository);

  Future<void> call(String id) => _repository.deletePost(id);
}

/// 获取草稿列表用例
class GetDraftsUseCase {
  final PostRepository _repository;

  GetDraftsUseCase(this._repository);

  Future<List<PostDocumentModel>> call() => _repository.getDrafts();
}

/// 获取已发布列表用例
class GetPublishedUseCase {
  final PostRepository _repository;

  GetPublishedUseCase(this._repository);

  Future<List<PostDocumentModel>> call() => _repository.getPublished();
}
