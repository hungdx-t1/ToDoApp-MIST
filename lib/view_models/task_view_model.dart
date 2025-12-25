import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../models/task_model.dart';
import '../models/category_model.dart';
import '../data/database_helper.dart';
import '../services/notification_service.dart';

class TaskViewModel extends ChangeNotifier {
  List<Task> _tasks = [];
  List<Category> _categories = [];
  bool _isLoading = false;

  // Getters
  List<Task> get tasks => _tasks;
  List<Category> get categories => _categories;
  bool get isLoading => _isLoading;

  // logic filters (lọc dữ liệu)
  List<Task> get activeTasks => _tasks.where((t) => !t.isCompleted).toList(); // Việc cần làm (Chưa xong)
  List<Task> get completedTasks => _tasks.where((t) => t.isCompleted).toList(); // Việc đã xong
  List<Task> get starredTasks => _tasks.where((t) => t.isMarkedStar).toList(); // Việc quan trọng (Có sao)

  final NotificationService _notificationService = NotificationService();

  // Helper: Lấy thông tin Category từ ID (dùng cho UI hiển thị)
  Category? getCategoryById(int id) {
    try {
      return _categories.firstWhere((c) => c.id == id);
    } catch (e) {
      return null; // Không tìm thấy (hoặc đã bị xóa)
    }
  }

  // các hàm tương tác db
  Future<void> loadData() async {
    _isLoading = true;
    notifyListeners();

    // Load song song cả 2 bảng
    final results = await Future.wait([
      DatabaseHelper.instance.getTasks(),
      DatabaseHelper.instance.getCategories(),
    ]);

    _tasks = results[0] as List<Task>;
    _categories = results[1] as List<Category>;

    _isLoading = false;
    notifyListeners();
  }

  Future<void> addTask(Task task) async {
    // await DatabaseHelper.instance.insertTask(task);
    int newId = await DatabaseHelper.instance.insertTask(task); // insert, đồng thời lấy id vừa tạo

    // Hẹn giờ thông báo (Task ban đầu id là null, nhưng khi insert xong DB trả về ID thật)
    await _notificationService.scheduleNotification(
      id: newId,
      title: 'Đã đến giờ: ${task.title}',
      body: task.description ?? 'Hãy bắt đầu công việc ngay nhé!',
      scheduledTime: task.startTime, // Dùng giờ bắt đầu để nhắc
    );

    await loadData(); // Reload lại list
  }

  Future<void> updateTask(Task task) async {
    await DatabaseHelper.instance.updateTask(task);
    await loadData();
  }

  Future<void> deleteTask(int id) async {
    await DatabaseHelper.instance.deleteTask(id);
    await _notificationService.cancelNotification(id); // Hủy thông báo
    await loadData();
  }

  // Hàm nhanh để toggle trạng thái
  void toggleTaskStatus(Task task) {
    task.isCompleted = !task.isCompleted;
    updateTask(task);
    if (task.isCompleted) {
      _notificationService.cancelNotification(task.id!); // Nếu xong rồi thì tắt thông báo đi cho đỡ phiền
    } else {
      _notificationService.scheduleNotification( // Nếu bỏ tick (chưa xong) thì hẹn giờ lại (nếu thời gian chưa qua)
          id: task.id!,
          title: task.title,
          body: task.description ?? '',
          scheduledTime: task.startTime
      );

      // TODO Trong trường hợp đã qua
    }
  }

  void toggleTaskStar(Task task) {
    task.isMarkedStar = !task.isMarkedStar;
    updateTask(task);
  }

  // thêm Category mới
  Future<void> addCategory(String name, String hexColor) async {
    final newCat = Category(name: name, hexColor: hexColor);
    await DatabaseHelper.instance.insertCategory(newCat);
    await loadData(); // Load lại để update dropdown ở màn hình AddTask
  }

  // xóa danh mục
  Future<void> deleteCategory(int id) async {
    await DatabaseHelper.instance.deleteCategory(id);
    await loadData();
  }

  // đếm tổng số task trong 1 danh mục
  int getTotalTasksByCategory(int catId) {
    return _tasks.where((t) => t.categoryId == catId).length;
  }

  // đếm số task đã hoàn thành trong 1 danh mục
  int getCompletedTasksByCategory(int catId) {
    return _tasks.where((t) => t.categoryId == catId && t.isCompleted).length;
  }

  // xuất file json
  Future<void> exportToJson() async {
    try {
      _isLoading = true;
      notifyListeners();

      // a. Gom dữ liệu thành Map
      final data = {
        'version': 1, // Đánh dấu phiên bản backup
        'timestamp': DateTime.now().toIso8601String(),
        'categories': _categories.map((c) => c.toMap()).toList(),
        'tasks': _tasks.map((t) => t.toMap()).toList(),
      };

      // b. Chuyển sang chuỗi JSON
      final jsonString = jsonEncode(data);

      // c. Lưu vào file tạm
      final directory = await getTemporaryDirectory();
      final file = File('${directory.path}/todo_backup_${DateTime.now().millisecondsSinceEpoch}.json');
      await file.writeAsString(jsonString);

      // d. Gọi hộp thoại chia sẻ (Share Sheet)
      // Người dùng có thể chọn lưu vào Drive, gửi Zalo, hoặc Lưu vào Tệp
      await Share.shareXFiles([XFile(file.path)], text: 'Sao lưu dữ liệu Pro Todo'); // TODO deprecated method , 'shareXFiles' is deprecated and shouldn't be used. Use SharePlus.instance.share() instead.

    } catch (e) {
      debugPrint("Lỗi Export: $e");
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // nhập file json
  Future<bool> importFromJson() async {
    try {
      // a. Mở trình chọn file
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json'], // Chỉ cho chọn file .json
      );

      if (result != null) {
        _isLoading = true;
        notifyListeners();

        File file = File(result.files.single.path!);
        String jsonString = await file.readAsString();

        // b. Decode JSON
        Map<String, dynamic> data = jsonDecode(jsonString); // dart.convert

        // Kiểm tra sơ qua cấu trúc file
        if (data.containsKey('categories') && data.containsKey('tasks')) {
          List<Map<String, dynamic>> cats = List<Map<String, dynamic>>.from(data['categories']);
          List<Map<String, dynamic>> tasks = List<Map<String, dynamic>>.from(data['tasks']);

          // c. Gọi DatabaseHelper để restore
          await DatabaseHelper.instance.restoreBackup(categories: cats, tasks: tasks);
          await _notificationService.cancelAll(); // Hủy hết thông báo cũ

          // d. Load lại dữ liệu lên UI
          await loadData();

          for (var task in _tasks) {
            if (!task.isCompleted) {
              await _notificationService.scheduleNotification(
                  id: task.id!,
                  title: task.title,
                  body: task.description ?? '',
                  scheduledTime: task.startTime
              );
            }
          }

          return true; // Thành công
        }
      }
    } catch (e) {
      debugPrint("Lỗi Import: $e");
    } finally {
      _isLoading = false;
      notifyListeners();
    }
    return false; // Thất bại
  }
}