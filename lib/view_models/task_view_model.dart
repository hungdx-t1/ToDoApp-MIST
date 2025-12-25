import 'package:flutter/material.dart';
import '../models/task_model.dart';
import '../models/category_model.dart';
import '../data/database_helper.dart';

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
    await DatabaseHelper.instance.insertTask(task);
    await loadData(); // Reload lại list
  }

  Future<void> updateTask(Task task) async {
    await DatabaseHelper.instance.updateTask(task);
    await loadData();
  }

  Future<void> deleteTask(int id) async {
    await DatabaseHelper.instance.deleteTask(id);
    await loadData();
  }

  // Hàm nhanh để toggle trạng thái
  void toggleTaskStatus(Task task) {
    task.isCompleted = !task.isCompleted;
    updateTask(task);
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
    // Vì DB có ON DELETE CASCADE, các task sẽ tự mất trong DB.
    // Ta chỉ cần load lại dữ liệu để ViewModel cập nhật list _tasks và _categories mới.
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
}