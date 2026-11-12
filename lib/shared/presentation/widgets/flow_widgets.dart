import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:lottie/lottie.dart';

import '../../../app/theme/app_theme.dart';

/// A bordered surface with optional gradient, shadow, and tap handling.
class SurfaceCard extends StatelessWidget {
  const SurfaceCard({
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.color = AppColors.white,
    this.gradient,
    this.shadowColor = const Color(0x080F172A),
    this.borderColor = AppColors.border,
    this.radius = AppRadii.card,
    this.onTap,
    super.key,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final Color color;
  final Gradient? gradient;
  final Color shadowColor;
  final Color borderColor;
  final double radius;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: gradient == null ? color : Colors.transparent,
      borderRadius: BorderRadius.circular(radius),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(radius),
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            gradient: gradient,
            border: Border.all(color: borderColor),
            borderRadius: BorderRadius.circular(radius),
            boxShadow: [
              BoxShadow(
                color: shadowColor,
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: child,
        ),
      ),
    );
  }
}

/// Displays a deterministic Clay avatar for a member.
class MemberAvatar extends StatelessWidget {
  const MemberAvatar({
    required this.name,
    this.size = 34,
    this.color = AppColors.paleBlue,
    this.border = true,
    super.key,
  });

  final String name;
  final double size;
  final Color color;
  final bool border;

  @override
  Widget build(BuildContext context) {
    final avatarUri = Uri.https('api.dicebear.com', '/10.x/clay/svg', {
      'seed': name,
      'backgroundColor': 'e2ecf4',
    });
    final fallback = _InitialsAvatar(name: name, size: size, color: color);

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(shape: BoxShape.circle),
      clipBehavior: Clip.antiAlias,
      child: SvgPicture.network(
        avatarUri.toString(),
        width: size,
        height: size,
        fit: BoxFit.cover,
        placeholderBuilder: (_) => fallback,
        errorBuilder: (_, _, _) => fallback,
      ),
    );
  }
}

class _InitialsAvatar extends StatelessWidget {
  const _InitialsAvatar({
    required this.name,
    required this.size,
    required this.color,
  });

  final String name;
  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final initials = name
        .split(' ')
        .map((part) => part.isEmpty ? '' : part[0])
        .take(2)
        .join()
        .toUpperCase();

    return Container(
      width: size,
      height: size,
      color: color,
      alignment: Alignment.center,
      child: Text(
        initials,
        style: TextStyle(
          color: AppColors.ink,
          fontWeight: FontWeight.w700,
          fontSize: size * 0.32,
        ),
      ),
    );
  }
}

/// Shows a compact, capped list of member avatars with an overflow count.
class AvatarStack extends StatelessWidget {
  const AvatarStack({required this.names, this.maxVisible = 4, super.key});

  final List<String> names;
  final int maxVisible;

  @override
  Widget build(BuildContext context) {
    final visible = names.take(maxVisible).toList();
    return SizedBox(
      height: 34,
      width: visible.length * 24 + 10,
      child: Stack(
        children: [
          for (var index = 0; index < visible.length; index++)
            Positioned(
              left: index * 22,
              child: MemberAvatar(
                name: visible[index],
                size: 34,
                color: [
                  AppColors.paleBlue,
                  AppColors.paleCyan,
                  const Color(0xFFFFEAD8),
                  const Color(0xFFE9E4FF),
                ][index % 4],
              ),
            ),
          if (names.length > maxVisible)
            Positioned(
              left: visible.length * 22,
              child: Container(
                width: 32,
                height: 32,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: AppColors.paleBlue,
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.white, width: 2),
                ),
                child: Text(
                  '+${names.length - maxVisible}',
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Standard primary action button used by form and mutation flows.
///
/// When [loading] is true, the action remains visually occupied by a spinner
/// and callers should pass a null [onPressed] to prevent duplicate submits.
class PrimaryButton extends StatelessWidget {
  const PrimaryButton({
    required this.label,
    required this.onPressed,
    this.icon,
    this.loading = false,
    this.expand = true,
    this.backgroundColor = AppColors.primary,
    this.foregroundColor = AppColors.white,
    super.key,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool loading;
  final bool expand;
  final Color backgroundColor;
  final Color foregroundColor;

  @override
  Widget build(BuildContext context) {
    final button = FilledButton.icon(
      onPressed: onPressed,
      icon: loading
          ? const SizedBox.square(
              dimension: 19,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : Icon(icon ?? Icons.arrow_forward_rounded, size: 19),
      label: Text(label),
      style: FilledButton.styleFrom(
        minimumSize: const Size(0, 50),
        backgroundColor: backgroundColor,
        foregroundColor: foregroundColor,
        disabledBackgroundColor: AppColors.border,
        disabledForegroundColor: AppColors.muted,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadii.control),
        ),
        textStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
      ),
    );
    return expand ? SizedBox(width: double.infinity, child: button) : button;
  }
}

class SectionHeading extends StatelessWidget {
  const SectionHeading(
    this.title, {
    required this.icon,
    this.iconColors,
    this.trailing,
    super.key,
  });

  final String title;
  final Widget? trailing;
  final IconData icon;
  final Color? iconColors;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 24, color: iconColors ?? AppColors.primary),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            title,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
          ),
        ),
        ?trailing,
      ],
    );
  }
}

class StatusPill extends StatelessWidget {
  const StatusPill({
    required this.label,
    this.color = AppColors.paleBlue,
    this.textColor,
    super.key,
  });

  final String label;
  final Color color;
  final Color? textColor;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(AppRadii.pill),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: textColor ?? Colors.black.withValues(alpha: 0.3),
          ),
        ),
      ),
    );
  }
}

class EmptyState extends StatelessWidget {
  const EmptyState({
    required this.title,
    required this.message,
    this.actionLabel,
    this.onAction,
    super.key,
  });

  final String title;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Lottie.asset(
          'assets/lottie/no_result.lottie',
          width: 100,
          height: 100,
          fit: BoxFit.cover,
        ),
        const SizedBox(height: 9),
        Text(title, style: const TextStyle(fontWeight: FontWeight.w800)),
        const SizedBox(height: 4),
        Text(
          message,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 12, color: AppColors.muted),
        ),
        if (actionLabel != null) ...[
          const SizedBox(height: 12),
          TextButton(onPressed: onAction, child: Text(actionLabel!)),
        ],
      ],
    );
  }
}

class ErrorState extends StatelessWidget {
  const ErrorState({
    required this.title,
    required this.message,
    this.onRetry,
    super.key,
  });

  final String title;
  final String message;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    return SurfaceCard(
      color: const Color(0xFFFFF1F1),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.error_outline_rounded, color: AppColors.danger),
          const SizedBox(width: 11),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 3),
                Text(
                  message,
                  style: const TextStyle(fontSize: 12, color: AppColors.muted),
                ),
                if (onRetry != null)
                  Align(
                    alignment: Alignment.centerLeft,
                    child: TextButton(
                      onPressed: onRetry,
                      child: const Text('Try again'),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class LoadingState extends StatelessWidget {
  const LoadingState({
    this.message = 'Loading your shared finances…',
    super.key,
  });

  final String message;

  @override
  Widget build(BuildContext context) {
    return SurfaceCard(
      child: Row(
        children: [
          const SizedBox(
            width: 22,
            height: 22,
            child: CircularProgressIndicator(strokeWidth: 2.4),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(color: AppColors.muted, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }
}
