import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

import 'main.dart'; // เพื่อใช้ class Diary

class DatabaseHelper {
  static Database? _db;

  // เปิดฐานข้อมูล (เปิดครั้งเดียว ใช้ซ้ำ)
  static Future<Database> get database async {
    if (_db != null) return _db!;
    _db = await openDatabase(
      join(await getDatabasesPath(), 'mydiary.db'), // ที่อยู่ไฟล์ DB
      version: 1,
      onCreate: (db, version) async {
        await db.execute(
          'CREATE TABLE diaries('
          'id INTEGER PRIMARY KEY AUTOINCREMENT, '
          'title TEXT NOT NULL, '
          'content TEXT NOT NULL, '
          'date TEXT NOT NULL, '
          'mood TEXT NOT NULL)', //
        );
      },
    );
    return _db!;
  }

  // เพิ่มบันทึก
  static Future<void> insert(Diary diary) async {
    final db = await database;
    await db.insert('diaries', diary.toMap());
  }

  // อ่านบันทึกทั้งหมด
  static Future<List<Diary>> getAll() async {
    final db = await database;
    final maps = await db.query('diaries', orderBy: 'id DESC');
    return maps.map((map) => Diary.fromMap(map)).toList();
  }

  // ลบบันทึก
  static Future<void> delete(int id) async {
    final db = await database;
    await db.delete('diaries', where: 'id = ?', whereArgs: [id]);
  }

  static Future<void> update(Diary diary) async {
    final db = await database;
    await db.update(
      'diaries',
      diary.toMap(),
      where: 'id = ?',
      whereArgs: [diary.id],
    );
  }
  
}
