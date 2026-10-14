import 'login_page.dart';
import 'firestore_diary.dart';

import 'package:flutter/material.dart';

import 'database_helper.dart'; // เพื่อใช้ class DatabaseHelper
import 'api_service.dart';

import 'package:firebase_core/firebase_core.dart';

import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const MyApp());
}

// แม่พิมพ์บันทึก

class Diary {
  final int? id;
  final String title;
  final String content;
  final String date;
  final String mood; // << field ใหม่
  Diary({
    this.id,
    required this.title,
    required this.content,
    required this.date,
    required this.mood,
  });

  Map<String, dynamic> toMap() => {
    'id': id, 'title': title, 'content': content,
    'date': date, 'mood': mood, // << เพิ่มใน toMap
  };

  factory Diary.fromMap(Map<String, dynamic> map) => Diary(
    id: map['id'],
    title: map['title'],
    content: map['content'],
    date: map['date'],
    mood: map['mood'] ?? 'เฉยๆ', // << เพิ่มใน fromMap (?? กันค่าเก่าไม่มี mood)
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'MyDiary',
      theme: ThemeData(colorSchemeSeed: Colors.indigo),
      home: const AuthGate(), // เปลี่ยนเป็น AuthGate (ยาม)
    );
  }
}

// หน้ารายการบันทึก

class DiaryListPage extends StatefulWidget {
  const DiaryListPage({super.key});

  @override
  State<DiaryListPage> createState() => _DiaryListPageState();
}

class _DiaryListPageState extends State<DiaryListPage> {
  // ย้าย List ข้อมูลมาไว้ตรงนี้ (นอก build)
  List<Diary> diaries = []; // เริ่มจากว่าง (จะโหลดจาก DB)
  late Future<Quote> _quoteFuture;

  @override
  void initState() {
    super.initState();
    _quoteFuture = ApiService.fetchQuote();
    _loadDiaries(); // โหลดข้อมูลตอนเปิดหน้า
  }

  // โหลดจาก DB
  Future<void> _loadDiaries() async {
    final data = await DatabaseHelper.getAll();
    setState(() {
      diaries = data;
    });
  }

  // เพิ่ม: เขียน DB แล้วโหลดใหม่
  Future<void> _addDiary(Diary diary) async {
    await DatabaseHelper.insert(diary);
    await _loadDiaries();
  }

  // แก้ไข: เขียน DB แล้วโหลดใหม่
  Future<void> _updateDiary(Diary diary) async {
    await DatabaseHelper.update(diary);
    await _loadDiaries();
  }

  // ลบ: เขียน DB แล้วโหลดใหม่
  Future<void> _deleteDiary(int id) async {
    await DatabaseHelper.delete(id);
    await _loadDiaries();
  }

