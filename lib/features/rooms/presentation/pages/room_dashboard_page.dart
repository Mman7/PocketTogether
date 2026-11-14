import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pocket_together/shared/presentation/widgets/ambient_background.dart';

import '../../../../app/theme/app_theme.dart';
import '../../../../shared/presentation/money_format.dart';
import '../../../../shared/presentation/widgets/flow_widgets.dart';
import '../../../expenses/data/expense_repository.dart';
import '../../../expenses/models/expense.dart';
import '../../../expenses/presentation/cubit/expense_cubit.dart';
import '../../../expenses/presentation/cubit/expense_state.dart';
import '../../../expenses/presentation/pages/add_expense_page.dart';
import '../../../expenses/presentation/pages/expense_detail_page.dart';
import '../../data/room_repository.dart';
import '../../data/room_activity_repository.dart';
import '../../models/room.dart';
import '../../models/room_member.dart';
import 'room_members_page.dart';
import 'room_expense_history_page.dart';
import 'room_statistics_page.dart';
import 'room_activity_page.dart';
import '../widgets/room_actions_drawer.dart';
import '../widgets/room_expenses_section.dart';

class RoomDashboardPage extends StatefulWidget {
  const RoomDashboardPage({
    required this.room,
    required this.currentUserId,
    required this.currentUserDisplayName,
    required this.roomRepository,
    required this.expenseRepository,
    required this.activityRepository,
    required this.onDeleted,
    super.key,
  });

  final Room room;
  final String currentUserId;
  final String currentUserDisplayName;
  final RoomRepository roomRepository;
  final ExpenseRepository expenseRepository;
  final RoomActivityRepository activityRepository;
  final VoidCallback onDeleted;

  @override
  State<RoomDashboardPage> createState() => _RoomDashboardPageState();
}

class _RoomDashboardPageState extends State<RoomDashboardPage> {
  late final ExpenseCubit _expenseCubit;
  late Future<List<RoomMember>> _membersFuture;
  String _roomName = '';
  bool _creatingInvite = false;
  bool _removingMember = false;
  bool _deletingRoom = false;
  bool _renamingRoom = false;

  @override
  void initState() {
    super.initState();
    _expenseCubit = ExpenseCubit(widget.expenseRepository)
      ..loadExpenses(widget.room.id);
    _membersFuture = widget.roomRepository.getRoomMembers(widget.room.id);
    _roomName = widget.room.name;
  }

