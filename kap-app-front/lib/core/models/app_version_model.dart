class AppVersionModel {
  final String? id;
  final int versionCode;
  final String versionName;
  final String apkUrl;
  final String? sha256Hash;
  final String? changelog;
  final bool isMandatory;
  final String? createdBy;

  const AppVersionModel({
    this.id,
    required this.versionCode,
    required this.versionName,
    required this.apkUrl,
    this.sha256Hash,
    this.changelog,
    this.isMandatory = false,
    this.createdBy,
  });

  factory AppVersionModel.fromJson(Map<String, dynamic> json) {
    return AppVersionModel(
      id: json['id'] as String?,
      versionCode: json['version_code'] as int? ?? 100,
      versionName: json['version_name'] as String? ?? 'v1.0.0',
      apkUrl: json['apk_url'] as String? ?? '',
      sha256Hash: json['sha256_hash'] as String?,
      changelog: json['changelog'] as String?,
      isMandatory: json['is_mandatory'] as bool? ?? false,
      createdBy: json['created_by'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'version_code': versionCode,
      'version_name': versionName,
      'apk_url': apkUrl,
      if (sha256Hash != null) 'sha256_hash': sha256Hash,
      if (changelog != null) 'changelog': changelog,
      'is_mandatory': isMandatory,
      if (createdBy != null) 'created_by': createdBy,
    };
  }
}
