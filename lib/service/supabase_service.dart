import 'package:supabase_flutter/supabase_flutter.dart';
import '../model/resume_model.dart';

class SupabaseService {
  final SupabaseClient _supabase = Supabase.instance.client;

  // 1. Save Address to Supabase 'user_addresses' table
  Future<void> saveAddress({
    required String userId,
    required String address,
    double? latitude,
    double? longitude,
  }) async {
    await _supabase.from('user_addresses').upsert({
      'user_id': userId,
      'address': address,
      'latitude': latitude,
      'longitude': longitude,
      'updated_at': DateTime.now().toIso8601String(),
    });
  }

  // 2. Insert Resume into Supabase 'resumes' table
  Future<int?> insertResume(ResumeData resume) async {
    final response = await _supabase.from('resumes').insert({
      'full_name': resume.fullName,
      'age': resume.age,
      'gender': resume.gender,
      'email': resume.email,
      'phone': resume.phone,
      'address': resume.address,
      'summary': resume.summary,
      'experience': resume.experience,
      'education': resume.education,
      'created_at': DateTime.now().toIso8601String(),
    }).select('id').single();

    return response['id'] as int?;
  }

  // 3. Update Resume in Supabase
  Future<void> updateResume(ResumeData resume) async {
    if (resume.id == null) return;
    await _supabase.from('resumes').update({
      'full_name': resume.fullName,
      'age': resume.age,
      'gender': resume.gender,
      'email': resume.email,
      'phone': resume.phone,
      'address': resume.address,
      'summary': resume.summary,
      'experience': resume.experience,
      'education': resume.education,
    }).eq('id', resume.id!);
  }

  // 4. Delete Resume from Supabase
  Future<void> deleteResume(int id) async {
    await _supabase.from('resumes').delete().eq('id', id);
  }
}