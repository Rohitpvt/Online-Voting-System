// ignore_for_file: file_names, library_private_types_in_public_api, avoid_print, use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class NewPassPage extends StatefulWidget {
  final String phone;
  const NewPassPage({super.key, required this.phone});

  @override
  _NewPassPageState createState() => _NewPassPageState();
}

class _NewPassPageState extends State<NewPassPage> {
  final TextEditingController currentPasswordController =
      TextEditingController();
  final TextEditingController newPasswordController = TextEditingController();
  final TextEditingController confirmPasswordController =
      TextEditingController();

  String? password;

  bool currentPasswordVerified = false;
  bool passwordsMatch = true;
  bool isPasswordValid = false;
  bool showPasswordValidationMessage = false;
  bool showPasswordMatchMessage = false;
  bool isNewPasswordTyped = false;
  bool isConfirmPasswordTyped = false;

  // Visibility states
  bool currentPasswordVisible = false;
  bool newPasswordVisible = false;
  bool confirmPasswordVisible = false;

  // Focus nodes
  final FocusNode currentPasswordFocusNode = FocusNode();
  final FocusNode newPasswordFocusNode = FocusNode();
  final FocusNode confirmPasswordFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _fetchCurrentPassword();
  }

  @override
  void dispose() {
    currentPasswordFocusNode.dispose();
    newPasswordFocusNode.dispose();
    confirmPasswordFocusNode.dispose();
    super.dispose();
  }

  Future<void> _fetchCurrentPassword() async {
    try {
      DocumentSnapshot userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.phone)
          .get();
      setState(() {
        password = userDoc['password'] as String?;
      });
    } catch (e) {
      print('Failed to fetch current password: $e');
    }
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
        backgroundColor:
            Colors.transparent, // Make scaffold background transparent
        appBar: AppBar(
          backgroundColor:
              Colors.transparent, // Make app bar background transparent
          elevation: 0, // Remove shadow under app bar
          iconTheme: const IconThemeData(
            color: Colors.white, // Change the color of the back arrow to white
          ),
          toolbarHeight: 35, // Adjust the height as needed
        ),
        body: Container(
          padding: const EdgeInsets.only(right: 15, left: 15),
          width: double.infinity,
          child: Center(
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Change Password',
                    style: TextStyle(
                      fontSize: 30,
                      fontFamily: "urwbold",
                      color: Colors.white, // Change text color to white
                    ),
                  ),
                  const SizedBox(height: 33),
                  _buildPasswordTextField(
                    controller: currentPasswordController,
                    label: 'Current Password',
                    obscureText: !currentPasswordVisible,
                    isVisible: currentPasswordVisible,
                    focusNode: currentPasswordFocusNode,
                    nextFocusNode: newPasswordFocusNode,
                    onChanged: (value) {
                      setState(() {
                        currentPasswordVerified = value == password;
                      });
                    },
                    onVisibilityChanged: () {
                      setState(() {
                        currentPasswordVisible = !currentPasswordVisible;
                      });
                    },
                  ),
                  const SizedBox(height: 20),
                  _buildPasswordTextField(
                    controller: newPasswordController,
                    label: 'New Password',
                    obscureText: !newPasswordVisible,
                    isVisible: newPasswordVisible,
                    enabled: currentPasswordVerified,
                    focusNode: newPasswordFocusNode,
                    nextFocusNode: confirmPasswordFocusNode,
                    onChanged: (value) {
                      setState(() {
                        isNewPasswordTyped = true;
                        isPasswordValid = _validatePassword(value);
                        showPasswordValidationMessage =
                            isNewPasswordTyped && !isPasswordValid;

                        if (isPasswordValid) {
                          passwordsMatch =
                              value == confirmPasswordController.text;
                          showPasswordMatchMessage =
                              isConfirmPasswordTyped && !passwordsMatch;
                        } else {
                          showPasswordMatchMessage = false;
                        }
                      });
                    },
                    onVisibilityChanged: () {
                      setState(() {
                        newPasswordVisible = !newPasswordVisible;
                      });
                    },
                  ),
                  const SizedBox(height: 20),
                  _buildPasswordTextField(
                    controller: confirmPasswordController,
                    label: 'Confirm New Password',
                    obscureText: !confirmPasswordVisible,
                    isVisible: confirmPasswordVisible,
                    enabled: currentPasswordVerified && isPasswordValid,
                    focusNode: confirmPasswordFocusNode,
                    onChanged: (value) {
                      setState(() {
                        isConfirmPasswordTyped = true;
                        passwordsMatch = newPasswordController.text == value;
                        showPasswordMatchMessage =
                            isConfirmPasswordTyped && !passwordsMatch;
                      });
                    },
                    onVisibilityChanged: () {
                      setState(() {
                        confirmPasswordVisible = !confirmPasswordVisible;
                      });
                    },
                  ),
                  const SizedBox(height: 10),
                  if (showPasswordValidationMessage)
                    const Text(
                      'Password must be alphanumeric, one letter should be capital, include a special character, and have at least 9 digits.',
                      style: TextStyle(color: Colors.black54),
                    ),
                  if (showPasswordMatchMessage)
                    const Text(
                      'New password does not match. Enter new password again here.',
                      style: TextStyle(color: Colors.red),
                    ),
                  const SizedBox(height: 25),
                  ElevatedButton(
                    onPressed: currentPasswordVerified &&
                            passwordsMatch &&
                            isPasswordValid
                        ? () async {
                            String newPassword = newPasswordController.text;
                            try {
                              await FirebaseFirestore.instance
                                  .collection('users')
                                  .doc(widget.phone)
                                  .update({'password': newPassword});
                                
                              Navigator.of(context).pop();
                              ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text("Password Changed Successfully",style: TextStyle(fontFamily: "urmed",fontSize: 17),),
                                backgroundColor: Color(0xff4e5dc1), // Set your desired background color
                              ),
                            );
                            } catch (e) {
                              print('Failed to update password: $e');
                            }
                          }
                        : null,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                          vertical: 10, horizontal: 35), // Vertical Padding
                    ),
                    child: const Text(
                      'Change Password',
                      style: TextStyle(fontFamily: 'urwbold', fontSize: 18),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPasswordTextField({
    required TextEditingController controller,
    required String label,
    required bool obscureText,
    required bool isVisible,
    required FocusNode focusNode,
    FocusNode? nextFocusNode,
    bool enabled = true,
    required ValueChanged<String> onChanged,
    required VoidCallback onVisibilityChanged,
  }) {
    return TextField(
      controller: controller,
      obscureText: obscureText,
      enabled: enabled,
      focusNode: focusNode,
      textInputAction: nextFocusNode != null
          ? TextInputAction.next
          : TextInputAction.done, // Set text input action
      onSubmitted: (value) {
        if (nextFocusNode != null) {
          FocusScope.of(context).requestFocus(nextFocusNode);
        }
      },
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(
          fontFamily: "urwbold",
          fontSize: 18,
          color: Colors.black54,
        ),
        filled: true,
        fillColor: controller.text.isEmpty
            ? Colors.white.withOpacity(0.2)
            : Colors.white.withOpacity(0.2),
        border: const OutlineInputBorder(
          borderSide: BorderSide(color: Colors.white, width: 2),
        ),
        enabledBorder: const OutlineInputBorder(
          borderSide: BorderSide(color: Colors.white, width: 2),
        ),
        focusedBorder: const OutlineInputBorder(
          borderSide: BorderSide(color: Colors.white, width: 2),
        ),
        suffixIcon: IconButton(
          icon: Icon(
            isVisible ? Icons.visibility : Icons.visibility_off,
            color:
                controller.text.isEmpty ? Colors.grey : const Color(0xff4e5dc1),
          ),
          onPressed: onVisibilityChanged,
        ),
      ),
      onChanged: (value) {
        onChanged(value);
        setState(() {}); // To trigger a rebuild and apply the new opacity
      },
    );
  }

  bool _validatePassword(String password) {
    final hasUpperCase =
        password.contains(RegExp(r'[A-Z]')); // At least one uppercase letter
    final hasDigits = password.contains(RegExp(r'[0-9]'));
    final hasLowerCase = password.contains(RegExp(r'[a-z]'));
    final hasSpecialCharacters =
        password.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'));
    final isAtLeast9Characters = password.length >= 9;

    return hasUpperCase &&
        hasDigits &&
        hasLowerCase &&
        hasSpecialCharacters &&
        isAtLeast9Characters;
  }
}
