import 'dart:math';
import 'package:flutter/foundation.dart';

/// 工具函数集合

/// 日志打印（仅在 debug 模式）
void logDebug(String message, {String tag = 'LiteWork'}) {
  if (kDebugMode) {
    print('[$tag] $message');
  }
}

/// 格式化日期时间
String formatDateTime(DateTime dateTime, {bool showTime = true}) {
  final now = DateTime.now();
  final difference = now.difference(dateTime);
  
  if (difference.inDays == 0) {
    if (difference.inHours == 0) {
      if (difference.inMinutes == 0) {
        return '刚刚';
      }
      return '${difference.inMinutes}分钟前';
    }
    return '${difference.inHours}小时前';
  } else if (difference.inDays == 1) {
    return '昨天';
  } else if (difference.inDays < 7) {
    return '${difference.inDays}天前';
  } else {
    if (showTime) {
      return '${dateTime.year}-${_twoDigits(dateTime.month)}-${_twoDigits(dateTime.day)} '
          '${_twoDigits(dateTime.hour)}:${_twoDigits(dateTime.minute)}';
    }
    return '${dateTime.year}-${_twoDigits(dateTime.month)}-${_twoDigits(dateTime.day)}';
  }
}

String _twoDigits(int n) {
  if (n >= 10) return '$n';
  return '0$n';
}

/// 文件大小格式化
String formatFileSize(int bytes) {
  if (bytes < 0) return '0 B';
  
  const units = ['B', 'KB', 'MB', 'GB', 'TB'];
  int unitIndex = 0;
  double size = bytes.toDouble();
  
  while (size >= 1024 && unitIndex < units.length - 1) {
    size /= 1024;
    unitIndex++;
  }
  
  return '${size.toStringAsFixed(size < 10 && unitIndex > 0 ? 1 : 0)} ${units[unitIndex]}';
}

/// 生成唯一 ID
String generateUniqueId() {
  return DateTime.now().millisecondsSinceEpoch.toString() + 
         _generateRandomString(8);
}

String _generateRandomString(int length) {
  const chars = 'abcdefghijklmnopqrstuvwxyz0123456789';
  final random = Random();
  return String.fromCharCodes(
    Iterable.generate(
      length,
      (_) => chars.codeUnitAt(random.nextInt(chars.length)),
    ),
  );
}

/// 验证邮箱格式
bool isValidEmail(String email) {
  return RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email);
}

/// 验证 URL 格式
bool isValidUrl(String url) {
  return Uri.tryParse(url)?.hasScheme ?? false;
}

/// 截断文本
String truncateText(String text, int maxLength, {String suffix = '...'}) {
  if (text.length <= maxLength) return text;
  return text.substring(0, maxLength - suffix.length) + suffix;
}

/// 计算字符串字节长度（中文算 2 字节）
int getByteLength(String text) {
  int length = 0;
  for (int i = 0; i < text.length; i++) {
    length += text.codeUnitAt(i) > 255 ? 2 : 1;
  }
  return length;
}
