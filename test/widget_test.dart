import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:melobox_app/screens/about_screen.dart';

void main() {
  testWidgets('About screen exposes the update action', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: AboutScreen()),
    );

    expect(find.text('MeloBox'), findsOneWidget);
    expect(find.byIcon(Icons.system_update_alt), findsOneWidget);
    expect(find.text('检查更新'), findsOneWidget);
  });
}
