class PurchaseConfirmationMessage {
  static const String _prefix = '__purchase_confirmed__:';
  static const String previewText = 'Buyer confirmed the purchase';

  static String build({required int productId}) => '$_prefix$productId';

  static bool isPurchaseConfirmation(String messageText) {
    return tryParseProductId(messageText) != null;
  }

  static int? tryParseProductId(String messageText) {
    final normalized = messageText.trim();
    if (!normalized.startsWith(_prefix)) {
      return null;
    }

    final rawProductId = normalized.substring(_prefix.length);
    final productId = int.tryParse(rawProductId);
    if (productId == null || productId <= 0) {
      return null;
    }
    return productId;
  }

  static String displayText({String? productTitle}) {
    final normalizedTitle = productTitle?.trim();
    if (normalizedTitle != null && normalizedTitle.isNotEmpty) {
      return 'Buyer confirmed the purchase for "$normalizedTitle".';
    }
    return previewText;
  }
}