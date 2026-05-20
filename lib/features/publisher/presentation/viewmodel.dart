/// 图文发布模块 - ViewModel (MVVM)

import 'package:flutter/foundation.dart';
import 'package:dart_quill_delta/dart_quill_delta.dart';
import '../domain/models.dart';
import '../data/models/post_document_model.dart';
import '../domain/repositories/post_repository.dart';
import '../domain/usecases/post_usecases.dart';

PublishStatus _mapPostStatusToPublishStatus(PostStatus status) {
  switch (status) {
    case PostStatus.draft:
      return PublishStatus.draft;
    case PostStatus.published:
      return PublishStatus.published;
    case PostStatus.scheduled:
      return PublishStatus.scheduled;
    case PostStatus.archived:
      return PublishStatus.failed;
  }
}

PostStatus _mapPublishStatusToPostStatus(PublishStatus status) {
  switch (status) {
    case PublishStatus.draft:
      return PostStatus.draft;
    case PublishStatus.pending:
      return PostStatus.draft;
    case PublishStatus.published:
      return PostStatus.published;
    case PublishStatus.scheduled:
      return PostStatus.scheduled;
    case PublishStatus.failed:
      return PostStatus.draft;
  }
}

/// 图文发布 ViewModel
class PublisherViewModel extends ChangeNotifier {
  final PostRepository _repository;
  late final GetAllPostsUseCase _getAllPosts;
  late final SavePostUseCase _savePost;
  late final DeletePostUseCase _deletePost;

  final List<PublishContent> _contents = [];
  bool _isLoading = false;
  String? _error;
  
  List<PublishContent> get contents => _contents;
  bool get isLoading => _isLoading;
  String? get error => _error;
  
  PublisherViewModel({required PostRepository repository})
      : _repository = repository {
    _getAllPosts = GetAllPostsUseCase(_repository);
    _savePost = SavePostUseCase(_repository);
    _deletePost = DeletePostUseCase(_repository);
  }
  
  /// 加载发布列表
  Future<void> loadContents() async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    
    try {
      final posts = await _getAllPosts();
      _contents.clear();
      _contents.addAll(posts.map((post) => PublishContent(
        id: post.id,
        title: post.title,
        content: '',
        images: [],
        status: _mapPostStatusToPublishStatus(post.status),
        createdAt: post.createdAt,
        updatedAt: post.updatedAt,
      )).toList());
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _error = e.toString();
      notifyListeners();
    }
  }
  
  /// 创建新发布
  Future<void> createContent(PublishContent content) async {
    _isLoading = true;
    notifyListeners();
    
    try {
      final post = PostDocumentModel(
        id: content.id,
        title: content.title,
        content: Delta(),
        createdAt: content.createdAt,
        updatedAt: content.updatedAt,
        status: _mapPublishStatusToPostStatus(content.status),
      );
      await _savePost(post);
      _contents.insert(0, content);
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _error = e.toString();
      notifyListeners();
    }
  }
  
  /// 更新发布
  Future<void> updateContent(PublishContent content) async {
    _isLoading = true;
    notifyListeners();
    
    try {
      final post = PostDocumentModel(
        id: content.id,
        title: content.title,
        content: Delta(),
        createdAt: content.createdAt,
        updatedAt: DateTime.now(),
        status: _mapPublishStatusToPostStatus(content.status),
      );
      await _savePost(post);
      final index = _contents.indexWhere((c) => c.id == content.id);
      if (index != -1) {
        _contents[index] = content;
      }
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _error = e.toString();
      notifyListeners();
    }
  }
  
  /// 删除发布
  Future<void> deleteContent(String id) async {
    _isLoading = true;
    notifyListeners();
    
    try {
      await _deletePost(id);
      _contents.removeWhere((c) => c.id == id);
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _error = e.toString();
      notifyListeners();
    }
  }
  
  /// 发布到指定平台
  Future<void> publishToPlatform(String contentId, PlatformType platform) async {
    _isLoading = true;
    notifyListeners();
    
    try {
      final content = _contents.firstWhere((c) => c.id == contentId);
      final updatedContent = content.copyWith(
        status: PublishStatus.published,
      );
      await updateContent(updatedContent);
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _error = e.toString();
      notifyListeners();
    }
  }
  
  /// 清空错误
  void clearError() {
    _error = null;
    notifyListeners();
  }
}
