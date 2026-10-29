import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pocket_together/shared/presentation/widgets/ambient_background.dart';

import '../../../../app/theme/app_theme.dart';
import '../../../../shared/presentation/widgets/flow_widgets.dart';

class RoomCreatedPage extends StatelessWidget {
  const RoomCreatedPage({
    required this.roomName,
    required this.currency,
    required this.inviteCode,
    required this.expiresAt,
    super.key,
  });

  final String roomName;
  final String currency;
  final String inviteCode;
  final DateTime expiresAt;

  @override
  Widget build(BuildContext context) {
    return AmbientBackground(
      child: Scaffold(
        appBar: AppBar(
          leading: IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.close_rounded),
            tooltip: 'Close',
          ),
        ),
        body: SafeArea(
          top: false,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(22, 16, 22, 28),
            children: [
              Container(
                width: 58,
                height: 58,
                decoration: const BoxDecoration(
                  color: AppColors.paleCyan,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check_rounded,
                  size: 30,
                  color: AppColors.success,
                ),
              ),
              const SizedBox(height: 18),
              const Text(
                'Your room is ready',
                style: TextStyle(fontSize: 27, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 5),
              Text(
                '$roomName is set up. Share this invite code with your group.',
                style: const TextStyle(color: AppColors.muted),
              ),
              const SizedBox(height: 18),
              SurfaceCard(
                padding: const EdgeInsets.all(17),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'INVITE CODE',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        color: AppColors.muted,
                      ),
                    ),
                    const SizedBox(height: 7),
                    Row(
                      children: [
                        Expanded(
                          child: SelectableText(
                            inviteCode,
                            style: const TextStyle(
                              fontSize: 25,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                        IconButton.filledTonal(
                          tooltip: 'Copy invite code',
                          onPressed: () async {
                            await Clipboard.setData(
                              ClipboardData(text: inviteCode),
                            );
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Invite code copied.'),
                                ),
                              );
                            }
                          },
                          icon: const Icon(Icons.copy_rounded, size: 18),
                        ),
                      ],
                    ),
                    Text(
                      'Expires ${formatRoomInviteExpiry(expiresAt)}',
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.muted,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              SurfaceCard(
                child: Row(
                  children: [
                    const Icon(
                      Icons.currency_exchange_rounded,
                      color: AppColors.primary,
                    ),
                    const SizedBox(width: 10),
                    const Expanded(
                      child: Text(
                        'Room currency',
                        style: TextStyle(color: AppColors.muted),
                      ),
                    ),
                    Text(
                      currency,
                      style: const TextStyle(fontWeight: FontWeight.w800),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              OutlinedButton.icon(
                onPressed: () =>
                    Navigator.popUntil(context, (route) => route.isFirst),
                icon: const Icon(Icons.arrow_back_rounded),
                label: const Text('Back to rooms'),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(0, 49),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppRadii.control),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

String formatRoomInviteExpiry(DateTime value) {
  final local = value.toLocal();
  final day = local.day.toString().padLeft(2, '0');
  final month = local.month.toString().padLeft(2, '0');
  final hour = local.hour.toString().padLeft(2, '0');
  final minute = local.minute.toString().padLeft(2, '0');
  return '$day/$month/${local.year} at $hour:$minute';
}
