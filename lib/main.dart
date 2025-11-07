import 'package:flutter/material.dart';
import 'package:path_wise/ViewModel/careerroadmap_view_model.dart';
import 'package:path_wise/ViewModel/interview_view_model.dart';
import 'package:path_wise/ViewModel/resume_view_model.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:path_wise/ViewModel/profile_view_model.dart';
import 'package:path_wise/ViewModel/career_view_model.dart';
import 'package:path_wise/ViewModel/job_view_model.dart';
import 'package:path_wise/routes.dart';
import 'package:path_wise/view/profile/edit_personal_view.dart';
import 'package:path_wise/view/profile/edit_skills_view.dart';
import 'package:path_wise/view/profile/edit_education_view.dart';
import 'package:path_wise/view/profile/edit_experience_view.dart';
import 'package:path_wise/view/profile/edit_preferences_view.dart';
import 'package:path_wise/view/profile/edit_personality_view.dart';
import 'firebase_options.dart';
import 'package:path_wise/view/bottomNavigationBar.dart';
import 'package:path_wise/view/interview/interview_home_view.dart';
import 'package:path_wise/view/interview/interview_setup_view.dart';
import 'package:path_wise/view/interview/interview_session_view.dart';
import 'package:path_wise/view/interview/interview_result_view.dart';
import 'package:path_wise/view/interview/interview_history_view.dart';
import 'package:path_wise/view/resume/resume_create_view.dart';
import 'package:path_wise/view/resume/resume_customize_view.dart';



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
        ChangeNotifierProvider(create: (_) => CareerViewModel()),
        ChangeNotifierProvider(create: (_) => JobViewModel()),
        ChangeNotifierProvider(create: (_) => InterviewViewModel()),
        ChangeNotifierProvider(create: (_) => CareerRoadmapViewModel()),
        ChangeNotifierProvider(create: (_) => ResumeViewModel()),
      ],
      child: MaterialApp(
        routes: {
          AppRoutes.editPersonal:     (_) => const EditPersonalInfoScreen(),
          AppRoutes.editSkills:       (_) => const EditSkillsScreen(),
          AppRoutes.editEducation:    (_) => const EditEducationScreen(),
          AppRoutes.editExperience:   (_) => const EditExperienceScreen(),
          AppRoutes.editPreferences:  (_) => const EditPreferencesScreen(),
          AppRoutes.editPersonality:  (_) => const EditPersonalityScreen(),
          '/interview-home': (context) => const InterviewHomePage(),
          '/interview-setup': (context) => const InterviewSetupPage(),
          '/interview-session': (context) => const InterviewSessionPage(),
          '/interview-results': (context) => const InterviewResultsPage(),
          '/interview-history': (context) => const InterviewHistoryPage(),
          '/resume/template-selection': (context) => TemplateSelectionPage(),
          '/resume/edit':(context) => CustomizeResumePage(),
        },
        debugShowCheckedModeBanner: false,
        title: 'PathWise Demo',
        theme: ThemeData(
          colorSchemeSeed: const Color(0xFF7C4DFF),
          useMaterial3: true,
        ),
        home: const BottomNavScreen(), // <-- View kita
      ),
    );
  }
}
