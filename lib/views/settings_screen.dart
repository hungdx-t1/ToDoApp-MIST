import 'package:flutter/material.dart';

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
      body: ListView(
        children: [
          SwitchListTile(
            title: const Text("Giao diện tối (Dark Mode)"),
            subtitle: const Text("Chuyển đổi giao diện sáng/tối"),
            value: false, // Sau này sẽ binding với ViewModel
            onChanged: (val) {
              // TODO: Xử lý logic dark mode
            },
          ),
          ListTile(
            leading: const Icon(Icons.notifications_outlined),
            title: const Text("Cài đặt thông báo"),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () {
              // TODO: Điều hướng sang màn hình setting thông báo
            },
          ),
        ],
      ),
    );
  }
}