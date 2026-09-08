class EventModel {
  final int? id;
  final String title;
  final String speaker;
  final String venue;
  final String date;
  final String time;
  final int capacity;
  final int booked;

  EventModel({
    this.id,
    required this.title,
    required this.speaker,
    required this.venue,
    required this.date,
    required this.time,
    required this.capacity,
    this.booked = 0,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'speaker': speaker,
      'venue': venue,
      'date': date,
      'time': time,
      'capacity': capacity,
      'booked': booked,
    };
  }

  factory EventModel.fromMap(Map<String, dynamic> map) {
    return EventModel(
      id: map['id'] as int?,
      title: map['title'] as String? ?? '',
      speaker: map['speaker'] as String? ?? '',
      venue: map['venue'] as String? ?? '',
      date: map['date'] as String? ?? '',
      time: map['time'] as String? ?? '',
      capacity: map['capacity'] as int? ?? 0,
      booked: map['booked'] as int? ?? 0,
    );
  }
}