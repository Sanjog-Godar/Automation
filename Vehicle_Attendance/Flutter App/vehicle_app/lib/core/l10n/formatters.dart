import 'dart:ui';
import 'package:intl/intl.dart';

/// Central formatting utility providing pure, locale-aware number, currency,
/// date, unit, and calendar string representations across English (`en`) and Nepali (`ne`).
class AppFormatters {
  AppFormatters._();

  static const List<String> _nepaliDigits = [
    '०', '१', '२', '३', '४', '५', '६', '७', '८', '९',
  ];

  static const List<String> _bsMonthsNepali = [
    'बैशाख', 'जेष्ठ', 'अषाढ', 'श्रावण', 'भाद्र', 'आश्विन',
    'कार्तिक', 'मंसिर', 'पौष', 'माघ', 'फाल्गुन', 'चैत्र',
  ];

  static const List<String> _bsMonthsEnglish = [
    'Baisakh', 'Jestha', 'Ashadh', 'Shrawan', 'Bhadra', 'Ashwin',
    'Kartik', 'Mangsir', 'Poush', 'Magh', 'Falgun', 'Chaitra',
  ];

  static const List<String> _adMonthsEnglish = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
  ];

  static const List<String> _adMonthsEnglishFull = [
    'January', 'February', 'March', 'April', 'May', 'June',
    'July', 'August', 'September', 'October', 'November', 'December',
  ];

  static const List<String> _adMonthsNepali = [
    'जनवरी', 'फेब्रुअरी', 'मार्च', 'अप्रिल', 'मे', 'जुन',
    'जुलाई', 'अगस्ट', 'सेप्टेम्बर', 'अक्टोबर', 'नोभेम्बर', 'डिसेम्बर',
  ];

  static const List<String> _weekdaysNepaliShort = [
    'आइत', 'सोम', 'मंगल', 'बुध', 'बिही', 'शुक्र', 'शनि',
  ];

  static const List<String> _weekdaysNepaliFull = [
    'आइतबार', 'सोमबार', 'मंगलबार', 'बुधबार', 'बिहीबार', 'शुक्रबार', 'शनिबार',
  ];

  static const List<String> _weekdaysEnglishShort = [
    'Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat',
  ];

  static const List<String> _weekdaysEnglishFull = [
    'Sunday', 'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday',
  ];

  /// Converts any string containing ASCII digits 0-9 into Devanagari numerals ०-९.
  static String toDevanagariDigits(String input) {
    final buffer = StringBuffer();
    for (int i = 0; i < input.length; i++) {
      final code = input.codeUnitAt(i);
      if (code >= 48 && code <= 57) {
        buffer.write(_nepaliDigits[code - 48]);
      } else {
        buffer.write(input[i]);
      }
    }
    return buffer.toString();
  }

  /// Formats numbers with thousand / lakh grouping.
  /// Converts to Devanagari digits when [locale.languageCode == 'ne'].
  static String formatNumber(
    num value,
    Locale locale, {
    int? maxFractionDigits,
  }) {
    final isNepali = locale.languageCode == 'ne';
    final NumberFormat formatter;
    if (maxFractionDigits != null && maxFractionDigits > 0) {
      final pattern = '#,##,##0.${'#' * maxFractionDigits}';
      formatter = NumberFormat(pattern, 'en_IN');
    } else {
      formatter = NumberFormat('#,##,##0', 'en_IN');
    }

    final formatted = formatter.format(value).trim();
    return isNepali ? toDevanagariDigits(formatted) : formatted;
  }

  /// Formats currency amounts (`Rs. 1,200` in English, `रु. १,२००` in Nepali).
  static String formatCurrency(
    num amount,
    Locale locale, {
    bool includePrefix = true,
  }) {
    final isNepali = locale.languageCode == 'ne';
    final prefix = includePrefix ? (isNepali ? 'रु. ' : 'Rs. ') : '';
    final formattedNum = formatNumber(amount, locale);
    return '$prefix$formattedNum';
  }

  /// Formats units such as distance (`km` / `कि.मि.`) or fuel volume (`L` / `लिटर`).
  static String formatUnit(
    num value,
    String unit,
    Locale locale, {
    bool fullWord = false,
  }) {
    final isNepali = locale.languageCode == 'ne';
    final formattedValue = formatNumber(
      value,
      locale,
      maxFractionDigits: value is double && value.truncateToDouble() != value ? 2 : 0,
    );

    String localizedUnit;
    switch (unit.toLowerCase()) {
      case 'km':
        localizedUnit = isNepali ? 'कि.मि.' : 'km';
        break;
      case 'l':
      case 'liter':
      case 'liters':
        if (fullWord) {
          localizedUnit = isNepali ? 'लिटर' : (value == 1 ? 'Liter' : 'Liters');
        } else {
          localizedUnit = isNepali ? 'लि.' : 'L';
        }
        break;
      default:
        localizedUnit = unit;
    }

    return '$formattedValue $localizedUnit';
  }

  /// Returns Bikram Sambat month name (0 = Baisakh ... 11 = Chaitra).
  static String bsMonthName(int monthIndex, Locale locale) {
    final idx = monthIndex.clamp(0, 11);
    return locale.languageCode == 'ne' ? _bsMonthsNepali[idx] : _bsMonthsEnglish[idx];
  }

  /// Returns Gregorian month name (1 = Jan ... 12 = Dec).
  static String adMonthName(int monthNumber, Locale locale, {bool full = false}) {
    final idx = (monthNumber - 1).clamp(0, 11);
    if (locale.languageCode == 'ne') {
      return _adMonthsNepali[idx];
    }
    return full ? _adMonthsEnglishFull[idx] : _adMonthsEnglish[idx];
  }

  /// Returns weekday name (0 = Sun ... 6 = Sat).
  static String weekdayName(int dayIndex, Locale locale, {bool full = false}) {
    final idx = dayIndex.clamp(0, 6);
    if (locale.languageCode == 'ne') {
      return full ? _weekdaysNepaliFull[idx] : _weekdaysNepaliShort[idx];
    }
    return full ? _weekdaysEnglishFull[idx] : _weekdaysEnglishShort[idx];
  }

  /// Formats a complete Bikram Sambat date (e.g. `10 Kartik 2083` or `१० कार्तिक २०८३`).
  static String formatBsDate(int day, int monthIndex, int year, Locale locale) {
    final month = bsMonthName(monthIndex, locale);
    if (locale.languageCode == 'ne') {
      return '${toDevanagariDigits('$day')} $month ${toDevanagariDigits('$year')}';
    }
    return '$day $month $year';
  }

  /// Formats a Gregorian date (e.g. `27 Oct 2026` or `२७ अक्टोबर २०२६`).
  static String formatAdDate(DateTime date, Locale locale, {bool fullMonth = false}) {
    final month = adMonthName(date.month, locale, full: fullMonth);
    if (locale.languageCode == 'ne') {
      return '${toDevanagariDigits('${date.day}')} $month ${toDevanagariDigits('${date.year}')}';
    }
    return '${date.day} $month ${date.year}';
  }

  /// Formats the Gregorian span for a BS month (e.g. `October - November 2026` / `अक्टोबर - नोभेम्बर २०२६`).
  static String formatAdMonthSpan(String englishSpan, Locale locale) {
    if (locale.languageCode != 'ne') return englishSpan;

    // Replace English month names and digits with Nepali transliteration
    String result = englishSpan;
    for (int i = 0; i < 12; i++) {
      result = result.replaceAll(_adMonthsEnglishFull[i], _adMonthsNepali[i]);
      result = result.replaceAll(_adMonthsEnglish[i], _adMonthsNepali[i]);
    }
    return toDevanagariDigits(result);
  }
}
