// lib/main.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';

import 'services/config_service.dart';
import 'services/database_service.dart';
import 'screens/splash_screen.dart';
import 'screens/setup/setup_screen.dart';
import 'screens/main/print_screen.dart';
import 'utils/constants.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Set system UI preferences
  await _setupSystemUI();

  // Initialize services
  await _initializeServices();

  runApp(const QueuePrintApp());
}

Future<void> _setupSystemUI() async {
  // Force landscape orientation for tablets
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);

  // Keep screen awake
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);

  // Set system UI overlay style
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
    systemNavigationBarColor: Colors.transparent,
    systemNavigationBarIconBrightness: Brightness.light,
  ));
}

Future<void> _initializeServices() async {
  // Pre-initialize critical services
  try {
    // Initialize database
    final dbService = DatabaseService();
    await dbService.database;

    // Pre-load configuration
    final configService = ConfigService();
    await configService.loadConfig();

    debugPrint('Services initialized successfully');
  } catch (e) {
    debugPrint('Error initializing services: $e');
  }
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
        return MultiProvider(
          providers: [
            // Core services
            ChangeNotifierProvider(create: (_) => ConfigService()),
            Provider(create: (_) => DatabaseService()),

            // Additional providers can be added here
            // ChangeNotifierProvider(create: (_) => MqttService()),
            // ChangeNotifierProvider(create: (_) => PrinterService()),
          ],
          child: MaterialApp(
            title: AppConstants.appName,
            debugShowCheckedModeBanner: false,

            // Theme configuration
            theme: ThemeData(
              primarySwatch: Colors.blue,
              primaryColor: Color(AppConstants.colors['primary']!),
              colorScheme: ColorScheme.fromSeed(
                seedColor: Color(AppConstants.colors['primary']!),
                brightness: Brightness.light,
              ),

              // Typography
              fontFamily: 'Roboto',
              textTheme: const TextTheme(
                displayLarge: TextStyle(fontWeight: FontWeight.bold),
                displayMedium: TextStyle(fontWeight: FontWeight.bold),
                displaySmall: TextStyle(fontWeight: FontWeight.bold),
                headlineLarge: TextStyle(fontWeight: FontWeight.bold),
                headlineMedium: TextStyle(fontWeight: FontWeight.bold),
                headlineSmall: TextStyle(fontWeight: FontWeight.w600),
              ),

              // App bar theme
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

              // Card theme
              cardTheme: CardTheme(
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                margin: EdgeInsets.all(8.w),
              ),

              // Elevated button theme
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

              // Input decoration theme
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

            // Navigation
            home: const SplashScreen(),
            routes: {
              '/splash': (context) => const SplashScreen(),
              '/setup': (context) => const SetupScreen(),
              '/main': (context) => const PrintScreen(),
            },

            // Route generation for dynamic routes
            onGenerateRoute: (settings) {
              switch (settings.name) {
                case '/setup':
                  return MaterialPageRoute(
                    builder: (context) => const SetupScreen(),
                    settings: settings,
                  );
                case '/main':
                  return MaterialPageRoute(
                    builder: (context) => const PrintScreen(),
                    settings: settings,
                  );
                default:
                  return null;
              }
            },

            // Error handling
            builder: (context, child) {
              // Global error boundary
              ErrorWidget.builder = (FlutterErrorDetails errorDetails) {
                return _buildErrorWidget(errorDetails);
              };

              return child ?? const SizedBox.shrink();
            },
          ),
        );
      },
    );
  }

  Widget _buildErrorWidget(FlutterErrorDetails errorDetails) {
    return Material(
      child: Container(
        color: Colors.red[50],
        padding: EdgeInsets.all(16.w),
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
              'Đã xảy ra lỗi',
              style: TextStyle(
                fontSize: 20.sp,
                fontWeight: FontWeight.bold,
                color: Colors.red[800],
              ),
            ),
            SizedBox(height: 8.h),
            Text(
              'Vui lòng khởi động lại ứng dụng',
              style: TextStyle(
                fontSize: 16.sp,
                color: Colors.red[600],
              ),
            ),
            SizedBox(height: 16.h),
            if (kDebugMode) ...[
              Container(
                padding: EdgeInsets.all(12.w),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  errorDetails.toString(),
                  style: TextStyle(
                    fontSize: 12.sp,
                    fontFamily: 'monospace',
                    color: Colors.red[800],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}