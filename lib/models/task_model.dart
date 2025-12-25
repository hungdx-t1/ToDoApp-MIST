class Task {
  final int? id;
  final String title;
  final String? description;
  final int categoryId; // region khóa ngoại
  final DateTime deadline;
  final DateTime startTime;
  bool isCompleted;
  bool isMarkedStar;
 // bool isRepeated; // TODO hơi nâng cao, dành cho chức năng lặp lại task

  Task({
    this.id,
    required this.title,
    this.description,
    required this.categoryId,
    required this.deadline,
    required this.startTime,
    this.isCompleted = false,
    this.isMarkedStar = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'categoryId': categoryId,
      'deadline': deadline.toIso8601String(),
      'startTime': startTime.toIso8601String(),
      'isCompleted': isCompleted ? 1 : 0,
      'isMarkedStar': isMarkedStar ? 1 : 0,
    };
  }

  factory Task.fromMap(Map<String, dynamic> map) {
    return Task(
      id: map['id'],
      title: map['title'],
      description: map['description'],
      categoryId: map['categoryId'],
      deadline: DateTime.parse(map['deadline']),
      startTime: DateTime.parse(map['startTime']),
      isCompleted: map['isCompleted'] == 1,
      isMarkedStar: map['isMarkedStar'] == 1,
    );
  }
}
