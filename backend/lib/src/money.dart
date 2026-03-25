int moneyDisplayAmount(int amount) {
  final int absolute = amount.abs();
  if (absolute == 0) {
    return 0;
  }
  if (absolute < 1000) {
    return amount * 1000;
  }
  return amount;
}

String moneyInputValue(int amount) {
  return moneyDisplayAmount(amount).toString();
}

String formatMoneyUzs(int amount) {
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

int? tryParseStoredMoneyAmount(String raw) {
  final String value = raw.trim();
  if (value.isEmpty) {
    return null;
  }

  final String lower = value.toLowerCase();
  final bool usesLegacyThousands = RegExp(r'\d\s*k\b|\dk\b').hasMatch(lower);
  final String digitsOnly = lower.replaceAll(RegExp(r'[^0-9]'), '');
  if (digitsOnly.isEmpty) {
    return null;
  }

  final int? parsed = int.tryParse(digitsOnly);
  if (parsed == null) {
    return null;
  }
  if (parsed == 0) {
    return 0;
  }
  if (usesLegacyThousands || parsed < 1000) {
    return parsed;
  }
  if (parsed % 1000 != 0) {
    return null;
  }
  return parsed ~/ 1000;
}
