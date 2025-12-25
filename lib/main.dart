import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'view_models/task_view_model.dart';
import 'views/add_task_screen.dart';
import 'views/task_detail_screen.dart';
import 'views/category_management_screen.dart';
import 'models/task_model.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => TaskViewModel()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Pro Todo',
      theme: ThemeData(primarySwatch: Colors.blue, scaffoldBackgroundColor: Colors.grey[100]),
      home: const HomeScreen(),
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
    // Load dữ liệu khi mở app
    Future.microtask(() => context.read<TaskViewModel>().loadData());
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3, // 3 Tab
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Công việc của tôi', style: TextStyle(color: Colors.black)),
          backgroundColor: Colors.white,
          elevation: 0,

          actions: [
            IconButton(
              icon: const Icon(Icons.category, color: Colors.black), // Icon quản lý danh mục
              tooltip: "Quản lý danh mục",
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const CategoryManagementScreen()),
                );
              },
            ),
          ],

          bottom: const TabBar(
            labelColor: Colors.blue,
            unselectedLabelColor: Colors.grey,
            indicatorColor: Colors.blue,
            tabs: [
              Tab(text: 'Cần làm'),
              Tab(text: 'Quan trọng'),
              Tab(text: 'Đã xong'),
            ],
          ),
        ),
        body: Consumer<TaskViewModel>(
          builder: (context, viewModel, child) {
            if (viewModel.isLoading) return const Center(child: CircularProgressIndicator());

            return TabBarView(
              children: [
                _buildTaskList(context, viewModel.activeTasks, viewModel),
                _buildTaskList(context, viewModel.starredTasks, viewModel),
                _buildTaskList(context, viewModel.completedTasks, viewModel),
              ],
            );
          },
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const AddTaskScreen()),
          ),
          child: const Icon(Icons.add),
        ),
      ),
    );
  }

  // Widget hiển thị danh sách để tái sử dụng cho 3 tab
  Widget _buildTaskList(BuildContext context, List<Task> tasks, TaskViewModel viewModel) {
    if (tasks.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.inbox, size: 60, color: Colors.grey[300]),
            const SizedBox(height: 10),
            Text('Không có công việc nào', style: TextStyle(color: Colors.grey[500])),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(10),
      itemCount: tasks.length,
      itemBuilder: (context, index) {
        final task = tasks[index];
        final category = viewModel.getCategoryById(task.categoryId);

        // Convert hex string sang Color object
        Color catColor = Colors.grey;
        if (category != null) {
          catColor = Color(int.parse(category.hexColor.replaceFirst('#', '0xff')));
        }

        return Card(
          margin: const EdgeInsets.only(bottom: 10),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            onTap: () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => TaskDetailScreen(task: task)));
            },
            leading: Checkbox(
              shape: const CircleBorder(),
              value: task.isCompleted,
              onChanged: (val) => viewModel.toggleTaskStatus(task),
            ),
            title: Text(
              task.title,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                decoration: task.isCompleted ? TextDecoration.lineThrough : null,
                color: task.isCompleted ? Colors.grey : Colors.black,
              ),
            ),
            subtitle: Row(
              children: [
                // Chấm màu danh mục
                Container(width: 10, height: 10, decoration: BoxDecoration(color: catColor, shape: BoxShape.circle)),
                const SizedBox(width: 5),
                // Tên danh mục
                Text(category?.name ?? 'Unknown', style: const TextStyle(fontSize: 12)),
                const SizedBox(width: 10),
                // Giờ bắt đầu
                Icon(Icons.access_time, size: 14, color: Colors.grey[600]),
                const SizedBox(width: 4),
                Text(DateFormat('HH:mm dd/MM').format(task.startTime), style: const TextStyle(fontSize: 12)),
              ],
            ),
            trailing: IconButton(
              icon: Icon(
                task.isMarkedStar ? Icons.star : Icons.star_border,
                color: task.isMarkedStar ? Colors.amber : Colors.grey,
              ),
              onPressed: () => viewModel.toggleTaskStar(task),
            ),
          ),
        );
      },
    );
  }
}