class Room {
  final int? id;
  final String number;
  final int capacity;
  final int occupied;
  final int? floor;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  Room({
    this.id,
    required this.number,
    required this.capacity,
    this.occupied = 0,
    this.floor,
    this.createdAt,
    this.updatedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'room_number': number,
      'capacity': capacity,
      'occupied': occupied,
      'floor': floor,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  factory Room.fromMap(Map<String, dynamic> map) {
    return Room(
      id: map['id']?.toInt(),
      number: map['room_number'] ?? '',
      capacity: map['capacity']?.toInt() ?? 0,
      occupied: map['occupied']?.toInt() ?? 0,
      floor: map['floor']?.toInt(),
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
    int? occupied,
    int? floor,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Room(
      id: id ?? this.id,
      number: number ?? this.number,
      capacity: capacity ?? this.capacity,
      occupied: occupied ?? this.occupied,
      floor: floor ?? this.floor,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
