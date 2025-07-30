import 'package:sqflite/sqflite.dart';
import '../database/database_helper.dart';

class EventRepository {
  static final EventRepository _instance = EventRepository._internal();
  factory EventRepository() => _instance;
  EventRepository._internal();

  // ========== EVENTOS PRINCIPALES ==========

  /// Obtener todos los eventos ordenados por fecha
  Future<List<Map<String, dynamic>>> getAllEvents() async {
    final db = await DatabaseHelper.database;
    return await db.query(
      'eventos',
      orderBy: 'date ASC',
    );
  }

  /// Obtener eventos por categoría
  Future<List<Map<String, dynamic>>> getEventsByCategory(String category) async {
    final db = await DatabaseHelper.database;
    return await db.query(
      'eventos',
      where: 'category = ?',
      whereArgs: [category],
      orderBy: 'date ASC',
    );
  }

  /// Buscar eventos por título o descripción
  Future<List<Map<String, dynamic>>> searchEvents(String query) async {
    final db = await DatabaseHelper.database;
    return await db.query(
      'eventos',
      where: 'title LIKE ? OR description LIKE ?',
      whereArgs: ['%$query%', '%$query%'],
      orderBy: 'date ASC',
    );
  }

  /// Obtener eventos de una fecha específica
  Future<List<Map<String, dynamic>>> getEventsByDate(String date) async {
    final db = await DatabaseHelper.database;
    return await db.query(
      'eventos',
      where: 'DATE(date) = ?',
      whereArgs: [date],
      orderBy: 'date ASC',
    );
  }
  /// Obtiene conteos de eventos por fecha en un rango
  Future<Map<String, int>> getEventCountsForDateRange(String startDate, String endDate) async {
    final db = await DatabaseHelper.database;
    final results = await db.rawQuery('''
      SELECT DATE(date) as day, COUNT(*) as count 
      FROM eventos 
      WHERE DATE(date) BETWEEN ? AND ? 
      GROUP BY DATE(date)
    ''', [startDate, endDate]);

    final Map<String, int> counts = {};
    for (final row in results) {
      counts[row['day'] as String] = row['count'] as int;
    }

    return counts;
  }

