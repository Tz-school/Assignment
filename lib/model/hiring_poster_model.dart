class HiringPoster {
  final int? id;
  final int? userId;
  final String companyName;
  final String email;
  final String address;
  final String state;
  final String contactNumber;
  final String title;
  final String description;
  final String imagePath;
  final String datePosted;

  HiringPoster({
    this.id,
    this.userId,
    required this.companyName,
    required this.email,
    required this.address,
    required this.state,
    required this.contactNumber,
    required this.title,
    required this.description,
    required this.imagePath,
    required this.datePosted,
  });

  /// Convert a HiringPoster object into a Map for SQLite
  Map<String, dynamic> toMap({int? assignedUserId}) {
    return {
      if (id != null) 'id': id,
      'userId': assignedUserId ?? userId,
      'companyName': companyName,
      'email': email,
      'address': address,
      'state': state,
      'contactNumber': contactNumber,
      'title': title,
      'description': description,
      'imagePath': imagePath,
      'datePosted': datePosted,
    };
  }


  factory HiringPoster.fromMap(Map<String, dynamic> map) {
    return HiringPoster(
      id: map['id'] as int?,
      userId: map['userId'] as int?,
      companyName: map['companyName'] as String? ?? '',
      email: map['email'] as String? ?? '',
      address: map['address'] as String? ?? '',
      state: map['state'] as String? ?? '',
      contactNumber: map['contactNumber'] as String? ?? '',
      title: map['title'] as String? ?? '',
      description: map['description'] as String? ?? '',
      imagePath: map['imagePath'] as String? ?? '',
      datePosted: map['datePosted'] as String? ?? '',
    );
  }
}