import 'package:flutter/material.dart';

/// 还原确认对话框
class RestoreDialog extends StatelessWidget {
  final String itemName;

  const RestoreDialog({super.key, required this.itemName});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('还原项目'),
      content: Text('确定要将 "$itemName" 还原到原位置吗？'),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('取消'),
        ),
        TextButton(
          onPressed: () {
            Navigator.pop(context, true);
          },
          style: TextButton.styleFrom(foregroundColor: Colors.green),
          child: const Text('还原'),
        ),
      ],
    );
  }
}
