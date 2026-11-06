import 'dart:ui';
import 'package:flutter_test/flutter_test.dart';
import 'package:vehicle_app/core/l10n/formatters.dart';

void main() {
  group('AppFormatters Unit Tests', () {
    const enLocale = Locale('en');
    const neLocale = Locale('ne');

    test('toDevanagariDigits transforms ASCII numbers to Nepali numerals', () {
      expect(AppFormatters.toDevanagariDigits('0123456789'), equals('०१२३४५६७८९'));
      expect(AppFormatters.toDevanagariDigits('2083-07-20'), equals('२०८३-०७-२०'));
      expect(AppFormatters.toDevanagariDigits('Rs. 1,200'), equals('Rs. १,२००'));
      expect(AppFormatters.toDevanagariDigits('No numbers here!'), equals('No numbers here!'));
    });

    test('formatNumber handles Indian numbering system and Devanagari conversion', () {
      expect(AppFormatters.formatNumber(1000, enLocale), equals('1,000'));
      expect(AppFormatters.formatNumber(100000, enLocale), equals('1,00,000'));
      expect(AppFormatters.formatNumber(1250000, enLocale), equals('12,50,000'));

      expect(AppFormatters.formatNumber(1000, neLocale), equals('१,०००'));
      expect(AppFormatters.formatNumber(100000, neLocale), equals('१,००,०००'));
      expect(AppFormatters.formatNumber(1250000, neLocale), equals('१२,५०,०००'));
    });

    test('formatCurrency prefixes correct symbol per locale', () {
      expect(AppFormatters.formatCurrency(1200, enLocale), equals('Rs. 1,200'));
      expect(AppFormatters.formatCurrency(-3000, enLocale), equals('Rs. -3,000'));
      expect(AppFormatters.formatCurrency(0, enLocale), equals('Rs. 0'));

      expect(AppFormatters.formatCurrency(1200, neLocale), equals('रु. १,२००'));
      expect(AppFormatters.formatCurrency(-3000, neLocale), equals('रु. -३,०००'));
      expect(AppFormatters.formatCurrency(0, neLocale), equals('रु. ०'));
    });

    test('formatUnit formats km and liters correctly in English and Nepali', () {
      expect(AppFormatters.formatUnit(15, 'km', enLocale), equals('15 km'));
      expect(AppFormatters.formatUnit(15, 'km', neLocale), equals('१५ कि.मि.'));

      expect(AppFormatters.formatUnit(45.5, 'L', enLocale), equals('45.5 L'));
      expect(AppFormatters.formatUnit(45.5, 'L', neLocale), equals('४५.५ लि.'));

      expect(AppFormatters.formatUnit(45, 'liter', enLocale, fullWord: true), equals('45 Liters'));
      expect(AppFormatters.formatUnit(1, 'liter', enLocale, fullWord: true), equals('1 Liter'));
      expect(AppFormatters.formatUnit(45, 'liter', neLocale, fullWord: true), equals('४५ लिटर'));
    });

    test('bsMonthName returns English name for EN and Devanagari for NE', () {
      expect(AppFormatters.bsMonthName(0, enLocale), equals('Baisakh'));
      expect(AppFormatters.bsMonthName(6, enLocale), equals('Kartik'));
      expect(AppFormatters.bsMonthName(11, enLocale), equals('Chaitra'));

      expect(AppFormatters.bsMonthName(0, neLocale), equals('बैशाख'));
      expect(AppFormatters.bsMonthName(6, neLocale), equals('कार्तिक'));
      expect(AppFormatters.bsMonthName(11, neLocale), equals('चैत्र'));
    });

    test('adMonthName returns English abbreviation or full for EN and Nepali transliteration for NE', () {
      expect(AppFormatters.adMonthName(10, enLocale), equals('Oct'));
      expect(AppFormatters.adMonthName(10, enLocale, full: true), equals('October'));

      expect(AppFormatters.adMonthName(10, neLocale), equals('अक्टोबर'));
    });

    test('weekdayName returns localized day abbreviations', () {
      expect(AppFormatters.weekdayName(0, enLocale), equals('Sun'));
      expect(AppFormatters.weekdayName(6, enLocale), equals('Sat'));
      expect(AppFormatters.weekdayName(0, enLocale, full: true), equals('Sunday'));

      expect(AppFormatters.weekdayName(0, neLocale), equals('आइत'));
      expect(AppFormatters.weekdayName(6, neLocale), equals('शनि'));
      expect(AppFormatters.weekdayName(0, neLocale, full: true), equals('आइतबार'));
    });

    test('formatBsDate formats full date with year, month, and day', () {
      expect(AppFormatters.formatBsDate(20, 6, 2083, enLocale), equals('20 Kartik 2083'));
      expect(AppFormatters.formatBsDate(20, 6, 2083, neLocale), equals('२० कार्तिक २०८३'));
    });

    test('formatAdDate formats Gregorian date', () {
      final date = DateTime(2026, 10, 27);
      expect(AppFormatters.formatAdDate(date, enLocale), equals('27 Oct 2026'));
      expect(AppFormatters.formatAdDate(date, neLocale), equals('२७ अक्टोबर २०२६'));
    });

    test('formatAdMonthSpan transliterates month ranges in Nepali', () {
      expect(
        AppFormatters.formatAdMonthSpan('October - November 2026', enLocale),
        equals('October - November 2026'),
      );
      expect(
        AppFormatters.formatAdMonthSpan('October - November 2026', neLocale),
        equals('अक्टोबर - नोभेम्बर २०२६'),
      );
    });
  });
}

