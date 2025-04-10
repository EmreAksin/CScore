import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../services/cache_service.dart';
import '../utils/logger.dart';

class CachedImage extends StatelessWidget {
  final String imageUrl;
  final double? width;
  final double? height;
  final BoxFit fit;
  final Widget? placeholder;
  final Widget? errorWidget;
  final BorderRadius? borderRadius;
  final Color? backgroundColor;
  final Duration cacheRefreshInterval;
  final bool forcePrecache;

  const CachedImage({
    super.key,
    required this.imageUrl,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.placeholder,
    this.errorWidget,
    this.borderRadius,
    this.backgroundColor,
    this.cacheRefreshInterval = const Duration(days: 7),
    this.forcePrecache = false,
  });

  @override
  Widget build(BuildContext context) {
    if (imageUrl.isEmpty) {
      return _buildErrorWidget(context);
    }

    if (forcePrecache) {
      _precacheImage(context);
    }

    final Widget imageWidget = CachedNetworkImage(
      imageUrl: imageUrl,
      width: width,
      height: height,
      fit: fit,
      cacheManager: CacheService.imageCacheManager,
      fadeOutDuration: const Duration(milliseconds: 300),
      fadeInDuration: const Duration(milliseconds: 300),
      placeholderFadeInDuration: const Duration(milliseconds: 300),
      maxWidthDiskCache: 800, // Max genişlik için optimizasyon
      maxHeightDiskCache: 800, // Max yükseklik için optimizasyon
      placeholder: (context, url) => _buildPlaceholder(context),
      errorWidget: (context, url, error) => _buildErrorWidget(context),
    );

    // BorderRadius varsa ClipRRect ile sarmala
    if (borderRadius != null) {
      return Container(
        decoration: BoxDecoration(
          color: backgroundColor ?? Colors.transparent,
          borderRadius: borderRadius,
        ),
        child: ClipRRect(borderRadius: borderRadius!, child: imageWidget),
      );
    }

    return Container(color: backgroundColor, child: imageWidget);
  }

  Widget _buildPlaceholder(BuildContext context) {
    if (placeholder != null) {
      return placeholder!;
    }

    return Container(
      width: width,
      height: height,
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      child: Center(
        child: SizedBox(
          width: 24,
          height: 24,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
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
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      child: Icon(
        Icons.broken_image,
        color: Theme.of(context).colorScheme.onSurfaceVariant,
        size: 24,
      ),
    );
  }

  /// URL'nin önbellekte olup olmadığını kontrol eder
  static Future<bool> isInCache(String url) async {
    final fileInfo = await CacheService.imageCacheManager.getFileFromCache(url);
    return fileInfo != null;
  }

  /// URL'yi önbellekten siler
  static Future<void> removeFromCache(String url) async {
    await CacheService.imageCacheManager.removeFile(url);
  }

  /// URL'yi önbelleğe ekler (ön yükleme)
  static Future<void> preloadImage(String url) async {
    if (url.isEmpty) return;

    try {
      await CacheService.imageCacheManager.getSingleFile(url);
    } catch (e) {
      Logger.error('Görsel ön yüklemesi başarısız: $e');
    }
  }

  /// Birden fazla URL'yi önbelleğe ekler (batch ön yükleme)
  static Future<void> preloadImages(List<String> urls) async {
    for (final url in urls) {
      if (url.isNotEmpty) {
        preloadImage(url);
      }
    }
  }

  void _precacheImage(BuildContext context) {
    try {
      precacheImage(
        CachedNetworkImageProvider(imageUrl),
        context,
        onError: (e, stackTrace) {
          // Debug bilgisini kaldırdık, hata durumunda Logger kullanabiliriz
          Logger.error('Görsel ön yüklemesi başarısız: $e');
        },
      );
    } catch (e) {
      // Hata durumunu sadece kaydet, kullanıcıya gösterme
      Logger.error('Görsel ön yüklemesi başarısız: $e');
    }
  }
}
