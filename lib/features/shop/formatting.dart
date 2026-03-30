String formatCurrency(int amount) {
  final digits = amount.toString();
  final buffer = StringBuffer();
  for (var i = 0; i < digits.length; i++) {
    final indexFromRight = digits.length - i;
    buffer.write(digits[i]);
    if (indexFromRight > 1 && indexFromRight % 3 == 1) {
      buffer.write('.');
    }
  }
  return '${buffer.toString()}đ';
}
