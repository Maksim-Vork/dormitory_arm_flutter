class Payment {
  final int? id;
  final int studentId;
  final double amount;
  final DateTime paidAt;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  Payment({
    this.id,
    required this.studentId,
    required this.amount,
    required this.paidAt,
    this.createdAt,
    this.updatedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'student_id': studentId,
      'amount': amount,
      'paid_at': paidAt.toIso8601String(),
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  factory Payment.fromMap(Map<String, dynamic> map) {
    return Payment(
      id: map['id']?.toInt(),
      studentId: map['student_id']?.toInt() ?? 0,
      amount: map['amount']?.toDouble() ?? 0.0,
      paidAt: DateTime.parse(map['paid_at']),
      createdAt: map['created_at'] != null 
          ? DateTime.parse(map['created_at']) 
          : null,
      updatedAt: map['updated_at'] != null 
          ? DateTime.parse(map['updated_at']) 
          : null,
    );
  }

  Payment copyWith({
    int? id,
    int? studentId,
    double? amount,
    DateTime? paidAt,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Payment(
      id: id ?? this.id,
      studentId: studentId ?? this.studentId,
      amount: amount ?? this.amount,
      paidAt: paidAt ?? this.paidAt,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
