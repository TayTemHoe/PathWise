// lib/main.dart
import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:path_wise/services/firebase_service.dart';
import 'package:path_wise/utils/currency_utils.dart';
import 'package:path_wise/utils/shared_preferences_helper.dart';
import 'package:path_wise/view/auth_screen.dart';
import 'package:path_wise/view/program_list_screen.dart';
import 'package:path_wise/view/university_list_screen.dart';
import 'package:path_wise/viewModel/auth_view_model.dart';
import 'package:path_wise/viewModel/branch_view_model.dart';
import 'package:path_wise/viewModel/filter_view_model.dart';
import 'package:path_wise/viewModel/notification_view_model.dart';
import 'package:path_wise/viewModel/program_detail_view_model.dart';
import 'package:path_wise/viewModel/program_filter_view_model.dart';
import 'package:path_wise/viewModel/program_list_view_model.dart';
import 'package:path_wise/viewModel/university_detail_view_model.dart';
import 'package:path_wise/viewModel/university_list_view_model.dart';
import 'package:path_wise/widgets/app_loading_screen.dart';
import 'package:path_wise/widgets/firebase_request_monitor.dart';
import 'package:provider/provider.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    // Initialize timezone
    tz.initializeTimeZones();

    // Initialize Firebase
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    debugPrint('✅ Firebase initialized');

    // Enable Firestore offline persistence
    await _enableFirestoreOffline();

    // Initialize SharedPreferences
    await SharedPreferencesHelper.init();
    debugPrint('✅ SharedPreferences initialized');

    // Pre-load currency rates (non-blocking)
    _initializeCurrencyRates();

    // Pre-warm Firestore cache (non-blocking)
    _prewarmFirestoreCache();
  } catch (e) {
    debugPrint('❌ Initialization error: $e');
  }

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthViewModel()),
        ChangeNotifierProvider(create: (_) => NotificationViewModel()),
        ChangeNotifierProvider(create: (_) => UniversityListViewModel()),
        ChangeNotifierProvider(create: (_) => UniversityDetailViewModel()),
        ChangeNotifierProvider(create: (_) => BranchViewModel()),
        ChangeNotifierProvider(create: (_) => FilterViewModel()),
        ChangeNotifierProvider(create: (_) => ProgramListViewModel()),
        ChangeNotifierProvider(create: (_) => ProgramFilterViewModel()),
        ChangeNotifierProvider(create: (_) => ProgramDetailViewModel()),
      ],
      child: const PathWiseApp(),
    ),
  );
}

/// Enable Firestore offline persistence for better caching
Future<void> _enableFirestoreOffline() async {
  try {
    // Enable offline persistence with large cache size
    FirebaseFirestore.instance.settings = const Settings(
      persistenceEnabled: true,
      cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
    );
    debugPrint('✅ Firestore offline persistence enabled');
  } catch (e) {
    debugPrint('⚠️ Could not enable offline persistence: $e');
  }
}

/// Initialize currency rates in background
void _initializeCurrencyRates() {
  Future.microtask(() async {
    try {
      await CurrencyUtils.fetchExchangeRates();
      debugPrint('✅ Currency rates loaded');
    } catch (e) {
      debugPrint('⚠️ Currency rates failed, using fallback: $e');
    }
  });
}

/// Pre-warm Firestore cache by loading critical data
void _prewarmFirestoreCache() {
  Future.microtask(() async {
    try {
      debugPrint('🔥 Pre-warming Firestore cache...');

      // Pre-load Malaysian branches (most common query)
      await FirebaseFirestore.instance
          .collection('branches')
          .where('country', isEqualTo: 'Malaysia')
          .get(const GetOptions(source: Source.server));

      // Pre-load top 20 universities for immediate display
      await FirebaseFirestore.instance
          .collection('universities')
          .orderBy('university_id')
          .limit(20)
          .get(const GetOptions(source: Source.server));

      debugPrint('✅ Firestore cache pre-warmed');
    } catch (e) {
      debugPrint('⚠️ Cache pre-warming failed: $e');
    }
  });
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
        // Log Firebase usage before pausing
        final requestCount = FirebaseService.getRequestCount();
        debugPrint('📊 Firebase requests this session: $requestCount');
        break;

      case AppLifecycleState.detached:
        debugPrint('🛑 App detached');
        // Clear caches to free memory
        FirebaseService.clearAllCaches();
        break;

      default:
        break;
    }
  }

  void _checkAndRefreshData() {
    Future.microtask(() async {
      try {
        // Only refresh if cache is stale (12+ hours)
        if (!CurrencyUtils.hasValidCache) {
          await CurrencyUtils.refreshRates();
          debugPrint('🔄 Currency rates refreshed');
        }
      } catch (e) {
        debugPrint('⚠️ Refresh failed: $e');
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
      home: FirebaseRequestMonitor(child: const AuthWrapper()),
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
  int _progress = 0;

  @override
  void initState() {
    super.initState();
    _initializeApp();
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

      // Step 1: Initialize auth (0-30%)
      setState(() {
        _initStatus = 'Checking authentication...';
        _progress = 10;
      });
      await authViewModel.init();
      setState(() => _progress = 30);
      debugPrint('✅ Auth initialized');

      // Step 2: Initialize user services (30-60%)
      if (authViewModel.isUserLoggedIn() && authViewModel.currentUser != null) {
        final userId = authViewModel.currentUser!.userId;

        setState(() {
          _initStatus = 'Setting up notifications...';
          _progress = 40;
        });
        await notificationViewModel.initializeForUser(userId);
        setState(() => _progress = 60);
        debugPrint('✅ Notifications initialized');

        // Step 3: Load initial data (60-100%)
        setState(() {
          _initStatus = 'Loading universities...';
          _progress = 70;
        });

        // OPTIMIZATION: Load from cache first, don't wait for network
        try {
          await universityListViewModel.loadUniversities().timeout(
            const Duration(seconds: 5),
            onTimeout: () {
              debugPrint('⚠️ Initial load timed out, continuing with cache');
            },
          );
        } catch (e) {
          debugPrint('⚠️ Initial load error: $e');
        }

        setState(() => _progress = 100);
        debugPrint('✅ Initial data loaded');
      }

      // Log total Firebase requests during initialization
      final requestCount = FirebaseService.getRequestCount();
      debugPrint(
        '📊 Initialization complete. Firebase requests: $requestCount',
      );

      await Future.delayed(const Duration(milliseconds: 500));

      setState(() {
        _isInitialized = true;
        _initStatus = 'Ready!';
      });
    } catch (e) {
      debugPrint('❌ Error initializing app: $e');
      setState(() {
        _isInitialized = true;
        _initStatus = 'Ready with errors';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_isInitialized) {
      return Scaffold(
        backgroundColor: Colors.white,
        body: AppLoadingContent(progress: _progress, statusText: _initStatus),
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
