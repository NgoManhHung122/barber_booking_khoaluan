import 'package:barber_booking_app/data/barber_data.dart';
import 'package:barber_booking_app/services/database.dart';
import 'package:barber_booking_app/services/shared_pref.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class BookingHistory extends StatefulWidget {
  @override
  _BookingHistoryState createState() => _BookingHistoryState();
}

class _BookingHistoryState extends State<BookingHistory> {
  String? userEmail;
  bool isLoading = true;
  String? currentUserId;

  @override
  void initState() {
    super.initState();
    _getUserInfo();
    _getUserEmail();
  }

  Future<void> _getUserInfo() async {
    currentUserId = await SharedpreferenceHelper().getUserId();
    userEmail = await SharedpreferenceHelper().getUserEmail();
    setState(() {});
  }

  Future<void> _getUserEmail() async {
    userEmail = await SharedpreferenceHelper().getUserEmail();
    setState(() => isLoading = false);
  }

  DateTime _parseBookingDateTime(Timestamp timestamp) {
    return timestamp.toDate();
  }

  String _formatDate(DateTime date) {
    return "${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}";
  }

  String _formatTime(DateTime date) {
    return "${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}";
  }

  Future<void> _cancelBooking(String bookingId, int price) async {
    try {
      final bookingDoc = await FirebaseFirestore.instance
          .collection('Booking')
          .doc(bookingId)
          .get();

      final bookingData = bookingDoc.data() as Map<String, dynamic>;
      final bookingDateTime = _parseBookingDateTime(bookingData['Date']);

      final now = DateTime.now();
      final difference = bookingDateTime.difference(now);

      if (difference.inHours >= 24) {
        await _refundToWallet(price);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Booking canceled successfully! Refund issued to wallet.'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Booking canceled. No refund due to late cancellation.'),
            backgroundColor: Colors.orange,
          ),
        );
      }

      await FirebaseFirestore.instance
          .collection('Booking')
          .doc(bookingId)
          .update({'status': 'cancelled'});

    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Widget _buildStatusBadge(String status) {
    Color color;
    switch (status) {
      case "confirmed":
        color = Colors.green;
        break;
      case "pending":
        color = Colors.orange;
        break;
      case "cancelled":
        color = Colors.red;
        break;
      case "completed":
        color = Colors.blue;
        break;
      default:
        color = Colors.grey;
    }
    return Chip(
      label: Text(status.toUpperCase()),
      backgroundColor: color.withOpacity(0.2),
      labelStyle: TextStyle(color: color),
    );
  }

  Future<void> _refundToWallet(int amount) async {
    final userId = await SharedpreferenceHelper().getUserId();
    if (userId == null) return;

    final currentBalance = int.tryParse(
        await SharedpreferenceHelper().getUserWallet() ?? '0') ?? 0;
    final newBalance = currentBalance + amount;

    await SharedpreferenceHelper().saveUserWallet(newBalance.toString());
    await DatabaseMethods().updateUserWallet(userId, newBalance.toString());
  }

  void _showCancelDialog(BuildContext context, String bookingId, int price) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Cancellation'),
        content: const Text('Are you sure you want to cancel this booking?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('No'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await _cancelBooking(bookingId, price);
            },
            child: const Text('Yes'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Booking History"),
        backgroundColor: Colors.brown,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('Booking')
                  .where('userId', isEqualTo: currentUserId)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(
                    child: Text(
                      "No bookings yet!",
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  );
                }

                var bookings = snapshot.data!.docs;
                return ListView.builder(
                  itemCount: bookings.length,
                  itemBuilder: (context, index) {
                    var booking = bookings[index];
                    var bookingData = booking.data() as Map<String, dynamic>?;

                    if (bookingData?['status'] == 'cancelled') return const SizedBox.shrink();

                    int price = (bookingData?["Price"] is int) 
                        ? bookingData!["Price"] 
                        : int.tryParse(bookingData?["Price"]?.toString() ?? '0') ?? 0;

                    Timestamp timestamp = bookingData?['Date'];
                    DateTime bookingDate = timestamp.toDate();

                    return Card(
                      margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                      color: Colors.brown[100],
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundImage: AssetImage(
                            getBarberByName(bookingData?["Barber"] ?? "")?["image"] 
                            ?? "assets/images/default_barber.png"),
                        ),
                        title: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              bookingData?["Main_Service"] ?? "Unknown",
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.brown[800]),
                            ),
                            Text(
                              "Package: ${bookingData?["Sub_Service"] ?? "Unknown"}",
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.brown[600]),
                            ),
                          ],
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text("Barber: ${bookingData?["Barber"] ?? "Unknown"}"),
                            Text("Price: \$${price.toString()}"),
                            Text("Date: ${_formatDate(bookingDate)}"),
                            Text("Time: ${_formatTime(bookingDate)}"),
                            _buildStatusBadge(bookingData?["status"] ?? "pending"),
                          ],
                        ),
                        trailing: bookingData?["status"] == "cancelled"
                            ? null
                            : IconButton(
                                icon: const Icon(Icons.cancel, color: Colors.red),
                                onPressed: () => _showCancelDialog(
                                  context, 
                                  booking.id,
                                  price
                                ),
                              ),
                      ),
                    );
                  },
                );
              },
            ),
    );
  }
}