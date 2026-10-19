import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter/services.dart';

import '../../../../app/theme/app_theme.dart';
import '../../../../shared/presentation/category_emoji.dart';
import '../../../../shared/presentation/widgets/flow_widgets.dart';
import '../../../rooms/models/room.dart';
import '../../../rooms/models/room_member.dart';
import '../../models/expense.dart';
import '../cubit/expense_cubit.dart';
import '../widgets/category_bottom_sheet.dart';

class AddExpensePage extends StatefulWidget {
  const AddExpensePage({
    required this.room,
    required this.members,
    required this.currentUserId,
    required this.currentUserDisplayName,
    this.expense,
    super.key,
  });

  final Room room;
  final List<RoomMember> members;
  final String currentUserId;
  final String currentUserDisplayName;
  final Expense? expense;

  @override
  State<AddExpensePage> createState() => _AddExpensePageState();
}

class _AddExpensePageState extends State<AddExpensePage> {
  late String _amount;
  late final TextEditingController _amountController;
  late String _category;
  late String _paidByUserId;
  late Set<String> _splitMemberIds;
  late String _transferMethod;
  late String _transferToUserId;
  late final TextEditingController _note;
  late DateTime _date;

  bool get _editing => widget.expense != null;

  @override
  void initState() {
    super.initState();
    _amount = widget.expense == null
        ? ''
        : (widget.expense!.amountInCents / 100).toStringAsFixed(2);
    _amountController = TextEditingController(text: _amount);
    _category = widget.expense?.category ?? 'Food';
    _paidByUserId = widget.expense?.paidByUserId ?? widget.currentUserId;
    _splitMemberIds =
        widget.expense?.splitAmountsInCents.keys.toSet() ??
        widget.members.map((member) => member.userId).toSet();
    _transferMethod = widget.expense?.transferMethod ?? 'Bank transfer';
    final recipients = _transferRecipients(_paidByUserId);
    _transferToUserId =
        widget.expense?.transferToUserId ??
        (recipients.isEmpty ? _paidByUserId : recipients.first);
    _date = widget.expense?.expenseDate ?? DateTime.now();
    _note = TextEditingController(text: widget.expense?.note ?? '');
  }

