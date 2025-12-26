// lib/views/add_task_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../models/task_model.dart';
import '../view_models/task_view_model.dart';

class AddTaskScreen extends StatefulWidget {
  final Task? taskToEdit;

  const AddTaskScreen({super.key, this.taskToEdit});

  @override
  State<AddTaskScreen> createState() => _AddTaskScreenState();
}

class _AddTaskScreenState extends State<AddTaskScreen> {
  final _titleController = TextEditingController();
  final _descController = TextEditingController();

  int? _selectedCategoryId; // Lưu ID danh mục được chọn
  DateTime _startTime = DateTime.now();
  DateTime _deadline = DateTime.now().add(const Duration(hours: 1));

  @override
  void initState() {
    super.initState();

    // kiểm tra chế độ sửa
    if (widget.taskToEdit != null) {
      // Nếu là sửa, điền dữ liệu cũ vào form
      final t = widget.taskToEdit!;
      _titleController.text = t.title;
      _descController.text = t.description ?? '';
      _selectedCategoryId = t.categoryId;
      _startTime = t.startTime;
      _deadline = t.deadline;
    } else {
      // Nếu là thêm mới, lấy category mặc định
      final viewModel = context.read<TaskViewModel>();
      if (viewModel.categories.isNotEmpty) {
        _selectedCategoryId = viewModel.categories.first.id;
      }
    }
  }

  // Hàm chọn ngày giờ
  Future<void> _pickDateTime(bool isStart) async {
    final date = await showDatePicker(
      context: context,
      initialDate: isStart ? _startTime : _deadline, // UX: focus vào ngày hiện tại của task
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (date == null) return;

    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(isStart ? _startTime : _deadline),
    );

    if (time == null) return;

    final result = DateTime(date.year, date.month, date.day, time.hour, time.minute);

    setState(() {
      if (isStart) {
        _startTime = result;
      } else {
        _deadline = result;
      }
    });
  }

  void _saveTask() {
    if (_titleController.text.isEmpty || _selectedCategoryId == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Vui lòng nhập tên và chọn danh mục')));
      return;
    }

    // validate thời gian
    if (_startTime.isAfter(_deadline)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Lỗi: Thời gian bắt đầu phải trước Hạn chót!'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Lấy ViewModel
    final viewModel = context.read<TaskViewModel>();

    if (widget.taskToEdit == null) {
      final newTask = Task( // thêm mới
        title: _titleController.text,
        description: _descController.text,
        categoryId: _selectedCategoryId!,
        startTime: _startTime,
        deadline: _deadline,
      );
      viewModel.addTask(newTask);
    } else {
      // chỉnh sửa: giữ nguyên ID, trạng thái hoàn thành, sao... chỉ sửa nội dung
      final updatedTask = Task(
        id: widget.taskToEdit!.id, // phải giữ ID cũ
        title: _titleController.text,
        description: _descController.text,
        categoryId: _selectedCategoryId!,
        startTime: _startTime,
        deadline: _deadline,
        isCompleted: widget.taskToEdit!.isCompleted,
        isMarkedStar: widget.taskToEdit!.isMarkedStar,
      );
      viewModel.updateTask(updatedTask);
    }

    Navigator.pop(context);
  }

  // Hàm hiển thị dialog thêm category mới (như cũ, nhưng update cho đúng logic mới)
  void _showAddCategoryDialog() {
    final nameController = TextEditingController();
    showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text("Thêm danh mục"),
          content: TextField(controller: nameController, decoration: const InputDecoration(hintText: "Tên danh mục")),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Hủy")),
            ElevatedButton(onPressed: () {
              // Mặc định màu đỏ cho demo, bạn có thể làm color picker sau
              context.read<TaskViewModel>().addCategory(nameController.text, "#FF5722");
              Navigator.pop(ctx);
            }, child: const Text("Thêm"))
          ],
        )
    );
  }

  @override
  Widget build(BuildContext context) {
    // Lấy list category từ VM
    final categories = context.watch<TaskViewModel>().categories;

    return Scaffold(
      appBar: AppBar(
          title: Text(widget.taskToEdit == null ? 'Thêm công việc' : 'Sửa công việc'),
          backgroundColor: Colors.white,
          foregroundColor: Colors.black,
          elevation: 0
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title
            TextField(
              controller: _titleController,
              decoration: InputDecoration(
                labelText: 'Tên công việc',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 20),

            // Description
            TextField(
              controller: _descController,
              maxLines: 3,
              decoration: InputDecoration(
                labelText: 'Mô tả (Tùy chọn)',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 20),

            // Category Selector
            const Text("Danh mục", style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            Wrap(
              spacing: 10,
              children: [
                ...categories.map((cat) => ChoiceChip(
                  label: Text(cat.name),
                  selected: _selectedCategoryId == cat.id,
                  onSelected: (selected) {
                    setState(() => _selectedCategoryId = cat.id);
                  },
                )),
                ActionChip(
                  avatar: const Icon(Icons.add),
                  label: const Text("Mới"),
                  onPressed: _showAddCategoryDialog,
                )
              ],
            ),
            const SizedBox(height: 20),

            // Date Pickers
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.play_arrow),
                    label: Text(DateFormat('HH:mm dd/MM').format(_startTime)),
                    onPressed: () => _pickDateTime(true),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.stop),
                    label: Text(DateFormat('HH:mm dd/MM').format(_deadline)),
                    onPressed: () => _pickDateTime(false),
                    style: OutlinedButton.styleFrom(foregroundColor: Colors.red),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 40),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _saveTask,
                child: Text(widget.taskToEdit == null ? 'Lưu công việc' : 'Cập nhật'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}