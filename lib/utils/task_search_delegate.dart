// lib/utils/task_search_delegate.dart

import 'package:flutter/material.dart';

// lớp xử lý tìm kiếm
class TaskSearchDelegate extends SearchDelegate {
  @override
  String? get searchFieldLabel => 'Tìm kiếm công việc...';

  @override
  List<Widget>? buildActions(BuildContext context) {
    return [
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
    // Logic hiển thị kết quả khi nhấn Enter
    return Center(child: Text("Kết quả cho: $query"));
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    // Logic hiển thị gợi ý khi đang gõ
    // Bạn có thể kết nối với ViewModel để filter list task tại đây
    return Container();
  }
}