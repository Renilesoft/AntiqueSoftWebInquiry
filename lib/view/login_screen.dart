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
    // ignore: unused_local_variable
    final screenSize = MediaQuery.of(context).size;
    final responsive = ResponsiveValues(context);
    
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: SingleChildScrollView(
          child: Container(
            width: responsive.formWidth,
            padding: EdgeInsets.symmetric(horizontal: responsive.horizontalPadding),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                SizedBox(height: responsive.verticalSpacing * 2),
                // Animated Logo Section
                SlideTransition(
                  position: _logoSlideAnimation,
                  child: FadeTransition(
                    opacity: _logoFadeAnimation,
                    child: SvgPicture.asset(
                      'assets/logo.svg',
                      height: responsive.logoHeight,
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
                SizedBox(height: responsive.verticalSpacing),
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
                          responsive: responsive,
                        ),
                        SizedBox(height: responsive.fieldSpacing),
                        _buildTextField(
                          labelText: 'User Id',
                          iconPath: 'assets/user.png',
                          controller: loginViewModel.usernameController,
                          responsive: responsive,
                        ),
                        SizedBox(height: responsive.fieldSpacing),
                        _buildPasswordField(
                          controller: loginViewModel.passwordController,
                          isPasswordVisible: loginViewModel.isPasswordVisible,
                          onToggleVisibility: loginViewModel.togglePasswordVisibility,
                          responsive: responsive,
                        ),
                        SizedBox(height: responsive.smallSpacing),
                        SizedBox(
                          width: responsive.fieldWidth,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  Transform.scale(
                                    scale: responsive.checkboxScale,
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
                                      fontSize: responsive.smallTextSize,
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
                                    fontSize: responsive.smallTextSize,
                                    color: const Color(0xFF172B4D),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        SizedBox(height: responsive.verticalSpacing),
                        SizedBox(
                          width: responsive.buttonWidth,
                          height: responsive.buttonHeight,
                          child: ElevatedButton(
                            onPressed: () async {
                              bool success = await loginViewModel.login(context);
                              if (!success) {
                                // ignore: use_build_context_synchronously
                                _showErrorDialog(context, responsive);
                              }
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFFF8500),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(responsive.borderRadius * 6),
                              ),
                              padding: EdgeInsets.symmetric(
                                horizontal: responsive.horizontalPadding,
                                vertical: responsive.smallSpacing,
                              ),
                            ),
                            child: Text(
                              'Login',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: responsive.buttonTextSize,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                SizedBox(height: responsive.verticalSpacing),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showErrorDialog(BuildContext context, ResponsiveValues responsive) {
    AwesomeDialog(
      context: context,
      dialogType: DialogType.error,
      animType: AnimType.bottomSlide,
      title: 'Login Failed',
      desc: 'Invalid credentials. Please try again.',
      btnOkOnPress: () {},
      btnOkColor: Colors.red,
      titleTextStyle: TextStyle(fontSize: responsive.dialogTitleSize),
      descTextStyle: TextStyle(fontSize: responsive.dialogTextSize),
    ).show();
  }

  Widget _buildTextField({
    required String labelText,
    required String iconPath,
    required TextEditingController controller,
    required ResponsiveValues responsive,
  }) {
    return SizedBox(
      width: responsive.fieldWidth,
      height: responsive.fieldHeight,
      child: TextField(
        controller: controller,
        cursorColor: const Color(0xFF172B4D),
        style: TextStyle(
          color: const Color(0xFF172B4D),
          fontSize: responsive.inputTextSize,
        ),
        decoration: InputDecoration(
          labelText: labelText,
          labelStyle: TextStyle(
            color: const Color(0xFF172B4D),
            fontSize: responsive.inputTextSize,
          ),
          floatingLabelStyle: TextStyle(
            color: Colors.grey,
            fontSize: responsive.inputTextSize,
          ),
          filled: true,
          fillColor: Colors.white,
          contentPadding: EdgeInsets.symmetric(
            horizontal: responsive.contentPadding,
            vertical: responsive.contentPadding * 0.75,
          ),
          suffixIcon: Padding(
            padding: EdgeInsets.all(responsive.iconPadding),
            child: Image.asset(
              iconPath,
              width: responsive.iconSize,
              height: responsive.iconSize,
              fit: BoxFit.contain,
            ),
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(responsive.borderRadius),
            borderSide: const BorderSide(color: Colors.grey),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(responsive.borderRadius),
            borderSide: const BorderSide(color: Colors.grey),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(responsive.borderRadius),
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
    required ResponsiveValues responsive,
  }) {
    return SizedBox(
      width: responsive.fieldWidth,
      height: responsive.fieldHeight,
      child: TextField(
        controller: controller,
        obscureText: !isPasswordVisible,
        cursorColor: const Color(0xFF172B4D),
        style: TextStyle(
          color: const Color(0xFF172B4D),
          fontSize: responsive.inputTextSize,
        ),
        decoration: InputDecoration(
          labelText: 'Password',
          labelStyle: TextStyle(
            color: const Color(0xFF172B4D),
            fontSize: responsive.inputTextSize,
          ),
          floatingLabelStyle: TextStyle(
            color: Colors.grey,
            fontSize: responsive.inputTextSize,
          ),
          filled: true,
          fillColor: Colors.white,
          contentPadding: EdgeInsets.symmetric(
            horizontal: responsive.contentPadding,
            vertical: responsive.contentPadding * 0.75,
          ),
          suffixIcon: IconButton(
            iconSize: responsive.iconSize,
            padding: EdgeInsets.all(responsive.iconPadding),
            icon: Icon(
              isPasswordVisible ? Icons.visibility : Icons.visibility_off,
              color: const Color(0xFFFF8500),
            ),
            onPressed: onToggleVisibility,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(responsive.borderRadius),
            borderSide: const BorderSide(color: Colors.grey),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(responsive.borderRadius),
            borderSide: const BorderSide(color: Colors.grey),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(responsive.borderRadius),
            borderSide: const BorderSide(color: Colors.grey, width: 2),
          ),
        ),
      ),
    );
  }
}

/// A class to handle responsive values across different device sizes
class ResponsiveValues {
  final BuildContext context;
  late final double _screenWidth;
  // ignore: unused_field
  late final bool _isTablet;
  // ignore: unused_field
  late final bool _isDesktop;
  late final DeviceType _deviceType;

  ResponsiveValues(this.context) {
    final size = MediaQuery.of(context).size;
    _screenWidth = size.width;
    
    // Determine device type based on width, aspect ratio, and platform
    if (_screenWidth >= 1200) {
      _deviceType = DeviceType.desktop;
      _isTablet = false;
      _isDesktop = true;
    } else if (_screenWidth >= 600) {
      _deviceType = DeviceType.tablet;
      _isTablet = true;
      _isDesktop = false;
    } else {
      _deviceType = DeviceType.mobile;
      _isTablet = false;
      _isDesktop = false;
    }
  }

  DeviceType get deviceType => _deviceType;
  
  // Base dimensions for a smartphone layout (iPhone-like)
  static const double _baseWidth = 390.0;
  
  // Calculate factor but with upper limits to prevent overgrowth on large screens
  double get _getScaleFactor {
    switch (_deviceType) {
      case DeviceType.mobile:
        return _screenWidth / _baseWidth;
      case DeviceType.tablet:
        return (_screenWidth / _baseWidth).clamp(0.8, 1.2);
      case DeviceType.desktop:
        return (_screenWidth / _baseWidth).clamp(0.8, 1.3);
    }
  }
  
  // Density factor helps us reduce the size on tablets and desktops
  double get _getDensityFactor {
    switch (_deviceType) {
      case DeviceType.mobile:
        return 1.0;
      case DeviceType.tablet:
        return 0.7; // Reduce form elements size on tablets
      case DeviceType.desktop:
        return 0.6; // Reduce even more on desktop
    }
  }
  
  // Size for the content container
  double get formWidth {
    switch (_deviceType) {
      case DeviceType.mobile:
        return _screenWidth * 0.95;
      case DeviceType.tablet:
        return _screenWidth * 0.7;
      case DeviceType.desktop:
        return _screenWidth * 0.5;
    }
  }
  
  // Logo height
  double get logoHeight => 150.0 * _getScaleFactor * _getDensityFactor;
  
  // Field width
  double get fieldWidth {
    final baseWidth = 366.0 * _getScaleFactor * _getDensityFactor;
    switch (_deviceType) {
      case DeviceType.mobile:
        return baseWidth;
      case DeviceType.tablet:
      case DeviceType.desktop:
        return min(baseWidth, formWidth * 0.9);
    }
  }
  
  // Field height
  double get fieldHeight => 60.0 * _getScaleFactor * _getDensityFactor;
  
  // Button width
  double get buttonWidth => 173.0 * _getScaleFactor * _getDensityFactor;
  
  // Button height
  double get buttonHeight => 64.0 * _getScaleFactor * _getDensityFactor;
  
  // Spacings
  double get verticalSpacing => 40.0 * _getScaleFactor * _getDensityFactor;
  double get fieldSpacing => 23.0 * _getScaleFactor * _getDensityFactor;
  double get smallSpacing => 8.0 * _getScaleFactor * _getDensityFactor;
  double get horizontalPadding => 24.0 * _getScaleFactor * _getDensityFactor;
  
  // Text sizes
  double get inputTextSize => 14.0 * _getScaleFactor * _getDensityFactor;
  double get smallTextSize => 14.0 * _getScaleFactor * _getDensityFactor;
  double get buttonTextSize => 16.0 * _getScaleFactor * _getDensityFactor;
  
  // Dialog text sizes
  double get dialogTitleSize => 18.0 * _getScaleFactor * _getDensityFactor;
  double get dialogTextSize => 14.0 * _getScaleFactor * _getDensityFactor;
  
  // Other
  double get borderRadius => 5.0 * _getScaleFactor * _getDensityFactor;
  double get contentPadding => 16.0 * _getScaleFactor * _getDensityFactor;
  double get iconPadding => 12.0 * _getScaleFactor * _getDensityFactor;
  double get iconSize => 18.0 * _getScaleFactor * _getDensityFactor;
  double get checkboxScale => _getScaleFactor * _getDensityFactor;
}

// Helper function to find the minimum of two values
double min(double a, double b) => a < b ? a : b;

// Enum for device types
enum DeviceType {
  mobile,
  tablet,
  desktop,
}