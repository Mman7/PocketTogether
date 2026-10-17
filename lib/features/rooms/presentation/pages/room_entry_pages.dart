import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter/services.dart';

import '../../../../app/theme/app_theme.dart';
import '../../../../shared/presentation/widgets/flow_widgets.dart';
import '../cubit/room_cubit.dart';
import '../cubit/room_state.dart';

class CreateRoomPage extends StatefulWidget {
  const CreateRoomPage({required this.ownerId, super.key});

  final String ownerId;

  @override
  State<CreateRoomPage> createState() => _CreateRoomPageState();
}

class _CreateRoomPageState extends State<CreateRoomPage> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  String _currency = 'MYR';
  String _expiration = '7 days';

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<RoomCubit, RoomState>(
      listener: (context, state) {
        final room = state.createdRoom;
        if (room != null) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute<void>(
              builder: (_) => RoomCreatedPage(
                roomName: room.name,
                roomId: room.id,
                currency: room.currency ?? _currency,
                expiration: _expiration,
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
                      DropdownButtonFormField<String>(
                        initialValue: _expiration,
                        decoration: const InputDecoration(
                          labelText: 'Invite expires after',
                          prefixIcon: Icon(Icons.timer_outlined),
                        ),
                        items: const [
                          DropdownMenuItem(
                            value: '24 hours',
                            child: Text('24 hours'),
                          ),
                          DropdownMenuItem(
                            value: '7 days',
                            child: Text('7 days'),
                          ),
                          DropdownMenuItem(
                            value: '30 days',
                            child: Text('30 days'),
                          ),
                          DropdownMenuItem(
                            value: 'Never',
                            child: Text('Never'),
                          ),
                        ],
                        onChanged: (value) =>
                            setState(() => _expiration = value ?? _expiration),
                      ),
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
      ownerId: widget.ownerId,
      name: _name.text.trim(),
      currency: _currency,
    );
  }
}

class RoomCreatedPage extends StatelessWidget {
  const RoomCreatedPage({
    required this.roomName,
    required this.roomId,
    required this.currency,
    required this.expiration,
    super.key,
  });

  final String roomName;
  final String roomId;
  final String currency;
  final String expiration;

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
              '$roomName is set up. Share these codes with your crew.',
              style: const TextStyle(color: AppColors.muted),
            ),
            const SizedBox(height: 23),
            _CodeCard(
              label: 'ROOM CODE',
              code: roomId,
              helper: 'Use this to find your room',
            ),
            const SizedBox(height: 12),
            _CodeCard(
              label: 'INVITE CODE',
              code: 'FLOW-72MX',
              helper: 'Expires in $expiration',
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
            PrimaryButton(
              label: 'Share invite',
              icon: Icons.ios_share_rounded,
              onPressed: () =>
                  _message(context, 'Invite details are ready to share.'),
            ),
            const SizedBox(height: 9),
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

class _CodeCard extends StatelessWidget {
  const _CodeCard({
    required this.label,
    required this.code,
    required this.helper,
  });

  final String label;
  final String code;
  final String helper;

  @override
  Widget build(BuildContext context) {
    return SurfaceCard(
      padding: const EdgeInsets.all(17),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
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
                  code,
                  style: const TextStyle(
                    fontSize: 25,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              IconButton.filledTonal(
                tooltip: 'Copy $label',
                onPressed: () async {
                  await Clipboard.setData(ClipboardData(text: code));
                  if (context.mounted) _message(context, '$label copied.');
                },
                icon: const Icon(Icons.copy_rounded, size: 18),
              ),
            ],
          ),
          Text(
            helper,
            style: const TextStyle(fontSize: 11, color: AppColors.muted),
          ),
        ],
      ),
    );
  }
}

class JoinRoomPage extends StatefulWidget {
  const JoinRoomPage({super.key});

  @override
  State<JoinRoomPage> createState() => _JoinRoomPageState();
}

class _JoinRoomPageState extends State<JoinRoomPage> {
  final _formKey = GlobalKey<FormState>();
  final _roomCode = TextEditingController();
  final _inviteCode = TextEditingController();
  String? _roomError;
  String? _inviteError;
  bool _loading = false;

  @override
  void dispose() {
    _roomCode.dispose();
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
              'Enter both codes from your room owner to join the shared ledger.',
              style: TextStyle(fontSize: 13, color: AppColors.muted),
            ),
            const SizedBox(height: 21),
            Form(
              key: _formKey,
              child: Column(
                children: [
                  TextFormField(
                    controller: _roomCode,
                    textCapitalization: TextCapitalization.characters,
                    onChanged: (_) => setState(() => _roomError = null),
                    decoration: InputDecoration(
                      labelText: 'Room code',
                      hintText: 'e.g. JP4K8D',
                      prefixIcon: const Icon(Icons.tag_rounded),
                      errorText: _roomError,
                    ),
                    validator: (value) =>
                        value == null || value.trim().length < 4
                        ? 'Enter the room code from your invite'
                        : null,
                  ),
                  const SizedBox(height: 13),
                  TextFormField(
                    controller: _inviteCode,
                    textCapitalization: TextCapitalization.characters,
                    onChanged: (_) => setState(() => _inviteError = null),
                    decoration: InputDecoration(
                      labelText: 'Invite code',
                      hintText: 'Enter your invite code',
                      prefixIcon: const Icon(Icons.key_rounded),
                      errorText: _inviteError,
                    ),
                    validator: (value) =>
                        value == null || value.trim().length < 4
                        ? 'Enter the invite code from your owner'
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
                      'Room codes help find the right group. Invite codes confirm you were invited.',
                      style: TextStyle(fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),
            if (_inviteCode.text.toUpperCase() == 'EXPIRED') ...[
              const SizedBox(height: 12),
              const _InlineError(
                title: 'Invite expired',
                message: 'Ask the room owner to send a fresh invite code.',
              ),
            ],
            const SizedBox(height: 22),
            PrimaryButton(
              label: _loading ? 'Checking invite…' : 'Join room',
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

  void _join() {
    if (!_formKey.currentState!.validate()) return;
    final room = _roomCode.text.trim().toUpperCase();
    final invite = _inviteCode.text.trim().toUpperCase();
    if (room != 'JP4K8D') {
      setState(
        () => _roomError =
            'We couldn’t find that room code. Check it and try again.',
      );
      return;
    }
    if (invite == 'EXPIRED') {
      setState(
        () => _inviteError = 'This invite has expired. Ask for a new one.',
      );
      return;
    }
    if (invite != 'TOKYO24') {
      setState(
        () => _inviteError =
            'That invite code is invalid. Check with the room owner.',
      );
      return;
    }
    setState(() => _loading = true);
    Future<void>.delayed(const Duration(milliseconds: 350), () {
      if (!mounted) return;
      setState(() => _loading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('You joined Japan Trip in this preview.')),
      );
      Navigator.pop(context);
    });
  }
}

class _InlineError extends StatelessWidget {
  const _InlineError({required this.title, required this.message});

  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    return SurfaceCard(
      color: const Color(0xFFFFF0F0),
      child: Row(
        children: [
          const Icon(Icons.error_outline_rounded, color: AppColors.danger),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
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

void _message(BuildContext context, String text) {
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
}
