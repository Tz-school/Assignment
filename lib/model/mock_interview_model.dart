class MockInterviewModel {
  final int? id;
  final String username;
  final String requestType; // e.g., 'Mock Interview', 'Career Advisory'
  final String date;
  final String status;      // 'Pending', 'Accepted', 'Rejected'
  final String? advisor;
  final String? notes;

  // New fields for location and admin assignment
  final String? preferredLocation;
  final String? assignedTime;
  final String? venue;
  final int? durationMinutes;

  MockInterviewModel({
    this.id,
    required this.username,
    required this.requestType,
    required this.date,
    this.status = 'Pending',
    this.advisor,
    this.notes,
    this.preferredLocation,
    this.assignedTime,
    this.venue,
    this.durationMinutes,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'username': username,
      'requestType': requestType,
      'date': date,
      'status': status,
      'advisor': advisor,
      'notes': notes,
      'preferredLocation': preferredLocation,
      'assignedTime': assignedTime,
      'venue': venue,
      'durationMinutes': durationMinutes,
    };
  }

  factory MockInterviewModel.fromMap(Map<String, dynamic> map) {
    return MockInterviewModel(
      id: map['id'],
      username: map['username'] ?? '',
      requestType: map['requestType'] ?? 'Mock Interview',
      date: map['date'] ?? '',
      status: map['status'] ?? 'Pending',
      advisor: map['advisor'],
      notes: map['notes'],
      preferredLocation: map['preferredLocation'],
      assignedTime: map['assignedTime'],
      venue: map['venue'],
      durationMinutes: map['durationMinutes'],
    );
  }
}