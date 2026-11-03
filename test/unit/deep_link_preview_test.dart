import 'dart:io';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('P12-09: Telegram Web Companion Social Preview & Deep Link Meta Tags', () {
    test('index.html contains all required OpenGraph and Telegram social preview tags', () {
      final file = File('index.html');
      expect(file.existsSync(), isTrue, reason: 'index.html must exist at repo root');

      final content = file.readAsStringSync();

      // OpenGraph Protocol Meta Tags
      expect(content.contains('<meta property="og:title"'), isTrue,
          reason: 'Must contain og:title for Telegram preview cards');
      expect(content.contains('<meta property="og:description"'), isTrue,
          reason: 'Must contain og:description for rich snippet previews');
      expect(content.contains('<meta property="og:image"'), isTrue,
          reason: 'Must contain og:image for preview banner');
      expect(content.contains('<meta property="og:type" content="website"'), isTrue,
          reason: 'Must contain og:type');

      // Telegram Channel Integration & Twitter Cards
      expect(content.contains('<meta name="telegram:channel" content="@around_tashkent"'), isTrue,
          reason: 'Must declare official Tashkent Telegram channel');
      expect(content.contains('<meta name="twitter:card" content="summary_large_image"'), isTrue,
          reason: 'Must specify large image summary card');
    });

    test('index.html contains mobile viewport and web app configuration', () {
      final file = File('index.html');
      final content = file.readAsStringSync();

      expect(content.contains('name="viewport"'), isTrue);
      expect(content.contains('name="apple-mobile-web-app-capable" content="yes"'), isTrue);
      expect(content.contains('name="theme-color"'), isTrue);
    });
  });
}
