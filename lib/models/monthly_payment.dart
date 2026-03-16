class MonthlyPayment {
  final int? id;
  final int studentId;
  final double amount;
  final String month; // Формат: '2024-01'
  final String description;
  final bool isPaid;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  MonthlyPayment({
    this.id,
    required this.studentId,
    required this.amount,
    required this.month,
    required this.description,
    this.isPaid = false,
    this.createdAt,
    this.updatedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'student_id': studentId,
      'amount': amount,
      'month': month,
      'description': description,
      'is_paid': isPaid ? 1 : 0,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  factory MonthlyPayment.fromMap(Map<String, dynamic> map) {
    return MonthlyPayment(
      id: map['id']?.toInt(),
      studentId: map['student_id']?.toInt() ?? 0,
      amount: map['amount']?.toDouble() ?? 0.0,
      month: map['month'] ?? '',
      description: map['description'] ?? '',
      isPaid: (map['is_paid'] ?? 0) == 1,
      createdAt: map['created_at'] != null 
          ? DateTime.parse(map['created_at']) 
          : null,
      updatedAt: map['updated_at'] != null 
          ? DateTime.parse(map['updated_at']) 
          : null,
    );
  }

  MonthlyPayment copyWith({
    int? id,
    int? studentId,
    double? amount,
    String? month,
    String? description,
    bool? isPaid,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return MonthlyPayment(
      id: id ?? this.id,
      studentId: studentId ?? this.studentId,
      amount: amount ?? this.amount,
      month: month ?? this.month,
      description: description ?? this.description,
      isPaid: isPaid ?? this.isPaid,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
