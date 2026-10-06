import 'package:flutter/material.dart';

import '../core/app_theme.dart';

/// 加载中占位
class LoadingView extends StatelessWidget {
  final String? text;

  const LoadingView({super.key, this.text});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(
            width: 26,
            height: 26,
            child: CircularProgressIndicator(
              strokeWidth: 2.4,
              color: AppColors.primary,
            ),
          ),
          if (text != null) ...[
            const SizedBox(height: 12),
            Text(
              text!,
              style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
            ),
          ],
        ],
      ),
    );
  }
}

/// 加载失败 + 重试
class ErrorView extends StatelessWidget {
  final String message;
  final VoidCallback? onRetry;

  const ErrorView({super.key, required this.message, this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.cloud_off_outlined, size: 44, color: Color(0xFFCCCCCC)),
            const SizedBox(height: 14),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 13, height: 1.5, color: AppColors.textSecondary),
            ),
            if (onRetry != null) ...[
              const SizedBox(height: 16),
              OutlinedButton(
                onPressed: onRetry,
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.primary,
                  side: const BorderSide(color: AppColors.primary),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                  padding: const EdgeInsets.symmetric(horizontal: 22),
                ),
                child: const Text('重新加载'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// 空数据占位
class EmptyView extends StatelessWidget {
  final String text;
  final String? hint;

  const EmptyView({super.key, required this.text, this.hint});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.inbox_outlined, size: 44, color: Color(0xFFCCCCCC)),
          const SizedBox(height: 14),
          Text(
            text,
            style: const TextStyle(fontSize: 14, color: AppColors.textSecondary),
          ),
          if (hint != null) ...[
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40),
              child: Text(
                hint!,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 12, height: 1.5, color: Color(0xFFBBBBBB)),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
