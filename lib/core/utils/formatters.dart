abstract final class AppFormatters {
  static String moneyK(int amount) => '${amount}k UZS';

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
