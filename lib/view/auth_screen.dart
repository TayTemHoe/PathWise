import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import '../../utils/validators.dart';
import '../services/notification_service.dart';
import '../viewModel/auth_view_model.dart';
import '../viewModel/notification_view_model.dart';
import '../widgets/custom_text_field.dart';
import '../widgets/custom_button.dart';
import '../widgets/role_selection_widget.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  DateTime? _selectedDob;

  // Registration step controller
  int _currentStep = 0;

  // Validation Modes
  AutovalidateMode _loginAutoValidateMode = AutovalidateMode.disabled;
  AutovalidateMode _registerAutoValidateMode = AutovalidateMode.disabled;

  // Login form controllers
  final _loginFormKey = GlobalKey<FormState>();
  final _loginEmailController = TextEditingController();
  final _loginPasswordController = TextEditingController();
  bool _rememberMe = false;

  // Register form controllers
  final _registerFormKey = GlobalKey<FormState>();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _dobController = TextEditingController();
  final _registerEmailController = TextEditingController();
  final _registerPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _addressLine1Controller = TextEditingController();
  final _addressLine2Controller = TextEditingController();
  final _cityController = TextEditingController();
  final _stateController = TextEditingController();
  final _countryController = TextEditingController();
  final _zipCodeController = TextEditingController();

  String _selectedRole = 'education';

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
      if (!_tabController.indexIsChanging) {
        viewModel.setAuthMode(_tabController.index);

        // Reset validation state and step when switching tabs
        setState(() {
          _loginAutoValidateMode = AutovalidateMode.disabled;
          _registerAutoValidateMode = AutovalidateMode.disabled;
          if (_tabController.index == 1) {
            _currentStep = 0;
          }
        });
      }
    });
  }

  // Helper to check if required fields are simply filled (not validated for correctness yet)
  bool _areRequiredFieldsFilled() {
    switch (_currentStep) {
      case 0: // Personal Info
        return _firstNameController.text.trim().isNotEmpty &&
            _lastNameController.text.trim().isNotEmpty &&
            _registerEmailController.text.trim().isNotEmpty &&
            _selectedDob != null && // CHANGED: Check DateTime object
            _phoneController.text.trim().isNotEmpty;

      case 1: // Account Info
        return _registerPasswordController.text.trim().isNotEmpty &&
            _confirmPasswordController.text.trim().isNotEmpty;

      case 2: // Address Info
        return _addressLine1Controller.text.trim().isNotEmpty &&
            _cityController.text.trim().isNotEmpty &&
            _stateController.text.trim().isNotEmpty &&
            _countryController.text.trim().isNotEmpty &&
            _zipCodeController.text.trim().isNotEmpty;

      default:
        return false;
    }
  }

  void _nextStep() {
    FocusScope.of(context).unfocus();

    setState(() {
      _registerAutoValidateMode = AutovalidateMode.onUserInteraction;
    });

    // Validate current step BEFORE proceeding
    if (_registerFormKey.currentState?.validate() ?? false) {
      if (_currentStep < 2) {
        setState(() {
          _currentStep++;
          _registerAutoValidateMode = AutovalidateMode.disabled;
        });
      } else {
        _handleRegister();
      }
    }
    // } else {
    //   // Show error message
    //   ScaffoldMessenger.of(context).showSnackBar(
    //     const SnackBar(
    //       content: Text('Please correct the errors before continuing'),
    //       backgroundColor: Colors.orange,
    //       behavior: SnackBarBehavior.floating,
    //       duration: Duration(seconds: 2),
    //     ),
    //   );
    // }
  }

  void _previousStep() {
    FocusScope.of(context).unfocus();
    if (_currentStep > 0) {
      setState(() {
        _currentStep--;
        _registerAutoValidateMode = AutovalidateMode.disabled;
      });
    }
  }

  Future<void> _handleLogin() async {
    FocusScope.of(context).unfocus();

    setState(() {
      _loginAutoValidateMode = AutovalidateMode.onUserInteraction;
    });

    if (_loginFormKey.currentState?.validate() ?? false) {
      final authViewModel = Provider.of<AuthViewModel>(context, listen: false);
      authViewModel.setRememberMe(_rememberMe);

      final success = await authViewModel.login(
        email: _loginEmailController.text,
        password: _loginPasswordController.text,
      );

      if (!mounted) return;

      if (success) {
        final notificationViewModel = Provider.of<NotificationViewModel>(context, listen: false);
        final userId = authViewModel.currentUser?.userId;
        if (userId != null) {
          await notificationViewModel.initializeForUser(userId);
        }

        if (!mounted) return;
        Navigator.of(context).pushReplacementNamed('/home');
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(authViewModel.errorMessage ?? 'Login failed'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<void> _handleRegister() async {
    FocusScope.of(context).unfocus();

    setState(() {
      _registerAutoValidateMode = AutovalidateMode.onUserInteraction;
    });

    if (_registerFormKey.currentState?.validate() ?? false) {
      if (_selectedDob == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please select your date of birth'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      final viewModel = Provider.of<AuthViewModel>(context, listen: false);

      final success = await viewModel.register(
        email: _registerEmailController.text,
        password: _registerPasswordController.text,
        firstName: _firstNameController.text,
        lastName: _lastNameController.text,
        phone: _phoneController.text,
        dob: _selectedDob!, // CHANGED: Pass DateTime object
        addressLine1: _addressLine1Controller.text,
        addressLine2: _addressLine2Controller.text.isEmpty ? null : _addressLine2Controller.text,
        city: _cityController.text,
        state: _stateController.text,
        country: _countryController.text,
        zipCode: _zipCodeController.text,
        userRole: _selectedRole,
      );

      if (!mounted) return;

      if (success) {
        final notificationViewModel = Provider.of<NotificationViewModel>(context, listen: false);
        final userId = viewModel.currentUser?.userId;
        final userName = "${viewModel.currentUser!.firstName} ${viewModel.currentUser!.lastName}";

        if (userId != null) {
          await notificationViewModel.initializeForUser(userId);
          await NotificationService.createWelcomeNotification(
            userId: userId,
            userName: userName,
          );
        }

        if (!mounted) return;
        Navigator.of(context).pushReplacementNamed('/home');
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(viewModel.errorMessage ?? 'Registration failed'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  void _handleForgotPassword() async {
    FocusScope.of(context).unfocus();
    if (_loginEmailController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter your email address first'),
          backgroundColor: Colors.orange,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    final viewModel = Provider.of<AuthViewModel>(context, listen: false);
    final success = await viewModel.resetPassword(_loginEmailController.text);

    if (!mounted) return;

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Password reset email sent!'),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(viewModel.errorMessage ?? 'Failed to send reset email'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
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
    _addressLine1Controller.dispose();
    _addressLine2Controller.dispose();
    _cityController.dispose();
    _stateController.dispose();
    _countryController.dispose();
    _zipCodeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        backgroundColor: Colors.white,
        resizeToAvoidBottomInset: true,
        body: Stack(
          children: [
            // Background Image
            Positioned(
              top: 0,
              right: 0,
              child: Image.asset(
                'assets/images/Vector.png',
                height: 250,
                fit: BoxFit.contain,
              ),
            ),

            // Main Content
            LayoutBuilder(
              builder: (context, constraints) {
                return SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0),
                  child: ConstrainedBox(
                    // Ensure content is at least screen height, but allows growing
                    // which prevents error messages from blocking sentences or overlapping
                    constraints: BoxConstraints(minHeight: constraints.maxHeight),
                    child: IntrinsicHeight(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const SizedBox(height: 40),

                          // Header Section
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
                                      letterSpacing: -0.5,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    isLogin
                                        ? 'Sign In to explore your journey'
                                        : 'Create account to start your journey',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontSize: 15,
                                      color: Colors.grey[600],
                                      height: 1.4,
                                    ),
                                  ),
                                ],
                              );
                            },
                          ),

                          const SizedBox(height: 24),

                          // Tab Bar
                          Container(
                            height: 48,
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF0F2F5),
                              borderRadius: BorderRadius.circular(24),
                            ),
                            child: Stack(
                              children: [
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
                                          decoration: BoxDecoration(
                                            borderRadius: BorderRadius.circular(20),
                                            gradient: const LinearGradient(
                                              colors: [Color(0xFF4285F4), Color(0xFF6C63FF)],
                                              begin: Alignment.topLeft,
                                              end: Alignment.bottomRight,
                                            ),
                                            boxShadow: [
                                              BoxShadow(
                                                color: const Color(0xFF4285F4).withOpacity(0.3),
                                                blurRadius: 4,
                                                offset: const Offset(0, 2),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    );
                                  },
                                ),
                                Row(
                                  children: [
                                    _buildTabItem(0, 'Log In'),
                                    _buildTabItem(1, 'Sign Up'),
                                  ],
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 24),

                          // Content Area
                          AnimatedBuilder(
                            animation: _tabController,
                            builder: (context, child) {
                              return _tabController.index == 0
                                  ? _buildLoginContent()
                                  : _buildRegisterContent();
                            },
                          ),

                          const SizedBox(height: 20),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTabItem(int index, String title) {
    return Expanded(
      child: GestureDetector(
        onTap: () => _tabController.animateTo(index),
        behavior: HitTestBehavior.translucent,
        child: Container(
          alignment: Alignment.center,
          child: AnimatedBuilder(
            animation: _tabController,
            builder: (context, child) {
              final isSelected = _tabController.index == index;
              return Text(
                title,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                  color: isSelected ? Colors.white : const Color(0xFF6B7280),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildLoginContent() {
    return Form(
      key: _loginFormKey,
      autovalidateMode: _loginAutoValidateMode,
      child: Column(
        children: [
          CustomTextField(
            labelText: 'Email',
            hintText: 'Enter your email',
            controller: _loginEmailController,
            keyboardType: TextInputType.emailAddress,
            validator: Validators.validateEmail,
            prefixIcon: const Icon(Icons.email_outlined, color: Colors.grey),
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 16),
          CustomTextField(
            labelText: 'Password',
            hintText: 'Enter your password',
            controller: _loginPasswordController,
            obscureText: true,
            validator: Validators.validatePassword,
            prefixIcon: const Icon(Icons.lock_outline, color: Colors.grey),
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              SizedBox(
                height: 24,
                width: 24,
                child: Checkbox(
                  value: _rememberMe,
                  onChanged: (value) => setState(() => _rememberMe = value ?? false),
                  activeColor: const Color(0xFF4285F4),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                ),
              ),
              const SizedBox(width: 8),
              const Text(
                'Remember me',
                style: TextStyle(fontSize: 14, color: Color(0xFF666666)),
              ),
              const Spacer(),
              TextButton(
                onPressed: _handleForgotPassword,
                style: TextButton.styleFrom(
                  padding: EdgeInsets.zero,
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: const Text(
                  'Forgot Password?',
                  style: TextStyle(
                    fontSize: 14,
                    color: Color(0xFF4285F4),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Consumer<AuthViewModel>(
            builder: (context, viewModel, child) {
              // Login also implements the "must be filled" logic for consistency
              final bool isLoginFilled = _loginEmailController.text.trim().isNotEmpty &&
                  _loginPasswordController.text.trim().isNotEmpty;
              return CustomButton(
                text: 'Log In',
                onPressed: _handleLogin,
                isLoading: viewModel.isLoading,
                isEnabled: isLoginFilled,
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildRegisterContent() {
    return Form(
      key: _registerFormKey,
      autovalidateMode: _registerAutoValidateMode,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildProgressIndicator(),
          const SizedBox(height: 12),

          AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            transitionBuilder: (Widget child, Animation<double> animation) {
              return FadeTransition(opacity: animation, child: child);
            },
            child: KeyedSubtree(
              key: ValueKey<int>(_currentStep),
              child: _getCurrentStepWidget(),
            ),
          ),

          const SizedBox(height: 20),

          Row(
            children: [
              if (_currentStep > 0)
                Expanded(
                  child: OutlinedButton(
                    onPressed: _previousStep,
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      side: const BorderSide(color: Color(0xFF4285F4)),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      backgroundColor: Colors.white,
                    ),
                    child: const Text(
                      'Back',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF4285F4),
                      ),
                    ),
                  ),
                ),

              if (_currentStep > 0) const SizedBox(width: 12),

              Expanded(
                flex: _currentStep == 0 ? 1 : 1,
                child: Consumer<AuthViewModel>(
                  builder: (context, viewModel, child) {
                    return CustomButton(
                      text: _currentStep == 2 ? 'Complete Registration' : 'Next',
                      onPressed: _nextStep,
                      isLoading: _currentStep == 2 && viewModel.isLoading,
                      // The button is strictly enabled based on whether fields are filled
                      isEnabled: _areRequiredFieldsFilled(),
                    );
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _getCurrentStepWidget() {
    switch (_currentStep) {
      case 0:
        return _buildPersonalInfoStep();
      case 1:
        return _buildAccountInfoStep();
      case 2:
        return _buildAddressInfoStep();
      default:
        return Container();
    }
  }

  Widget _buildProgressIndicator() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          for (int index = 0; index < 3; index++) ...[
            _buildStepCircle(index),
            if (index < 2) Expanded(child: _buildConnectorLine(index)),
          ],
        ],
      ),
    );
  }

  Widget _buildStepCircle(int index) {
    final isCompleted = index < _currentStep;
    final isCurrent = index == _currentStep;

    return Column(
      children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isCompleted || isCurrent
                ? const Color(0xFF4285F4)
                : const Color(0xFFF3F4F6),
            boxShadow: isCurrent
                ? [
              BoxShadow(
                color: const Color(0xFF4285F4).withOpacity(0.3),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ]
                : [],
          ),
          child: Center(
            child: isCompleted
                ? const Icon(Icons.check, color: Colors.white, size: 16)
                : Text(
              '${index + 1}',
              style: TextStyle(
                color: isCurrent ? Colors.white : const Color(0xFF9CA3AF),
                fontWeight: FontWeight.w600,
                fontSize: 15,
              ),
            ),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          _getStepLabel(index),
          style: TextStyle(
            fontSize: 15,
            fontWeight: isCurrent ? FontWeight.w600 : FontWeight.w500,
            color: isCurrent || isCompleted
                ? const Color(0xFF1A1A1A)
                : const Color(0xFF9CA3AF),
          ),
        ),
      ],
    );
  }

  Widget _buildConnectorLine(int index) {
    final isCompleted = index < _currentStep;
    return Container(
      height: 2,
      margin: const EdgeInsets.only(bottom: 20, left: 4, right: 4),
      color: isCompleted ? const Color(0xFF4285F4) : const Color(0xFFE5E7EB),
    );
  }

  String _getStepLabel(int index) {
    switch (index) {
      case 0: return 'Personal';
      case 1: return 'Account';
      case 2: return 'Address';
      default: return '';
    }
  }

  Widget _buildPersonalInfoStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: CustomTextField(
                labelText: 'First Name',
                hintText: 'John',
                controller: _firstNameController,
                validator: (value) => Validators.validateName(value, 'First name'),
                keyboardType: TextInputType.name,
                inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z\s]'))],
                prefixIcon: const Icon(Icons.person_outline, color: Colors.grey),
                onChanged: (_) => setState(() {}),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: CustomTextField(
                labelText: 'Last Name',
                hintText: 'Doe',
                controller: _lastNameController,
                validator: (value) => Validators.validateName(value, 'Last name'),
                keyboardType: TextInputType.name,
                inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z\s]'))],
                prefixIcon: const Icon(Icons.person_outline, color: Colors.grey),
                onChanged: (_) => setState(() {}),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        CustomTextField(
          labelText: 'Email',
          hintText: 'john@example.com',
          controller: _registerEmailController,
          keyboardType: TextInputType.emailAddress,
          validator: Validators.validateEmail,
          prefixIcon: const Icon(Icons.email_outlined, color: Colors.grey),
          onChanged: (_) => setState(() {}),
        ),
        const SizedBox(height: 16),
        InkWell(
          onTap: () async {
            FocusScope.of(context).unfocus();
            DateTime? pickedDate = await showDatePicker(
              context: context,
              initialDate: DateTime(2005),
              firstDate: DateTime(1950),
              lastDate: DateTime.now(),
              builder: (context, child) {
                return Theme(
                  data: Theme.of(context).copyWith(
                    colorScheme: const ColorScheme.light(primary: Color(0xFF4285F4)),
                  ),
                  child: child!,
                );
              },
            );

            if (pickedDate != null) {
              setState(() {
                _selectedDob = pickedDate; // CHANGED: Store DateTime
                _dobController.text = DateFormat('yyyy-MM-dd').format(pickedDate);
              });
            }
          },
          child: AbsorbPointer(
            child: CustomTextField(
              labelText: 'Date of Birth',
              hintText: 'YYYY-MM-DD',
              controller: _dobController,
              validator: (value) {
                if (_selectedDob == null) {
                  return "Date of Birth is required";
                }
                return null;
              },
              prefixIcon: const Icon(Icons.calendar_today, color: Colors.grey),
              onChanged: (_) => setState(() {}),
            ),
          ),
        ),
        const SizedBox(height: 16),
        CustomTextField(
          labelText: 'Phone Number',
          hintText: '0123456789',
          controller: _phoneController,
          keyboardType: TextInputType.phone,
          validator: Validators.validatePhone,
          prefixIcon: const Icon(Icons.phone_outlined, color: Colors.grey),
          inputFormatters: [
            FilteringTextInputFormatter.digitsOnly,
            LengthLimitingTextInputFormatter(15),
          ],
          onChanged: (_) => setState(() {}),
        ),
      ],
    );
  }

  Widget _buildAccountInfoStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 16),
        CustomTextField(
          labelText: 'Password',
          hintText: 'Min. 8 characters',
          controller: _registerPasswordController,
          obscureText: true,
          validator: Validators.validatePassword,
          prefixIcon: const Icon(Icons.lock_outline, color: Colors.grey),
          onChanged: (_) => setState(() {}),
        ),
        const SizedBox(height: 16),
        CustomTextField(
          labelText: 'Confirm Password',
          hintText: 'Re-enter your password',
          controller: _confirmPasswordController,
          obscureText: true,
          validator: (value) {
            if (value != _registerPasswordController.text) return 'Passwords do not match';
            return null;
          },
          prefixIcon: const Icon(Icons.lock_outline, color: Colors.grey),
          onChanged: (_) => setState(() {}),
        ),
        const SizedBox(height: 20),
        RoleSelectionWidget(
          selectedRole: _selectedRole,
          onRoleSelected: (role) => setState(() => _selectedRole = role),
        ),
      ],
    );
  }

  Widget _buildAddressInfoStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 16),
        CustomTextField(
          labelText: 'Address Line 1',
          hintText: 'Street address',
          controller: _addressLine1Controller,
          validator: Validators.validateAddressLine1,
          prefixIcon: const Icon(Icons.home_outlined, color: Colors.grey),
          onChanged: (_) => setState(() {}),
        ),
        const SizedBox(height: 16),
        CustomTextField(
          labelText: 'Address Line 2 (Optional)',
          hintText: 'Apartment, unit, etc.',
          controller: _addressLine2Controller,
          validator: Validators.validateAddressLine2,
          prefixIcon: const Icon(Icons.business_outlined, color: Colors.grey),
          onChanged: (_) => setState(() {}),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: CustomTextField(
                labelText: 'City',
                hintText: 'City',
                controller: _cityController,
                validator: Validators.validateCity,
                prefixIcon: const Icon(Icons.location_city_outlined, color: Colors.grey),
                inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z\s\-]'))],
                onChanged: (_) => setState(() {}),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: CustomTextField(
                labelText: 'State',
                hintText: 'State',
                controller: _stateController,
                validator: Validators.validateState,
                prefixIcon: const Icon(Icons.map_outlined, color: Colors.grey),
                inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z\s\-]'))],
                onChanged: (_) => setState(() {}),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              flex: 2,
              child: CustomTextField(
                labelText: 'Country',
                hintText: 'Country',
                controller: _countryController,
                validator: Validators.validateCountry,
                prefixIcon: const Icon(Icons.public_outlined, color: Colors.grey),
                inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z\s\-]'))],
                onChanged: (_) => setState(() {}),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: CustomTextField(
                labelText: 'Zip Code',
                hintText: '12345',
                controller: _zipCodeController,
                validator: Validators.validateZipCode,
                keyboardType: TextInputType.number, // ADDED
                prefixIcon: const Icon(Icons.markunread_mailbox_outlined, color: Colors.grey),
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly, // CHANGED: Digits only
                  LengthLimitingTextInputFormatter(6), // CHANGED: Max 6 digits
                ],
                onChanged: (_) => setState(() {}),
              ),
            ),
          ],
        ),
      ],
    );
  }
}