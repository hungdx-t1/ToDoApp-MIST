import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../view_models/task_view_model.dart'; // Import ViewModel

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Cài đặt"),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: Consumer<TaskViewModel>(
        builder: (context, viewModel, child) {
          // Hiển thị loading nếu đang xử lý file
          if (viewModel.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          return ListView(
            children: [
              // --- PHẦN GIAO DIỆN ---
              const Padding(
                padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: Text("Giao diện", style: TextStyle(color: Colors.blue, fontWeight: FontWeight.bold)),
              ),
              SwitchListTile(
                title: const Text("Giao diện tối (Dark Mode)"),
                subtitle: const Text("Chuyển đổi giao diện sáng/tối"),
                value: false,
                onChanged: (val) {
                  // TODO: Xử lý logic dark mode
                },
              ),

              const Divider(),

              // --- PHẦN DỮ LIỆU (MỚI) ---
              const Padding(
                padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: Text("Sao lưu & Khôi phục", style: TextStyle(color: Colors.blue, fontWeight: FontWeight.bold)),
              ),

              // Nút Xuất dữ liệu
              ListTile(
                leading: const Icon(Icons.upload_file, color: Colors.green),
                title: const Text("Xuất dữ liệu (.json)"),
                subtitle: const Text("Sao lưu toàn bộ công việc và danh mục"),
                onTap: () async {
                  await viewModel.exportToJson();
                },
              ),

              // Nút Nhập dữ liệu
              ListTile(
                leading: const Icon(Icons.download_rounded, color: Colors.orange),
                title: const Text("Nhập dữ liệu"),
                subtitle: const Text("Khôi phục từ file backup (Sẽ xóa dữ liệu hiện tại)"),
                onTap: () => _confirmImport(context, viewModel),
              ),

              const Divider(),

              const Padding(
                padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: Text("Cài đặt thông báo", style: TextStyle(color: Colors.blue, fontWeight: FontWeight.bold)),
              ),

              ListTile(
                leading: const Icon(Icons.notifications_active),
                title: const Text("Quản lý thông báo"),
                subtitle: const Text("Truy cập vào cài đặt ứng dụng và bật/tắt thông báo đẩy"),
                // TODO onTap vào settings
              ),

              const Divider(),

              ListTile(
                leading: const Icon(Icons.info_outline),
                title: const Text("Thông tin ứng dụng"),
                trailing: const Text("v1.0.0", style: TextStyle(color: Colors.grey)),
              ),
            ],
          );
        },
      ),
    );
  }

  // Hộp thoại cảnh báo trước khi Import
  void _confirmImport(BuildContext context, TaskViewModel viewModel) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Cảnh báo khôi phục"),
        content: const Text(
          "Hành động này sẽ XÓA TOÀN BỘ dữ liệu hiện tại và thay thế bằng dữ liệu trong file backup.\n\nBạn có chắc chắn muốn tiếp tục không?",
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Hủy")),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              Navigator.pop(ctx); // Đóng dialog trước

              // Gọi hàm import
              bool success = await viewModel.importFromJson();

              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(success ? "Khôi phục thành công!" : "Lỗi hoặc đã hủy chọn file"),
                    backgroundColor: success ? Colors.green : Colors.red,
                  ),
                );
              }
            },
            child: const Text("Đồng ý nhập", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}