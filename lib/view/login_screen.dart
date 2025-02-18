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
    final screenWidth = MediaQuery.of(context).size.width;
    
    // Calculate scale factor to maintain phone proportions
    double scaleFactor = screenWidth / 400; // 390 is base iPhone width
    
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: SingleChildScrollView(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 24.0 * scaleFactor),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                SizedBox(height: 80 * scaleFactor),
                // Animated Logo Section
                SlideTransition(
                  position: _logoSlideAnimation,
                  child: FadeTransition(
                    opacity: _logoFadeAnimation,
                    child: SvgPicture.asset(
                      'assets/logo.svg',
                      height: 200 * scaleFactor,
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
                SizedBox(height: 40 * scaleFactor),
                // Animated Form Section
                SlideTransition(
                  position: _formSlideAnimation,
                  child: FadeTransition(
                    opacity: _formFadeAnimation,
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
                        SizedBox(height: 23* scaleFactor),
                        _buildTextField(
                          labelText: 'User Id',
                          iconPath: 'assets/user.png',
                          controller: loginViewModel.usernameController,
                          scaleFactor: scaleFactor,
                          
                        ),
                        SizedBox(height: 23 * scaleFactor),
                        _buildPasswordField(
                          controller: loginViewModel.passwordController,
                          isPasswordVisible: loginViewModel.isPasswordVisible,
                          onToggleVisibility: loginViewModel.togglePasswordVisibility,
                          scaleFactor: scaleFactor,
                        ),
                        SizedBox(height: 8 * scaleFactor),
                        SizedBox(
                          width: 366 * scaleFactor,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  Transform.scale(
                                    scale: scaleFactor,
                                    child: Checkbox(
                                      value: loginViewModel.rememberMe,
                                      onChanged: (_) => loginViewModel.toggleRememberMe(),
                                      activeColor: const Color(0xFF172B4D),
                                    ),
                                  ),
                                  Text(
                                    'Remember me',
                                    style: TextStyle(
                                      decoration: TextDecoration.underline,
                                      fontSize: 14 * scaleFactor,
                                      color: const Color(0xFF172B4D),
                                    ),
                                  ),
                                ],
                              ),
                              TextButton(
                                onPressed: () {},
                                child: Text(
                                  'Forgot password',
                                  style: TextStyle(
                                    decoration: TextDecoration.underline,
                                    fontSize: 14 * scaleFactor,
                                    color: const Color(0xFF172B4D),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        SizedBox(height: 16 * scaleFactor),
                        SizedBox(
                          width: 173 * scaleFactor,
                          height: 64 * scaleFactor,
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
                                borderRadius: BorderRadius.circular(30 * scaleFactor),
                              ),
                              padding: EdgeInsets.symmetric(
                                horizontal: 20 * scaleFactor,
                                vertical: 10 * scaleFactor,
                              ),
                            ),
                            child: Text(
                              'Login',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16 * scaleFactor,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                SizedBox(height: 20 * scaleFactor),
              ],
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
      width: 366 * scaleFactor,
      height: 60 * scaleFactor,
      child: TextField(
        controller: controller,
        cursorColor: const Color(0xFF172B4D),
        style: TextStyle(
          color: const Color(0xFF172B4D),
          fontSize: 14 * scaleFactor,
        ),
        decoration: InputDecoration(
          labelText: labelText,
          labelStyle: TextStyle(
            color: const Color(0xFF172B4D),
            fontSize: 14 * scaleFactor,
          ),
          floatingLabelStyle: TextStyle(
            color: Colors.grey,
            fontSize: 14 * scaleFactor,
          ),
          filled: true,
          fillColor: Colors.white,
          contentPadding: EdgeInsets.symmetric(
            horizontal: 16 * scaleFactor,
            vertical: 12 * scaleFactor,
          ),
          suffixIcon: Padding(
            padding: EdgeInsets.all(12.0 * scaleFactor), // Reduced padding to accommodate larger icon
            child: Image.asset(
              iconPath,
              width: 18 * scaleFactor,  // Increased from 24 to 32
              height: 18 * scaleFactor, // Increased from 24 to 32
              fit: BoxFit.contain,      // Added to ensure proper scaling
            ),
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(5 * scaleFactor),
            borderSide: const BorderSide(color: Colors.grey),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(5 * scaleFactor),
            borderSide: const BorderSide(color: Colors.grey),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(5 * scaleFactor),
            borderSide: const BorderSide(color: Colors.grey, width: 2),
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
      width: 366 * scaleFactor,
      height: 60 * scaleFactor,
      child: TextField(
        controller: controller,
        obscureText: !isPasswordVisible,
        cursorColor: const Color(0xFF172B4D),
        style: TextStyle(
          color: const Color(0xFF172B4D),
          fontSize: 14 * scaleFactor,
        ),
        decoration: InputDecoration(
          labelText: 'Password',
          labelStyle: TextStyle(
            color: const Color(0xFF172B4D),
            fontSize: 14 * scaleFactor,
          ),
          floatingLabelStyle: TextStyle(
            color: Colors.grey,
            fontSize: 14 * scaleFactor,
          ),
          filled: true,
          fillColor: Colors.white,
          contentPadding: EdgeInsets.symmetric(
            horizontal: 16 * scaleFactor,
            vertical: 12 * scaleFactor,
          ),
          suffixIcon: IconButton(
            iconSize: 24 * scaleFactor,
            padding: EdgeInsets.all(12 * scaleFactor),
            icon: Icon(
              isPasswordVisible ? Icons.visibility : Icons.visibility_off,
              color: const Color(0xFFFF8500),
            ),
            onPressed: onToggleVisibility,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(5 * scaleFactor),
            borderSide: const BorderSide(color: Colors.grey),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(5 * scaleFactor),
            borderSide: const BorderSide(color: Colors.grey),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(5 * scaleFactor),
            borderSide: const BorderSide(color: Colors.grey, width: 2),
          ),
        ),
      ),
    );
  }
}