class GroupModel {
  final String id;
  final String name;
  final String? joinCode;
  final String? createdBy;
  final DateTime createdAt;

  const GroupModel({
    required this.id,
    required this.name,
    this.joinCode,
    this.createdBy,
    required this.createdAt,
  });

  factory GroupModel.fromJson(Map<String, dynamic> json) {
    return GroupModel(
      id: json['id'] as String,
      name: json['name'] as String,
      joinCode: json['join_code'] as String?,
      createdBy: json['created_by'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'join_code': joinCode,
      'created_by': createdBy,
      'created_at': createdAt.toIso8601String(),
    };
  }
}
