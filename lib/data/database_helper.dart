import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/category_model.dart';
import '../models/task_model.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('todo_app.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(path, version: 1, onCreate: _createDB);
  }

  Future _createDB(Database db, int version) async {
    await db.execute('''
    CREATE TABLE categories (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      name TEXT NOT NULL,
      hexColor TEXT NOT NULL
    )
  ''');

    await db.execute('''
    CREATE TABLE tasks (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      title TEXT NOT NULL,
      description TEXT,
      categoryId INTEGER NOT NULL, 
      isCompleted INTEGER NOT NULL,
      isMarkedStar INTEGER NOT NULL,
      deadline TEXT NOT NULL,
      startTime TEXT NOT NULL,
      FOREIGN KEY (categoryId) REFERENCES categories (id) ON DELETE CASCADE
    )
  ''');

    // Seed data
    await db.insert('categories', {'name': 'Cá nhân', 'hexColor': '#4CAF50'}); // Xanh lá
    await db.insert('categories', {'name': 'Công việc', 'hexColor': '#F44336'}); // Đỏ
    await db.insert('categories', {'name': 'Học tập', 'hexColor': '#2196F3'}); // Xanh dương
  }

  // --- TASKS ---
  Future<int> insertTask(Task task) async {
    final db = await database;
    return await db.insert('tasks', task.toMap());
  }

  Future<List<Task>> getTasks() async {
    final db = await database;
    // Đã sửa 'date' thành 'startTime'
    final result = await db.query('tasks', orderBy: 'startTime DESC');
    return result.map((json) => Task.fromMap(json)).toList();
  }

  Future<int> updateTask(Task task) async {
    final db = await database;
    return await db.update(
      'tasks',
      task.toMap(),
      where: 'id = ?',
      whereArgs: [task.id],
    );
  }

  Future<int> deleteTask(int id) async {
    final db = await database;
    return await db.delete('tasks', where: 'id = ?', whereArgs: [id]);
  }

  // --- CATEGORIES ---
  Future<int> insertCategory(Category category) async {
    final db = await database;
    return await db.insert('categories', category.toMap());
  }

  Future<List<Category>> getCategories() async {
    final db = await database;
    final result = await db.query('categories', orderBy: 'id ASC');
    return result.map((json) => Category.fromMap(json)).toList();
  }

  Future<int> deleteCategory(int id) async {
    final db = await database;
    return await db.delete('categories', where: 'id = ?', whereArgs: [id]);
  }
}