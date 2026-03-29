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

class SellerPurchaseDecision {
  final int productId;
  final String action;

  const SellerPurchaseDecision({
    required this.productId,
    required this.action,
  });

  bool get isMarkedSold => action == SellerPurchaseDecisionMessage.actionSold;
  bool get isKeptActive =>
      action == SellerPurchaseDecisionMessage.actionKeepActive;
  bool get isNotSold => action == SellerPurchaseDecisionMessage.actionNotSold;
}

class SellerPurchaseDecisionMessage {
  static const String _prefix = '__seller_purchase_decision__:';
  static const String actionSold = 'sold';
  static const String actionKeepActive = 'keep_active';
  static const String actionNotSold = 'not_sold';
  static const String previewText = 'Seller updated purchase status';

  static String build({required int productId, required String action}) {
    return '$_prefix$productId:$action';
  }

  static SellerPurchaseDecision? tryParse(String messageText) {
    final normalized = messageText.trim();
    if (!normalized.startsWith(_prefix)) {
      return null;
    }

    final body = normalized.substring(_prefix.length);
    final separatorIndex = body.indexOf(':');
    if (separatorIndex <= 0 || separatorIndex >= body.length - 1) {
      return null;
    }

    final productId = int.tryParse(body.substring(0, separatorIndex));
    if (productId == null || productId <= 0) {
      return null;
    }

    final action = body.substring(separatorIndex + 1);
    if (!_isValidAction(action)) {
      return null;
    }

    return SellerPurchaseDecision(productId: productId, action: action);
  }

  static bool isSellerDecision(String messageText) {
    return tryParse(messageText) != null;
  }

  static String displayText(
    String messageText, {
    String? productTitle,
  }) {
    final decision = tryParse(messageText);
    if (decision == null) {
      return previewText;
    }

    final normalizedTitle = productTitle?.trim();
    final hasTitle = normalizedTitle != null && normalizedTitle.isNotEmpty;

    if (decision.isMarkedSold) {
      return hasTitle
          ? 'Seller marked "$normalizedTitle" as sold.'
          : 'Seller marked this purchase as sold.';
    }
    if (decision.isKeptActive) {
      return hasTitle
          ? 'Seller marked "$normalizedTitle" as sold.'
          : 'Seller marked this purchase as sold.';
    }

    return hasTitle
        ? 'Seller marked "$normalizedTitle" as not sold.'
        : 'Seller marked this purchase as not sold.';
  }

  static bool _isValidAction(String action) {
    return action == actionSold ||
        action == actionKeepActive ||
        action == actionNotSold;
  }
}