import 'package:flutter/material.dart';

import '../../../widgets/app_report_sheet.dart';

typedef ProductReportInput = ReportSheetInput;

Future<ProductReportInput?> showProductReportSheet(BuildContext context) {
  return showReportSheet(
    context,
    title: 'Report product',
    description: 'Tell us what is wrong with this listing.',
    reasons: const [
      'Spam or scam',
      'Prohibited or illegal item',
      'Counterfeit item',
      'Misleading description',
      'Inappropriate content',
      'Other',
    ],
  );
}