  // เก็บคำคมลงตาราง diaries เพื่อให้แสดงร่วมกับบันทึกทั่วไปได้
  Future<void> _saveQuote(Quote quote) async {
    final today = DateTime.now().toIso8601String().substring(0, 10);
    await _addDiary(
      Diary(
        title: quote.text,
        content: '— ${quote.author}',
        date: today,
        mood: 'คำคม: ${quote.author}',
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // ข้อมูลตัวอย่าง (พิมพ์ไว้ในโค้ดก่อน)

    final List<Color> colors = [
      Colors.indigo,
      Colors.teal,
      Colors.orange,
      Colors.pink,
      Colors.green,
    ];

    return Scaffold(
      appBar: AppBar(
        title: Text('บันทึกของฉัน (${diaries.length})'),
        actions: [
          //  เพิ่มส่วนนี้
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              setState(() {
                _quoteFuture = ApiService.fetchQuote(); // สร้าง Future ใหม่ = โหลดใหม่ (ตั้งใจ)
              });
            },
          ),
        ],
      ),

      body: Column(
        children: [
          // ── กล่องคำคมประจำวัน ──
          FutureBuilder<Quote>(
            future: _quoteFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Padding(
                  padding: EdgeInsets.all(16),
                  child: Column(
                    children: [
                      CircularProgressIndicator(),
                      SizedBox(height: 8),
                      Text(
                        'กำลังโหลดคำคม...',
                        style: TextStyle(color: Colors.grey),
                      ),
                    ],
                  ),
                );
              } else if (snapshot.hasError) {
                return Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      const Text(
                        'โหลดคำคมไม่ได้',
                        style: TextStyle(color: Colors.grey),
                      ),
                      TextButton(
                        onPressed: () {
                          setState(() {
                            _quoteFuture = ApiService.fetchQuote(); // โหลดใหม่
                          });
                        },
                        child: const Text('ลองใหม่'),
                      ),
                    ],
                  ),
                );
              } else {
                final quote = snapshot.data!;
                return Container(
                  width: double.infinity,
                  margin: const EdgeInsets.all(12),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.indigo[50],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    children: [
                      Text(
                        '"${quote.text}"',
                        style: const TextStyle(
                          fontStyle: FontStyle.italic,
                          fontSize: 15,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '— ${quote.author}',
                        style: const TextStyle(
                          color: Colors.grey,
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: 4),
                      TextButton.icon(
                        icon: const Icon(Icons.bookmark_add_outlined),
                        label: const Text('บันทึกคำคม'),
                        onPressed: () async {
                          await _saveQuote(quote);
                          if (!context.mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('บันทึกคำคมแล้ว')),
                          );
                        },
                      ),
                    ],
                  ),
                );
              }
            },
          ),

          // ── รายการบันทึก (ของเดิมทั้งก้อน ยัดใน Expanded) ──
          Expanded(
            child: diaries.isEmpty
                ? const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.book_outlined, size: 80, color: Colors.grey),
                        SizedBox(height: 16),
                        Text(
                          'ยังไม่มีบันทึก',
                          style: TextStyle(fontSize: 18, color: Colors.grey),
                        ),
                        Text(
                          'กดปุ่ม + เพื่อเขียนบันทึกแรก',
                          style: TextStyle(color: Colors.grey),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    itemCount: diaries.length, // มีกี่อัน

                    itemBuilder: (context, i) {
                      // สร้างการ์ดทีละอัน
                      final diary = diaries[i];
                      final isQuote = diary.mood.startsWith('คำคม: ');
                      final subtitle = isQuote
                          ? '${diary.mood.substring('คำคม: '.length)} • ${diary.date}'
                          : '${diary.mood} • ${diary.date}';

                      return Card(
                        margin: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),

                        child: ListTile(
                          leading: Icon(
                            isQuote ? Icons.bookmark : Icons.book,
                            color: colors[i % colors.length],
                          ),

                          title: Text(
                            diary.title,
                            maxLines: isQuote ? 2 : 1,
                            overflow: TextOverflow.ellipsis,
                          ),

                          subtitle: Text(
                            subtitle,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),

                          trailing: Row(
                            mainAxisSize:
                                MainAxisSize.min, // ให้ Row กว้างเท่าที่จำเป็น
                            children: [
                              IconButton(
                                icon: const Icon(
                                  Icons.edit,
                                  color: Colors.blue,
                                ),
                                onPressed: () async {
                                  final result = await Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => isQuote
                                          ? EditQuotePage(existing: diary)
                                          : AddDiaryPage(existing: diary),
                                    ),
                                  );
                                  if (result != null && result is Diary) {
                                    await _updateDiary(
                                      result,
                                    ); //  อัปเดตแทนการเพิ่ม
                                  }
                                },
                              ),
                              IconButton(
                                icon: const Icon(
                                  Icons.delete,
                                  color: Colors.red,
                                ),
                                onPressed: () async {
                                  final confirm = await showDialog<bool>(
                                    context: context,
                                    builder: (ctx) => AlertDialog(
                                      title: const Text('ลบบันทึก?'),
                                      content: Text(
                                        'ต้องการลบ "${diaries[i].title}" ใช่ไหม',
                                      ),
                                      actions: [
                                        TextButton(
                                          onPressed: () =>
                                              Navigator.pop(ctx, false),
                                          child: const Text('ยกเลิก'),
                                        ),
                                        TextButton(
                                          onPressed: () =>
                                              Navigator.pop(ctx, true),
                                          child: const Text(
                                            'ลบ',
                                            style: TextStyle(color: Colors.red),
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                  if (confirm == true) {
                                    _deleteDiary(diaries[i].id!);
                                  }
                                },
                              ),
                            ],
                          ),

                          onTap: () {
                            // เมื่อแตะการ์ด

                            Navigator.push(
                              context,

                              MaterialPageRoute(
                                builder: (context) => DiaryDetailPage(
                                  diary: diaries[i],
                                ), // ส่งบันทึกที่แตะไป
                              ),
                            );
                          },
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),

      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          // async เพราะต้องรอค่ากลับ
          final result = await Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const AddDiaryPage()),
          );
          if (result != null && result is Diary) {
            _addDiary(result); // แทน setState(() => diaries.add(result))
          }
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}

// หน้ารายละเอียดบันทึก

class DiaryDetailPage extends StatelessWidget {
  final Diary diary; // รับบันทึกที่ถูกแตะเข้ามา

  const DiaryDetailPage({super.key, required this.diary});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('รายละเอียด')),

      body: Padding(
        padding: const EdgeInsets.all(20),

        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,

          children: [
            Text(
              diary.title,
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 4),

            Text(
              diary.date,
              style: const TextStyle(fontSize: 14, color: Colors.grey),
            ), // << วันที่

            const Divider(height: 32), // << เส้นคั่น

            Text(
              diary.content,
              style: const TextStyle(fontSize: 16, height: 1.6),
            ),
          ],
        ),
      ),
    );
  }
}

