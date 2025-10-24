import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:path_wise/viewmodel/profile_view_model.dart';
import 'package:path_wise/view/profile_overview_view.dart';
import 'package:path_wise/routes.dart';
import 'package:path_wise/view/edit_personal_view.dart';
import 'firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  final opts = Firebase.app().options;
  debugPrint('FIREBASE PROJECT: ${opts.projectId} / ${opts.appId}');
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) {
            final vm = ProfileViewModel();
            vm.loadAll();
            return vm;
          },
        ),
      ],
      child: MaterialApp(
        routes: {
          AppRoutes.editPersonal:     (_) => const EditPersonalInfoScreen()
        },
        debugShowCheckedModeBanner: false,
        title: 'PathWise Demo',
        theme: ThemeData(
          colorSchemeSeed: const Color(0xFF7C4DFF),
          useMaterial3: true,
        ),
        home: const ProfileOverviewScreen(), // <-- View kita
      ),
    );
  }
}