  @override
  void dispose() {
    _amountController.dispose();
    _note.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final amount = double.tryParse(_amount) ?? 0;
    final expenseState = context.watch<ExpenseCubit>().state;
    final quickCategories = <String>[
      'Food',
      'Transport',
      'Shopping',
      'Hotel',
      'Coffee',
      'Transfer',
    ];
    if (!quickCategories.contains(_category)) {
      quickCategories.insert(0, _category);
    }
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.close_rounded),
          tooltip: 'Close',
        ),
        title: Text(
          _editing ? 'Edit expense' : 'Add expense',
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
        ),
        actions: [
          TextButton(
            onPressed: amount > 0 ? _save : null,
            child: const Text('Save'),
          ),
        ],
      ),
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(18, 5, 18, 14),
                children: [
                  _AmountCard(
                    controller: _amountController,
                    onAmountChanged: (value) => setState(() => _amount = value),
                    currency: _currencySymbol(widget.room.currency ?? 'MYR'),
                    roomName: widget.room.name,
                    onQuickAdd: _addAmount,
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      const Expanded(
                        child: Text(
                          'Category',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      TextButton(
                        onPressed: _chooseCategory,
                        child: const Text('See all'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 3),
                  SizedBox(
                    height: 56,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      children: [
                        for (final category in quickCategories)
                          Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: _CategoryChip(
                              name: category,
                              icon: categoryIcon(category),
                              selected: _category == category,
                              onTap: () => _setCategory(category),
                            ),
                          ),
                        IconButton.filledTonal(
                          onPressed: _chooseCategory,
                          icon: const Icon(Icons.grid_view_rounded),
                          tooltip: 'All categories',
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  SurfaceCard(
                    padding: EdgeInsets.zero,
                    child: Column(
                      children: [
                        _MetadataRow(
                          icon: Icons.account_balance_wallet_outlined,
                          label: 'Paid by',
                          trailing: DropdownButtonHideUnderline(
                            child: DropdownButton<String>(
                              value:
                                  widget.members.any(
                                    (member) => member.userId == _paidByUserId,
                                  )
                                  ? _paidByUserId
                                  : null,
                              borderRadius: BorderRadius.circular(14),
                              items: [
                                for (final member in widget.members)
                                  DropdownMenuItem(
                                    value: member.userId,
                                    child: Text(
                                      member.userId == widget.currentUserId
                                          ? '${member.displayName} (You)'
                                          : member.displayName,
                                    ),
                                  ),
                              ],
                              onChanged: (value) {
                                if (value == null) return;
                                setState(() {
                                  _paidByUserId = value;
                                  final recipients = _transferRecipients(value);
                                  if (!recipients.contains(_transferToUserId) &&
                                      recipients.isNotEmpty) {
                                    _transferToUserId = recipients.first;
                                  }
                                });
                              },
                            ),
                          ),
                        ),
                        const Divider(height: 1, color: AppColors.paleBlue),
                        if (_isTransfer) ...[
                          _MetadataRow(
                            icon: Icons.swap_horiz_rounded,
                            label: 'Transfer method',
                            trailing: SizedBox(
                              width: 150,
                              child: DropdownButtonHideUnderline(
                                child: DropdownButton<String>(
                                  value: _transferMethod,
                                  isExpanded: true,
                                  alignment: AlignmentDirectional.centerEnd,
                                  borderRadius: BorderRadius.circular(14),
                                  items: [
                                    for (final method in [
                                      'Bank transfer',
                                      'Cash',
                                      'E-wallet',
                                    ])
                                      DropdownMenuItem(
                                        value: method,
                                        child: Text(method),
                                      ),
                                  ],
                                  onChanged: (value) => setState(
                                    () => _transferMethod =
                                        value ?? _transferMethod,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const Divider(height: 1, color: AppColors.paleBlue),
                          _MetadataRow(
                            icon: Icons.person_outline_rounded,
                            label: 'Transfer to',
                            trailing: SizedBox(
                              width: 150,
                              child: DropdownButtonHideUnderline(
                                child: DropdownButton<String>(
                                  value:
                                      _transferRecipients(_paidByUserId)
                                          .contains(_transferToUserId)
                                      ? _transferToUserId
                                      : null,
                                  isExpanded: true,
                                  alignment: AlignmentDirectional.centerEnd,
                                  borderRadius: BorderRadius.circular(14),
                                  items: [
                                    for (final member in _transferRecipients(
                                      _paidByUserId,
                                    ))
                                      DropdownMenuItem(
                                        value: member,
                                        child: Text(_memberName(member)),
                                      ),
                                  ],
                                  onChanged: (value) => setState(
                                    () => _transferToUserId =
                                        value ?? _transferToUserId,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ] else ...[
                          Padding(
                            padding: const EdgeInsets.fromLTRB(13, 12, 13, 4),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.call_split_rounded,
                                  size: 19,
                                  color: AppColors.primary,
                                ),
                                const SizedBox(width: 10),
                                const Expanded(
                                  child: Text(
                                    'Split with',
                                    style: TextStyle(
                                      color: AppColors.muted,
                                      fontSize: 13,
                                    ),
                                  ),
                                ),
                                Text(
                                  '${_selectedSplitIds.length} selected',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          for (final member in widget.members)
                            CheckboxListTile(
                              dense: true,
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 13,
                              ),
                              title: Text(member.displayName),
                              value: _selectedSplitIds.contains(member.userId),
                              onChanged: (selected) => setState(() {
                                if (selected == true) {
                                  _splitMemberIds.add(member.userId);
                                } else {
                                  _splitMemberIds.remove(member.userId);
                                }
                              }),
                            ),
                        ],
                        const Divider(height: 1, color: AppColors.paleBlue),
                        _MetadataRow(
                          icon: Icons.edit_note_rounded,
                          label: 'Note',
                          trailing: SizedBox(
                            width: 150,
                            child: TextField(
                              controller: _note,
                              textAlign: TextAlign.end,
                              decoration: const InputDecoration(
                                hintText: 'Add a note',
                                border: InputBorder.none,
                                filled: false,
                                // contentPadding: EdgeInsets.zero,
                              ),
                            ),
                          ),
                        ),
                        const Divider(height: 1, color: AppColors.paleBlue),
                        _MetadataRow(
                          icon: Icons.calendar_today_outlined,
                          label: 'Date',
                          trailing: TextButton.icon(
                            onPressed: _chooseDate,
                            icon: const Icon(
                              Icons.keyboard_arrow_down_rounded,
                              size: 17,
                            ),
                            label: Text(_dateLabel),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.fromLTRB(18, 12, 18, 16),
              decoration: const BoxDecoration(
                color: AppColors.white,
                border: Border(top: BorderSide(color: AppColors.border)),
              ),
              child: PrimaryButton(
                label: expenseState.isMutating
                    ? 'Saving…'
                    : '${_editing ? 'Save changes' : 'Add expense'}  ·  ${_currencySymbol(widget.room.currency ?? 'MYR')}${_amount.isEmpty ? '0' : _amount}',
                icon: expenseState.isMutating
                    ? Icons.hourglass_top_rounded
                    : Icons.add_task_rounded,
                onPressed: amount > 0 && !expenseState.isMutating
                    ? _save
                    : null,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String get _dateLabel {
    final today = DateTime.now();
    if (_date.year == today.year &&
        _date.month == today.month &&
        _date.day == today.day) {
      return 'Today';
    }
    return '${_date.day} ${_month(_date.month)}';
  }

  bool get _isTransfer => _category == 'Transfer';

  List<String> get _selectedSplitIds => _isTransfer
      ? (_transferToUserId.isEmpty ? const [] : [_transferToUserId])
      : _splitMemberIds
            .where((id) => widget.members.any((member) => member.userId == id))
            .toList();

  List<String> _transferRecipients(String paidByUserId) {
    return widget.members
        .map((member) => member.userId)
        .where((userId) => userId != paidByUserId)
        .toList();
  }

  String _memberName(String userId) {
    for (final member in widget.members) {
      if (member.userId == userId) return member.displayName;
    }
    if (userId == widget.currentUserId) return widget.currentUserDisplayName;
    return 'Unknown member';
  }

  void _setCategory(String category) {
    setState(() => _category = category);
  }

  Future<void> _chooseCategory() async {
    final selected = await showCategoryBottomSheet(
      context,
      selected: _category,
    );
    if (!mounted || selected == null) return;
    setState(() => _category = selected.name);
  }

  Future<void> _chooseDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2020),
      lastDate: DateTime(2035),
    );
    if (picked != null) setState(() => _date = picked);
  }

  void _addAmount(int amount) {
    final value = (double.tryParse(_amount) ?? 0) + amount;
    final updatedAmount = value.toStringAsFixed(value % 1 == 0 ? 0 : 2);
    _amountController.value = TextEditingValue(
      text: updatedAmount,
      selection: TextSelection.collapsed(offset: updatedAmount.length),
    );
    setState(() => _amount = updatedAmount);
  }

  Future<void> _save() async {
    final amount = double.tryParse(_amount);
    if (amount == null || amount <= 0) return;
    final amountInCents = (amount * 100).round();
    final splitIds = _selectedSplitIds;
    if (splitIds.isEmpty || splitIds.length > amountInCents) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(content: Text('Select valid members for this split.')),
        );
      return;
    }
    final previous = widget.expense;
    final note = _note.text.trim();
    final expense = Expense(
      id: previous?.id ?? '',
      amountInCents: amountInCents,
      category: _category,
      note: note.isEmpty ? null : note,
      paidByUserId: _paidByUserId,
      createdByUserId: previous?.createdByUserId ?? widget.currentUserId,
      transferMethod: _isTransfer ? _transferMethod : null,
      transferToUserId: _isTransfer ? _transferToUserId : null,
      splitAmountsInCents: _splitAmounts(splitIds, amountInCents),
      expenseDate: DateTime(_date.year, _date.month, _date.day),
      createdAt: previous?.createdAt,
      updatedAt: previous?.updatedAt,
    );
    final cubit = context.read<ExpenseCubit>();
    final saved = _editing
        ? await cubit.updateExpense(widget.room.id, expense)
        : await cubit.createExpense(widget.room.id, expense);
    if (saved != null && mounted) Navigator.pop(context);
  }

  Map<String, int> _splitAmounts(List<String> memberIds, int totalCents) {
    final baseAmount = totalCents ~/ memberIds.length;
    final remainder = totalCents % memberIds.length;
    return {
      for (var index = 0; index < memberIds.length; index++)
        memberIds[index]: baseAmount + (index < remainder ? 1 : 0),
    };
  }

  String _currencySymbol(String currency) {
    switch (currency) {
      case 'JPY':
        return '¥';
      case 'THB':
        return '฿';
      default:
        return 'RM ';
    }
  }

  String _month(int month) => const [
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
  ][month - 1];
}

class _AmountCard extends StatelessWidget {
  const _AmountCard({
    required this.controller,
    required this.onAmountChanged,
    required this.currency,
    required this.roomName,
    required this.onQuickAdd,
  });

  final TextEditingController controller;
  final ValueChanged<String> onAmountChanged;
  final String currency;
  final String roomName;
  final ValueChanged<int> onQuickAdd;

  @override
  Widget build(BuildContext context) {
    return SurfaceCard(
      padding: const EdgeInsets.fromLTRB(16, 17, 16, 15),
      child: Column(
        children: [
          StatusPill(
            label: roomName.toUpperCase(),
            color: AppColors.primary,
            textColor: Colors.white,
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Text(
                currency,
                style: const TextStyle(
                  fontSize: 23,
                  color: AppColors.muted,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(width: 4),
              Expanded(
                child: TextField(
                  key: const ValueKey('expense-amount'),
                  controller: controller,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  inputFormatters: [
                    TextInputFormatter.withFunction((oldValue, newValue) {
                      return RegExp(r'^\d*\.?\d{0,2}$').hasMatch(newValue.text)
                          ? newValue
                          : oldValue;
                    }),
                  ],
                  textAlign: TextAlign.center,
                  maxLength: 9,
                  onChanged: onAmountChanged,
                  style: const TextStyle(
                    fontSize: 48,
                    fontWeight: FontWeight.w800,
                    fontFeatures: [FontFeature.tabularFigures()],
                  ),
                  decoration: const InputDecoration(
                    hintText: '0',
                    border: InputBorder.none,
                    filled: false,
                    isCollapsed: true,
                    contentPadding: EdgeInsets.zero,
                    counterText: '',
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final value in [50, 100, 150])
                ActionChip(
                  label: Text('+$currency${_group(value)}'),
                  onPressed: () => onQuickAdd(value),
                  backgroundColor: AppColors.paleBlue,
                  side: BorderSide.none,
                  labelStyle: const TextStyle(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  String _group(int value) => value.toString().replaceAllMapped(
    RegExp(r'\B(?=(\d{3})+(?!\d))'),
    (_) => ',',
  );
}

class _CategoryChip extends StatelessWidget {
  const _CategoryChip({
    required this.name,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  final String name;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: onTap,
      icon: Icon(icon, size: 18),
      label: Text(name),
      style: OutlinedButton.styleFrom(
        backgroundColor: selected ? AppColors.paleBlue : AppColors.white,
        foregroundColor: AppColors.ink,
        side: BorderSide(
          color: selected ? AppColors.primary : AppColors.border,
          width: selected ? 1.6 : 1,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(13)),
      ),
    );
  }
}

class _MetadataRow extends StatelessWidget {
  const _MetadataRow({
    required this.icon,
    required this.label,
    required this.trailing,
  });

  final IconData icon;
  final String label;
  final Widget trailing;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 8),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: const BoxDecoration(
              color: AppColors.paleBlue,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 18, color: AppColors.primary),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(color: AppColors.muted, fontSize: 13),
            ),
          ),
          trailing,
        ],
      ),
    );
  }
}
