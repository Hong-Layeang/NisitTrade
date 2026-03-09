/// Utility class for formatting numbers and values consistently.
class NumberFormatters {
  NumberFormatters._();

  /// Format large numbers into readable short format (e.g., 1.5k, 2.3m)
  static String formatCount(int count, {int decimals = 1}) {
    if (count >= 1000000) {
      final value = count / 1000000;
      return '${value.toStringAsFixed(value % 1 == 0 ? 0 : decimals)}m';
    }
    if (count >= 1000) {
      final value = count / 1000;
      return '${value.toStringAsFixed(value % 1 == 0 ? 0 : decimals)}k';
    }
    return count.toString();
  }

  /// Format price with currency symbol and 2 decimal places
  static String formatPrice(double price, {String currency = '\$'}) {
    return '$currency${price.toStringAsFixed(2)}';
  }

  /// Format percentage with 1 decimal place
  static String formatPercentage(double value, {int decimals = 1}) {
    return '${(value * 100).toStringAsFixed(decimals)}%';
  }
}

/// Utility class for formatting strings.
class StringFormatters {
  StringFormatters._();

  /// Obfuscate email for privacy
  static String obfuscateEmail(String email) {
    final parts = email.split('@');
    if (parts.length < 2) return email;

    final username = parts[0];
    final domain = parts[1];

    // Obfuscate username
    String obfuscatedUsername;
    if (username.length <= 2) {
      obfuscatedUsername = username;
    } else {
      obfuscatedUsername = '${username[0]}***${username[username.length - 1]}';
    }

    // Obfuscate domain
    final domainParts = domain.split('.');
    String obfuscatedDomain = domain;
    if (domainParts.length >= 2) {
      final domainName = domainParts[0];
      final tld = domainParts.sublist(1).join('.');

      if (domainName.length > 2) {
        obfuscatedDomain =
            '${domainName[0]}***${domainName[domainName.length - 1]}.$tld';
      }
    }

    return '$obfuscatedUsername@$obfuscatedDomain';
  }

  /// Capitalize first letter of string
  static String capitalize(String text) {
    if (text.isEmpty) return text;
    return text[0].toUpperCase() + text.substring(1);
  }

  /// Truncate text with ellipsis
  static String truncate(String text, int maxLength, {String ellipsis = '...'}) {
    if (text.length <= maxLength) return text;
    return '${text.substring(0, maxLength)}$ellipsis';
  }
}
