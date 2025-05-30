// Archivo: lib/widgets/image_picker_widget.dart
// Widget para seleccionar y gestionar imágenes del proyecto

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../services/storage_service.dart';

class ImagePickerWidget extends StatefulWidget {
  final String? initialImageUrl;
  final List<String> initialImages;
  final Function(String) onMainImageSelected;
  final Function(List<String>) onImagesSelected;
  final int maxImages;
  final bool allowMainImageSelection;

  const ImagePickerWidget({
    super.key,
    this.initialImageUrl,
    this.initialImages = const [],
    required this.onMainImageSelected,
    required this.onImagesSelected,
    this.maxImages = 3,
    this.allowMainImageSelection = true,
  });

  @override
  State<ImagePickerWidget> createState() => _ImagePickerWidgetState();
}

class _ImagePickerWidgetState extends State<ImagePickerWidget> {
  late List<String> _selectedImages;
  String? _mainImageUrl;
  bool _isUploading = false;
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _selectedImages = List.from(widget.initialImages);
    _mainImageUrl = widget.initialImageUrl;
  }

  Future<void> _pickImages() async {
    if (_isUploading) return;
    
    final remainingSlots = widget.maxImages - _selectedImages.length;
    if (remainingSlots <= 0) {
      _showSnackBar('Máximo ${widget.maxImages} imágenes permitidas', Colors.orange);
      return;
    }

    try {
      final List<XFile> pickedFiles = await _picker.pickMultiImage(
        imageQuality: 80,
      );

      if (pickedFiles.isEmpty) return;

      // Limitar la cantidad de imágenes seleccionadas
      final imagesToUpload = pickedFiles.take(remainingSlots).toList();
      
      if (pickedFiles.length > remainingSlots) {
        _showSnackBar(
          'Solo se seleccionaron $remainingSlots imágenes de ${pickedFiles.length}',
          Colors.orange,
        );
      }

      setState(() {
        _isUploading = true;
      });

      // Subir imágenes
      final uploadedUrls = await _uploadImages(imagesToUpload);
      
      setState(() {
        _selectedImages.addAll(uploadedUrls);
        _isUploading = false;
      });

      // Si no hay imagen principal y se subió al menos una imagen
      if (_mainImageUrl == null && uploadedUrls.isNotEmpty) {
        _mainImageUrl = uploadedUrls.first;
        widget.onMainImageSelected(_mainImageUrl!);
      }

      widget.onImagesSelected(_selectedImages);
      
      _showSnackBar(
        'Imágenes subidas exitosamente',
        Colors.green,
      );

    } catch (e) {
      setState(() {
        _isUploading = false;
      });
      _showSnackBar('Error al seleccionar imágenes: $e', Colors.red);
    }
  }

  
