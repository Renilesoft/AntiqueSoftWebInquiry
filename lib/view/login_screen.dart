import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';
import 'package:awesome_dialog/awesome_dialog.dart';
import '../viewmodel/login_viewmodel.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<Offset> _logoSlideAnimation;
  late Animation<double> _logoFadeAnimation;
  late Animation<Offset> _formSlideAnimation;
  late Animation<double> _formFadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    );

    _logoSlideAnimation = Tween<Offset>(
      begin: const Offset(0, 1),
      end: const Offset(0, 0),
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: const Interval(0.0, 0.5, curve: Curves.easeOut),
    ));

    _logoFadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: const Interval(0.0, 0.5, curve: Curves.easeOut),
    ));

    _formSlideAnimation = Tween<Offset>(
      begin: const Offset(0, 1),
      end: const Offset(0, 0),
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: const Interval(0.5, 1.0, curve: Curves.easeOut),
    ));

    _formFadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: const Interval(0.5, 1.0, curve: Curves.easeOut),
    ));

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final loginViewModel = context.watch<LoginViewModel>();
    final screenSize = MediaQuery.of(context).size;
    
    // Improved adaptive scaling
    double scaleFactor = screenSize.width / 450; // Reduced base width for more compact UI
    
    // Apply constraints to prevent UI from being too large on larger screens
    if (scaleFactor > 0.9) scaleFactor = 0.9;
    
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 20.0 * scaleFactor),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  SizedBox(height: 40 * scaleFactor), // Reduced top spacing
                  // Animated Logo Section
                  SlideTransition(
                    position: _logoSlideAnimation,
                    child: FadeTransition(
                      opacity: _logoFadeAnimation,
                      child: SvgPicture.asset(
                        'assets/logo.svg',
                        height: 120 * scaleFactor, // Reduced logo size
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),
                  SizedBox(height: 30 * scaleFactor), // Reduced spacing
                  // Animated Form Section
                  SlideTransition(
                    position: _formSlideAnimation,
                    child: FadeTransition(
                      opacity: _formFadeAnimation,
                      child: ConstrainedBox(
                        constraints: BoxConstraints(
                          maxWidth: 340 * scaleFactor, // Constrain maximum width
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            _buildTextField(
                              labelText: 'Store Code',
                              iconPath: 'assets/store.png',
                              controller: loginViewModel.storeCodeController,
                              scaleFactor: scaleFactor,
                            ),
                            SizedBox(height: 16 * scaleFactor), // Reduced spacing
                            _buildTextField(
                              labelText: 'User Id',
                              iconPath: 'assets/user.png',
                              controller: loginViewModel.usernameController,
                              scaleFactor: scaleFactor,
                            ),
                            SizedBox(height: 16 * scaleFactor), // Reduced spacing
                            _buildPasswordField(
                              controller: loginViewModel.passwordController,
                              isPasswordVisible: loginViewModel.isPasswordVisible,
                              onToggleVisibility: loginViewModel.togglePasswordVisibility,
                              scaleFactor: scaleFactor,
                            ),
                            SizedBox(height: 6 * scaleFactor), // Reduced spacing
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    Transform.scale(
                                      scale: 0.9 * scaleFactor, // Slightly smaller checkbox
                                      child: Checkbox(
                                        value: loginViewModel.rememberMe,
                                        onChanged: (_) => loginViewModel.toggleRememberMe(),
                                        activeColor: const Color(0xFF172B4D),
                                        visualDensity: VisualDensity.compact,
                                      ),
                                    ),
                                    Text(
                                      'Remember me',
                                      style: TextStyle(
                                        decoration: TextDecoration.underline,
                                        fontSize: 12 * scaleFactor, // Smaller font
                                        color: const Color(0xFF172B4D),
                                      ),
                                    ),
                                  ],
                                ),
                                TextButton(
                                  onPressed: () {},
                                  style: TextButton.styleFrom(
                                    padding: EdgeInsets.zero, // Remove padding
                                    minimumSize: Size.zero,
                                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                  ),
                                  child: Text(
                                    'Forgot password',
                                    style: TextStyle(
                                      decoration: TextDecoration.underline,
                                      fontSize: 12 * scaleFactor, // Smaller font
                                      color: const Color(0xFF172B4D),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: 20 * scaleFactor),
                            SizedBox(
                              width: 140 * scaleFactor, // Smaller button
                              height: 48 * scaleFactor, // Shorter button
                              child: ElevatedButton(
                                onPressed: () async {
                                  bool success = await loginViewModel.login(context);
                                  if (!success) {
                                    // ignore: use_build_context_synchronously
                                    _showErrorDialog(context);
                                  }
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFFFF8500),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(24 * scaleFactor),
                                  ),
                                  padding: EdgeInsets.symmetric(
                                    horizontal: 16 * scaleFactor,
                                    vertical: 8 * scaleFactor,
                                  ),
                                ),
                                child: Text(
                                  'Login',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 15 * scaleFactor,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: 20 * scaleFactor),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _showErrorDialog(BuildContext context) {
    AwesomeDialog(
      context: context,
      dialogType: DialogType.error,
      animType: AnimType.bottomSlide,
      title: 'Login Failed',
      desc: 'Invalid credentials. Please try again.',
      btnOkOnPress: () {},
      btnOkColor: Colors.red,
    ).show();
  }

  Widget _buildTextField({
    required String labelText,
    required String iconPath,
    required TextEditingController controller,
    required double scaleFactor,
  }) {
    return SizedBox(
      width: 340 * scaleFactor, // Reduced width
      height: 50 * scaleFactor, // Reduced height
      child: TextField(
        controller: controller,
        cursorColor: const Color(0xFF172B4D),
        style: TextStyle(
          color: const Color(0xFF172B4D),
          fontSize: 13 * scaleFactor, // Smaller font
        ),
        decoration: InputDecoration(
          labelText: labelText,
          labelStyle: TextStyle(
            color: const Color(0xFF172B4D),
            fontSize: 13 * scaleFactor, // Smaller font
          ),
          floatingLabelStyle: TextStyle(
            color: Colors.grey,
            fontSize: 12 * scaleFactor, // Smaller font
          ),
          filled: true,
          fillColor: Colors.white,
          isDense: true, // More compact
          contentPadding: EdgeInsets.symmetric(
            horizontal: 12 * scaleFactor, // Reduced padding
            vertical: 10 * scaleFactor, // Reduced padding
          ),
          suffixIcon: Padding(
            padding: EdgeInsets.all(8.0 * scaleFactor), // Reduced padding
            child: Image.asset(
              iconPath,
              width: 16 * scaleFactor, // Smaller icon
              height: 16 * scaleFactor, // Smaller icon
              fit: BoxFit.contain,
            ),
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(4 * scaleFactor), // Smaller radius
            borderSide: const BorderSide(color: Colors.grey),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(4 * scaleFactor), // Smaller radius
            borderSide: const BorderSide(color: Colors.grey),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(4 * scaleFactor), // Smaller radius
            borderSide: const BorderSide(color: Colors.grey, width: 1.5), // Thinner border
          ),
        ),
      ),
    );
  }

  Widget _buildPasswordField({
    required TextEditingController controller,
    required bool isPasswordVisible,
    required VoidCallback onToggleVisibility,
    required double scaleFactor,
  }) {
    return SizedBox(
      width: 340 * scaleFactor, // Reduced width
      height: 50 * scaleFactor, // Reduced height
      child: TextField(
        controller: controller,
        obscureText: !isPasswordVisible,
        cursorColor: const Color(0xFF172B4D),
        style: TextStyle(
          color: const Color(0xFF172B4D),
          fontSize: 13 * scaleFactor, // Smaller font
        ),
        decoration: InputDecoration(
          labelText: 'Password',
          labelStyle: TextStyle(
            color: const Color(0xFF172B4D),
            fontSize: 13 * scaleFactor, // Smaller font
          ),
          floatingLabelStyle: TextStyle(
            color: Colors.grey,
            fontSize: 12 * scaleFactor, // Smaller font
          ),
          filled: true,
          fillColor: Colors.white,
          isDense: true, // More compact
          contentPadding: EdgeInsets.symmetric(
            horizontal: 12 * scaleFactor, // Reduced padding
            vertical: 10 * scaleFactor, // Reduced padding
          ),
          suffixIcon: IconButton(
            iconSize: 20 * scaleFactor, // Smaller icon
            padding: EdgeInsets.all(8 * scaleFactor), // Reduced padding
            constraints: BoxConstraints(), // Remove constraints
            icon: Icon(
              isPasswordVisible ? Icons.visibility : Icons.visibility_off,
              color: const Color(0xFFFF8500),
            ),
            onPressed: onToggleVisibility,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(4 * scaleFactor), // Smaller radius
            borderSide: const BorderSide(color: Colors.grey),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(4 * scaleFactor), // Smaller radius
            borderSide: const BorderSide(color: Colors.grey),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(4 * scaleFactor), // Smaller radius
            borderSide: const BorderSide(color: Colors.grey, width: 1.5), // Thinner border
          ),
        ),
      ),
    );
  }
}