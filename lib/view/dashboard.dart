import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../utils/app_color.dart';
import '../viewModel/auth_view_model.dart';

class Dashboard extends StatefulWidget {
  const Dashboard({super.key});

  @override
  State<Dashboard> createState() => _DashboardState();
}

class _DashboardState extends State<Dashboard> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // Simple (flat) app bar row
          SliverAppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            pinned: false,
            automaticallyImplyLeading: false,
            toolbarHeight: 56,
            centerTitle: true,
            title: SizedBox(
              height: 35,
              child: Image.asset(
                "assets/images/carFixer_logo.png",
                fit: BoxFit.contain,
              ),
            ),
            actions: [
              Container(
                margin: const EdgeInsets.only(right: 16.0),
                child: IconButton(
                  icon: const Icon(Icons.logout),
                  onPressed: () async {
                    final authViewModel = Provider.of<AuthViewModel>(
                      context,
                      listen: false,
                    );
                    await authViewModel.logout();
                    if (context.mounted) {
                      Navigator.of(context).pushReplacementNamed('/login');
                    }
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
