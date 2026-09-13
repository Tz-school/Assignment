import 'dart:developer';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';
import '../model/booking_model.dart';
import '../model/event_model.dart';
import '../model/event_registration_model.dart';
import '../model/resume_model.dart';
import '../model/mock_interview_model.dart';
import '../model/timetable_model.dart';

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
        // Updated version 3 migration to match the new model fields
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
        }
      },
      version: 3,
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
        role TEXT
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

    // Updated initial creation for mock_interviews
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
      orderBy: 'id DESC', // Show newest requests first
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

  // --- ADMIN MOCK INTERVIEW & COUNSELOR METHODS ---
  Future<List<MockInterviewModel>> getAllMockInterviews() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('mock_interviews', orderBy: 'id DESC');
    return List.generate(maps.length, (i) => MockInterviewModel.fromMap(maps[i]));
  }

  Future<List<Map<String, dynamic>>> getCareerCounselors() async {
    final db = await database;
    // Fetches any user registered specifically as a Career Counselor
    return await db.query('users', where: 'role = ?', whereArgs: ['Career Counselor']);
  }

  Future<bool> isCounselorAvailable(String counselorName, String date, String time) async {
    final db = await database;
    // Checks if the counselor already has an accepted/pending session at this exact date and time
    final results = await db.query(
      'mock_interviews',
      where: 'advisor = ? AND date = ? AND time = ? AND status != ?',
      whereArgs: [counselorName, date, time, 'Rejected'],
    );
    return results.isEmpty; // Returns true if no conflicts are found
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

  // Fetches a specific advisor's schedule for a given date to build the timetable graph
  Future<List<TimetableSlot>> getAdvisorTimetable(String advisorName, String date) async {
    final db = await database;

    // Get all accepted bookings for this advisor on this date
    final results = await db.query(
      'mock_interviews',
      where: 'advisor = ? AND date = ? AND status = ?',
      whereArgs: [advisorName, date, 'Accepted'],
    );

    // Extract the booked times (assuming assignedTime is stored as "HH:MM")
    final bookedTimes = results.map((r) => r['assignedTime'] as String?).whereType<String>().toSet();

    // Generate a standard 9 AM to 5 PM timetable block
    List<TimetableSlot> schedule = [];
    for (int i = 9; i <= 17; i++) {
      String timeLabel = '${i.toString().padLeft(2, '0')}:00';
      schedule.add(TimetableSlot(
        timeLabel: timeLabel,
        isBooked: bookedTimes.contains(timeLabel), // Will be true if a booking exists
      ));
    }

    return schedule;
  }

  // Updated assignment method including new admin parameters
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