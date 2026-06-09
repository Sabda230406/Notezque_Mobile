import 'package:path/path.dart' as path;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite/sqflite.dart';

class SQLiteService {
  static const String _loginUserIdKey = 'login_user_id';
  static const String _lastLoginEmailKey = 'login_last_email';

  static int? _currentUserId;
  static Database? _database;

  static bool get isLoggedIn => _currentUserId != null;

  static Future<Database> get _db async {
    if (_database != null) return _database!;

    final databasePath = await getDatabasesPath();
    final fullPath = path.join(databasePath, 'notezque.db');

    _database = await openDatabase(
      fullPath,
      version: 4,
      onCreate: _createTables,
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          await db.execute(
            'CREATE TABLE IF NOT EXISTS materi_folders (id INTEGER PRIMARY KEY AUTOINCREMENT, user_id INTEGER NOT NULL, parent_id INTEGER, name TEXT NOT NULL, color TEXT, created_at TEXT NOT NULL, updated_at TEXT NOT NULL, FOREIGN KEY (parent_id) REFERENCES materi_folders (id) ON DELETE CASCADE)',
          );
          await db.execute(
            'CREATE TABLE IF NOT EXISTS materi_files (id INTEGER PRIMARY KEY AUTOINCREMENT, user_id INTEGER NOT NULL, folder_id INTEGER, name TEXT NOT NULL, size INTEGER NOT NULL DEFAULT 0, type TEXT NOT NULL, path TEXT NOT NULL, created_at TEXT NOT NULL, updated_at TEXT NOT NULL, FOREIGN KEY (folder_id) REFERENCES materi_folders (id) ON DELETE CASCADE)',
          );
        }
        if (oldVersion < 4) {
          await _createNotificationReminderTable(db);
        }
      },
    );

    return _database!;
  }

  static Future<void> _createTables(Database db, int version) async {
    await db.execute('''
      CREATE TABLE users (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        email TEXT NOT NULL UNIQUE,
        password TEXT NOT NULL,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE notes (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id INTEGER NOT NULL,
        title TEXT NOT NULL,
        content TEXT NOT NULL,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE activities (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id INTEGER NOT NULL,
        title TEXT NOT NULL,
        date TEXT NOT NULL,
        time TEXT NOT NULL,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE tasks (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id INTEGER NOT NULL,
        title TEXT NOT NULL,
        description TEXT NOT NULL DEFAULT '',
        due_date TEXT NOT NULL DEFAULT '',
        status TEXT NOT NULL DEFAULT 'pending',
        priority TEXT NOT NULL DEFAULT 'medium',
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL
      )
    ''');
    await db.execute(
      'CREATE TABLE IF NOT EXISTS materi_folders (id INTEGER PRIMARY KEY AUTOINCREMENT, user_id INTEGER NOT NULL, parent_id INTEGER, name TEXT NOT NULL, color TEXT, created_at TEXT NOT NULL, updated_at TEXT NOT NULL, FOREIGN KEY (parent_id) REFERENCES materi_folders (id) ON DELETE CASCADE)',
    );
    await db.execute(
      'CREATE TABLE IF NOT EXISTS materi_files (id INTEGER PRIMARY KEY AUTOINCREMENT, user_id INTEGER NOT NULL, folder_id INTEGER, name TEXT NOT NULL, size INTEGER NOT NULL DEFAULT 0, type TEXT NOT NULL, path TEXT NOT NULL, created_at TEXT NOT NULL, updated_at TEXT NOT NULL, FOREIGN KEY (folder_id) REFERENCES materi_folders (id) ON DELETE CASCADE)',
    );
    await _createNotificationReminderTable(db);
  }

  static Future<void> _createNotificationReminderTable(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS notification_reminders (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id INTEGER NOT NULL,
        activity_id INTEGER,
        title TEXT NOT NULL,
        remind_at TEXT NOT NULL,
        is_enabled INTEGER NOT NULL DEFAULT 1,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL
      )
    ''');
  }

  static String get _now => DateTime.now().toIso8601String();

  static int _requireUserId() {
    final userId = _currentUserId;
    if (userId == null) {
      throw Exception('Pengguna belum login');
    }
    return userId;
  }

  static List<Map<String, dynamic>> _rows(List<Map<String, Object?>> rows) {
    return rows.map((row) => Map<String, dynamic>.from(row)).toList();
  }

  static Future<Map<String, dynamic>?> _findById(
    String table,
    int id,
    int userId,
  ) async {
    final db = await _db;
    final rows = await db.query(
      table,
      where: 'id = ? AND user_id = ?',
      whereArgs: [id, userId],
      limit: 1,
    );

    if (rows.isEmpty) return null;
    return Map<String, dynamic>.from(rows.first);
  }

  static Future<bool> restoreLoginSession() async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getInt(_loginUserIdKey);
    if (userId == null) return false;

    final db = await _db;
    final users = await db.query(
      'users',
      where: 'id = ?',
      whereArgs: [userId],
      limit: 1,
    );

    if (users.isEmpty) {
      await prefs.remove(_loginUserIdKey);
      return false;
    }

    _currentUserId = userId;
    return true;
  }

  static Future<String> getLastLoginEmail() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_lastLoginEmailKey) ?? '';
  }

  static Future<void> _saveLoginSession(int userId, String email) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_loginUserIdKey, userId);
    await prefs.setString(_lastLoginEmailKey, email);
  }

  static Future<Map<String, dynamic>> login(
    String email,
    String password,
  ) async {
    final trimmedEmail = email.trim();
    final trimmedPassword = password.trim();

    if (trimmedEmail.isEmpty || trimmedPassword.isEmpty) {
      return {'message': 'Email dan password wajib diisi'};
    }

    try {
      final db = await _db;
      final users = await db.query(
        'users',
        where: 'email = ?',
        whereArgs: [trimmedEmail],
        limit: 1,
      );

      if (users.isEmpty) {
        return {'message': 'Email belum terdaftar'};
      }

      final user = users.first;
      if (user['password'] != trimmedPassword) {
        return {'message': 'Password salah'};
      }

      final userId = user['id'] as int;
      _currentUserId = userId;
      await _saveLoginSession(userId, trimmedEmail);

      return {
        'success': true,
        'user': {'id': userId, 'name': user['name'], 'email': trimmedEmail},
      };
    } catch (e) {
      return {'message': 'Gagal login lokal: $e'};
    }
  }

  static Future<Map<String, dynamic>> register(
    String name,
    String email,
    String password,
  ) async {
    final trimmedName = name.trim();
    final trimmedEmail = email.trim();
    final trimmedPassword = password.trim();

    if (trimmedName.isEmpty ||
        trimmedEmail.isEmpty ||
        trimmedPassword.isEmpty) {
      return {'message': 'Nama, email, dan password wajib diisi'};
    }

    try {
      final db = await _db;
      final userId = await db.insert('users', {
        'name': trimmedName,
        'email': trimmedEmail,
        'password': trimmedPassword,
        'created_at': _now,
        'updated_at': _now,
      });

      _currentUserId = userId;
      await _saveLoginSession(userId, trimmedEmail);

      return {
        'success': true,
        'user': {'id': userId, 'name': trimmedName, 'email': trimmedEmail},
      };
    } on DatabaseException catch (e) {
      if (e.isUniqueConstraintError()) {
        return {'message': 'Email sudah terdaftar'};
      }
      return {'message': 'Gagal register lokal: $e'};
    } catch (e) {
      return {'message': 'Gagal register lokal: $e'};
    }
  }

  static Future<Map<String, dynamic>> logout() async {
    _currentUserId = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_loginUserIdKey);
    return {'message': 'Logout berhasil'};
  }

  static Future<Map<String, dynamic>> getCurrentUserProfile() async {
    try {
      final userId = _requireUserId();
      final db = await _db;
      final users = await db.query(
        'users',
        where: 'id = ?',
        whereArgs: [userId],
        limit: 1,
      );

      if (users.isEmpty) {
        return {'message': 'Profil pengguna tidak ditemukan'};
      }

      return {'data': Map<String, dynamic>.from(users.first)};
    } catch (e) {
      return {'message': 'Error: $e'};
    }
  }

  static Future<Map<String, dynamic>> updateCurrentUserProfile(
    String name,
    String email, {
    String? password,
  }) async {
    final trimmedName = name.trim();
    final trimmedEmail = email.trim();
    final trimmedPassword = password?.trim() ?? '';

    if (trimmedName.isEmpty || trimmedEmail.isEmpty) {
      return {'message': 'Nama dan email wajib diisi'};
    }

    try {
      final userId = _requireUserId();
      final db = await _db;
      final payload = <String, Object?>{
        'name': trimmedName,
        'email': trimmedEmail,
        'updated_at': _now,
      };

      if (trimmedPassword.isNotEmpty) {
        payload['password'] = trimmedPassword;
      }

      await db.update('users', payload, where: 'id = ?', whereArgs: [userId]);
      await _saveLoginSession(userId, trimmedEmail);
      final updatedProfile = await getCurrentUserProfile();

      return {
        'success': true,
        'message': 'Profil berhasil diperbarui',
        'data': updatedProfile['data'],
      };
    } on DatabaseException catch (e) {
      if (e.isUniqueConstraintError()) {
        return {'message': 'Email sudah digunakan'};
      }
      return {'message': 'Gagal memperbarui profil: $e'};
    } catch (e) {
      return {'message': 'Error: $e'};
    }
  }

  static Future<Map<String, dynamic>> deleteCurrentUserAccount() async {
    try {
      final userId = _requireUserId();
      final db = await _db;

      await db.transaction((txn) async {
        for (final table in [
          'notification_reminders',
          'notes',
          'activities',
          'tasks',
          'materi_files',
          'materi_folders',
        ]) {
          await txn.delete(table, where: 'user_id = ?', whereArgs: [userId]);
        }

        await txn.delete('users', where: 'id = ?', whereArgs: [userId]);
      });

      _currentUserId = null;
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_loginUserIdKey);
      await prefs.remove(_lastLoginEmailKey);

      return {'success': true, 'message': 'Akun berhasil dihapus'};
    } catch (e) {
      return {'message': 'Error: $e'};
    }
  }

  static Future<Map<String, dynamic>> getNotes() async {
    try {
      final userId = _requireUserId();
      final db = await _db;
      final rows = await db.query(
        'notes',
        where: 'user_id = ?',
        whereArgs: [userId],
        orderBy: 'created_at DESC',
      );

      return {'data': _rows(rows)};
    } catch (e) {
      return {'message': 'Error: $e'};
    }
  }

  static Future<Map<String, dynamic>> createNote(
    String title,
    String content,
  ) async {
    try {
      final userId = _requireUserId();
      final db = await _db;
      final id = await db.insert('notes', {
        'user_id': userId,
        'title': title,
        'content': content,
        'created_at': _now,
        'updated_at': _now,
      });

      return {
        'message': 'Catatan berhasil ditambahkan',
        'data': await _findById('notes', id, userId),
      };
    } catch (e) {
      return {'message': 'Error: $e'};
    }
  }

  static Future<Map<String, dynamic>> updateNote(
    int noteId,
    String title,
    String content,
  ) async {
    try {
      final userId = _requireUserId();
      final db = await _db;
      await db.update(
        'notes',
        {'title': title, 'content': content, 'updated_at': _now},
        where: 'id = ? AND user_id = ?',
        whereArgs: [noteId, userId],
      );

      return {
        'message': 'Catatan berhasil diperbarui',
        'data': await _findById('notes', noteId, userId),
      };
    } catch (e) {
      return {'message': 'Error: $e'};
    }
  }

  static Future<Map<String, dynamic>> deleteNote(int noteId) async {
    try {
      final userId = _requireUserId();
      final db = await _db;
      await db.delete(
        'notes',
        where: 'id = ? AND user_id = ?',
        whereArgs: [noteId, userId],
      );

      return {'message': 'Catatan berhasil dihapus'};
    } catch (e) {
      return {'message': 'Error: $e'};
    }
  }

  static Future<Map<String, dynamic>> getActivities() async {
    try {
      final userId = _requireUserId();
      final db = await _db;
      final rows = await db.query(
        'activities',
        where: 'user_id = ?',
        whereArgs: [userId],
        orderBy: 'date ASC, time ASC',
      );

      return {'data': _rows(rows)};
    } catch (e) {
      return {'message': 'Error: $e'};
    }
  }

  static Future<Map<String, dynamic>> createActivity(
    String title,
    String date,
    String time,
  ) async {
    try {
      final userId = _requireUserId();
      final db = await _db;
      final id = await db.insert('activities', {
        'user_id': userId,
        'title': title,
        'date': date,
        'time': time,
        'created_at': _now,
        'updated_at': _now,
      });

      return {
        'message': 'Acara berhasil ditambahkan',
        'data': await _findById('activities', id, userId),
      };
    } catch (e) {
      return {'message': 'Error: $e'};
    }
  }

  static Future<Map<String, dynamic>> updateActivity(
    int activityId,
    String title,
    String date,
    String time,
  ) async {
    try {
      final userId = _requireUserId();
      final db = await _db;
      await db.update(
        'activities',
        {'title': title, 'date': date, 'time': time, 'updated_at': _now},
        where: 'id = ? AND user_id = ?',
        whereArgs: [activityId, userId],
      );

      return {
        'message': 'Acara berhasil diperbarui',
        'data': await _findById('activities', activityId, userId),
      };
    } catch (e) {
      return {'message': 'Error: $e'};
    }
  }

  static Future<Map<String, dynamic>> deleteActivity(int activityId) async {
    try {
      final userId = _requireUserId();
      final db = await _db;
      await db.delete(
        'activities',
        where: 'id = ? AND user_id = ?',
        whereArgs: [activityId, userId],
      );

      return {'message': 'Acara berhasil dihapus'};
    } catch (e) {
      return {'message': 'Error: $e'};
    }
  }

  static Future<Map<String, dynamic>> getNotificationReminders() async {
    try {
      final userId = _requireUserId();
      final db = await _db;
      final rows = await db.rawQuery(
        '''
        SELECT
          reminders.*,
          activities.title AS activity_title,
          activities.date AS activity_date,
          activities.time AS activity_time
        FROM notification_reminders reminders
        LEFT JOIN activities
          ON activities.id = reminders.activity_id
          AND activities.user_id = reminders.user_id
        WHERE reminders.user_id = ?
        ORDER BY reminders.remind_at ASC
        ''',
        [userId],
      );

      return {'data': _rows(rows)};
    } catch (e) {
      return {'message': 'Error: $e'};
    }
  }

  static Future<Map<String, dynamic>> createNotificationReminder(
    int? activityId,
    String title,
    String remindAt, {
    bool isEnabled = true,
  }) async {
    final trimmedTitle = title.trim();
    if (trimmedTitle.isEmpty || remindAt.trim().isEmpty) {
      return {'message': 'Judul dan waktu reminder wajib diisi'};
    }

    try {
      final userId = _requireUserId();
      final db = await _db;
      final id = await db.insert('notification_reminders', {
        'user_id': userId,
        'activity_id': activityId,
        'title': trimmedTitle,
        'remind_at': remindAt,
        'is_enabled': isEnabled ? 1 : 0,
        'created_at': _now,
        'updated_at': _now,
      });

      return {
        'success': true,
        'message': 'Reminder berhasil ditambahkan',
        'data': await _findById('notification_reminders', id, userId),
      };
    } catch (e) {
      return {'message': 'Error: $e'};
    }
  }

  static Future<Map<String, dynamic>> updateNotificationReminder(
    int reminderId,
    int? activityId,
    String title,
    String remindAt, {
    bool isEnabled = true,
  }) async {
    final trimmedTitle = title.trim();
    if (trimmedTitle.isEmpty || remindAt.trim().isEmpty) {
      return {'message': 'Judul dan waktu reminder wajib diisi'};
    }

    try {
      final userId = _requireUserId();
      final db = await _db;
      await db.update(
        'notification_reminders',
        {
          'activity_id': activityId,
          'title': trimmedTitle,
          'remind_at': remindAt,
          'is_enabled': isEnabled ? 1 : 0,
          'updated_at': _now,
        },
        where: 'id = ? AND user_id = ?',
        whereArgs: [reminderId, userId],
      );

      return {
        'success': true,
        'message': 'Reminder berhasil diperbarui',
        'data': await _findById('notification_reminders', reminderId, userId),
      };
    } catch (e) {
      return {'message': 'Error: $e'};
    }
  }

  static Future<Map<String, dynamic>> toggleNotificationReminder(
    int reminderId,
    bool isEnabled,
  ) async {
    try {
      final userId = _requireUserId();
      final db = await _db;
      await db.update(
        'notification_reminders',
        {'is_enabled': isEnabled ? 1 : 0, 'updated_at': _now},
        where: 'id = ? AND user_id = ?',
        whereArgs: [reminderId, userId],
      );

      return {
        'success': true,
        'message': isEnabled
            ? 'Reminder berhasil diaktifkan'
            : 'Reminder berhasil dinonaktifkan',
      };
    } catch (e) {
      return {'message': 'Error: $e'};
    }
  }

  static Future<Map<String, dynamic>> deleteNotificationReminder(
    int reminderId,
  ) async {
    try {
      final userId = _requireUserId();
      final db = await _db;
      await db.delete(
        'notification_reminders',
        where: 'id = ? AND user_id = ?',
        whereArgs: [reminderId, userId],
      );

      return {'success': true, 'message': 'Reminder berhasil dihapus'};
    } catch (e) {
      return {'message': 'Error: $e'};
    }
  }

  static Future<Map<String, dynamic>> getTasks() async {
    try {
      final userId = _requireUserId();
      final db = await _db;
      final rows = await db.query(
        'tasks',
        where: 'user_id = ?',
        whereArgs: [userId],
        orderBy: 'created_at DESC',
      );

      return {'data': _rows(rows)};
    } catch (e) {
      return {'message': 'Error: $e'};
    }
  }

  static Future<Map<String, dynamic>> createTask(
    String title,
    String priority,
  ) async {
    try {
      final userId = _requireUserId();
      final db = await _db;
      final id = await db.insert('tasks', {
        'user_id': userId,
        'title': title,
        'description': '',
        'due_date': '',
        'status': 'pending',
        'priority': priority,
        'created_at': _now,
        'updated_at': _now,
      });

      return {
        'message': 'Tugas berhasil ditambahkan',
        'data': await _findById('tasks', id, userId),
      };
    } catch (e) {
      return {'message': 'Error: $e'};
    }
  }

  static Future<Map<String, dynamic>> updateTask(
    int taskId,
    String title,
    String description,
  ) async {
    try {
      final userId = _requireUserId();
      final db = await _db;
      await db.update(
        'tasks',
        {'title': title, 'description': description, 'updated_at': _now},
        where: 'id = ? AND user_id = ?',
        whereArgs: [taskId, userId],
      );

      return {
        'message': 'Tugas berhasil diperbarui',
        'data': await _findById('tasks', taskId, userId),
      };
    } catch (e) {
      return {'message': 'Error: $e'};
    }
  }

  static Future<Map<String, dynamic>> toggleTaskStatus(
    int taskId,
    String newStatus,
  ) async {
    try {
      final userId = _requireUserId();
      final db = await _db;
      await db.update(
        'tasks',
        {'status': newStatus, 'updated_at': _now},
        where: 'id = ? AND user_id = ?',
        whereArgs: [taskId, userId],
      );

      return {
        'message': 'Status tugas berhasil diperbarui',
        'data': await _findById('tasks', taskId, userId),
      };
    } catch (e) {
      return {'message': 'Error: $e'};
    }
  }

  static Future<Map<String, dynamic>> deleteTask(int taskId) async {
    try {
      final userId = _requireUserId();
      final db = await _db;
      await db.delete(
        'tasks',
        where: 'id = ? AND user_id = ?',
        whereArgs: [taskId, userId],
      );

      return {'message': 'Tugas berhasil dihapus'};
    } catch (e) {
      return {'message': 'Error: $e'};
    }
  }

  // --- MATERI FOLDERS ---
  static Future<List<Map<String, dynamic>>> getFolders({int? parentId}) async {
    final userId = _currentUserId!;
    final db = await _db;
    List<Map<String, Object?>> rows;
    if (parentId == null) {
      rows = await db.query(
        'materi_folders',
        where: 'user_id = ? AND parent_id IS NULL',
        whereArgs: [userId],
        orderBy: 'name ASC',
      );
    } else {
      rows = await db.query(
        'materi_folders',
        where: 'user_id = ? AND parent_id = ?',
        whereArgs: [userId, parentId],
        orderBy: 'name ASC',
      );
    }
    return _rows(rows);
  }

  static Future<Map<String, dynamic>> createFolder(
    String name, {
    int? parentId,
    String? color,
  }) async {
    final userId = _currentUserId!;
    final db = await _db;
    final id = await db.insert('materi_folders', {
      'user_id': userId,
      'parent_id': parentId,
      'name': name,
      'color': color,
      'created_at': _now,
      'updated_at': _now,
    });
    return {'success': true, 'id': id};
  }

  static Future<Map<String, dynamic>> updateFolder(
    int id,
    String name, {
    String? color,
  }) async {
    final userId = _currentUserId!;
    final db = await _db;
    await db.update(
      'materi_folders',
      {'name': name, if (color != null) 'color': color, 'updated_at': _now},
      where: 'id = ? AND user_id = ?',
      whereArgs: [id, userId],
    );
    return {'success': true};
  }

  static Future<Map<String, dynamic>> deleteFolder(int id) async {
    final userId = _currentUserId!;
    final db = await _db;
    await db.delete(
      'materi_folders',
      where: 'id = ? AND user_id = ?',
      whereArgs: [id, userId],
    );
    return {'success': true};
  }

  // --- MATERI FILES ---
  static Future<List<Map<String, dynamic>>> getFiles(int? folderId) async {
    final userId = _currentUserId!;
    final db = await _db;
    List<Map<String, Object?>> rows;
    if (folderId == null) {
      rows = await db.query(
        'materi_files',
        where: 'user_id = ? AND folder_id IS NULL',
        whereArgs: [userId],
        orderBy: 'name ASC',
      );
    } else {
      rows = await db.query(
        'materi_files',
        where: 'user_id = ? AND folder_id = ?',
        whereArgs: [userId, folderId],
        orderBy: 'name ASC',
      );
    }
    return _rows(rows);
  }

  static Future<Map<String, dynamic>> createFile(
    String name,
    int size,
    String type,
    String filePath, {
    int? folderId,
  }) async {
    final userId = _currentUserId!;
    final db = await _db;
    final id = await db.insert('materi_files', {
      'user_id': userId,
      'folder_id': folderId,
      'name': name,
      'size': size,
      'type': type,
      'path': filePath,
      'created_at': _now,
      'updated_at': _now,
    });
    return {'success': true, 'id': id};
  }

  static Future<Map<String, dynamic>> renameFile(int id, String name) async {
    final userId = _currentUserId!;
    final db = await _db;
    await db.update(
      'materi_files',
      {'name': name, 'updated_at': _now},
      where: 'id = ? AND user_id = ?',
      whereArgs: [id, userId],
    );
    return {'success': true};
  }

  static Future<Map<String, dynamic>> deleteFile(int id) async {
    final userId = _currentUserId!;
    final db = await _db;
    await db.delete(
      'materi_files',
      where: 'id = ? AND user_id = ?',
      whereArgs: [id, userId],
    );
    return {'success': true};
  }
}
