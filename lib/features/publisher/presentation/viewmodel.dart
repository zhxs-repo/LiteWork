/// 图文发布模块 - ViewModel (MVVM)

import 'package:flutter/foundation.dart';
import '../domain/models.dart';
import '../domain/repositories/post_repository.dart';
import '../domain/usecases/post_usecases.dart';

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
      // 从数据层加载数据
      final posts = await _getAllPosts();
      _contents.clear();
      _contents.addAll(posts.map((post) => PublishContent(
        id: post.id,
        title: post.title,
        content: post.content,
        images: post.images,
        status: post.status,
        platforms: post.platforms,
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
      // 保存到数据层
      final post = PostDocumentModel(
        id: content.id,
        title: content.title,
        content: content.content,
        images: content.images,
        status: content.status,
        platforms: content.platforms,
        createdAt: content.createdAt,
        updatedAt: content.updatedAt,
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
      // 更新数据层
      final post = PostDocumentModel(
        id: content.id,
        title: content.title,
        content: content.content,
        images: content.images,
        status: content.status,
        platforms: content.platforms,
        createdAt: content.createdAt,
        updatedAt: DateTime.now(),
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
      // 从数据层删除
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
      // 实现平台发布逻辑
      final content = _contents.firstWhere((c) => c.id == contentId);
      final updatedContent = content.copyWith(
        status: PostStatus.published,
        platforms: [...content.platforms, platform],
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
