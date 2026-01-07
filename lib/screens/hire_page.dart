import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class HirePage extends StatelessWidget {
  const HirePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[300],
      appBar: AppBar(
        title: const Text("Hire Applicants"),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('applications')
            .orderBy('updatedAt', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          // Loading state
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          // Empty state
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(
              child: Text(
                "No applicants yet",
                style: TextStyle(fontSize: 16),
              ),
            );
          }

          final applicants = snapshot.data!.docs;

          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: applicants.length,
            itemBuilder: (context, index) {
              final doc = applicants[index];
              final data = doc.data() as Map<String, dynamic>;

              final String username = data['username'] ?? 'Unknown';
              final Timestamp? updatedAt = data['updatedAt'];

              final String displayRole =
              data['role'] == "custom"
                  ? (data['customRole'] ?? "CUSTOM")
                  : (data['role'] ?? "N/A");

              return Card(
                elevation: 2,
                margin: const EdgeInsets.symmetric(vertical: 8),
                child: ListTile(
                  leading: const Icon(Icons.person),

                  // Username only (NO EMAIL)
                  title: Text(username),

                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Role: ${displayRole.toUpperCase()}",
                        style: const TextStyle(fontWeight: FontWeight.w500),
                      ),

                      if (updatedAt != null)
                        Text(
                          "Updated: ${updatedAt.toDate().day}-"
                              "${updatedAt.toDate().month}-"
                              "${updatedAt.toDate().year}",
                          style: const TextStyle(fontSize: 12),
                        ),
                    ],
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