  /// Obtener evento por ID
  Future<Map<String, dynamic>?> getEventById(int id) async {
    final db = await DatabaseHelper.database;
    final results = await db.query(
      'eventos',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    return results.isNotEmpty ? results.first : null;
  }

  /// Insertar múltiples eventos (para sync desde Firestore)
  Future<void> insertEvents(List<Map<String, dynamic>> events) async {
    final db = await DatabaseHelper.database;
    final batch = db.batch();

    for (var event in events) {
      batch.insert(
        'eventos',
        event,
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }

    await batch.commit(noResult: true);
  }/// Limpiar eventos vencidos con lógica inteligente
  Future<Map<String, int>> cleanOldEvents() async {              // CAMBIO: retorna stats detalladas
    final db = await DatabaseHelper.database;

    final eventsDays = await getCleanupDays('cleanup_events_days');
    final favoritesDays = await getCleanupDays('cleanup_favorites_days');

    final events_cutoff = DateTime.now().subtract(Duration(days: eventsDays));
    final favorites_cutoff = DateTime.now().subtract(Duration(days: favoritesDays));

    // Limpiar eventos normales (no favoritos)                    // NUEVO: lógica inteligente
    final normalDeleted = await db.delete(
      'eventos',
      where: 'DATE(date) < ? AND favorite = ?',                   // NUEVO: filtro por favorite = FALSE
      whereArgs: [events_cutoff.toIso8601String().split('T')[0], 0],
    );

    // Limpiar favoritos vencidos (más días de gracia)            // NUEVO: favoritos con más tiempo
    final favoritesDeleted = await db.delete(
      'eventos',
      where: 'DATE(date) < ? AND favorite = ?',                   // NUEVO: filtro por favorite = TRUE
      whereArgs: [favorites_cutoff.toIso8601String().split('T')[0], 1],
    );

    return {                                                      // NUEVO: retornar estadísticas
      'normalEvents': normalDeleted,
      'favoriteEvents': favoritesDeleted,
      'total': normalDeleted + favoritesDeleted,
    };
  }

  /// Remover eventos duplicados por CODE (mantener el más reciente) - NUEVO
  Future<int> removeDuplicatesByCodes() async {                     // NUEVO: función completa
    final db = await DatabaseHelper.database;

    // Query para encontrar y eliminar duplicados (mantener el de ID mayor = más reciente) - NUEVO
    final deletedDuplicates = await db.rawDelete('''              
        DELETE FROM eventos 
        WHERE id NOT IN (
          SELECT MAX(id) 
          FROM eventos 
          GROUP BY code
          HAVING code IS NOT NULL
        ) 
        AND code IS NOT NULL
      ''');

    if (deletedDuplicates > 0) {
      print('🔄 Removidos $deletedDuplicates eventos duplicados por CODE');
    }

    return deletedDuplicates;                        // NUEVO: retorna cantidad
  }
  // ========== FAVORITOS ==========
  /// Obtener todos los favoritos
  Future<List<Map<String, dynamic>>> getAllFavorites() async {
    final db = await DatabaseHelper.database;
    return await db.query(
      'eventos',                                        // CAMBIO: misma tabla
      where: 'favorite = ?',                           // NUEVO: filtrar por favoritos
      whereArgs: [1],                                  // NUEVO: true = 1 en SQLite
      orderBy: 'date ASC',
    );
  }

  /// Verificar si un evento es favorito
  Future<bool> favorite(int eventoId) async {
    final db = await DatabaseHelper.database;
    final results = await db.query(
      'eventos',
      where: 'id = ?',
      whereArgs: [eventoId],
      limit: 1,
    );
    if (results.isEmpty) return false;
    // CORREGIR: SQLite guarda como int, convertir a bool
    final int rawValue = results.first['favorite'] as int;
    return rawValue == 1;
  }
  /// Agregar evento a favoritos
  Future<void> addToFavorites(int eventoId) async {      // CAMBIO: solo necesita ID
    final db = await DatabaseHelper.database;

    await db.update(                                     // CAMBIO: update en vez de insert
      'eventos',                                         // CAMBIO: misma tabla
      {'favorite': 1},                                   // NUEVO: marcar como favorito
      where: 'id = ?',                                   // NUEVO: buscar por id
      whereArgs: [eventoId],                             // NUEVO: parámetro simplificado
    );
  }

  /// Remover evento de favoritos
  Future<void> removeFromFavorites(int eventoId) async {
    final db = await DatabaseHelper.database;
    await db.update(                                     // CAMBIO: update en vez de delete
      'eventos',                                         // CAMBIO: misma tabla
      {'favorite': 0},                                   // NUEVO: desmarcar favorito
      where: 'id = ?',                                   // CAMBIO: buscar por id directo
      whereArgs: [eventoId],
    );
  }

  /// Toggle favorito (agregar/remover)
  Future<bool> toggleFavorite(int eventoId) async {      // CAMBIO: solo necesita ID
    final isFav = await favorite(eventoId);

    if (isFav) {
      await removeFromFavorites(eventoId);
      return false;
    } else {
      await addToFavorites(eventoId);                     // CAMBIO: solo pasa ID
      return true;
    }
  }

  // ========== CONFIGURACIÓN ==========

  /// Obtener valor de configuración
  Future<String?> getSetting(String key) async {
    final db = await DatabaseHelper.database;
    final results = await db.query(
      'app_settings',
      where: 'setting_key = ?',
      whereArgs: [key],
      limit: 1,
    );
    return results.isNotEmpty ? results.first['setting_value'] as String : null;
  }

  /// Actualizar configuración
  Future<void> updateSetting(String key, String value) async {
    final db = await DatabaseHelper.database;
    await db.update(
      'app_settings',
      {
        'setting_value': value,
        'updated_at': DateTime.now().toIso8601String(),
      },
      where: 'setting_key = ?',
      whereArgs: [key],
    );
  }

  /// Obtener días de limpieza desde configuración
  Future<int> getCleanupDays(String settingKey) async {
    final value = await getSetting(settingKey);
    return value != null ? int.parse(value) : (settingKey.contains('events') ? 3 : 7);
  }

  // ========== SYNC INFO ==========

  /// Obtener información de última sincronización
  Future<Map<String, dynamic>?> getSyncInfo() async {
    final db = await DatabaseHelper.database;
    final results = await db.query('sync_info', limit: 1);
    return results.isNotEmpty ? results.first : null;
  }

  /// Actualizar información de sincronización
  Future<void> updateSyncInfo({
    required String batchVersion,
    required int totalEvents,
  }) async {
    final db = await DatabaseHelper.database;
    await db.update(
      'sync_info',
      {
        'last_sync': DateTime.now().toIso8601String(),
        'batch_version': batchVersion,
        'total_events': totalEvents,
        'updated_at': DateTime.now().toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [1],
    );
  }

  // ========== UTILIDADES ==========

  /// Contar total de eventos
  Future<int> getTotalEvents() async {
    final db = await DatabaseHelper.database;
    final result = await db.rawQuery('SELECT COUNT(*) as count FROM eventos');
    return result.first['count'] as int;
  }

  /// Contar total de favoritos
  Future<int> getTotalFavorites() async {
    final db = await DatabaseHelper.database;
    final result = await db.rawQuery('SELECT COUNT(*) as count FROM eventos WHERE favorite = 1');  // CAMBIO: query en misma tabla con filtro
    return result.first['count'] as int;
  }

  // ========== NOTIFICACIONES ========== // NUEVO: Sección completa

  /// NUEVO: Insertar notificación
  Future<int> insertNotification({
    required String title,
    required String message,
    required String type,
    String? eventCode,                              // NUEVO: usar event_code
    String? scheduledDatetime,                      // NUEVO: para recordatorios programados
    int? localNotificationId,                       // NUEVO: para cancelar local notifications
  }) async {
    final db = await DatabaseHelper.database;

    return await db.insert('notifications', {       // NUEVO: inserción en tabla notifications
      'title': title,
      'message': message,
      'type': type,
      'event_code': eventCode,                      // NUEVO: campo event_code
      'created_at': DateTime.now().toIso8601String(),
      'is_read': 0,
      'scheduled_datetime': scheduledDatetime,      // NUEVO: para scheduling
      'local_notification_id': localNotificationId, // NUEVO: para local notifications
    });
  }

  /// NUEVO: Obtener todas las notificaciones ordenadas por fecha
  Future<List<Map<String, dynamic>>> getAllNotifications({
    bool unreadOnly = false,                        // NUEVO: filtro opcional
  }) async {
    final db = await DatabaseHelper.database;

    String whereClause = '';                        // NUEVO: construcción dinámica de WHERE
    List<dynamic> whereArgs = [];

    if (unreadOnly) {                              // NUEVO: filtrar solo no leídas
      whereClause = 'WHERE is_read = ?';
      whereArgs = [0];
    }

    return await db.rawQuery('''                   
      SELECT * FROM notifications 
      $whereClause
      ORDER BY created_at DESC
    ''', whereArgs);
  }

  /// NUEVO: Marcar notificación como leída
  Future<void> markNotificationAsRead(int notificationId) async {
    final db = await DatabaseHelper.database;

    await db.update(                               // NUEVO: update específico por ID
      'notifications',
      {'is_read': 1},
      where: 'id = ?',
      whereArgs: [notificationId],
    );
  }

  /// NUEVO: Marcar todas las notificaciones como leídas
  Future<void> markAllNotificationsAsRead() async {
    final db = await DatabaseHelper.database;

    await db.update(                               // NUEVO: update masivo
      'notifications',
      {'is_read': 1},
      where: 'is_read = ?',
      whereArgs: [0],
    );
  }

  /// NUEVO: Eliminar notificación específica
  Future<void> deleteNotification(int notificationId) async {
    final db = await DatabaseHelper.database;

    await db.delete(                               // NUEVO: delete por ID
      'notifications',
      where: 'id = ?',
      whereArgs: [notificationId],
    );
  }

  /// NUEVO: Limpiar todas las notificaciones
  Future<void> clearAllNotifications() async {
    final db = await DatabaseHelper.database;
    await db.delete('notifications');             // NUEVO: truncate tabla notifications
  }

  /// NUEVO: Contar notificaciones no leídas (para badge)
  Future<int> getUnreadNotificationsCount() async {
    final db = await DatabaseHelper.database;

    final result = await db.rawQuery(             // NUEVO: count con filtro is_read
        'SELECT COUNT(*) as count FROM notifications WHERE is_read = 0'
    );

    return result.first['count'] as int;
  }

  /// NUEVO: Obtener recordatorios programados pendientes
  Future<List<Map<String, dynamic>>> getPendingScheduledNotifications() async {
    final db = await DatabaseHelper.database;

    return await db.query(                        // NUEVO: query para scheduling system
      'notifications',
      where: 'scheduled_datetime IS NOT NULL AND is_read = 0', // NUEVO: filtros específicos
      orderBy: 'scheduled_datetime ASC',
    );
  }

  /// NUEVO: Obtener notificaciones por event_code (para mantenimiento)
  Future<List<Map<String, dynamic>>> getNotificationsByEventCode(String eventCode) async {
    final db = await DatabaseHelper.database;

    return await db.query(                        // NUEVO: query por event_code
      'notifications',
      where: 'event_code = ? AND is_read = 0',   // NUEVO: filtro por código de evento
      whereArgs: [eventCode],
    );
  }

  /// Limpiar toda la base de datos (solo para debug/reset)
  Future<void> clearAllData() async {
    final db = await DatabaseHelper.database;
    final batch = db.batch();

    batch.delete('eventos');
    batch.update('sync_info', {
      'last_sync': null,  // ✅ CAMBIO: limpiar fecha
      'batch_version': '0.0.0',
      'total_events': 0,
      'updated_at': DateTime.now().toIso8601String(),
    }, where: 'id = ?', whereArgs: [1]);

    await batch.commit(noResult: true);
  }
}