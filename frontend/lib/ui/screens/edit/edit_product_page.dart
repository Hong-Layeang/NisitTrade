import 'dart:io';

import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:get_it/get_it.dart';
import 'package:frontend/domain/repository_interfaces/i_category_repository.dart';
import 'package:frontend/domain/repository_interfaces/i_product_repository.dart';
import 'package:frontend/domain/repository_interfaces/i_product_image_repository.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';


import '../../../data/models/product.dart';
import '../../../data/models/category.dart';
import '../../../core/errors/app_error_messages.dart';
import '../../../core/errors/api_exception.dart';
import '../../../core/constants/app_limits.dart';
import '../../../core/constants/colors.dart';
import '../../../logic/view_models/product_feed_view_model.dart';
import '../../../logic/view_models/user_view_model.dart';
import '../../widgets/app_snack_bar.dart';
import '../sell/product_form_image_picker.dart';
import '../sell/product_form_orchestrator.dart';
import '../sell/product_form_shared.dart';
import '../sell/widgets/sell_form_widgets.dart';

final getIt = GetIt.instance;

class EditProductPage extends StatefulWidget {
  final Product product;

  const EditProductPage({super.key, required this.product});

  @override
  State<EditProductPage> createState() => _EditProductPageState();
}

class _EditProductPageState extends State<EditProductPage> {
  late final ICategoryRepository _categoryRepository;
  late final ProductFormOrchestrator _orchestrator;
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();
  final ImagePicker _imagePicker = ImagePicker();

  List<Category> _categories = [];
  int? _selectedCategoryId;
  
  // Existing images from server (imageId -> imageUrl)
  final Map<int, String> _existingImages = {};
  
  // New images picked locally (XFile paths)
  final List<XFile> _newImages = [];
  