// เพิ่ม class นี้

class MainPage extends StatefulWidget {
  const MainPage({super.key});

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  int _selectedIndex = 0; // หน้าที่เลือกอยู่ (0=บันทึก, 1=เกี่ยวกับ)

  // รายการหน้า

  final List<Widget> _pages = [
    const DiaryListPage(), // แท็บ SQLite + คำคม (ของเดิม)
    const ApiDiaryPage(), // แท็บ REST API (สัปดาห์ 4)
    const FirestoreDiaryPage(), // แท็บ Cloud (สัปดาห์นี้)
    const AboutPage(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_selectedIndex], // แสดงหน้าที่เลือก

      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        type: BottomNavigationBarType
            .fixed, // ต้องมีเมื่อ 4 แท็บขึ้นไป (ไม่งั้นแท็บซ่อน)
        onTap: (index) => setState(() => _selectedIndex = index),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.book), label: 'บันทึก'),
          BottomNavigationBarItem(
            icon: Icon(Icons.cloud_queue),
            label: 'ออนไลน์',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.cloud),
            label: 'Cloud',
          ), // เพิ่ม
          BottomNavigationBarItem(icon: Icon(Icons.info), label: 'เกี่ยวกับ'),
        ],
      ),
    );
  }
}

// หน้าเกี่ยวกับ (ง่ายๆ)

class AboutPage extends StatelessWidget {
  const AboutPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('เกี่ยวกับ')),

      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),

          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,

            children: [
              const CircleAvatar(
                // << รูปวงกลม (ใช้ไอคอนแทนรูปก่อน)

                radius: 50,

                backgroundColor: Colors.indigo,

                child: Icon(Icons.book, size: 50, color: Colors.white),
              ),

              const SizedBox(height: 20),

              const Text(
                'MyDiary',
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
              ),

              const SizedBox(height: 8),

              const Text('แอปสมุดบันทึกส่วนตัว'),

              const SizedBox(height: 4),

              const Text('สร้างโดย [ปภังกร วิเศษศรี]'), // << ใส่ชื่อตัวเอง

              const Text('รหัสนักศึกษา [67011212045]'), // << ใส่รหัส

              const SizedBox(height: 16),

              const Text('เวอร์ชัน 1.0', style: TextStyle(color: Colors.grey)),
            ],
          ),
        ),
      ),
    );
  }
}

class AddDiaryPage extends StatefulWidget {
  final Diary? existing; // ถ้าส่งมา = โหมดแก้ไข / null = เพิ่มใหม่
  const AddDiaryPage({super.key, this.existing});
  @override
  State<AddDiaryPage> createState() => _AddDiaryPageState();
}

