import 'package:image_picker/image_picker.dart';

import '../../../core/constants/app_limits.dart';

class ProductImagePickResult {
  final List<XFile> images;
  final bool reachedLimit;

  const ProductImagePickResult({
    required this.images,
    required this.reachedLimit,
  });
}

class ProductFormImagePicker {
  const ProductFormImagePicker._();

  static Future<ProductImagePickResult> pickWithinLimit({
    required ImagePicker imagePicker,
    required int currentCount,
    int maxCount = maxProductImages,
  }) async {
    if (currentCount >= maxCount) {
      return const ProductImagePickResult(images: [], reachedLimit: true);
    }

    final picked = await imagePicker.pickMultiImage();
    if (picked.isEmpty) {
      return const ProductImagePickResult(images: [], reachedLimit: false);
    }

    final remaining = maxCount - currentCount;
    return ProductImagePickResult(
      images: picked.take(remaining).toList(),
      reachedLimit: false,
    );
  }
}
