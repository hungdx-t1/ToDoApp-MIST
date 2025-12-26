// lib/main.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:todoapp_mist/view_models/theme_view_model.dart';
import 'services/notification_service.dart';
import 'utils/task_search_delegate.dart';
import 'view_models/task_view_model.dart';
import 'views/add_task_screen.dart';
import 'views/task_detail_screen.dart';
import 'views/category_management_screen.dart';
import 'views/settings_screen.dart';
import 'models/task_model.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await NotificationService().init(); // khởi tạo notification

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => TaskViewModel()),
        ChangeNotifierProvider(create: (_) => ThemeViewModel()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    // return MaterialApp(
    //   title: 'Pro Todo',
    //   theme: ThemeData(primarySwatch: Colors.blue, scaffoldBackgroundColor: Colors.grey[100]),
    //   home: const HomeScreen(),
    // );

    return Consumer<ThemeViewModel>( // consumer có tác dụng lắng nghe thay đổi theme
      builder: (context, themeViewModel, child) {
        return MaterialApp(
          title: 'Pro Todo',
          debugShowCheckedModeBanner: false,

          // theme configuration
          themeMode: themeViewModel.isDarkMode ? ThemeMode.dark : ThemeMode.light, // hiện tại

          // bộ màu cho gd sáng
          theme: ThemeData(
            brightness: Brightness.light,
            primarySwatch: Colors.blue,
            scaffoldBackgroundColor: Colors.grey[100],
            appBarTheme: const AppBarTheme(
              backgroundColor: Colors.white,
              foregroundColor: Colors.black, // Màu chữ/icon AppBar
              elevation: 0,
            ),
            cardColor: Colors.white,
            // TODO thêm các style khác (có thể)
          ),

          // bộ màu cho gd tối
          darkTheme: ThemeData(
            brightness: Brightness.dark,
            primarySwatch: Colors.blue,
            scaffoldBackgroundColor: const Color(0xFF121212), // nền tối
            appBarTheme: const AppBarTheme(
              backgroundColor: Color(0xFF1E1E1E), // appbar tối hơn nền chút
              foregroundColor: Colors.white,
              elevation: 0,
            ),
            cardColor: const Color(0xFF1E1E1E), // thẻ card màu tối
            // Màu chữ tự động chuyển sang trắng
          ),

          home: const HomeScreen(),
        );
      },
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
         // title: const Text('Công việc của tôi', style: TextStyle(color: Colors.black)),
          title: const Text('Công việc của tôi'),
          backgroundColor: Colors.white,
          elevation: 0,

          actions: [
            // 1. Nút Tìm kiếm
            IconButton(
              icon: const Icon(Icons.search, color: Colors.black),
              tooltip: "Tìm kiếm",
              onPressed: () {
                // Gọi giao diện tìm kiếm chuẩn của Flutter
                showSearch(
                    context: context,
                    delegate: TaskSearchDelegate(context.read<TaskViewModel>())
                );
              },
            ),

            // 2. Nút Sắp xếp
            IconButton(
              icon: const Icon(Icons.sort, color: Colors.black),
              tooltip: "Sắp xếp",
              onPressed: () {
                _showSortOptions(context);
              },
            ),

            // 3. Nút Menu 3 chấm (Popup Menu)
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert, color: Colors.black),
              onSelected: (value) {
                if (value == 'category') {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const CategoryManagementScreen()),
                  );
                } else if (value == 'settings') {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const SettingsScreen()),
                  );
                }
              },
              itemBuilder: (BuildContext context) {
                return [
                  // Mục 1: Quản lý danh mục
                  const PopupMenuItem<String>(
                    value: 'category',
                    child: Row(
                      children: [
                        Icon(Icons.category_outlined, color: Colors.black54),
                        SizedBox(width: 10),
                        Text('Quản lý danh mục'),
                      ],
                    ),
                  ),
                  // Mục 2: Cài đặt
                  const PopupMenuItem<String>(
                    value: 'settings',
                    child: Row(
                      children: [
                        Icon(Icons.settings_outlined, color: Colors.black54),
                        SizedBox(width: 10),
                        Text('Cài đặt'),
                      ],
                    ),
                  ),
                ];
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

  // Hàm hiển thị tùy chọn sắp xếp (BottomSheet)
  void _showSortOptions(BuildContext context) {
    // Lấy viewModel nhưng không listen (listen=false) vì chỉ gọi hàm
    final viewModel = Provider.of<TaskViewModel>(context, listen: false);
    final currentOption = viewModel.currentSortOption;

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text("Sắp xếp theo", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),

              ListTile(
                leading: const Icon(Icons.access_time),
                title: const Text("Thời gian bắt đầu (Mới nhất)"),
                // Hiển thị dấu tick nếu đang chọn mục này
                trailing: currentOption == SortOption.startTimeNewest ? const Icon(Icons.check, color: Colors.blue) : null,
                onTap: () {
                  viewModel.setSortOption(SortOption.startTimeNewest);
                  Navigator.pop(context); // Đóng BottomSheet
                },
              ),

              ListTile(
                leading: const Icon(Icons.flag_outlined),
                title: const Text("Hạn chót (Gấp nhất)"),
                trailing: currentOption == SortOption.deadlineUrgent ? const Icon(Icons.check, color: Colors.blue) : null,
                onTap: () {
                  viewModel.setSortOption(SortOption.deadlineUrgent);
                  Navigator.pop(context);
                },
              ),

              ListTile(
                leading: const Icon(Icons.sort_by_alpha),
                title: const Text("Tên công việc (A-Z)"),
                trailing: currentOption == SortOption.titleAZ ? const Icon(Icons.check, color: Colors.blue) : null,
                onTap: () {
                  viewModel.setSortOption(SortOption.titleAZ);
                  Navigator.pop(context);
                },
              ),

            ],
          ),
        );
      },
    );
  }
}