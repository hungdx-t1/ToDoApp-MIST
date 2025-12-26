// lib/views/category_management_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../view_models/task_view_model.dart';
import '../models/category_model.dart';

class CategoryManagementScreen extends StatelessWidget {
  const CategoryManagementScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Lắng nghe thay đổi từ ViewModel
    final viewModel = context.watch<TaskViewModel>();
    final categories = viewModel.categories;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Quản lý danh mục"),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: categories.isEmpty
          ? const Center(child: Text("Chưa có danh mục nào"))
          : ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: categories.length,
        itemBuilder: (context, index) {
          final category = categories[index];

          // Tính toán thống kê
          final totalTasks = viewModel.getTotalTasksByCategory(category.id!);
          final completedTasks = viewModel.getCompletedTasksByCategory(category.id!);
          final progress = totalTasks == 0 ? 0.0 : completedTasks / totalTasks;

          // Parse màu
          Color catColor = Colors.blue;
          try {
            catColor = Color(int.parse(category.hexColor.replaceFirst('#', '0xff')));
          } catch (_) {}

          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: Row(
                children: [
                  // 1. Vòng tròn màu sắc
                  Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      color: catColor.withOpacity(0.2),
                      shape: BoxShape.circle,
                      border: Border.all(color: catColor, width: 2),
                    ),
                    child: Icon(Icons.folder, color: catColor),
                  ),
                  const SizedBox(width: 16),

                  // 2. Thông tin + Thống kê
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          category.name,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          "Tiến độ: $completedTasks/$totalTasks công việc",
                          style: TextStyle(color: Colors.grey[600], fontSize: 13),
                        ),
                        const SizedBox(height: 8),
                        // Thanh tiến độ nhỏ
                        ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: progress,
                            backgroundColor: Colors.grey[200],
                            color: catColor,
                            minHeight: 4,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // 3. Nút xóa
                  IconButton(
                    icon: const Icon(Icons.delete_outline, color: Colors.red),
                    onPressed: () => _confirmDelete(context, category, totalTasks),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // Hộp thoại cảnh báo trước khi xóa
  void _confirmDelete(BuildContext context, Category category, int totalTasks) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Xóa danh mục?"),
        content: Text.rich(
          TextSpan(
            text: "Bạn có chắc muốn xóa danh mục ",
            style: const TextStyle(color: Colors.black),
            children: [
              TextSpan(
                  text: "${category.name}?\n\n",
                  style: const TextStyle(fontWeight: FontWeight.bold)),
              const TextSpan(
                  text: "CẢNH BÁO: ", style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
              TextSpan(
                  text: "$totalTasks công việc thuộc danh mục này cũng sẽ bị xóa vĩnh viễn!"),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Hủy"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              // Gọi ViewModel xóa
              context.read<TaskViewModel>().deleteCategory(category.id!);
              Navigator.pop(ctx);
            },
            child: const Text("Xóa luôn", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}