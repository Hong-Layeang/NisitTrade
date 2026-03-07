import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';

import 'package:get_it/get_it.dart';
import '../../../domain/repository_interfaces/i_category_repository.dart';
import '../../../domain/repository_interfaces/i_product_repository.dart';
import '../../../domain/repository_interfaces/i_product_image_repository.dart';

import '../../../data/models/category.dart';
import '../../../core/errors/api_exception.dart';
import '../../../core/constants/colors.dart';
import '../../../logic/view_models/product_feed_view_model.dart';
import '../../widgets/app_buttons.dart';
import 'widgets/sell_form_widgets.dart';

final getIt = GetIt.instance;

class SellPage extends StatefulWidget {
  const SellPage({super.key});

  @override
  State<SellPage> createState() => _SellPageState();
}

class _SellPageState extends State<SellPage> {
  late final ICategoryRepository _categoryRepository;
  late final IProductRepository _productRepository;
  late final IProductImageRepository _productImageRepository;
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();
  final ImagePicker _imagePicker = ImagePicker();

  List<Category> _categories = [];
  int? _selectedCategoryId;
  List<XFile> _selectedImages = [];

  bool _isLoading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _categoryRepository = getIt<ICategoryRepository>();
    _productRepository = getIt<IProductRepository>();
    _productImageRepository = getIt<IProductImageRepository>();
    _loadCategories();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  Future<void> _loadCategories() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final response = await _categoryRepository.getCategories();
      if (!response.isSuccess) {
        throw response.error!;
      }

      if (mounted) {
        setState(() {
          _categories = (response.data ?? [])
              .map((entity) => Category.fromEntity(entity))
              .toList();
          _isLoading = false;
        });
      }
    } on ApiException catch (e) {
      if (mounted) {
        setState(() {
          _error = e.message;
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _pickImages() async {
    if (_selectedImages.length >= 8) {
      _showSnack('You can upload up to 8 images.');
      return;
    }

    final images = await _imagePicker.pickMultiImage();
    if (images.isEmpty) return;

    setState(() {
      final remaining = 8 - _selectedImages.length;
      _selectedImages.addAll(images.take(remaining));
    });
  }

  void _removeImage(int index) {
    setState(() {
      _selectedImages.removeAt(index);
    });
  }

  Future<void> _submit() async {
    if (_isLoading) return;

    final title = _titleController.text.trim();
    final description = _descriptionController.text.trim();
    final price = double.tryParse(_priceController.text.trim());

    if (title.isEmpty) {
      _showSnack('Title is required.');
      return;
    }

    if (price == null || price <= 0) {
      _showSnack('Please enter a valid price.');
      return;
    }

    if (_selectedCategoryId == null) {
      _showSnack('Please select a category.');
      return;
    }

    if (_selectedImages.length < 1) {
      _showSnack('Please add at least 1 photo.');
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final createResponse = await _productRepository.createProduct(
        title: title,
        description: description.isEmpty ? null : description,
        price: price,
        categoryId: _selectedCategoryId!,
      );

      if (!createResponse.isSuccess) {
        throw createResponse.error!;
      }

      final productId = createResponse.data!.id;
      final imagePaths = _selectedImages.map((image) => image.path).toList();

      final imageResponse = await _productImageRepository.addProductImages(
        productId: productId,
        imagePaths: imagePaths,
      );

      if (!imageResponse.isSuccess) {
        throw imageResponse.error!;
      }

      context.read<ProductFeedViewModel>().refresh();
      _showSnack('Product created successfully.');
      _clearForm();
    } on ApiException catch (e) {
      if (mounted) {
        setState(() => _error = e.message);
        _showSnack(e.message);
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _clearForm() {
    _titleController.clear();
    _descriptionController.clear();
    _priceController.clear();
    setState(() {
      _selectedCategoryId = null;
      _selectedImages = [];
    });
  }

  void _showSnack(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading && _categories.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null && _categories.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('Error: $_error'),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadCategories,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SellHeaderRow(),
            const SizedBox(height: 12),
            const SectionLabel(text: 'Title'),
            const SizedBox(height: 6),
            OutlinedField(
              hintText: 'Name',
              controller: _titleController,
              textInputAction: TextInputAction.next,
              isDense: true,
            ),
            const SizedBox(height: 12),
            const SectionLabel(text: 'Description'),
            const SizedBox(height: 6),
            OutlinedField(
              hintText: 'Detailed description of your product',
              maxLines: 3,
              controller: _descriptionController,
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 10,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SectionLabel(text: 'Category'),
                      const SizedBox(height: 6),
                      CategoryDropdownField<int>(
                        value: _selectedCategoryId,
                        hint: 'Select category',
                        items: _categories
                            .map(
                              (category) => DropdownMenuItem<int>(
                                value: category.id,
                                child: Text(
                                  category.name,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontSize: 14,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                              ),
                            )
                            .toList(),
                        onChanged: (value) {
                          setState(() => _selectedCategoryId = value);
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SectionLabel(text: 'Price (in \$)'),
                      const SizedBox(height: 6),
                      OutlinedField(
                        hintText: '0.0',
                        controller: _priceController,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        isDense: true,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const SectionLabel(text: 'Photos'),
            const SizedBox(height: 4),
            Text.rich(
              TextSpan(
                text:
                    'Capture all the angles and details. Your first square is the key image. ',
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                  height: 1.2,
                ),
                children: const [
                  TextSpan(
                    text: 'At least 1 photo required.',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.primary,
                      height: 1.2,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            PhotoGrid(
              imagePaths: _selectedImages.map((image) => image.path).toList(),
              maxCount: 8,
              onAddTap: _pickImages,
              onRemoveTap: _removeImage,
            ),
            const SizedBox(height: 16),
            AppPrimaryButton(
              label: _isLoading ? 'Adding...' : 'Add',
              isLoading: _isLoading,
              onPressed: _isLoading ? null : _submit,
            ),
          ],
        ),
      ),
    );
  }
}
