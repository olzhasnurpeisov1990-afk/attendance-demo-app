class AppData {
  final Map<String, String> teachers;
  final Map<String, ClassData> classes;

  AppData({required this.teachers, required this.classes});

  factory AppData.fromJson(Map<String, dynamic> json) {
    final teachers = Map<String, String>.from(json['teachers'] ?? {});
    final classesRaw = Map<String, dynamic>.from(json['classes'] ?? {});
    final classes = classesRaw.map((k, v) => MapEntry(k, ClassData.fromJson(Map<String, dynamic>.from(v))));
    return AppData(teachers: teachers, classes: classes);
  }
}

class ClassData {
  final String teacher;
  final List<String> students;
  ClassData({required this.teacher, required this.students});
  factory ClassData.fromJson(Map<String, dynamic> json) => ClassData(teacher: json['teacher'] ?? '', students: List<String>.from(json['students'] ?? []));
}
