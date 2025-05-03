import 'package:barber_booking_app/pages/home/home.dart';
import 'package:barber_booking_app/services/database.dart';
import 'package:barber_booking_app/services/shared_pref.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:barber_booking_app/pages/auth/login.dart';

class Signup extends StatefulWidget {
  const Signup({super.key});

  @override
  State<Signup> createState() => _SignupState();
}

class _SignupState extends State<Signup> {
  String? name;
  String? mail;
  String? password;
  bool isShowPassword = true;
  bool isLoading = false; // Biến quản lý loading

  final TextEditingController nameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  final _formKey = GlobalKey<FormState>();

  String? _nameError;
  String? _emailError;
  String? _passwordError;

  void validateName(String value) {
    setState(() => _nameError = value.isEmpty ? 'This field is required' : null);
  }

  void validateEmail(String value) {
    setState(() {
      if (value.isEmpty) {
        _emailError = 'This field is required';
      } else {
        const pattern = r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$';
        _emailError = RegExp(pattern).hasMatch(value) ? null : 'Enter a valid email address';
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

  Future<void> registration() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        isLoading = true; // Hiển thị loading khi bắt đầu đăng ký
        mail = emailController.text.trim();
        name = nameController.text.trim();
        password = passwordController.text;
      });

      try {
        UserCredential userCredential = await FirebaseAuth.instance
            .createUserWithEmailAndPassword(email: mail!, password: password!);

        if (userCredential.user != null) {
          String userId = userCredential.user!.uid; // Lấy userId từ Firebase

          await SharedpreferenceHelper().saveUserName(name!);
          await SharedpreferenceHelper().saveUserEmail(mail!);
          await SharedpreferenceHelper().saveUserAvatar("https://i.imgur.com/a6kQUGU.png"); // Thay saveUserImage -> saveUserAvatar
          await SharedpreferenceHelper().saveUserWallet("0");
          await SharedpreferenceHelper().saveUserId(userId);

          final userInfoMap = {
            "Name": name!,
            "Email": mail!,
            "Id": userId,
            "avatarUrl": "https://i.imgur.com/a6kQUGU.png",
             "Wallet": "0"
          };

          await DatabaseMethods().addUserDetails(userInfoMap, userId);
          print('Log[]$userInfoMap');
          setState(() => isLoading = false); // Ẩn loading khi thành công

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Registered Successfully!", style: TextStyle(fontSize: 20.0)),
              backgroundColor: Colors.green,
            ),
          );

          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const Home()),
          );
        }
      } on FirebaseAuthException catch (e) {
        setState(() => isLoading = false); // Ẩn loading khi lỗi

        String errorMessage = "An error occurred, please try again.";
        if (e.code == 'weak-password') {
          errorMessage = "Password is too weak, please use a stronger one!";
        } else if (e.code == "email-already-in-use") {
          errorMessage = "Email already exists, please sign in!";
        } else if (e.code == "invalid-email") {
          errorMessage = "Invalid email format!";
        } else if (e.code == "operation-not-allowed") {
          errorMessage = "Email/password authentication is not enabled!";
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage, style: const TextStyle(fontSize: 18.0)),
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
        backgroundColor: Colors.white,
        body: SingleChildScrollView(
          child: Stack(
            children: [
              //  Header
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
                  "Create Your\nAccount",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 32.0,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),

              // Form
              Container(
                padding: const EdgeInsets.all(30.0),
                margin: EdgeInsets.only(top: MediaQuery.of(context).size.height / 4),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(40),
                    topRight: Radius.circular(40.0),
                  ),
                ),
                child: Form(
                  key: _formKey,
                  autovalidateMode: AutovalidateMode.onUserInteraction,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "Name",
                        style: TextStyle(
                          color: Color(0xFFB91635),
                          fontSize: 23.0,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      TextFormField(
                        controller: nameController,
                        textInputAction: TextInputAction.next,
                        decoration: InputDecoration(
                          hintText: "Name",
                          prefixIcon: const Icon(Icons.person_outline),
                          contentPadding: const EdgeInsets.symmetric(vertical: 13.0),
                          errorText: _nameError,
                        ),
                        onChanged: validateName,
                      ),
                      const SizedBox(height: 30.0),

                      const Text(
                        "Gmail",
                        style: TextStyle(
                          color: Color(0xFFB91635),
                          fontSize: 23.0,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      TextFormField(
                        controller: emailController,
                        textInputAction: TextInputAction.next,
                        decoration: InputDecoration(
                          hintText: "Gmail",
                          prefixIcon: const Icon(Icons.mail_outline),
                          contentPadding: const EdgeInsets.symmetric(vertical: 13.0),
                          errorText: _emailError,
                        ),
                        onChanged: validateEmail,
                      ),
                      const SizedBox(height: 30.0),

                      const Text(
                        "Password",
                        style: TextStyle(
                          color: Color(0xFFB91635),
                          fontSize: 23.0,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      TextFormField(
                        controller: passwordController,
                        textInputAction: TextInputAction.done,
                        decoration: InputDecoration(
                          hintText: "Password",
                          prefixIcon: const Icon(Icons.password_outlined),
                          suffixIcon: InkWell(
                            onTap: () => setState(() => isShowPassword = !isShowPassword),
                            child: Icon(isShowPassword ? Icons.visibility_off : Icons.visibility),
                          ),
                          contentPadding: const EdgeInsets.symmetric(vertical: 13.0),
                          errorText: _passwordError,
                        ),
                        obscureText: isShowPassword,
                        onChanged: validatePassword,
                      ),
                      const SizedBox(height: 50.0),

                      // SIGN UP button with loading
                      GestureDetector(
                        onTap: isLoading
                            ? null
                            : () {
                                validateName(nameController.text);
                                validateEmail(emailController.text);
                                validatePassword(passwordController.text);

                                if (_nameError == null &&
                                    _emailError == null &&
                                    _passwordError == null) {
                                  registration();
                                }
                              },
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
                                    "SIGN UP",
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

                      // 🔑 Sign In prompt
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text(
                            "Already have an account?",
                            style: TextStyle(
                              color: Color(0xFF311937),
                              fontSize: 17.0,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(width: 5.0),
                          GestureDetector(
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => const Login()),
                            ),
                            child: const Text(
                              "Sign In",
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
