import 'package:cloud_firestore/cloud_firestore.dart';

/// Filters activity logs by the event types written by Cloud Functions.
///
/// The filter is intentionally represented as the existing string values
/// rather than a new Firestore field, so changing it does not require a data
/// migration or alter the existing `whereIn` queries.
enum RoomActivityFilter {
  all,
  expenses,
  members;

  List<String>? get types => switch (this) {
    all => null,
    expenses => const ['expense_created', 'expense_updated', 'expense_deleted'],
    members => const ['member_joined', 'member_left', 'member_removed'],
  };
}

/// A normalized activity-log entry displayed in a room timeline.
///
/// Activity documents may come from more than one schema version. The model
/// keeps both current target fields and legacy `expenseId`/`memberUserId`
/// fields so historical entries remain readable.
class RoomActivity {
  const RoomActivity({
    required this.id,
    required this.type,
    required this.actorUserId,
    required this.createdAt,
    this.targetType,
    this.targetId,
    this.expenseId,
    this.memberUserId,
    this.metadata = const {},
  });

  final String id;
  final String type;
  final String actorUserId;
  final DateTime? createdAt;
  final String? targetType;
  final String? targetId;
  final String? expenseId;
  final String? memberUserId;
  final Map<String, dynamic> metadata;

  bool get isExpense => _isTarget('expense');

  bool get isMember => _isTarget('member');

  /// Returns a metadata amount only when it represents a whole cent value.
  ///
  /// Firestore numeric values can arrive as either `int` or `double`. A
  /// fractional value is rejected instead of being silently truncated.
  int? get amountInCents => _integerMetadata('amountInCents');

  int? get previousAmountInCents => _integerMetadata('previousAmountInCents');

  /// Returns the updated amount, falling back to the event amount for older
  /// activity records that did not store a separate new amount.
  int? get newAmountInCents =>
      _integerMetadata('newAmountInCents') ?? amountInCents;

  String? get expenseTitle =>
      _stringMetadata('expenseTitle') ??
      _stringMetadata('note') ??
      _stringMetadata('category');

  String? get memberDisplayName =>
      _stringMetadata('memberDisplayName') ?? _stringMetadata('displayName');

  factory RoomActivity.fromMap(String id, Map<String, dynamic> data) {
    final type = _stringValue(data['type']) ?? 'unknown';
    final legacyExpenseId = _stringValue(data['expenseId']);
    final legacyMemberId = _stringValue(data['memberUserId']);
    final targetType = _targetType(
      rawTargetType: _stringValue(data['targetType']),
      type: type,
      legacyExpenseId: legacyExpenseId,
      legacyMemberId: legacyMemberId,
    );
    final targetId = _targetId(
      rawTargetId: _stringValue(data['targetId']),
      targetType: targetType,
      legacyExpenseId: legacyExpenseId,
      legacyMemberId: legacyMemberId,
    );
    return RoomActivity(
      id: id,
      type: type,
      actorUserId: _stringValue(data['actorUserId']) ?? '',
      createdAt: _dateTimeValue(data['createdAt']),
      targetType: targetType,
      targetId: targetId,
      expenseId: legacyExpenseId ?? (targetType == 'expense' ? targetId : null),
      memberUserId:
          legacyMemberId ?? (targetType == 'member' ? targetId : null),
      metadata: _metadataValue(data['metadata']),
    );
  }

  // A recognized targetType is authoritative when it disagrees with the
  // event prefix. Older documents without targetType are inferred from the
  // event type or their legacy ID field.
  bool _isTarget(String expectedTargetType) {
    if (targetType == 'expense' || targetType == 'member') {
      return targetType == expectedTargetType;
    }
    return switch (expectedTargetType) {
      'expense' => type.startsWith('expense_'),
      'member' => type.startsWith('member_'),
      _ => false,
    };
  }

  static String? _targetType({
    required String? rawTargetType,
    required String type,
    required String? legacyExpenseId,
    required String? legacyMemberId,
  }) {
    if (rawTargetType == 'expense' || rawTargetType == 'member') {
      return rawTargetType;
    }
    if (type.startsWith('expense_') || legacyExpenseId != null) {
      return 'expense';
    }
    if (type.startsWith('member_') || legacyMemberId != null) {
      return 'member';
    }
    return null;
  }

  static String? _targetId({
    required String? rawTargetId,
    required String? targetType,
    required String? legacyExpenseId,
    required String? legacyMemberId,
  }) {
    // When both legacy IDs exist, prefer the ID belonging to the resolved
    // target type. This prevents a malformed mixed-version document from
    // pointing a member event at an expense.
    if (rawTargetId != null) return rawTargetId;
    return switch (targetType) {
      'expense' => legacyExpenseId ?? legacyMemberId,
      'member' => legacyMemberId ?? legacyExpenseId,
      _ => legacyExpenseId ?? legacyMemberId,
    };
  }

  static String? _stringValue(Object? value) => value is String ? value : null;

  static DateTime? _dateTimeValue(Object? value) {
    if (value is Timestamp) return value.toDate().toUtc();
    if (value is DateTime) return value.toUtc();
    return null;
  }

  static Map<String, dynamic> _metadataValue(Object? value) {
    if (value is! Map) return const {};
    final metadata = <String, dynamic>{};
    for (final entry in value.entries) {
      if (entry.key is String) metadata[entry.key as String] = entry.value;
    }
    return metadata.isEmpty ? const {} : metadata;
  }

  String? _stringMetadata(String key) {
    final value = metadata[key];
    return value is String && value.trim().isNotEmpty ? value.trim() : null;
  }

  int? _integerMetadata(String key) {
    final value = metadata[key];
    if (value is int) return value;
    if (value is! double || !value.isFinite) return null;
    final integer = value.toInt();
    return integer.toDouble() == value ? integer : null;
  }
}

/// One page of activity results and whether another cursor page is available.
class RoomActivityPage {
  const RoomActivityPage({required this.items, required this.hasMore});

  final List<RoomActivity> items;
  final bool hasMore;
}
