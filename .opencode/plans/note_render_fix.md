# 修复方案：笔记页面渲染失败

## 问题描述
错误信息：`HiveError: The box "notes_box" is already open and of type Box<dynamic>`

## 根因分析
`main.dart` 第33-38行已经以 `Box<dynamic>` 类型打开了所有需要的 Hive box：
```dart
await Future.wait([
  Hive.openBox('posts_box'),
  Hive.openBox('notes_box'),        // <-- 以 Box<dynamic> 打开
  Hive.openBox('video_projects_box'),
  Hive.openBox('trash_box'),
  Hive.openBox('folders_box'),
  Hive.openBox('onboarding_box'),
]);
```

但 `NotesDataSource.init()` (第11-14行) 又尝试以 `Box<Map>` 类型重新打开同一个 box：
```dart
Future<void> init() async {
  _notesBox = await Hive.openBox<Map>(StorageKeys.notesBox);  // <-- 类型冲突！
  _foldersBox = await Hive.openBox<Map>(StorageKeys.foldersBox);  // <-- 类型冲突！
}
```

Hive 不允许同一个 box 以不同类型重复打开，导致初始化失败，页面渲染失败。

## 修复方法

### 文件 1: `lib/features/notes/data/note_datasource.dart`

将 `init()` 方法中的 `Hive.openBox()` 改为 `Hive.box()`（获取已打开的 box）：

```dart
// 修改前
Future<void> init() async {
  _notesBox = await Hive.openBox<Map>(StorageKeys.notesBox);
  _foldersBox = await Hive.openBox<Map>(StorageKeys.foldersBox);
}

// 修改后
Future<void> init() async {
  _notesBox = Hive.box<Map>(StorageKeys.notesBox);
  _foldersBox = Hive.box<Map>(StorageKeys.foldersBox);
}
```

### 文件 2: `lib/features/notes/data/datasources/trash_datasource.dart`

同样修复 `trash_box` 的问题：

```dart
// 修改前
Future<void> init() async {
  _box = await Hive.openBox<Map>(_boxName);
}

// 修改后
Future<void> init() async {
  _box = Hive.box<Map>(_boxName);
}
```

### 文件 3: `lib/features/video_editor/data/datasources/video_local_datasource.dart`

同样修复 video editor 相关的 box：

```dart
// 修改前
_projectBox = await Hive.openBox<Map>(projectBoxName);
_mediaBox = await Hive.openBox<Map>(mediaBoxName);
_clipsBox = await Hive.openBox<Map>(clipsBoxName);

// 修改后
_projectBox = Hive.box<Map>(projectBoxName);
_mediaBox = Hive.box<Map>(mediaBoxName);
_clipsBox = Hive.box<Map>(clipsBoxName);
```

## 验证
修复后运行 `flutter run` 验证笔记页面是否正常渲染。