Future<List<String>> _uploadImages(List<XFile> imageFiles) async {
  final List<String> uploadedUrls = [];
  
  for (int i = 0; i < imageFiles.length; i++) {
    try {
      // Verificar que el path no sea null y no esté vacío
      final imagePath = imageFiles[i].path;
      if (imagePath.trim().isEmpty) {
        debugPrint('Error: Image path is empty for image $i');
        continue;
      }
      
      final String? url = await StorageService.uploadProjectImage(
        'project_${DateTime.now().millisecondsSinceEpoch}_$i',
        imagePath,
      );
      
      // Verificar que la URL no sea null ni vacía antes de agregarla
      if (url != null && url.isNotEmpty) {
        uploadedUrls.add(url);
      } else {
        debugPrint('Error: Upload returned null or empty URL for image $i');
      }
    } catch (e) {
      debugPrint('Error uploading image $i: $e');
    }
  }
  
  return uploadedUrls;
}

  void _removeImage(int index) {
    setState(() {
      final removedImage = _selectedImages[index];
      _selectedImages.removeAt(index);
      
      // Si la imagen removida era la principal, seleccionar la primera disponible
      if (_mainImageUrl == removedImage) {
        _mainImageUrl = _selectedImages.isNotEmpty ? _selectedImages.first : null;
        if (_mainImageUrl != null) {
          widget.onMainImageSelected(_mainImageUrl!);
        }
      }
    });
    
    widget.onImagesSelected(_selectedImages);
  }

  void _setAsMainImage(String imageUrl) {
    if (!widget.allowMainImageSelection) return;
    
    setState(() {
      _mainImageUrl = imageUrl;
    });
    widget.onMainImageSelected(imageUrl);
  }

  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header con botón de agregar
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Imágenes del proyecto',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            TextButton.icon(
              onPressed: _selectedImages.length >= widget.maxImages || _isUploading
                  ? null
                  : _pickImages,
              icon: _isUploading
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.add_photo_alternate),
              label: Text(_isUploading ? 'Subiendo...' : 'Agregar'),
            ),
          ],
        ),
        
        // Información sobre límites
        Text(
          'Máximo ${widget.maxImages} imágenes (${_selectedImages.length}/${widget.maxImages})',
          style: TextStyle(
            fontSize: 12,
            color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
          ),
        ),
        
        const SizedBox(height: 16),
        
        // Imagen principal
        if (widget.allowMainImageSelection && _mainImageUrl != null) ...[
          Text(
            'Imagen principal',
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          _buildMainImageCard(),
          const SizedBox(height: 16),
        ],
        
        // Grid de imágenes
        if (_selectedImages.isEmpty)
          _buildEmptyState(isDarkMode)
        else
          _buildImageGrid(),
      ],
    );
  }

  Widget _buildMainImageCard() {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;
    
    return Container(
      height: 120,
      width: double.infinity,
      decoration: BoxDecoration(
        border: Border.all(
          color: theme.primaryColor,
          width: 2,
        ),
        borderRadius: BorderRadius.circular(8),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(6),
        child: Stack(
          children: [
            CachedNetworkImage(
              imageUrl: _mainImageUrl!,
              width: double.infinity,
              height: double.infinity,
              fit: BoxFit.cover,
              placeholder: (context, url) => Container(
                color: isDarkMode ? Colors.grey[800] : Colors.grey[200],
                child: const Center(
                  child: CircularProgressIndicator(),
                ),
              ),
              errorWidget: (context, url, error) => Container(
                color: isDarkMode ? Colors.grey[800] : Colors.grey[200],
                child: const Icon(Icons.error),
              ),
            ),
            Positioned(
              top: 8,
              left: 8,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: theme.primaryColor,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Text(
                  'Principal',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(bool isDarkMode) {
    return Container(
      height: 120,
      width: double.infinity,
      decoration: BoxDecoration(
        border: Border.all(
          color: isDarkMode ? Colors.grey[600]! : Colors.grey[300]!,
          style: BorderStyle.solid,
        ),
        borderRadius: BorderRadius.circular(8),
        color: isDarkMode ? Colors.grey[900] : Colors.grey[50],
      ),
      child: InkWell(
        onTap: _isUploading ? null : _pickImages,
        borderRadius: BorderRadius.circular(8),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.add_photo_alternate,
              size: 32,
              color: isDarkMode ? Colors.grey[500] : Colors.grey[400],
            ),
            const SizedBox(height: 8),
            Text(
              'Toca para agregar imágenes',
              style: TextStyle(
                color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                fontSize: 14,
              ),
            ),
            Text(
              'Máximo ${widget.maxImages} imágenes',
              style: TextStyle(
                color: isDarkMode ? Colors.grey[500] : Colors.grey[500],
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImageGrid() {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
        childAspectRatio: 1,
      ),
      itemCount: _selectedImages.length,
      itemBuilder: (context, index) {
        return _buildImageCard(_selectedImages[index], index);
      },
    );
  }

  Widget _buildImageCard(String imageUrl, int index) {
    final theme = Theme.of(context);
    final isMainImage = _mainImageUrl == imageUrl;
    
    return Container(
      decoration: BoxDecoration(
        border: Border.all(
          color: isMainImage ? theme.primaryColor : Colors.grey[300]!,
          width: isMainImage ? 2 : 1,
        ),
        borderRadius: BorderRadius.circular(8),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(6),
        child: Stack(
          children: [
            // Imagen
            CachedNetworkImage(
              imageUrl: imageUrl,
              width: double.infinity,
              height: double.infinity,
              fit: BoxFit.cover,
              placeholder: (context, url) => Container(
                color: Colors.grey[200],
                child: const Center(
                  child: CircularProgressIndicator(),
                ),
              ),
              errorWidget: (context, url, error) => Container(
                color: Colors.grey[200],
                child: const Icon(Icons.error),
              ),
            ),
            
            // Overlay con botones
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Colors.black.withOpacity(0.7),
                    ],
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Botón eliminar
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        IconButton(
                          icon: const Icon(
                            Icons.close,
                            color: Colors.white,
                            size: 16,
                          ),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(
                            minWidth: 24,
                            minHeight: 24,
                          ),
                          onPressed: () => _removeImage(index),
                        ),
                      ],
                    ),
                    
                    // Botón marcar como principal
                    if (widget.allowMainImageSelection)
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          if (!isMainImage)
                            IconButton(
                              icon: const Icon(
                                Icons.star_border,
                                color: Colors.white,
                                size: 16,
                              ),
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(
                                minWidth: 24,
                                minHeight: 24,
                              ),
                              onPressed: () => _setAsMainImage(imageUrl),
                            )
                          else
                            const Icon(
                              Icons.star,
                              color: Colors.amber,
                              size: 16,
                            ),
                        ],
                      ),
                  ],
                ),
              ),
            ),
            
            // Badge de principal
            if (isMainImage)
              Positioned(
                top: 4,
                left: 4,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                  decoration: BoxDecoration(
                    color: theme.primaryColor,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Text(
                    'Principal',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 8,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}