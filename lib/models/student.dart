class Student {
  final int? id;
  final String fullName;
  final String group;
  final String phone;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  Student({
    this.id,
    required this.fullName,
    required this.group,
    required this.phone,
    this.createdAt,
    this.updatedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'full_name': fullName,
      'group_name': group,
      'phone': phone,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  factory Student.fromMap(Map<String, dynamic> map) {
    return Student(
      id: map['id']?.toInt(),
      fullName: map['full_name'] ?? '',
      group: map['group_name'] ?? '',
      phone: map['phone'] ?? '',
      createdAt: map['created_at'] != null
          ? DateTime.parse(map['created_at'])
          : null,
      updatedAt: map['updated_at'] != null
          ? DateTime.parse(map['updated_at'])
          : null,
    );
  }

  Student copyWith({
    int? id,
    String? fullName,
    String? group,
    String? phone,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Student(
      id: id ?? this.id,
      fullName: fullName ?? this.fullName,
      group: group ?? this.group,
      phone: phone ?? this.phone,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
