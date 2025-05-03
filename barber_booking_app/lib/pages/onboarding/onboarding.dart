import 'package:barber_booking_app/pages/auth/login.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class Onboarding extends StatefulWidget {
  const Onboarding({super.key});

  @override
  State<Onboarding> createState() => _OnboardingState();
}

class _OnboardingState extends State<Onboarding> {
  Future<void> _completeOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isFirstTime', false);
    Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const Login()));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF2b1615),
      body: Container(
        margin: const EdgeInsets.only(top: 120.0),
        child: Column(
          children: [
            Image.asset("assets/images/barber.png"),
            const SizedBox(height: 50.0),
            GestureDetector(
              onTap: _completeOnboarding,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 20.0),
                decoration: BoxDecoration(
                  color: const Color(0xFFdf711a),
                  borderRadius: BorderRadius.circular(30.0),
                ),
                child: const Text(
                  "Get a Stylish Haircut",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 22.0,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            )
          ],
        ),
      ),
    );
  }
}
