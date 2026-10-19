import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

import 'models.dart';
import 'services/storage_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final storage = await StorageService.create();
  runApp(AttendanceDemoApp(storage: storage));
}

class AttendanceDemoApp extends StatelessWidget {
  final StorageService storage;
  const AttendanceDemoApp({required this.storage, Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Attendance Demo',
      theme: ThemeData(primarySwatch: Colors.indigo),
      home: FutureBuilder<AppData>(
        future: loadInitialData(),
        builder: (context, snap) {
          if (snap.connectionState != ConnectionState.done) {
            return const Scaffold(body: Center(child: CircularProgressIndicator()));
          }
          final appData = snap.data!;
          return LoginScreen(appData: appData, storage: storage);
        },
      ),
    );
  }

  Future<AppData> loadInitialData() async {
    final jsonStr = await rootBundle.loadString('assets/attendance_app_data.json');
    final map = json.decode(jsonStr) as Map<String, dynamic>;
    return AppData.fromJson(map);
  }
}

class LoginScreen extends StatefulWidget {
  final AppData appData;
  final StorageService storage;
  const LoginScreen({required this.appData, required this.storage, Key? key}) : super(key: key);

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  String? _error;

  void _login() async {
    final email = _emailCtrl.text.trim();
    final pass = _passCtrl.text;
    final users = widget.appData.teachers;
    if (users.containsKey(email) && users[email] == pass) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => ClassesScreen(appData: widget.appData, storage: widget.storage, teacherId: email),
        ),
      );
    } else {
      setState(() => _error = 'Қате логин немесе пароль');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Кіру')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextField(controller: _emailCtrl, decoration: const InputDecoration(labelText: 'Логин')),
            const SizedBox(height: 8),
            TextField(controller: _passCtrl, decoration: const InputDecoration(labelText: 'Пароль'), obscureText: true),
            const SizedBox(height: 12),
            ElevatedButton(onPressed: _login, child: const Text('Кіру')),
            if (_error != null) ...[
              const SizedBox(height: 12),
              Text(_error!, style: const TextStyle(color: Colors.red)),
            ]
          ],
        ),
      ),
    );
  }
}

class ClassesScreen extends StatefulWidget {
  final AppData appData;
  final StorageService storage;
  final String teacherId;
  const ClassesScreen({required this.appData, required this.storage, required this.teacherId, Key? key}) : super(key: key);

  @override
  State<ClassesScreen> createState() => _ClassesScreenState();
}

class _ClassesScreenState extends State<ClassesScreen> {
  @override
  Widget build(BuildContext context) {
    final classes = widget.appData.classes.entries.where((e) => e.value.teacher == widget.teacherId).toList();
    return Scaffold(
      appBar: AppBar(title: const Text('Сыныптар')),
      body: ListView.builder(
        itemCount: classes.length,
        itemBuilder: (context, idx) {
          final cId = classes[idx].key;
          final c = classes[idx].value;
          return ListTile(
            title: Text(cId),
            subtitle: Text('${c.students.length} оқушы'),
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ClassDetailScreen(classId: cId, classData: c, storage: widget.storage))),
          );
        },
      ),
    );
  }
}

class ClassDetailScreen extends StatefulWidget {
  final String classId;
  final ClassData classData;
  final StorageService storage;
  const ClassDetailScreen({required this.classId, required this.classData, required this.storage, Key? key}) : super(key: key);

  @override
  State<ClassDetailScreen> createState() => _ClassDetailScreenState();
}

class _ClassDetailScreenState extends State<ClassDetailScreen> {
  late Map<String, String> statuses; // student -> status
  late String todayKey;

  @override
  void initState() {
    super.initState();
    final date = DateFormat('yyyy-MM-dd').format(DateTime.now());
    todayKey = date;
    statuses = {};
    _load();
  }

  Future<void> _load() async {
    final map = await widget.storage.loadAttendanceForDate(widget.classId, todayKey);
    setState(() => statuses = map);
  }

  void _toggleStatus(String student) {
    final order = ['present', 'late', 'absent_unexcused', 'absent_excused', 'sick'];
    final cur = statuses[student] ?? 'present';
    final idx = order.indexOf(cur);
    final next = order[(idx + 1) % order.length];
    setState(() => statuses[student] = next);
    widget.storage.saveAttendanceForDate(widget.classId, todayKey, statuses);
  }

  void _markAllPresent() {
    final newMap = {for (var s in widget.classData.students) s: 'present'};
    setState(() => statuses = newMap);
    widget.storage.saveAttendanceForDate(widget.classId, todayKey, statuses);
  }

  Color _colorFor(String status) {
    switch (status) {
      case 'present':
        return Colors.green;
      case 'late':
        return Colors.orange;
      case 'absent_unexcused':
        return Colors.red;
      case 'absent_excused':
        return Colors.blueGrey;
      case 'sick':
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }

  String _label(String status) {
    switch (status) {
      case 'present':
        return '✅ Қатысты';
      case 'late':
        return '⏰ Кешікті';
      case 'absent_unexcused':
        return '❌ Себепсіз';
      case 'absent_excused':
        return '📝 Себепті';
      case 'sick':
        return '🏥 Ауру';
      default:
        return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.classId)),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _markAllPresent,
        label: const Text('Барлығын Қатысты'),
        icon: const Icon(Icons.check),
      ),
      body: ListView.builder(
        itemCount: widget.classData.students.length,
        itemBuilder: (context, idx) {
          final student = widget.classData.students[idx];
          final status = statuses[student] ?? 'present';
          return ListTile(
            title: Text(student),
            subtitle: Text(_label(status)),
            leading: CircleAvatar(backgroundColor: _colorFor(status), child: Text(student[0])),
            onTap: () => _toggleStatus(student),
            onLongPress: () async {
              final reason = await showDialog<String?>(context: context, builder: (c) {
                final ctrl = TextEditingController();
                return AlertDialog(
                  title: const Text('Себебін енгізіңіз'),
                  content: TextField(controller: ctrl),
                  actions: [TextButton(onPressed: () => Navigator.pop(c), child: const Text('Болдырмау')), TextButton(onPressed: () => Navigator.pop(c, ctrl.text), child: const Text('Сақтау'))],
                );
              });
              if (reason != null) {
                // store as status with reason in storage as a special combined string
                setState(() => statuses[student] = 'absent_excused');
                await widget.storage.saveAttendanceForDate(widget.classId, todayKey, statuses, reasons: {student: reason});
              }
            },
          );
        },
      ),
    );
  }
}
