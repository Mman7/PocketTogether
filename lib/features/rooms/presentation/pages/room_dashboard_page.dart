import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../app/theme/app_theme.dart';
import '../../../../core/presentation/mock_data.dart';
import '../../../../shared/presentation/category_emoji.dart';
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

class RoomDashboardPage extends StatefulWidget {
  const RoomDashboardPage({
    required this.room,
    required this.currentUserId,
    required this.currentUserDisplayName,
    required this.roomRepository,
    required this.expenseRepository,
    super.key,
  });

  final Room room;
  final String currentUserId;
  final String currentUserDisplayName;
  final RoomRepository roomRepository;
  final ExpenseRepository expenseRepository;

  @override
  State<RoomDashboardPage> createState() => _RoomDashboardPageState();
}

class _RoomDashboardPageState extends State<RoomDashboardPage> {
  late final ExpenseCubit _expenseCubit;
  late Future<List<RoomMember>> _membersFuture;
  bool _creatingInvite = false;

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
    final nameById = {
      for (final member in members) member.userId: member.displayName,
    };
    final today = state.expenses.where((expense) {
      final date = expense.expenseDate;
      final now = DateTime.now();
      return date.year == now.year &&
          date.month == now.month &&
          date.day == now.day;
    }).toList();
    final total = state.expenses.fold<int>(
      0,
      (sum, expense) => sum + expense.amountInCents,
    );
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
            TextButton.icon(
              onPressed: _creatingInvite ? null : _showInviteCode,
              icon: _creatingInvite
                  ? const SizedBox.square(
                      dimension: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.mail_outline_rounded),
              label: const Text('Invite'),
            ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(18, 8, 18, 90),
        children: [
          SurfaceCard(
            padding: const EdgeInsets.all(17),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Expanded(
                      child: Text(
                        'Total spent',
                        style: TextStyle(color: AppColors.muted, fontSize: 12),
                      ),
                    ),
                    StatusPill(
                      label: _periodLabel,
                      color: AppColors.paleBlue,
                      textColor: Colors.grey,
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  _money(total / 100),
                  style: const TextStyle(
                    fontSize: 33,
                    fontWeight: FontWeight.w800,
                    fontFeatures: [FontFeature.tabularFigures()],
                  ),
                ),
                const SizedBox(height: 14),
                Container(
                  decoration: BoxDecoration(
                    color: AppColors.paleBlue.withValues(alpha: 0.64),
                    borderRadius: BorderRadius.circular(13),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 11),
                  child: Row(
                    children: [
                      _Metric(
                        label: 'Today',
                        value: _money(
                          today.fold<int>(
                                0,
                                (sum, expense) => sum + expense.amountInCents,
                              ) /
                              100,
                        ),
                      ),
                      _Metric(label: 'Members', value: '${members.length}'),
                      _Metric(
                        label: 'Expenses',
                        value: '${state.expenses.length}',
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    for (final action in const [
                      _QuickAction('Members', Icons.groups_outlined),
                      _QuickAction('Settle', Icons.call_split_rounded),
                      _QuickAction('Stats', Icons.bar_chart_rounded),
                    ])
                      Expanded(
                        child: InkWell(
                          onTap: () => _openSection(action.label, members),
                          borderRadius: BorderRadius.circular(12),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 5),
                            child: Column(
                              children: [
                                Container(
                                  width: 39,
                                  height: 39,
                                  decoration: const BoxDecoration(
                                    color: AppColors.paleBlue,
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    action.icon,
                                    size: 19,
                                    color: AppColors.primary,
                                  ),
                                ),
                                const SizedBox(height: 5),
                                Text(
                                  action.label,
                                  style: const TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ),
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
          SectionHeading(
            "Today's expenses",
            trailing: TextButton(
              onPressed: () => _openSection('History', members),
              child: const Text('View all'),
            ),
          ),
          const SizedBox(height: 5),
          // loading state
          if (state.isLoading && state.expenses.isEmpty)
            const Padding(
              padding: EdgeInsets.all(24),
              child: Center(child: CircularProgressIndicator()),
            )
          else if (state.expenses.isEmpty && state.errorMessage == null)
            const _RoomEmptyState()
          else
            for (final expense in today.take(4)) ...[
              _FirestoreExpenseTile(
                expense: expense,
                amount: _money(expense.amountInCents / 100),
                paidByName: nameById[expense.paidByUserId] ?? 'Unknown member',
                onTap: () => _openExpense(expense, members),
              ),
              const SizedBox(height: 8),
            ],
          if (!state.isLoading && state.expenses.isNotEmpty && today.isEmpty)
            const Text(
              'No expenses today',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.muted),
            ),
          const SizedBox(height: 16),
          SectionHeading(
            "Who's in this room",
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

  String get _periodLabel => 'All time';

  String _money(double amount) {
    switch (widget.room.currency) {
      case 'JPY':
        return '¥${amount.toStringAsFixed(0)}';
      case 'THB':
        return '฿${amount.toStringAsFixed(0)}';
      default:
        return formatMoney(amount);
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
              onPressed: () => setState(
                () => _membersFuture = widget.roomRepository.getRoomMembers(
                  widget.room.id,
                ),
              ),
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

  void _openMembers(List<RoomMember> members) {
    Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (_) =>
            _RoomMembersPage(roomName: widget.room.name, members: members),
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
    if (section == 'Stats') {
      Navigator.of(context).push<void>(
        MaterialPageRoute<void>(
          builder: (_) => BlocProvider.value(
            value: _expenseCubit,
            child: _RoomStatisticsPage(
              room: widget.room,
              membersFuture: _membersFuture,
            ),
          ),
        ),
      );
      return;
    }
    final total = _expenseCubit.state.expenses.fold<int>(
      0,
      (sum, expense) => sum + expense.amountInCents,
    );
    final mockRoom = RoomMock(
      name: widget.room.name,
      subtitle: widget.room.description ?? 'Shared room',
      emoji: '🏠',
      currency: widget.room.currency ?? 'MYR',
      total: _money(total / 100),
      members: members
          .map((member) => member.displayName.split(' ').first)
          .toList(),
    );
    Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (_) => RoomSectionPage(room: mockRoom, section: section),
      ),
    );
  }
}

class _RoomMembersPage extends StatelessWidget {
  const _RoomMembersPage({required this.roomName, required this.members});

  final String roomName;
  final List<RoomMember> members;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('$roomName members')),
      body: members.isEmpty
          ? const Center(child: Text('No members found in this room.'))
          : ListView(
              padding: const EdgeInsets.all(18),
              children: [
                for (final member in members) ...[
                  SurfaceCard(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 12,
                    ),
                    child: Row(
                      children: [
                        MemberAvatar(
                          name: member.displayName,
                          size: 42,
                          color: member.isOwner
                              ? AppColors.paleBlue
                              : AppColors.paleCyan,
                        ),
                        const SizedBox(width: 11),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                member.displayName,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              if (member.email != null)
                                Text(
                                  member.email!,
                                  style: const TextStyle(
                                    fontSize: 11,
                                    color: AppColors.muted,
                                  ),
                                ),
                            ],
                          ),
                        ),
                        StatusPill(label: member.isOwner ? 'Owner' : 'Member'),
                      ],
                    ),
                  ),
                  const SizedBox(height: 9),
                ],
              ],
            ),
    );
  }
}

class _RoomExpenseHistoryPage extends StatelessWidget {
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
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('${room.name} expenses')),
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
                    onPressed: () =>
                        context.read<ExpenseCubit>().loadExpenses(room.id),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }
          if (state.expenses.isEmpty) {
            return const Center(child: Text('No expenses yet.'));
          }
          final nameById = {
            for (final member in members) member.userId: member.displayName,
          };
          return ListView.separated(
            padding: const EdgeInsets.all(18),
            itemCount: state.expenses.length,
            separatorBuilder: (_, _) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              final expense = state.expenses[index];
              return _FirestoreExpenseTile(
                expense: expense,
                amount: _formatExpenseMoney(
                  room.currency,
                  expense.amountInCents,
                ),
                paidByName: nameById[expense.paidByUserId] ?? 'Unknown member',
                onTap: () => Navigator.of(context).push<void>(
                  MaterialPageRoute<void>(
                    builder: (_) => BlocProvider.value(
                      value: context.read<ExpenseCubit>(),
                      child: ExpenseDetailPage(
                        room: room,
                        expense: expense,
                        members: members,
                        currentUserId: currentUserId,
                        currentUserDisplayName: currentUserDisplayName,
                      ),
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class _RoomStatisticsPage extends StatelessWidget {
  const _RoomStatisticsPage({required this.room, required this.membersFuture});

  final Room room;
  final Future<List<RoomMember>> membersFuture;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('${room.name} stats')),
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
                    onPressed: () =>
                        context.read<ExpenseCubit>().loadExpenses(room.id),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          final now = DateTime.now();
          final monthExpenses = state.expenses
              .where(
                (expense) =>
                    expense.expenseDate.year == now.year &&
                    expense.expenseDate.month == now.month,
              )
              .toList();
          final totalInCents = monthExpenses.fold<int>(
            0,
            (sum, expense) => sum + expense.amountInCents,
          );
          final totalsByCategory = <String, int>{};
          for (final expense in monthExpenses) {
            totalsByCategory.update(
              expense.category,
              (total) => total + expense.amountInCents,
              ifAbsent: () => expense.amountInCents,
            );
          }
          final categories = totalsByCategory.entries.toList()
            ..sort((a, b) => b.value.compareTo(a.value));

          return FutureBuilder<List<RoomMember>>(
            future: membersFuture,
            builder: (context, memberSnapshot) {
              final members = memberSnapshot.data ?? const <RoomMember>[];
              final memberTotals = <String, int>{
                for (final member in members) member.userId: 0,
              };
              for (final expense in monthExpenses) {
                memberTotals.update(
                  expense.paidByUserId,
                  (total) => total + expense.amountInCents,
                  ifAbsent: () => expense.amountInCents,
                );
              }
              final memberNames = {
                for (final member in members) member.userId: member.displayName,
              };
              final sortedMemberTotals = memberTotals.entries.toList()
                ..sort((a, b) => b.value.compareTo(a.value));
              const categoryColors = [
                AppColors.primary,
                AppColors.secondary,
                AppColors.cyan,
                AppColors.success,
                AppColors.danger,
              ];

              return ListView(
                padding: const EdgeInsets.fromLTRB(18, 8, 18, 28),
                children: [
                  SurfaceCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Total spending in ${_monthName(now.month)}',
                          style: const TextStyle(
                            color: AppColors.muted,
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          _formatExpenseMoney(room.currency, totalInCents),
                          style: const TextStyle(
                            fontSize: 31,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${monthExpenses.length} ${monthExpenses.length == 1 ? 'expense' : 'expenses'}',
                          style: const TextStyle(
                            color: AppColors.muted,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  const SectionHeading('Spending by category'),
                  const SizedBox(height: 10),
                  if (categories.isEmpty)
                    const SurfaceCard(child: Text('No expenses this month.'))
                  else
                    SurfaceCard(
                      child: Column(
                        children: [
                          for (
                            var index = 0;
                            index < categories.length;
                            index++
                          ) ...[
                            if (index > 0) const SizedBox(height: 14),
                            Row(
                              children: [
                                Container(
                                  width: 32,
                                  height: 32,
                                  decoration: BoxDecoration(
                                    color: AppColors.paleBlue,
                                    borderRadius: BorderRadius.circular(9),
                                  ),
                                  alignment: Alignment.center,
                                  child: Text(
                                    categoryEmoji(categories[index].key),
                                    style: const TextStyle(fontSize: 17),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    categories[index].key,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                                Text(
                                  '${(categories[index].value * 100 / totalInCents).round()}%',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Text(
                                  _formatExpenseMoney(
                                    room.currency,
                                    categories[index].value,
                                  ),
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(5),
                              child: LinearProgressIndicator(
                                value: categories[index].value / totalInCents,
                                color:
                                    categoryColors[index %
                                        categoryColors.length],
                                backgroundColor: AppColors.paleBlue,
                                minHeight: 7,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  const SizedBox(height: 16),
                  const SectionHeading('Paid by member'),
                  const SizedBox(height: 10),
                  if (memberSnapshot.connectionState == ConnectionState.waiting)
                    const SurfaceCard(
                      child: Center(child: CircularProgressIndicator()),
                    )
                  else if (memberSnapshot.hasError)
                    const SurfaceCard(
                      child: Text('Unable to load room members.'),
                    )
                  else if (sortedMemberTotals.isEmpty)
                    const SurfaceCard(child: Text('No members found.'))
                  else
                    SurfaceCard(
                      child: Column(
                        children: [
                          for (final entry in sortedMemberTotals) ...[
                            Row(
                              children: [
                                MemberAvatar(
                                  name: memberNames[entry.key] ?? 'Unknown',
                                  size: 30,
                                  color: AppColors.paleBlue,
                                  border: false,
                                ),
                                const SizedBox(width: 9),
                                Expanded(
                                  child: Text(
                                    memberNames[entry.key] ?? 'Unknown member',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                Text(
                                  _formatExpenseMoney(
                                    room.currency,
                                    entry.value,
                                  ),
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                            if (entry.key != sortedMemberTotals.last.key)
                              const SizedBox(height: 12),
                          ],
                        ],
                      ),
                    ),
                ],
              );
            },
          );
        },
      ),
    );
  }
}

String _monthName(int month) => const [
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
][month - 1];

String _formatExpenseMoney(String? currency, int amountInCents) {
  final amount = amountInCents / 100;
  switch (currency) {
    case 'JPY':
      return '¥${amount.toStringAsFixed(0)}';
    case 'THB':
      return '฿${amount.toStringAsFixed(0)}';
    default:
      return formatMoney(amount);
  }
}

class RoomSectionPage extends StatefulWidget {
  const RoomSectionPage({required this.room, required this.section, super.key});

  final RoomMock room;
  final String section;

  @override
  State<RoomSectionPage> createState() => _RoomSectionPageState();
}

class _RoomSectionPageState extends State<RoomSectionPage> {
  final Set<String> _paidSettlements = {};

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.section,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(18, 8, 18, 28),
        children: switch (widget.section) {
          // member page
          'Members' => _members(),
          // settle page
          'Settle' => _settlements(),
          _ => _history(),
        },
      ),
    );
  }

  List<Widget> _members() => [
    SurfaceCard(
      color: AppColors.paleBlue,
      child: Row(
        children: [
          const Icon(Icons.groups_rounded, color: AppColors.primary),
          const SizedBox(width: 11),
          Expanded(
            child: Text(
              '${widget.room.members.length} people are sharing ${widget.room.name}.',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    ),
    const SizedBox(height: 16),
    for (final member in roomMembers) ...[
      SurfaceCard(
        padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 12),
        child: Row(
          children: [
            MemberAvatar(name: member.name, size: 42, color: member.color),
            const SizedBox(width: 11),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    member.name,
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                  Text(
                    member.role,
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.muted,
                    ),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                const Text(
                  'Total spending',
                  style: TextStyle(fontSize: 10, color: AppColors.muted),
                ),
                Text(
                  _money(member.spending),
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
              ],
            ),
            PopupMenuButton<String>(
              tooltip: 'Member options',
              onSelected: (value) => _memberAction(member, value),
              itemBuilder: (_) => [
                const PopupMenuItem(
                  value: 'invite',
                  child: Text('Manage invite'),
                ),
                if (member.role == 'Member')
                  const PopupMenuItem(
                    value: 'remove',
                    child: Text('Remove member'),
                  ),
                if (member.role == 'Owner')
                  const PopupMenuItem(
                    value: 'regenerate',
                    child: Text('Regenerate invite'),
                  ),
              ],
            ),
          ],
        ),
      ),
      const SizedBox(height: 9),
    ],
    const SizedBox(height: 6),
    OutlinedButton.icon(
      onPressed: () => _message('Invite code copied: JAPAN-4K8D'),
      icon: const Icon(Icons.link_rounded),
      label: const Text('Manage room invite'),
    ),
  ];

  List<Widget> _settlements() => [
    SurfaceCard(
      color: AppColors.paleBlue,
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Everyone is almost even',
            style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
          ),
          SizedBox(height: 4),
          Text(
            'Suggested transfers keep the number of payments low.',
            style: TextStyle(color: AppColors.muted, fontSize: 12),
          ),
        ],
      ),
    ),
    const SizedBox(height: 17),
    const SectionHeading(
      'Suggested settlements',
      trailing: StatusPill(label: '2 pending', color: AppColors.accent),
    ),
    const SizedBox(height: 10),
    for (final pair in const [
      ('Eric', 'John', 50.0),
      ('David', 'John', 30.0),
      ('Amy', 'Eric', 20.0),
    ]) ...[
      SurfaceCard(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            _SettlementAvatars(from: pair.$1, to: pair.$2),
            const SizedBox(width: 11),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${pair.$1} → ${pair.$2}',
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                  Text(
                    _paidSettlements.contains(pair.$1)
                        ? 'Paid just now'
                        : 'Pending',
                    style: const TextStyle(
                      color: AppColors.muted,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  _money(pair.$3),
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                TextButton(
                  onPressed: _paidSettlements.contains(pair.$1)
                      ? null
                      : () => _markPaid(pair.$1),
                  child: Text(
                    _paidSettlements.contains(pair.$1) ? 'Paid' : 'Mark paid',
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
      const SizedBox(height: 9),
    ],
  ];

  List<Widget> _history() {
    final expenses = widget.room.currency == 'MYR'
        ? householdExpenses
        : japanExpenses;
    return [
      SurfaceCard(
        child: Row(
          children: [
            const Icon(Icons.filter_list_rounded, color: AppColors.primary),
            const SizedBox(width: 9),
            const Expanded(
              child: Text(
                'October · All categories',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
            Text(
              '${expenses.length} items',
              style: const TextStyle(color: AppColors.muted, fontSize: 11),
            ),
          ],
        ),
      ),
      const SizedBox(height: 16),
      for (final group in ['Today', 'Yesterday', 'Earlier']) ...[
        if (expenses.any((expense) => expense.dateGroup == group)) ...[
          Padding(
            padding: const EdgeInsets.only(bottom: 9, top: 5),
            child: Text(
              group,
              style: const TextStyle(fontWeight: FontWeight.w800),
            ),
          ),
          for (final expense in expenses.where(
            (expense) => expense.dateGroup == group,
          )) ...[
            _ExpenseTile(
              expense: expense,
              amount: _money(expense.amount),
              onTap: () => _message('Open room history to manage expenses.'),
            ),
            const SizedBox(height: 8),
          ],
        ],
      ],
    ];
  }

  void _markPaid(String name) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Mark this payment as paid?'),
        content: Text('This will update the preview status for $name.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Not yet'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Mark paid'),
          ),
        ],
      ),
    );
    if (confirmed == true) setState(() => _paidSettlements.add(name));
  }

  void _memberAction(MemberMock member, String action) async {
    if (action == 'invite' || action == 'regenerate') {
      _message(
        action == 'invite'
            ? 'Room invite: JAPAN-4K8D'
            : 'A fresh invite code is ready: FMLY-82QK',
      );
      return;
    }
    final remove = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Remove ${member.name.split(' ').first}?'),
        content: const Text(
          'They will no longer appear in this local room preview.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Remove'),
          ),
        ],
      ),
    );
    if (remove == true) {
      _message('${member.name.split(' ').first} removed from the preview.');
    }
  }

  String _money(double amount) => widget.room.currency == 'JPY'
      ? '¥${amount.toStringAsFixed(0)}'
      : widget.room.currency == 'THB'
      ? '฿${amount.toStringAsFixed(0)}'
      : formatMoney(amount);

  void _message(String value) =>
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(value)));
}

class _QuickAction {
  const _QuickAction(this.label, this.icon);

  final String label;
  final IconData icon;
}

class _Metric extends StatelessWidget {
  const _Metric({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 12, color: AppColors.muted),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
          ),
        ],
      ),
    );
  }
}

class _ExpenseTile extends StatelessWidget {
  const _ExpenseTile({
    required this.expense,
    required this.amount,
    required this.onTap,
  });

  final ExpenseMock expense;
  final String amount;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SurfaceCard(
      onTap: onTap,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: AppColors.paleBlue,
              borderRadius: BorderRadius.circular(12),
            ),
            alignment: Alignment.center,
            child: Text(expense.emoji, style: const TextStyle(fontSize: 20)),
          ),
          const SizedBox(width: 11),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  expense.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  'Paid by ${expense.paidBy} · ${expense.time}',
                  style: const TextStyle(fontSize: 10, color: AppColors.muted),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                amount,
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  fontFeatures: [FontFeature.tabularFigures()],
                ),
              ),
              const Text(
                'Split equally',
                style: TextStyle(fontSize: 9, color: AppColors.muted),
              ),
            ],
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
    required this.onTap,
  });

  final Expense expense;
  final String amount;
  final String paidByName;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final description = expense.note?.trim();
    return SurfaceCard(
      onTap: onTap,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: AppColors.paleBlue,
              borderRadius: BorderRadius.circular(12),
            ),
            alignment: Alignment.center,
            child: Text(
              categoryEmoji(expense.category),
              style: const TextStyle(fontSize: 20),
            ),
          ),
          const SizedBox(width: 11),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
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
                Text(
                  'Paid by $paidByName · ${formatShortDate(expense.expenseDate)}',
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

class _SettlementAvatars extends StatelessWidget {
  const _SettlementAvatars({required this.from, required this.to});

  final String from;
  final String to;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 60,
      height: 36,
      child: Stack(
        children: [
          MemberAvatar(name: from, size: 34, color: AppColors.paleBlue),
          Positioned(
            left: 25,
            child: MemberAvatar(name: to, size: 34, color: AppColors.paleCyan),
          ),
        ],
      ),
    );
  }
}
