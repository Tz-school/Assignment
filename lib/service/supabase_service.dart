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


  Future<void> deleteResume(int id) async {
    await _supabase.from('resumes').delete().eq('id', id);
  }

  String makeConversationId(
      String username1,
      String username2,
      ) {
    final names = [
      username1,
      username2,
    ]..sort();

    return '${names[0]}_${names[1]}';
  }

  Future<void> sendChatMessage({
    required String senderUsername,
    required String receiverUsername,
    required String message,
  }) async {
    final conversationId =
    makeConversationId(
      senderUsername,
      receiverUsername,
    );

    await _supabase
        .from('chat_messages')
        .insert({
      'conversation_id': conversationId,
      'sender_username': senderUsername,
      'receiver_username': receiverUsername,
      'message': message,
      'created_at':
      DateTime.now().toIso8601String(),
      'is_read': false,
    });
  }

  Future<List<Map<String, dynamic>>> getChatMessages({
    required String username1,
    required String username2,
  }) async {
    final conversationId =
    makeConversationId(
      username1,
      username2,
    );

    final data = await _supabase
        .from('chat_messages')
        .select()
        .eq(
      'conversation_id',
      conversationId,
    )
        .order(
      'created_at',
      ascending: true,
    );

    return List<Map<String, dynamic>>.from(
      data,
    );
  }

  Future<void> markMessagesAsRead({
    required String currentUsername,
    required String otherUsername,
  }) async {
    await _supabase
        .from('chat_messages')
        .update({
      'is_read': true,
    })
        .eq(
      'sender_username',
      otherUsername,
    )
        .eq(
      'receiver_username',
      currentUsername,
    )
        .eq(
      'is_read',
      false,
    );
  }

  Future<List<Map<String, dynamic>>> getChatList({
    required String username,
  }) async {

    final sent = await _supabase
        .from('chat_messages')
        .select()
        .eq(
      'sender_username',
      username,
    )
        .order(
      'created_at',
      ascending: false,
    );

    final received = await _supabase
        .from('chat_messages')
        .select()
        .eq(
      'receiver_username',
      username,
    )
        .order(
      'created_at',
      ascending: false,
    );

    final allMessages = [
      ...List<Map<String, dynamic>>.from(sent),
      ...List<Map<String, dynamic>>.from(received),
    ];


    allMessages.sort((a, b) {
      final dateA =
          DateTime.tryParse(
            a['created_at']
                ?.toString() ??
                '',
          ) ??
              DateTime(2000);

      final dateB =
          DateTime.tryParse(
            b['created_at']
                ?.toString() ??
                '',
          ) ??
              DateTime(2000);

      return dateB.compareTo(dateA);
    });

    final Map<String, Map<String, dynamic>>
    conversations = {};

    for (final message in allMessages) {
      final sender =
          message['sender_username']
              ?.toString() ??
              '';

      final receiver =
          message['receiver_username']
              ?.toString() ??
              '';

      final otherUsername =
      sender == username
          ? receiver
          : sender;

      if (otherUsername.isEmpty) {
        continue;
      }

      if (!conversations
          .containsKey(otherUsername)) {
        conversations[otherUsername] = {
          'otherUsername':
          otherUsername,
          'lastMessage':
          message['message']
              ?.toString() ??
              '',
          'lastMessageTime':
          message['created_at'],
          'unread': 0,
        };
      }
    }
    for (final message in allMessages) {
      final sender =
          message['sender_username']
              ?.toString() ??
              '';
      final receiver =
          message['receiver_username']
              ?.toString() ??
              '';
      if (receiver == username &&
          message['is_read'] == false) {
        final otherUsername = sender;
        if (conversations
            .containsKey(otherUsername)) {
          conversations[otherUsername]![
          'unread'] =
              (conversations[otherUsername]![
              'unread'] ??
                  0) + 1;
        }
      }
    }
    return conversations.values.toList();
  }
  Future<int> getUnreadChatCount({
    required String username,
  }) async {
    final data = await _supabase
        .from('chat_messages')
        .select('id')
        .eq('receiver_username', username)
        .eq('is_read', false);

    return data.length;
  }
}