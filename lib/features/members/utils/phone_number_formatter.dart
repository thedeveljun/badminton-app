import 'package:flutter/services.dart';

class PhoneNumberFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final numbers = newValue.text.replaceAll(RegExp(r'[^0-9]'), '');

    String formatted = '';
    if (numbers.length <= 3) {
      formatted = numbers;
    } else if (numbers.length <= 7) {
      formatted = '${numbers.substring(0, 3)}-${numbers.substring(3)}';
    } else if (numbers.length <= 11) {
      formatted =
          '${numbers.substring(0, 3)}-${numbers.substring(3, 7)}-${numbers.substring(7)}';
    } else {
      formatted =
          '${numbers.substring(0, 3)}-${numbers.substring(3, 7)}-${numbers.substring(7, 11)}';
    }

    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}
