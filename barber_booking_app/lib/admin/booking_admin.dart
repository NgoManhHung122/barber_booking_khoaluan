import 'package:barber_booking_app/admin/user_management.dart';
import 'package:barber_booking_app/pages/auth/login.dart';
import 'package:barber_booking_app/services/database.dart';
import 'package:barber_booking_app/services/shared_pref.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class BookingAdmin extends StatefulWidget {
  const BookingAdmin({super.key});

  @override
  State<BookingAdmin> createState() => _BookingAdminState();
}

class _BookingAdminState extends State<BookingAdmin> {
  Stream? bookingStream;

  // Lấy dữ liệu booking từ Firestore
  getontheload() async {
    try {
      bookingStream = DatabaseMethods().getBookings(); 
      setState(() {});
    } catch (e) {
      print("Lỗi khi tải dữ liệu: $e");
    }
  }

  @override
  void initState() {
    getontheload();
    super.initState();
  }

  // Hàm xác định màu trạng thái
  Color _getStatusColor(String status) {
    switch (status) {
      case 'confirmed':
        return Colors.green;
      case 'cancelled':
        return Colors.red;
      case 'completed':
        return Colors.blue;
      default:
        return Colors.orange;
    }
  }

  // Widget dropdown trạng thái
  Widget _buildStatusDropdown(DocumentSnapshot ds) {
    final Timestamp bookingDateTs = ds['Date'] as Timestamp;
    final String bookingTime = ds['Time'] as String? ?? '';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: DropdownButton<String>(
        value: ds["status"] ?? 'pending', // Sửa thành chữ thường
        icon: const Icon(Icons.arrow_drop_down, size: 20),
        underline: const SizedBox(),
        items: ['pending', 'confirmed', 'completed', 'cancelled']
            .map((value) => DropdownMenuItem(
                  value: value,
                  child: Text(
                    value.toUpperCase(),
                    style: TextStyle(
                      color: _getStatusColor(value),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ))
            .toList(),
        onChanged: (newValue) async {
          if (newValue != null) {
            await DatabaseMethods().updateBookingStatus(ds.id, newValue);
            setState(() {});

            // Gửi thông báo nếu là trạng thái đặc biệt
            if (['pending','confirmed', 'completed', 'cancelled'].contains(newValue)) {
              String message = "";
              switch (newValue) {
                case 'pending':
                  message = "Your booking has been pending. $bookingTime";
                  break;
                case 'confirmed':
                  message = "Your booking has been confirmed. $bookingTime";
                  break;
                case 'completed':
                  message =
                      "Your service has been completed.$bookingTime Thank you! ";
                  break;
                case 'cancelled':
                  message = "Your booking has been cancelled.$bookingTime";
                  break;
              }

              await sendUserNotification(
                  ds['userId'], ds.id, message, ds["Time"], bookingDateTs);
            }
          }
        },
      ),
    );
  }

  Future<void> sendUserNotification(
    String userId,
    String bookingId,
    String message,
    String time,
     Timestamp bookingDateTs,  
  ) async {
    await FirebaseFirestore.instance.collection('UserNotifications').add({
      'userId': userId,
      'bookingId': bookingId,
      'message': message,
      'time': time,
      'date': bookingDateTs,
      'read': false,
    });
  }

  // Widget hiển thị danh sách booking
  Widget _buildBookingList() {
    return StreamBuilder(
      stream: bookingStream,
      builder: (context, AsyncSnapshot snapshot) {
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(child: Text("No bookings found"));
        }

        return ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          itemCount: snapshot.data.docs.length,
          itemBuilder: (context, index) {
            DocumentSnapshot ds = snapshot.data.docs[index];
            String userId = ds["userId"];
            String barberName = ds["Barber"] ?? "Unknown";

            return FutureBuilder<DocumentSnapshot>(
              future: FirebaseFirestore.instance
                  .collection('Users')
                  .doc(userId)
                  .get(),
              builder: (context, userSnapshot) {
                if (userSnapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (!userSnapshot.hasData || !userSnapshot.data!.exists) {
                  return const ListTile(title: Text("User data not found"));
                }

                var userData =
                    userSnapshot.data!.data() as Map<String, dynamic>;
                String username = userData['Name'] ?? "Unknown";
                String avatarUrl =
                    userData['avatarUrl'] ?? "https://i.imgur.com/a6kQUGU.png";

                return Card(
                  margin: const EdgeInsets.symmetric(vertical: 8),
                  color: Colors.grey[100],
                  child: ListTile(
                    contentPadding: const EdgeInsets.all(12),
                    leading: CircleAvatar(
                      radius: 30,
                      backgroundImage: NetworkImage(avatarUrl),
                      onBackgroundImageError: (_, __) =>
                          const Icon(Icons.person, color: Colors.white),
                    ),
                    title: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          ds["Main_Service"] ?? "No service",
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.blueGrey[800],
                          ),
                        ),
                        Text(
                          "Package: ${ds["Sub_Service"] ?? "No package"}",
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.blueGrey[600],
                          ),
                        ),
                      ],
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildInfoRow("Customer", username),
                        _buildInfoRow("Barber", barberName),
                        _buildInfoRow("Price",
                            "\$${(ds["Price"] ?? 0).toStringAsFixed(2)}"),
                        _buildInfoRow(
                            "Date",
                            ds["Date"] != null
                                ? DateFormat('dd/MM/yyyy')
                                    .format((ds["Date"] as Timestamp).toDate())
                                : "N/A"),
                        _buildInfoRow("Time", ds["Time"] ?? "N/A"),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            const SizedBox(width: 10),
                            Expanded(child: _buildStatusDropdown(ds)),
                            const SizedBox(width: 10),
                            GestureDetector(
                              onTap: () async =>
                                  await DatabaseMethods().deleteBooking(ds.id),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 16, vertical: 8),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFdf711a),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: const Text(
                                  "DONE",
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  // Widget helper hiển thị thông tin
  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: RichText(
        text: TextSpan(
          style: const TextStyle(fontSize: 13),
          children: [
            TextSpan(
              text: "$label: ",
              style: TextStyle(
                color: Colors.blueGrey[700],
                fontWeight: FontWeight.w500,
              ),
            ),
            TextSpan(
              text: value,
              style: TextStyle(
                color: Colors.blueGrey[900],
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Booking Management"),
        backgroundColor: Colors.brown,
        actions: [
          Stack(
            children: [
              StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('Booking')
                    .where('status', isEqualTo: 'pending')
                    .where('read', isEqualTo: false)
                    .snapshots(),
                builder: (context, snapshot) {
                  int unreadCount = 0;
                  if (snapshot.hasData) {
                    unreadCount = snapshot.data!.docs.length;
                  }
                  return IconButton(
                    icon: Stack(
                      children: [
                        const Icon(Icons.notifications),
                        if (unreadCount > 0)
                          Positioned(
                            right: 0,
                            top: 0,
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: const BoxDecoration(
                                color: Colors.red,
                                shape: BoxShape.circle,
                              ),
                              constraints: const BoxConstraints(
                                minWidth: 20,
                                minHeight: 20,
                              ),
                              child: Text(
                                '$unreadCount',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ),
                      ],
                    ),
                    onPressed: () {
                      _showNotificationBookings(context);
                    },
                  );
                },
              ),
            ],
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: getontheload,
          ),
        ],
      ),
      body: _buildBookingList(),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            const DrawerHeader(
              decoration: BoxDecoration(color: Colors.brown),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CircleAvatar(
                    radius: 30,
                    backgroundImage:
                        NetworkImage("https://i.imgur.com/a6kQUGU.png"),
                  ),
                  SizedBox(height: 10),
                  Text(
                    "Admin Panel",
                    style: TextStyle(color: Colors.white, fontSize: 18),
                  ),
                ],
              ),
            ),
            ListTile(
              leading: const Icon(Icons.people),
              title: const Text("Manage Users"),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(context, MaterialPageRoute(builder: (context) => const UserManagement()));
              },
            ),
            ListTile(
              leading: const Icon(Icons.settings),
              title: const Text("Settings"),
              onTap: () {},
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.logout, color: Colors.red),
              title: const Text("Logout", style: TextStyle(color: Colors.red)),
              onTap: () async {
                final confirmLogout = await showDialog<bool>(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text("Logout Confirmation"),
                    content: const Text("Are you sure you want to log out?"),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context, false),
                        child: const Text("Cancel"),
                      ),
                      TextButton(
                        onPressed: () => Navigator.pop(context, true),
                        child: const Text(
                          "Logout",
                          style: TextStyle(color: Colors.red),
                        ),
                      ),
                    ],
                  ),
                );

                if (confirmLogout == true) {
                  await FirebaseAuth.instance.signOut();
                  await SharedpreferenceHelper().clearAllData();
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(builder: (context) => const Login()),
                    (route) => false,
                  );
                }
              },
            ),
          ],
        ),
      ),
    );
  }
