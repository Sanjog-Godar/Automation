import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ARB Localization Parity Tests', () {
    late Map<String, dynamic> enJson;
    late Map<String, dynamic> neJson;

    setUpAll(() {
      final enFile = File('lib/l10n/app_en.arb');
      final neFile = File('lib/l10n/app_ne.arb');

      expect(enFile.existsSync(), isTrue, reason: 'app_en.arb must exist');
      expect(neFile.existsSync(), isTrue, reason: 'app_ne.arb must exist');

      enJson = jsonDecode(enFile.readAsStringSync()) as Map<String, dynamic>;
      neJson = jsonDecode(neFile.readAsStringSync()) as Map<String, dynamic>;
    });

    test('Both ARB files have @@locale defined correctly', () {
      expect(enJson['@@locale'], equals('en'));
      expect(neJson['@@locale'], equals('ne'));
    });

    test('app_en.arb and app_ne.arb have identical translation keys', () {
      // Filter out @ metadata keys from English ARB
      final enKeys = enJson.keys.where((k) => !k.startsWith('@')).toSet();
      final neKeys = neJson.keys.where((k) => !k.startsWith('@')).toSet();

      final missingInNe = enKeys.difference(neKeys);
      final missingInEn = neKeys.difference(enKeys);

      expect(
        missingInNe,
        isEmpty,
        reason: 'Keys present in app_en.arb but missing in app_ne.arb: $missingInNe',
      );
      expect(
        missingInEn,
        isEmpty,
        reason: 'Keys present in app_ne.arb but missing in app_en.arb: $missingInEn',
      );
    });

    test('All non-empty string values exist and are not blanks', () {
      final enKeys = enJson.keys.where((k) => !k.startsWith('@'));
      for (final key in enKeys) {
        final enVal = enJson[key];
        final neVal = neJson[key];

        expect(enVal, isA<String>(), reason: 'en[$key] should be a string');
        expect(neVal, isA<String>(), reason: 'ne[$key] should be a string');

        expect((enVal as String).trim(), isNotEmpty, reason: 'en[$key] should not be empty');
        expect((neVal as String).trim(), isNotEmpty, reason: 'ne[$key] should not be empty');
      }
    });

    test('Placeholder variables match between en and ne', () {
      final placeholderRegex = RegExp(r'\{([a-zA-Z0-9_]+)');
      final enKeys = enJson.keys.where((k) => !k.startsWith('@'));

      for (final key in enKeys) {
        final enVal = enJson[key] as String;
        final neVal = neJson[key] as String;

        // Skip complex ICU plural expressions that have internal plural sub-keys
        if (enVal.contains('plural,') || neVal.contains('plural,')) {
          continue;
        }

        final enPlaceholders = placeholderRegex
            .allMatches(enVal)
            .map((m) => m.group(1)!)
            .toSet();
        final nePlaceholders = placeholderRegex
            .allMatches(neVal)
            .map((m) => m.group(1)!)
            .toSet();

        expect(
          nePlaceholders,
          equals(enPlaceholders),
          reason: 'Placeholders for key "$key" do not match. EN: $enPlaceholders, NE: $nePlaceholders',
        );
      }
    });
  });
}

