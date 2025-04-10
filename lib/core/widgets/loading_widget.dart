import 'package:flutter/material.dart';
import '../theme/colors.dart';

class LoadingWidget extends StatelessWidget {
  final String? message;
  final bool isFullScreen;
  final double size;
  final Color? color;

  const LoadingWidget({
    super.key,
    this.message,
    this.isFullScreen = false,
    this.size = 40.0,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final loadingWidget = Column(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        SizedBox(
          width: size,
          height: size,
          child: CircularProgressIndicator(
            strokeWidth: 3.0,
            valueColor: AlwaysStoppedAnimation<Color>(
              color ?? AppColors.csAccent,
            ),
          ),
        ),
        if (message != null) ...[
          const SizedBox(height: 16),
          Text(
            message!,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: color ?? Theme.of(context).colorScheme.primary,
            ),
          ),
        ],
      ],
    );

    if (isFullScreen) {
      return Container(
        width: double.infinity,
        height: double.infinity,
        color: Colors.black.withAlpha(26),
        child: Center(
          child: Card(
            elevation: 4,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: loadingWidget,
            ),
          ),
        ),
      );
    }

    return Center(child: loadingWidget);
  }
}

class LoadingListWidget extends StatelessWidget {
  final bool isLoading;
  final Widget child;

  const LoadingListWidget({
    super.key,
    required this.isLoading,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        child,
        if (isLoading)
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 16.0),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface.withAlpha(179),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withAlpha(128),
                    blurRadius: 6,
                    offset: const Offset(0, -3),
                  ),
                ],
              ),
              child: const Center(child: LoadingWidget(size: 32)),
            ),
          ),
      ],
    );
  }
}
