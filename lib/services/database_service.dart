import 'dart:convert';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/flight.dart';
import '../models/airport.dart';
import '../models/notam.dart';
import '../models/weather.dart';

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

  Future<void> saveFlight(Flight flight) async {
    final db = await database;
    await db.transaction((txn) async {
      // Insert flight
      await txn.insert('flights', flight.toDbJson(), conflictAlgorithm: ConflictAlgorithm.replace);
      
      // Insert airports
      for (var airport in flight.airports) {
        await txn.insert('airports', airport.toDbJson(flight.id), conflictAlgorithm: ConflictAlgorithm.replace);
      }
      
      // Insert NOTAMs
      for (var notam in flight.notams) {
        await txn.insert('notams', notam.toDbJson(flight.id), conflictAlgorithm: ConflictAlgorithm.replace);
      }

      // Insert weather
      for (var weatherItem in flight.weather) {
        await txn.insert('weather', weatherItem.toDbJson(flight.id), conflictAlgorithm: ConflictAlgorithm.replace);
      }
    });
  }

  Future<List<Flight>> getSavedFlights() async {
    final db = await database;
    final List<Map<String, dynamic>> flightMaps = await db.query('flights', orderBy: 'createdAt DESC');
    
    if (flightMaps.isEmpty) return [];

    List<Flight> flights = [];
    for (var flightMap in flightMaps) {
      final flightId = flightMap['id'];
      
      final airportMaps = await db.query('airports', where: 'flightId = ?', whereArgs: [flightId]);
      final notamMaps = await db.query('notams', where: 'flightId = ?', whereArgs: [flightId]);
      final weatherMaps = await db.query('weather', where: 'flightId = ?', whereArgs: [flightId]);
      
      flights.add(Flight.fromDb(
        flightMap,
        airportMaps,
        notamMaps,
        weatherMaps,
      ));
    }
    return flights;
  }
} 