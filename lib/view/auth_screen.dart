import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../utils/validators.dart';
import '../services/notification_service.dart';
import '../viewModel/auth_view_model.dart';
import '../viewModel/notification_view_model.dart';
import '../widgets/custom_text_field.dart';
import '../widgets/custom_button.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // Login form controllers
  final _loginFormKey = GlobalKey<FormState>();
  final _loginEmailController = TextEditingController();
  final _loginPasswordController = TextEditingController();
  bool _rememberMe = false;

  // Register form controllers
  final _registerFormKey = GlobalKey<FormState>();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _registerEmailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _registerPasswordController = TextEditingController();
  final _dobController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _addressController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final viewModel = Provider.of<AuthViewModel>(context, listen: false);
      setState(() {
        _rememberMe = viewModel.rememberMe;
      });
    });

    final viewModel = Provider.of<AuthViewModel>(context, listen: false);
    _tabController.addListener(() {
      // Check if the controller's animation is finished to avoid multiple calls
      if (!_tabController.indexIsChanging) {
        viewModel.setAuthMode(_tabController.index);
        // Validate the current form after switching tabs
        if (_tabController.index == 0) {
          // Login tab
          _validateLoginForm();
        } else {
          // Register tab
          _validateRegisterForm();
        }
      }
    });
  }

  void _validateLoginForm() {
    final viewModel = Provider.of<AuthViewModel>(context, listen: false);
    viewModel.validateForm(
      email: _loginEmailController.text,
      password: _loginPasswordController.text,
    );
  }

  void _validateRegisterForm() {
    final viewModel = Provider.of<AuthViewModel>(context, listen: false);
    viewModel.validateForm(
      email: _registerEmailController.text,
      password: _registerPasswordController.text,
      confirmPassword: _confirmPasswordController.text,
      firstName: _firstNameController.text,
      lastName: _lastNameController.text,
      phone: _phoneController.text,
      dob: _dobController.text,
      address: _addressController.text,
    );
  }

  Future<void> _handleLogin() async {
    if (_loginFormKey.currentState?.validate() ?? false) {
      final authViewModel = Provider.of<AuthViewModel>(context, listen: false);
      // final carViewModel = Provider.of<CarViewModel>(context, listen: false); // Get CarViewModel
      authViewModel.setRememberMe(_rememberMe);

      final success = await authViewModel.login(
        email: _loginEmailController.text,
        password: _loginPasswordController.text,
        // carViewModel: carViewModel, // Pass it here
      );

      if (success && mounted) {
        final notificationViewModel = Provider.of<NotificationViewModel>(
            context,
            listen: false
        );

        // Get the userId from the authViewModel after successful login
        final userId = authViewModel.currentUser?.userId;
        print(userId);
        if (userId != null) {
          await notificationViewModel.initializeForUser(userId);
        }

        Navigator.of(context).pushReplacementNamed('/home');
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(authViewModel.errorMessage ?? 'Login failed'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _handleRegister() async {
    if (_registerFormKey.currentState?.validate() ?? false) {
      final viewModel = Provider.of<AuthViewModel>(context, listen: false);

      final success = await viewModel.register(
        email: _registerEmailController.text,
        password: _registerPasswordController.text,
        firstName: _firstNameController.text,
        lastName: _lastNameController.text,
        phone: _phoneController.text,
        dob: _dobController.text,
        address: _addressController.text,
      );

      if (success && mounted) {
        final notificationViewModel = Provider.of<NotificationViewModel>(
            context,
            listen: false
        );

        final userId = viewModel.currentUser?.userId;
        final userName = "${viewModel.currentUser!.firstName} ${viewModel.currentUser!.lastName}";
        print(userId);
        if (userId != null) {
          await notificationViewModel.initializeForUser(userId);
          await NotificationService.createWelcomeNotification(
            userId: userId,
            userName: userName,
          );
        }

        Navigator.of(context).pushReplacementNamed('/home');
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(viewModel.errorMessage ?? 'Registration failed'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _handleForgotPassword() async {
    if (_loginEmailController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter your email address first'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final viewModel = Provider.of<AuthViewModel>(context, listen: false);
    final success = await viewModel.resetPassword(_loginEmailController.text);

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Password reset email sent!'),
          backgroundColor: Colors.green,
        ),
      );
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(viewModel.errorMessage ?? 'Failed to send reset email'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _loginEmailController.dispose();
    _loginPasswordController.dispose();
    _firstNameController.dispose();
    _lastNameController.dispose();
    _registerEmailController.dispose();
    _phoneController.dispose();
    _registerPasswordController.dispose();
    _dobController.dispose();
    _confirmPasswordController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Stack(
          children: [
            // Vector pinned to top-right
            Positioned(
              top: 0,
              right: 0,
              child: Image.asset(
                'assets/images/Vector.png',
                height: 250,
                fit: BoxFit.contain,
              ),
            ),

            // Main scrollable content - everything scrolls together
            SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                children: [
                  const SizedBox(height: 40),

                  // // Logo
                  // Image.asset(
                  //   "assets/images/carFixer_logo.png",
                  //   height: 40,
                  //   fit: BoxFit.contain,
                  // ),

                  const SizedBox(height: 24),

                  // Title
                  AnimatedBuilder(
                    animation: _tabController,
                    builder: (context, _) {
                      final isLogin = _tabController.index == 0;

                      return Column(
                        children: [
                          Text(
                            isLogin ? 'Welcome to PathWise' : 'Join PathWise',
                            style: const TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1A1A1A),
                            ),
                          ),

                          const SizedBox(height: 8),

                          Text(
                            isLogin
                                ? 'Sign In to explore your educational and career journey'
                                : 'Create your account to start your educational and career journey',
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 16,
                              color: Colors.grey,
                              height: 1.5,
                            ),
                          ),
                        ],
                      );
                    },
                  ),

                  const SizedBox(height: 32),

                  // Premium Tab Bar Design
                  Container(
                    height: 52,
                    padding: const EdgeInsets.all(3),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF0F2F5),
                      borderRadius: BorderRadius.circular(26),
                      border: Border.all(
                        color: const Color(0xFFE8EAED),
                        width: 1,
                      ),
                    ),
                    child: Stack(
                      children: [
                        // Animated indicator
                        AnimatedBuilder(
                          animation: _tabController,
                          builder: (context, child) {
                            return AnimatedAlign(
                              duration: const Duration(milliseconds: 250),
                              curve: Curves.easeInOut,
                              alignment: _tabController.index == 0
                                  ? Alignment.centerLeft
                                  : Alignment.centerRight,
                              child: FractionallySizedBox(
                                widthFactor: 0.5,
                                child: Container(
                                  height: 46,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(23),
                                    gradient: const LinearGradient(
                                      colors: [
                                        Color(0xFF4285F4),
                                        Color(0xFF6C63FF),
                                      ],
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: const Color(0xFF4285F4).withOpacity(0.4),
                                        blurRadius: 12,
                                        offset: const Offset(0, 4),
                                        spreadRadius: 0,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                        // Tab buttons
                        Row(
                          children: [
                            Expanded(
                              child: GestureDetector(
                                onTap: () => _tabController.animateTo(0),
                                child: Container(
                                  height: 46,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(23),
                                  ),
                                  child: Center(
                                    child: AnimatedBuilder(
                                      animation: _tabController,
                                      builder: (context, child) {
                                        final isSelected = _tabController.index == 0;
                                        return Text(
                                          'Log In',
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: isSelected
                                                ? FontWeight.w600
                                                : FontWeight.w500,
                                            color: isSelected
                                                ? Colors.white
                                                : const Color(0xFF6B7280),
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            Expanded(
                              child: GestureDetector(
                                onTap: () => _tabController.animateTo(1),
                                child: Container(
                                  height: 46,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(23),
                                  ),
                                  child: Center(
                                    child: AnimatedBuilder(
                                      animation: _tabController,
                                      builder: (context, child) {
                                        final isSelected = _tabController.index == 1;
                                        return Text(
                                          'Sign Up',
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: isSelected
                                                ? FontWeight.w600
                                                : FontWeight.w500,
                                            color: isSelected
                                                ? Colors.white
                                                : const Color(0xFF6B7280),
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 32),

                  // Tab content - shows current tab's content without nested scrolling
                  AnimatedBuilder(
                    animation: _tabController,
                    builder: (context, child) {
                      return _tabController.index == 0
                          ? _buildLoginContent()
                          : _buildRegisterContent();
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoginContent() {
    return Form(
      key: _loginFormKey,
      child: Column(
        children: [
          // Email field
          CustomTextField(
            labelText: 'Email',
            hintText: 'Enter your email',
            controller: _loginEmailController,
            keyboardType: TextInputType.emailAddress,
            validator: Validators.validateEmail,
            prefixIcon: const Icon(
              Icons.email_outlined,
              color: Colors.grey,
            ),
            onChanged: (_) => _validateLoginForm(),
          ),

          const SizedBox(height: 20),

          // Password field
          CustomTextField(
            labelText: 'Password',
            hintText: 'Enter your password',
            controller: _loginPasswordController,
            obscureText: true,
            validator: Validators.validatePassword,
            prefixIcon: const Icon(
              Icons.lock_outline,
              color: Colors.grey,
            ),
            onChanged: (_) => _validateLoginForm(),
          ),

          const SizedBox(height: 16),

          // Remember me + Forgot Password
          Row(
            children: [
              Transform.scale(
                scale: 0.9,
                child: Checkbox(
                  value: _rememberMe,
                  onChanged: (value) {
                    setState(() {
                      _rememberMe = value ?? false;
                    });
                  },
                  activeColor: const Color(0xFF4285F4),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
              const Text(
                'Remember me',
                style: TextStyle(fontSize: 14, color: Color(0xFF666666)),
              ),
              const Spacer(),
              TextButton(
                onPressed: _handleForgotPassword,
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: const Text(
                  'Forgot Password ?',
                  style: TextStyle(
                    fontSize: 14,
                    color: Color(0xFF4285F4),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 32),

          // Login button
          Consumer<AuthViewModel>(
            builder: (context, viewModel, child) {
              return CustomButton(
                text: 'Log In',
                onPressed: _handleLogin,
                isLoading: viewModel.isLoading,
                isEnabled: viewModel.isFormValid,
              );
            },
          ),

          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildRegisterContent() {
    return Form(
      key: _registerFormKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Name fields row
          Row(
            children: [
              Expanded(
                child: CustomTextField(
                  labelText: 'First Name',
                  hintText: 'First Name',
                  controller: _firstNameController,
                  validator: (value) => Validators.validateName(value, 'First name'),
                  keyboardType: TextInputType.name,
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z\s]')),
                  ],
                  onChanged: (_) => _validateRegisterForm(),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: CustomTextField(
                  labelText: 'Last Name',
                  hintText: 'Last Name',
                  controller: _lastNameController,
                  validator: (value) => Validators.validateName(value, 'Last name'),
                  keyboardType: TextInputType.name,
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z\s]')),
                  ],
                  onChanged: (_) => _validateRegisterForm(),
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          // DOB
          GestureDetector(
            onTap: () async {
              DateTime? pickedDate = await showDatePicker(
                context: context,
                initialDate: DateTime(2000),
                firstDate: DateTime(1900),
                lastDate: DateTime.now(),
                helpText: 'Select Date of Birth',
                builder: (context, child) {
                  return Theme(
                    data: Theme.of(context).copyWith(
                      colorScheme: const ColorScheme.light(
                        primary: Color(0xFF5C6BC0),
                      ),
                    ),
                    child: child!,
                  );
                },
              );

              if (pickedDate != null) {
                _dobController.text = pickedDate.toIso8601String().split('T').first;
                _validateRegisterForm();
                setState(() {});
              }
            },
            child: AbsorbPointer(
              child: CustomTextField(
                labelText: 'Date of Birth',
                hintText: 'YYYY-MM-DD',
                controller: _dobController,
                readOnly: true,
                prefixIcon: const Icon(Icons.calendar_today),
              ),
            ),
          ),

          const SizedBox(height: 20),

          // Email
          CustomTextField(
            labelText: 'Email',
            hintText: 'Enter your email',
            controller: _registerEmailController,
            keyboardType: TextInputType.emailAddress,
            validator: Validators.validateEmail,
            onChanged: (_) => _validateRegisterForm(),
          ),

          const SizedBox(height: 20),

          // Phone (already exists)
          CustomTextField(
            labelText: 'Phone Number',
            hintText: 'Enter your phone number',
            controller: _phoneController,
            keyboardType: TextInputType.phone,
            validator: Validators.validatePhone,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(15),
            ],
            onChanged: (_) => _validateRegisterForm(),
          ),

          const SizedBox(height: 20),

          // Address
          CustomTextField(
            labelText: 'Address',
            hintText: 'Enter your full address',
            controller: _addressController,
            validator: (value) =>
            value == null || value.isEmpty ? 'Address is required' : null,
            onChanged: (_) => _validateRegisterForm(),
            maxLines: 3,
          ),

          const SizedBox(height: 20),

          // Password
          CustomTextField(
            labelText: 'Set Password',
            hintText: 'Set a strong password',
            controller: _registerPasswordController,
            obscureText: true,
            validator: Validators.validatePassword,
            onChanged: (_) => _validateRegisterForm(),
          ),

          const SizedBox(height: 20),

          // Confirm Password
          CustomTextField(
            labelText: 'Confirm Password',
            hintText: 'Re-enter your password',
            controller: _confirmPasswordController,
            obscureText: true,
            validator: (value) {
              if (value != _registerPasswordController.text) {
                return 'Passwords do not match';
              }
              return null;
            },
            onChanged: (_) => _validateRegisterForm(),
          ),

          const SizedBox(height: 40),

          Consumer<AuthViewModel>(
            builder: (context, viewModel, child) {
              return CustomButton(
                text: 'Register',
                onPressed: _handleRegister,
                isLoading: viewModel.isLoading,
                isEnabled: viewModel.isFormValid,
              );
            },
          ),

          const SizedBox(height: 40),
        ],
      ),
    );
  }

}