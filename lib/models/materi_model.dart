class MateriFolder {
  final int id;
  final int userId;
  final int? parentId;
  final String name;
  final String? color;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  int size = 0; // Calculated dynamically from its files and subfolders

  MateriFolder({
    required this.id,
    required this.userId,
    this.parentId,
    required this.name,
    this.color,
    this.createdAt,
    this.updatedAt,
  });

  factory MateriFolder.fromJson(Map<String, dynamic> json) {
    return MateriFolder(
      id: json['id'] ?? 0,
      userId: json['user_id'] ?? 0,
      parentId: json['parent_id'],
      name: json['name'] ?? '',
      color: json['color'],
      createdAt: json['created_at'] != null ? DateTime.tryParse(json['created_at']) : null,
      updatedAt: json['updated_at'] != null ? DateTime.tryParse(json['updated_at']) : null,
    );
  }
}

class MateriFile {
  final int id;
  final int userId;
  final int? folderId;
  final String name;
  final int size;
  final String type;
  final String path;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  MateriFile({
    required this.id,
    required this.userId,
    this.folderId,
    required this.name,
    required this.size,
    required this.type,
    required this.path,
    this.createdAt,
    this.updatedAt,
  });

  factory MateriFile.fromJson(Map<String, dynamic> json) {
    return MateriFile(
      id: json['id'] ?? 0,
      userId: json['user_id'] ?? 0,
      folderId: json['folder_id'],
      name: json['name'] ?? '',
      size: json['size'] ?? 0,
      type: json['type'] ?? '',
      path: json['path'] ?? '',
      createdAt: json['created_at'] != null ? DateTime.tryParse(json['created_at']) : null,
      updatedAt: json['updated_at'] != null ? DateTime.tryParse(json['updated_at']) : null,
    );
  }
}
