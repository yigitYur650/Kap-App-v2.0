import 'stock_status.dart';

class InventoryItem {
  final String id;
  final String groupId;
  final String itemName;
  final StockStatus status;
  final String? lastUpdatedBy;
  final DateTime? lastUpdatedAt;
  final DateTime createdAt;
  final DateTime? deletedAt;

  const InventoryItem({
    required this.id,
    required this.groupId,
    required this.itemName,
    required this.status,
    this.lastUpdatedBy,
    this.lastUpdatedAt,
    required this.createdAt,
    this.deletedAt,
  });

  factory InventoryItem.fromJson(Map<String, dynamic> json) {
    return InventoryItem(
      id: json['id'] as String,
      groupId: json['group_id'] as String,
      itemName: json['item_name'] as String,
      status: StockStatus.fromString(json['status'] as String),
      lastUpdatedBy: json['last_updated_by'] as String?,
      lastUpdatedAt: json['last_updated_at'] != null
          ? DateTime.parse(json['last_updated_at'] as String)
          : null,
      createdAt: DateTime.parse(json['created_at'] as String),
      deletedAt: json['deleted_at'] != null
          ? DateTime.parse(json['deleted_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'group_id': groupId,
      'item_name': itemName,
      'status': status.toDbString(),
      'last_updated_by': lastUpdatedBy,
      'last_updated_at': lastUpdatedAt?.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
      'deleted_at': deletedAt?.toIso8601String(),
    };
  }
}
