import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../app/theme/app_theme.dart';
import '../../../../shared/presentation/widgets/flow_widgets.dart';
import '../../models/room.dart';
import '../cubit/room_cubit.dart';

class JoinRoomPage extends StatefulWidget {
  const JoinRoomPage({required this.onJoined, super.key});

  final void Function(Room room) onJoined;

  @override
  State<JoinRoomPage> createState() => _JoinRoomPageState();
}

class _JoinRoomPageState extends State<JoinRoomPage> {
  final _formKey = GlobalKey<FormState>();
  final _inviteCode = TextEditingController();
  String? _inviteError;
  bool _loading = false;

  @override
  void dispose() {
    _inviteCode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Join a room',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
        ),
      ),
      body: SafeArea(
        top: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
          children: [
            const Text(
              "You're invited.",
              style: TextStyle(fontSize: 25, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 5),
            const Text(
              'Enter the invite code shared by a room member.',
              style: TextStyle(fontSize: 13, color: AppColors.muted),
            ),
            const SizedBox(height: 21),
            Form(
              key: _formKey,
              child: TextFormField(
                controller: _inviteCode,
                textCapitalization: TextCapitalization.characters,
                onChanged: (_) => setState(() => _inviteError = null),
                decoration: InputDecoration(
                  labelText: 'Invite code',
                  hintText: 'e.g. ABCD2345',
                  prefixIcon: const Icon(Icons.key_rounded),
                  errorText: _inviteError,
                ),
                validator: (value) =>
                    value == null ||
                        !RegExp(r'^[A-Za-z0-9]{6,8}$').hasMatch(value.trim())
                    ? 'Enter the 8-character invite code'
                    : null,
              ),
            ),
            const SizedBox(height: 12),
            SurfaceCard(
              color: AppColors.paleBlue,
              child: const Row(
                children: [
                  Icon(Icons.info_outline_rounded, color: AppColors.primary),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'The invite code identifies the room and confirms you were invited.',
                      style: TextStyle(fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 22),
            PrimaryButton(
              label: _loading ? 'Joining room…' : 'Join room',
              icon: _loading
                  ? Icons.hourglass_top_rounded
                  : Icons.login_rounded,
              onPressed: _loading ? null : _join,
            ),
            const SizedBox(height: 10),
            OutlinedButton.icon(
              onPressed: () => Navigator.pop(context),
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
    );
  }

  Future<void> _join() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      final cubit = context.read<RoomCubit>();
      final result = await cubit.joinRoom(
        inviteCode: _inviteCode.text.trim().toUpperCase(),
      );
      if (!mounted) return;
      if (result == null) {
        setState(
          () => _inviteError =
              cubit.state.joinErrorMessage ?? 'Unable to join this room.',
        );
        return;
      }
      Navigator.pop(context);
      widget.onJoined(result.room);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }
}
