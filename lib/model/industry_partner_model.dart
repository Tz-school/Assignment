class IndustryPartner {
  final int? id;
  final int? userId;
  final String companyName;
  final String email;
  final String contactNumber;
  final String location;
  final String state;
  final String photoPath;

  IndustryPartner({
    this.id,
    this.userId,
    required this.companyName,
    required this.email,
    required this.contactNumber,
    required this.location,
    required this.state,
    required this.photoPath,
  });

  Map<String, dynamic> toMap({int? assignedUserId}) {
    return {
      'id': id,
      'userId': assignedUserId ?? userId,
      'companyName': companyName,
      'email': email,
      'contactNumber': contactNumber,
      'location': location,
      'state': state,
      'photoPath': photoPath,
    };
  }

  factory IndustryPartner.fromMap(Map<String, dynamic> map) {
    return IndustryPartner(
      id: map['id'] as int?,
      userId: map['userId'] as int?,
      companyName: map['companyName'] ?? '',
      email: map['email'] ?? '',
      contactNumber: map['contactNumber'] ?? '',
      location: map['location'] ?? '',
      state: map['state'] as String?? '',
      photoPath: map['photoPath'] ?? '',
    );
  }
}