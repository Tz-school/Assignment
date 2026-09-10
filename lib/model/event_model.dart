class EventModel {
  final int? id;
  final String title;
  final String description;
  final String speaker;
  final String venue;
  final String date;
  final String time;
  final int capacity;
  final int booked;

  EventModel({
    this.id,
    required this.title,
    required this.description,
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
      'description': description,
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
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      speaker: map['speaker'] ?? '',
      venue: map['venue'] ?? '',
      date: map['date'] ?? '',
      time: map['time'] ?? '',
      capacity: map['capacity'] ?? 0,
      booked: map['booked'] ?? 0,
    );
  }
}