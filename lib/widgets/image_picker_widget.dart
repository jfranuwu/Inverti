// Archivo: lib/widgets/image_picker_widget.dart
// Widget para seleccionar y gestionar imágenes

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class ImagePickerWidget extends StatefulWidget {
  final String? initialImageUrl;
  final List<String> initialImages;
  final Function(String?) onMainImageSelected;
  final Function(List<String>) onImagesSelected;
  final int maxImages;
  final bool showMainImageSelector;

  const ImagePickerWidget({
    super.key,
    this.initialImageUrl,
    this.initialImages = const [],
    required this.onMainImageSelected,
    required this.onImagesSelected,
    this.maxImages = 5,
    this.showMainImageSelector = true,
  });

  @override
  State<ImagePickerWidget> createState() => _ImagePickerWidgetState();
}

class _ImagePickerWidgetState extends State<ImagePickerWidget> {
  final ImagePicker _imagePicker = ImagePicker();
  String? _mainImageUrl;
  List<String> _additionalImages = [];
  bool _isUploading = false;

  @override
  void initState() {
    super.initState();
    _mainImageUrl = widget.initialImageUrl;
    _additionalImages = List.from(widget.initialImages);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.showMainImageSelector) ...[
          Text(
            'Imagen principal *',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          _buildMainImageSelector(),
          const SizedBox(height: 24),
        ],
        
        Text(
          'Imágenes adicionales (${_additionalImages.length}/${widget.maxImages})',
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        _buildAdditionalImagesGrid(),
        
        if (_isUploading) ...[
          const SizedBox(height: 16),
          const Center(
            child: CircularProgressIndicator(),
          ),
        ],
      ],
    );
  }

  Widget _buildMainImageSelector() {
    return Container(
      height: 200,
      width: double.infinity,
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey[300]!),
        borderRadius: BorderRadius.circular(12),
      ),
      child: _mainImageUrl != null
          ? _buildImagePreview(_mainImageUrl!, isMain: true)
          : _buildImagePlaceholder(isMain: true),
    );
  }

  Widget _buildAdditionalImagesGrid() {
    return SizedBox(
      height: 120,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: _additionalImages.length + 1,
        itemBuilder: (context, index) {
          if (index == _additionalImages.length) {
            // Botón para agregar nueva imagen
            return _buildAddImageButton();
          }
          
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: _buildImagePreview(
              _additionalImages[index],
              isMain: false,
              onRemove: () => _removeAdditionalImage(index),
            ),
          );
        },
      ),
    );
  }

  Widget _buildImagePreview(
    String imageUrl, {
    required bool isMain,
    VoidCallback? onRemove,
  }) {
    return Container(
      width: isMain ? double.infinity : 120,
      height: isMain ? 200 : 120,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Stack(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: _buildImage(imageUrl),
          ),
          
          // Botón de eliminar
          Positioned(
            top: 8,
            right: 8,
            child: GestureDetector(
              onTap: isMain ? _removeMainImage : onRemove,
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: const BoxDecoration(
                  color: Colors.red,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.close,
                  color: Colors.white,
                  size: 16,
                ),
              ),
            ),
          ),
          
          // Botón de cambiar (solo para imagen principal)
          if (isMain)
            Positioned(
              bottom: 8,
              right: 8,
              child: GestureDetector(
                onTap: () => _pickImage(isMain: true),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.7),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.camera_alt,
                        color: Colors.white,
                        size: 16,
                      ),
                      SizedBox(width: 4),
                      Text(
                        'Cambiar',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildImage(String imageUrl) {
    // Si es una URL de red
    if (imageUrl.startsWith('http')) {
      return Image.network(
        imageUrl,
        width: double.infinity,
        height: double.infinity,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return _buildErrorPlaceholder();
        },
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return _buildLoadingPlaceholder();
        },
      );
    }
    
    // Si es una ruta de archivo local
    return Image.file(
      File(imageUrl),
      width: double.infinity,
      height: double.infinity,
      fit: BoxFit.cover,
      errorBuilder: (context, error, stackTrace) {
        return _buildErrorPlaceholder();
      },
    );
  }

  Widget _buildImagePlaceholder({required bool isMain}) {
    return GestureDetector(
      onTap: () => _pickImage(isMain: isMain),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.grey[50],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: Colors.grey[300]!,
            style: BorderStyle.solid,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.add_photo_alternate,
              size: isMain ? 48 : 32,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 8),
            Text(
              isMain ? 'Agregar imagen principal' : 'Agregar imagen',
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: isMain ? 16 : 12,
              ),
            ),
            if (isMain) ...[
              const SizedBox(height: 4),
              Text(
                'Toca para seleccionar',
                style: TextStyle(
                  color: Colors.grey[500],
                  fontSize: 12,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildAddImageButton() {
    final canAddMore = _additionalImages.length < widget.maxImages;
    
    return GestureDetector(
      onTap: canAddMore ? () => _pickImage(isMain: false) : null,
      child: Container(
        width: 120,
        height: 120,
        decoration: BoxDecoration(
          color: canAddMore ? Colors.grey[50] : Colors.grey[200],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: canAddMore ? Colors.grey[300]! : Colors.grey[400]!,
            style: BorderStyle.solid,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.add,
              size: 32,
              color: canAddMore ? Colors.grey[600] : Colors.grey[500],
            ),
            const SizedBox(height: 4),
            Text(
              canAddMore ? 'Agregar' : 'Máximo ${widget.maxImages}',
              style: TextStyle(
                color: canAddMore ? Colors.grey[600] : Colors.grey[500],
                fontSize: 12,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingPlaceholder() {
    return Container(
      color: Colors.grey[100],
      child: const Center(
        child: CircularProgressIndicator(),
      ),
    );
  }

  Widget _buildErrorPlaceholder() {
    return Container(
      color: Colors.grey[100],
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            color: Colors.grey[400],
            size: 32,
          ),
          const SizedBox(height: 8),
          Text(
            'Error al cargar imagen',
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _pickImage({required bool isMain}) async {
    try {
      final source = await _showImageSourceDialog();
      if (source == null) return;

      setState(() {
        _isUploading = true;
      });

      final XFile? pickedFile = await _imagePicker.pickImage(
        source: source,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );

      if (pickedFile != null) {
        // En una implementación real, aquí subirías la imagen a Firebase Storage
        // Por ahora usamos la ruta local
        final imageUrl = await _uploadImageToStorage(pickedFile.path);
        
        if (isMain) {
          setState(() {
            _mainImageUrl = imageUrl;
          });
          widget.onMainImageSelected(imageUrl);
        } else {
          if (_additionalImages.length < widget.maxImages) {
            setState(() {
              _additionalImages.add(imageUrl);
            });
            widget.onImagesSelected(_additionalImages);
          }
        }
      }
    } catch (e) {
      _showErrorSnackBar('Error al seleccionar imagen: $e');
    } finally {
      setState(() {
        _isUploading = false;
      });
    }
  }

  Future<ImageSource?> _showImageSourceDialog() async {
    return showDialog<ImageSource>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Seleccionar imagen'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_camera),
              title: const Text('Cámara'),
              onTap: () => Navigator.pop(context, ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Galería'),
              onTap: () => Navigator.pop(context, ImageSource.gallery),
            ),
          ],
        ),
      ),
    );
  }

  Future<String> _uploadImageToStorage(String filePath) async {
    // TODO: Implementar subida real a Firebase Storage
    // Por ahora retornamos la ruta local para testing
    await Future.delayed(const Duration(seconds: 1)); // Simular subida
    
    // En producción sería algo como:
    // final ref = FirebaseStorage.instance.ref().child('images/${DateTime.now().millisecondsSinceEpoch}');
    // final uploadTask = ref.putFile(File(filePath));
    // final snapshot = await uploadTask;
    // return await snapshot.ref.getDownloadURL();
    
    return filePath; // Temporal para testing
  }

  void _removeMainImage() {
    setState(() {
      _mainImageUrl = null;
    });
    widget.onMainImageSelected(null);
  }

  void _removeAdditionalImage(int index) {
    setState(() {
      _additionalImages.removeAt(index);
    });
    widget.onImagesSelected(_additionalImages);
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}