class Room {
  final int? id;
  final String number;
  final int capacity;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  Room({
    this.id,
    required this.number,
    required this.capacity,
    this.createdAt,
    this.updatedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'number': number,
      'capacity': capacity,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  factory Room.fromMap(Map<String, dynamic> map) {
    return Room(
      id: map['id']?.toInt(),
      number: map['number'] ?? '',
      capacity: map['capacity']?.toInt() ?? 0,
      createdAt: map['created_at'] != null 
          ? DateTime.parse(map['created_at']) 
          : null,
      updatedAt: map['updated_at'] != null 
          ? DateTime.parse(map['updated_at']) 
          : null,
    );
  }

  Room copyWith({
    int? id,
    String? number,
    int? capacity,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Room(
      id: id ?? this.id,
      number: number ?? this.number,
      capacity: capacity ?? this.capacity,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
