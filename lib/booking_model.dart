class BookingModel {
  final int? id;
  final String studentName;
  final String bookingType; // 'Career Fair', 'Mock Interview', etc.
  final String date;
  String status; // 'Pending', 'Approved', 'Rejected', 'Cancelled'
  String? assignedAdvisor; // Set by admin

  BookingModel({
    this.id,
    required this.studentName,
    required this.bookingType,
    required this.date,
    this.status = 'Pending',
    this.assignedAdvisor,
  });

  factory BookingModel.fromJson(Map<String, dynamic> data) => BookingModel(
    id: data['id'],
    studentName: data['studentName'] ?? 'Student',
    bookingType: data['bookingType'] ?? data['itemName'] ?? 'General',
    date: data['date'],
    status: data['status'] ?? 'Pending',
    assignedAdvisor: data['assignedAdvisor'],
  );

  Map<String, dynamic> toMap() => {
    'id': id,
    'studentName': studentName,
    'bookingType': bookingType,
    'date': date,
    'status': status,
    'assignedAdvisor': assignedAdvisor,
  };
}

class EventModel {
  int? id;
  String title;
  String speaker;
  String venue;
  String date;
  String time;
  int capacity;
  int booked;

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
      id: map['id'],
      title: map['title'],
      speaker: map['speaker'],
      venue: map['venue'],
      date: map['date'],
      time: map['time'],
      capacity: map['capacity'],
      booked: map['booked'],
    );
  }
}