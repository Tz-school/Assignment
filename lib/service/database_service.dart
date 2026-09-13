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
              photoPath TEXT,
              FOREIGN KEY (userId) REFERENCES users(id) ON DELETE CASCADE
            )
          ''');
        }
        if (oldVersion < 4) {
          await db.execute('ALTER TABLE users ADD COLUMN email TEXT');
          await db.execute('ALTER TABLE users ADD COLUMN phone TEXT');
          await db.execute('ALTER TABLE users ADD COLUMN state TEXT');
          await db.execute('ALTER TABLE users ADD COLUMN photoPath TEXT');
        }
        if (oldVersion < 5) {
          await db.execute('ALTER TABLE users ADD COLUMN name TEXT');
        }
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
              datePosted TEXT NOT NULL,
              FOREIGN KEY (userId) REFERENCES users(id) ON DELETE CASCADE
            )
          ''');
        }
      },
      version: 6,
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

    await db.execute('''
      CREATE TABLE users (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        username TEXT UNIQUE,
        password TEXT,
        role TEXT,
        name TEXT,
        email TEXT,
        phone TEXT,
        state TEXT,
        photoPath TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE events(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        title TEXT,
        description TEXT,
        speaker TEXT,
        venue TEXT,
        date TEXT,
        time TEXT,
        capacity INTEGER,
        booked INTEGER DEFAULT 0
      )
    ''');

    await db.execute('''
      CREATE TABLE event_registrations (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        userId INTEGER,
        eventId INTEGER,
        status TEXT DEFAULT 'pending',
        FOREIGN KEY (userId) REFERENCES users(id),
        FOREIGN KEY (eventId) REFERENCES events(id)
      )
    ''');
    log('TABLE event_registrations CREATED');

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
        photoPath TEXT,
        FOREIGN KEY (userId) REFERENCES users(id) ON DELETE CASCADE
      )
    ''');
    log('TABLE industry_partners CREATED');

    await db.execute('''
      CREATE TABLE hiring_posters (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        userId INTEGER,
        companyName TEXT NOT NULL,
        email TEXT NOT NULL,
        address TEXT NOT NULL,
        contactNumber TEXT NOT NULL,
        title TEXT NOT NULL,
        description TEXT NOT NULL,
        imagePath TEXT,
        datePosted TEXT NOT NULL,
        FOREIGN KEY (userId) REFERENCES users(id) ON DELETE CASCADE
      )
    ''');
    log('TABLE hiring_posters CREATED');

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

    await _seedHardcodedCounselors(db);

    await db.rawInsert('''
      INSERT INTO users (username, password, role) 
      VALUES ('admin', 'admin123', 'admin')
    ''');
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
    return await db.delete(
      'hiring_posters',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // --- INDUSTRY PARTNER METHODS ---
  Future<int> registerIndustryUser({
    required String username,
    required String password,
    required IndustryPartner partner,
  }) async {
    final db = await database;
    return await db.transaction((txn) async {
      int userId = await txn.insert('users', {
        'username': username,
        'password': password,
        'role': 'industry',
      });

      await txn.insert(
        'industry_partners',
        partner.toMap(assignedUserId: userId),
      );

      return userId;
    });
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

  Future<void> _seedHardcodedCounselors(Database db) async {
    final List<Map<String, dynamic>> hardcodedCounselors = [
      {
        'username': 'Sarah',
        'password': 'a',
        'role': 'Career Counselor'
      },
      {
        'username': 'James',
        'password': 'a',
        'role': 'Career Counselor'
      },
      {
        'username': 'Emily',
        'password': 'a',
        'role': 'Career Counselor'
      },
    ];

    for (var counselor in hardcodedCounselors) {
      await db.insert(
        'users',
        counselor,
        conflictAlgorithm: ConflictAlgorithm.ignore,
      );
    }
  }

  // --- USER PROFILE METHODS ---
  Future<Map<String, dynamic>?> getUserProfile(String username) async {
    final db = await database;
    final results = await db.query(
      'users',
      where: 'username = ?',
      whereArgs: [username],
    );
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
    final db = await database;
    final updates = <String, dynamic>{};
    if (name != null) updates['name'] = name;
    if (email != null) updates['email'] = email;
    if (phone != null) updates['phone'] = phone;
    if (state != null) updates['state'] = state;
    if (photoPath != null) updates['photoPath'] = photoPath;

    if (updates.isEmpty) return 0;

    return await db.update(
      'users',
      updates,
      where: 'username = ?',
      whereArgs: [username],
    );
  }

  Future<bool> changePassword(
      String username,
      String currentPassword,
      String newPassword,
      ) async {
    final db = await database;
    final match = await db.query(
      'users',
      where: 'username = ? AND password = ?',
      whereArgs: [username, currentPassword],
    );

    if (match.isEmpty) return false;

    await db.update(
      'users',
      {'password': newPassword},
      where: 'username = ?',
      whereArgs: [username],
    );
    return true;
  }

  // --- MOCK INTERVIEW & ADVISORY METHODS ---
  Future<int> insertMockInterviewRequest(MockInterviewModel request) async {
    final db = await database;
    return await db.insert('mock_interviews', request.toMap());
  }

  Future<List<MockInterviewModel>> getStudentMockInterviews(String username) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'mock_interviews',
      where: 'username = ?',
      whereArgs: [username],
      orderBy: 'id DESC',
    );
    return List.generate(maps.length, (i) => MockInterviewModel.fromMap(maps[i]));
  }

  // --- RESUME METHODS ---
  Future<int> insertResume(ResumeData resume) async {
    final db = await database;
    return await db.insert('resumes', resume.toMap());
  }

  Future<List<ResumeData>> getAllResumes() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('resumes', orderBy: 'id DESC');
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
    return await db.delete(
      'resumes',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // --- EVENT METHODS ---
  Future<int> insertEvent(EventModel event) async {
    final db = await database;
    return await db.insert('events', event.toMap());
  }

  Future<void> deleteEvent(int id) async {
    final db = await database;
    await db.delete('events', where: 'id = ?', whereArgs: [id]);
  }

  Future<List<EventModel>> getEvents() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('events');
    return List.generate(maps.length, (i) => EventModel.fromMap(maps[i]));
  }

  Future<void> incrementEventBooking(int eventId, int currentBooked) async {
    final db = await database;
    await db.update(
      'events',
      {'booked': currentBooked + 1},
      where: 'id = ?',
      whereArgs: [eventId],
    );
  }

  // --- REGISTRATION & APPROVAL LOGIC ---
  Future<int?> getUserId(String username) async {
    final db = await database;
    var results = await db.query(
        'users',
        columns: ['id'],
        where: 'username = ?',
        whereArgs: [username]
    );
    if (results.isNotEmpty) {
      return results.first['id'] as int;
    }
    return null;
  }

  Future<bool> hasUserRegistered(int userId, int eventId) async {
    final db = await database;
    final result = await db.query(
      'event_registrations',
      where: 'userId = ? AND eventId = ?',
      whereArgs: [userId, eventId],
    );
    return result.isNotEmpty;
  }

  Future<int> registerForEvent(int userId, int eventId) async {
    final db = await database;
    return await db.insert('event_registrations', {
      'userId': userId,
      'eventId': eventId,
      'status': 'pending'
    });
  }

  Future<List<EventRegistrationModel>> getUserRegistrations(int userId) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.rawQuery('''
      SELECT er.id as registrationId, er.status, 
             e.title as eventTitle, e.date, e.time, e.id as eventId
      FROM event_registrations er
      JOIN events e ON er.eventId = e.id
      WHERE er.userId = ?
    ''', [userId]);

    return List.generate(maps.length, (i) => EventRegistrationModel.fromMap(maps[i]));
  }

  Future<List<EventRegistrationModel>> getAllRegistrations() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.rawQuery('''
      SELECT er.id as registrationId, er.status, 
             u.username, u.id as userId,
             e.title as eventTitle, e.date, e.time, e.id as eventId
      FROM event_registrations er
      JOIN users u ON er.userId = u.id
      JOIN events e ON er.eventId = e.id
    ''');

    return List.generate(maps.length, (i) => EventRegistrationModel.fromMap(maps[i]));
  }

  Future<void> updateRegistrationStatus(int registrationId, int eventId, String newStatus) async {
    final db = await database;

    await db.update(
      'event_registrations',
      {'status': newStatus},
      where: 'id = ?',
      whereArgs: [registrationId],
    );

    if (newStatus.toLowerCase() == 'accepted') {
      await db.rawUpdate(
          'UPDATE events SET booked = booked + 1 WHERE id = ?',
          [eventId]
      );
    }
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

  // --- USER AUTHENTICATION ---
  Future<int> registerUser(String username, String password, String role) async {
    final db = await database;
    return await db.insert('users', {
      'username': username,
      'password': password,
      'role': role,
    });
  }

  Future<Map<String, dynamic>?> loginUser(String username, String password) async {
    final db = await database;
    List<Map<String, dynamic>> results = await db.query(
      'users',
      where: 'username = ? AND password = ?',
      whereArgs: [username, password],
    );
    if (results.isNotEmpty) {
      return results.first;
    }
    return null;
  }

  Future<List<String>> getAcceptedParticipants(int eventId) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.rawQuery('''
      SELECT u.username 
      FROM event_registrations er
      JOIN users u ON er.userId = u.id
      WHERE er.eventId = ? AND er.status = 'accepted'
    ''', [eventId]);

    return List.generate(maps.length, (i) => maps[i]['username'] as String);
  }

  Future<EventModel?> getEventById(int id) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'events',
      where: 'id = ?',
      whereArgs: [id],
    );

    if (maps.isNotEmpty) {
      return EventModel.fromMap(maps.first);
    }
    return null;
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

  Future<List<ComparisonModel>> getComparisons({String searchQuery = ''}) async {
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
    final List<Map<String, dynamic>> maps = await db.query('mock_interviews', orderBy: 'id DESC');
    return List.generate(maps.length, (i) => MockInterviewModel.fromMap(maps[i]));
  }

  Future<List<Map<String, dynamic>>> getCareerCounselors() async {
    final db = await database;
    return await db.query('users', where: 'role = ?', whereArgs: ['Career Counselor']);
  }

  Future<bool> isCounselorAvailable(String counselorName, String date, String time) async {
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

  Future<List<TimetableSlot>> getAdvisorTimetable(String advisorName, String date) async {
    final db = await database;

    final results = await db.query(
      'mock_interviews',
      where: 'advisor = ? AND date = ? AND status = ?',
      whereArgs: [advisorName, date, 'Accepted'],
    );

    final bookedTimes = results.map((r) => r['assignedTime'] as String?).whereType<String>().toSet();

    List<TimetableSlot> schedule = [];
    for (int i = 9; i <= 17; i++) {
      String timeLabel = '${i.toString().padLeft(2, '0')}:00';
      schedule.add(TimetableSlot(
        timeLabel: timeLabel,
        isBooked: bookedTimes.contains(timeLabel),
      ));
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
        'status': 'Accepted'
      },
      where: 'id = ?',
      whereArgs: [requestId],
    );
  }
}