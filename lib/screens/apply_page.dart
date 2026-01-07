import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ApplyPage extends StatefulWidget {
  const ApplyPage({super.key});

  @override
  State<ApplyPage> createState() => _ApplyPageState();
}

class _ApplyPageState extends State<ApplyPage> {
  final User? user = FirebaseAuth.instance.currentUser;
  bool isLoading = false;

  String? selectedRole;
  String? username;

  // Custom role controller
  final TextEditingController customRoleController = TextEditingController();

  // Default roles
  final List<String> roles = [
    "cleaner",
    "washer",
    "dishwasher",
    "housekeeping",
    "cooking",
    "delivery assistant",
    "custom",
  ];

  /// Fetch username
  Future<void> loadUsername() async {
    if (user == null) return;

    final userDoc = await FirebaseFirestore.instance
        .collection('users')
        .doc(user!.uid)
        .get();

    if (userDoc.exists) {
      setState(() {
        username = userDoc['username'];
      });
    }
  }

  ///  Submit / Update role
  Future<void> submitOrUpdateRole() async {
    if (user == null || username == null || selectedRole == null) return;

    // Validation only for custom
    if (selectedRole == "custom" &&
        customRoleController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please enter custom role")),
      );
      return;
    }

    setState(() => isLoading = true);

    await FirebaseFirestore.instance
        .collection('applications')
        .doc(user!.uid)
        .set({
      'uid': user!.uid,
      'username': username,
      'email': user!.email,

      // 🔹 ALWAYS save role as 'custom' or predefined
      'role': selectedRole,

      // 🔹 Save user-typed value every time
      'customRole': selectedRole == "custom"
          ? customRoleController.text.trim()
          : null,

      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    setState(() => isLoading = false);

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Role saved successfully")),
    );
  }
    /// Add custom role safely
  void addCustomRole() {
    final role = customRoleController.text.trim().toLowerCase();

    if (role.isEmpty) return;

    if (!roles.contains(role)) {
      setState(() {
        roles.add(role);
        selectedRole = role;
      });
    } else {
      setState(() {
        selectedRole = role;
      });
    }

    customRoleController.clear();
  }

  @override
  void initState() {
    super.initState();
    loadUsername();
  }

  @override
  void dispose() {
    customRoleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (user == null) {
      return const Scaffold(
        body: Center(child: Text("Not logged in")),
      );
    }

    return Scaffold(
      backgroundColor: Colors.grey[300],
      appBar: AppBar(title: const Text("Apply / Update Role")),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance
            .collection('applications')
            .doc(user!.uid)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final data = snapshot.data?.data() as Map<String, dynamic>?;

          // Preselect role
          if (data != null && selectedRole == null) {
            selectedRole = data['role'];
            if (!roles.contains(selectedRole)) {
              roles.add(selectedRole!);
            }
          }

          return Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Applied Role Font
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 25),
                  child: const Text(
                    "Your Applied Role",
                    style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold
                    ),
                  ),
                ),
                const SizedBox(height: 10),

                // Identity Card
                if (data != null) ...[
                  Card(
                    child: ListTile(
                      leading: const Icon(Icons.person),
                      title: Text("Username: ${data['username']}"),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text("Email: ${data['email']}"),
                          Text(
                            "Role: ${(data['role'] == "custom"
                                ? data['customRole']
                                : data['role'])?.toString().toUpperCase()}",
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),
                ],

                // Role selection and Custom
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 25),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.grey.shade200,
                      border: Border.all(color: Colors.white),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: DropdownButtonFormField<String>(
                        value: selectedRole,
                        hint: const Text("Select Role"),
                        items: roles.map((role) {
                          return DropdownMenuItem(
                            value: role,
                            child: Text(role.toUpperCase()),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() {
                            selectedRole = value;
                          });
                        },
                        decoration: const InputDecoration(border: InputBorder.none),
                      ),
                    ),
                  ),
                ),

                // If custom, show custom field
                if (selectedRole == "custom") ...[
                  const SizedBox(height: 15),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 25),
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.grey.shade200,
                        border: Border.all(color: Colors.white),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.only(left: 20),
                        child: TextField(
                          controller: customRoleController,
                          decoration: const InputDecoration(
                            labelText: "Enter Custom Role",
                            border: InputBorder.none,
                              contentPadding: EdgeInsets.symmetric(vertical: 3),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],

                const SizedBox(height: 30),

                // Update
                Center(
                  child: SizedBox(
                    width: 150,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.grey.shade900,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: isLoading ? null : submitOrUpdateRole,
                      child: Text(data == null ? "Apply" : "Update Role"),
                    ),
                  ),
                ),

              ],
            ),
          );
        },
      ),
    );
  }
}