class _AddDiaryPageState extends State<AddDiaryPage> {
  String _selectedMood = 'มีความสุข'; // ค่าเริ่มต้น
  final List<String> _moods = [
    'มีความสุข',
    'เฉยๆ',
    'เศร้า',
    'เหนื่อย',
    'ตื่นเต้น',
  ];
  DateTime _selectedDate = DateTime.now();
  final _formKey = GlobalKey<FormState>(); // กุญแจคุมฟอร์ม
  final _titleController = TextEditingController(); // อ่านค่าช่องชื่อเรื่อง
  final _contentController = TextEditingController(); // อ่านค่าช่องเนื้อหา

  @override
  void dispose() {
    _titleController.dispose(); // คืนทรัพยากรตอนปิดหน้า
    _contentController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    if (widget.existing != null) {
      // โหมดแก้ไข: เติมค่าเดิม
      _titleController.text = widget.existing!.title;
      _contentController.text = widget.existing!.content;
      _selectedMood = widget.existing!.mood;
      _selectedDate = DateTime.parse(widget.existing!.date);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('เขียนบันทึกใหม่')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: 'ชื่อเรื่อง',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'กรุณากรอกชื่อเรื่อง';
                  }
                  return null; // null = ผ่าน
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _contentController,
                maxLines: 5, // ช่องเนื้อหาสูง 5 บรรทัด
                decoration: const InputDecoration(
                  labelText: 'เนื้อหา',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'กรุณากรอกเนื้อหา';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _selectedMood,
                decoration: const InputDecoration(
                  labelText: 'อารมณ์วันนี้',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.mood),
                ),
                items: _moods.map((mood) {
                  return DropdownMenuItem(value: mood, child: Text(mood));
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    //  เลือกค่าเลือกต้อง setState เอง
                    _selectedMood = value!;
                  });
                },
              ),
              const SizedBox(height: 8),
              ListTile(
                leading: const Icon(Icons.calendar_today),
                title: Text(
                  'วันที่: ${_selectedDate.toString().substring(0, 10)}',
                ),
                trailing: const Icon(Icons.edit),
                onTap: () async {
                  final picked = await showDatePicker(
                    // เปิดปฏิทินให้เลือก
                    context: context,
                    initialDate: _selectedDate,
                    firstDate: DateTime(2020), // เลือกได้ตั้งแต่ปี 2020
                    lastDate: DateTime(2030), // ถึงปี 2030
                  );
                  if (picked != null) {
                    // ถ้าเลือก (ไม่กดยกเลิก)
                    setState(() {
                      _selectedDate = picked;
                    });
                  }
                },
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    if (_formKey.currentState!.validate()) {
                      // validate เช็คแค่ TextFormField
                      final newDiary = Diary(
                        id: widget.existing?.id,
                        title: _titleController.text.trim(),
                        content: _contentController.text.trim(),
                        date: _selectedDate.toString().substring(
                          0,
                          10,
                        ), // วันที่ที่เลือก
                        mood: _selectedMood, // อารมณ์ที่เลือก
                      );
                      Navigator.pop(context, newDiary);
                    }
                  },
                  child: const Text('บันทึก'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ฟอร์มเฉพาะสำหรับแก้ไขคำคมที่บันทึกไว้
class EditQuotePage extends StatefulWidget {
  final Diary existing;

  const EditQuotePage({super.key, required this.existing});

  @override
  State<EditQuotePage> createState() => _EditQuotePageState();
}

class _EditQuotePageState extends State<EditQuotePage> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _quoteController;
  late final TextEditingController _authorController;

  @override
  void initState() {
    super.initState();
    _quoteController = TextEditingController(text: widget.existing.title);
    _authorController = TextEditingController(
      text: widget.existing.mood.replaceFirst('คำคม: ', ''),
    );
  }

  @override
  void dispose() {
    _quoteController.dispose();
    _authorController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('แก้ไขคำคม')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _quoteController,
                maxLines: 5,
                decoration: const InputDecoration(
                  labelText: 'ข้อความคำคม',
                  border: OutlineInputBorder(),
                ),
                validator: (value) => value == null || value.trim().isEmpty
                    ? 'กรุณากรอกข้อความคำคม'
                    : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _authorController,
                decoration: const InputDecoration(
                  labelText: 'ชื่อผู้แต่ง',
                  border: OutlineInputBorder(),
                ),
                validator: (value) => value == null || value.trim().isEmpty
                    ? 'กรุณากรอกชื่อผู้แต่ง'
                    : null,
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    if (!_formKey.currentState!.validate()) return;
                    final quote = _quoteController.text.trim();
                    final author = _authorController.text.trim();
                    Navigator.pop(
                      context,
                      Diary(
                        id: widget.existing.id,
                        title: quote,
                        content: '— $author',
                        date: widget.existing.date,
                        mood: 'คำคม: $author',
                      ),
                    );
                  },
                  child: const Text('บันทึกการแก้ไข'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class Quote {
  final String text;
  final String author;
  Quote({required this.text, required this.author});

  // แปลง JSON (Map) → Quote — เหมือน fromMap ของ SQLite!
  factory Quote.fromJson(Map<String, dynamic> json) {
    return Quote(
      text: json['quote'] ?? '', // dummyjson ใช้ field ชื่อ 'quote'
      author: json['author'] ?? 'ไม่ทราบ',
    );
  }
}

class ApiDiaryPage extends StatefulWidget {
  const ApiDiaryPage({super.key});
  @override
  State<ApiDiaryPage> createState() => _ApiDiaryPageState();
}

class _ApiDiaryPageState extends State<ApiDiaryPage> {
  late Future<List<dynamic>>
  _diariesFuture; // รหัสอยู่ใน ApiService.baseUrl แล้ว

  @override
  void initState() {
    super.initState();
    _loadDiaries();
  }

  void _loadDiaries() {
    setState(() {
      _diariesFuture = ApiService.getDiaries(); // โหลดใหม่ (ได้เฉพาะของเรา)
    });
  }

  // เพิ่มแล้วโหลดใหม่ (แพตเทิร์นเดียวกับ SQLite สัปดาห์ 2!)
  Future<void> _addDiary(
    String title,
    String content,
    String mood,
    String date,
  ) async {
    try {
      await ApiService.createDiary(title, content, mood, date);
      _loadDiaries();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('เพิ่มไม่สำเร็จ ตรวจสอบอินเทอร์เน็ต')),
        );
      }
    }
  }

  Future<void> _deleteDiary(String id) async {
    await ApiService.deleteDiary(id);
    _loadDiaries();
  }

  // แก้ไขแล้วโหลดใหม่
  Future<void> _updateDiary(
    String id,
    String title,
    String content,
    String mood,
    String date,
  ) async {
    await ApiService.updateDiary(id, title, content, mood, date);
    _loadDiaries();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('บันทึกบน Cloud (REST API)')),
      body: FutureBuilder<List<dynamic>>(
        future: _diariesFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('ผิดพลาด: ${snapshot.error}'));
          }
          final diaries = snapshot.data!;
          if (diaries.isEmpty) {
            return const Center(child: Text('ยังไม่มีบันทึก กดปุ่ม +'));
          }
          return ListView.builder(
            itemCount: diaries.length,
            itemBuilder: (context, i) {
              final obj = diaries[i];
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                child: ListTile(
                  title: Text(obj['title'] ?? ''),
                  subtitle: Text(
                    '${obj['mood'] ?? ''} • ${obj['date'] ?? ''} • ${obj['content'] ?? ''}',
                  ),
                  trailing: Row(
                    mainAxisSize:
                        MainAxisSize.min, // ให้ Row กว้างเท่าที่จำเป็น
                    children: [
                      // ── แก้ไข (Update) ──
                      IconButton(
                        icon: const Icon(Icons.edit, color: Colors.blue),
                        onPressed: () async {
                          final result = await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => ApiFormPage(existing: obj),
                            ),
                          ); // ส่ง object เดิม
                          if (result is Map) {
                            await ApiService.updateDiary(
                              obj['id'],
                              result['title'],
                              result['content'],
                              result['mood'],
                              result['date'],
                            );
                            _loadDiaries();
                          }
                        },
                      ),
                      // ── ลบ (Delete) + ยืนยันก่อนลบ ──
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () async {
                          final confirm = await showDialog<bool>(
                            context: context,
                            builder: (ctx) => AlertDialog(
                              title: const Text('ลบบันทึก?'),
                              content: Text(
                                'ต้องการลบ "${obj['title']}" ใช่ไหม',
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(ctx, false),
                                  child: const Text('ยกเลิก'),
                                ),
                                TextButton(
                                  onPressed: () => Navigator.pop(ctx, true),
                                  child: const Text(
                                    'ลบ',
                                    style: TextStyle(color: Colors.red),
                                  ),
                                ),
                              ],
                            ),
                          );
                          if (confirm == true) {
                            await ApiService.deleteDiary(obj['id']);
                            _loadDiaries(); // โหลดใหม่หลังลบ
                          }
                        },
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
      // ── ปุ่มเพิ่ม: เปิดฟอร์มโหมดเพิ่ม แล้วรับค่ากลับมา createDiary ──
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const ApiFormPage()),
          );
          if (result is Map) {
            await _addDiary(
              result['title'],
              result['content'],
              result['mood'],
              result['date'],
            );
          }
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}

