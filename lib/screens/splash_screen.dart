// // lib/screens/splash_screen.dart
// import 'package:flutter/material.dart';
// import 'package:flutter_screenutil/flutter_screenutil.dart';
// import 'package:provider/provider.dart';
// import '../services/config_service.dart';
// import '../services/database_service.dart';
// import '../utils/constants.dart';
//
// class SplashScreen extends StatefulWidget {
//   const SplashScreen({Key? key}) : super(key: key);
//
//   @override
//   State<SplashScreen> createState() => _SplashScreenState();
// }
//
// class _SplashScreenState extends State<SplashScreen> with TickerProviderStateMixin {
//   late AnimationController _logoController;
//   late AnimationController _progressController;
//   late Animation<double> _logoAnimation;
//   late Animation<double> _progressAnimation;
//
//   String _statusText = 'Đang khởi tạo...';
//   double _progress = 0.0;
//   bool _hasError = false;
//
//   @override
//   void initState() {
//     super.initState();
//     _setupAnimations();
//     _initializeApp();
//   }
//
//   void _setupAnimations() {
//     // Logo animation
//     _logoController = AnimationController(
//       duration: const Duration(milliseconds: 1500),
//       vsync: this,
//     );
//     _logoAnimation = CurvedAnimation(
//       parent: _logoController,
//       curve: Curves.elasticOut,
//     );
//
//     // Progress animation
//     _progressController = AnimationController(
//       duration: const Duration(milliseconds: 500),
//       vsync: this,
//     );
//     _progressAnimation = CurvedAnimation(
//       parent: _progressController,
//       curve: Curves.easeInOut,
//     );
//
//     _logoController.forward();
//   }
//
//   Future<void> _initializeApp() async {
//     try {
//       // Step 1: Initialize Database
//       await _updateProgress(0.2, 'Khởi tạo cơ sở dữ liệu...');
//       final dbService = context.read<DatabaseService>();
//       await dbService.database;
//       await Future.delayed(const Duration(milliseconds: 500));
//
//       // Step 2: Load Configuration
//       await _updateProgress(0.4, 'Tải cấu hình...');
//       final configService = context.read<ConfigService>();
//       await configService.loadConfig();
//       await Future.delayed(const Duration(milliseconds: 500));
//
//       // Step 3: Validate Configuration
//       await _updateProgress(0.6, 'Kiểm tra cấu hình...');
//       final isConfigured = await configService.isConfigured();
//       await Future.delayed(const Duration(milliseconds: 500));
//
//       // Step 4: Database Maintenance
//       await _updateProgress(0.8, 'Kiểm tra dữ liệu...');
//       await _performMaintenanceIfNeeded(dbService);
//       await Future.delayed(const Duration(milliseconds: 500));
//
//       // Step 5: Complete
//       await _updateProgress(1.0, 'Hoàn tất!');
//       await Future.delayed(const Duration(milliseconds: 800));
//
//       // Navigate to appropriate screen
//       if (mounted) {
//         if (isConfigured) {
//           Navigator.of(context).pushReplacementNamed('/main');
//         } else {
//           Navigator.of(context).pushReplacementNamed('/setup');
//         }
//       }
//
//     } catch (e) {
//       await _handleInitializationError(e);
//     }
//   }
//
//   Future<void> _updateProgress(double progress, String status) async {
//     setState(() {
//       _progress = progress;
//       _statusText = status;
//     });
//
//     _progressController.reset();
//     _progressController.forward();
//
//     await Future.delayed(const Duration(milliseconds: 100));
//   }
//
//   Future<void> _performMaintenanceIfNeeded(DatabaseService dbService) async {
//     try {
//       // Check if daily reset is needed
//       final lastReset = await dbService.getSetting('queue', 'last_reset');
//       final today = DateTime.now().toIso8601String().split('T')[0];
//
//       if (lastReset == null || !lastReset.startsWith(today)) {
//         await _updateProgress(0.85, 'Đang reset hàng đợi hàng ngày...');
//         await dbService.resetDailyQueue();
//       }
//
//       // Perform database maintenance occasionally
//       final dbInfo = await dbService.getDatabaseInfo();
//       if (dbInfo['queue_count'] > 1000) {
//         await _updateProgress(0.9, 'Tối ưu hóa cơ sở dữ liệu...');
//         await dbService.vacuum();
//       }
//     } catch (e) {
//       debugPrint('Maintenance error: $e');
//       // Don't fail the app for maintenance errors
//     }
//   }
//
//   Future<void> _handleInitializationError(dynamic error) async {
//     setState(() {
//       _hasError = true;
//       _statusText = 'Lỗi khởi tạo: ${error.toString()}';
//     });
//
//     // Show error for a few seconds, then try to continue
//     await Future.delayed(const Duration(seconds: 3));
//
//     if (mounted) {
//       // Try to navigate to setup screen as fallback
//       Navigator.of(context).pushReplacementNamed('/setup');
//     }
//   }
//
//   @override
//   void dispose() {
//     _logoController.dispose();
//     _progressController.dispose();
//     super.dispose();
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: Color(AppConstants.colors['primary']!),
//       body: Container(
//         decoration: BoxDecoration(
//           gradient: LinearGradient(
//             begin: Alignment.topLeft,
//             end: Alignment.bottomRight,
//             colors: [
//               Color(AppConstants.colors['primary']!),
//               Color(AppConstants.colors['primaryDark']!),
//             ],
//           ),
//         ),
//         child: SafeArea(
//           child: Column(
//             children: [
//               // Top spacer
//               SizedBox(height: 60.h),
//
//               // App info
//               Text(
//                 AppConstants.appName.toUpperCase(),
//                 style: TextStyle(
//                   fontSize: 16.sp,
//                   fontWeight: FontWeight.w300,
//                   color: Colors.white70,
//                   letterSpacing: 4,
//                 ),
//               ),
//
//               // Main content
//               Expanded(
//                 child: Column(
//                   mainAxisAlignment: MainAxisAlignment.center,
//                   children: [
//                     // App logo with animation
//                     ScaleTransition(
//                       scale: _logoAnimation,
//                       child: Container(
//                         width: 120.w,
//                         height: 120.h,
//                         decoration: BoxDecoration(
//                           color: Colors.white,
//                           borderRadius: BorderRadius.circular(20),
//                           boxShadow: [
//                             BoxShadow(
//                               color: Colors.black.withOpacity(0.3),
//                               blurRadius: 20,
//                               offset: const Offset(0, 10),
//                             ),
//                           ],
//                         ),
//                         child: Icon(
//                           Icons.print,
//                           size: 60.w,
//                           color: Color(AppConstants.colors['primary']!),
//                         ),
//                       ),
//                     ),
//
//                     SizedBox(height: 40.h),
//
//                     // App title
//                     Text(
//                       'PRINT STATION',
//                       style: TextStyle(
//                         fontSize: 28.sp,
//                         fontWeight: FontWeight.bold,
//                         color: Colors.white,
//                         letterSpacing: 2,
//                       ),
//                     ),
//
//                     SizedBox(height: 8.h),
//
//                     // App subtitle
//                     Text(
//                       'Máy In Phiếu Số Thứ Tự',
//                       style: TextStyle(
//                         fontSize: 16.sp,
//                         color: Colors.white70,
//                         fontWeight: FontWeight.w300,
//                       ),
//                     ),
//                   ],
//                 ),
//               ),
//
//               // Bottom section with progress
//               Container(
//                 padding: EdgeInsets.all(40.w),
//                 child: Column(
//                   children: [
//                     // Progress bar
//                     Container(
//                       width: double.infinity,
//                       height: 4.h,
//                       decoration: BoxDecoration(
//                         color: Colors.white.withOpacity(0.2),
//                         borderRadius: BorderRadius.circular(2),
//                       ),
//                       child: AnimatedBuilder(
//                         animation: _progressAnimation,
//                         builder: (context, child) {
//                           return FractionallySizedBox(
//                             alignment: Alignment.centerLeft,
//                             widthFactor: _progress * _progressAnimation.value,
//                             child: Container(
//                               decoration: BoxDecoration(
//                                 color: _hasError
//                                     ? Color(AppConstants.colors['error']!)
//                                     : Colors.white,
//                                 borderRadius: BorderRadius.circular(2),
//                                 boxShadow: [
//                                   BoxShadow(
//                                     color: Colors.white.withOpacity(0.5),
//                                     blurRadius: 4,
//                                   ),
//                                 ],
//                               ),
//                             ),
//                           );
//                         },
//                       ),
//                     ),
//
//                     SizedBox(height: 20.h),
//
//                     // Status text with loading indicator
//                     Row(
//                       mainAxisAlignment: MainAxisAlignment.center,
//                       children: [
//                         if (!_hasError && _progress < 1.0) ...[
//                           SizedBox(
//                             width: 16.w,
//                             height: 16.h,
//                             child: CircularProgressIndicator(
//                               strokeWidth: 2,
//                               valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
//                             ),
//                           ),
//                           SizedBox(width: 12.w),
//                         ],
//
//                         if (_hasError) ...[
//                           Icon(
//                             Icons.error_outline,
//                             color: Color(AppConstants.colors['error']!),
//                             size: 16.w,
//                           ),
//                           SizedBox(width: 8.w),
//                         ],
//
//                         Flexible(
//                           child: Text(
//                             _statusText,
//                             style: TextStyle(
//                               color: _hasError
//                                   ? Color(AppConstants.colors['error']!)
//                                   : Colors.white70,
//                               fontSize: 14.sp,
//                               fontWeight: FontWeight.w400,
//                             ),
//                             textAlign: TextAlign.center,
//                           ),
//                         ),
//                       ],
//                     ),
//
//                     SizedBox(height: 30.h),
//
//                     // Version info
//                     Text(
//                       'Version ${AppConstants.appVersion} - ${AppConstants.deviceType}',
//                       style: TextStyle(
//                         color: Colors.white54,
//                         fontSize: 11.sp,
//                         fontWeight: FontWeight.w300,
//                       ),
//                     ),
//
//                     // Error retry button
//                     if (_hasError) ...[
//                       SizedBox(height: 20.h),
//                       ElevatedButton(
//                         onPressed: () {
//                           setState(() {
//                             _hasError = false;
//                             _progress = 0.0;
//                             _statusText = 'Đang thử lại...';
//                           });
//                           _initializeApp();
//                         },
//                         style: ElevatedButton.styleFrom(
//                           backgroundColor: Colors.white,
//                           foregroundColor: Color(AppConstants.colors['primary']!),
//                           padding: EdgeInsets.symmetric(horizontal: 32.w, vertical: 12.h),
//                         ),
//                         child: Text(
//                           'THỬ LẠI',
//                           style: TextStyle(
//                             fontWeight: FontWeight.bold,
//                             fontSize: 14.sp,
//                           ),
//                         ),
//                       ),
//                     ],
//                   ],
//                 ),
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
// }
//
// // Helper widget for animated progress indicator
// class AnimatedProgressIndicator extends StatelessWidget {
//   final double progress;
//   final Color color;
//   final Color backgroundColor;
//   final double height;
//
//   const AnimatedProgressIndicator({
//     Key? key,
//     required this.progress,
//     this.color = Colors.white,
//     this.backgroundColor = Colors.transparent,
//     this.height = 4.0,
//   }) : super(key: key);
//
//   @override
//   Widget build(BuildContext context) {
//     return Container(
//       width: double.infinity,
//       height: height,
//       decoration: BoxDecoration(
//         color: backgroundColor.withOpacity(0.2),
//         borderRadius: BorderRadius.circular(height / 2),
//       ),
//       child: TweenAnimationBuilder<double>(
//         duration: const Duration(milliseconds: 500),
//         curve: Curves.easeInOut,
//         tween: Tween(begin: 0.0, end: progress),
//         builder: (context, value, child) {
//           return FractionallySizedBox(
//             alignment: Alignment.centerLeft,
//             widthFactor: value,
//             child: Container(
//               decoration: BoxDecoration(
//                 color: color,
//                 borderRadius: BorderRadius.circular(height / 2),
//                 boxShadow: [
//                   BoxShadow(
//                     color: color.withOpacity(0.5),
//                     blurRadius: 4,
//                   ),
//                 ],
//               ),
//             ),
//           );
//         },
//       ),
//     );
//   }
// }
// lib/screens/splash_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import '../services/config_service.dart';
import '../services/database_service.dart';
import '../utils/constants.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({Key? key}) : super(key: key);

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with TickerProviderStateMixin {
  late AnimationController _logoController;
  late AnimationController _progressController;
  late Animation<double> _logoAnimation;
  late Animation<double> _progressAnimation;

  String _statusText = 'Đang khởi tạo...';
  double _progress = 0.0;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _initializeApp();
  }

  void _setupAnimations() {
    // Logo animation
    _logoController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    _logoAnimation = CurvedAnimation(
      parent: _logoController,
      curve: Curves.elasticOut,
    );

    // Progress animation
    _progressController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _progressAnimation = CurvedAnimation(
      parent: _progressController,
      curve: Curves.easeInOut,
    );

    _logoController.forward();
  }

  Future<void> _initializeApp() async {
    try {
      // Step 1: Initialize Database
      await _updateProgress(0.2, 'Khởi tạo cơ sở dữ liệu...');
      final dbService = context.read<DatabaseService>();
      await dbService.database;
      await Future.delayed(const Duration(milliseconds: 500));

      // Step 2: Load Configuration
      await _updateProgress(0.4, 'Tải cấu hình...');
      final configService = context.read<ConfigService>();
      await configService.loadConfig();
      await Future.delayed(const Duration(milliseconds: 500));

      // Step 3: Validate Configuration
      await _updateProgress(0.6, 'Kiểm tra cấu hình...');
      final isConfigured = await configService.isConfigured();
      await Future.delayed(const Duration(milliseconds: 500));

      // Step 4: Database Maintenance
      await _updateProgress(0.8, 'Kiểm tra dữ liệu...');
      await _performMaintenanceIfNeeded(dbService);
      await Future.delayed(const Duration(milliseconds: 500));

      // Step 5: Complete
      await _updateProgress(1.0, 'Hoàn tất!');
      await Future.delayed(const Duration(milliseconds: 800));

      // Navigate to appropriate screen
      if (mounted) {
        if (isConfigured) {
          Navigator.of(context).pushReplacementNamed('/main');
        } else {
          Navigator.of(context).pushReplacementNamed('/setup');
        }
      }

    } catch (e) {
      await _handleInitializationError(e);
    }
  }

  Future<void> _updateProgress(double progress, String status) async {
    setState(() {
      _progress = progress;
      _statusText = status;
    });

    _progressController.reset();
    _progressController.forward();

    await Future.delayed(const Duration(milliseconds: 100));
  }

  Future<void> _performMaintenanceIfNeeded(DatabaseService dbService) async {
    try {
      // Check if daily reset is needed
      final lastReset = await dbService.getSetting('queue', 'last_reset');
      final today = DateTime.now().toIso8601String().split('T')[0];

      if (lastReset == null || !lastReset.startsWith(today)) {
        await _updateProgress(0.85, 'Đang reset hàng đợi hàng ngày...');
        await dbService.resetDailyQueue();
      }

      // Perform database maintenance occasionally
      final dbInfo = await dbService.getDatabaseInfo();
      if (dbInfo['queue_count'] > 1000) {
        await _updateProgress(0.9, 'Tối ưu hóa cơ sở dữ liệu...');
        await dbService.vacuum();
      }
    } catch (e) {
      debugPrint('Maintenance error: $e');
      // Don't fail the app for maintenance errors
    }
  }

  Future<void> _handleInitializationError(dynamic error) async {
    setState(() {
      _hasError = true;
      _statusText = 'Lỗi khởi tạo: ${error.toString()}';
    });

    // Show error for a few seconds, then try to continue
    await Future.delayed(const Duration(seconds: 3));

    if (mounted) {
      // Try to navigate to setup screen as fallback
      Navigator.of(context).pushReplacementNamed('/setup');
    }
  }

  @override
  void dispose() {
    _logoController.dispose();
    _progressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(AppConstants.colors['primary']!),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(AppConstants.colors['primary']!),
              Color(AppConstants.colors['primary']!).withOpacity(0.8),
            ],
          ),
        ),
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              return SingleChildScrollView(
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    minHeight: constraints.maxHeight,
                  ),
                  child: Column(
                    children: [
                      // Top spacer - responsive
                      SizedBox(height: constraints.maxHeight * 0.1),

                      // App info
                      Text(
                        AppConstants.appName.toUpperCase(),
                        style: TextStyle(
                          fontSize: 16.sp,
                          fontWeight: FontWeight.w300,
                          color: Colors.white70,
                          letterSpacing: 4,
                        ),
                      ),

                      // Main content
                      SizedBox(
                        height: constraints.maxHeight * 0.6,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            // App logo with animation
                            ScaleTransition(
                              scale: _logoAnimation,
                              child: Container(
                                width: 120.w,
                                height: 120.h,
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(20),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.3),
                                      blurRadius: 20,
                                      offset: const Offset(0, 10),
                                    ),
                                  ],
                                ),
                                child: Icon(
                                  Icons.print,
                                  size: 60.w,
                                  color: Color(AppConstants.colors['primary']!),
                                ),
                              ),
                            ),

                            SizedBox(height: 40.h),

                            // App title
                            Text(
                              'PRINT STATION',
                              style: TextStyle(
                                fontSize: 28.sp,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                                letterSpacing: 2,
                              ),
                            ),

                            SizedBox(height: 8.h),

                            // App subtitle
                            Text(
                              'Máy In Phiếu Số Thứ Tự',
                              style: TextStyle(
                                fontSize: 16.sp,
                                color: Colors.white70,
                                fontWeight: FontWeight.w300,
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Bottom section with progress
                      SizedBox(
                        height: constraints.maxHeight * 0.25,
                        child: Container(
                          padding: EdgeInsets.symmetric(horizontal: 40.w),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              // Progress bar
                              Container(
                                width: double.infinity,
                                height: 4.h,
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(2),
                                ),
                                child: AnimatedBuilder(
                                  animation: _progressAnimation,
                                  builder: (context, child) {
                                    return FractionallySizedBox(
                                      alignment: Alignment.centerLeft,
                                      widthFactor: _progress * _progressAnimation.value,
                                      child: Container(
                                        decoration: BoxDecoration(
                                          color: _hasError
                                              ? Colors.red
                                              : Colors.white,
                                          borderRadius: BorderRadius.circular(2),
                                          boxShadow: [
                                            BoxShadow(
                                              color: Colors.white.withOpacity(0.5),
                                              blurRadius: 4,
                                            ),
                                          ],
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ),

                              SizedBox(height: 20.h),

                              // Status text with loading indicator
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  if (!_hasError && _progress < 1.0) ...[
                                    SizedBox(
                                      width: 16.w,
                                      height: 16.h,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                                      ),
                                    ),
                                    SizedBox(width: 12.w),
                                  ],

                                  if (_hasError) ...[
                                    Icon(
                                      Icons.error_outline,
                                      color: Colors.red,
                                      size: 16.w,
                                    ),
                                    SizedBox(width: 8.w),
                                  ],

                                  Flexible(
                                    child: Text(
                                      _statusText,
                                      style: TextStyle(
                                        color: _hasError
                                            ? Colors.red
                                            : Colors.white70,
                                        fontSize: 14.sp,
                                        fontWeight: FontWeight.w400,
                                      ),
                                      textAlign: TextAlign.center,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),

                              SizedBox(height: 20.h),

                              // Version info
                              Text(
                                'Version ${AppConstants.appVersion} - ${AppConstants.deviceType}',
                                style: TextStyle(
                                  color: Colors.white54,
                                  fontSize: 11.sp,
                                  fontWeight: FontWeight.w300,
                                ),
                              ),

                              // Error retry button
                              if (_hasError) ...[
                                SizedBox(height: 20.h),
                                ElevatedButton(
                                  onPressed: () {
                                    setState(() {
                                      _hasError = false;
                                      _progress = 0.0;
                                      _statusText = 'Đang thử lại...';
                                    });
                                    _initializeApp();
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.white,
                                    foregroundColor: Color(AppConstants.colors['primary']!),
                                    padding: EdgeInsets.symmetric(horizontal: 32.w, vertical: 12.h),
                                  ),
                                  child: Text(
                                    'THỬ LẠI',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14.sp,
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

// Helper widget for animated progress indicator
class AnimatedProgressIndicator extends StatelessWidget {
  final double progress;
  final Color color;
  final Color backgroundColor;
  final double height;

  const AnimatedProgressIndicator({
    Key? key,
    required this.progress,
    this.color = Colors.white,
    this.backgroundColor = Colors.transparent,
    this.height = 4.0,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: height,
      decoration: BoxDecoration(
        color: backgroundColor.withOpacity(0.2),
        borderRadius: BorderRadius.circular(height / 2),
      ),
      child: TweenAnimationBuilder<double>(
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
        tween: Tween(begin: 0.0, end: progress),
        builder: (context, value, child) {
          return FractionallySizedBox(
            alignment: Alignment.centerLeft,
            widthFactor: value,
            child: Container(
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(height / 2),
                boxShadow: [
                  BoxShadow(
                    color: color.withOpacity(0.5),
                    blurRadius: 4,
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}