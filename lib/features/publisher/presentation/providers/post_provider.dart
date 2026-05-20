import 'package:flutter/foundation.dart';
import 'package:dart_quill_delta/dart_quill_delta.dart';
import '../../domain/usecases/post_usecases.dart';
import '../../data/models/post_document_model.dart';

/// 帖子编辑器状态
enum EditorState {
  idle,
  loading,
  saving,
  saved,
  error,
}

/// 帖子 Provider (ViewModel)
class PostProvider extends ChangeNotifier {
  final GetAllPostsUseCase _getAllPosts;
  final GetPostByIdUseCase _getPostById;
  final SavePostUseCase _savePost;
  final DeletePostUseCase _deletePost;
  final GetDraftsUseCase _getDrafts;

  List<PostDocumentModel> _posts = [];
  PostDocumentModel? _currentPost;
  EditorState _state = EditorState.idle;
  String? _errorMessage;

  PostProvider({
    required GetAllPostsUseCase getAllPosts,
    required GetPostByIdUseCase getPostById,
    required SavePostUseCase savePost,
    required DeletePostUseCase deletePost,
    required GetDraftsUseCase getDrafts,
  })  : _getAllPosts = getAllPosts,
        _getPostById = getPostById,
        _savePost = savePost,
        _deletePost = deletePost,
        _getDrafts = getDrafts;

  // Getters
  List<PostDocumentModel> get posts => _posts;
  PostDocumentModel? get currentPost => _currentPost;
  EditorState get state => _state;
  String? get errorMessage => _errorMessage;
  List<PostDocumentModel> get drafts =>
      _posts.where((p) => p.status == PostStatus.draft).toList();
  List<PostDocumentModel> get published =>
      _posts.where((p) => p.status == PostStatus.published).toList();

  /// 加载所有帖子
  Future<void> loadPosts() async {
    try {
      _state = EditorState.loading;
      notifyListeners();

      _posts = await _getAllPosts();
      _state = EditorState.idle;
      notifyListeners();
    } catch (e) {
      _state = EditorState.error;
      _errorMessage = e.toString();
      notifyListeners();
    }
  }

  /// 创建新帖子
  void createPost({String title = '新草稿'}) {
    final now = DateTime.now();
    _currentPost = PostDocumentModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: title,
      content: Delta(), // 空内容
      createdAt: now,
      updatedAt: now,
      status: PostStatus.draft,
    );
    notifyListeners();
  }

  /// 加载指定帖子进行编辑
  Future<void> loadPost(String id) async {
    try {
      _state = EditorState.loading;
      notifyListeners();

      _currentPost = await _getPostById(id);
      _state = EditorState.idle;
      notifyListeners();
    } catch (e) {
      _state = EditorState.error;
      _errorMessage = e.toString();
      notifyListeners();
    }
  }

  /// 更新当前编辑的帖子内容
  void updateContent(Delta content) {
    if (_currentPost != null) {
      _currentPost = _currentPost!.copyWith(
        content: content,
        updatedAt: DateTime.now(),
      );
      notifyListeners();
    }
  }

  /// 更新标题
  void updateTitle(String title) {
    if (_currentPost != null) {
      _currentPost = _currentPost!.copyWith(
        title: title,
        updatedAt: DateTime.now(),
      );
      notifyListeners();
    }
  }

  /// 自动保存草稿
  Future<void> autoSave() async {
    if (_currentPost == null) return;

    try {
      _state = EditorState.saving;
      notifyListeners();

      await _savePost(_currentPost!);
      
      // 更新本地列表
      final index = _posts.indexWhere((p) => p.id == _currentPost!.id);
      if (index >= 0) {
        _posts[index] = _currentPost!;
      } else {
        _posts.add(_currentPost!);
      }

      _state = EditorState.saved;
      notifyListeners();

      // 重置状态
      Future.delayed(const Duration(seconds: 1), () {
        if (_state == EditorState.saved) {
          _state = EditorState.idle;
          notifyListeners();
        }
      });
    } catch (e) {
      _state = EditorState.error;
      _errorMessage = '保存失败：${e.toString()}';
      notifyListeners();
    }
  }

  /// 删除帖子
  Future<void> deletePost(String id) async {
    try {
      await _deletePost(id);
      _posts.removeWhere((p) => p.id == id);
      if (_currentPost?.id == id) {
        _currentPost = null;
      }
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
    }
  }

  /// 发布帖子
  Future<void> publishPost() async {
    if (_currentPost == null) return;

    try {
      _state = EditorState.saving;
      notifyListeners();

      final publishedPost = _currentPost!.copyWith(
        status: PostStatus.published,
        updatedAt: DateTime.now(),
      );

      await _savePost(publishedPost);
      _currentPost = publishedPost;

      // 更新本地列表
      final index = _posts.indexWhere((p) => p.id == publishedPost.id);
      if (index >= 0) {
        _posts[index] = publishedPost;
      }

      _state = EditorState.saved;
      notifyListeners();
    } catch (e) {
      _state = EditorState.error;
      _errorMessage = e.toString();
      notifyListeners();
    }
  }

  /// 清空当前编辑
  void clearCurrent() {
    _currentPost = null;
    notifyListeners();
  }
}
