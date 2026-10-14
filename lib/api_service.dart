import 'dart:convert'; // สำหรับ jsonDecode

import 'package:http/http.dart' as http;

import 'main.dart'; // ใช้ class Weather

class ApiService {
  static Future<Quote> fetchQuote() async {
    try {
      final url = Uri.parse(
        'https://dummyjson.com/quotes/random',
      );
      final response = await http.get(url).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return Quote.fromJson(data);
      } else {
        throw Exception('เซิร์ฟเวอร์ตอบผิดพลาด (${response.statusCode})');
      }
    } catch (e) {
      // จับ error ทุกแบบ (เน็ตหลุด/timeout/เซิร์ฟเวอร์พัง)
      throw Exception('เชื่อมต่อไม่ได้ ตรวจสอบอินเทอร์เน็ต');
    }
  }

  static const String studentId = '67011212045';   // << ใส่รหัสของคุณ
  static const String baseUrl =
      'https://thipwimon.comsciproject.net/mydiary/api.php/$studentId';   // << กล่องข้อมูลของเราโดยเฉพาะ

  // CREATE — เพิ่มบันทึก (POST)
  static Future<void> createDiary(String title, String content, String mood, String date) async {
    final url = Uri.parse(baseUrl);
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},   // บอกว่าส่ง JSON
      body: jsonEncode({                                // แปลง Map → JSON string
        'title': title,
        'content': content,
        'mood': mood,
        'date': date,
      }),
    );
    if (response.statusCode != 200 && response.statusCode != 201) {
      throw Exception('เพิ่มไม่สำเร็จ (${response.statusCode})');
    }
  }

  static Future<List<dynamic>> getDiaries() async {
  final url = Uri.parse(baseUrl);
  final response = await http.get(url);
  if (response.statusCode == 200) {
    final List<dynamic> all = jsonDecode(response.body);
    return all;                 // ได้เฉพาะกล่องของเรา ไม่ต้องกรอง
  }
  throw Exception('โหลดไม่สำเร็จ');
  }

    // UPDATE — แก้ไขบันทึก (PUT)
  static Future<void> updateDiary(String id, String title, String content, String mood, String date) async {
    final url = Uri.parse('$baseUrl/$id');        // ระบุ id ที่จะแก้
    final response = await http.put(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'title': title,
        'content': content,
        'mood': mood,
        'date': date,
      }),
    );
    if (response.statusCode != 200) {
      throw Exception('แก้ไขไม่สำเร็จ');
    }
  }

    // DELETE — ลบบันทึก
  static Future<void> deleteDiary(String id) async {
    final url = Uri.parse('$baseUrl/$id');
    final response = await http.delete(url);
    if (response.statusCode != 200) {
      throw Exception('ลบไม่สำเร็จ');
    }
  }
  
}
