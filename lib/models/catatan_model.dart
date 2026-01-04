/// Model untuk data Catatan
class Catatan {
  final int id;
  final String title;
  final String content;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  Catatan({
    required this.id,
    required this.title,
    required this.content,
    this.createdAt,
    this.updatedAt,
  });

  /// Membuat instance Catatan dari JSON
  factory Catatan.fromJson(Map<String, dynamic> json) {
    return Catatan(
      id: json['id'] ?? 0,
      title: json['title'] ?? '',
      content: json['content'] ?? '',
      createdAt: json['created_at'] != null 
          ? DateTime.tryParse(json['created_at']) 
          : null,
      updatedAt: json['updated_at'] != null 
          ? DateTime.tryParse(json['updated_at']) 
          : null,
    );
  }

  /// Mengkonversi instance Catatan ke JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'content': content,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  /// Membuat copy Catatan dengan perubahan tertentu
  Catatan copyWith({
    int? id,
    String? title,
    String? content,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Catatan(
      id: id ?? this.id,
      title: title ?? this.title,
      content: content ?? this.content,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
