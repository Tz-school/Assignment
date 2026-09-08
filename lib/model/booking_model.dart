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