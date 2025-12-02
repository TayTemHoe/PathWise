// lib/main.dart
import 'dart:async';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:path_wise/repository/ai_match_repository.dart';
import 'package:path_wise/services/shared_preference_services.dart';
import 'package:path_wise/view/comparison_screen.dart';
import 'package:path_wise/viewModel/ai_match_view_model.dart';
import 'package:path_wise/viewModel/comparison_view_model.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:path_wise/services/app_initialization_service.dart';
import 'package:path_wise/utils/shared_preferences_helper.dart';
import 'package:path_wise/view/auth_screen.dart';
import 'package:path_wise/view/program_list_screen.dart';
import 'package:path_wise/view/university_list_screen.dart';
import 'package:path_wise/viewModel/auth_view_model.dart';
import 'package:path_wise/viewModel/branch_view_model.dart';
import 'package:path_wise/viewModel/university_filter_view_model.dart';
import 'package:path_wise/viewModel/notification_view_model.dart';
import 'package:path_wise/viewModel/program_filter_view_model.dart';
import 'package:path_wise/viewModel/program_list_view_model.dart';
import 'package:path_wise/widgets/app_loading_screen.dart';
import 'package:provider/provider.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:path_wise/viewModel/university_detail_view_model.dart';
import 'package:path_wise/viewModel/university_list_view_model.dart';
import 'package:path_wise/viewModel/program_detail_view_model.dart';

import 'config/supabase_config.dart';
import 'firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    debugPrint('🚀 Starting PathWise initialization...');

    // Initialize timezone
    tz.initializeTimeZones();

    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    debugPrint('Firebase initialized');

    // Initialize Supabase
    await Supabase.initialize(
      url: SupabaseConfig.supabaseUrl,
      anonKey: SupabaseConfig.supabaseAnonKey,
      debug: true, // Set to false in production
    );
    debugPrint('✅ Supabase initialized');

    // Initialize SharedPreferences
    await SharedPreferencesHelper.init();
    debugPrint('✅ SharedPreferences initialized');

    await SharedPreferenceService.instance.initialize();
    debugPrint('✅ AI Match Storage initialized');

    // Initialize three-layer architecture (SQLite + Sync)
    await AppInitializationService.instance.initialize(
      onProgress: (message, progress) {
        debugPrint('📊 Init Progress: $message (${(progress * 100).toStringAsFixed(0)}%)');
      },
    );
    debugPrint('✅ Three-layer architecture initialized');

    // Schedule periodic sync (every 6 hours)
    AppInitializationService.instance.schedulePeriodicSync();
    debugPrint('✅ Periodic sync scheduled');

    final repo = AIMatchRepository.instance;
    final isConnected = await repo.testGeminiConnection();

    if (!isConnected) {
      print('⚠️ Gemini API connection failed');
      print('Please check your API key and model configuration');
    }
  } catch (e) {
    debugPrint('❌ Initialization error: $e');
  }

  runApp(
    MultiProvider(
      providers: [
        // Auth & Notifications (unchanged)
        ChangeNotifierProvider(create: (_) => AuthViewModel()),
        ChangeNotifierProvider(create: (_) => NotificationViewModel()),

        // V2 ViewModels (NEW - Three-layer architecture)
        ChangeNotifierProvider(create: (_) => UniversityListViewModel()),
        ChangeNotifierProvider(create: (_) => UniversityDetailViewModel()),
        ChangeNotifierProvider(create: (_) => BranchViewModel()),
        ChangeNotifierProvider(create: (_) => FilterViewModel()),
        ChangeNotifierProvider(create: (_) => ProgramListViewModel()),
        ChangeNotifierProvider(create: (_) => ProgramFilterViewModel()),
        ChangeNotifierProvider(create: (_) => ProgramDetailViewModel()),
        ChangeNotifierProvider(create: (_) => ComparisonViewModel()),
        ChangeNotifierProvider(create: (_) => AIMatchViewModel()),
      ],
      child: const PathWiseApp(),
    ),
  );
}

class PathWiseApp extends StatefulWidget {
  const PathWiseApp({super.key});

  @override
  State<PathWiseApp> createState() => _PathWiseAppState();
}

