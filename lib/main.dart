import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'core/services/supabase_service.dart';
import 'core/theme/app_theme.dart';
import 'core/routes/app_routes.dart';
import 'providers/auth_provider.dart';
import 'providers/post_provider.dart';
import 'providers/profile_provider.dart';
import 'providers/chat_provider.dart';
import 'providers/search_provider.dart';
import 'providers/category_provider.dart';
import 'providers/announcement_provider.dart';
import 'providers/app_settings_provider.dart';
import 'admin/providers/admin_stats_provider.dart';
import 'admin/providers/admin_user_provider.dart';
import 'admin/providers/admin_book_provider.dart';
import 'admin/providers/admin_category_provider.dart';
import 'admin/providers/admin_report_provider.dart';
import 'admin/providers/admin_announcement_provider.dart';
import 'admin/providers/admin_settings_provider.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Allow all orientations for responsive tablet/desktop support
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);

  // Transparent status bar (light theme)
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.dark,
  ));

  // Initialize Supabase
  await SupabaseService.initialize();

  runApp(const BookSwapApp());
}

class BookSwapApp extends StatelessWidget {
  const BookSwapApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        // Auth is created first — others may depend on it
        ChangeNotifierProvider<AuthProvider>(
          create: (_) => AuthProvider(),
        ),
        ChangeNotifierProxyProvider<AuthProvider, PostProvider>(
          create: (_) => PostProvider(),
          update: (_, auth, post) {
            // Refresh posts when user signs in
            if (auth.isAuthenticated) post?.fetchPosts();
            return post ?? PostProvider();
          },
        ),
        ChangeNotifierProxyProvider<AuthProvider, ProfileProvider>(
          create: (_) => ProfileProvider(),
          update: (_, auth, profile) {
            if (auth.isAuthenticated && auth.currentUser != null) {
              profile?.fetchProfile(auth.currentUser!.id);
            }
            return profile ?? ProfileProvider();
          },
        ),
        ChangeNotifierProvider<ChatProvider>(
          create: (_) => ChatProvider(),
        ),
        ChangeNotifierProvider<SearchProvider>(
          create: (_) => SearchProvider(),
        ),
        ChangeNotifierProvider<CategoryProvider>(
          create: (_) => CategoryProvider(),
        ),
        ChangeNotifierProvider<AnnouncementProvider>(
          create: (_) => AnnouncementProvider(),
        ),
        ChangeNotifierProvider<AppSettingsProvider>(
          create: (_) => AppSettingsProvider(),
        ),
        ChangeNotifierProvider<AdminStatsProvider>(
          create: (_) => AdminStatsProvider(),
        ),
        ChangeNotifierProvider<AdminUserProvider>(
          create: (_) => AdminUserProvider(),
        ),
        ChangeNotifierProvider<AdminBookProvider>(
          create: (_) => AdminBookProvider(),
        ),
        ChangeNotifierProvider<AdminCategoryProvider>(
          create: (_) => AdminCategoryProvider(),
        ),
        ChangeNotifierProvider<AdminReportProvider>(
          create: (_) => AdminReportProvider(),
        ),
        ChangeNotifierProvider<AdminAnnouncementProvider>(
          create: (_) => AdminAnnouncementProvider(),
        ),
        ChangeNotifierProvider<AdminSettingsProvider>(
          create: (_) => AdminSettingsProvider(),
        ),
      ],
      child: Stack(
        textDirection: TextDirection.ltr,
        children: [
          Positioned.fill(
            child: Image.asset(
              'assets/images/bg.jpg',
              fit: BoxFit.cover,
            ),
          ),
          MaterialApp(
            title: 'BookSwap',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.light,
            darkTheme: AppTheme.dark,
            themeMode: ThemeMode.dark,
            initialRoute: AppRoutes.splash,
            onGenerateRoute: AppRoutes.onGenerateRoute,
          ),
        ],
      ),
    );
  }
}
