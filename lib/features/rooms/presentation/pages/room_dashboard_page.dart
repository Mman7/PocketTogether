import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../app/theme/app_theme.dart';
import '../../../../shared/presentation/category_emoji.dart';
import '../../../../shared/presentation/money_format.dart';
import '../../../../shared/presentation/short_date.dart';
import '../../../../shared/presentation/widgets/flow_widgets.dart';
import '../../../expenses/data/expense_repository.dart';
import '../../../expenses/models/expense.dart';
import '../../../expenses/presentation/cubit/expense_cubit.dart';
import '../../../expenses/presentation/cubit/expense_state.dart';
import '../../../expenses/presentation/pages/add_expense_page.dart';
import '../../../expenses/presentation/pages/expense_detail_page.dart';
import '../../data/room_repository.dart';
import '../../models/room.dart';
import '../../models/room_member.dart';
import 'room_section_pages.dart';

class RoomDashboardPage extends StatefulWidget {
  const RoomDashboardPage({
    required this.room,
    required this.currentUserId,
    required this.currentUserDisplayName,
    required this.roomRepository,
    required this.expenseRepository,
    required this.onDeleted,
    super.key,
  });

  final Room room;
  final String currentUserId;
  final String currentUserDisplayName;
  final RoomRepository roomRepository;
  final ExpenseRepository expenseRepository;
  final VoidCallback onDeleted;

  @override
  State<RoomDashboardPage> createState() => _RoomDashboardPageState();
}

class _RoomDashboardPageState extends State<RoomDashboardPage> {
  late final ExpenseCubit _expenseCubit;
  late Future<List<RoomMember>> _membersFuture;
  bool _creatingInvite = false;
  bool _removingMember = false;
  bool _deletingRoom = false;

