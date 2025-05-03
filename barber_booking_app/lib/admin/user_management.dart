import 'package:barber_booking_app/services/database.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class UserManagement extends StatefulWidget {
  const UserManagement({super.key});

  @override
  State<UserManagement> createState() => _UserManagementState();
}

class _UserManagementState extends State<UserManagement> {
  final DatabaseMethods _database = DatabaseMethods();
  Stream<QuerySnapshot>? _usersStream;

  @override
  void initState() {
    _loadUsers();
    super.initState();
  }

  void _loadUsers() {
    _usersStream = _database.getUsers().asBroadcastStream();
    setState(() {});
  }

  Widget _buildUserListItem(DocumentSnapshot ds) {
    final userData = ds.data() as Map<String, dynamic>? ?? {};

    final userName = (userData['Name'] as String?)?.trim() ?? 'No name';
    final userEmail = (userData['Email'] as String?)?.trim() ?? 'No email';
    final avatarUrl = (userData['avatarUrl'] as String?)?.trim() ?? 
        'https://i.imgur.com/a6kQUGU.png';

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      child: ListTile(
        leading: CircleAvatar(
          backgroundImage: NetworkImage(avatarUrl),
          onBackgroundImageError: (_, __) =>
              const Icon(Icons.person, color: Colors.white),
        ),
        title: Text(userName),
        subtitle: Text(userEmail),
        trailing: IconButton(
          icon: const Icon(Icons.delete, color: Colors.red),
          onPressed: () => _confirmDeleteUser(ds.id),
        ),
      ),
    );
  }

  Future<void> _confirmDeleteUser(String userId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Confirm Deletion"),
        content: const Text("Are you sure you want to delete this user?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text("Delete", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await _database.deleteUser(userId);
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("User deleted successfully")));
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Error deleting user: ${e.toString()}")));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        appBar: AppBar(
          title: const Text("User Management"),
          backgroundColor: Colors.brown,
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: _loadUsers,
            )
          ],
        ),
        body: Column(
          children: [
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: _usersStream,
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return Center(child: Text('Error: ${snapshot.error}'));
                  }
                  
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return const Center(child: Text("No users found"));
                  }

                  return ListView.builder(
                    itemCount: snapshot.data!.docs.length,
                    itemBuilder: (context, index) {
                      final doc = snapshot.data!.docs[index];
                      return _buildUserListItem(doc);
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}