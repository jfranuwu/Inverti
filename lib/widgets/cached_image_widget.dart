// Archivo: lib/widgets/cached_image_widget.dart
// Widget para imágenes con cache offline

import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

class CachedImageWidget extends StatelessWidget {
  final String imageUrl;
  final double? width;
  final double? height;
  final BoxFit fit;
  final String? placeholder;
  final Widget? errorWidget;
  final BorderRadius? borderRadius;
  final Color? backgroundColor;
  final bool showOfflineIndicator;

  const CachedImageWidget({
    super.key,
    required this.imageUrl,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.placeholder,
    this.errorWidget,
    this.borderRadius,
    this.backgroundColor,
    this.showOfflineIndicator = true,
  });

  @override
  Widget build(BuildContext context) {
    if (imageUrl.isEmpty) {
      return _buildErrorWidget(context);
    }

    return StreamBuilder<List<ConnectivityResult>>(
      stream: Connectivity().onConnectivityChanged,
      builder: (context, connectivitySnapshot) {
        // Verificar si hay conectividad (la lista no debe contener solo ConnectivityResult.none)
        final isOnline = connectivitySnapshot.hasData && 
                        connectivitySnapshot.data != null &&
                        !connectivitySnapshot.data!.contains(ConnectivityResult.none) &&
                        connectivitySnapshot.data!.isNotEmpty;

        return Container(
          width: width,
          height: height,
          decoration: BoxDecoration(
            color: backgroundColor ?? Colors.grey[100],
            borderRadius: borderRadius,
          ),
          child: ClipRRect(
            borderRadius: borderRadius ?? BorderRadius.zero,
            child: Stack(
              children: [
                CachedNetworkImage(
                  imageUrl: imageUrl,
                  width: width,
                  height: height,
                  fit: fit,
                  placeholder: (context, url) => _buildPlaceholder(context),
                  errorWidget: (context, url, error) => _buildErrorWidget(context),
                  fadeInDuration: const Duration(milliseconds: 300),
                  fadeOutDuration: const Duration(milliseconds: 100),
                  cacheKey: _generateCacheKey(imageUrl),
                ),
                
                if (showOfflineIndicator && !isOnline)
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.orange.withOpacity(0.9),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.cloud_off,
                            size: 12,
                            color: Colors.white,
                          ),
                          const SizedBox(width: 2),
                          Text(
                            'Cache',
                            style: TextStyle(
                              fontSize: 10,
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  String _generateCacheKey(String url) {
    return '${url.hashCode}_${width?.toInt() ?? 0}_${height?.toInt() ?? 0}';
  }

  Widget _buildPlaceholder(BuildContext context) {
    if (placeholder != null && placeholder!.isNotEmpty) {
      return Image.asset(
        placeholder!,
        width: width,
        height: height,
        fit: fit,
        errorBuilder: (context, error, stackTrace) {
          return _buildDefaultPlaceholder(context);
        },
      );
    }
    return _buildDefaultPlaceholder(context);
  }

  Widget _buildDefaultPlaceholder(BuildContext context) {
    return Container(
      width: width,
      height: height,
      color: Colors.grey[100],
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(
                Theme.of(context).primaryColor,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Cargando...',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorWidget(BuildContext context) {
    if (errorWidget != null) {
      return errorWidget!;
    }

    return Container(
      width: width,
      height: height,
      color: Colors.grey[200],
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.broken_image_outlined,
            size: 32,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 8),
          Text(
            'Imagen no\ndisponible',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }
}

class UserAvatarWidget extends StatelessWidget {
  final String? imageUrl;
  final String userName;
  final double size;
  final Color? backgroundColor;

  const UserAvatarWidget({
    super.key,
    this.imageUrl,
    required this.userName,
    this.size = 40,
    this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    if (imageUrl == null || imageUrl!.isEmpty) {
      return _buildInitialsAvatar(context);
    }

    return CachedImageWidget(
      imageUrl: imageUrl!,
      width: size,
      height: size,
      borderRadius: BorderRadius.circular(size / 2),
      backgroundColor: backgroundColor,
      showOfflineIndicator: false,
      errorWidget: _buildInitialsAvatar(context),
    );
  }

  Widget _buildInitialsAvatar(BuildContext context) {
    final initials = _getInitials(userName);
    
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: backgroundColor ?? _generateColorFromName(userName),
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Text(
          initials,
          style: TextStyle(
            color: Colors.white,
            fontSize: size * 0.4,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  String _getInitials(String name) {
    if (name.isEmpty) return '?';
    
    final words = name.trim().split(' ');
    if (words.length == 1) {
      return words[0].substring(0, 1).toUpperCase();
    }
    
    return '${words[0].substring(0, 1)}${words[1].substring(0, 1)}'.toUpperCase();
  }

  Color _generateColorFromName(String name) {
    final colors = [
      Colors.blue,
      Colors.green,
      Colors.purple,
      Colors.orange,
      Colors.teal,
      Colors.pink,
      Colors.indigo,
      Colors.red,
    ];
    
    final index = name.hashCode % colors.length;
    return colors[index.abs()];
  }
}

class ProjectImageWidget extends StatelessWidget {
  final String imageUrl;
  final double? width;
  final double? height;
  final VoidCallback? onTap;

  const ProjectImageWidget({
    super.key,
    required this.imageUrl,
    this.width,
    this.height,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: CachedImageWidget(
        imageUrl: imageUrl,
        width: width,
        height: height,
        borderRadius: BorderRadius.circular(12),
        placeholder: 'assets/images/ui/project_placeholder.png',
        fit: BoxFit.cover,
        errorWidget: Container(
          width: width,
          height: height,
          decoration: BoxDecoration(
            color: Colors.grey[200],
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.business_center_outlined,
                size: 32,
                color: Colors.grey[400],
              ),
              const SizedBox(height: 8),
              Text(
                'Proyecto\nsin imagen',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Clase auxiliar para gestionar conectividad de forma más robusta
class ConnectivityHelper {
  // Método estático para verificar conectividad
  static bool isOnline(List<ConnectivityResult>? connectivityResults) {
    if (connectivityResults == null || connectivityResults.isEmpty) {
      return false;
    }
    
    // Si la lista contiene solo ConnectivityResult.none, no hay conectividad
    if (connectivityResults.length == 1 && 
        connectivityResults.first == ConnectivityResult.none) {
      return false;
    }
    
    // Si hay cualquier tipo de conectividad (wifi, mobile, ethernet), está online
    return connectivityResults.any((result) => 
      result == ConnectivityResult.wifi ||
      result == ConnectivityResult.mobile ||
      result == ConnectivityResult.ethernet
    );
  }
  
  // Método para obtener el tipo de conectividad principal
  static String getConnectivityType(List<ConnectivityResult>? connectivityResults) {
    if (!isOnline(connectivityResults)) {
      return 'Sin conexión';
    }
    
    if (connectivityResults!.contains(ConnectivityResult.wifi)) {
      return 'WiFi';
    } else if (connectivityResults.contains(ConnectivityResult.mobile)) {
      return 'Datos móviles';
    } else if (connectivityResults.contains(ConnectivityResult.ethernet)) {
      return 'Ethernet';
    }
    
    return 'Conectado';
  }
}