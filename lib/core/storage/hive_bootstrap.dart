import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../utils/common_utils.dart';

/// Hive 初始化
///
/// 原实现 `Hive.initFlutter()` 会把 box 直接写到「用户文档目录」(Documents)，
/// 与用户的个人文件混在一起。这里改为写入应用私有目录：
///
/// - Windows: `%APPDATA%\com.example\litework\hive`
/// - macOS:   `~/Library/Application Support/com.example.litework/hive`
/// - Linux:   `~/.local/share/<company>/<product>/hive`
/// - Android: `/data/user/0/<package>/files/hive`
/// - iOS:     `Library/Application Support/hive`
///
/// 用户文档目录仍由 `media_utils.dart`、`mind_map_editor_screen.dart`
/// 使用（`media_imports` / `Default Project`），不受本文件影响。
///
/// 必须在任何 `Hive.openBox` 之前调用。
Future<String?> initHive() async {
  // Web 端 Hive 使用 IndexedDB，无需（也不能）指定文件路径
  if (kIsWeb) return null;

  final supportDir = await getApplicationSupportDirectory();
  final hiveDir = Directory(p.join(supportDir.path, 'hive'));
  await hiveDir.create(recursive: true);

  Hive.init(hiveDir.path);
  logDebug('Hive 数据目录：${hiveDir.path}');
  return hiveDir.path;
}