class _PathWiseAppState extends State<PathWiseApp> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);

    switch (state) {
      case AppLifecycleState.resumed:
        debugPrint('📱 App resumed');
        _checkAndRefreshData();
        break;

      case AppLifecycleState.paused:
        debugPrint('⏸️ App paused');
        _logSyncStatus();
        break;

      case AppLifecycleState.detached:
        debugPrint('🛑 App detached');
        break;

      default:
        break;
    }
  }

  void _checkAndRefreshData() {
    Future.microtask(() async {
      try {
        // Perform incremental sync when app resumes
        final initService = AppInitializationService.instance;
        if (initService.hasInternet) {
          debugPrint('🔄 Performing background sync...');
          await initService.manualSync();
          debugPrint('✅ Background sync completed');
        }
      } catch (e) {
        debugPrint('⚠️ Background sync failed: $e');
      }
    });
  }

  void _logSyncStatus() {
    Future.microtask(() async {
      try {
        final status = await AppInitializationService.instance.getStatus();
        debugPrint('📊 Sync Status: ${status['sync_statistics']}');
      } catch (e) {
        debugPrint('⚠️ Could not get sync status: $e');
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'PathWise',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        fontFamily: 'SF Pro Display',
        useMaterial3: true,
      ),
      home: const AuthWrapper(),
      routes: {
        '/login': (context) => const AuthScreen(),
        '/home': (context) => const UniversityListScreen(),
        '/programs': (context) => const ProgramListScreen(),
      },
      debugShowCheckedModeBanner: false,
    );
  }
}

class AuthWrapper extends StatefulWidget {
  const AuthWrapper({Key? key}) : super(key: key);

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  bool _isInitialized = false;
  String _initStatus = 'Initializing PathWise...';
  double _progress = 0.0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeApp();
    });
  }

  Future<void> _initializeApp() async {
    try {
      final authViewModel = Provider.of<AuthViewModel>(context, listen: false);
      final notificationViewModel = Provider.of<NotificationViewModel>(
        context,
        listen: false,
      );
      final universityListViewModel = Provider.of<UniversityListViewModel>(
        context,
        listen: false,
      );

      // Step 1: Initialize auth (0-20%)
      setState(() {
        _initStatus = 'Checking authentication...';
        _progress = 0.1;
      });
      await authViewModel.init();
      setState(() => _progress = 0.2);
      debugPrint('✅ Auth initialized');

      // Step 2: Initialize user services (20-40%)
      if (authViewModel.isUserLoggedIn() && authViewModel.currentUser != null) {
        final userId = authViewModel.currentUser!.userId;

        setState(() {
          _initStatus = 'Setting up notifications...';
          _progress = 0.3;
        });
        await notificationViewModel.initializeForUser(userId);
        setState(() => _progress = 0.4);
        debugPrint('✅ Notifications initialized');

        // Step 3: Initialize view model with sync check (40-90%)
        setState(() {
          _initStatus = 'Loading data from Supabase...';
          _progress = 0.5;
        });

        // Initialize university list (checks sync status)
        await universityListViewModel.initialize();

        setState(() => _progress = 0.9);
        debugPrint('✅ Data loaded from SQLite');
      }

      // Step 4: Get final status (90-100%)
      setState(() {
        _initStatus = 'Finalizing...';
        _progress = 0.95;
      });

      final appStatus = await AppInitializationService.instance.getStatus();
      debugPrint('📊 App Status: ${appStatus['initialized']}');
      debugPrint('📊 Database Size: ${(appStatus['database_size'] / 1024 / 1024).toStringAsFixed(2)} MB');

      await Future.delayed(const Duration(milliseconds: 300));

      setState(() {
        _isInitialized = true;
        _initStatus = 'Ready!';
        _progress = 1.0;
      });

      debugPrint('✅ App initialization complete');
    } catch (e) {
      debugPrint('❌ Error initializing app: $e');
      setState(() {
        _isInitialized = true;
        _initStatus = 'Ready with errors';
        _progress = 1.0;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_isInitialized) {
      return Scaffold(
        backgroundColor: Colors.white,
        body: AppLoadingContent(
          progress: (_progress * 100).toInt(),
          statusText: _initStatus,
        ),
      );
    }

    return Consumer<AuthViewModel>(
      builder: (context, authViewModel, child) {
        if (authViewModel.isUserLoggedIn()) {
          return const UniversityListScreen();
        } else {
          return const AuthScreen();
        }
      },
    );
  }
}