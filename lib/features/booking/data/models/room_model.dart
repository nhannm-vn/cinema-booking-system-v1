/// Room model mapping from PostgreSQL `rooms` table.
/// References: TECH_STACK.md Section 4 & BUSINESS_RULES.md Section 3.2
class RoomModel {
  final String id;
  final String cinemaId;
  final String name;
  final List<String> formats;
  final int rows;
  final int cols;
  final List<String> seatLayout;
  final int seatCount;

  const RoomModel({
    required this.id,
    required this.cinemaId,
    required this.name,
    required this.formats,
    required this.rows,
    required this.cols,
    required this.seatLayout,
    required this.seatCount,
  });

  factory RoomModel.fromMap(Map<String, dynamic> map) {
    return RoomModel(
      id: map['id'] as String,
      cinemaId: map['cinema_id'] as String,
      name: map['name'] as String,
      formats: List<String>.from(map['formats'] ?? ['2D']),
      rows: map['rows'] as int,
      cols: map['cols'] as int,
      seatLayout: List<String>.from(map['seat_layout'] ?? []),
      seatCount: map['seat_count'] as int,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'cinema_id': cinemaId,
      'name': name,
      'formats': formats,
      'rows': rows,
      'cols': cols,
      'seat_layout': seatLayout,
      'seat_count': seatCount,
    };
  }
}
