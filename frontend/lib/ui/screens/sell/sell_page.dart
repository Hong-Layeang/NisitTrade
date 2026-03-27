import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_limits.dart';
import '../../../core/errors/app_error_messages.dart';
import '../../../core/errors/api_exception.dart';
import '../../../data/dtos/category_dto.dart';
import '../../../data/repository_interfaces/i_category_repository.dart';
import '../../../data/repository_interfaces/i_product_image_repository.dart';
import '../../../data/repository_interfaces/i_product_repository.dart';
import '../../../logic/view_models/product_feed_view_model.dart';
import '../../widgets/app_snack_bar.dart';
import 'product_form_image_picker.dart';
import 'product_form_orchestrator.dart';
import 'product_form_shared.dart';
import 'widgets/sell_form_widgets.dart';

final getIt = GetIt.instance;

class SellPage extends StatefulWidget {
  final VoidCallback? onProductUploaded;

  const SellPage({
    super.key,
    this.onProductUploaded,
  });

  @override
  State<SellPage> createState() => _SellPageState();
}

class _SellPageState extends State<SellPage> {
  late final ICategoryRepository _categoryRepository;
  late final ProductFormOrchestrator _orchestrator;
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();
  final ImagePicker _imagePicker = ImagePicker();

  List<CategoryDto> _categories = [];
  int? _selectedCategoryId;
  List<XFile> _selectedImages = [];

  bool _isLoading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _categoryRepository = getIt<ICategoryRepository>();
    _orchestrator = ProductFormOrchestrator(
      productRepository: getIt<IProductRepository>(),
      productImageRepository: getIt<IProductImageRepository>(),
    );
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
      final categories = await ProductFormShared.loadCategories(
        _categoryRepository,
      );

      if (mounted) {
        setState(() {
          _categories = categories;
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
    final pickResult = await ProductFormImagePicker.pickWithinLimit(
      imagePicker: _imagePicker,
      currentCount: _selectedImages.length,
    );

    if (pickResult.reachedLimit) {
      _showSnack('You can upload up to $maxProductImages images.');
      return;
    }

    if (pickResult.images.isEmpty) return;

    setState(() {
      _selectedImages.addAll(pickResult.images);
    });
  }

  void _removeImage(int index) {
    setState(() {
      _selectedImages.removeAt(index);
    });
  }

  Future<void> _submit() async {
    if (_isLoading) return;

    final validation = ProductFormShared.validateSubmission(
      titleInput: _titleController.text,
      descriptionInput: _descriptionController.text,
      priceInput: _priceController.text,
      selectedCategoryId: _selectedCategoryId,
      imageCount: _selectedImages.length,
      imageRequiredMessage: 'Please add at least 1 photo.',
    );

    if (!validation.isValid) {
      _showSnack(validation.error!);
      return;
    }

    final title = validation.title;
    final description = validation.description;
    final price = validation.price!;

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final result = await _orchestrator.createProduct(
        title: title,
        description: description.isEmpty ? null : description,
        price: price,
        categoryId: _selectedCategoryId!,
        images: _selectedImages,
      );

      if (!mounted) return;

      if (result.success) {
        await context.read<ProductFeedViewModel>().refresh();
        _showSnack(result.message);
        _clearForm();
        widget.onProductUploaded?.call();
      } else {
        setState(() => _error = result.message);
        _showSnack(result.message);
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
    AppSnackBar.show(context, message);
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
            Text(AppErrorMessages.resolve(_error)),
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
            ProductFormFieldsSection(
              titleController: _titleController,
              descriptionController: _descriptionController,
              priceController: _priceController,
              categories: _categories,
              selectedCategoryId: _selectedCategoryId,
              onCategoryChanged: (value) {
                setState(() => _selectedCategoryId = value);
              },
              photoGrid: PhotoGrid(
                imagePaths: _selectedImages.map((image) => image.path).toList(),
                maxCount: 8,
                onAddTap: _pickImages,
                onRemoveTap: _removeImage,
              ),
              submitLabel: _isLoading ? 'Adding...' : 'Add',
              isSubmitting: _isLoading,
              onSubmit: _isLoading ? null : _submit,
            ),
          ],
        ),
      ),
    );
  }
}

