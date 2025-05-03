import 'dart:convert';
import 'dart:io';
import 'package:barber_booking_app/services/cloudinary_service.dart';
import 'package:barber_booking_app/services/shared_pref.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';

class Profile extends StatefulWidget {
  const Profile({super.key, this.user, this.email});

  final String? user;
  final String? email;
  @override
  State<Profile> createState() => _ProfileState();
}

class _ProfileState extends State<Profile> {
  final GlobalKey<FormState> formKey = GlobalKey<FormState>();
  final TextEditingController nameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();

  bool isLoading = false;
  File? fileAvatar;

  @override
@override
void initState() {
  super.initState();
  final user = FirebaseAuth.instance.currentUser;
  nameController.text = widget.user ?? '';
  emailController.text = user?.email ?? widget.email ?? '';
}

  Future<void> pickAvatar() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.image,
    );
    if (result != null) {
      setState(() {
        fileAvatar = File(result.files.single.path!);
      });
    }
  }

Future<void> _updateProfile() async {
  if (!formKey.currentState!.validate()) return;

  setState(() => isLoading = true);

  try {
    final User? user = FirebaseAuth.instance.currentUser;
    if (user == null) throw Exception("User not logged in");

    // Upload ảnh mới nếu có
    String? avatarUrl;
    if (fileAvatar != null) {
      final response = await CloudinaryService.uploadImage(fileAvatar!);
      if (response == null) throw Exception("Upload failed");
      final jsonResponse = json.decode(response);
      avatarUrl = jsonResponse['secure_url'];
    }

    // Cập nhật Firestore
    final updateData = {
      "Name": nameController.text.trim(),
      if (avatarUrl != null) "avatarUrl": avatarUrl,
    };

    await FirebaseFirestore.instance
        .collection('Users')
        .doc(user.uid)
        .update(updateData);

    // Cập nhật SharedPreferences
    await SharedpreferenceHelper().saveUserName(nameController.text.trim());
    if (avatarUrl != null) {
      await SharedpreferenceHelper().saveUserAvatar(avatarUrl);
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("🎉 Profile updated successfully!")),
    );

    Navigator.pop(context, {
      'name': nameController.text.trim(),
      'avatar': avatarUrl,
    });
  } catch (e) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("❌ Error: ${e.toString()}")),
    );
  } finally {
    setState(() => isLoading = false);
  }
}

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        appBar: AppBar(
          title: const Text('My Profile'),
          centerTitle: true,
          backgroundColor: Colors.blueAccent,
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(20.0),
          child: Form(
            key: formKey,
            child: Column(
              children: [
                Center(child: _buildAvatar()),
                const SizedBox(height: 40.0),
                _buildInputField(
                  controller: nameController,
                  label: "Full Name",
                  icon: Icons.person,
                ),
                const SizedBox(height: 20.0),
                _buildInputField(
                  controller: emailController,
                  label: "Email",
                  icon: Icons.email,
                  readOnly: true,
                  customValidator: null,
                ),
                const SizedBox(height: 50.0),
                _buildSaveButton(),
                const SizedBox(height: 15.0),
                _buildBackButton(),
              ],
            ),
          ),
        ),
      ),
    );
  }

Widget _buildAvatar() {
  return FutureBuilder<String?>(
    future: SharedpreferenceHelper().getUserAvatar(),
    builder: (context, snapshot) {
      final avatarUrl = snapshot.data;
      return GestureDetector(
        onTap: isLoading ? null : pickAvatar,
        child: Stack(
          alignment: Alignment.center,
          children: [
            CircleAvatar(
              radius: 50,
              backgroundColor: Colors.grey.shade200,
              backgroundImage: fileAvatar != null
                  ? FileImage(fileAvatar!)
                  : avatarUrl != null
                      ? NetworkImage(avatarUrl)
                      : const AssetImage("assets/images/default_user.png")
                          as ImageProvider,
            ),
            Positioned(
              right: 0,
              bottom: 0,
              child: Container(
                padding: const EdgeInsets.all(6.0),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.camera_alt_outlined, color: Colors.pink),
              ),
            ),
          ],
        ),
      );
    },
  );
}

Widget _buildInputField({
  required TextEditingController controller,
  required String label,
  required IconData icon,
  bool readOnly = false,
  String? Function(String?)? customValidator,
}) {
  return TextFormField(
    controller: controller,
    readOnly: readOnly,
    decoration: InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon, color: Colors.blueAccent),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12.0),
      ),
      filled: true,
      fillColor: Colors.white,
    ),
    validator: customValidator ?? (value) {
      if (value == null || value.isEmpty) {
        return "Please enter your $label";
      }
      return null;
    },
  );
}

  Widget _buildSaveButton() {
    return SizedBox(
      width: double.infinity,
      height: 50.0,
      child: ElevatedButton(
        onPressed: isLoading ? null : _updateProfile,
        style: ElevatedButton.styleFrom(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30.0),
          ),
          padding: const EdgeInsets.symmetric(vertical: 14.0),
          backgroundColor: Colors.blueAccent,
        ),
        child: isLoading
            ? const CircularProgressIndicator(color: Colors.white)
            : const Text(
                "Save",
                style: TextStyle(fontSize: 18.0, color: Colors.white),
              ),
      ),
    );
  }

  Widget _buildBackButton() {
    return SizedBox(
      width: double.infinity,
      height: 50.0,
      child: OutlinedButton(
        onPressed: isLoading ? null : () => Navigator.pop(context),
        style: OutlinedButton.styleFrom(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30.0),
          ),
          side: const BorderSide(color: Colors.blueAccent),
        ),
        child: const Text(
          "Back",
          style: TextStyle(fontSize: 18.0, color: Colors.blueAccent),
        ),
      ),
    );
  }
}
