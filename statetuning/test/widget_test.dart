import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';

import 'package:statetuning/main.dart';

void main() {
  testWidgets('App builds GetMaterialApp', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MyApp(locale: Locale('en', 'US')),
    );
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.byType(GetMaterialApp), findsOneWidget);
  });
}
