import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../app/theme/app_theme.dart';
import '../../../../shared/presentation/widgets/flow_widgets.dart';
import '../../models/room.dart';
import '../cubit/room_cubit.dart';
import '../cubit/room_state.dart';

class CreateRoomPage extends StatefulWidget {
  const CreateRoomPage({super.key});

  @override
  State<CreateRoomPage> createState() => _CreateRoomPageState();
}

class _CreateRoomPageState extends State<CreateRoomPage> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  String _currency = 'MYR';

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<RoomCubit, RoomState>(
      listenWhen: (previous, current) =>
          (previous.createdRoom == null && current.createdRoom != null) ||
          (previous.errorMessage == null && current.errorMessage != null),
      listener: (context, state) {
        final created = state.createdRoom;
        if (created != null) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute<void>(
              builder: (_) => RoomCreatedPage(
                roomName: created.room.name,
                currency: created.room.currency ?? _currency,
                inviteCode: created.invite.inviteCode,
                expiresAt: created.invite.expiresAt,
              ),
            ),
          );
        }
        final errorMessage = state.errorMessage;
        if (errorMessage != null) {
          ScaffoldMessenger.of(context)
              .showSnackBar(SnackBar(content: Text(errorMessage)));
        }
      },
      child: BlocBuilder<RoomCubit, RoomState>(
        builder: (context, state) => Scaffold(
          appBar: AppBar(
            title: const Text(
              'Create a room',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
            ),
          ),
          body: SafeArea(
            top: false,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 30),
              children: [
                const Text(
                  'Bring everyone’s spending together.',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 5),
                const Text(
                  'Set up a shared space. You can invite people next.',
                  style: TextStyle(color: AppColors.muted, fontSize: 13),
                ),
                const SizedBox(height: 22),
                Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      TextFormField(
                        controller: _name,
                        textCapitalization: TextCapitalization.words,
                        decoration: const InputDecoration(
                          labelText: 'Room name',
                          hintText: 'e.g. Weekend in Penang',
                          prefixIcon: Icon(Icons.groups_outlined),
                        ),
                        validator: (value) =>
                            value == null || value.trim().isEmpty
                            ? 'Give your room a name'
                            : null,
                      ),
                      const SizedBox(height: 14),
                      DropdownButtonFormField<String>(
                        initialValue: _currency,
                        decoration: const InputDecoration(
                          labelText: 'Room currency',
                          prefixIcon: Icon(Icons.currency_exchange_rounded),
                        ),
                        items: const [
                          DropdownMenuItem(
                            value: 'MYR',
                            child: Text('MYR · Malaysian Ringgit'),
                          ),
                          DropdownMenuItem(
                            value: 'JPY',
                            child: Text('JPY · Japanese Yen'),
                          ),
                          DropdownMenuItem(
                            value: 'THB',
                            child: Text('THB · Thai Baht'),
                          ),
                        ],
                        onChanged: (value) =>
                            setState(() => _currency = value ?? _currency),
                      ),
                      const SizedBox(height: 14),
                    ],
                  ),
                ),
                const SizedBox(height: 18),
                SurfaceCard(
                  color: AppColors.paleBlue,
                  child: const Row(
                    children: [
                      Icon(
                        Icons.info_outline_rounded,
                        color: AppColors.primary,
                      ),
                      SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Everyone in the room will use the same currency. You can still track other currencies in a different room.',
                          style: TextStyle(fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                PrimaryButton(
                  label: state.isLoading ? 'Creating room…' : 'Create room',
                  icon: state.isLoading
                      ? Icons.hourglass_top_rounded
                      : Icons.add_rounded,
                  onPressed: state.isLoading ? null : () => _submit(context),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _submit(BuildContext context) async {
    if (!_formKey.currentState!.validate()) return;
    await context.read<RoomCubit>().createRoom(
      name: _name.text.trim(),
      currency: _currency,
    );
  }
}

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
    return Scaffold(
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
                    'Expires ${_formatExpiry(expiresAt)}',
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
    );
  }
}

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
              'You’re invited.',
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
              child: Column(
                children: [
                  TextFormField(
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
                            !RegExp(r'^[A-Za-z0-9]{6,8}$')
                                .hasMatch(value.trim())
                        ? 'Enter the 8-character invite code'
                        : null,
                  ),
                ],
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

String _formatExpiry(DateTime value) {
  final local = value.toLocal();
  final day = local.day.toString().padLeft(2, '0');
  final month = local.month.toString().padLeft(2, '0');
  final hour = local.hour.toString().padLeft(2, '0');
  final minute = local.minute.toString().padLeft(2, '0');
  return '$day/$month/${local.year} at $hour:$minute';
}
