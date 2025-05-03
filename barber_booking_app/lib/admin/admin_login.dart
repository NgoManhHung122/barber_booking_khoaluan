import 'package:barber_booking_app/admin/booking_admin.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class AdminLogin extends StatefulWidget {
  const AdminLogin({super.key});

  @override
  State<AdminLogin> createState() => _AdminLoginState();
}

class _AdminLoginState extends State<AdminLogin> {
  bool isShowPassword = true;
  bool isLoading = false;

  final TextEditingController usernameController = TextEditingController();
  final TextEditingController userPasswordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  String? _usernameError;
  String? _passwordError;

  void validateInputs() {
    setState(() {
      _usernameError = usernameController.text.isEmpty ? "This field is required" : null;
      _passwordError = userPasswordController.text.isEmpty ? "This field is required" : null;
    });
  }

  Future<void> loginAdmin() async {
    FocusScope.of(context).unfocus(); 
    validateInputs();

    if (_usernameError != null || _passwordError != null) return; // Nếu có lỗi -> Dừng

    setState(() => isLoading = true); // Hiển thị loading

    try {
      final snapshot = await FirebaseFirestore.instance.collection("Admin").get();
      
      bool isValid = false;
      String validDocId = ""; 
      for (var result in snapshot.docs) {
        final data = result.data();

        if (data['id'] != usernameController.text.trim()) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Your ID is not correct", style: TextStyle(fontSize: 18.0)),
              backgroundColor: Colors.redAccent,
            ),
          );
        } else if (data['password'] != userPasswordController.text.trim()) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Your password is not correct", style: TextStyle(fontSize: 18.0)),
              backgroundColor: Colors.redAccent,
            ),
          );
        } else {
          isValid = true;
          validDocId = result.id; // Lưu ID của tài liệu hợp lệ
          break; // ✅ Thoát vòng lặp khi đăng nhập thành công
        }
      }

      setState(() => isLoading = false);

      if (isValid  && validDocId.isNotEmpty) {
        // await DatabaseMethods.saveFcmTokenToFirestore(validDocId, true);
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const BookingAdmin()),
        );
      }
    } catch (e) {
      setState(() => isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Error: ${e.toString()}", style: const TextStyle(fontSize: 18.0)),
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
        body: SingleChildScrollView(
          child: Stack(
            children: [
              // Header gradient
              Container(
                padding: const EdgeInsets.only(top: 80.0, left: 30.0),
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
                  "Admin\nPanel",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 32.0,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),

              // 🔙 Back button
              Positioned(
                top: 50.0,
                left: 10.0,
                child: GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: const Icon(
                    Icons.arrow_back_sharp,
                    color: Colors.white,
                    size: 30.0,
                  ),
                ),
              ),

              // Form section
              Container(
                padding: const EdgeInsets.all(30.0),
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
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Username field
                      const Text(
                        "Username",
                        style: TextStyle(
                          color: Color(0xFFB91635),
                          fontSize: 23.0,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      TextFormField(
                        controller: usernameController,
                        textInputAction: TextInputAction.next,
                        decoration: InputDecoration(
                          hintText: "Username",
                          prefixIcon: const Icon(Icons.person_outline),
                          contentPadding: const EdgeInsets.symmetric(vertical: 13.0),
                          errorText: _usernameError,
                        ),
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
                        controller: userPasswordController,
                        textInputAction: TextInputAction.done,
                        obscureText: isShowPassword,
                        decoration: InputDecoration(
                          hintText: "Password",
                          prefixIcon: const Icon(Icons.password_outlined),
                          suffixIcon: InkWell(
                            onTap: () => setState(() => isShowPassword = !isShowPassword),
                            child: Icon(
                              isShowPassword ? Icons.visibility_off : Icons.visibility,
                            ),
                          ),
                          contentPadding: const EdgeInsets.symmetric(vertical: 13.0),
                          errorText: _passwordError,
                        ),
                      ),
                      const SizedBox(height: 60.0),

                      // LOG IN button with loading
                      GestureDetector(
                        onTap: isLoading ? null : loginAdmin,
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
                                    "LOG IN",
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 24.0,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                          ),
                        ),
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