void _showNotificationBookings(BuildContext context) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
    ),
    builder: (context) {
      // local set để lưu tạm các booking đã được tap trong session này
      final Set<String> locallyMarkedRead = <String>{};

      return StatefulBuilder(
        builder: (context, setStateSB) {
          return FutureBuilder<QuerySnapshot>(
            future: getPendingBookings(), // fetch cả read/unread
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Padding(
                  padding: EdgeInsets.all(20),
                  child: Center(child: CircularProgressIndicator()),
                );
              }
              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return const Padding(
                  padding: EdgeInsets.all(20),
                  child: Center(child: Text('No pending bookings')),
                );
              }

              final bookings = snapshot.data!.docs;

              return ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: bookings.length,
                separatorBuilder: (_, __) => const Divider(),
                itemBuilder: (context, index) {
                  final doc = bookings[index];
                  final data = doc.data() as Map<String, dynamic>;
                  final id = doc.id;

                  // Tính trạng thái read: nếu Firestore đã mark hoặc user đã tap trong session này
                  final bool isReadFirestore = data['read'] as bool? ?? false;
                  final bool isReadLocal   = locallyMarkedRead.contains(id);
                  final bool isRead        = isReadFirestore || isReadLocal;

                  // Chọn màu nền khác nhau
                  final tileColor = isRead
                      ? Colors.grey.shade200
                      : Colors.lightBlue.shade50;

                  // Format ngày giờ
                  Timestamp? ts = data['Date'];
                  String dateStr = 'N/A';
                  if (ts != null) {
                    final dt = ts.toDate();
                    dateStr = "${dt.day}/${dt.month}/${dt.year}";
                  }
                  final timeStr = data['Time'] ?? '';

                  return InkWell(
                    onTap: () async {
                      if (!isRead) {
                        // 1. Cập nhật Firestore
                        await FirebaseFirestore.instance
                            .collection('Booking')
                            .doc(id)
                            .update({'read': true});
                        // 2. Đánh dấu local để rebuild màu ngay
                        locallyMarkedRead.add(id);
                        setStateSB(() {});
                      }
                    },
                    child: Container(
                      color: tileColor,
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundImage:
                              NetworkImage(data['Image'] ?? ''),
                        ),
                        title: Text(data['Main_Service'] ?? ''),
                        subtitle: Text(
                          "${data['Email'] ?? 'Unknown'}\n"
                          "$dateStr at $timeStr",
                        ),
                        isThreeLine: true,
                      ),
                    ),
                  );
                },
              );
            },
          );
        },
      );
    },
  ).whenComplete(() async {
    // Khi đóng sheet: đánh dấu tất cả pending booking là read
    await markPendingBookingsAsRead();
  });
}

  Future<QuerySnapshot> getPendingBookings() async {
    final data = await FirebaseFirestore.instance
        .collection('Booking')
        .where('status', isEqualTo: 'pending')
        .orderBy('Date', descending: true)
        .get();
    return data;
  }

  Future<void> markPendingBookingsAsRead() async {
    QuerySnapshot snapshot = await FirebaseFirestore.instance
        .collection('Booking')
        .where('status', isEqualTo: 'pending')
        .where('read', isEqualTo: false)
        .get();

    for (var doc in snapshot.docs) {
      await doc.reference.update({'read': true});
    }
  }
}
