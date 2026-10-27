import 'package:flutter/material.dart';
import 'package:pocket_together/shared/presentation/widgets/ambient_background.dart';

import '../../../../app/theme/app_theme.dart';
import '../../../../shared/presentation/money_format.dart';
import '../../../../shared/presentation/widgets/flow_widgets.dart';
import '../../data/room_activity_repository.dart';
import '../../models/room.dart';
import '../../models/room_activity.dart';
import '../../models/room_member.dart';

class RoomActivityPage extends StatefulWidget {
  const RoomActivityPage({
    required this.room,
    required this.members,
    required this.repository,
    super.key,
  });

  final Room room;
  final List<RoomMember> members;
  final RoomActivityRepository repository;

  @override
  State<RoomActivityPage> createState() => _RoomActivityPageState();
}

class _RoomActivityPageState extends State<RoomActivityPage> {
  final _scrollController = ScrollController();
  final _items = <RoomActivity>[];
  bool _loading = false;
  bool _hasMore = true;
  String? _error;

  Map<String, String> get _names => {
    for (final member in widget.members) member.userId: member.displayName,
  };

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_loadWhenNearEnd);
    _loadPage();
  }

  @override
  void dispose() {
    _scrollController
      ..removeListener(_loadWhenNearEnd)
      ..dispose();
    super.dispose();
  }

  Future<void> _loadPage() async {
    if (_loading || !_hasMore) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final page = await widget.repository.getPage(
        roomId: widget.room.id,
        after: _items.isEmpty ? null : _items.last,
      );
      if (!mounted) return;
      setState(() {
        _items.addAll(page.items);
        _hasMore = page.hasMore;
        _loading = false;
      });
    } on RoomActivityFailure catch (error) {
      if (mounted) {
        setState(() {
          _loading = false;
          _error = error.message;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _loading = false;
          _error = 'Unable to load room activity.';
        });
      }
    }
  }

  void _loadWhenNearEnd() {
    if (_scrollController.position.extentAfter < 320) _loadPage();
  }

  @override
  Widget build(BuildContext context) {
    return AmbientBackground(
      child: Scaffold(
        appBar: AppBar(title: Text('${widget.room.name} activity')),
        body: RefreshIndicator(
          onRefresh: () async {
            setState(() {
              _items.clear();
              _hasMore = true;
            });
            await _loadPage();
          },
          child: _items.isEmpty && _loading
              ? const Center(child: CircularProgressIndicator())
              : _items.isEmpty && _error != null
              ? _ErrorView(message: _error!, onRetry: _loadPage)
              : _items.isEmpty
              ? const Center(child: Text('No activity yet.'))
              : ListView.separated(
                  controller: _scrollController,
                  padding: const EdgeInsets.fromLTRB(18, 18, 18, 28),
                  itemCount: _items.length + (_loading || _hasMore ? 1 : 0),
                  separatorBuilder: (_, _) => const SizedBox(height: 10),
                  itemBuilder: (_, index) {
                    if (index == _items.length) {
                      return _error == null
                          ? const Center(
                              child: Padding(
                                padding: EdgeInsets.all(12),
                                child: CircularProgressIndicator(),
                              ),
                            )
                          : _ErrorView(message: _error!, onRetry: _loadPage);
                    }
                    return _ActivityTile(
                      activity: _items[index],
                      actorName: _names[_items[index].actorUserId] ?? 'Member',
                      currency: widget.room.currency,
                    );
                  },
                ),
        ),
      ),
    );
  }
}

class _ActivityTile extends StatelessWidget {
  const _ActivityTile({
    required this.activity,
    required this.actorName,
    required this.currency,
  });

  final RoomActivity activity;
  final String actorName;
  final String? currency;

  @override
  Widget build(BuildContext context) {
    final metadata = activity.metadata;
    final amount = metadata['amountInCents'];
    final title = switch (activity.type) {
      'expense_created' => 'added an expense',
      'expense_updated' => 'updated an expense',
      'expense_deleted' => 'deleted an expense',
      'member_joined' => 'joined the room',
      'member_left' => 'removed a member',
      _ => 'changed the room',
    };
    final note = metadata['note'] as String?;
    final amountText = amount is num
        ? ' - ${formatCurrency(amount.toInt(), currency: currency)}'
        : '';
    return SurfaceCard(
      padding: const EdgeInsets.all(14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.history_rounded, color: AppColors.primary),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$actorName $title$amountText',
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                if (note?.trim().isNotEmpty == true) ...[
                  const SizedBox(height: 3),
                  Text(note!, style: const TextStyle(color: AppColors.muted)),
                ],
                const SizedBox(height: 5),
                Text(
                  _formatDate(activity.createdAt),
                  style: const TextStyle(color: AppColors.muted, fontSize: 11),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime? value) {
    if (value == null) return 'Just now';
    final local = value.toLocal();
    return '${local.day}/${local.month}/${local.year} ${local.hour.toString().padLeft(2, '0')}:${local.minute.toString().padLeft(2, '0')}';
  }
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => Center(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(message),
        TextButton(onPressed: onRetry, child: const Text('Retry')),
      ],
    ),
  );
}
