import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_theme.dart';
import '../providers/user_provider.dart';

/// 用户信息展示组件
class UserInfoWidget extends StatelessWidget {
  final VoidCallback? onTap;
  final bool showLogoutButton;

  const UserInfoWidget({
    super.key,
    this.onTap,
    this.showLogoutButton = false,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<UserProvider>(
      builder: (context, userProvider, child) {
        final user = userProvider.currentUser;
        final isGuest = userProvider.isGuest;

        // 安全获取用户名首字符，避免空字符串崩溃
        String getInitials(String? username) {
          if (username == null || username.isEmpty) return '用';
          return username.substring(0, 1);
        }

        return Card(
          margin: const EdgeInsets.all(16),
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  // 头像
                  CircleAvatar(
                    radius: 30,
                    backgroundColor: AppTheme.primaryColor,
                    child: Text(
                      getInitials(user?.username),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  // 用户信息
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          user?.username ?? '未知用户',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: isGuest
                                ? Colors.orange.shade100
                                : Colors.green.shade100,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            isGuest ? '游客模式' : '已登录',
                            style: TextStyle(
                              fontSize: 12,
                              color: isGuest
                                  ? Colors.orange.shade700
                                  : Colors.green.shade700,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  // 退出按钮（仅显示在设置页）
                  if (showLogoutButton && !isGuest)
                    TextButton(
                      onPressed: () => _showLogoutDialog(context, userProvider),
                      child: const Text('退出'),
                    ),
                  const Icon(Icons.chevron_right),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void _showLogoutDialog(BuildContext context, UserProvider userProvider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('确认退出'),
        content: const Text('退出后将清除当前账号信息，确定要退出吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () async {
              await userProvider.logout();
              if (context.mounted) {
                Navigator.pop(context);
              }
            },
            child: const Text('退出', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
