// ignore_for_file: library_private_types_in_public_api, avoid_print, use_build_context_synchronously

import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'WelcomeScreen.dart';
import 'NewPass.dart';

class ProfilePage extends StatefulWidget {
  final String phone;
  const ProfilePage({super.key, required this.phone});
  @override
  _ProfilePageState createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  String? firstName;
  String? lastName;
  String? email;
  String? phoneNumber;
  String? age;
  bool isEligible = false;
  String? password;
  File? _image;
  String? _imageUrl;
  bool _isLoading = true;

  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _fetchUserData();
  }

  Future<void> _fetchUserData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      DocumentSnapshot userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.phone)
          .get();

      if (userDoc.exists) {
        print('User document data: ${userDoc.data()}');

        setState(() {
          firstName = capitalize(userDoc['firstName']);
          lastName = capitalize(userDoc['lastName']);
          email = userDoc['email']; // Corrected field name
          phoneNumber = userDoc['phoneNumber'];
          age = userDoc['Age'].toString();
          isEligible = int.parse(age ?? '0') >= 18;
          password = userDoc['password']; // Fetch password
          _imageUrl = userDoc['profileImage'] ?? '';
          _isLoading = false;
        });
      } else {
        print('Document does not exist');
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error fetching user data: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _uploadProfileImage() async {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt, color: Color(0xff4e5dc1)),
              title: const Text(
                'Upload New Image',
                style: TextStyle(
                    color: Color(0xff4e5dc1),
                    fontFamily: "urmed",
                    fontSize: 18),
              ),
              onTap: () async {
                final XFile? image =
                    await _picker.pickImage(source: ImageSource.gallery);
                if (image != null) {
                  setState(() {
                    _image = File(image.path);
                  });

                  // Upload the image to Firebase Storage
                  try {
                    // Delete old image if exists
                    if (_imageUrl != null && _imageUrl!.isNotEmpty) {
                      final oldImageRef =
                          FirebaseStorage.instance.refFromURL(_imageUrl!);
                      await oldImageRef.delete();
                    }

                    String fileName =
                        '${widget.phone}_${DateTime.now().millisecondsSinceEpoch}.jpg';
                    Reference storageRef = FirebaseStorage.instance
                        .ref()
                        .child('profile_images/$fileName');

                    UploadTask uploadTask = storageRef.putFile(_image!);
                    TaskSnapshot taskSnapshot = await uploadTask;

                    // Get the image URL
                    String imageUrl = await taskSnapshot.ref.getDownloadURL();

                    // Update Firestore with the new image URL
                    await FirebaseFirestore.instance
                        .collection('users')
                        .doc(widget.phone)
                        .update({
                      'profileImage': imageUrl,
                    });

                    setState(() {
                      _imageUrl = imageUrl;
                    });
                  } catch (e) {
                    print('Error uploading image: $e');
                  }
                }
                Navigator.of(context).pop();
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete, color: Color(0xff4e5dc1)),
              title: const Text(
                'Remove Image',
                style: TextStyle(
                    color: Color(0xff4e5dc1),
                    fontFamily: "urmed",
                    fontSize: 18),
              ),
              onTap: () async {
                // Remove the image from Firestore and Firebase Storage
                if (_imageUrl != null && _imageUrl!.isNotEmpty) {
                  try {
                    final imageRef =
                        FirebaseStorage.instance.refFromURL(_imageUrl!);
                    await imageRef
                        .delete(); // Delete image from Firebase Storage

                    await FirebaseFirestore.instance
                        .collection('users')
                        .doc(widget.phone)
                        .update({
                      'profileImage': FieldValue.delete(),
                    });

                    setState(() {
                      _image = null;
                      _imageUrl = '';
                    });
                  } catch (e) {
                    print('Error removing image: $e');
                  }
                }

                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  void _logout() async {
    // Show the confirmation dialog
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text(
            'Are you sure you want to Sign out?',
            style: TextStyle(
              fontFamily: "urwbold",
              fontSize: 20,
            ),
          ),
          actions: <Widget>[
            // Close icon on the left
            IconButton(
              icon: const Icon(
                Icons.close,
                color: Colors.red,
                size: 30,
              ),
              onPressed: () {
                Navigator.of(context).pop(); // Close the dialog
              },
            ),
            const SizedBox(width: 10),
            // Check icon on the right
            IconButton(
              icon: const Icon(
                Icons.check,
                color: Colors.green,
                size: 30,
              ),
              onPressed: () async {
                Navigator.of(context).pop(); // Close the dialog

                // Clear SharedPreferences
                final SharedPreferences prefs =
                    await SharedPreferences.getInstance();
                await prefs.clear();

                // Redirect to WelcomeScreen
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(
                    builder: (context) => const WelcomeScreen(),
                  ),
                  (Route<dynamic> route) => false,
                );
              },
            ),
          ],
        );
      },
    );
  }

  String capitalize(String text) {
    if (text.isEmpty) {
      return '';
    }
    return text.split(' ').map((word) {
      if (word.isEmpty) return '';
      return word[0].toUpperCase() + word.substring(1).toLowerCase();
    }).join(' ');
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFCAA1FF), Color(0xFF8DAFFF)],
        ),
      ),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0, // Remove shadow under app bar
          iconTheme: const IconThemeData(
            color: Colors.white, // Change the color of the back arrow to white
          ),
          toolbarHeight: 35,
        ),
        body: Padding(
          padding:
              const EdgeInsets.only(top: 5, right: 15, left: 15, bottom: 20),
          child: Column(
            children: [
              const Text('Profile',
                  style: TextStyle(
                    fontSize: 35,
                    fontFamily: "urwbold",
                    color: Colors.white,
                  )),
              // Container for Profile Picture
              Container(
                padding: const EdgeInsets.only(top: 5, bottom: 5),
                decoration: BoxDecoration(
                  color: Colors.transparent,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Center(
                  child: Stack(
                    children: [
                      Container(
                        width: 150, // Adjust the size as needed
                        height: 150, // Adjust the size as needed
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: Colors.white, // Border color
                            width: 4, // Border width
                          ),
                        ),
                        child: CircleAvatar(
                          radius: 70,
                          backgroundImage: _image != null
                              ? FileImage(_image!)
                              : (_imageUrl != null && _imageUrl!.isNotEmpty
                                  ? NetworkImage(_imageUrl!) as ImageProvider
                                  : const NetworkImage(
                                          'https://firebasestorage.googleapis.com/v0/b/voting-469a3.appspot.com/o/profile_images%2Fdefault_profile.png?alt=media&token=07d0fb05-652b-4cb6-ba8d-b1e49851e66e')
                                      as ImageProvider),
                        ),
                      ),
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: GestureDetector(
                          onTap: _uploadProfileImage,
                          child: const CircleAvatar(
                            backgroundColor: Colors.white,
                            child: Icon(
                              Icons.camera_alt,
                              color: Color(0xff4e5dc1),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 25),
              // Container for Profile Fields with Animation
              Expanded(
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : ListView(
                        children: [
                          _buildAnimatedProfileField(
                              "Name", "$firstName $lastName"),
                          _buildAnimatedProfileField("Age", age),
                          _buildAnimatedProfileField("Email", email),
                          _buildAnimatedProfileField(
                              "Phone Number", phoneNumber),
                          _buildAnimatedProfileField(
                              "Vote Eligible", isEligible ? 'Yes' : 'No'),
                          _buildAnimatedProfileField(
                              "Password",
                              password != null && password!.isNotEmpty
                                  ? '*' * password!.length
                                  : 'No password set'), // New container for password
                        ],
                      ),
              ),
              const SizedBox(height: 8),
              // LOG OUT button
              SizedBox(
                width: 150, height: 40, // Adjust the width as needed
                child: ElevatedButton(
                  onPressed: _logout,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.all(
                        10.0), // Adjust padding to reduce height and width
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(50.0),
                    ),
                    backgroundColor:
                        const Color.fromARGB(255, 255, 29, 29), // Button color
                  ),
                  child: const Text(
                    'SIGN OUT',
                    style: TextStyle(
                      fontSize: 16,
                      fontFamily: "urwbold",
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAnimatedProfileField(String label, String? value) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      margin: const EdgeInsets.only(bottom: 10.0),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.8),
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      height: 50.0,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            "$label: ",
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 19,
              fontFamily: "urwbold", // Set your desired font family here
            ),
          ),
          const SizedBox(width: 8.0),
          Expanded(
            child: Text(
              label == "Password"
                  ? (value != null && value.isNotEmpty
                      ? '*' * (value.length > 10 ? 10 : value.length)
                      : 'No password set')
                  : value ?? '',
              style: const TextStyle(
                color: Colors.black,
                fontSize: 19,
                fontFamily: "urmed", // Set your desired font family here
              ),
            ),
          ),
          if (label == "Password")
            Transform.translate(
              offset: const Offset(0, -4), // Move the icon up by 5 pixels
              child: IconButton(
                icon: const Icon(Icons.edit, color: Color(0xff4e5dc1)),
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => NewPassPage(
                          phone: widget.phone), // Pass the phone number here
                    ),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}
