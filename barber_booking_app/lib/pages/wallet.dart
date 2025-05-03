import 'dart:async';
import 'dart:convert';
import 'package:barber_booking_app/services/constants.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/material.dart' as material;
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:barber_booking_app/services/database.dart';
import 'package:barber_booking_app/services/shared_pref.dart';
import 'package:http/http.dart' as http;

class Wallet extends StatefulWidget {
  const Wallet({super.key});

  @override
  State<Wallet> createState() => _WalletState();
}

class _WalletState extends State<Wallet> {
  String? balance;
  String? userId;
  TextEditingController amountController = TextEditingController();
  Map<String, dynamic>? paymentIntent;

  @override
  void initState() {
    super.initState();
    // _loadUserData();
    // _initWalletData();
    _initialize(); // Gọi hàm khởi tạo
  }
  Future<void> _initialize() async {
  userId = await SharedpreferenceHelper().getUserId();
  await _initWalletData();
}
Future<void> _initWalletData() async {
  await WalletService.fetchAndSaveWalletBalance();
   balance = await SharedpreferenceHelper().getUserWallet(); // Lấy balance từ local
  setState(() {}); 
}

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        FocusScope.of(context).unfocus();
      },
      child: Scaffold(
        backgroundColor: const Color(0xFF2b1615),
        appBar: AppBar(
          title: const Text('My Wallet'),
          centerTitle: true,
          backgroundColor: const Color(0xFF2b1615),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => Navigator.pop(context), // 🔙 Nút quay lại
          ),
        ),
        body: balance == null
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
              child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _buildWalletBalanceCard(),
                      const SizedBox(height: 24),
                      _buildQuickTopUpButtons(),
                      const SizedBox(height: 24),
                      _buildCustomAmountField(),
                    ],
                  ),
                ),
            ),
      ),
    );
  }

  Widget _buildWalletBalanceCard() {
    return material.Card(
      color: Colors.black,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            const Icon(Icons.account_balance_wallet,
                size: 50, color: Colors.white),
            const SizedBox(height: 16),
            Text(
              'Current Balance',
              style: TextStyle(
                color: Colors.white.withOpacity(0.8),
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '\$$balance',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 36,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickTopUpButtons() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Quick Top-Up',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: ['50', '100', '200', '500'].map((amount) {
            return ElevatedButton(
              onPressed: () => _processPayment(amount),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.black,
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
              child: Text('\$$amount'),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildCustomAmountField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Custom Amount',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: amountController,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
            hintText: 'Enter amount in USD',
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide.none,
            ),
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: () => _processPayment(amountController.text),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
            child: const Text('Add Money'),
          ),
        ),
      ],
    );
  }

Future<void> _processPayment(String amount) async {
  if (amount.isEmpty || int.tryParse(amount) == null) {
  ScaffoldMessenger.of(context).showSnackBar(
    const SnackBar(
      content: Text('Please enter a valid number!'),
      backgroundColor: Colors.red,
    ),
  );
  return;
}


  try {
    paymentIntent = await _createPaymentIntent(amount);
    await Stripe.instance.initPaymentSheet(
      paymentSheetParameters: SetupPaymentSheetParameters(
        paymentIntentClientSecret: paymentIntent!['client_secret'],
        merchantDisplayName: 'BarberPro',
        style: ThemeMode.dark,
      ),
    );

    await Stripe.instance.presentPaymentSheet();
    await _updateWalletBalance(amount);
    await _initWalletData();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Payment successful!'),
        backgroundColor: Colors.green,
      ),
    );

  } on StripeException catch (e) {
    if (e.error.localizedMessage == "The payment flow has been canceled") {
      // Người dùng hủy thanh toán, không hiển thị lỗi
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Payment error: ${e.error.localizedMessage}'),
        backgroundColor: Colors.red,
      ),
    );
  } catch (e) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('An error occurred: ${e.toString()}'),
        backgroundColor: Colors.red,
      ),
    );
  }
}


  Future<Map<String, dynamic>> _createPaymentIntent(String amount) async {
    final response = await http.post(
      Uri.parse('https://api.stripe.com/v1/payment_intents'),
      headers: {
        'Authorization': 'Bearer ${Constants.stripeSecretKey}',
        'Content-Type': 'application/x-www-form-urlencoded'
      },
      body: {
        'amount': ((int.tryParse(amount) ?? 0) * 100).toString(),
        'currency': 'usd',
        'payment_method_types[]': 'card'
      },
    );
    return json.decode(response.body);
  }

  Future<void> _updateWalletBalance(String amount) async {
    if (userId == null) return;

    final currentBalance = int.tryParse(balance ?? '0') ?? 0;
    final newBalance = (currentBalance + int.parse(amount)).toString();

    await SharedpreferenceHelper().saveUserWallet(newBalance);
    await DatabaseMethods().updateUserWallet(userId!, newBalance);
  }
}


class WalletService {
   static Future<void> fetchAndSaveWalletBalance() async {
final userId = await SharedpreferenceHelper().getUserId();

    final firestoreBalance = await FirebaseFirestore.instance
        .collection('Users')
        .doc(userId)
        .get()
        .then((doc) => doc.data()?['Wallet'] ?? '0');

    await SharedpreferenceHelper().saveUserWallet(firestoreBalance);
    return firestoreBalance;
  
   }
}
