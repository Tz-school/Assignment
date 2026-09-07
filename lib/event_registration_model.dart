class EventRegistrationModel {
  final int registrationId;
  final int eventId;
  final int? userId;
  final String? username;
  final String eventTitle;
  final String date;
  final String time;
  final String status;

  EventRegistrationModel({
    required this.registrationId,
    required this.eventId,
    this.userId,
    this.username,
    required this.eventTitle,
    required this.date,
    required this.time,
    required this.status,
  });

  factory EventRegistrationModel.fromMap(Map<String, dynamic> map) {
    return EventRegistrationModel(
      registrationId: map['registrationId'] as int,
      eventId: map['eventId'] as int,
      userId: map['userId'] as int?,
      username: map['username'] as String?,
      eventTitle: map['eventTitle'] as String,
      date: map['date'] as String,
      time: map['time'] as String,
      status: map['status'] as String,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'registrationId': registrationId,
      'eventId': eventId,
      'userId': userId,
      'username': username,
      'eventTitle': eventTitle,
      'date': date,
      'time': time,
      'status': status,
    };
  }
}