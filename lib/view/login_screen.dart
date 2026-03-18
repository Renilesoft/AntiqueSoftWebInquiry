import 'package:antiquewebemquiry/app_data.dart';
import 'package:antiquewebemquiry/Services/notification.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';
import 'package:quickalert/quickalert.dart';
import '../viewmodel/login_viewmodel.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => LoginViewModel()),
        ChangeNotifierProvider(create: (_) => AppData()),
      ],
      child: const _LoginScreenContent(),
    );
  }
}

class _LoginScreenContent extends StatefulWidget {
  const _LoginScreenContent();

  @override
  State<_LoginScreenContent> createState() => _LoginScreenContentState();
}

class _LoginScreenContentState extends State<_LoginScreenContent> {
  bool isUsingStoreCode = true;
  
  // Focus nodes to track focus state
  final FocusNode _storeCodeFocusNode = FocusNode();
  final FocusNode _userIdFocusNode = FocusNode();
  final FocusNode _passwordFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<LoginViewModel>().restoreSavedCredentials();
    });
  }

  @override
  void dispose() {
    _storeCodeFocusNode.dispose();
    _userIdFocusNode.dispose();
    _passwordFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final loginViewModel = context.watch<LoginViewModel>();
    final screenSize = MediaQuery.of(context).size;
    final screenWidth = screenSize.width;
    final screenHeight = screenSize.height;
    
    // Comprehensive responsive breakpoints
    bool isMobile = screenWidth < 600;
    bool isTablet = screenWidth >= 600 && screenWidth < 1024;
    
    // Dynamic sizing based on device type
    double getResponsiveValue({
      required double mobile,
      required double tablet,
      required double desktop,
    }) {
      if (isMobile) return mobile;
      if (isTablet) return tablet;
      return desktop;
    }
    
    // Container width that maintains aspect ratio
    double getContainerWidth() {
      if (isMobile) {
        return screenWidth * 0.9; // 90% of screen width
      } else if (isTablet) {
        return screenWidth * 0.6; // 60% for tablets
      } else {
        return 450; // Fixed width for desktop
      }
    }
    
    // Responsive padding
    double getHorizontalPadding() {
      return getResponsiveValue(
        mobile: 20.0,
        tablet: 40.0,
        desktop: 60.0,
      );
    }
    
    double getVerticalPadding() {
      return getResponsiveValue(
        mobile: 20.0,
        tablet: 40.0,
        desktop: 30.0,
      );
    }

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: EdgeInsets.symmetric(
              horizontal: getHorizontalPadding(),
              vertical: getVerticalPadding(),
            ),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: getContainerWidth(),
                minHeight: screenHeight * 0.7, // Minimum height for proper centering
              ),
              child: IntrinsicHeight(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    SizedBox(height: getResponsiveValue(
                      mobile: 20,
                      tablet: 40,
                      desktop: 60,
                    )),
                    
                    
                    _buildLogoSection(),
                    
                    SizedBox(height: getResponsiveValue(
                      mobile: 40,
                      tablet: 60,
                      desktop: 80,
                    )),
                    
                    
                    _buildFormSection(loginViewModel),
                    
                    SizedBox(height: getResponsiveValue(
                      mobile: 20,
                      tablet: 30,
                      desktop: 40,
                    )),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLogoSection() {
    final screenWidth = MediaQuery.of(context).size.width;
    
    // Responsive logo size
    double getLogoSize() {
      if (screenWidth < 600) return 130; // Mobile
      if (screenWidth < 1024) return 180; // Tablet
      return 160; // Desktop
    }
    
    // Responsive title font sizes
    double getMainTitleSize() {
      if (screenWidth < 600) return 24; // Mobile
      if (screenWidth < 1024) return 32; // Tablet
      return 36; // Desktop
    }
    
    double getSubTitleSize() {
      if (screenWidth < 600) return 24; // Mobile
      if (screenWidth < 1024) return 32; // Tablet
      return 22; // Desktop
    }
    
    return Column(
      children: [
        // Responsive logo with container
        Container(
          width: getLogoSize(),
          height: getLogoSize(),
          padding: EdgeInsets.all(screenWidth < 600 ? 12 : 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(screenWidth < 600 ? 16 : 20),
            boxShadow: [
              BoxShadow(
                // ignore: deprecated_member_use
                color: Colors.black.withOpacity(0.05),
                blurRadius: screenWidth < 600 ? 8 : 12,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: SvgPicture.asset(
            'assets/logo.svg',
            fit: BoxFit.contain,
          ),
        ),
        
        SizedBox(height: screenWidth < 600 ? 20 : 28),
        
        // Responsive app title
        Column(
          children: [
            Text(
              'AntiqueSoft',
              style: TextStyle(
                fontSize: getMainTitleSize(),
                fontWeight: FontWeight.bold,
                color: const Color(0xFF0C2A5D),
                letterSpacing: 0.5,
              ),
            ),
            SizedBox(height: screenWidth < 600 ? 1 : 2),
            Text(
              'Web Inquiry',
              style: TextStyle(
                fontSize: getSubTitleSize(),
                fontWeight: FontWeight.bold,
                color: const Color(0xFF0C2A5D),
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildFormSection(LoginViewModel loginViewModel) {
    final screenWidth = MediaQuery.of(context).size.width;
    
    // Responsive spacing
    double getFieldSpacing() {
      if (screenWidth < 600) return 16; // Mobile
      if (screenWidth < 1024) return 24; // Tablet
      return 28; // Desktop
    }
    
    double getCheckboxSpacing() {
      if (screenWidth < 600) return 12; // Mobile
      if (screenWidth < 1024) return 16; // Tablet
      return 20; // Desktop
    }
    
    double getButtonSpacing() {
      if (screenWidth < 600) return 28; // Mobile
      if (screenWidth < 1024) return 36; // Tablet
      return 44; // Desktop
    }
    
    return Column(
      children: [
        _buildTextFieldWithSvg(
          labelText: isUsingStoreCode ? 'Store Code or Vendor Name' : 'Vendor Name',
          svgPath: 'assets/store.svg',
          controller: loginViewModel.storeCodeController,
          focusNode: _storeCodeFocusNode,
        ),
        
        SizedBox(height: getFieldSpacing()),
        
        _buildTextFieldWithSvg(
          labelText: 'User Id',
          svgPath: 'assets/user.svg',
          controller: loginViewModel.usernameController,
          focusNode: _userIdFocusNode,
        ),
        
        SizedBox(height: getFieldSpacing()),
        
        _buildPasswordField(
          controller: loginViewModel.passwordController,
          isPasswordVisible: loginViewModel.isPasswordVisible,
          onToggleVisibility: loginViewModel.togglePasswordVisibility,
          focusNode: _passwordFocusNode,
        ),
        
        SizedBox(height: getCheckboxSpacing()),
        
        // Responsive remember me checkbox
        Row(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            Transform.scale(
              scale: screenWidth < 600 ? 1.0 : 1.2,
              child: Checkbox(
                value: loginViewModel.rememberMe,
                onChanged: (_) => loginViewModel.toggleRememberMe(),
                activeColor: const Color(0xFF172B4D),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
            SizedBox(width: screenWidth < 600 ? 1 : 2),
            Text(
              'Remember me',
              style: TextStyle(
                fontSize: screenWidth < 600 ? 14 : 16,
                color: const Color(0xFF172B4D),
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        
        SizedBox(height: getButtonSpacing()),
        
        // Responsive login button
        loginViewModel.isLoading
            ? CircularProgressIndicator(
                valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFFFF8500)),
                strokeWidth: screenWidth < 600 ? 3.0 : 4.0,
              )
            : SizedBox(
                width: double.infinity,
                height: screenWidth < 600 ? 52 : 60,
                child: ElevatedButton(
                  onPressed: () async {
                    bool success = await loginViewModel.login(context);
                    if (!success) _showErrorDialog(context);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFF8500),
                    elevation: 2,
                    // ignore: deprecated_member_use
                    shadowColor: const Color(0xFFFF8500).withOpacity(0.3),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(screenWidth < 600 ? 26 : 30),
                    ),
                  ),
                  child: Text(
                    'Login',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: screenWidth < 600 ? 16 : 18,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ),
        
        SizedBox(height: getCheckboxSpacing()),
        
        // Test Notification Button
        SizedBox(
          width: double.infinity,
          height: screenWidth < 600 ? 52 : 60,
          child: OutlinedButton(
            onPressed: () async {
              await NotificationService().showLocalNotification(
                title: "Test Notification",
                body: "This is a test local notification"
              );
            },
            style: OutlinedButton.styleFrom(
              side: const BorderSide(
                color: Color(0xFFFF8500),
                width: 2,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(screenWidth < 600 ? 26 : 30),
              ),
            ),
            child: Text(
              'Test Notification',
              style: TextStyle(
                color: const Color(0xFFFF8500),
                fontSize: screenWidth < 600 ? 16 : 18,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.5,
              ),
            ),
          ),
        ),
      ],
    );
  }

  void _showErrorDialog(BuildContext context) {
    QuickAlert.show(
      context: context,
      type: QuickAlertType.error,
      title: 'Login Failed',
      text: 'Invalid credentials. Please try again.',
      confirmBtnText: 'OK',
      confirmBtnColor: Colors.red,
      onConfirmBtnTap: () {
        Navigator.of(context).pop();
      },
    );
  }

  Widget _buildTextFieldWithSvg({
    required String labelText,
    required String svgPath,
    required TextEditingController controller,
    required FocusNode focusNode,
  }) {
    return AnimatedBuilder(
      animation: focusNode,
      builder: (context, child) {
        final bool isFocused = focusNode.hasFocus;
        final Color textColor = isFocused ? const Color(0xFFFF8500) : const Color(0xFF172B4D);
        final screenWidth = MediaQuery.of(context).size.width;
        
        // Responsive text field dimensions
        double getFieldHeight() {
          if (screenWidth < 600) return 56; // Mobile
          if (screenWidth < 1024) return 64; // Tablet
          return 68; // Desktop
        }
        
        double getTextSize() {
          if (screenWidth < 600) return 15; // Mobile
          if (screenWidth < 1024) return 16; // Tablet
          return 17; // Desktop
        }
        
        double getLabelSize() {
          if (screenWidth < 600) return 14; // Mobile
          if (screenWidth < 1024) return 15; // Tablet
          return 16; // Desktop
        }
        
        double getIconSize() {
          if (screenWidth < 600) return 18; // Mobile
          if (screenWidth < 1024) return 20; // Tablet
          return 22; // Desktop
        }
        
        double getBorderRadius() {
          if (screenWidth < 600) return 10; // Mobile
          if (screenWidth < 1024) return 12; // Tablet
          return 14; // Desktop
        }
        
        return SizedBox(
          height: getFieldHeight(),
          child: TextField(
            controller: controller,
            focusNode: focusNode,
            cursorColor: const Color(0xFFFF8500),
            style: TextStyle(
              color: textColor,
              fontSize: getTextSize(),
              fontWeight: FontWeight.w500,
            ),
            decoration: InputDecoration(
              labelText: labelText,
              labelStyle: TextStyle(
                // ignore: deprecated_member_use
                color: const Color(0xFF172B4D).withOpacity(0.7),
                fontSize: getLabelSize(),
                fontWeight: FontWeight.w500,
              ),
              floatingLabelStyle: TextStyle(
                color: const Color(0xFFFF8500),
                fontSize: getLabelSize(),
                fontWeight: FontWeight.w600,
              ),
              filled: true,
              fillColor: Colors.grey.shade50,
              contentPadding: EdgeInsets.symmetric(
                horizontal: screenWidth < 600 ? 16 : 20,
                vertical: screenWidth < 600 ? 16 : 20,
              ),
              suffixIcon: Container(
                padding: EdgeInsets.all(screenWidth < 600 ? 14 : 16),
                child: SvgPicture.asset(
                  svgPath,
                  width: getIconSize(),
                  height: getIconSize(),
                  colorFilter: const ColorFilter.mode(
                    Color(0xFFFF8500),
                    BlendMode.srcIn,
                  ),
                ),
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(getBorderRadius()),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(getBorderRadius()),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(getBorderRadius()),
                borderSide: const BorderSide(
                  color: Color(0xFFFF8500),
                  width: 2,
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildPasswordField({
    required TextEditingController controller,
    required bool isPasswordVisible,
    required VoidCallback onToggleVisibility,
    required FocusNode focusNode,
  }) {
    return AnimatedBuilder(
      animation: focusNode,
      builder: (context, child) {
        final bool isFocused = focusNode.hasFocus;
        final Color textColor = isFocused ? const Color(0xFFFF8500) : const Color(0xFF172B4D);
        final screenWidth = MediaQuery.of(context).size.width;
        
        // Responsive password field dimensions
        double getFieldHeight() {
          if (screenWidth < 600) return 56; // Mobile
          if (screenWidth < 1024) return 64; // Tablet
          return 68; // Desktop
        }
        
        double getTextSize() {
          if (screenWidth < 600) return 15; // Mobile
          if (screenWidth < 1024) return 16; // Tablet
          return 17; // Desktop
        }
        
        double getLabelSize() {
          if (screenWidth < 600) return 14; // Mobile
          if (screenWidth < 1024) return 15; // Tablet
          return 16; // Desktop
        }
        
        double getIconSize() {
          if (screenWidth < 600) return 22; // Mobile
          if (screenWidth < 1024) return 24; // Tablet
          return 26; // Desktop
        }
        
        double getBorderRadius() {
          if (screenWidth < 600) return 10; // Mobile
          if (screenWidth < 1024) return 12; // Tablet
          return 14; // Desktop
        }
        
        return SizedBox(
          height: getFieldHeight(),
          child: TextField(
            controller: controller,
            focusNode: focusNode,
            obscureText: !isPasswordVisible,
            cursorColor: const Color(0xFFFF8500),
            style: TextStyle(
              color: textColor,
              fontSize: getTextSize(),
              fontWeight: FontWeight.w500,
            ),
            decoration: InputDecoration(
              labelText: 'Password',
              labelStyle: TextStyle(
                // ignore: deprecated_member_use
                color: const Color(0xFF172B4D).withOpacity(0.7),
                fontSize: getLabelSize(),
                fontWeight: FontWeight.w500,
              ),
              floatingLabelStyle: TextStyle(
                color: const Color(0xFFFF8500),
                fontSize: getLabelSize(),
                fontWeight: FontWeight.w600,
              ),
              filled: true,
              fillColor: Colors.grey.shade50,
              contentPadding: EdgeInsets.symmetric(
                horizontal: screenWidth < 600 ? 16 : 20,
                vertical: screenWidth < 600 ? 16 : 20,
              ),
              suffixIcon: IconButton(
                iconSize: getIconSize(),
                padding: EdgeInsets.all(screenWidth < 600 ? 14 : 16),
                icon: Icon(
                  isPasswordVisible ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                  color: const Color(0xFFFF8500),
                ),
                onPressed: onToggleVisibility,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(getBorderRadius()),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(getBorderRadius()),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(getBorderRadius()),
                borderSide: const BorderSide(
                  color: Color(0xFFFF8500),
                  width: 2,
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}