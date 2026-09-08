import 'dart:developer';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';
import '../model/booking_model.dart';
import '../model/event_model.dart';
import '../model/event_registration_model.dart';

class DatabaseService {
  static final DatabaseService _databaseService = DatabaseService._internal();
  factory DatabaseService() => _databaseService;
  DatabaseService._internal();

  static Database? _database;

  // Get an instance of the database
  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await initDatabase();
    return _database!;
  }

  // Initialize the database and establish the file path
  Future<Database> initDatabase() async {
    final getDirectory = await getApplicationDocumentsDirectory();
    String path = '${getDirectory.path}/bookings.db';
    log(path);
    return await openDatabase(path, onCreate: _onCreate, version: 1);
  }

  // Create the table schema
  void _onCreate(Database db, int version) async {
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
          speaker TEXT,
          venue TEXT,
          date TEXT,
          time TEXT,
          capacity INTEGER,
          booked INTEGER DEFAULT 0
        )
      ''');

    // NEW TABLE: To handle student registrations and admin approvals
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

    await db.rawInsert('''
      INSERT INTO users (username, password, role) 
      VALUES ('admin', 'admin123', 'admin')
    ''');
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
  // Helper to get user ID by username
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

  // Check if a user has already registered for an event
  Future<bool> hasUserRegistered(int userId, int eventId) async {
    final db = await database;
    final result = await db.query(
      'event_registrations',
      where: 'userId = ? AND eventId = ?',
      whereArgs: [userId, eventId],
    );
    return result.isNotEmpty;
  }

  // Student: Register for an event time slot
  Future<int> registerForEvent(int userId, int eventId) async {
    final db = await database;
    // Defaults to 'pending' as defined in table creation
    return await db.insert('event_registrations', {
      'userId': userId,
      'eventId': eventId,
      'status': 'pending'
    });
  }

  // Student: View their own registrations
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

  // Admin: View all registrations to accept or reject
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

  // Admin: Update registration status (Accept or Reject)
  Future<void> updateRegistrationStatus(int registrationId, int eventId, String newStatus) async {
    final db = await database;

    // Update the registration status to 'accepted' or 'rejected'
    await db.update(
      'event_registrations',
      {'status': newStatus},
      where: 'id = ?',
      whereArgs: [registrationId],
    );

    // If accepted, increment the event's booked capacity automatically
    if (newStatus.toLowerCase() == 'accepted') {
      await db.rawUpdate(
          'UPDATE events SET booked = booked + 1 WHERE id = ?',
          [eventId]
      );
    }
  }

  // --- EXISTING BOOKING METHODS ---
  Future<List<BookingModel>> getBookings() async {
    final db = await _databaseService.database;
    var data = await db.query('Bookings');
    List<BookingModel> bookings = List.generate(
      data.length,
          (index) => BookingModel.fromJson(data[index]),
    );
    return bookings;
  }

  Future<void> insertBooking(BookingModel booking) async {
    final db = await _databaseService.database;
    await db.insert('Bookings', booking.toMap());
  }

  Future<void> editBooking(BookingModel booking) async {
    final db = await _databaseService.database;
    var data = await db.update(
      'Bookings',
      booking.toMap(),
      where: 'id=?',
      whereArgs: [booking.id],
    );
    log('updated $data');
  }

  Future<void> deleteBooking(int id) async {
    final db = await _databaseService.database;
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
}