  @override
  void initState() {
    super.initState();
    _expenseCubit = ExpenseCubit(widget.expenseRepository)
      ..loadExpenses(widget.room.id);
    _membersFuture = widget.roomRepository.getRoomMembers(widget.room.id);
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
          return date.year == now.year && date.month == now.month;
        })
        .fold<int>(0, (sum, expense) => sum + expense.amountInCents);
    return Scaffold(
      appBar: AppBar(
        titleSpacing: 0,
        title: Row(
          children: [
            Flexible(
              child: Text(
                widget.room.name,
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
          ? _buildRoomDrawer(members)
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
                        'Total spent',
                        style: TextStyle(color: Colors.white70, fontSize: 12),
                      ),
                    ),
                    StatusPill(
                      label: _periodLabel,
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
                      // divided line
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
                _QuickAction('Settle', Icons.call_split_rounded),
                _QuickAction('Stats', Icons.bar_chart_rounded),
                _QuickAction('History', Icons.bar_chart_rounded),
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
          _RoomExpensesSection(
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

  String get _periodLabel {
    const monthNames = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];
    final now = DateTime.now();
    return '${monthNames[now.month - 1]} ${now.year}';
  }

  Widget _buildRoomDrawer(List<RoomMember> members) {
    return Drawer(
      backgroundColor: AppColors.canvas,
      child: SafeArea(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            Container(
              padding: const EdgeInsets.fromLTRB(20, 18, 12, 20),
              decoration: const BoxDecoration(
                color: AppColors.paleBlue,
                border: Border(bottom: BorderSide(color: AppColors.border)),
                borderRadius: BorderRadius.vertical(
                  bottom: Radius.circular(AppRadii.card),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Expanded(
                        child: Text(
                          'Room actions',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.of(context).pop(),
                        icon: const Icon(Icons.close_rounded),
                        tooltip: 'Close',
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      const Icon(
                        Icons.home_work_outlined,
                        color: AppColors.primary,
                        size: 20,
                      ),
                      const SizedBox(width: 9),
                      Expanded(
                        child: Text(
                          widget.room.name,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Owner controls',
                    style: TextStyle(
                      color: AppColors.muted,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 22, 16, 8),
              child: Text(
                'PEOPLE',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: AppColors.muted,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.1,
                ),
              ),
            ),
            _roomActionTile(
              icon: Icons.mail_outline_rounded,
              title: 'Generate invite',
              subtitle: 'Invite someone to this room',
              iconColor: AppColors.primary,
              enabled: !_creatingInvite,
              onTap: () async {
                Navigator.of(context).pop();
                await _showInviteCode();
              },
            ),
            _roomActionTile(
              icon: Icons.person_remove_outlined,
              title: 'Remove member',
              subtitle: 'Remove a member from this room',
              iconColor: AppColors.secondary,
              enabled: !_removingMember,
              onTap: () async {
                Navigator.of(context).pop();
                await _showRemoveMemberDialog(members);
              },
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 22, 16, 8),
              child: Text(
                'DANGER ZONE',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: AppColors.danger,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.1,
                ),
              ),
            ),
            _roomActionTile(
              icon: Icons.delete_outline_rounded,
              title: 'Delete room',
              subtitle: 'Permanently delete this room',
              iconColor: AppColors.danger,
              titleColor: AppColors.danger,
              enabled: !_deletingRoom,
              onTap: () async {
                Navigator.of(context).pop();
                await _confirmDeleteRoom();
              },
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _roomActionTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color iconColor,
    required VoidCallback onTap,
    required bool enabled,
    Color? titleColor,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: Material(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(AppRadii.control),
        child: InkWell(
          onTap: enabled ? onTap : null,
          borderRadius: BorderRadius.circular(AppRadii.control),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: iconColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  alignment: Alignment.center,
                  child: Icon(icon, color: iconColor, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          color: titleColor ?? AppColors.ink,
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        subtitle,
                        style: const TextStyle(
                          color: AppColors.muted,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(
                  Icons.chevron_right_rounded,
                  color: AppColors.muted,
                  size: 20,
                ),
              ],
            ),
          ),
        ),
      ),
    );
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
        builder: (_) =>
            RoomMembersPage(roomName: widget.room.name, members: latestMembers),
      ),
    );
  }

  Future<void> _showInviteCode() async {
    setState(() => _creatingInvite = true);
    try {
      final invite = await widget.roomRepository.createInvite(
        roomId: widget.room.id,
      );
      if (!mounted) return;
      await showDialog<void>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: const Text('Invite people'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Share this code to invite people to ${widget.room.name}.'),
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
    try {
      await widget.roomRepository.removeMember(
        roomId: widget.room.id,
        memberId: member.userId,
      );
      if (!mounted) return;
      setState(() {
        _membersFuture = widget.roomRepository.getRoomMembers(widget.room.id);
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${member.displayName} was removed.')),
      );
    } on RoomFailure catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(error.message)));
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
          'This will permanently delete ${widget.room.name}, its expenses, and its members.',
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
    try {
      await widget.roomRepository.deleteRoom(roomId: widget.room.id);
      widget.onDeleted();
      if (mounted) Navigator.of(context).pop();
    } on RoomFailure catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(error.message)));
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
            child: _RoomExpenseHistoryPage(
              room: widget.room,
              members: members,
              currentUserId: widget.currentUserId,
              currentUserDisplayName: widget.currentUserDisplayName,
            ),
          ),
        ),
      );
      return;
    }
    final page = section == 'Stats'
        ? RoomStatisticsPage(room: widget.room, members: members)
        : RoomSettlePage(
            room: widget.room,
            members: members,
            currentUserId: widget.currentUserId,
          );
    Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (_) => BlocProvider.value(value: _expenseCubit, child: page),
      ),
    );
  }
}

class _RoomExpenseHistoryPage extends StatefulWidget {
  const _RoomExpenseHistoryPage({
    required this.room,
    required this.members,
    required this.currentUserId,
    required this.currentUserDisplayName,
  });

  final Room room;
  final List<RoomMember> members;
  final String currentUserId;
  final String currentUserDisplayName;

  @override
  State<_RoomExpenseHistoryPage> createState() =>
      _RoomExpenseHistoryPageState();
}

