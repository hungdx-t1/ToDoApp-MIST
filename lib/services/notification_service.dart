// lib/services/notification_service.dart
import 'dart:io';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;

class NotificationService {
  static final NotificationService _instance = NotificationService._internal(); // singleton
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
  FlutterLocalNotificationsPlugin();

  // init method
  Future<void> init() async {
    tz.initializeTimeZones(); // Cấu hình múi giờ
    try {
      final TimezoneInfo localTimezone = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(localTimezone.identifier));
      print("Đã cập nhật múi giờ thành công: ${localTimezone.identifier}");
    } catch (e) {
      print("Lỗi lấy múi giờ: $e. Dùng mặc định Asia/Ho_Chi_Minh");
      tz.setLocalLocation(tz.getLocation('Asia/Ho_Chi_Minh'));
    }

    // Icon mặc định cho Android (cần file app_icon.png hoặc ic_launcher trong folder drawable)
    // '@mipmap/ic_launcher' là icon mặc định của Flutter app
    const AndroidInitializationSettings initializationSettingsAndroid =
    AndroidInitializationSettings('@mipmap/ic_launcher');

    // Cấu hình cho iOS (đơn giản)
    const DarwinInitializationSettings initializationSettingsDarwin = DarwinInitializationSettings();

    const InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsDarwin,
    );

    await flutterLocalNotificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        // Xử lý khi người dùng bấm vào thông báo (ví dụ mở màn hình chi tiết)
        print("User clicked notification: ${response.payload}");
      },
    );
  }

  // Kiểm tra xem quyền đã được cấp hay chưa
  Future<bool> checkPermissionStatus() async {
    if (Platform.isAndroid) {
      final AndroidFlutterLocalNotificationsPlugin? androidImplementation =
      flutterLocalNotificationsPlugin.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();

      // Hàm này trả về true nếu đã được cấp quyền, false nếu chưa
      return await androidImplementation?.areNotificationsEnabled() ?? false;
    }
    // Nếu là iOS (tạm thời trả về false hoặc logic riêng nếu cần)
    return false;
  }

  // yêu cầu quyền (android 13+)
  Future<void> requestPermissions() async {
    final AndroidFlutterLocalNotificationsPlugin? androidImplementation =
    flutterLocalNotificationsPlugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();

    await androidImplementation?.requestNotificationsPermission();
  }

  // lên lịch thông báo
  Future<void> scheduleNotification({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledTime,
  }) async {
    final now = DateTime.now();

    // nếu thời gian đã qua quá lâu (hơn 2 phút trước) thì bỏ qua
    if (scheduledTime.isBefore(now.subtract(const Duration(minutes: 2)))) {
      return;
    }

    // xử lý delay: nếu thời gian hẹn nhỏ hơn hoặc bằng hiện tại (do trễ vài giây lúc bấm nút Lưu)
    // -> Cộng thêm 5 giây để thông báo nổ ngay lập tức -> fix thông báo không hiện.
    DateTime finalTime = scheduledTime;
    if (scheduledTime.isBefore(now.add(const Duration(seconds: 1)))) {
      finalTime = now.add(const Duration(seconds: 5));
    }

    await flutterLocalNotificationsPlugin.zonedSchedule(
        id,
        title,
        body,
        tz.TZDateTime.from(finalTime, tz.local),
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'todo_channel_id',
            'Nhắc nhở công việc',
            channelDescription: 'Thông báo nhắc nhở khi đến giờ làm việc',
            importance: Importance.max,
            priority: Priority.high,
          ),
          iOS: DarwinNotificationDetails(),
        ),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle
    );

    print("Đã đặt lịch thông báo lúc: $finalTime"); // In log để kiểm tra
  }

  // hủy thông báo (Khi xóa task hoặc hoàn thành sớm)
  Future<void> cancelNotification(int id) async {
    await flutterLocalNotificationsPlugin.cancel(id);
  }

  // hủy tất cả (dùng khi restore backup)
  Future<void> cancelAll() async {
    await flutterLocalNotificationsPlugin.cancelAll();
  }

  // hiển thị thông báo từ Firebase khi app đang mở
  Future<void> showRemoteNotification(RemoteMessage message) async {
    RemoteNotification? notification = message.notification;
    AndroidNotification? android = message.notification?.android;

    // Nếu tin nhắn có chứa nội dung thông báo
    if (notification != null && android != null) {
      await flutterLocalNotificationsPlugin.show(
        notification.hashCode, // ID ngẫu nhiên dựa trên nội dung
        notification.title,
        notification.body,
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'todo_channel_id', // Phải trùng với ID kênh bạn đã tạo
            'Nhắc nhở công việc',
            channelDescription: 'Thông báo từ hệ thống',
            importance: Importance.max,
            priority: Priority.high,
            icon: '@mipmap/ic_launcher', // Icon app
          ),
          iOS: DarwinNotificationDetails(),
        ),
      );
    }
  }
}