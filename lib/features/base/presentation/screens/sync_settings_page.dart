/// WebDAV 同步设置页面
/// 
/// 提供 WebDAV 服务器配置、测试连接和同步管理功能

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/di/injection_container.dart' as di;
import '../../../../core/network/webdav_client.dart';
import '../../../../core/network/webdav_config.dart';
import '../providers/sync_provider.dart';

/// WebDAV 同步设置页面
class SyncSettingsPage extends StatefulWidget {
  const SyncSettingsPage({Key? key}) : super(key: key);

  @override
  State<SyncSettingsPage> createState() => _SyncSettingsPageState();
}

class _SyncSettingsPageState extends State<SyncSettingsPage> {
  final _formKey = GlobalKey<FormState>();
  final _serverController = TextEditingController();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _notesDirController = TextEditingController(text: '/litework/notes');
  
  bool _obscurePassword = true;
  bool _isTesting = false;
  bool _testSuccess = false;
  String? _testMessage;
  
  @override
  void initState() {
    super.initState();
    _loadCurrentConfig();
  }
  
  void _loadCurrentConfig() {
    final client = di.sl<WebDavClient>();
    if (client.isConfigured && client.config != null) {
      final config = client.config!;
      _serverController.text = config.baseUrl;
      _usernameController.text = config.username;
      // 密码出于安全考虑不自动填充，但可以提示已保存
      _notesDirController.text = config.notesDirectory;
    }
  }
  
  Future<void> _testConnection() async {
    if (!_formKey.currentState!.validate()) return;
    
    setState(() {
      _isTesting = true;
      _testSuccess = false;
      _testMessage = null;
    });
    
    try {
      final config = WebDavConfig(
        baseUrl: _serverController.text.trim(),
        username: _usernameController.text.trim(),
        password: _passwordController.text,
        notesDirectory: _notesDirController.text.trim(),
      );
      
      final client = di.sl<WebDavClient>();
      final success = await client.testConnectionWithConfig(config);
      
      setState(() {
        _isTesting = false;
        _testSuccess = success;
        _testMessage = success 
            ? '连接成功！可以开始同步笔记。' 
            : '连接失败，请检查服务器地址、用户名和密码。';
      });
    } catch (e) {
      setState(() {
        _isTesting = false;
        _testSuccess = false;
        _testMessage = '连接错误：${e.toString()}';
      });
    }
  }
  
  Future<void> _saveConfig() async {
    if (!_formKey.currentState!.validate()) return;
    
    try {
      final config = WebDavConfig(
        baseUrl: _serverController.text.trim(),
        username: _usernameController.text.trim(),
        password: _passwordController.text,
        notesDirectory: _notesDirController.text.trim(),
      );
      
      final client = di.sl<WebDavClient>();
      await client.configure(config);
      
      // 通知 Provider 更新状态
      if (mounted) {
        context.read<SyncProvider>().checkSyncStatus();
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('WebDAV 配置已保存'),
            backgroundColor: Colors.green,
          ),
        );
        
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('保存失败：${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
  
  Future<void> _clearConfig() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('清除配置'),
        content: const Text('确定要清除 WebDAV 配置吗？这将导致无法同步笔记。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('清除'),
          ),
        ],
      ),
    );
    
    if (confirm == true && mounted) {
      try {
        final client = di.sl<WebDavClient>();
        await client.clearConfig();
        
        context.read<SyncProvider>().checkSyncStatus();
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('配置已清除'),
            backgroundColor: Colors.orange,
          ),
        );
        
        Navigator.of(context).pop(true);
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('清除失败：${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
  
  @override
  void dispose() {
    _serverController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    _notesDirController.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('云同步设置'),
        subtitle: const Text('WebDAV'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // 说明卡片
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.cloud_upload_outlined,
                          color: Theme.of(context).primaryColor,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '什么是 WebDAV？',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'WebDAV 是一种基于 HTTP 的文件传输协议，您可以使用它来同步笔记到私有云存储。\n\n'
                      '推荐的 WebDAV 服务：\n'
                      '• Nextcloud / ownCloud（自建）\n'
                      '• 坚果云（国内访问快）\n'
                      '• Seafile（高性能）\n'
                      '• Apache WebDAV 模块',
                      style: TextStyle(fontSize: 14),
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 24),
            
            // 服务器地址
            TextFormField(
              controller: _serverController,
              decoration: const InputDecoration(
                labelText: '服务器地址',
                hintText: 'https://dav.example.com',
                prefixIcon: Icon(Icons.link),
                helperText: '包含 http:// 或 https:// 的完整地址',
              ),
              keyboardType: TextInputType.url,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return '请输入服务器地址';
                }
                if (!value.trim().startsWith('http://') && 
                    !value.trim().startsWith('https://')) {
                  return '地址必须以 http:// 或 https:// 开头';
                }
                return null;
              },
            ),
            
            const SizedBox(height: 16),
            
            // 用户名
            TextFormField(
              controller: _usernameController,
              decoration: const InputDecoration(
                labelText: '用户名',
                hintText: '您的 WebDAV 用户名',
                prefixIcon: Icon(Icons.person_outline),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return '请输入用户名';
                }
                return null;
              },
            ),
            
            const SizedBox(height: 16),
            
            // 密码
            TextFormField(
              controller: _passwordController,
              obscureText: _obscurePassword,
              decoration: InputDecoration(
                labelText: '密码',
                hintText: '您的 WebDAV 密码',
                prefixIcon: const Icon(Icons.lock_outline),
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscurePassword 
                        ? Icons.visibility_outlined 
                        : Icons.visibility_off_outlined,
                  ),
                  onPressed: () {
                    setState(() {
                      _obscurePassword = !_obscurePassword;
                    });
                  },
                ),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return '请输入密码';
                }
                return null;
              },
            ),
            
            const SizedBox(height: 16),
            
            // 笔记目录（可选）
            TextFormField(
              controller: _notesDirController,
              decoration: const InputDecoration(
                labelText: '笔记存储目录',
                hintText: '/litework/notes',
                prefixIcon: Icon(Icons.folder_outlined),
                helperText: 'WebDAV 服务器上用于存储笔记的目录路径',
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return '请输入目录路径';
                }
                if (!value.trim().startsWith('/')) {
                  return '目录路径必须以 / 开头';
                }
                return null;
              },
            ),
            
            const SizedBox(height: 24),
            
            // 测试连接按钮
            if (_testMessage != null)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: _testSuccess 
                      ? Colors.green.withOpacity(0.1) 
                      : Colors.red.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(
                      _testSuccess 
                          ? Icons.check_circle_outline 
                          : Icons.error_outline,
                      color: _testSuccess ? Colors.green : Colors.red,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _testMessage!,
                        style: TextStyle(
                          color: _testSuccess ? Colors.green : Colors.red,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            
            if (_testMessage != null) const SizedBox(height: 16),
            
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _isTesting ? null : _testConnection,
                    icon: _isTesting 
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.wifi_test_outlined),
                    label: Text(_isTesting ? '测试中...' : '测试连接'),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _saveConfig,
                    icon: const Icon(Icons.save),
                    label: const Text('保存配置'),
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 24),
            
            Divider(color: Colors.grey[300]),
            
            const SizedBox(height: 16),
            
            // 危险操作区域
            ListTile(
              leading: const Icon(Icons.delete_outline, color: Colors.red),
              title: const Text(
                '清除配置',
                style: TextStyle(color: Colors.red),
              ),
              subtitle: const Text('删除已保存的 WebDAV 服务器信息'),
              onTap: _clearConfig,
            ),
          ],
        ),
      ),
    );
  }
}