class _RoomExpenseHistoryPageState extends State<_RoomExpenseHistoryPage> {
  int? _selectedMonthKey;
  String _selectedCategory = 'All';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F9FC),
      appBar: AppBar(
        backgroundColor: AppColors.white,
        titleSpacing: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Flexible(
                  child: Text(
                    '${widget.room.name} expenses',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                const SizedBox(width: 7),
                const DecoratedBox(
                  decoration: BoxDecoration(
                    color: AppColors.success,
                    shape: BoxShape.circle,
                  ),
                  child: SizedBox(width: 8, height: 8),
                ),
              ],
            ),
            Text(
              '${widget.members.length} active members · Shared room',
              style: const TextStyle(
                color: AppColors.muted,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
      body: BlocBuilder<ExpenseCubit, ExpenseState>(
        builder: (context, state) {
          if (state.isLoading && state.expenses.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state.errorMessage != null && state.expenses.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(state.errorMessage!),
                  TextButton(
                    onPressed: () => context.read<ExpenseCubit>().loadExpenses(
                      widget.room.id,
                    ),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }
          if (state.expenses.isEmpty) {
            return const Center(child: Text('No expenses yet.'));
          }

          final monthKeys =
              state.expenses
                  .map((expense) => _monthKey(expense.expenseDate))
                  .toSet()
                  .toList()
                ..sort((first, second) => second.compareTo(first));
          final selectedMonthKey = _selectedMonthKey ?? monthKeys.first;
          final categories = <String>{
            'All',
            ...state.expenses.map((expense) => expense.category),
          }.toList();
          final selectedExpenses = state.expenses
              .where(
                (expense) => _monthKey(expense.expenseDate) == selectedMonthKey,
              )
              .toList();
          final filteredExpenses = selectedExpenses
              .where(
                (expense) =>
                    _selectedCategory == 'All' ||
                    expense.category == _selectedCategory,
              )
              .toList();
          final groupedExpenses = <String, List<Expense>>{};
          final today = DateTime.now();
          for (final expense in state.expenses) {
            if (!filteredExpenses.contains(expense)) continue;
            final date = expense.expenseDate;
            final day = DateTime(date.year, date.month, date.day);
            final currentDay = DateTime(today.year, today.month, today.day);
            final label = day == currentDay
                ? 'Today'
                : day == currentDay.subtract(const Duration(days: 1))
                ? 'Yesterday'
                : _formatDate(date);
            groupedExpenses.putIfAbsent(label, () => []).add(expense);
          }
          for (final expenses in groupedExpenses.values) {
            expenses.sort(
              (first, second) =>
                  second.expenseDate.compareTo(first.expenseDate),
            );
          }
          final nameById = {
            for (final member in widget.members)
              member.userId: member.displayName,
          };
          final groupTotal = state.expenses.fold<int>(
            0,
            (sum, expense) => sum + expense.amountInCents,
          );
          final paid = selectedExpenses
              .where((expense) => expense.paidByUserId == widget.currentUserId)
              .fold<int>(0, (sum, expense) => sum + expense.amountInCents);
          final theyPaid = selectedExpenses
              .where((expense) => expense.paidByUserId != widget.currentUserId)
              .fold<int>(0, (sum, expense) => sum + expense.amountInCents);
          final balance = selectedExpenses.fold<int>(0, (sum, expense) {
            final owed = expense.splitAmountsInCents[widget.currentUserId] ?? 0;
            return sum +
                (expense.paidByUserId == widget.currentUserId
                    ? expense.amountInCents - owed
                    : -owed);
          });
          return ListView(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
            children: [
              _RoomLedgerSummary(
                total: formatCurrency(
                  groupTotal,
                  currency: widget.room.currency,
                ),
                paid: formatCurrency(paid, currency: widget.room.currency),
                theyPaid: formatCurrency(
                  theyPaid,
                  currency: widget.room.currency,
                ),
                balance: formatCurrency(
                  balance.abs(),
                  currency: widget.room.currency,
                ),
                positiveBalance: balance >= 0,
                memberNames: widget.members
                    .where((member) => member.userId != widget.currentUserId)
                    .map((member) => member.displayName)
                    .take(2)
                    .join(' & '),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Categories',
                    style: TextStyle(color: AppColors.muted, fontSize: 13),
                  ),
                  TextButton(
                    onPressed: () => setState(() {
                      _selectedCategory = 'All';
                    }),
                    child: const Text('Clear filters'),
                  ),
                ],
              ),
              SizedBox(
                height: 38,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: categories.length,
                  separatorBuilder: (_, _) => const SizedBox(width: 8),
                  itemBuilder: (_, index) {
                    final category = categories[index];
                    return ChoiceChip(
                      label: Text(category),
                      selected: _selectedCategory == category,
                      onSelected: (_) =>
                          setState(() => _selectedCategory = category),
                      showCheckmark: false,
                      avatar: Icon(
                        categoryIcon(category),
                        size: 16,
                        color: _selectedCategory == category
                            ? AppColors.primary
                            : Colors.black.withAlpha(255),
                      ),
                    );
                  },
                ),
              ),
              if (filteredExpenses.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 36),
                  child: Center(
                    child: Text(
                      'No expenses for this month',
                      style: TextStyle(color: AppColors.muted),
                    ),
                  ),
                )
              else
                for (final entry in groupedExpenses.entries) ...[
                  _RoomExpenseDateHeading(
                    label: entry.key,
                    monthLabel: _formatMonth(selectedMonthKey),
                    total: entry.value.fold<int>(
                      0,
                      (sum, expense) => sum + expense.amountInCents,
                    ),
                    currency: widget.room.currency,
                    onMonthSelected: entry.key == groupedExpenses.keys.first
                        ? () => _selectMonth(monthKeys)
                        : null,
                  ),
                  for (final expense in entry.value) ...[
                    _FirestoreExpenseTile(
                      expense: expense,
                      amount: formatCurrency(
                        expense.amountInCents,
                        currency: widget.room.currency,
                      ),
                      paidByName:
                          nameById[expense.paidByUserId] ?? 'Unknown member',
                      createdByCurrentUser:
                          expense.createdByUserId == widget.currentUserId,
                      onTap: () => Navigator.of(context).push<void>(
                        MaterialPageRoute<void>(
                          builder: (_) => BlocProvider.value(
                            value: context.read<ExpenseCubit>(),
                            child: ExpenseDetailPage(
                              room: widget.room,
                              expense: expense,
                              members: widget.members,
                              currentUserId: widget.currentUserId,
                              currentUserDisplayName:
                                  widget.currentUserDisplayName,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                  ],
                ],
              const SizedBox(height: 16),
              const Center(
                child: Text(
                  'All transactions settled and synced',
                  style: TextStyle(color: AppColors.muted, fontSize: 12),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  int _monthKey(DateTime date) => date.year * 100 + date.month;

  Future<void> _selectMonth(List<int> availableMonthKeys) async {
    final selectedMonthKey = await showDialog<int>(
      context: context,
      builder: (_) => _MonthPickerDialog(monthKeys: availableMonthKeys),
    );
    if (!mounted || selectedMonthKey == null) return;
    setState(() => _selectedMonthKey = selectedMonthKey);
  }

  String _formatMonth(int monthKey) {
    const monthNames = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];
    final year = monthKey ~/ 100;
    final month = monthKey % 100;
    return '${monthNames[month - 1]} $year';
  }

  String _formatDate(DateTime date) =>
      '${date.day} ${_formatMonth(_monthKey(date)).split(' ').first}';
}

class _RoomLedgerSummary extends StatelessWidget {
  const _RoomLedgerSummary({
    required this.total,
    required this.paid,
    required this.theyPaid,
    required this.balance,
    required this.positiveBalance,
    required this.memberNames,
  });

  final String total;
  final String paid;
  final String theyPaid;
  final String balance;
  final bool positiveBalance;
  final String memberNames;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF172238), Color(0xFF0D172B)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(28),
        boxShadow: const [
          BoxShadow(
            color: Color(0x220B1425),
            blurRadius: 18,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'TOTAL GROUP SPENDING',
                        style: TextStyle(
                          color: Color(0xFF9AA8BC),
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.7,
                        ),
                      ),
                      const SizedBox(height: 7),
                      Text(
                        total.toString(),
                        style: const TextStyle(
                          color: AppColors.white,
                          fontSize: 34,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(
                  Icons.arrow_downward_rounded,
                  color: Color(0xFF50D6B0),
                ),
              ],
            ),
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Divider(color: Color(0x334A5A73), height: 1),
            ),
            // TODO add a chart here
            const Padding(
              padding: EdgeInsets.only(top: 16),
              child: Divider(color: Color(0x334A5A73), height: 1),
            ),
          ],
        ),
      ),
    );
  }
}

class _RoomExpenseDateHeading extends StatelessWidget {
  const _RoomExpenseDateHeading({
    required this.label,
    required this.monthLabel,
    required this.total,
    required this.currency,
    this.onMonthSelected,
  });

  final String label;
  final String monthLabel;
  final int total;
  final String? currency;
  final VoidCallback? onMonthSelected;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 18, bottom: 8),
      child: Row(
        children: [
          Text(
            label.toUpperCase(),
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800),
          ),
          if (onMonthSelected != null)
            Row(
              children: [
                // show selected month
                StatusPill(label: monthLabel),
                IconButton(
                  icon: const Icon(Icons.calendar_month_rounded, size: 16),
                  tooltip: 'Choose month',
                  onPressed: onMonthSelected,
                ),
              ],
            ),
          const Spacer(),

          StatusPill(label: formatCurrency(total, currency: currency)),
        ],
      ),
    );
  }
}

