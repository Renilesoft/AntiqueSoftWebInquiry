import 'package:antiquewebemquiry/app_data.dart';
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
    
    // Better responsive scaling approach
    double getResponsiveWidth() {
      if (screenSize.width > 600) return 400; // Tablet/Desktop
      return screenSize.width * 0.85; // Mobile
    }

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: getResponsiveWidth(),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const SizedBox(height: 40),
                  
                  // ⭐ IMPROVED LOGO SECTION ⭐
                  _buildLogoSection(),
                  
                  const SizedBox(height: 50),
                  
                  // Form fields with better spacing
                  _buildFormSection(loginViewModel),
                  
                  const SizedBox(height: 30),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLogoSection() {
    return Column(
      children: [
        // Logo with fixed, appropriate size
        Container(
          width: 120,
          height: 120,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: SvgPicture.asset(
            'assets/logo.svg',
            fit: BoxFit.contain,
          ),
        ),
        
        const SizedBox(height: 24),
        
        // App title with better typography
        const Column(
          children: [
            Text(
              'AntiqueSoft',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF0C2A5D),
                letterSpacing: 0.5,
              ),
            ),
            SizedBox(height: 4),
            Text(
              'Web Inquiry',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF0C2A5D),
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildFormSection(LoginViewModel loginViewModel) {
    return Column(
      children: [
        _buildTextFieldWithSvg(
          labelText: isUsingStoreCode ? 'Store Code or Vendor Name' : 'Vendor Name',
          svgPath: 'assets/store.svg',
          controller: loginViewModel.storeCodeController,
          focusNode: _storeCodeFocusNode,
        ),
        
        const SizedBox(height: 20),
        
        _buildTextFieldWithSvg(
          labelText: 'User Id',
          svgPath: 'assets/user.svg',
          controller: loginViewModel.usernameController,
          focusNode: _userIdFocusNode,
        ),
        
        const SizedBox(height: 20),
        
        _buildPasswordField(
          controller: loginViewModel.passwordController,
          isPasswordVisible: loginViewModel.isPasswordVisible,
          onToggleVisibility: loginViewModel.togglePasswordVisibility,
          focusNode: _passwordFocusNode,
        ),
        
        const SizedBox(height: 16),
        
        // Remember me checkbox
        Row(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            Transform.scale(
              scale: 1.1,
              child: Checkbox(
                value: loginViewModel.rememberMe,
                onChanged: (_) => loginViewModel.toggleRememberMe(),
                activeColor: const Color(0xFF172B4D),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              'Remember me',
              style: TextStyle(
                fontSize: 15,
                color: const Color(0xFF172B4D),
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        
        const SizedBox(height: 32),
        
        // Login button
        loginViewModel.isLoading
            ? const CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFFF8500)),
              )
            : SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: () async {
                    bool success = await loginViewModel.login(context);
                    if (!success) _showErrorDialog(context);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFF8500),
                    elevation: 2,
                    shadowColor: const Color(0xFFFF8500).withOpacity(0.3),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(28),
                    ),
                  ),
                  child: const Text(
                    'Login',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
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
        
        return SizedBox(
          height: 64,
          child: TextField(
            controller: controller,
            focusNode: focusNode,
            cursorColor: const Color(0xFFFF8500),
            style: TextStyle(
              color: textColor,
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
            decoration: InputDecoration(
              labelText: labelText,
              labelStyle: TextStyle(
                color: const Color(0xFF172B4D).withOpacity(0.7),
                fontSize: 15,
                fontWeight: FontWeight.w500,
              ),
              floatingLabelStyle: const TextStyle(
                color: Color(0xFFFF8500),
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
              filled: true,
              fillColor: Colors.grey.shade50,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 20,
                vertical: 20,
              ),
              suffixIcon: Container(
                padding: const EdgeInsets.all(16),
                child: SvgPicture.asset(
                  svgPath,
                  width: 20,
                  height: 20,
                  colorFilter: ColorFilter.mode(
                    const Color(0xFFFF8500),
                    BlendMode.srcIn,
                  ),
                ),
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
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
        
        return SizedBox(
          height: 64,
          child: TextField(
            controller: controller,
            focusNode: focusNode,
            obscureText: !isPasswordVisible,
            cursorColor: const Color(0xFFFF8500),
            style: TextStyle(
              color: textColor,
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
            decoration: InputDecoration(
              labelText: 'Password',
              labelStyle: TextStyle(
                color: const Color(0xFF172B4D).withOpacity(0.7),
                fontSize: 15,
                fontWeight: FontWeight.w500,
              ),
              floatingLabelStyle: const TextStyle(
                color: Color(0xFFFF8500),
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
              filled: true,
              fillColor: Colors.grey.shade50,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 20,
                vertical: 20,
              ),
              suffixIcon: IconButton(
                iconSize: 24,
                padding: const EdgeInsets.all(16),
                icon: Icon(
                  isPasswordVisible ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                  color: const Color(0xFFFF8500),
                ),
                onPressed: onToggleVisibility,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
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