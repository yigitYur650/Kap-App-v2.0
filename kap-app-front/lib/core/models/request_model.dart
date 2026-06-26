/// Model representing a shopping request, mapped from the PostgreSQL requests schema.
class RequestModel {
  final String id;
  final String groupId;
  final String requestedBy;
  final String itemName;
  final bool isPrivate;
  final String? privateTo;
  final String status;
  final DateTime createdAt;
  final DateTime? deletedAt;

  const RequestModel({
    required this.id,
    required this.groupId,
    required this.requestedBy,
    required this.itemName,
    required this.isPrivate,
    this.privateTo,
    required this.status,
    required this.createdAt,
    this.deletedAt,
  });

  /// Explanatory comment: dynamic is used here because JSON payload values can represent multiple different Dart types (e.g. String, bool, num, null).
  factory RequestModel.fromJson(Map<String, dynamic> json) {
    return RequestModel(
      id: json['id'] as String,
      groupId: json['group_id'] as String,
      requestedBy: json['requested_by'] as String,
      itemName: json['item_name'] as String,
      isPrivate: json['is_private'] as bool,
      privateTo: json['private_to'] as String?,
      status: json['status'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
      deletedAt: json['deleted_at'] != null
          ? DateTime.parse(json['deleted_at'] as String)
          : null,
    );
  }

  /// Explanatory comment: dynamic is used here because JSON payload values can represent multiple different Dart types (e.g. String, bool, num, null).
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'group_id': groupId,
      'requested_by': requestedBy,
      'item_name': itemName,
      'is_private': isPrivate,
      'private_to': privateTo,
      'status': status,
      'created_at': createdAt.toIso8601String(),
      'deleted_at': deletedAt?.toIso8601String(),
    };
  }
}
