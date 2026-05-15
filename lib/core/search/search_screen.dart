import 'package:flutter/material.dart';
import 'search_engine.dart';
import 'search_result_model.dart';

/// 全局搜索页面
class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _controller = TextEditingController();
  final SearchEngine _searchEngine = SearchEngine();
  String _filterType = 'all';
  List<SearchResult> _results = [];
  bool _isSearching = false;
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _initializeSearchEngine();
  }

  /// 初始化搜索引擎并添加测试数据
  Future<void> _initializeSearchEngine() async {
    // 添加一些测试数据
    _searchEngine.addDocument(SearchResult(
      id: '1',
      title: '我的第一篇笔记',
      contentSnippet: '这是关于 Flutter 学习的心得体会...',
      type: 'note',
      createdAt: DateTime.now().subtract(const Duration(days: 2)),
      updatedAt: DateTime.now(),
    ));
    
    _searchEngine.addDocument(SearchResult(
      id: '2',
      title: '图文发布教程',
      contentSnippet: '如何使用 LiteWork 发布精美的图文内容...',
      type: 'post',
      createdAt: DateTime.now().subtract(const Duration(days: 5)),
      updatedAt: DateTime.now(),
    ));
    
    _searchEngine.addDocument(SearchResult(
      id: '3',
      title: '旅行视频项目',
      contentSnippet: '视频项目 - 3 个片段',
      type: 'video_project',
      createdAt: DateTime.now().subtract(const Duration(days: 1)),
      updatedAt: DateTime.now(),
    ));

    setState(() {
      _isInitialized = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: TextField(
          controller: _controller,
          decoration: const InputDecoration(
            hintText: '搜索笔记、图文、视频...',
            border: InputBorder.none,
          ),
          autofocus: true,
          onChanged: (value) => _performSearch(value),
        ),
        actions: [
          if (_controller.text.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.clear),
              onPressed: () {
                _controller.clear();
                setState(() {
                  _results = [];
                });
              },
            ),
        ],
      ),
      body: Column(
        children: [
          _buildFilterBar(),
          Expanded(
            child: _isSearching
                ? const Center(child: CircularProgressIndicator())
                : _results.isEmpty
                    ? _buildEmptyState()
                    : _buildResultsList(),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterBar() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          _filterChip('全部', 'all'),
          const SizedBox(width: 8),
          _filterChip('笔记', 'note'),
          const SizedBox(width: 8),
          _filterChip('图文', 'publisher'),
          const SizedBox(width: 8),
          _filterChip('视频', 'video'),
        ],
      ),
    );
  }

  Widget _filterChip(String label, String value) {
    final isSelected = _filterType == value;
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        setState(() {
          _filterType = selected ? value : 'all';
        });
        if (_controller.text.isNotEmpty) {
          _performSearch(_controller.text);
        }
      },
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.search, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            _controller.text.isEmpty ? '输入关键词开始搜索' : '未找到相关内容',
            style: TextStyle(fontSize: 16, color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }

  Widget _buildResultsList() {
    return ListView.builder(
      itemCount: _results.length,
      itemBuilder: (context, index) {
        final result = _results[index];
        return ListTile(
          leading: _getTypeIcon(result.type),
          title: Text(result.title),
          subtitle: Text(result.contentSnippet),
          trailing: Chip(
            label: Text(_getTypeLabel(result.type), style: const TextStyle(fontSize: 12, color: Colors.white)),
            backgroundColor: _getTypeColor(result.type),
            padding: EdgeInsets.zero,
          ),
          onTap: () {
            // TODO: 跳转到对应详情页
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('点击了：${result.title}')),
            );
          },
        );
      },
    );
  }

  void _performSearch(String query) {
    setState(() {
      _isSearching = true;
    });

    Future.delayed(const Duration(milliseconds: 100), () {
      setState(() {
        _isSearching = false;
        if (query.isEmpty) {
          _results = [];
        } else {
          String? typeFilter = _filterType == 'all' ? null : _filterType;
          _results = _searchEngine.search(query, typeFilter: typeFilter);
        }
      });
    });
  }

  Widget _getTypeIcon(String type) {
    switch (type) {
      case 'note':
        return const Icon(Icons.note, color: Colors.green);
      case 'post':
        return const Icon(Icons.article, color: Colors.blue);
      case 'video_project':
        return const Icon(Icons.video_library, color: Colors.orange);
      default:
        return const Icon(Icons.description);
    }
  }

  String _getTypeLabel(String type) {
    switch (type) {
      case 'note':
        return '笔记';
      case 'post':
        return '图文';
      case 'video_project':
        return '视频';
      default:
        return '其他';
    }
  }

  Color _getTypeColor(String type) {
    switch (type) {
      case 'note':
        return Colors.green;
      case 'post':
        return Colors.blue;
      case 'video_project':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}
