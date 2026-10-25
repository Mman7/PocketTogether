import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../app/theme/app_theme.dart';
import '../../../../shared/presentation/widgets/flow_widgets.dart';
import '../cubit/room_cubit.dart';
import '../cubit/room_state.dart';
import 'room_created_page.dart';

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
