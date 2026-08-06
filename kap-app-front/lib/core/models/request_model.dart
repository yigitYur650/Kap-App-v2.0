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
  final String? quantity;
  final String? unit;
  final String? category;
  final String? boughtBy;
  final DateTime? boughtAt;
  final double? boughtPrice;

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
    this.quantity,
    this.unit,
    this.category,
    this.boughtBy,
    this.boughtAt,
    this.boughtPrice,
  });

  RequestModel copyWith({
    String? id,
    String? groupId,
    String? requestedBy,
    String? itemName,
    bool? isPrivate,
    String? privateTo,
    String? status,
    DateTime? createdAt,
    DateTime? deletedAt,
    String? quantity,
    String? unit,
    String? category,
    String? boughtBy,
    DateTime? boughtAt,
    double? boughtPrice,
  }) {
    return RequestModel(
      id: id ?? this.id,
      groupId: groupId ?? this.groupId,
      requestedBy: requestedBy ?? this.requestedBy,
      itemName: itemName ?? this.itemName,
      isPrivate: isPrivate ?? this.isPrivate,
      privateTo: privateTo ?? this.privateTo,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      deletedAt: deletedAt ?? this.deletedAt,
      quantity: quantity ?? this.quantity,
      unit: unit ?? this.unit,
      category: category ?? this.category,
      boughtBy: boughtBy ?? this.boughtBy,
      boughtAt: boughtAt ?? this.boughtAt,
      boughtPrice: boughtPrice ?? this.boughtPrice,
    );
  }

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
      quantity: json['quantity'] as String?,
      unit: json['unit'] as String?,
      category: json['category'] as String?,
      boughtBy: json['bought_by'] as String?,
      boughtAt: json['bought_at'] != null ? DateTime.parse(json['bought_at'] as String) : null,
      boughtPrice: json['bought_price'] != null ? (json['bought_price'] as num).toDouble() : null,
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
      'quantity': quantity,
      'unit': unit,
      'category': category,
      'bought_by': boughtBy,
      'bought_at': boughtAt?.toIso8601String(),
      'bought_price': boughtPrice,
    };
  }
}
