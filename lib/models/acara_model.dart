/// Model untuk data Acara/Activity
class Acara {
  final int id;
  final String title;
  final String date;
  final String time;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  Acara({
    required this.id,
    required this.title,
    required this.date,
    required this.time,
    this.createdAt,
    this.updatedAt,
  });

  /// Membuat instance Acara dari JSON
  factory Acara.fromJson(Map<String, dynamic> json) {
    return Acara(
      id: json['id'] ?? 0,
      title: json['title'] ?? '',
      date: json['date'] ?? '',
      time: json['time'] ?? '',
      createdAt: json['created_at'] != null 
          ? DateTime.tryParse(json['created_at']) 
          : null,
      updatedAt: json['updated_at'] != null 
          ? DateTime.tryParse(json['updated_at']) 
          : null,
    );
  }

  /// Mengkonversi instance Acara ke JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'date': date,
      'time': time,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  /// Membuat copy Acara dengan perubahan tertentu
  Acara copyWith({
    int? id,
    String? title,
    String? date,
    String? time,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Acara(
      id: id ?? this.id,
      title: title ?? this.title,
      date: date ?? this.date,
      time: time ?? this.time,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  /// Mendapatkan DateTime gabungan dari date dan time
  DateTime get dateTime {
    try {
      final dateParts = date.split('-');
      final timeParts = time.split(':');
      return DateTime(
        int.parse(dateParts[0]), // year
        int.parse(dateParts[1]), // month
        int.parse(dateParts[2]), // day
        int.parse(timeParts[0]), // hour
        int.parse(timeParts[1]), // minute
      );
    } catch (e) {
      return DateTime.now();
    }
  }

  /// Format tanggal yang lebih readable
  String get formattedDate {
    try {
      final dt = DateTime.parse(date);
      final months = [
        'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun',
        'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des'
      ];
      return '${dt.day} ${months[dt.month - 1]} ${dt.year}';
    } catch (e) {
      return date;
    }
  }
}
