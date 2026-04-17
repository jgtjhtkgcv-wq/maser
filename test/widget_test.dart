// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter_test/flutter_test.dart';

import 'package:yj_converter/main.dart';

void main() {
  testWidgets('YJ Converter home page loads', (WidgetTester tester) async {
    await tester.pumpWidget(const YJConverterApp());
    await tester.pumpAndSettle();

    expect(find.text('YJ Converter'), findsOneWidget);
    expect(find.text('إضافة فيديو'), findsOneWidget);
  });
}
