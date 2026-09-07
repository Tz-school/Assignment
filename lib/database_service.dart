import 'dart:developer';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';
import 'booking_model.dart';

class DatabaseService {
  static final DatabaseService _databaseService = DatabaseService._internal();
  factory DatabaseService() => _databaseService;
  DatabaseService._internal();

  static Database? _database;

  // Get an instance of the database[cite: 1]
  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await initDatabase();
    return _database!;
  }

  // Initialize the database and establish the file path[cite: 1]
  Future<Database> initDatabase() async {
    final getDirectory = await getApplicationDocumentsDirectory();
    String path = '${getDirectory.path}/bookings.db';
    log(path);
    return await openDatabase(path, onCreate: _onCreate, version: 1);
  }

  // --- EVENT METHODS ---
  Future<int> insertEvent(EventModel event) async {
    final db = await database;
    return await db.insert('events', event.toMap());
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

  // Create the table schema[cite: 1]
  void _onCreate(Database db, int version) async {
    await db.execute(
      'CREATE TABLE Bookings('
      'id INTEGER PRIMARY KEY AUTOINCREMENT, '
      'itemName TEXT, '
      'date TEXT, '
      'status TEXT)',
    );
    log('TABLE CREATED');

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
          booked INTEGER
        )
      ''');

    await db.rawInsert('''
      INSERT INTO users (username, password, role) 
      VALUES ('admin', 'admin123', 'admin')
    ''');
  }

  // Retrieve all booking records[cite: 1]
  Future<List<BookingModel>> getBookings() async {
    final db = await _databaseService.database;
    var data = await db.query('Bookings');
    List<BookingModel> bookings = List.generate(
      data.length,
      (index) => BookingModel.fromJson(data[index]),
    );
    return bookings;
  }

  // Insert a new booking[cite: 1]
  Future<void> insertBooking(BookingModel booking) async {
    final db = await _databaseService.database;
    await db.insert('Bookings', booking.toMap());
  }

  // Update an existing booking (e.g., changing status from Available to Booked)[cite: 1]
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

  // Delete a booking record[cite: 1]
  Future<void> deleteBooking(int id) async {
    final db = await _databaseService.database;
    var data = await db.delete('Bookings', where: 'id=?', whereArgs: [id]);
    log('deleted $data');
  }

  // Register a new user
  Future<int> registerUser(String username, String password, String role) async {
    final db = await database;
    return await db.insert('users', {
      'username': username,
      'password': password,
      'role': role,
    });
  }

  // Authenticate user
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
