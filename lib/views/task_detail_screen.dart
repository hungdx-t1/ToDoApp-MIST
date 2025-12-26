// lib/views/task_detail_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../models/task_model.dart';
import '../view_models/task_view_model.dart';
import 'add_task_screen.dart';

class TaskDetailScreen extends StatelessWidget {
  final Task task;

  const TaskDetailScreen({super.key, required this.task});

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<TaskViewModel>();

    // lấy task mới nhất từ list (để UI tự update khi sửa xong)
    Task currentTask;
    try {
      // Tìm task trong list của ViewModel trùng ID với task được truyền vào
      currentTask = viewModel.tasks.firstWhere((t) => t.id == task.id);
    } catch (e) {
      // Task bị xóa khi đang xem, fallback về task cũ (hiếm xảy ra)
      currentTask = task;
    }

    final category = viewModel.getCategoryById(task.categoryId);

    Color catColor = Colors.blue;
    if (category != null) {
      catColor = Color(int.parse(category.hexColor.replaceFirst('#', '0xff')));
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text("Chi tiết"),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined, color: Colors.blue),
            tooltip: "Chỉnh sửa",
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => AddTaskScreen(taskToEdit: currentTask),
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline, color: Colors.red),
            tooltip: "Xóa",
            onPressed: () {
              // Logic xóa task
              viewModel.deleteTask(task.id!);
              Navigator.pop(context);
            },
          )
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Category Badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: catColor.withOpacity(0.2),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: catColor),
              ),
              child: Text(
                category?.name ?? "Unknown",
                style: TextStyle(color: catColor, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: 15),

            // Title (Dùng currentTask để hiện tên mới nhất)
            Text(task.title, style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold)),

            const SizedBox(height: 25),

            // Times
            _buildRow(Icons.play_circle_outline, "Bắt đầu", task.startTime),
            const SizedBox(height: 10),
            _buildRow(Icons.flag_outlined, "Hạn chót", task.deadline, isRed: true),

            const Divider(height: 40),

            // Description
            const Text("Mô tả:", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 10),
            Text(
              task.description != null && task.description!.isNotEmpty
                  ? task.description!
                  : "Không có mô tả nào.",
              style: const TextStyle(fontSize: 16, color: Colors.black87, height: 1.5),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRow(IconData icon, String label, DateTime date, {bool isRed = false}) {
    return Row(
      children: [
        Icon(icon, color: isRed ? Colors.red : Colors.grey, size: 20),
        const SizedBox(width: 10),
        Text("$label: ", style: const TextStyle(fontSize: 16)),
        Text(
          DateFormat('HH:mm - dd/MM/yyyy').format(date),
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: isRed ? Colors.red : Colors.black),
        ),
      ],
    );
  }
}