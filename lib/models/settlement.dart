class Settlement {
  final int? id;
  final int studentId;
  final int roomId;
  final DateTime startDate;
  final DateTime? endDate;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  Settlement({
    this.id,
    required this.studentId,
    required this.roomId,
    required this.startDate,
    this.endDate,
    this.createdAt,
    this.updatedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'student_id': studentId,
      'room_id': roomId,
      'start_date': startDate.toIso8601String(),
      'end_date': endDate?.toIso8601String(),
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  factory Settlement.fromMap(Map<String, dynamic> map) {
    return Settlement(
      id: map['id']?.toInt(),
      studentId: map['student_id']?.toInt() ?? 0,
      roomId: map['room_id']?.toInt() ?? 0,
      startDate: DateTime.parse(map['start_date']),
      endDate: map['end_date'] != null 
          ? DateTime.parse(map['end_date']) 
          : null,
      createdAt: map['created_at'] != null 
          ? DateTime.parse(map['created_at']) 
          : null,
      updatedAt: map['updated_at'] != null 
          ? DateTime.parse(map['updated_at']) 
          : null,
    );
  }

  Settlement copyWith({
    int? id,
    int? studentId,
    int? roomId,
    DateTime? startDate,
    DateTime? endDate,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Settlement(
      id: id ?? this.id,
      studentId: studentId ?? this.studentId,
      roomId: roomId ?? this.roomId,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