  // IDs of images marked for deletion
  final Set<int> _imagesToDelete = {};

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
    _initializeForm();
    _loadCategories();
  }

  void _initializeForm() {
    _titleController.text = widget.product.title;
    _descriptionController.text = widget.product.description ?? '';
    _priceController.text = widget.product.price.toString();
    _selectedCategoryId = widget.product.categoryId;

    // Load existing images
    if (widget.product.productImages != null) {
      for (var image in widget.product.productImages!) {
        _existingImages[image.id] = image.imageUrl;
      }
    }
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
    final totalImages = _existingImages.length - _imagesToDelete.length + _newImages.length;

    final pickResult = await ProductFormImagePicker.pickWithinLimit(
      imagePicker: _imagePicker,
      currentCount: totalImages,
    );

    if (pickResult.reachedLimit) {
      _showSnack('You can upload up to $maxProductImages images.');
      return;
    }

    if (pickResult.images.isEmpty) return;

    setState(() {
      _newImages.addAll(pickResult.images);
    });
  }

  void _removeExistingImage(int imageId) {
    setState(() {
      _imagesToDelete.add(imageId);
    });
  }

  void _undoRemoveExistingImage(int imageId) {
    setState(() {
      _imagesToDelete.remove(imageId);
    });
  }

  void _confirmDeleteExistingImage(int imageId) {
    setState(() {
      _existingImages.remove(imageId);
      _imagesToDelete.remove(imageId);
    });
  }

  void _removeNewImage(int index) {
    setState(() {
      _newImages.removeAt(index);
    });
  }

  void _reorderImages(int oldIndex, int newIndex) {
    setState(() {
      final allEntries = _existingImages.entries.toList();
      final existingCount = allEntries.length;

      if (oldIndex < existingCount && newIndex < existingCount) {
        // Reordering within existing images
        final temp = allEntries[oldIndex];
        allEntries.removeAt(oldIndex);
        allEntries.insert(newIndex, temp);
        _existingImages.clear();
        for (var entry in allEntries) {
          _existingImages[entry.key] = entry.value;
        }
      } else if (oldIndex >= existingCount && newIndex >= existingCount) {
        // Reordering within new images
        final oldNewIndex = oldIndex - existingCount;
        final newNewIndex = newIndex - existingCount;
        final temp = _newImages[oldNewIndex];
        _newImages.removeAt(oldNewIndex);
        _newImages.insert(newNewIndex, temp);
      } else {
        // Mixed reordering between existing and new - not supported for simplicity
        // Could be implemented if needed
      }
    });
  }

  Future<void> _submit() async {
    if (_isLoading) return;

    final remainingExistingCount = _existingImages.length - _imagesToDelete.length;
    final totalImageCount = remainingExistingCount + _newImages.length;

    final validation = ProductFormShared.validateSubmission(
      titleInput: _titleController.text,
      descriptionInput: _descriptionController.text,
      priceInput: _priceController.text,
      selectedCategoryId: _selectedCategoryId,
      imageCount: totalImageCount,
      imageRequiredMessage: 'Please have at least 1 photo.',
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
      final result = await _orchestrator.updateProduct(
        productId: widget.product.id,
        title: title,
        description: description.isEmpty ? null : description,
        price: price,
        categoryId: _selectedCategoryId!,
        imageIdsToDelete: _imagesToDelete,
        newImages: _newImages,
      );

      if (!mounted) return;

      if (result.success) {
        context.read<ProductFeedViewModel>().refresh();
        // Refresh user products in ProfilePage
        final userViewModel = context.read<UserViewModel>();
        if (userViewModel.userId != null) {
          userViewModel.refresh(); // Fire and forget - refresh in background
        }
        _showSnack(result.message);
        Navigator.of(context).pop(true);
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

  void _showSnack(String message) {
    AppSnackBar.show(context, message);
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading && _categories.isEmpty) {
      return Scaffold(
        body: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                child: EditHeaderRow(onBack: () => Navigator.of(context).pop()),
              ),
              const Expanded(
                child: Center(child: CircularProgressIndicator()),
              ),
            ],
          ),
        ),
      );
    }

    if (_error != null && _categories.isEmpty) {
      return Scaffold(
        body: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                child: EditHeaderRow(onBack: () => Navigator.of(context).pop()),
              ),
              Expanded(
                child: Center(
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
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              EditHeaderRow(onBack: () => Navigator.of(context).pop()),
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
                photoGrid: EditPhotoGrid(
                  existingImages: _existingImages,
                  newImages: _newImages,
                  imagesToDelete: _imagesToDelete,
                  onAddTap: _pickImages,
                  onRemoveExisting: _removeExistingImage,
                  onUndoRemoveExisting: _undoRemoveExistingImage,
                  onConfirmDeleteExisting: _confirmDeleteExistingImage,
                  onRemoveNew: _removeNewImage,
                  onReorder: _reorderImages,
                ),
                submitLabel: _isLoading ? 'Saving...' : 'Save Changes',
                isSubmitting: _isLoading,
                onSubmit: _isLoading ? null : _submit,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Edit-specific header widget
class EditHeaderRow extends StatelessWidget {
  final VoidCallback onBack;

  const EditHeaderRow({super.key, required this.onBack});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        IconButton(
          onPressed: onBack,
          icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
        ),
        const SizedBox(width: 8),
        const Expanded(
          child: Text(
            'Edit Your Listing',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
        ),
        const SizedBox(width: 44),
      ],
    );
  }
}

// Edit-specific photo grid widget with existing/new image management
class EditPhotoGrid extends StatefulWidget {
  final Map<int, String> existingImages;
  final List<XFile> newImages;
  final Set<int> imagesToDelete;
  final VoidCallback onAddTap;
  final ValueChanged<int> onRemoveExisting;
  final ValueChanged<int> onUndoRemoveExisting;
  final ValueChanged<int> onConfirmDeleteExisting;
  final ValueChanged<int> onRemoveNew;
  final void Function(int oldIndex, int newIndex) onReorder;

  const EditPhotoGrid({
    super.key,
    required this.existingImages,
    required this.newImages,
    required this.imagesToDelete,
    required this.onAddTap,
    required this.onRemoveExisting,
    required this.onUndoRemoveExisting,
    required this.onConfirmDeleteExisting,
    required this.onRemoveNew,
    required this.onReorder,
  });

  @override
  State<EditPhotoGrid> createState() => _EditPhotoGridState();
}

class _EditPhotoGridState extends State<EditPhotoGrid> {
  int? _hoveringIndex;

  @override
  Widget build(BuildContext context) {
    // Build display list: existing (not deleted) + new images
    final displayItems = <_PhotoItem>[];
    
    // Add existing images (show even if marked for deletion, but visually indicate)
    final existingList = widget.existingImages.entries.toList();
    for (int i = 0; i < existingList.length; i++) {
      final entry = existingList[i];
      displayItems.add(_PhotoItem.existing(
        entry.key,
        entry.value,
        widget.imagesToDelete.contains(entry.key),
      ));
    }

    // Add new local images
    for (int i = 0; i < widget.newImages.length; i++) {
      displayItems.add(_PhotoItem.newLocal(
        i,
        widget.newImages[i].path,
      ));
    }

    // Calculate remaining slots
    final activeImageCount = displayItems.where((item) => !item.isMarkedForDeletion).length;
    final canAddMore = activeImageCount < 8;
    final showMinimumSlots = displayItems.length < 3;
    final itemCount = showMinimumSlots
        ? 3
        : (canAddMore ? displayItems.length + 1 : displayItems.length);

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: itemCount,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
      ),
      itemBuilder: (context, index) {
        // Add new photo button
        if (index >= displayItems.length) {
          return EditPhotoTile.addButton(onTap: widget.onAddTap);
        }

        final item = displayItems[index];
        final isHovering = _hoveringIndex == index;

        return DragTarget<int>(
          onWillAcceptWithDetails: (details) => details.data != index,
          onAcceptWithDetails: (details) {
            widget.onReorder(details.data, index);
            setState(() {
              _hoveringIndex = null;
            });
          },
          onMove: (_) {
            if (_hoveringIndex != index) {
              setState(() => _hoveringIndex = index);
            }
          },
          onLeave: (_) {
            if (_hoveringIndex == index) {
              setState(() => _hoveringIndex = null);
            }
          },
          builder: (context, candidateData, rejectedData) {
            if (item.isExisting) {
              return LongPressDraggable<int>(
                data: index,
                feedback: Material(
                  elevation: 8,
                  child: Opacity(
                    opacity: 0.8,
                    child: Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        border: Border.all(color: AppColors.primary, width: 2),
                      ),
                      child: CachedNetworkImage(
                        key: ValueKey('edit_product_thumb_${item.imageUrl}'),
                        imageUrl: item.imageUrl!,
                        fit: BoxFit.cover,
                        useOldImageOnUrlChange: true,
                        fadeInDuration: Duration.zero,
                        fadeOutDuration: Duration.zero,
                      ),
                    ),
                  ),
                ),
                childWhenDragging: Container(
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    border: Border.all(color: AppColors.border, width: 1.2),
                  ),
                  child: const Center(
                    child: Icon(Icons.photo, color: AppColors.textSecondary, size: 32),
                  ),
                ),
                child: EditPhotoTile.existing(
                  imageUrl: item.imageUrl!,
                  isMarkedForDeletion: item.isMarkedForDeletion,
                  isHovering: isHovering,
                  onRemove: () => widget.onRemoveExisting(item.existingId!),
                  onUndo: () => widget.onUndoRemoveExisting(item.existingId!),
                  onConfirmDelete: () => widget.onConfirmDeleteExisting(item.existingId!),
                ),
              );
            } else {
              return LongPressDraggable<int>(
                data: index,
                feedback: Material(
                  elevation: 8,
                  child: Opacity(
                    opacity: 0.8,
                    child: Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        border: Border.all(color: AppColors.primary, width: 2),
                      ),
                      child: Image.file(File(item.localPath!), fit: BoxFit.cover),
                    ),
                  ),
                ),
                childWhenDragging: Container(
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    border: Border.all(color: AppColors.border, width: 1.2),
                  ),
                  child: const Center(
                    child: Icon(Icons.photo, color: AppColors.textSecondary, size: 32),
                  ),
                ),
                child: EditPhotoTile.newLocal(
                  imagePath: item.localPath!,
                  isHovering: isHovering,
                  onRemove: () => widget.onRemoveNew(item.newIndex!),
                ),
              );
            }
          },
        );
      },
    );
  }
}

