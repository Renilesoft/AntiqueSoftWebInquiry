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

class _LoginScreenState extends State<LoginScreen> {
  bool isUsingStoreCode = true;

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
                SvgPicture.asset(
                  'assets/logo.svg',
                  height: 130 * scaleFactor,
                  fit: BoxFit.contain,
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
                    SizedBox(
                      width: 366 * scaleFactor,
                      child: Row(children: []),
                    ),
                    SizedBox(height: 11 * scaleFactor),
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
                        ],
                      ),
                    ),
                    SizedBox(height: 16 * scaleFactor),

                    /// ✅ Button or Loading Spinner
                    loginViewModel.isLoading
                        ? const CircularProgressIndicator()
                        : SizedBox(
                            width: 173 * scaleFactor,
                            height: 64 * scaleFactor,
                            child: ElevatedButton(
                              onPressed: () async {
                                bool success = await loginViewModel.login(context);
                                if (!success) {
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