class _MonthPickerDialog extends StatelessWidget {
  const _MonthPickerDialog({required this.monthKeys});

  final List<int> monthKeys;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Choose month'),
      content: SizedBox(
        width: 320,
        child: GridView.builder(
          shrinkWrap: true,
          itemCount: monthKeys.length,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            mainAxisSpacing: 8,
            crossAxisSpacing: 8,
            childAspectRatio: 1.8,
          ),
          itemBuilder: (context, index) {
            final monthKey = monthKeys[index];
            return OutlinedButton(
              onPressed: () => Navigator.of(context).pop(monthKey),
              child: Text(_formatMonth(monthKey), textAlign: TextAlign.center),
            );
          },
        ),
      ),
    );
  }

  String _formatMonth(int monthKey) {
    const monthNames = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];
    final month = monthKey % 100;
    return '${monthNames[month - 1].substring(0, 3)} ${monthKey ~/ 100}';
  }
}

class _RoomExpensesSection extends StatelessWidget {
  const _RoomExpensesSection({
    required this.roomCurrency,
    required this.members,
    required this.currentUserId,
    required this.onViewAll,
    required this.onExpenseTap,
  });

  final String? roomCurrency;
  final List<RoomMember> members;
  final String currentUserId;
  final VoidCallback onViewAll;
  final ValueChanged<Expense> onExpenseTap;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ExpenseCubit, ExpenseState>(
      builder: (context, state) {
        final today = state.expenses.where((expense) {
          final date = expense.expenseDate;
          final now = DateTime.now();
          return date.year == now.year &&
              date.month == now.month &&
              date.day == now.day;
        }).toList();
        final nameById = {
          for (final member in members) member.userId: member.displayName,
        };

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SectionHeading(
              "Today's expenses",
              icon: Icons.wallet,
              trailing: TextButton(
                onPressed: onViewAll,
                child: const Text('View all'),
              ),
            ),
            const SizedBox(height: 5),
            if (state.isLoading && state.expenses.isEmpty)
              const Padding(
                padding: EdgeInsets.all(24),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (state.expenses.isEmpty && state.errorMessage == null)
              const _RoomEmptyState()
            else
              for (final expense in today.take(5)) ...[
                _FirestoreExpenseTile(
                  expense: expense,
                  amount: formatCurrency(
                    expense.amountInCents,
                    currency: roomCurrency,
                  ),
                  paidByName:
                      nameById[expense.paidByUserId] ?? 'Unknown member',
                  createdByCurrentUser:
                      expense.createdByUserId == currentUserId,
                  onTap: () => onExpenseTap(expense),
                ),
                const SizedBox(height: 8),
              ],
            if (!state.isLoading && state.expenses.isNotEmpty && today.isEmpty)
              const Text(
                'No expenses today',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.muted),
              ),
          ],
        );
      },
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

