/// Converts a rupee amount into Indian-numbering-style words, e.g.
/// 24000 -> "Twenty Four Thousand Rupees Only"
/// 123456.50 -> "One Lakh Twenty Three Thousand Four Hundred Fifty Six Rupees And Fifty Paise Only"
String numberToIndianWords(double amount) {
  final int rupees = amount.floor();
  final int paise = ((amount - rupees) * 100).round();

  final String rupeeWords = _convertWholeNumber(rupees);
  final buffer = StringBuffer();
  buffer.write(rupeeWords.isEmpty ? 'Zero' : rupeeWords);
  buffer.write(' Rupees');
  if (paise > 0) {
    buffer.write(' And ${_convertWholeNumber(paise)} Paise');
  }
  buffer.write(' Only');
  return buffer.toString();
}

const List<String> _ones = [
  '', 'One', 'Two', 'Three', 'Four', 'Five', 'Six', 'Seven', 'Eight', 'Nine',
  'Ten', 'Eleven', 'Twelve', 'Thirteen', 'Fourteen', 'Fifteen', 'Sixteen',
  'Seventeen', 'Eighteen', 'Nineteen'
];

const List<String> _tens = [
  '', '', 'Twenty', 'Thirty', 'Forty', 'Fifty', 'Sixty', 'Seventy', 'Eighty', 'Ninety'
];

String _convertTwoDigits(int n) {
  if (n < 20) return _ones[n];
  final tens = n ~/ 10;
  final ones = n % 10;
  return (_tens[tens] + (ones != 0 ? ' ${_ones[ones]}' : '')).trim();
}

String _convertThreeDigits(int n) {
  final hundreds = n ~/ 100;
  final rest = n % 100;
  final parts = <String>[];
  if (hundreds != 0) parts.add('${_ones[hundreds]} Hundred');
  if (rest != 0) parts.add(_convertTwoDigits(rest));
  return parts.join(' ');
}

/// Indian numbering: crore (10,000,000), lakh (100,000), thousand (1,000), hundred
String _convertWholeNumber(int n) {
  if (n == 0) return '';
  final parts = <String>[];

  final crore = n ~/ 10000000;
  n %= 10000000;
  final lakh = n ~/ 100000;
  n %= 100000;
  final thousand = n ~/ 1000;
  n %= 1000;
  final hundred = n;

  if (crore != 0) parts.add('${_convertThreeDigits(crore)} Crore');
  if (lakh != 0) parts.add('${_convertTwoDigits(lakh)} Lakh');
  if (thousand != 0) parts.add('${_convertTwoDigits(thousand)} Thousand');
  if (hundred != 0) parts.add(_convertThreeDigits(hundred));

  return parts.join(' ').trim();
}
