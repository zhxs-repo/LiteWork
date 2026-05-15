import 'package:hive/hive.dart';

/// 回收站数据源
class TrashDataSource {
  static const String _boxName = 'trash_box';
  late Box<Map> _box;

  Future<void> init() async {
    _box = await Hive.openBox<Map>(_boxName);
  }

  /// 添加到回收站
  Future<void> add(String id, Map<String, dynamic> data, String type) async {
    await _box.put(id, {
      'id': id,
      'data': data,
      'type': type,
      'deletedAt': DateTime.now().toIso8601String(),
    });
  }

  /// 获取所有回收站项目
  List<MapEntry<String, Map>> getAll() {
    return _box.entries.toList();
  }

  /// 还原项目
  Future<void> restore(String id) async {
    await _box.delete(id);
  }

  /// 彻底删除
  Future<void> deletePermanently(String id) async {
    await _box.delete(id);
  }

  /// 清空回收站
  Future<void> clear() async {
    await _box.clear();
  }

  int get count => _box.length;
}
