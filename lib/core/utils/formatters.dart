abstract final class AppFormatters {
  static int moneyDisplayAmount(int amount) {
    final int absolute = amount.abs();
    if (absolute == 0) {
      return 0;
    }
    if (absolute < 1000) {
      return amount * 1000;
    }
    return amount;
  }

  static String moneyK(int amount) {
    final int normalized = moneyDisplayAmount(amount);
    final String sign = normalized < 0 ? '-' : '';
    final String digits = normalized.abs().toString();
    final StringBuffer formatted = StringBuffer();

    for (int index = 0; index < digits.length; index++) {
      if (index > 0 && (digits.length - index) % 3 == 0) {
        formatted.write(' ');
      }
      formatted.write(digits[index]);
    }

    return '$sign${formatted.toString()} UZS';
  }

  static String shortDate(DateTime date) {
    const List<String> months = <String>[
      'Yan',
      'Fev',
      'Mar',
      'Apr',
      'May',
      'Iyn',
      'Iyl',
      'Avg',
      'Sen',
      'Okt',
      'Noy',
      'Dek',
    ];
    return '${date.day.toString().padLeft(2, '0')} ${months[date.month - 1]}';
  }

  static String dateTime(DateTime dateTime) {
    final String date = shortDate(dateTime);
    final String hour = dateTime.hour.toString().padLeft(2, '0');
    final String minute = dateTime.minute.toString().padLeft(2, '0');
    return '$date ${dateTime.year}, $hour:$minute';
  }
}
