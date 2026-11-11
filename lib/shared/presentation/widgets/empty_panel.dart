import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

import '../../../app/theme/app_theme.dart';
import 'flow_widgets.dart';

class EmptyPanel extends StatelessWidget {
  const EmptyPanel({
    required this.title,
    required this.message,
    this.compact = false,
    super.key,
  });

  final String title;
  final String message;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return SurfaceCard(
      padding: EdgeInsets.all(compact ? 15 : 24),
      child: Row(
        children: [
          Lottie.asset('assets/lottie/no_result.lottie', width: 70, height: 70),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 2),
                Text(
                  message,
                  style: const TextStyle(fontSize: 11, color: AppColors.muted),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
