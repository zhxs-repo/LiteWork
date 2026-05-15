/// 用户数据模型
class User {
  final String id;
  final String username;
  final String? avatar;
  final bool isGuest;
  final DateTime createdAt;

  const User({
    required this.id,
    required this.username,
    this.avatar,
    this.isGuest = true,
    required this.createdAt,
  });

  /// 创建游客用户
  factory User.guest() {
    return User(
      id: 'guest_${DateTime.now().millisecondsSinceEpoch}',
      username: '游客用户',
      isGuest: true,
      createdAt: DateTime.now(),
    );
  }

  /// 从 JSON 解析
  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] as String,
      username: json['username'] as String,
      avatar: json['avatar'] as String?,
      isGuest: json['is_guest'] as bool? ?? true,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  /// 转换为 JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'username': username,
      'avatar': avatar,
      'is_guest': isGuest,
      'created_at': createdAt.toIso8601String(),
    };
  }

  /// 复制并修改
  User copyWith({
    String? id,
    String? username,
    String? avatar,
    bool? isGuest,
    DateTime? createdAt,
  }) {
    return User(
      id: id ?? this.id,
      username: username ?? this.username,
      avatar: avatar ?? this.avatar,
      isGuest: isGuest ?? this.isGuest,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