  @override
  void dispose() {
    _expenseCubit.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _expenseCubit,
      child: BlocBuilder<ExpenseCubit, ExpenseState>(
        builder: (context, state) => FutureBuilder<List<RoomMember>>(
          future: _membersFuture,
          builder: (context, memberSnapshot) => _buildDashboard(
            context,
            state,
            memberSnapshot.data ?? const [],
            memberSnapshot,
          ),
        ),
      ),
    );
  }

  Widget _buildDashboard(
    BuildContext context,
    ExpenseState state,
    List<RoomMember> members,
    AsyncSnapshot<List<RoomMember>> memberSnapshot,
  ) {
    final now = DateTime.now();
    final today = state.expenses.where((expense) {
      final date = expense.expenseDate;
      return date.year == now.year &&
          date.month == now.month &&
          date.day == now.day;
    }).toList();
    final total = state.expenses
        .where((expense) {
          final date = expense.expenseDate;
          return date.year == now.year &&
              date.month == now.month &&
              date.day == now.day;
        })
        .fold<int>(0, (sum, expense) => sum + expense.amountInCents);
    return Scaffold(
      appBar: AppBar(
        titleSpacing: 0,
        title: Row(
          children: [
            Flexible(
              child: Text(
                _roomName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ],
        ),
        actions: [
          if (widget.room.ownerId == widget.currentUserId)
            Builder(
              builder: (scaffoldContext) => IconButton(
                onPressed: _deletingRoom
                    ? null
                    : () => Scaffold.of(scaffoldContext).openEndDrawer(),
                icon: const Icon(Icons.more_vert_rounded),
                tooltip: 'Room actions',
              ),
            ),
        ],
      ),
      endDrawer: widget.room.ownerId == widget.currentUserId
          ? RoomActionsDrawer(
              roomName: _roomName,
              creatingInvite: _creatingInvite,
              removingMember: _removingMember,
              deletingRoom: _deletingRoom,
              onGenerateInvite: _showInviteCode,
              onRemoveMember: () => _showRemoveMemberDialog(members),
              onDeleteRoom: _confirmDeleteRoom,
              onRenameRoom: _showRenameRoomDialog,
              renamingRoom: _renamingRoom,
            )
          : null,
      body: ListView(
        padding: const EdgeInsets.fromLTRB(18, 8, 18, 90),
        children: [
          SurfaceCard(
            padding: const EdgeInsets.all(17),
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF2168EE), Color(0xFF388BFA)],
            ),
            shadowColor: Color(0x332373F4),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Expanded(
                      child: Text(
                        "Today's spending",
                        style: TextStyle(color: Colors.white70, fontSize: 12),
                      ),
                    ),
                    StatusPill(
                      label: _todayLabel,
                      color: Colors.white24,
                      textColor: Colors.white,
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  formatCurrency(total, currency: widget.room.currency),
                  style: const TextStyle(
                    color: AppColors.white,
                    fontSize: 33,
                    fontWeight: FontWeight.w800,
                    fontFeatures: [FontFeature.tabularFigures()],
                  ),
                ),
                const SizedBox(height: 14),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(13),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 11),
                  child: Row(
                    children: [
                      _Metric(
                        icon: Icons.today,
                        label: 'Today',
                        value: formatCurrency(
                          today.fold<int>(
                            0,
                            (sum, expense) => sum + expense.amountInCents,
                          ),
                          currency: widget.room.currency,
                        ),
                      ),
                      const SizedBox(
                        height: 68,
                        child: VerticalDivider(
                          color: Colors.white24,
                          thickness: 1,
                          width: 12,
                          endIndent: 8,
                          indent: 8,
                        ),
                      ),
                      _Metric(
                        icon: Icons.groups_outlined,
                        label: 'Members',
                        value: '${members.length}',
                      ),
                      const SizedBox(
                        height: 68,
                        child: VerticalDivider(
                          color: Colors.white24,
                          thickness: 1,
                          width: 12,
                          endIndent: 8,
                          indent: 8,
                        ),
                      ),
                      _Metric(
                        icon: Icons.receipt_long_outlined,
                        label: 'Expenses',
                        value: '${state.expenses.length}',
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              for (final action in const [
                _QuickAction('Members', Icons.groups_outlined),
                _QuickAction('Stats', Icons.bar_chart_rounded),
                _QuickAction('History', Icons.bar_chart_rounded),
                _QuickAction('Activity', Icons.bar_chart_rounded),
              ])
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 6),
                    child: Material(
                      color: Colors.transparent,
                      borderRadius: BorderRadius.circular(12),
                      child: InkWell(
                        onTap: () => _openSection(action.label, members),
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.1),
                                blurRadius: 10,
                                offset: const Offset(0, 2),
                              ),
                            ],
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                width: 40,
                                height: 40,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: AppColors.primary.withAlpha(20),
                                ),
                                child: Icon(
                                  action.icon,
                                  size: 20,
                                  color: AppColors.primary,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                action.label,
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          if (state.errorMessage != null)
            SurfaceCard(
              child: Column(
                children: [
                  Text(state.errorMessage!, textAlign: TextAlign.center),
                  TextButton.icon(
                    onPressed: () => _expenseCubit.loadExpenses(widget.room.id),
                    icon: const Icon(Icons.refresh_rounded),
                    label: const Text('Retry'),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 20),
          RoomExpensesSection(
            roomCurrency: widget.room.currency,
            members: members,
            currentUserId: widget.currentUserId,
            onViewAll: () => _openSection('History', members),
            onExpenseTap: (expense) => _openExpense(expense, members),
          ),
          const SizedBox(height: 16),
          SectionHeading(
            "Who's in this room",
            icon: Icons.people_rounded,
            trailing: StatusPill(
              label: '${members.length} members',
              color: AppColors.paleBlue,
              textColor: Colors.grey,
            ),
          ),
          const SizedBox(height: 11),
          _membersCard(memberSnapshot, members),
          // this sizedBox is for spacing above the floating action button
          const SizedBox(height: 30),
        ],
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _addExpense,
        backgroundColor: AppColors.primary,
        icon: const Icon(Icons.add_rounded, color: AppColors.white),
        label: const Text(
          'Add expense',
          style: TextStyle(fontWeight: FontWeight.w700, color: AppColors.white),
        ),
      ),
    );
  }

  String get _todayLabel {
    const monthNames = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    final today = DateTime.now();
    return '${today.day} ${monthNames[today.month - 1]}';
  }

  Future<void> _showRenameRoomDialog() async {
    final name = await showDialog<String>(
      context: context,
      builder: (_) => _RenameRoomDialog(initialName: _roomName),
    );
    if (name == null || !mounted || name == _roomName) return;
    await _renameRoom(name);
  }

  Future<void> _renameRoom(String name) async {
    setState(() => _renamingRoom = true);
    _showOperationProgress('Renaming room...');
    try {
      await widget.roomRepository.renameRoom(
        roomId: widget.room.id,
        name: name,
      );
      if (!mounted) return;
      setState(() {
        _roomName = name;
      });
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(const SnackBar(content: Text('Room name updated.')));
    } on RoomFailure catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(SnackBar(content: Text(error.message)));
      }
    } finally {
      if (mounted) setState(() => _renamingRoom = false);
    }
  }

  Widget _membersCard(
    AsyncSnapshot<List<RoomMember>> snapshot,
    List<RoomMember> members,
  ) {
    if (snapshot.connectionState == ConnectionState.waiting) {
      return const SurfaceCard(
        child: Center(child: CircularProgressIndicator()),
      );
    }
    if (snapshot.hasError) {
      return SurfaceCard(
        child: Column(
          children: [
            const Text('Unable to load room members.'),
            TextButton(
              onPressed: () {
                setState(() {
                  _membersFuture = widget.roomRepository.getRoomMembers(
                    widget.room.id,
                  );
                });
              },
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }
    if (members.isEmpty) {
      return const SurfaceCard(child: Text('No members found in this room.'));
    }
    return SurfaceCard(
      onTap: () => _openMembers(members),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
      child: Row(
        children: [
          AvatarStack(
            names: members.map((member) => member.displayName).toList(),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              members.map((member) => member.displayName).join(', '),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
            ),
          ),
          const Icon(Icons.chevron_right_rounded, color: AppColors.muted),
        ],
      ),
    );
  }

  Future<void> _addExpense() async {
    final members = await _membersFuture;
    if (!mounted) return;
    await Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (_) => BlocProvider.value(
          value: _expenseCubit,
          child: AddExpensePage(
            room: widget.room,
            members: members,
            currentUserId: widget.currentUserId,
            currentUserDisplayName: widget.currentUserDisplayName,
          ),
        ),
      ),
    );
  }

  Future<void> _openExpense(Expense expense, List<RoomMember> members) async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (_) => BlocProvider.value(
          value: _expenseCubit,
          child: ExpenseDetailPage(
            room: widget.room,
            expense: expense,
            members: members,
            currentUserId: widget.currentUserId,
            currentUserDisplayName: widget.currentUserDisplayName,
          ),
        ),
      ),
    );
  }

  Future<void> _openMembers(List<RoomMember> members) async {
    List<RoomMember> latestMembers;
    try {
      latestMembers = await widget.roomRepository.getRoomMembers(
        widget.room.id,
      );
    } on RoomFailure {
      latestMembers = members;
    }
    if (!mounted) return;
    Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (_) => AmbientBackground(
          child: RoomMembersPage(roomName: _roomName, members: latestMembers),
        ),
      ),
    );
  }

  Future<void> _showInviteCode() async {
    setState(() => _creatingInvite = true);
    _showOperationProgress('Generating invite...');
    try {
      final invite = await widget.roomRepository.createInvite(
        roomId: widget.room.id,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      await showDialog<void>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: const Text('Invite people'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Share this code to invite people to $_roomName.'),
              const SizedBox(height: 16),
              SelectableText(
                invite.inviteCode,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                'Expires ${_formatInviteExpiry(invite.expiresAt)}',
                style: const TextStyle(fontSize: 12, color: AppColors.muted),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Close'),
            ),
            FilledButton.icon(
              onPressed: () async {
                await Clipboard.setData(ClipboardData(text: invite.inviteCode));
                if (!dialogContext.mounted || !mounted) return;
                Navigator.pop(dialogContext);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Invite code copied.')),
                );
              },
              icon: const Icon(Icons.copy_rounded),
              label: const Text('Copy code'),
            ),
          ],
        ),
      );
    } on RoomFailure catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(SnackBar(content: Text(error.message)));
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(
            const SnackBar(content: Text('Unable to create an invite code.')),
          );
      }
    } finally {
      if (mounted) setState(() => _creatingInvite = false);
    }
  }

  Future<void> _showRemoveMemberDialog(List<RoomMember> members) async {
    final removableMembers = members
        .where((member) => !member.isOwner)
        .toList();
    if (removableMembers.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('There are no other members to remove.')),
      );
      return;
    }
    final member = await showDialog<RoomMember>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Remove member'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: removableMembers.length,
            itemBuilder: (_, index) {
              final candidate = removableMembers[index];
              return ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.person_outline_rounded),
                title: Text(candidate.displayName),
                onTap: () => Navigator.of(dialogContext).pop(candidate),
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
    if (member == null || !mounted) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Remove this member?'),
        content: Text('${member.displayName} will lose access to this room.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Remove'),
          ),
        ],
      ),
    );
    if (confirmed == true) await _removeMember(member);
  }

  Future<void> _removeMember(RoomMember member) async {
    setState(() => _removingMember = true);
    _showOperationProgress('Removing member...');
    try {
      await widget.roomRepository.removeMember(
        roomId: widget.room.id,
        memberId: member.userId,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      setState(() {
        _membersFuture = widget.roomRepository.getRoomMembers(widget.room.id);
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${member.displayName} was removed.')),
      );
    } on RoomFailure catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(SnackBar(content: Text(error.message)));
      }
    } finally {
      if (mounted) setState(() => _removingMember = false);
    }
  }

  Future<void> _confirmDeleteRoom() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete room?'),
        content: Text(
          'This will permanently delete $_roomName, its expenses, and its members.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Delete room'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    setState(() => _deletingRoom = true);
    _showOperationProgress('Deleting room...');
    try {
      await widget.roomRepository.deleteRoom(roomId: widget.room.id);
      if (!mounted) return;
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      widget.onDeleted();
      Navigator.of(context).pop();
    } on RoomFailure catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(SnackBar(content: Text(error.message)));
      }
    } finally {
      if (mounted) setState(() => _deletingRoom = false);
    }
  }

  String _formatInviteExpiry(DateTime value) {
    final local = value.toLocal();
    final day = local.day.toString().padLeft(2, '0');
    final month = local.month.toString().padLeft(2, '0');
    final hour = local.hour.toString().padLeft(2, '0');
    final minute = local.minute.toString().padLeft(2, '0');
    return '$day/$month/${local.year} at $hour:$minute';
  }

  void _showOperationProgress(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          duration: const Duration(days: 1),
          content: Row(
            children: [
              const SizedBox.square(
                dimension: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: AppColors.white,
                ),
              ),
              const SizedBox(width: 12),
              Text(message),
            ],
          ),
        ),
      );
  }

  void _openSection(String section, List<RoomMember> members) {
    if (section == 'Members') {
      _openMembers(members);
      return;
    }
    if (section == 'History') {
      Navigator.of(context).push<void>(
        MaterialPageRoute<void>(
          builder: (_) => BlocProvider.value(
            value: _expenseCubit,
            child: AmbientBackground(
              child: RoomExpenseHistoryPage(
                room: widget.room,
                members: members,
                currentUserId: widget.currentUserId,
                currentUserDisplayName: widget.currentUserDisplayName,
              ),
            ),
          ),
        ),
      );
      return;
    }
    if (section == 'Activity') {
      Navigator.of(context).push<void>(
        MaterialPageRoute<void>(
          builder: (_) => RoomActivityPage(
            room: widget.room,
            members: members,
            repository: widget.activityRepository,
          ),
        ),
      );
      return;
    }
    final page = RoomStatisticsPage(room: widget.room, members: members);
    Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (_) => BlocProvider.value(value: _expenseCubit, child: page),
      ),
    );
  }
}

