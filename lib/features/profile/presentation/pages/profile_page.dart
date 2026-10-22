import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../app/theme/app_theme.dart';
import '../../../auth/models/auth_user.dart';
import '../../models/user.dart';
import '../cubit/profile_cubit.dart';
import 'edit_display_name_page.dart';
import '../../../../shared/presentation/widgets/flow_widgets.dart';
import '../../../../shared/presentation/widgets/page_header.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({required this.onSignOut, this.user, super.key});

  final Future<void> Function() onSignOut;
  final AuthUser? user;

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  @override
  Widget build(BuildContext context) {
    final profile = context.watch<ProfileCubit>().state.profile;
    final displayName = _displayName(widget.user, profile);
    final profileEmail = profile?.email?.trim();
    final authEmail = widget.user?.email?.trim();
    final email = profileEmail?.isNotEmpty == true ? profileEmail : authEmail;

    return CustomScrollView(
      key: const PageStorageKey('profile-page'),
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
          sliver: SliverList.list(
            children: [
              const PageHeader(
                title: 'Profile',
                subtitle: 'Your account and preferences.',
              ),
              const SizedBox(height: 20),
              SurfaceCard(
                child: Row(
                  children: [
                    _ProfileAvatar(
                      name: displayName,
                      photoUrl: widget.user?.photoUrl,
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            displayName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            email == null || email.isEmpty
                                ? 'No email address'
                                : email,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.muted,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            'UID: ${widget.user?.uid ?? 'Unavailable'}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 11,
                              color: AppColors.muted,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: widget.user == null
                          ? null
                          : () => _editDisplayName(context, displayName),
                      icon: const Icon(Icons.edit_outlined),
                      tooltip: 'Edit profile',
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 22),
              const SectionHeading(
                'Help & account',
                icon: Icons.help_outline_rounded,
              ),
              const SizedBox(height: 8),
              SurfaceCard(
                padding: EdgeInsets.zero,
                child: Column(
                  children: [
                    _SettingsRow(
                      icon: Icons.logout_rounded,
                      title: 'Sign out',
                      destructive: true,
                      onTap: () async {
                        try {
                          await widget.onSignOut();
                        } catch (_) {
                          if (context.mounted) {
                            _message(context, 'Unable to sign out. Try again.');
                          }
                        }
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _editDisplayName(
    BuildContext context,
    String currentName,
  ) async {
    final updated = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => BlocProvider.value(
          value: context.read<ProfileCubit>(),
          child: EditDisplayNamePage(
            uid: widget.user!.uid,
            initialDisplayName: currentName,
          ),
        ),
      ),
    );
    if (updated == true && context.mounted) {
      _message(context, 'Display name updated.');
    }
  }
}

class _ProfileAvatar extends StatelessWidget {
  const _ProfileAvatar({required this.name, this.photoUrl});

  final String name;
  final String? photoUrl;

  @override
  Widget build(BuildContext context) {
    final url = photoUrl?.trim();
    if (url == null || url.isEmpty) {
      return MemberAvatar(
        name: name,
        size: 60,
        color: const Color(0xFFD9E8FF),
        border: false,
      );
    }

    return ClipOval(
      child: Image.network(
        url,
        width: 60,
        height: 60,
        fit: BoxFit.cover,
        loadingBuilder: (context, child, progress) => progress == null
            ? child
            : MemberAvatar(
                name: name,
                size: 60,
                color: const Color(0xFFD9E8FF),
                border: false,
              ),
        errorBuilder: (context, error, stackTrace) => MemberAvatar(
          name: name,
          size: 60,
          color: const Color(0xFFD9E8FF),
          border: false,
        ),
      ),
    );
  }
}

String _displayName(AuthUser? user, UserProfile? profile) {
  final profileName = profile?.displayName.trim();
  if (profileName != null && profileName.isNotEmpty) return profileName;

  final displayName = user?.displayName?.trim();
  if (displayName != null && displayName.isNotEmpty) return displayName;

  final email = user?.email?.trim();
  if (email != null && email.isNotEmpty) return email.split('@').first;

  return 'PocketTogether member';
}

class _SettingsRow extends StatelessWidget {
  const _SettingsRow({
    required this.icon,
    required this.title,
    this.destructive = false,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final bool destructive;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = destructive ? AppColors.danger : AppColors.ink;
    return ListTile(
      onTap: onTap,
      leading: Icon(
        icon,
        color: destructive ? AppColors.danger : AppColors.primary,
        size: 21,
      ),
      title: Text(
        title,
        style: TextStyle(
          color: color,
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
      ),
      trailing: Icon(
        Icons.chevron_right_rounded,
        color: AppColors.muted.withValues(alpha: 0.7),
      ),
    );
  }
}

void _message(BuildContext context, String message) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(message)));
}
