// lib/main.dart

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/date_symbol_data_local.dart'; // SỬA LỖI: Thêm import này
import 'package:provider/provider.dart';

import 'screens/main/print_screen.dart';
import 'screens/setup/setup_screen.dart';
import 'screens/splash_screen.dart';
import 'services/config_service.dart';
import 'services/database_service.dart';
import 'utils/constants.dart';

void main() async {
  // Đảm bảo các binding được khởi tạo trước khi chạy tác vụ async
  WidgetsFlutterBinding.ensureInitialized();

  // SỬA LỖI: Khởi tạo định dạng ngôn ngữ cho gói intl (sửa lỗi LocaleDataException)
  await initializeDateFormatting('vi_VN', null);

  // Cài đặt giao diện hệ thống (xoay ngang, ẩn thanh trạng thái)
  await _setupSystemUI();

  // Khởi tạo và tải trước các service quan trọng
  final configService = ConfigService();
  await configService.loadConfig(); // Tải cấu hình đã lưu

  final databaseService = DatabaseService();
  await databaseService.database; // Đảm bảo database đã được mở

  debugPrint('Services initialized successfully');

  runApp(
    // Cung cấp các service đã được khởi tạo cho toàn bộ ứng dụng
    MultiProvider(
      providers: [
        // SỬA LỖI: Dùng ChangeNotifierProvider.value để cung cấp service đã tồn tại
        ChangeNotifierProvider.value(value: configService),
        // SỬA LỖI: Dùng Provider.value để cung cấp service đã tồn tại
        Provider.value(value: databaseService),
      ],
      child: const QueuePrintApp(),
    ),
  );
}

/// Cấu hình giao diện người dùng của hệ thống.
Future<void> _setupSystemUI() async {
  // Buộc xoay ngang cho máy tính bảng
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);

  // Giữ màn hình luôn sáng và ở chế độ toàn màn hình
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
}

class QueuePrintApp extends StatelessWidget {
  const QueuePrintApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ScreenUtilInit(
      designSize: const Size(AppConstants.tabletWidth, AppConstants.tabletHeight),
      minTextAdapt: true,
      splitScreenMode: true,
      builder: (context, child) {
        // MaterialApp được đặt bên trong MultiProvider ở hàm main
        // nên nó và các con của nó có thể truy cập các service.
        return MaterialApp(
          title: AppConstants.appName,
          debugShowCheckedModeBanner: false,

          // Cấu hình Theme
          theme: ThemeData(
            primarySwatch: Colors.blue,
            primaryColor: Color(AppConstants.colors['primary']!),
            scaffoldBackgroundColor: Colors.grey[50],
            colorScheme: ColorScheme.fromSeed(
              seedColor: Color(AppConstants.colors['primary']!),
              brightness: Brightness.light,
            ),
            fontFamily: 'Roboto',
            textTheme: const TextTheme(
              displayLarge: TextStyle(fontWeight: FontWeight.bold),
              displayMedium: TextStyle(fontWeight: FontWeight.bold),
              displaySmall: TextStyle(fontWeight: FontWeight.bold),
              headlineLarge: TextStyle(fontWeight: FontWeight.bold),
              headlineMedium: TextStyle(fontWeight: FontWeight.bold),
              headlineSmall: TextStyle(fontWeight: FontWeight.w600),
            ),
            appBarTheme: AppBarTheme(
              elevation: 0,
              centerTitle: true,
              backgroundColor: Color(AppConstants.colors['primary']!),
              foregroundColor: Colors.white,
              systemOverlayStyle: SystemUiOverlayStyle.light,
              titleTextStyle: TextStyle(
                fontSize: 20.sp,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            cardTheme: CardTheme(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              margin: EdgeInsets.all(8.w),
            ),
            elevatedButtonTheme: ElevatedButtonThemeData(
              style: ElevatedButton.styleFrom(
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 12.h),
                textStyle: TextStyle(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            inputDecorationTheme: InputDecorationTheme(
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: Colors.grey[300]!),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: Color(AppConstants.colors['primary']!)),
              ),
              errorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: Color(AppConstants.colors['error']!)),
              ),
              contentPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
            ),
          ),

          // Điều hướng
          home: const SplashScreen(), // Bắt đầu với SplashScreen để kiểm tra trạng thái
          routes: {
            '/splash': (context) => const SplashScreen(),
            '/setup': (context) => const SetupScreen(),
            '/main': (context) => const PrintScreen(),
          },

          // Xử lý lỗi giao diện toàn cục
          builder: (context, widget) {
            ErrorWidget.builder = (FlutterErrorDetails errorDetails) {
              return _buildErrorWidget(context, errorDetails);
            };
            return widget ?? const SizedBox.shrink();
          },
        );
      },
    );
  }

  /// Widget hiển thị khi có lỗi nghiêm trọng xảy ra trong lúc build UI.
  Widget _buildErrorWidget(BuildContext context, FlutterErrorDetails errorDetails) {
    return Material(
      child: Container(
        color: Colors.red[50],
        padding: EdgeInsets.all(16.w),
        child: Center(
          child: SingleChildScrollView(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.error_outline,
                  size: 64.w,
                  color: Colors.red,
                ),
                SizedBox(height: 16.h),
                Text(
                  'Đã có lỗi xảy ra',
                  style: TextStyle(
                    fontSize: 20.sp,
                    fontWeight: FontWeight.bold,
                    color: Colors.red[800],
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 8.h),
                Text(
                  'Vui lòng khởi động lại ứng dụng.',
                  style: TextStyle(
                    fontSize: 16.sp,
                    color: Colors.red[600],
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 24.h),
                if (kDebugMode)
                  Container(
                    padding: EdgeInsets.all(12.w),
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      errorDetails.toString(),
                      style: TextStyle(
                        fontSize: 12.sp,
                        fontFamily: 'monospace',
                        color: Colors.black87,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
