import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class ChangePassword extends StatefulWidget {
  const ChangePassword({super.key});

  @override
  State<ChangePassword> createState() => _ChangePasswordState();
}

class _ChangePasswordState extends State<ChangePassword> {
  bool isShowOldPassword = true;
  bool isShowNewPassword = true;
  bool isShowConfirmPassword = true;
  bool isLoading = false; // Quản lý loading

  final _formKey = GlobalKey<FormState>();

  final TextEditingController _oldPasswordController = TextEditingController();
  final TextEditingController _newPasswordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();

  final FocusNode _oldPasswordFocus = FocusNode();
  final FocusNode _newPasswordFocus = FocusNode();
  final FocusNode _confirmPasswordFocus = FocusNode();

  @override
  void dispose() {
    _oldPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    _oldPasswordFocus.dispose();
    _newPasswordFocus.dispose();
    _confirmPasswordFocus.dispose();
    super.dispose();
  }

  // Hàm đổi mật khẩu với loading + validation
  Future<void> _changePassword() async {
// Bật tự động validate khi nhấn nút

    if (_formKey.currentState!.validate()) {
      setState(() => isLoading = true); // Hiển thị loading

      try {
        final user = FirebaseAuth.instance.currentUser;
        if (user == null) throw Exception("User not logged in");

        final credential = EmailAuthProvider.credential(
          email: user.email!,
          password: _oldPasswordController.text,
        );

        await user
            .reauthenticateWithCredential(credential); // Xác thực mật khẩu cũ
        await user
            .updatePassword(_newPasswordController.text); // Đổi mật khẩu mới

        setState(() => isLoading = false); // Ẩn loading khi thành công

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('🎉 Password changed successfully!'),
            backgroundColor: Colors.green,
          ),
        );

        Navigator.pop(context); // Quay lại màn trước
      } catch (e) {
  setState(() => isLoading = false);
  
  String errorMessage = 'An error occurred. Please try again.';
  if (e is FirebaseAuthException) {
    switch (e.code) {
      case 'invalid-credential':
        errorMessage = 'Old password is incorrect.';
        break;
      case 'weak-password':
        errorMessage = 'Password must be at least 6 characters'; // Đã xử lý trong validator
        break;
      default:
        errorMessage = e.message ?? errorMessage;
    }
  }

  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text('❌ Error: $errorMessage'),
      backgroundColor: Colors.redAccent,
    ),
  );
}
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Change Password'),
          centerTitle: true,
          backgroundColor: Colors.blueAccent,
        ),
        body: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Form(
              key: _formKey,
              autovalidateMode: AutovalidateMode
                  .onUserInteraction, // Validate khi người dùng tương tác
              child: Column(
                children: [
                  Center(
                    child: Image.asset(
                      "assets/images/logo.png",
                      width: 250.0,
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Old Password
                  TextFormField(
                    controller: _oldPasswordController,
                    focusNode: _oldPasswordFocus,
                    textInputAction: TextInputAction.next,
                    onFieldSubmitted: (_) =>
                        FocusScope.of(context).requestFocus(_newPasswordFocus),
                    decoration: InputDecoration(
                      labelText: 'Old Password',
                      prefixIcon: const Icon(Icons.password_outlined),
                      suffixIcon: InkWell(
                        onTap: () => setState(
                            () => isShowOldPassword = !isShowOldPassword),
                        child: Icon(isShowOldPassword
                            ? Icons.visibility_off
                            : Icons.visibility),
                      ),
                    ),
                    obscureText: isShowOldPassword,
                    validator: (value) => (value == null || value.isEmpty)
                        ? 'This field is required'
                        : null,
                  ),
                  const SizedBox(height: 12),

                  // New Password
                  TextFormField(
                    controller: _newPasswordController,
                    focusNode: _newPasswordFocus,
                    textInputAction: TextInputAction.next,
                    onFieldSubmitted: (_) => FocusScope.of(context)
                        .requestFocus(_confirmPasswordFocus),
                    decoration: InputDecoration(
                      labelText: 'New Password',
                      prefixIcon: const Icon(Icons.lock_outline),
                      suffixIcon: InkWell(
                        onTap: () => setState(
                            () => isShowNewPassword = !isShowNewPassword),
                        child: Icon(isShowNewPassword
                            ? Icons.visibility_off
                            : Icons.visibility),
                      ),
                    ),
                    obscureText: isShowNewPassword,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'This field is required';
                      }
                      if (value.length < 6) {
                        return 'Password must be at least 6 characters'; // Chỉ check độ dài
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),

                  // 🔑 Confirm Password
                  TextFormField(
                    controller: _confirmPasswordController,
                    focusNode: _confirmPasswordFocus,
                    textInputAction: TextInputAction.done,
                    decoration: InputDecoration(
                      labelText: 'Confirm Password',
                      prefixIcon: const Icon(Icons.lock_outline),
                      suffixIcon: InkWell(
                        onTap: () => setState(() =>
                            isShowConfirmPassword = !isShowConfirmPassword),
                        child: Icon(isShowConfirmPassword
                            ? Icons.visibility_off
                            : Icons.visibility),
                      ),
                    ),
                    obscureText: isShowConfirmPassword,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'This field is required';
                      }
                      if (value != _newPasswordController.text) {
                        return 'Passwords do not match';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 20),

                  // Change Password Button with Loading
                  ElevatedButton(
                    onPressed: isLoading
                        ? null
                        : _changePassword, // Ngăn nhấn khi đang loading
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 24, vertical: 14),
                      backgroundColor: Colors.blueAccent,
                    ),
                    child: isLoading
                        ? const SizedBox(
                            width: 26,
                            height: 26,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 3.0,
                            ),
                          )
                        : const Text(
                            'Change Password',
                            style: TextStyle(
                                fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
