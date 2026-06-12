import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'core/services/supabase_service.dart';
import 'core/services/fcm_service.dart';
import 'core/theme/app_theme.dart';
import 'core/routes/app_routes.dart';
import 'providers/auth_provider.dart';
import 'providers/notification_provider.dart';
import 'providers/listing_provider.dart';
import 'providers/home_provider.dart';
import 'providers/favorite_provider.dart';
import 'providers/report_provider.dart';
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

  // Initialize Firebase (required for FCM push notifications)
  try {
    await Firebase.initializeApp();
    await FcmService.initialize();
  } catch (_) {
    // FCM/Firebase not configured — in-app notifications via Supabase still work
  }

  runApp(const SwaplyApp());
}

class SwaplyApp extends StatelessWidget {
  const SwaplyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        // Auth is created first — others may depend on it
        ChangeNotifierProvider<AuthProvider>(
          create: (_) => AuthProvider(),
        ),
        ChangeNotifierProxyProvider<AuthProvider, NotificationProvider>(
          create: (_) => NotificationProvider(),
          update: (_, auth, notif) {
            if (auth.isAuthenticated) notif?.init();
            return notif ?? NotificationProvider();
          },
        ),
        ChangeNotifierProxyProvider<AuthProvider, ListingProvider>(
          create: (_) => ListingProvider(),
          update: (_, auth, listing) {
            if (auth.isAuthenticated) {
              listing?.subscribeToListings();
              listing?.fetchListings();
            }
            return listing ?? ListingProvider();
          },
        ),
        ChangeNotifierProxyProvider<AuthProvider, HomeProvider>(
          create: (_) => HomeProvider(),
          update: (_, auth, home) {
            if (auth.isAuthenticated) home?.fetchHomeData();
            return home ?? HomeProvider();
          },
        ),
        ChangeNotifierProxyProvider<AuthProvider, FavoriteProvider>(
          create: (_) => FavoriteProvider(),
          update: (_, auth, fav) {
            if (auth.isAuthenticated && auth.currentUser != null) {
              fav?.fetchFavorites(auth.currentUser!.id);
            }
            return fav ?? FavoriteProvider();
          },
        ),
        ChangeNotifierProvider<ReportProvider>(
          create: (_) => ReportProvider(),
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
            title: 'Swaply',
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
