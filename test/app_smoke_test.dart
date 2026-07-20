import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:melobox_app/providers/site_provider.dart';
import 'package:melobox_app/utils/helpers.dart';
import 'package:melobox_app/utils/theme.dart';

void main() {
  testWidgets('AppTheme builds a themed MaterialApp', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        home: const Scaffold(body: Text('ok')),
      ),
    );

    expect(find.byType(MaterialApp), findsOneWidget);
    expect(Theme.of(tester.element(find.byType(Scaffold))).colorScheme.primary, isNotNull);
  });

  test('MediaUrlHelper keeps absolute media urls unchanged', () {
    expect(
      MediaUrlHelper.resolveMediaUrl(
        'https://img.example.com/poster.jpg',
        'https://api.example.com/api.php/provide/vod/',
      ),
      'https://img.example.com/poster.jpg',
    );
  });

  test('MediaUrlHelper resolves root-relative media urls against api origin', () {
    expect(
      MediaUrlHelper.resolveMediaUrl(
        '/upload/poster.jpg',
        'https://api.example.com/api.php/provide/vod/',
      ),
      'https://api.example.com/upload/poster.jpg',
    );
  });

  test('MediaUrlHelper resolves path-relative media urls against api directory', () {
    expect(
      MediaUrlHelper.resolveMediaUrl(
        'poster.jpg',
        'https://api.example.com/api.php/provide/vod/',
      ),
      'https://api.example.com/api.php/provide/vod/poster.jpg',
    );
  });

  test('SiteProvider normalizes out-of-range video source indexes', () {
    expect(SiteProvider.normalizeVideoIndex(52, 43), 0);
  });

  test('SiteProvider keeps valid video source indexes', () {
    expect(SiteProvider.normalizeVideoIndex(3, 43), 3);
  });
}