// Data class for photo items
class _PhotoItem {
  final bool isExisting;
  final int? existingId;
  final String? imageUrl;
  final int? newIndex;
  final String? localPath;
  final bool isMarkedForDeletion;

  _PhotoItem.existing(
    this.existingId,
    this.imageUrl,
    this.isMarkedForDeletion,
  )   : isExisting = true,
        newIndex = null,
        localPath = null;

  _PhotoItem.newLocal(
    this.newIndex,
    this.localPath,
  )   : isExisting = false,
        existingId = null,
        imageUrl = null,
        isMarkedForDeletion = false;
}

// Edit-specific photo tile widget
class EditPhotoTile extends StatelessWidget {
  final String? imageUrl;
  final String? imagePath;
  final bool isMarkedForDeletion;
  final bool isAddButton;
  final bool isHovering;
  final VoidCallback? onTap;
  final VoidCallback? onRemove;
  final VoidCallback? onUndo;
  final VoidCallback? onConfirmDelete;

  const EditPhotoTile._({
    this.imageUrl,
    this.imagePath,
    this.isMarkedForDeletion = false,
    this.isAddButton = false,
    this.isHovering = false,
    this.onTap,
    this.onRemove,
    this.onUndo,
    this.onConfirmDelete,
  });

  factory EditPhotoTile.addButton({required VoidCallback onTap}) {
    return EditPhotoTile._(
      isAddButton: true,
      onTap: onTap,
    );
  }

