import 'package:hive/hive.dart';

/// 回收站数据源
class TrashDataSource {
  static const String _boxName = 'trash_box';
  late Box<Map> _box;

  Future<void> init() async {
    _box = Hive.box<Map>(_boxName);
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
    return _box.toMap().entries
        .map((e) => MapEntry(e.key.toString(), e.value as Map))
        .toList();
  }

  /// 还原项目（从回收站恢复）- 与 delete 逻辑区分
  Future<Map<String, dynamic>?> restore(String id) async {
    final data = _box.get(id);
    if (data == null) return null;
    
    // 返回数据以便调用者恢复到原始位置
    final result = {
      'id': data['id'],
      'data': data['data'],
      'type': data['type'],
      'originalPath': data['originalPath'], // 保存原始路径信息
    };
    
    // 从回收站删除
    await _box.delete(id);
    
    return result;
  }

  /// 彻底删除 - 与 restore 逻辑明确区分
  Future<void> deletePermanently(String id) async {
    // 直接删除，不保留任何数据
    await _box.delete(id);
  }

  /// 清空回收站
  Future<void> clear() async {
    await _box.clear();
  }

  int get count => _box.length;
}
