import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:litework/main.dart';

void main() {
  testWidgets('App loads successfully', (WidgetTester tester) async {
    await tester.pumpWidget(const LiteWorkApp());

    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
