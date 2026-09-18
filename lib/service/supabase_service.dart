import 'package:supabase_flutter/supabase_flutter.dart';
import '../model/resume_model.dart';
import '../model/event_model.dart';
import '../model/event_registration_model.dart';

class SupabaseService {
  final SupabaseClient _supabase = Supabase.instance.client;


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
      username1.trim(),
      username2.trim(),
    ]..sort();

    return '${names[0]}_${names[1]}';
  }

  Future<void> sendChatMessage({
    required String senderUsername,
    required String receiverUsername,
    required String message,
  }) async {
    final sender = senderUsername.trim();
    final receiver = receiverUsername.trim();
    final text = message.trim();

    if (sender.isEmpty || receiver.isEmpty || text.isEmpty) {
      throw Exception('Username or message is empty');
    }

    final conversationId = makeConversationId(
      sender,
      receiver,
    );

    await _supabase.from('chat_messages').insert({
      'conversation_id': conversationId,
      'sender_username': sender,
      'receiver_username': receiver,
      'message': text,
      'created_at': DateTime.now().toIso8601String(),
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
    final currentUsername = username.trim();

    if (currentUsername.isEmpty) {
      return [];
    }

    final sent = await _supabase
        .from('chat_messages')
        .select()
        .eq('sender_username', currentUsername)
        .order('created_at', ascending: false);

    final received = await _supabase
        .from('chat_messages')
        .select()
        .eq('receiver_username', currentUsername)
        .order('created_at', ascending: false);

    final allMessages = [
      ...List<Map<String, dynamic>>.from(sent),
      ...List<Map<String, dynamic>>.from(received),
    ];

    // Sort newest message first.
    allMessages.sort((a, b) {
      final dateA = DateTime.tryParse(
        a['created_at']?.toString() ?? '',
      ) ??
          DateTime(2000);

      final dateB = DateTime.tryParse(
        b['created_at']?.toString() ?? '',
      ) ??
          DateTime(2000);

      return dateB.compareTo(dateA);
    });

    final Map<String, Map<String, dynamic>> conversations = {};

    for (final message in allMessages) {
      final sender =
          message['sender_username']?.toString().trim() ?? '';

      final receiver =
          message['receiver_username']?.toString().trim() ?? '';

      String otherUsername;

      if (sender == currentUsername) {
        otherUsername = receiver;
      } else {
        otherUsername = sender;
      }

      if (otherUsername.isEmpty) {
        continue;
      }

      if (!conversations.containsKey(otherUsername)) {
        conversations[otherUsername] = {
          'otherUsername': otherUsername,
          'lastMessage':
          message['message']?.toString() ?? '',
          'lastMessageTime':
          message['created_at'],
          'unread': 0,
        };
      }
    }

    // Count unread messages.
    for (final message in allMessages) {
      final sender =
          message['sender_username']?.toString().trim() ?? '';

      final receiver =
          message['receiver_username']?.toString().trim() ?? '';

      final isRead = message['is_read'] == true;

      if (receiver == currentUsername && !isRead) {
        if (conversations.containsKey(sender)) {
          conversations[sender]!['unread'] =
              (conversations[sender]!['unread'] ?? 0) + 1;
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

  // =====================================================================
  // USERS — migrated from local sqlite (DatabaseService) to Supabase.
  // Table: public.users (see supabase_schema.sql)
  // =====================================================================

  Future<int?> registerUser(
      String username,
      String password,
      String role,
      ) async {
    // Throws a PostgrestException on duplicate username (unique constraint),
    // same as the old sqlite UNIQUE constraint did — callers already catch this.
    final response = await _supabase.from('users').insert({
      'username': username,
      'password': password,
      'role': role,
    }).select('id').single();

    return response['id'] as int?;
  }

  Future<Map<String, dynamic>?> loginUser(
      String username,
      String password,
      ) async {
    final data = await _supabase
        .from('users')
        .select()
        .eq('username', username)
        .eq('password', password);

    final results = List<Map<String, dynamic>>.from(data);
    if (results.isEmpty) {
      return null;
    }

    final user = Map<String, dynamic>.from(results.first);
    final bannedValue = user['Banned']?.toString().trim().toLowerCase();

    if (bannedValue == 'yes') {
      return {...user, 'isBanned': true};
    }

    return {...user, 'isBanned': false};
  }

  Future<int?> getUserId(String username) async {
    final data = await _supabase
        .from('users')
        .select('id')
        .eq('username', username);

    final results = List<Map<String, dynamic>>.from(data);
    if (results.isEmpty) return null;
    return results.first['id'] as int?;
  }

  Future<Map<String, dynamic>?> getUserProfile(String username) async {
    final data = await _supabase.from('users').select().eq(
      'username',
      username,
    );
    final results = List<Map<String, dynamic>>.from(data);
    return results.isNotEmpty ? results.first : null;
  }

  Future<int> updateUserProfile(
      String username, {
        String? name,
        String? email,
        String? phone,
        String? state,
        String? photoPath,
      }) async {
    final updates = <String, dynamic>{};
    if (name != null) updates['name'] = name;
    if (email != null) updates['email'] = email;
    if (phone != null) updates['phone'] = phone;
    if (state != null) updates['state'] = state;
    if (photoPath != null) updates['photoPath'] = photoPath;

    if (updates.isEmpty) return 0;

    final response = await _supabase
        .from('users')
        .update(updates)
        .eq('username', username)
        .select('id');

    return List<Map<String, dynamic>>.from(response).length;
  }

  Future<bool> changePassword(
      String username,
      String currentPassword,
      String newPassword,
      ) async {
    final match = await _supabase
        .from('users')
        .select('id')
        .eq('username', username)
        .eq('password', currentPassword);

    if (List<Map<String, dynamic>>.from(match).isEmpty) return false;

    await _supabase
        .from('users')
        .update({'password': newPassword})
        .eq('username', username);

    return true;
  }

  Future<List<Map<String, dynamic>>> getCareerCounselors() async {
    final data = await _supabase
        .from('users')
        .select()
        .eq('role', 'Career Counselor');

    return List<Map<String, dynamic>>.from(data);
  }

  Future<List<Map<String, dynamic>>> getStudentUsers() async {
    final data = await _supabase
        .from('users')
        .select()
        .eq('role', 'student');

    final results = List<Map<String, dynamic>>.from(data);

    // Mirrors the old `ORDER BY LOWER(COALESCE(name, username)) ASC`.
    results.sort((a, b) {
      final an = (a['name'] ?? a['username'] ?? '').toString().toLowerCase();
      final bn = (b['name'] ?? b['username'] ?? '').toString().toLowerCase();
      return an.compareTo(bn);
    });

    return results;
  }

  Future<int> updateUserBanStatus({
    required String username,
    required bool banned,
  }) async {
    final response = await _supabase
        .from('users')
        .update({'Banned': banned ? 'Yes' : 'No'})
        .eq('username', username)
        .eq('role', 'student')
        .select('id');

    return List<Map<String, dynamic>>.from(response).length;
  }

  // =====================================================================
  // EVENTS — migrated from local sqlite (DatabaseService) to Supabase.
  // Table: public.events (see supabase_schema.sql)
  // =====================================================================

  Future<int?> insertEvent(EventModel event) async {
    // EventModel.toMap() always includes an 'id' key (null for new events).
    // events.id is `generated always as identity`, so Postgres rejects any
    // explicit value for it — including an explicit null — unless the query
    // uses OVERRIDING SYSTEM VALUE. Drop it so the identity column can
    // generate its own value.
    final payload = event.toMap()..remove('id');

    final response = await _supabase
        .from('events')
        .insert(payload)
        .select('id')
        .single();

    return response['id'] as int?;
  }

  Future<void> deleteEvent(int id) async {
    await _supabase.from('events').delete().eq('id', id);
  }

  Future<List<EventModel>> getEvents() async {
    final data = await _supabase.from('events').select();
    return List<Map<String, dynamic>>.from(
      data,
    ).map((m) => EventModel.fromMap(m)).toList();
  }

  Future<EventModel?> getEventById(int id) async {
    final data = await _supabase.from('events').select().eq('id', id);
    final results = List<Map<String, dynamic>>.from(data);
    if (results.isEmpty) return null;
    return EventModel.fromMap(results.first);
  }

  Future<void> incrementEventBooking(int eventId, int currentBooked) async {
    await _supabase
        .from('events')
        .update({'booked': currentBooked + 1})
        .eq('id', eventId);
  }

  // =====================================================================
  // EVENT REGISTRATIONS — migrated from local sqlite (DatabaseService).
  // Table: public.event_registrations (see supabase_schema.sql)
  //
  // NOTE: PostgREST/Supabase doesn't do the same ad-hoc SQL JOIN the old
  // rawQuery() calls did, so the "join" style methods below fetch the
  // related rows and stitch them together client-side, but return maps
  // shaped exactly like the old rawQuery() results so EventRegistrationModel
  // .fromMap() keeps working unchanged.
  // =====================================================================

  Future<bool> hasUserRegistered(int userId, int eventId) async {
    final data = await _supabase
        .from('event_registrations')
        .select('id')
        .eq('userId', userId)
        .eq('eventId', eventId);

    return List<Map<String, dynamic>>.from(data).isNotEmpty;
  }

  Future<int?> registerForEvent(int userId, int eventId) async {
    final response = await _supabase.from('event_registrations').insert({
      'userId': userId,
      'eventId': eventId,
      'status': 'pending',
    }).select('id').single();

    return response['id'] as int?;
  }

  Future<List<EventRegistrationModel>> getUserRegistrations(
      int userId,
      ) async {
    final regData = await _supabase
        .from('event_registrations')
        .select()
        .eq('userId', userId);

    final registrations = List<Map<String, dynamic>>.from(regData);
    if (registrations.isEmpty) return [];

    final eventIds = registrations
        .map((r) => r['eventId'])
        .whereType<int>()
        .toSet()
        .toList();

    final eventData = await _supabase
        .from('events')
        .select('id, title, date, time')
        .inFilter('id', eventIds);

    final eventsById = {
      for (final e in List<Map<String, dynamic>>.from(eventData)) e['id']: e,
    };

    // EventRegistrationModel.fromMap requires eventTitle/date/time to be
    // non-null, and the old query used an INNER JOIN so a registration whose
    // event no longer exists simply wouldn't appear. Match that behavior
    // here instead of crashing on the null cast.
    final merged = registrations
        .where((r) => eventsById.containsKey(r['eventId']))
        .map((r) {
      final event = eventsById[r['eventId']]!;
      return {
        'registrationId': r['id'],
        'status': r['status'],
        'eventTitle': event['title'],
        'date': event['date'],
        'time': event['time'],
        'eventId': r['eventId'],
      };
    })
        .toList();

    return merged.map((m) => EventRegistrationModel.fromMap(m)).toList();
  }

  Future<List<EventRegistrationModel>> getAllRegistrations() async {
    final regData = await _supabase.from('event_registrations').select();
    final registrations = List<Map<String, dynamic>>.from(regData);
    if (registrations.isEmpty) return [];

    final eventIds = registrations
        .map((r) => r['eventId'])
        .whereType<int>()
        .toSet()
        .toList();
    final userIds = registrations
        .map((r) => r['userId'])
        .whereType<int>()
        .toSet()
        .toList();

    final eventData = await _supabase
        .from('events')
        .select('id, title, date, time')
        .inFilter('id', eventIds);
    final userData = await _supabase
        .from('users')
        .select('id, username')
        .inFilter('id', userIds);

    final eventsById = {
      for (final e in List<Map<String, dynamic>>.from(eventData)) e['id']: e,
    };
    final usersById = {
      for (final u in List<Map<String, dynamic>>.from(userData)) u['id']: u,
    };

    // Same reasoning as getUserRegistrations: drop registrations whose event
    // no longer exists rather than passing nulls into a non-nullable cast.
    final merged = registrations
        .where((r) => eventsById.containsKey(r['eventId']))
        .map((r) {
      final event = eventsById[r['eventId']]!;
      final user = usersById[r['userId']];
      return {
        'registrationId': r['id'],
        'status': r['status'],
        'username': user?['username'],
        'userId': r['userId'],
        'eventTitle': event['title'],
        'date': event['date'],
        'time': event['time'],
        'eventId': r['eventId'],
      };
    })
        .toList();

    return merged.map((m) => EventRegistrationModel.fromMap(m)).toList();
  }

  Future<void> updateRegistrationStatus(
      int registrationId,
      int eventId,
      String newStatus,
      ) async {
    // Look up the registration's CURRENT status before overwriting it, so we
    // know whether this transition is entering or leaving 'accepted'. The
    // events.booked counter must only ever be adjusted on that transition —
    // not on every status change — or it drifts out of sync with reality
    // (e.g. a student cancelling an accepted booking used to leave `booked`
    // stuck at its old value forever, since only the accept path touched it).
    final currentReg = await _supabase
        .from('event_registrations')
        .select('status')
        .eq('id', registrationId)
        .single();
    final previousStatus = (currentReg['status'] as String?)?.toLowerCase() ?? '';
    final nextStatus = newStatus.toLowerCase();

    await _supabase
        .from('event_registrations')
        .update({'status': newStatus})
        .eq('id', registrationId);

    final wasAccepted = previousStatus == 'accepted';
    final isNowAccepted = nextStatus == 'accepted';

    // Only adjust the counter on an actual accepted <-> not-accepted flip.
    if (wasAccepted == isNowAccepted) return;

    final eventRow = await _supabase
        .from('events')
        .select('booked')
        .eq('id', eventId)
        .single();

    final currentBooked = (eventRow['booked'] as int?) ?? 0;

    // Entering 'accepted' -> +1. Leaving 'accepted' (cancelled/rejected/etc)
    // -> -1, clamped at 0 so a stray double-decrement can never go negative.
    final updatedBooked = isNowAccepted
        ? currentBooked + 1
        : (currentBooked - 1).clamp(0, 1 << 30);

    await _supabase
        .from('events')
        .update({'booked': updatedBooked})
        .eq('id', eventId);
  }

  Future<List<String>> getAcceptedParticipants(int eventId) async {
    final regData = await _supabase
        .from('event_registrations')
        .select('userId')
        .eq('eventId', eventId)
        .eq('status', 'accepted');

    final userIds = List<Map<String, dynamic>>.from(
      regData,
    ).map((r) => r['userId']).whereType<int>().toSet().toList();

    if (userIds.isEmpty) return [];

    final userData = await _supabase
        .from('users')
        .select('username')
        .inFilter('id', userIds);

    return List<Map<String, dynamic>>.from(
      userData,
    ).map((u) => u['username'] as String).toList();
  }
}