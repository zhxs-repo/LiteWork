import 'package:flutter/material.dart';

/// 全局搜索页面
class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _controller = TextEditingController();
  String _filterType = 'all';
  List<dynamic> _results = [];
  bool _isSearching = false;

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
        // TODO: 渲染实际搜索结果
        return ListTile(
          leading: const Icon(Icons.article),
          title: Text('示例结果 $index'),
          subtitle: const Text('这是搜索结果的摘要内容...'),
          trailing: Chip(
            label: const Text('笔记', style: TextStyle(fontSize: 12, color: Colors.white)),
            backgroundColor: Colors.blue,
            padding: EdgeInsets.zero,
          ),
        );
      },
    );
  }

  void _performSearch(String query) {
    setState(() {
      _isSearching = true;
    });

    // 模拟搜索延迟
    Future.delayed(const Duration(milliseconds: 300), () {
      setState(() {
        _isSearching = false;
        // TODO: 调用搜索引擎
        _results = query.isNotEmpty ? List.generate(5, (i) => i) : [];
      });
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}
