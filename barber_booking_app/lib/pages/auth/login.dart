import 'package:barber_booking_app/admin/admin_login.dart';
import 'package:barber_booking_app/pages/auth/forgot_password.dart';
import 'package:barber_booking_app/pages/home/home.dart';
import 'package:barber_booking_app/pages/auth/signup.dart';
import 'package:barber_booking_app/services/shared_pref.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class Login extends StatefulWidget {
  const Login({super.key});

  @override
  State<Login> createState() => _LoginState();
}

class _LoginState extends State<Login> {
  String? mail;
  String? password;
  bool isShowPassword = true;
  bool isLoading = false; // Quản lý trạng thái loading

  final TextEditingController emailcontroller = TextEditingController();
  final TextEditingController passwordcontroller = TextEditingController();
  final _formkey = GlobalKey<FormState>();

  String? _emailError;
  String? _passwordError;

  void validateEmail(String value) {
    setState(() {
      if (value.isEmpty) {
        _emailError = 'This field is required';
      } else {
        String pattern = r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$';
        RegExp regex = RegExp(pattern);
        _emailError = regex.hasMatch(value) ? null : 'Enter a valid email address';
      }
    });
  }

  void validatePassword(String value) {
    setState(() {
      if (value.isEmpty) {
        _passwordError = 'This field is required';
      } else if (value.length < 6) {
        _passwordError = 'Password must be at least 6 characters long';
      } else {
        _passwordError = null;
      }
    });
  }


Future<void> userLogin() async {
  setState(() => isLoading = true);

  try {
    UserCredential userCredential = await FirebaseAuth.instance.signInWithEmailAndPassword(
      email: emailcontroller.text.trim(),
      password: passwordcontroller.text.trim(),
    );

    User? user = userCredential.user;
    if (user != null) {
      var snapshot = await FirebaseFirestore.instance.collection('Users').doc(user.uid).get();

      if (snapshot.exists) {
        var userData = snapshot.data();

        // Cập nhật dữ liệu vào SharedPreferences
        await SharedpreferenceHelper().saveUserName(userData?["Name"]);
        await SharedpreferenceHelper().saveUserEmail(userData?["Email"]);
        await SharedpreferenceHelper().saveUserAvatar(userData?["avatarUrl"]);
        await SharedpreferenceHelper().saveUserId(user.uid);
      }

      setState(() => isLoading = false);
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => Home(user: user)),
        (route) => false,
      );
    }
  } on FirebaseAuthException catch (e) {
    setState(() => isLoading = false);

    String message = "An error occurred";
    if (e.code == 'user-not-found') {
      message = "No user found for that email";
    } else if (e.code == 'wrong-password') {
      message = "Wrong password provided";
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: const TextStyle(fontSize: 18.0)),
        backgroundColor: Colors.redAccent,
      ),
    );
  }
}




  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        backgroundColor: Colors.white,
        resizeToAvoidBottomInset: true,
        body: SingleChildScrollView(
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
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
                  "Hello\nSign in!",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 32.0,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),

              // Form section
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 30.0, vertical: 40.0),
                margin: EdgeInsets.only(top: MediaQuery.of(context).size.height / 4),
                width: double.infinity,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(40),
                    topRight: Radius.circular(40.0),
                  ),
                ),
                child: Form(
                  key: _formkey,
                  autovalidateMode: AutovalidateMode.onUserInteraction,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Email field
                      const Text(
                        "Gmail",
                        style: TextStyle(
                          color: Color(0xFFB91635),
                          fontSize: 23.0,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      TextFormField(
                        controller: emailcontroller,
                        textInputAction: TextInputAction.next,
                        decoration: InputDecoration(
                          hintText: "Gmail",
                          prefixIcon: const Icon(Icons.mail_outline),
                          contentPadding: const EdgeInsets.symmetric(vertical: 13.0),
                          errorText: _emailError,
                        ),
                        onChanged: validateEmail,
                      ),
                      const SizedBox(height: 40.0),

                      // Password field
                      const Text(
                        "Password",
                        style: TextStyle(
                          color: Color(0xFFB91635),
                          fontSize: 23.0,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      TextFormField(
                        controller: passwordcontroller,
                        textInputAction: TextInputAction.done,
                        obscureText: isShowPassword,
                        decoration: InputDecoration(
                          hintText: "Password",
                          prefixIcon: const Icon(Icons.password_outlined),
                          suffixIcon: InkWell(
                            onTap: () {
                              setState(() => isShowPassword = !isShowPassword);
                            },
                            child: Icon(
                              isShowPassword ? Icons.visibility_off : Icons.visibility,
                            ),
                          ),
                          contentPadding: const EdgeInsets.symmetric(vertical: 13.0),
                          errorText: _passwordError,
                        ),
                        onChanged: validatePassword,
                      ),
                      const SizedBox(height: 30.0),

                      // Forgot Password
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          GestureDetector(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (context) => const ForgotPassword()),
                              );
                            },
                            child: const Text(
                              "Forgot Password?",
                              style: TextStyle(
                                color: Color(0xFF311937),
                                fontSize: 18.0,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 60.0),

                      // SIGN IN button with loading
                      GestureDetector(
                        onTap: isLoading ? null : userLogin,
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
                                    width: 26,
                                    height: 26,
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 3.0,
                                    ),
                                  )
                                : const Text(
                                    "SIGN IN",
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 24.0,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20.0),

                      // Sign up & Admin login
                      Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Text(
                                "Don't have an account?",
                                style: TextStyle(
                                  color: Color(0xFF311937),
                                  fontSize: 17.0,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(width: 5.0),
                              GestureDetector(
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(builder: (context) => const Signup()),
                                  );
                                },
                                child: const Text(
                                  "Sign up",
                                  style: TextStyle(
                                    color: Color(0Xff621d3c),
                                    fontSize: 22.0,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 15.0),
                          GestureDetector(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (context) => const AdminLogin()),
                              );
                            },
                            child: const Text(
                              "Admin Login",
                              style: TextStyle(
                                color: Color(0Xff621d3c),
                                fontSize: 22.0,
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
