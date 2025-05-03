import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:barber_booking_app/pages/auth/login.dart';

class ForgotPassword extends StatefulWidget {
  const ForgotPassword({super.key});

  @override
  State<ForgotPassword> createState() => _ForgotPasswordState();
}

class _ForgotPasswordState extends State<ForgotPassword> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();
  final FocusNode _emailFocusNode = FocusNode();
  AutovalidateMode _autoValidateMode = AutovalidateMode.disabled;
  bool isLoading = false; // Trạng thái loading

  @override
  void initState() {
    super.initState();
    _emailFocusNode.addListener(() {
      if (_emailFocusNode.hasFocus && _autoValidateMode != AutovalidateMode.always) {
        setState(() => _autoValidateMode = AutovalidateMode.always);
      }
    });
  }

  @override
  void dispose() {
    _emailController.dispose();
    _emailFocusNode.dispose();
    super.dispose();
  }

  Future<void> _resetPassword() async {
    setState(() => _autoValidateMode = AutovalidateMode.always);

    if (_formKey.currentState!.validate()) {
      setState(() => isLoading = true); // Hiển thị loading khi bắt đầu gửi yêu cầu

      try {
        await FirebaseAuth.instance
            .sendPasswordResetEmail(email: _emailController.text.trim());

        setState(() => isLoading = false); // Ẩn loading sau khi gửi thành công
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Password reset link has been sent!'),
            backgroundColor: Colors.green,
          ),
        );

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const Login()),
        );
      } on FirebaseAuthException catch (e) {
        setState(() => isLoading = false); // Ẩn loading khi có lỗi
        String errorMessage = 'An error occurred, please try again.';
        if (e.code == 'user-not-found') {
          errorMessage = 'No user found with this email!';
        } else if (e.code == 'invalid-email') {
          errorMessage = 'Invalid email address!';
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  String? _emailValidator(String? value) {
    if (value == null || value.isEmpty) return 'This field is required';
    if (!RegExp(r'^[\w-.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
      return 'Enter a valid email address';
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        backgroundColor: Colors.white,
        body: SingleChildScrollView(
          child: Stack(
            children: [
              // Header gradient
              Container(
                padding: const EdgeInsets.only(top: 50.0, left: 30.0),
                height: MediaQuery.of(context).size.height / 2.5,
                width: double.infinity,
                decoration: const BoxDecoration(
                  gradient: LinearGradient(colors: [
                    Color(0xFFB91635),
                    Color(0Xff621d3c),
                    Color(0xFF311937),
                  ]),
                ),
                child: const Text(
                  "Forgot\nPassword?",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 32.0,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),

              // Form section
              Container(
                padding: const EdgeInsets.all(30.0),
                margin: EdgeInsets.only(
                  top: MediaQuery.of(context).size.height / 4,
                ),
                width: double.infinity,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(40),
                    topRight: Radius.circular(40.0),
                  ),
                ),
                child: Form(
                  key: _formKey,
                  autovalidateMode: _autoValidateMode,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "Email",
                        style: TextStyle(
                          color: Color(0xFFB91635),
                          fontSize: 23.0,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 10.0),
                      TextFormField(
                        controller: _emailController,
                        focusNode: _emailFocusNode,
                        validator: _emailValidator,
                        textInputAction: TextInputAction.done,
                        decoration: const InputDecoration(
                          hintText: "Enter your email",
                          prefixIcon: Icon(Icons.mail_outline),
                          contentPadding: EdgeInsets.symmetric(vertical: 13.0),
                        ),
                      ),
                      const SizedBox(height: 40.0),

                      // SEND REQUEST button with loading
                      GestureDetector(
                        onTap: isLoading ? null : _resetPassword, // Ngăn bấm khi đang loading
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 12.0),
                          width: double.infinity,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(colors: [
                              Color(0xFFB91635),
                              Color(0Xff621d3c),
                              Color(0xFF311937),
                            ]),
                            borderRadius: BorderRadius.circular(30.0),
                          ),
                          child: Center(
                            child: isLoading
                                ? const SizedBox(
                                    width: 24,
                                    height: 24,
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 3.0,
                                    ),
                                  )
                                : const Text(
                                    "SEND REQUEST",
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 22.0,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20.0),

                      // Go back to login
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text(
                            "Remember your password?",
                            style: TextStyle(
                              color: Color(0xFF311937),
                              fontSize: 17.0,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(width: 5.0),
                          GestureDetector(
                            onTap: () {
                              Navigator.pushReplacement(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const Login(),
                                ),
                              );
                            },
                            child: const Text(
                              "Login",
                              style: TextStyle(
                                color: Color(0Xff621d3c),
                                fontSize: 20.0,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