class _RenameRoomDialog extends StatefulWidget {
  const _RenameRoomDialog({required this.initialName});

  final String initialName;

  @override
  State<_RenameRoomDialog> createState() => _RenameRoomDialogState();
}

class _RenameRoomDialogState extends State<_RenameRoomDialog> {
  late final TextEditingController _controller;
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialName);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Change room name'),
      content: Form(
        key: _formKey,
        child: TextFormField(
          controller: _controller,
          autofocus: true,
          maxLength: 20,
          textCapitalization: TextCapitalization.words,
          decoration: const InputDecoration(labelText: 'Room name'),
          validator: (value) {
            final name = value?.trim() ?? '';
            if (name.isEmpty) return 'Enter a room name.';
            if (name.length > 20) return 'Use 20 characters or fewer.';
            return null;
          },
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () {
            if (_formKey.currentState!.validate()) {
              Navigator.of(context).pop(_controller.text.trim());
            }
          },
          child: const Text('Save'),
        ),
      ],
    );
  }
}

class _QuickAction {
  const _QuickAction(this.label, this.icon);

  final String label;
  final IconData icon;
}

class _Metric extends StatelessWidget {
  const _Metric({required this.label, required this.value, required this.icon});

  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Icon(icon, size: 26, color: AppColors.white),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(fontSize: 12, color: AppColors.white),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 16,
              color: AppColors.white,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}