  factory EditPhotoTile.existing({
    required String imageUrl,
    required bool isMarkedForDeletion,
    required bool isHovering,
    required VoidCallback onRemove,
    required VoidCallback onUndo,
    required VoidCallback onConfirmDelete,
  }) {
    return EditPhotoTile._(
      imageUrl: imageUrl,
      isMarkedForDeletion: isMarkedForDeletion,
      isHovering: isHovering,
      onRemove: onRemove,
      onUndo: onUndo,
      onConfirmDelete: onConfirmDelete,
    );
  }

  factory EditPhotoTile.newLocal({
    required String imagePath,
    required bool isHovering,
    required VoidCallback onRemove,
  }) {
    return EditPhotoTile._(
      imagePath: imagePath,
      isHovering: isHovering,
      onRemove: onRemove,
    );
  }

  @override
  Widget build(BuildContext context) {
    if (isAddButton) {
      return Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          border: Border.all(color: AppColors.border, width: 1.2),
        ),
        child: InkWell(
          onTap: onTap,
          child: const Center(
            child: Icon(Icons.add, color: AppColors.textSecondary, size: 32),
          ),
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: isHovering ? AppColors.primary.withValues(alpha: 0.1) : AppColors.surface,
        border: Border.all(
          color: isHovering ? AppColors.primary : AppColors.border,
          width: isHovering ? 2 : 1.2,
        ),
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Image display (from URL or local file)
          if (imageUrl != null)
            CachedNetworkImage(
              key: ValueKey('edit_tile_$imageUrl'),
              imageUrl: imageUrl!,
              fit: BoxFit.cover,
              useOldImageOnUrlChange: true,
              fadeInDuration: Duration.zero,
              fadeOutDuration: Duration.zero,
              placeholder: (context, url) => Container(
                color: AppColors.surface,
                child: const Center(
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: AppColors.primary,
                  ),
                ),
              ),
              errorWidget: (context, url, error) => Container(
                color: AppColors.surface,
                child: const Icon(
                  Icons.image,
                  color: AppColors.textSecondary,
                ),
              ),
            )
          else if (imagePath != null)
            Image.file(
              File(imagePath!),
              fit: BoxFit.cover,
              errorBuilder: (_, _, _) => Container(
                color: AppColors.surface,
                child: const Icon(
                  Icons.image,
                  color: AppColors.textSecondary,
                ),
              ),
            ),

          // Deletion overlay for marked images (clickable to restore)
          if (isMarkedForDeletion)
            GestureDetector(
              onTap: onUndo,
              child: Container(
                color: Colors.black.withValues(alpha: 0.5),
                child: Center(
                  child: GestureDetector(
                    onTap: onConfirmDelete,
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.red.withValues(alpha: 0.8),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.delete,
                        color: Colors.white,
                        size: 28,
                      ),
                    ),
                  ),
                ),
              ),
            ),

          // X button (mark for deletion)
          if (!isMarkedForDeletion)
            Positioned(
              top: 6,
              right: 6,
              child: InkWell(
                onTap: onRemove,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.6),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.close,
                    color: Colors.white,
                    size: 14,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

