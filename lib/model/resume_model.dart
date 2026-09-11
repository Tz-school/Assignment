import 'dart:io';

class ResumeData {
  final int? id;
  final File profileImage;
  final File? certificateImage;
  final String fullName;
  final String age;
  final String gender;
  final String email;
  final String phone;
  final String address;
  final String summary;
  final String experience;
  final String education;

  ResumeData({
    this.id,
    required this.profileImage,
    this.certificateImage,
    required this.fullName,
    required this.age,
    required this.gender,
    required this.email,
    required this.phone,
    required this.address,
    required this.summary,
    required this.experience,
    required this.education,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'profileImage': profileImage.path,
      'certificateImage': certificateImage?.path,
      'fullName': fullName,
      'age': age,
      'gender': gender,
      'email': email,
      'phone': phone,
      'address': address,
      'summary': summary,
      'experience': experience,
      'education': education,
    };
  }

  factory ResumeData.fromMap(Map<String, dynamic> map) {
    return ResumeData(
      id: map['id'] as int?,
      profileImage: File(map['profileImage']),
      certificateImage: map['certificateImage'] != null
          ? File(map['certificateImage'])
          : null,
      fullName: map['fullName'] ?? '',
      age: map['age'] ?? '',
      gender: map['gender'] ?? '',
      email: map['email'] ?? '',
      phone: map['phone'] ?? '',
      address: map['address'] ?? '',
      summary: map['summary'] ?? '',
      experience: map['experience'] ?? '',
      education: map['education'] ?? '',
    );
  }
}