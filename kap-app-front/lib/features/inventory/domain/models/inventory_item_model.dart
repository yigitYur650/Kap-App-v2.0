import 'package:kap_app_front/shared/utils/category_helper.dart';

class InventoryItem {
  final String id;
  final String groupId;
  final String itemName;
  final String status; // 'var', 'azaldı', 'yok'
  final String category;
  final String? lastUpdatedBy;
  final DateTime? lastUpdatedAt;
  final DateTime createdAt;

  const InventoryItem({
    required this.id,
    required this.groupId,
    required this.itemName,
    required this.status,
    required this.category,
    this.lastUpdatedBy,
    this.lastUpdatedAt,
    required this.createdAt,
  });

  factory InventoryItem.fromJson(Map<String, dynamic> json) {
    final name = json['item_name'] as String? ?? '';
    final cat = json['category'] as String? ?? CategoryHelper.detectCategory(name);

    return InventoryItem(
      id: json['id'] as String,
      groupId: json['group_id'] as String,
      itemName: name,
      status: json['status'] as String? ?? 'var',
      category: cat,
      lastUpdatedBy: json['last_updated_by'] as String?,
      lastUpdatedAt: json['last_updated_at'] != null
          ? DateTime.tryParse(json['last_updated_at'].toString())
          : null,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'].toString())
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'group_id': groupId,
      'item_name': itemName,
      'status': status,
      'category': category,
      if (lastUpdatedBy != null) 'last_updated_by': lastUpdatedBy,
      if (lastUpdatedAt != null) 'last_updated_at': lastUpdatedAt!.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
    };
  }

  InventoryItem copyWith({
    String? id,
    String? groupId,
    String? itemName,
    String? status,
    String? category,
    String? lastUpdatedBy,
    DateTime? lastUpdatedAt,
    DateTime? createdAt,
  }) {
    return InventoryItem(
      id: id ?? this.id,
      groupId: groupId ?? this.groupId,
      itemName: itemName ?? this.itemName,
      status: status ?? this.status,
      category: category ?? this.category,
      lastUpdatedBy: lastUpdatedBy ?? this.lastUpdatedBy,
      lastUpdatedAt: lastUpdatedAt ?? this.lastUpdatedAt,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
