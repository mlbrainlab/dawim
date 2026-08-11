import 'package:flutter/widgets.dart';

const _easternArabicDigits = ['٠', '١', '٢', '٣', '٤', '٥', '٦', '٧', '٨', '٩'];

/// Renders a number in the digits the locale actually reads: Arabic-Indic
/// for Arabic, Western otherwise.
String localizedDigits(int number, Locale locale) {
  final raw = '$number';
  if (locale.languageCode != 'ar') return raw;
  return raw
      .split('')
      .map((character) {
        final digit = int.tryParse(character);
        return digit == null ? character : _easternArabicDigits[digit];
      })
      .join();
}