class _FirestoreExpenseTile extends StatelessWidget {
  const _FirestoreExpenseTile({
    required this.expense,
    required this.amount,
    required this.paidByName,
    required this.createdByCurrentUser,
    required this.onTap,
  });

  final Expense expense;
  final String amount;
  final String paidByName;
  final bool createdByCurrentUser;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final description = expense.note?.trim();
    final createdTime = formatShortTime(expense.createdAt);
    return SurfaceCard(
      onTap: onTap,
      color: createdByCurrentUser ? AppColors.expenseMine : AppColors.white,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            alignment: Alignment.center,
            child: Icon(
              categoryIcon(expense.category),
              size: 20,
              color: createdByCurrentUser
                  ? Colors.deepPurpleAccent
                  : AppColors.primary,
            ),
          ),
          const SizedBox(width: 11),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        description == null || description.isEmpty
                            ? expense.category
                            : description,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    if (createdByCurrentUser)
                      Padding(
                        padding: const EdgeInsets.only(left: 6),
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            color: AppColors.expenseMineBadge,
                            borderRadius: BorderRadius.circular(AppRadii.pill),
                          ),
                          child: const Padding(
                            padding: EdgeInsets.symmetric(
                              horizontal: 7,
                              vertical: 3,
                            ),
                            child: Text(
                              'You',
                              style: TextStyle(
                                color: Colors.deepPurpleAccent,
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
                Text(
                  'Paid by $paidByName· ${formatShortDate(expense.expenseDate)}'
                  '${createdTime == null ? '' : ' · $createdTime'}',
                  style: const TextStyle(fontSize: 10, color: AppColors.muted),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(
            amount,
            style: const TextStyle(
              fontWeight: FontWeight.w800,
              fontFeatures: [FontFeature.tabularFigures()],
            ),
          ),
        ],
      ),
    );
  }
}

class _RoomEmptyState extends StatelessWidget {
  const _RoomEmptyState();

  @override
  Widget build(BuildContext context) {
    return const SurfaceCard(
      child: Column(
        children: [
          Icon(Icons.receipt_long_outlined, color: AppColors.primary, size: 30),
          SizedBox(height: 8),
          Text(
            'No expenses yet',
            style: TextStyle(fontWeight: FontWeight.w800),
          ),
          SizedBox(height: 3),
          Text(
            'Add the first shared expense to get started.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 12, color: AppColors.muted),
          ),
        ],
      ),
    );
  }
}
