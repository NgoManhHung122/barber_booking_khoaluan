import 'package:barber_booking_app/pages/barbers/barbers.dart';
import 'package:barber_booking_app/pages/barbers/sub_service_selection.dart';
import 'package:barber_booking_app/services/database.dart';
import 'package:barber_booking_app/services/shared_pref.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class Booking extends StatefulWidget {
  final Map<String, dynamic> service;
  const Booking({required this.service, super.key});

  @override
  State<Booking> createState() => _BookingState();
}

class _BookingState extends State<Booking> {
  String? name;
  String? email;
  String? image;
  bool isLoading = false;
  bool read = false;
  Map<String, dynamic>? selectedBarber;
  Map<String, dynamic>? selectedSubService;

  DateTime _selectedDate = DateTime.now();
  TimeOfDay _selectedTime = TimeOfDay.now();

  @override
  void initState() {
    super.initState();
    getUserData();
  }

  Future<void> getUserData() async {
    name = await SharedpreferenceHelper().getUserName();
    email = await SharedpreferenceHelper().getUserEmail();
    image = await SharedpreferenceHelper().getUserAvatar();
    setState(() {});
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now(),
      lastDate: DateTime(2100),
    );
    
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
        // Reset time nếu chọn ngày hiện tại
        if (picked.day == DateTime.now().day && 
            picked.month == DateTime.now().month && 
            picked.year == DateTime.now().year) {
          _selectedTime = TimeOfDay.now();
        }
      });
    }
  }

  Future<void> _selectTime(BuildContext context) async {
    final DateTime now = DateTime.now();
    final TimeOfDay initialTime;
    
    // Nếu chọn ngày hôm nay -> chỉ cho phép chọn giờ trong tương lai
    if (_selectedDate.day == now.day &&
        _selectedDate.month == now.month &&
        _selectedDate.year == now.year) {
      initialTime = TimeOfDay.fromDateTime(now.add(Duration(minutes: 1)));
    } else {
      initialTime = _selectedTime;
    }

    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: initialTime,
    );

    if (picked != null) {
      final selectedDateTime = DateTime(
        _selectedDate.year,
        _selectedDate.month,
        _selectedDate.day,
        picked.hour,
        picked.minute,
      );

      if (selectedDateTime.isBefore(DateTime.now())) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Cannot select a past time!"),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      setState(() => _selectedTime = picked);
    }
  }

  Future<void> _selectBarber() async {
    final barber = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => Barbers()),
    );

    if (barber != null) {
      setState(() {
        selectedBarber = barber;
      });
    }
  }

  Future<void> bookService() async {
    final nowFull = DateTime.now();
    final now = DateTime(
        nowFull.year, nowFull.month, nowFull.day, nowFull.hour, nowFull.minute);

    final selectedDateTime = DateTime(
      _selectedDate.year,
      _selectedDate.month,
      _selectedDate.day,
      _selectedTime.hour,
      _selectedTime.minute,
    );

    if (selectedDateTime.isBefore(now)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Selected time is in the past!"),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    final Map<String, dynamic> userBookingMap = {
      "Main_Service": widget.service['title'],
      "Sub_Service": selectedSubService!['name'],
      "Price": selectedSubService!['price'],
      "Barber": selectedBarber?["name"],
      "Date": Timestamp.fromDate(
        DateTime(
          _selectedDate.year,
          _selectedDate.month,
          _selectedDate.day,
          _selectedTime.hour,
          _selectedTime.minute,
        ),
      ),
      "Time": _selectedTime.format(context),
      "userId": await SharedpreferenceHelper().getUserId(),
      "Email": email,
      "Image": image,
      "status": "pending", // Trạng thái mặc định,
      "read": read,
    };

    String? userId = await SharedpreferenceHelper().getUserId();
    if (userId != null) {
      await DatabaseMethods().addUserBooking(userBookingMap, userId);
    } else {
      throw Exception("User ID not found");
    }
  }

  Future<void> _selectSubService() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SubServiceSelection(
          subServices: widget.service['sub_services'],
        ),
      ),
    );

    if (result != null) {
      setState(() => selectedSubService = result);
    }
  }

  Future<void> _showPaymentConfirmation() async {
    if (selectedSubService == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Please select a service package!"),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final currentBalance =
        int.tryParse(await SharedpreferenceHelper().getUserWallet() ?? '0') ??
            0;
    final totalAmount = selectedSubService!['price'] as int;

    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Payment Confirmation",
            style: TextStyle(fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Total Amount: \$$totalAmount",
                style: const TextStyle(fontSize: 16)),
            const SizedBox(height: 8),
            Text("Wallet Balance: \$$currentBalance",
                style: TextStyle(
                    color: currentBalance >= totalAmount
                        ? Colors.green
                        : Colors.red,
                    fontSize: 16)),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              if (currentBalance >= totalAmount) {
                await _processPayment(totalAmount);
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text("Insufficient balance!"),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
            child: const Text("Confirm Payment",
                style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

// Hàm xử lý trừ tiền
  Future<void> _processPayment(int amount) async {
    setState(() => isLoading = true);

    try {
      final userId = await SharedpreferenceHelper().getUserId();
      if (userId == null) throw Exception("User not found");

      // Lấy số dư hiện tại
      final currentBalance =
          int.tryParse(await SharedpreferenceHelper().getUserWallet() ?? '0') ??
              0;
      final newBalance = currentBalance - amount;

      // Cập nhật ví
      await SharedpreferenceHelper().saveUserWallet(newBalance.toString());
      await DatabaseMethods().updateUserWallet(userId, newBalance.toString());

      // Thêm booking
      await bookService();
      resetBookingForm();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Payment successful! Please wait for confirmation"),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Payment failed: ${e.toString()}"),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() => isLoading = false);
    }
  }

  void resetBookingForm() {
    setState(() {
      selectedBarber = null;
      selectedSubService = null;
      _selectedDate = DateTime.now();
      _selectedTime = TimeOfDay.now();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF2b1615),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 20),
            GestureDetector(
              onTap: () => Navigator.pop(context),
              child:
                  const Icon(Icons.arrow_back, color: Colors.white, size: 30.0),
            ),
            const SizedBox(height: 20),

            Text("Book ${widget.service['title']}",
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 28.0,
                    fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),

            // 🔥 Chọn Barber
            GestureDetector(
              onTap: _selectBarber,
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                    color: Colors.orange,
                    borderRadius: BorderRadius.circular(12)),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.person, color: Colors.white),
                    const SizedBox(width: 10),
                    Text(selectedBarber?["name"] ?? "Select Barber",
                        style:
                            const TextStyle(color: Colors.white, fontSize: 18)),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            // Nút chọn gói dịch vụ con
            GestureDetector(
              onTap: _selectSubService,
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.assignment, color: Colors.white),
                    const SizedBox(width: 10),
                    Text(
                      selectedSubService?['name'] ?? "Select Service Package",
                      style: const TextStyle(color: Colors.white, fontSize: 18),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            if (selectedSubService != null)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.work_history,
                            color: Colors.orange, size: 25),
                        const SizedBox(width: 10),
                        Text(
                          selectedSubService!['name'],
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          "Price:",
                          style: TextStyle(color: Colors.white70),
                        ),
                        Text(
                          "\$${selectedSubService!['price']}",
                          style: const TextStyle(color: Colors.orange),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                  ],
                ),
              ),
            const SizedBox(height: 20),

            //  Chọn Ngày
            GestureDetector(
              onTap: () => _selectDate(context),
              child: _buildOptionTile(Icons.calendar_month, "Select Date",
                  "${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}"),
            ),
            const SizedBox(height: 20),

            //  Chọn Giờ
            GestureDetector(
              onTap: () => _selectTime(context),
              child: _buildOptionTile(Icons.access_time, "Select Time",
                  _selectedTime.format(context)),
            ),
            const SizedBox(height: 20),

            // 🚀 Nút Đặt Lịch
            GestureDetector(
              onTap: isLoading
                  ? null
                  : () async {
                      if (selectedBarber == null) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text("Please select a barber!"),
                            backgroundColor: Colors.red,
                          ),
                        );
                        return;
                      }
                      if (selectedSubService == null) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text("Please select a service package!"),
                            backgroundColor: Colors.red,
                          ),
                        );
                        return;
                      }
                      await _showPaymentConfirmation();
                    },
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(15),
                decoration: BoxDecoration(
                    color: Colors.blue,
                    borderRadius: BorderRadius.circular(12)),
                child: Center(
                  child: isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text("BOOK NOW",
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.bold)),
                ),
              ),
            ),
            const SizedBox(height: 10.0),
          ],
        ),
      ),
    );
  }

  Widget _buildOptionTile(IconData icon, String title, String value) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
          color: Colors.white24, borderRadius: BorderRadius.circular(12)),
      child: Row(
        children: [
          Icon(icon, color: Colors.white, size: 30),
          const SizedBox(width: 10),
          Text(title,
              style: const TextStyle(color: Colors.white70, fontSize: 18)),
          const Spacer(),
          Text(value,
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}
