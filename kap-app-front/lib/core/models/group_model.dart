class GroupModel {
  final String id;
  final String name;
  final String type;
  final String? createdBy;
  final DateTime createdAt;

  const GroupModel({
    required this.id,
    required this.name,
    required this.type,
    this.createdBy,
    required this.createdAt,
  });

  // Explanatory comment: dynamic is used here because JSON payload values can represent multiple different Dart types (e.g. String, bool, num, null).
  factory GroupModel.fromJson(Map<String, dynamic> json) {
    return GroupModel(
      id: json['id'] as String,
      name: json['name'] as String,
      type: json['type'] as String,
      createdBy: json['created_by'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  // Explanatory comment: dynamic is used here because JSON payload values can represent multiple different Dart types (e.g. String, bool, num, null).
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'type': type,
      'created_by': createdBy,
      'created_at': createdAt.toIso8601String(),
    };
  }
}
