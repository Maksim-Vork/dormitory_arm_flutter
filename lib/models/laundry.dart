enum LaundryType {
  washLinen('wash_linen', 'Стирка белья', 150.0),
  changeBedLinen('change_bed_linen', 'Смена постельного белья', 200.0),
  washBlanket('wash_blanket', 'Стирка одеяла', 300.0),
  dryCleaning('dry_cleaning', 'Химчистка', 500.0);

  const LaundryType(this.value, this.displayName, this.price);

  final String value;
  final String displayName;
  final double price;

  static LaundryType fromString(String value) {
    return LaundryType.values.firstWhere(
      (type) => type.value == value,
      orElse: () => LaundryType.washLinen,
    );
  }
}

class Laundry {
  final int? id;
  final int studentId;
  final LaundryType type;
  final DateTime performedAt;
  final DateTime? createdAt;

  Laundry({
    this.id,
    required this.studentId,
    required this.type,
    required this.performedAt,
    this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'student_id': studentId,
      'type': type.value,
      'performed_at': performedAt.toIso8601String(),
      'created_at': createdAt?.toIso8601String(),
    };
  }

  factory Laundry.fromMap(Map<String, dynamic> map) {
    return Laundry(
      id: map['id']?.toInt(),
      studentId: map['student_id']?.toInt() ?? 0,
      type: LaundryType.fromString(map['type'] ?? 'wash_linen'),
      performedAt: DateTime.parse(map['performed_at']),
      createdAt: map['created_at'] != null
          ? DateTime.parse(map['created_at'])
          : null,
    );
  }

  Laundry copyWith({
    int? id,
    int? studentId,
    LaundryType? type,
    DateTime? performedAt,
    DateTime? createdAt,
  }) {
    return Laundry(
      id: id ?? this.id,
      studentId: studentId ?? this.studentId,
      type: type ?? this.type,
      performedAt: performedAt ?? this.performedAt,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