class ApiFormPage extends StatefulWidget {
  final Map? existing; // ส่ง obj เดิมมา = โหมดแก้ / null = เพิ่มใหม่
  const ApiFormPage({super.key, this.existing});
  @override
  State<ApiFormPage> createState() => _ApiFormPageState();
}

class _ApiFormPageState extends State<ApiFormPage> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _contentController = TextEditingController();
  String _mood = 'มีความสุข';
  final List<String> _moods = [
    'มีความสุข',
    'เฉยๆ',
    'เศร้า',
    'เหนื่อย',
    'ตื่นเต้น',
  ];
  DateTime _date = DateTime.now();

  @override
  void initState() {
    super.initState();
    if (widget.existing != null) {
      // โหมดแก้: เติมค่าเดิมลงฟอร์ม
      _titleController.text = widget.existing!['title'] ?? '';
      _contentController.text = widget.existing!['content'] ?? '';
      _mood = widget.existing!['mood'] ?? 'มีความสุข';
      _date =
          DateTime.tryParse(widget.existing!['date'] ?? '') ?? DateTime.now();
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.existing == null ? 'เพิ่มบันทึก' : 'แก้ไขบันทึก'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              children: [
                TextFormField(
                  controller: _titleController,
                  decoration: const InputDecoration(
                    labelText: 'ชื่อเรื่อง',
                    border: OutlineInputBorder(),
                  ),
                  validator: (v) => (v == null || v.trim().isEmpty)
                      ? 'กรุณากรอกชื่อเรื่อง'
                      : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _contentController,
                  maxLines: 4,
                  decoration: const InputDecoration(
                    labelText: 'เนื้อหา',
                    border: OutlineInputBorder(),
                  ),
                  validator: (v) => (v == null || v.trim().isEmpty)
                      ? 'กรุณากรอกเนื้อหา'
                      : null,
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: _mood,
                  decoration: const InputDecoration(
                    labelText: 'อารมณ์',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.mood),
                  ),
                  items: _moods
                      .map((m) => DropdownMenuItem(value: m, child: Text(m)))
                      .toList(),
                  onChanged: (v) => setState(() => _mood = v!),
                ),
                const SizedBox(height: 16),
                ListTile(
                  leading: const Icon(Icons.calendar_today),
                  title: Text('วันที่: ${_date.toString().substring(0, 10)}'),
                  trailing: const Icon(Icons.edit),
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: _date,
                      firstDate: DateTime(2020),
                      lastDate: DateTime(2030),
                    );
                    if (picked != null) setState(() => _date = picked);
                  },
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      if (_formKey.currentState!.validate()) {
                        // ส่งค่ากลับเป็น Map ให้หน้ารายการเอาไปเรียก API
                        Navigator.pop(context, {
                          'title': _titleController.text.trim(),
                          'content': _contentController.text.trim(),
                          'mood': _mood,
                          'date': _date.toString().substring(0, 10),
                        });
                      }
                    },
                    child: const Text('บันทึก'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
