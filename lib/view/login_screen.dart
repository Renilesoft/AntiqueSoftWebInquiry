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

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<LoginViewModel>().restoreSavedCredentials();
    });
  }

  @override
  Widget build(BuildContext context) {
    final loginViewModel = context.watch<LoginViewModel>();
    final screenWidth = MediaQuery.of(context).size.width;
    double scaleFactor = screenWidth / 422;

    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: SingleChildScrollView(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 22.0 * scaleFactor),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                SizedBox(height: 80 * scaleFactor),
                Column(
                  children: [
                    // ⭐ NEW RESPONSIVE LOGO ⭐
                    Padding(
                      padding: EdgeInsets.symmetric(vertical: 20 * scaleFactor),
                      child: LayoutBuilder(
                        builder: (context, constraints) {
                          double logoWidth = constraints.maxWidth * 0.45;
                          return Center(
                            child: SvgPicture.asset(
                              'assets/logo.svg',
                              width: logoWidth,
                              fit: BoxFit.contain,
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 7),
                    RichText(
                      textAlign: TextAlign.center,
                      text: const TextSpan(
                        style: TextStyle(fontSize: 18, fontFamily: 'Arial'),
                        children: [
                          TextSpan(
                            text: 'AntiqueSoft\n',
                            style: TextStyle(
                              color: Color(0xFF0C2A5D),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          TextSpan(
                            text: 'Web Inquiry',
                            style: TextStyle(
                              color: Color(0xFF0C2A5D),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 38 * scaleFactor),
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    _buildTextFieldWithSvg(
                      labelText: isUsingStoreCode ? 'Store Code or Vendor Name' : 'Vendor Name',
                      svgPath: 'assets/store.svg',
                      controller: loginViewModel.storeCodeController,
                      scaleFactor: scaleFactor,
                    ),
                    SizedBox(height: 12 * scaleFactor),
                    _buildTextFieldWithSvg(
                      labelText: 'User Id',
                      svgPath: 'assets/user.svg',
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
                        mainAxisAlignment: MainAxisAlignment.start,
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
                    ),
                    SizedBox(height: 16 * scaleFactor),
                    loginViewModel.isLoading
                        ? const CircularProgressIndicator()
                        : SizedBox(
                            width: 173 * scaleFactor,
                            height: 64 * scaleFactor,
                            child: ElevatedButton(
                              onPressed: () async {
                                bool success = await loginViewModel.login(context);
                                if (!success) _showErrorDialog(context);
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
                SizedBox(height: 20 * scaleFactor),
              ],
            ),
          ),
        ),
      ),
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
            padding: EdgeInsets.all(12.0 * scaleFactor),
            child: SvgPicture.asset(
              svgPath,
              width: 18 * scaleFactor,
              height: 18 * scaleFactor,
              fit: BoxFit.contain,
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
            iconSize: 28 * scaleFactor,
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