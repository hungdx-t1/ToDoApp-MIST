// lib/utils/task_search_delegate.dart

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/task_model.dart';
import '../view_models/task_view_model.dart';
import '../views/task_detail_screen.dart';

// lớp xử lý tìm kiếm
class TaskSearchDelegate extends SearchDelegate {
  final TaskViewModel viewModel;

  TaskSearchDelegate(this.viewModel);

  @override
  String? get searchFieldLabel => 'Tìm kiếm công việc...';

  @override
  List<Widget>? buildActions(BuildContext context) {
    return [
      if (query.isNotEmpty)
        IconButton(
          icon: const Icon(Icons.clear),
          onPressed: () {
            query = ''; // Xóa text tìm kiếm
          },
        ),
    ];
  }

  @override
  Widget? buildLeading(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.arrow_back),
      onPressed: () {
        close(context, null); // Đóng màn hình tìm kiếm
      },
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    return _buildList(context);
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    return _buildList(context);
  }

  // hiển thị list kết quả
  Widget _buildList(BuildContext context) {
    // 1. lọc danh sách dựa trên query
    final List<Task> allTasks = viewModel.tasks;
    final List<Task> results = allTasks.where((task) {
      final titleLower = task.title.toLowerCase();
      final queryLower = query.toLowerCase();
      return titleLower.contains(queryLower);
    }).toList();

    if (results.isEmpty) {
      return Center(
        child: Text(
          query.isEmpty ? "Nhập tên công việc để tìm" : "Không tìm thấy kết quả nào",
          style: TextStyle(color: Colors.grey[600]),
        ),
      );
    }

    // 2. hiển thị danh sách kết quả
    return ListView.builder(
      itemCount: results.length,
      itemBuilder: (context, index) {
        final task = results[index];
        final category = viewModel.getCategoryById(task.categoryId);

        // icon trạng thái (Done/Pending)
        final icon = task.isCompleted
            ? const Icon(Icons.check_circle, color: Colors.green)
            : const Icon(Icons.radio_button_unchecked, color: Colors.grey);

        return ListTile(
          leading: icon,
          title: Text(task.title, style: const TextStyle(fontWeight: FontWeight.bold)),
          subtitle: Text(
            "${category?.name ?? 'No Category'} • ${DateFormat('dd/MM HH:mm').format(task.startTime)}",
          ),
          onTap: () {
            // đóng màn hình tìm kiếm trước khi vào chi tiết (để khi back ra là về Home)
            // close(context, null);
            // Hoặc muốn giữ trạng thái tìm kiếm thì cứ push đè lên:
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => TaskDetailScreen(task: task)),
            );
          },
        );
      },
    );
  }
}