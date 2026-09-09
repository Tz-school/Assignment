import 'dart:io';

class ResumeData {
  final File profileImage;
  final File? certificateImage;
  final String fullName;
  final String age;
  final String email;
  final String phone;
  final String address;
  final String summary;
  final String experience;
  final String education;

  ResumeData({
    required this.profileImage,
    this.certificateImage,
    required this.fullName,
    required this.age,
    required this.email,
    required this.phone,
    required this.address,
    required this.summary,
    required this.experience,
    required this.education,
  });
}