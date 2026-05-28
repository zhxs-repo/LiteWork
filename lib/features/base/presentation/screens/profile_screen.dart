import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../widgets/user_info_widget.dart';
import 'theme_settings_page.dart';
import 'storage_management_page.dart';

/// 个人中心页面
class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('个人中心'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // 用户信息卡片
            const UserInfoWidget(showLogoutButton: true),
            
            const SizedBox(height: 16),
            
            // 功能列表
            _buildSection(
              context,
              title: '账号管理',
              children: [
                _buildListTile(
                  icon: Icons.person_outline,
                  title: '编辑资料',
                  subtitle: '修改昵称、头像',
                  enabled: false,
                ),
                _buildListTile(
                  icon: Icons.cloud_sync_outlined,
                  title: '云同步设置',
                  subtitle: 'WebDAV 数据同步',
                  onTap: () => context.push('/profile/sync'),
                ),
              ],
            ),
            
            _buildSection(
              context,
              title: '通用设置',
              children: [
                _buildListTile(
                  icon: Icons.palette_outlined,
                  title: '主题设置',
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const ThemeSettingsPage()),
                  ),
                ),
                _buildListTile(
                  icon: Icons.storage_outlined,
                  title: '存储管理',
                  subtitle: '清理缓存',
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const StorageManagementPage()),
                  ),
                ),
                _buildListTile(
                  icon: Icons.info_outline,
                  title: '关于我们',
                  onTap: () => _showAboutDialog(context),
                ),
              ],
            ),
            
            const SizedBox(height: 32),
            
            // 版本信息
            Text(
              'Version 1.0.0',
              style: TextStyle(
                color: Colors.grey.shade400,
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(
    BuildContext context, {
    required String title,
    required List<Widget> children,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Text(
            title,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade600,
            ),
          ),
        ),
        Card(
          margin: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(children: children),
        ),
      ],
    );
  }

  Widget _buildListTile({
    required IconData icon,
    required String title,
    String? subtitle,
    Widget? trailing,
    VoidCallback? onTap,
    bool enabled = true,
  }) {
    return ListTile(
      leading: Icon(icon, color: enabled ? Colors.blue : Colors.grey),
      title: Text(title),
      subtitle: subtitle != null ? Text(subtitle) : null,
      trailing: trailing != null
          ? trailing
          : (enabled ? const Icon(Icons.chevron_right) : null),
      onTap: enabled ? onTap : null,
    );
  }

  void _showAboutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('关于 LiteWork'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('LiteWork 是一款跨平台内容创作与管理工具。'),
            SizedBox(height: 8),
            Text('功能包括：'),
            Text('• 图文排版多平台一键发布'),
            Text('• 短视频模板化剪辑助手'),
            Text('• 富文本 + 思维导图笔记管理'),
            SizedBox(height: 8),
            Text('© 2024 LiteWork Team'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('确定'),
          ),
        ],
      ),
    );
  }
}
