import 'package:flutter/material.dart';
import '../theme/colors.dart';
import '../theme/text_styles.dart';

class ErrorDisplayWidget extends StatelessWidget {
  final String title;
  final String? message;
  final VoidCallback? onRetry;
  final IconData icon;
  final bool isFullScreen;

  const ErrorDisplayWidget({
    super.key,
    this.title = 'Bir hata oluştu',
    this.message,
    this.onRetry,
    this.icon = Icons.error_outline,
    this.isFullScreen = false,
  });

  @override
  Widget build(BuildContext context) {
    final errorWidget = Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 64, color: AppColors.csWarn),
        const SizedBox(height: 16),
        Text(
          title,
          textAlign: TextAlign.center,
          style: AppTextStyles.headline5.copyWith(
            fontWeight: FontWeight.bold,
            color: Theme.of(context).colorScheme.error,
          ),
        ),
        if (message != null) ...[
          const SizedBox(height: 8),
          Text(
            message!,
            textAlign: TextAlign.center,
            style: AppTextStyles.bodyText2.copyWith(
              color: Theme.of(context).colorScheme.onSurface.withAlpha(179),
            ),
          ),
        ],
        if (onRetry != null) ...[
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh),
            label: const Text('Tekrar Dene'),
            style: ElevatedButton.styleFrom(
              foregroundColor: Colors.white,
              backgroundColor: AppColors.csAccent,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30),
              ),
            ),
          ),
        ],
      ],
    );

    if (isFullScreen) {
      return Container(
        width: double.infinity,
        height: double.infinity,
        color: Theme.of(context).colorScheme.surface,
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: errorWidget,
          ),
        ),
      );
    }

    return Center(
      child: Padding(padding: const EdgeInsets.all(16.0), child: errorWidget),
    );
  }
}

class NetworkErrorWidget extends StatelessWidget {
  final VoidCallback? onRetry;
  final bool isFullScreen;

  const NetworkErrorWidget({
    super.key,
    this.onRetry,
    this.isFullScreen = false,
  });

  @override
  Widget build(BuildContext context) {
    return ErrorDisplayWidget(
      title: 'Bağlantı Hatası',
      message: 'İnternet bağlantınızı kontrol edin ve tekrar deneyin.',
      icon: Icons.wifi_off,
      onRetry: onRetry,
      isFullScreen: isFullScreen,
    );
  }
}

class NoDataWidget extends StatelessWidget {
  final String message;
  final IconData icon;
  final VoidCallback? onAction;
  final String? actionLabel;

  const NoDataWidget({
    super.key,
    this.message = 'Görüntülenecek veri bulunamadı',
    this.icon = Icons.inbox,
    this.onAction,
    this.actionLabel,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 64, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            Text(
              message,
              textAlign: TextAlign.center,
              style: AppTextStyles.headline6.copyWith(
                color: Theme.of(context).colorScheme.onSurface.withAlpha(179),
              ),
            ),
            if (onAction != null && actionLabel != null) ...[
              const SizedBox(height: 24),
              OutlinedButton(
                onPressed: onAction,
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                  side: const BorderSide(color: AppColors.csAccent),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                ),
                child: Text(actionLabel!),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
