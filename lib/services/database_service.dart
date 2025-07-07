import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/flight.dart';

class DatabaseService {
  static final DatabaseService _instance = DatabaseService._internal();
  factory DatabaseService() => _instance;
  DatabaseService._internal();

  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB();
    return _database!;
  }

  Future<Database> _initDB() async {
    String path = join(await getDatabasesPath(), 'dispatch_buddy.db');
    return await openDatabase(
      path,
      version: 1,
      onCreate: _onCreate,
    );
  }

  Future _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE flights (
        id TEXT PRIMARY KEY,
        route TEXT NOT NULL,
        departure TEXT NOT NULL,
        destination TEXT NOT NULL,
        etd TEXT NOT NULL,
        flightLevel TEXT NOT NULL,
        alternates TEXT NOT NULL,
        createdAt TEXT NOT NULL
      )
    ''');
    await db.execute('''
      CREATE TABLE airports (
        icao TEXT PRIMARY KEY,
        flightId TEXT NOT NULL,
        name TEXT NOT NULL,
        city TEXT NOT NULL,
        systemsJson TEXT NOT NULL,
        FOREIGN KEY (flightId) REFERENCES flights (id) ON DELETE CASCADE
      )
    ''');
    await db.execute('''
      CREATE TABLE notams (
        id TEXT PRIMARY KEY,
        flightId TEXT NOT NULL,
        icao TEXT NOT NULL,
        type TEXT NOT NULL,
        validFrom TEXT NOT NULL,
        validTo TEXT NOT NULL,
        rawText TEXT NOT NULL,
        decodedText TEXT NOT NULL,
        affectedSystem TEXT NOT NULL,
        isCritical INTEGER NOT NULL,
        FOREIGN KEY (flightId) REFERENCES flights (id) ON DELETE CASCADE
      )
    ''');
    await db.execute('''
      CREATE TABLE weather (
        icao TEXT,
        flightId TEXT NOT NULL,
        timestamp TEXT NOT NULL,
        rawText TEXT NOT NULL,
        decodedText TEXT NOT NULL,
        windDirection INTEGER NOT NULL,
        windSpeed INTEGER NOT NULL,
        visibility INTEGER NOT NULL,
        cloudCover TEXT NOT NULL,
        temperature REAL NOT NULL,
        dewPoint REAL NOT NULL,
        qnh INTEGER NOT NULL,
        conditions TEXT NOT NULL,
        type TEXT NOT NULL DEFAULT 'METAR',
        PRIMARY KEY (icao, flightId, type),
        FOREIGN KEY (flightId) REFERENCES flights (id) ON DELETE CASCADE
      )
    ''');
  }

  // DISABLED: No caching for aviation safety - always fetch fresh data
  Future<void> saveFlight(Flight flight) async {
    print('DEBUG: 🚫 Flight saving DISABLED for aviation safety - no caching');
    // Do nothing - don't save to database to ensure fresh data
  }

  // DISABLED: No caching for aviation safety - always fetch fresh data
  Future<List<Flight>> getSavedFlights() async {
    print('DEBUG: 🚫 Database caching DISABLED for aviation safety');
    return []; // Return empty list to force fresh API calls
  }
  
  // Clear all cached data
  Future<void> clearAllData() async {
    final db = await database;
    await db.transaction((txn) async {
      await txn.delete('notams');
      await txn.delete('weather');
      await txn.delete('airports');
      await txn.delete('flights');
    });
    print('DEBUG: 🗑️ Cleared all cached data from database');
  }
} 