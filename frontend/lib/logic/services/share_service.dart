import 'package:share_plus/share_plus.dart';

/// Service to handle sharing content to external apps
class ShareService {
  static Future<void> shareProduct({
    required String title,
    required String url,
    String? text,
  }) async {
    await Share.share(
      text ?? 'Check out this listing on NisitTrade: $url',
      subject: title,
    );
  }

  static Future<void> sharePost({
    required String url,
    String? text,
  }) async {
    final shareText = text != null
        ? '$text\n\nCheck it out: $url'
        : 'Check out this post on NisitTrade: $url';

    await Share.share(
      shareText,
      subject: 'NisitTrade Post',
    );
  }

  static Future<void> share({
    required String text,
    String? subject,
  }) async {
    await Share.share(
      text,
      subject: subject,
    );
  }

  static Future<void> shareWithBox({
    required String shareUrl,
    String? message,
  }) async {
    try {
      await Share.share(
        message ?? shareUrl,
        subject: 'NisitTrade',
      );
    } catch (e) {
      rethrow;
    }
  }
}
