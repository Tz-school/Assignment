import 'dart:developer';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';
import '../model/booking_model.dart';
import '../model/event_model.dart';
import '../model/event_registration_model.dart';
import '../model/industry_partner_model.dart';
import '../model/hiring_poster_model.dart';
import '../model/resume_model.dart';
import '../model/mock_interview_model.dart';
import '../model/timetable_model.dart';
import '../model/comparison_model.dart';
import 'supabase_service.dart';

class DatabaseService {
  static final DatabaseService _databaseService = DatabaseService._internal();
  factory DatabaseService() => _databaseService;
  DatabaseService._internal();

  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await initDatabase();
    return _database!;
  }

  Future<Database> initDatabase() async {
    final getDirectory = await getApplicationDocumentsDirectory();
    String path = '${getDirectory.path}/bookings.db';
    log(path);
    return await openDatabase(
      path,
      onCreate: _onCreate,
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          await db.execute('''
            CREATE TABLE IF NOT EXISTS resumes (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              profileImage TEXT NOT NULL,
              certificateImage TEXT,
              fullName TEXT NOT NULL,
              age TEXT NOT NULL,
              gender TEXT NOT NULL,
              email TEXT NOT NULL,
              phone TEXT NOT NULL,
              address TEXT NOT NULL,
              summary TEXT NOT NULL,
              experience TEXT NOT NULL,
              education TEXT NOT NULL
            )
          ''');
        }
        if (oldVersion < 3) {
          await db.execute('''
            CREATE TABLE IF NOT EXISTS mock_interviews (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              username TEXT NOT NULL,
              requestType TEXT NOT NULL,
              date TEXT NOT NULL,
              status TEXT DEFAULT 'Pending',
              advisor TEXT,
              notes TEXT,
              preferredLocation TEXT,
              assignedTime TEXT,
              venue TEXT,
              durationMinutes INTEGER
            )
          ''');
          await db.execute('''
            CREATE TABLE IF NOT EXISTS industry_partners (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              userId INTEGER,
              companyName TEXT,
              email TEXT,
              contactNumber TEXT,
              location TEXT,
              photoPath TEXT
            )
          ''');
        }
        // NOTE: `oldVersion < 4` and `oldVersion < 5` used to ALTER TABLE
        // `users` (email/phone/state/photoPath/name columns). The `users`
        // table now lives in Supabase, not sqlite, so those migrations were
        // removed. See supabase_schema.sql for the Supabase `users` schema.
        if (oldVersion < 6) {
          await db.execute('''
            CREATE TABLE IF NOT EXISTS hiring_posters (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              userId INTEGER,
              companyName TEXT NOT NULL,
              email TEXT NOT NULL,
              address TEXT NOT NULL,
              contactNumber TEXT NOT NULL,
              title TEXT NOT NULL,
              description TEXT NOT NULL,
              imagePath TEXT,
              datePosted TEXT NOT NULL
            )
          ''');
        }
        if (oldVersion < 7) {
          await db.execute(
            'ALTER TABLE industry_partners '
                'ADD COLUMN state TEXT DEFAULT ""',
          );

          await db.execute(
            'ALTER TABLE hiring_posters '
                'ADD COLUMN state TEXT DEFAULT ""',
          );
        }
        if (oldVersion < 8) {
          await db.execute('''
        CREATE TABLE IF NOT EXISTS feedback (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          username TEXT NOT NULL,
          rating INTEGER NOT NULL,
          category TEXT,
          feature TEXT,
          comment TEXT,
          createdAt TEXT NOT NULL
        )
      ''');
        }
        if (oldVersion < 9) {
          await db.execute('''
        CREATE TABLE IF NOT EXISTS applications (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          resumeId INTEGER NOT NULL,
          hiringPosterId INTEGER NOT NULL,
          studentUsername TEXT NOT NULL,
          dateApplied TEXT NOT NULL,
          FOREIGN KEY (resumeId) REFERENCES resumes(id) ON DELETE CASCADE,
          FOREIGN KEY (hiringPosterId) REFERENCES hiring_posters(id) ON DELETE CASCADE
        )
      ''');
        }
        // NOTE: `oldVersion < 10` used to ALTER TABLE `users` ADD COLUMN
        // Banned. Removed for the same reason as above — `users` is now a
        // Supabase table.
      },
      version: 10,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute(
      'CREATE TABLE Bookings('
          'id INTEGER PRIMARY KEY AUTOINCREMENT, '
          'itemName TEXT, '
          'date TEXT, '
          'status TEXT)',
    );
    log('TABLE Bookings CREATED');

    // NOTE: `users`, `events` and `event_registrations` used to be created
    // here. They now live in Supabase — see supabase_schema.sql for the
    // matching table definitions (including the seeded admin user and the
    // hardcoded counselor accounts that `_seedHardcodedCounselors` used to
    // insert locally).

    await db.execute('''
      CREATE TABLE resumes (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        profileImage TEXT NOT NULL,
        certificateImage TEXT,
        fullName TEXT NOT NULL,
        age TEXT NOT NULL,
        gender TEXT NOT NULL,
        email TEXT NOT NULL,
        phone TEXT NOT NULL,
        address TEXT NOT NULL,
        summary TEXT NOT NULL,
        experience TEXT NOT NULL,
        education TEXT NOT NULL
      )
    ''');
    log('TABLE resumes CREATED');

    await db.execute('''
      CREATE TABLE industry_partners (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        userId INTEGER,
        companyName TEXT,
        email TEXT,
        contactNumber TEXT,
        location TEXT,
        state TEXT,
        photoPath TEXT
      )
    ''');
    log('TABLE industry_partners CREATED');
    // NOTE: `userId` here now refers to a Supabase `users.id`, not a local
    // sqlite row, so the old `FOREIGN KEY (userId) REFERENCES users(id)`
    // constraint was dropped — sqlite can't enforce a foreign key against a
    // table it no longer has.

    await db.execute('''
      CREATE TABLE hiring_posters (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        userId INTEGER,
        companyName TEXT NOT NULL,
        email TEXT NOT NULL,
        address TEXT NOT NULL,
        state TEXT,
        contactNumber TEXT NOT NULL,
        title TEXT NOT NULL,
        description TEXT NOT NULL,
        imagePath TEXT,
        datePosted TEXT NOT NULL
      )
    ''');
    log('TABLE hiring_posters CREATED');
    // Same note as industry_partners above: `userId` now points at Supabase.

    await db.execute('''
      CREATE TABLE mock_interviews (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        username TEXT NOT NULL,
        requestType TEXT NOT NULL,
        date TEXT NOT NULL,
        status TEXT DEFAULT 'Pending',
        advisor TEXT,
        notes TEXT,
        preferredLocation TEXT,
        assignedTime TEXT,
        venue TEXT,
        durationMinutes INTEGER
      )
    ''');
    log('TABLE mock_interviews CREATED');

    await db.execute('''
      CREATE TABLE feedback (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        username TEXT NOT NULL,
        rating INTEGER NOT NULL,
        category TEXT,
        feature TEXT,
        comment TEXT,
        createdAt TEXT NOT NULL
      )
    ''');
  }

  // ================= APPLICATIONS =================

  Future<int> submitApplication({
    required int resumeId,
    required int hiringPosterId,
    required String studentUsername,
  }) async {
    final db = await database;

    return await db.insert('applications', {
      'resumeId': resumeId,
      'hiringPosterId': hiringPosterId,
      'studentUsername': studentUsername,
      'dateApplied': DateTime.now().toIso8601String(),
    });
  }

  Future<List<Map<String, dynamic>>> getAllApplications() async {
    final db = await database;

    return await db.rawQuery('''
    SELECT
      a.id AS applicationId,
      a.studentUsername,
      a.dateApplied,
      a.resumeId,
      a.hiringPosterId,
      h.title AS hiringPosterTitle,
      h.companyName,
      r.*
    FROM applications a
    INNER JOIN resumes r
      ON a.resumeId = r.id
    INNER JOIN hiring_posters h
      ON a.hiringPosterId = h.id
    ORDER BY a.id DESC
  ''');
  }

  Future<List<Map<String, dynamic>>> getApplicationsByHiringPoster(
      int hiringPosterId,
      ) async {
    final db = await database;

    return await db.rawQuery(
      '''
    SELECT
      a.id AS applicationId,
      a.studentUsername,
      a.dateApplied,
      a.resumeId,
      a.hiringPosterId,
      h.title AS hiringPosterTitle,
      h.companyName,
      r.*
    FROM applications a
    INNER JOIN resumes r
      ON a.resumeId = r.id
    INNER JOIN hiring_posters h
      ON a.hiringPosterId = h.id
    WHERE a.hiringPosterId = ?
    ORDER BY a.id DESC
  ''',
      [hiringPosterId],
    );
  }

  // --- HIRING POSTER METHODS ---
  Future<int> insertHiringPoster(HiringPoster poster) async {
    final db = await database;
    return await db.insert('hiring_posters', poster.toMap());
  }

  Future<List<HiringPoster>> getHiringPostersByUserId(int userId) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'hiring_posters',
      where: 'userId = ?',
      whereArgs: [userId],
      orderBy: 'id DESC',
    );
    return List.generate(maps.length, (i) => HiringPoster.fromMap(maps[i]));
  }

  Future<List<HiringPoster>> getAllHiringPosters() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'hiring_posters',
      orderBy: 'id DESC',
    );
    return List.generate(maps.length, (i) => HiringPoster.fromMap(maps[i]));
  }

  Future<int> updateHiringPoster(HiringPoster poster) async {
    final db = await database;
    return await db.update(
      'hiring_posters',
      poster.toMap(),
      where: 'id = ?',
      whereArgs: [poster.id],
    );
  }

  Future<int> deleteHiringPoster(int id) async {
    final db = await database;
    return await db.delete('hiring_posters', where: 'id = ?', whereArgs: [id]);
  }

  // --- INDUSTRY PARTNER METHODS ---
  Future<int> registerIndustryUser({
    required String username,
    required String password,
    required IndustryPartner partner,
  }) async {
    // `users` now lives in Supabase and `industry_partners` stays local, so
    // this can no longer be a single atomic sqlite transaction the way it
    // used to be. If the local insert below fails after the Supabase insert
    // succeeds, you'll end up with a Supabase user that has no local
    // industry_partners row — worth keeping an eye on / wrapping in retry
    // logic if that matters for your use case.
    final userId = await SupabaseService().registerUser(
      username,
      password,
      'industry',
    );

    if (userId == null) {
      throw Exception('Failed to create industry user in Supabase');
    }

    final db = await database;
    await db.insert(
      'industry_partners',
      partner.toMap(assignedUserId: userId),
    );

    return userId;
  }

  Future<IndustryPartner?> getIndustryPartnerByUserId(int userId) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'industry_partners',
      where: 'userId = ?',
      whereArgs: [userId],
    );

    if (maps.isNotEmpty) {
      return IndustryPartner.fromMap(maps.first);
    }
    return null;
  }

  // --- USER PROFILE METHODS (delegated to Supabase) ---
  Future<Map<String, dynamic>?> getUserProfile(String username) {
    return SupabaseService().getUserProfile(username);
  }

  Future<int> updateUserProfile(
      String username, {
        String? name,
        String? email,
        String? phone,
        String? state,
        String? photoPath,
      }) {
    return SupabaseService().updateUserProfile(
      username,
      name: name,
      email: email,
      phone: phone,
      state: state,
      photoPath: photoPath,
    );
  }

  Future<bool> changePassword(
      String username,
      String currentPassword,
      String newPassword,
      ) {
    return SupabaseService().changePassword(
      username,
      currentPassword,
      newPassword,
    );
  }

  // --- MOCK INTERVIEW & ADVISORY METHODS ---
  Future<int> insertMockInterviewRequest(MockInterviewModel request) async {
    final db = await database;
    return await db.insert('mock_interviews', request.toMap());
  }

  Future<int> cancelMockInterview(int id) async {
    final db = await database;
    return await db.update(
      'mock_interviews',
      {'status': 'Cancelled'},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<List<MockInterviewModel>> getStudentMockInterviews(
      String username,
      ) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'mock_interviews',
      where: 'username = ?',
      whereArgs: [username],
      orderBy: 'id DESC',
    );
    return List.generate(
      maps.length,
          (i) => MockInterviewModel.fromMap(maps[i]),
    );
  }

  // --- RESUME METHODS ---
  Future<int> insertResume(ResumeData resume) async {
    final db = await database;
    return await db.insert('resumes', resume.toMap());
  }

  Future<List<ResumeData>> getAllResumes() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'resumes',
      orderBy: 'id DESC',
    );
    return List.generate(maps.length, (i) => ResumeData.fromMap(maps[i]));
  }

  Future<int> updateResume(ResumeData resume) async {
    final db = await database;
    return await db.update(
      'resumes',
      resume.toMap(),
      where: 'id = ?',
      whereArgs: [resume.id],
    );
  }

  Future<int> deleteResume(int id) async {
    final db = await database;
    return await db.delete('resumes', where: 'id = ?', whereArgs: [id]);
  }

  // --- EVENT METHODS (delegated to Supabase) ---
  Future<int> insertEvent(EventModel event) async {
    final id = await SupabaseService().insertEvent(event);
    if (id == null) throw Exception('Failed to insert event');
    return id;
  }

  Future<void> deleteEvent(int id) {
    return SupabaseService().deleteEvent(id);
  }

  Future<List<EventModel>> getEvents() {
    return SupabaseService().getEvents();
  }

  Future<void> incrementEventBooking(int eventId, int currentBooked) {
    return SupabaseService().incrementEventBooking(eventId, currentBooked);
  }

  // --- REGISTRATION & APPROVAL LOGIC (delegated to Supabase) ---
  Future<int?> getUserId(String username) {
    return SupabaseService().getUserId(username);
  }

  Future<bool> hasUserRegistered(int userId, int eventId) {
    return SupabaseService().hasUserRegistered(userId, eventId);
  }

  Future<int> registerForEvent(int userId, int eventId) async {
    final id = await SupabaseService().registerForEvent(userId, eventId);
    if (id == null) throw Exception('Failed to register for event');
    return id;
  }

  Future<List<EventRegistrationModel>> getUserRegistrations(int userId) {
    return SupabaseService().getUserRegistrations(userId);
  }

  Future<List<EventRegistrationModel>> getAllRegistrations() {
    return SupabaseService().getAllRegistrations();
  }

  Future<void> updateRegistrationStatus(
      int registrationId,
      int eventId,
      String newStatus,
      ) {
    return SupabaseService().updateRegistrationStatus(
      registrationId,
      eventId,
      newStatus,
    );
  }

  // --- BOOKING METHODS ---
  Future<List<BookingModel>> getBookings() async {
    final db = await database;
    var data = await db.query('Bookings');
    return List.generate(
      data.length,
          (index) => BookingModel.fromJson(data[index]),
    );
  }

  Future<void> insertBooking(BookingModel booking) async {
    final db = await database;
    await db.insert('Bookings', booking.toMap());
  }

  Future<void> editBooking(BookingModel booking) async {
    final db = await database;
    var data = await db.update(
      'Bookings',
      booking.toMap(),
      where: 'id=?',
      whereArgs: [booking.id],
    );
    log('updated $data');
  }

  Future<void> deleteBooking(int id) async {
    final db = await database;
    var data = await db.delete('Bookings', where: 'id=?', whereArgs: [id]);
    log('deleted $data');
  }

  // --- USER AUTHENTICATION (delegated to Supabase) ---
  Future<int> registerUser(
      String username,
      String password,
      String role,
      ) async {
    final id = await SupabaseService().registerUser(username, password, role);
    if (id == null) throw Exception('Failed to register user');
    return id;
  }

  Future<Map<String, dynamic>?> loginUser(
      String username,
      String password,
      ) {
    return SupabaseService().loginUser(username, password);
  }

  Future<List<String>> getAcceptedParticipants(int eventId) {
    return SupabaseService().getAcceptedParticipants(eventId);
  }

  Future<EventModel?> getEventById(int id) {
    return SupabaseService().getEventById(id);
  }

  Future<void> _ensureComparisonTable(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS saved_comparisons (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        title TEXT,
        state TEXT,
        sector TEXT,
        nominalSalary REAL,
        netDisposable REAL,
        savingsRatio REAL,
        status TEXT,
        notes TEXT
      )
    ''');
  }

  Future<int> insertComparison(ComparisonModel item) async {
    final db = await database;
    await _ensureComparisonTable(db);
    return await db.insert('saved_comparisons', item.toMap());
  }

  Future<List<ComparisonModel>> getComparisons({
    String searchQuery = '',
  }) async {
    final db = await database;
    await _ensureComparisonTable(db);
    List<Map<String, dynamic>> maps;
    if (searchQuery.trim().isEmpty) {
      maps = await db.query('saved_comparisons', orderBy: 'id DESC');
    } else {
      maps = await db.query(
        'saved_comparisons',
        where: 'title LIKE ? OR state LIKE ? OR sector LIKE ?',
        whereArgs: ['%$searchQuery%', '%$searchQuery%', '%$searchQuery%'],
        orderBy: 'id DESC',
      );
    }
    return List.generate(maps.length, (i) => ComparisonModel.fromMap(maps[i]));
  }

  Future<int> updateComparison(ComparisonModel item) async {
    final db = await database;
    await _ensureComparisonTable(db);
    return await db.update(
      'saved_comparisons',
      item.toMap(),
      where: 'id = ?',
      whereArgs: [item.id],
    );
  }

  Future<int> deleteComparison(int id) async {
    final db = await database;
    await _ensureComparisonTable(db);
    return await db.delete(
      'saved_comparisons',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // --- ADMIN MOCK INTERVIEW & COUNSELOR METHODS ---
  Future<List<MockInterviewModel>> getAllMockInterviews() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'mock_interviews',
      orderBy: 'id DESC',
    );
    return List.generate(
      maps.length,
          (i) => MockInterviewModel.fromMap(maps[i]),
    );
  }

  Future<List<Map<String, dynamic>>> getCareerCounselors() {
    return SupabaseService().getCareerCounselors();
  }

  Future<bool> isCounselorAvailable(
      String counselorName,
      String date,
      String time,
      ) async {
    final db = await database;
    final results = await db.query(
      'mock_interviews',
      where: 'advisor = ? AND date = ? AND time = ? AND status != ?',
      whereArgs: [counselorName, date, time, 'Rejected'],
    );
    return results.isEmpty;
  }

  Future<int> assignAdvisorToRequest(int requestId, String advisorName) async {
    final db = await database;
    return await db.update(
      'mock_interviews',
      {'advisor': advisorName, 'status': 'Accepted'},
      where: 'id = ?',
      whereArgs: [requestId],
    );
  }

  Future<List<TimetableSlot>> getAdvisorTimetable(
      String advisorName,
      String date,
      ) async {
    final db = await database;

    final results = await db.query(
      'mock_interviews',
      where: 'advisor = ? AND date = ? AND status = ?',
      whereArgs: [advisorName, date, 'Accepted'],
    );

    final bookedTimes = results
        .map((r) => r['assignedTime'] as String?)
        .whereType<String>()
        .toSet();

    List<TimetableSlot> schedule = [];
    for (int i = 9; i <= 17; i++) {
      String timeLabel = '${i.toString().padLeft(2, '0')}:00';
      schedule.add(
        TimetableSlot(
          timeLabel: timeLabel,
          isBooked: bookedTimes.contains(timeLabel),
        ),
      );
    }

    return schedule;
  }

  Future<int> assignAdvisorWithDetails(
      int requestId,
      String advisorName,
      String assignedTime,
      String venue,
      int duration,
      ) async {
    final db = await database;
    return await db.update(
      'mock_interviews',
      {
        'advisor': advisorName,
        'assignedTime': assignedTime,
        'venue': venue,
        'durationMinutes': duration,
        'status': 'Accepted',
      },
      where: 'id = ?',
      whereArgs: [requestId],
    );
  }

  // --- FEEDBACK METHODS ---
  Future<int> insertFeedback(
      String username,
      int rating,
      String comment, {
        String? category,
        String? feature,
      }) async {
    final db = await database;
    return await db.insert('feedback', {
      'username': username,
      'rating': rating,
      'comment': comment,
      'category': category,
      'feature': feature,
      'createdAt': DateTime.now().toIso8601String(),
    });
  }

  Future<List<Map<String, dynamic>>> getAllFeedback() async {
    final db = await database;
    return await db.query('feedback', orderBy: 'id DESC');
  }

  Future<int> deleteFeedback(int id) async {
    final db = await database;
    return await db.delete('feedback', where: 'id = ?', whereArgs: [id]);
  }

  // --- ADMIN USER MANAGEMENT METHODS ---

  Future<List<Map<String, dynamic>>> getStudentUsers() {
    return SupabaseService().getStudentUsers();
  }

  Future<int> updateUserBanStatus({
    required String username,
    required bool banned,
  }) {
    return SupabaseService().updateUserBanStatus(
      username: username,
      banned: banned,
    );
  }

  bool isUserBanned(Map<String, dynamic> user) {
    return user['Banned']?.toString().toLowerCase() == 'yes';
  }
}