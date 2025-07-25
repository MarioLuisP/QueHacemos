import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseHelper {
  static Database? _database;
  static const String _databaseName = 'eventos_cordoba.db';
  static const int _databaseVersion = 1;

  // Singleton pattern
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  factory DatabaseHelper() => _instance;
  DatabaseHelper._internal();

  // Getter para la base de datos
  static Future<Database> get database async {
    _database ??= await _initDatabase();
    return _database!;
  }

  // Inicialización de la base de datos
  static Future<Database> _initDatabase() async {
    String path = join(await getDatabasesPath(), _databaseName);

    return await openDatabase(
      path,
      version: _databaseVersion,
      onCreate: _createTables,
      onUpgrade: _onUpgrade,
    );
  }

  // Creación de tablas
  static Future<void> _createTables(Database db, int version) async {
    // Tabla principal de eventos
    await db.execute('''
    CREATE TABLE eventos (
      id INTEGER PRIMARY KEY,
      title TEXT NOT NULL,
      type TEXT NOT NULL,
      code TEXT UNIQUE,
      location TEXT,
      date TEXT NOT NULL,
      price TEXT,
      rating INTEGER DEFAULT 0,
      imageUrl TEXT,
      description TEXT,
      address TEXT,
      district TEXT,
      websiteUrl TEXT,
      lat REAL,
      lng REAL,
      favorite BOOLEAN DEFAULT FALSE, 
                        
      created_at TEXT DEFAULT CURRENT_TIMESTAMP
    )
    ''');
    //rating INTEGER DEFAULT 0,

    // Tabla de configuración de la app
    await db.execute('''
      CREATE TABLE app_settings (
        id INTEGER PRIMARY KEY,
        setting_key TEXT UNIQUE NOT NULL,
        setting_value TEXT NOT NULL,
        updated_at TEXT DEFAULT CURRENT_TIMESTAMP
      )
    ''');

    // Tabla de información de sincronización
    await db.execute('''
      CREATE TABLE sync_info (
        id INTEGER PRIMARY KEY,
        last_sync TEXT,
        batch_version TEXT,
        total_events INTEGER,
        created_at TEXT DEFAULT CURRENT_TIMESTAMP,
        updated_at TEXT DEFAULT CURRENT_TIMESTAMP
      )
    ''');

    // Insertar configuración por defecto
    await db.insert('app_settings', {
      'setting_key': 'cleanup_events_days',
      'setting_value': '3',
    });

    await db.insert('app_settings', {
      'setting_key': 'cleanup_favorites_days',
      'setting_value': '7',
    });

    // Insertar registro inicial de sincronización
    await db.insert('sync_info', {
      'id': 1,
      'last_sync': DateTime.now().toIso8601String(),
      'batch_version': '0.0.0',
      'total_events': 0,
    });

    // Índices para optimizar performance - NUEVO
    await db.execute('''
      CREATE INDEX IF NOT EXISTS idx_eventos_code ON eventos(code)
    ''');

    await db.execute('''
      CREATE INDEX IF NOT EXISTS idx_eventos_date ON eventos(date)
    ''');

    await db.execute('''
      CREATE INDEX IF NOT EXISTS idx_eventos_favorite ON eventos(favorite)
    ''');


    // NUEVO: Tabla de notificaciones híbrida (inmediatas + programadas)
    await db.execute('''
      CREATE TABLE notifications (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        title TEXT NOT NULL,
        message TEXT NOT NULL,
        type TEXT NOT NULL,
        event_code TEXT,
        created_at TEXT NOT NULL,
        is_read INTEGER DEFAULT 0,
        scheduled_datetime TEXT,
        local_notification_id INTEGER
      )
    ''');

    // NUEVO: Índice para consultas frecuentes de notificaciones
    await db.execute('''
      CREATE INDEX IF NOT EXISTS idx_notifications_read ON notifications(is_read)
    ''');

    // NUEVO: Índice para recordatorios programados
    await db.execute('''
      CREATE INDEX IF NOT EXISTS idx_notifications_scheduled ON notifications(scheduled_datetime)
    ''');
  }







  // Manejo de actualizaciones de esquema
  static Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    // Aquí manejarás futuras migraciones de esquema
    if (oldVersion < newVersion) {
      // Ejemplo para futuras versiones:
      // if (oldVersion < 2) {
      //   await db.execute('ALTER TABLE eventos ADD COLUMN new_field TEXT');
      // }
    }
  }

  // Métodos de utilidad
  static Future<void> closeDatabase() async {
    if (_database != null) {
      await _database!.close();
      _database = null;
    }
  }

  static Future<void> deleteDatabase() async {
    String path = join(await getDatabasesPath(), _databaseName);
    await databaseFactory.deleteDatabase(path);
    _database = null;
  }

  // Debug: Ver todas las tablas
  static Future<List<String>> getTables() async {
    final db = await database;
    final tables = await db.query(
      'sqlite_master',
      where: 'type = ?',
      whereArgs: ['table'],
    );
    return tables.map((table) => table['name'] as String).toList();
  }

  // Debug: Ver estructura de tabla
  static Future<List<Map<String, dynamic>>> getTableInfo(String tableName) async {
    final db = await database;
    return await db.rawQuery('PRAGMA table_info($tableName)');
  }
}