import 'package:flutter/material.dart';
import '../auth/logout_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Profile"),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),

        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,

          children: [
            const SizedBox(height: 20),

            Center(
              child: CircleAvatar(
                radius: 50,
                backgroundColor: Colors.red.shade100,
                child: const Icon(
                  Icons.person,
                  size: 60,
                  color: Colors.red,
                ),
              ),
            ),

            const SizedBox(height: 20),

            const Text(
              "Name",
              style: TextStyle(fontSize: 14, color: Colors.black54),
            ),
            const Text(
              "John Doe",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 20),

            const Text(
              "Email",
              style: TextStyle(fontSize: 14, color: Colors.black54),
            ),
            const Text(
              "johndoe@gmail.com",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 20),

            const Text(
              "Phone Number",
              style: TextStyle(fontSize: 14, color: Colors.black54),
            ),
            const Text(
              "+977 9862025822",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 40),

            const Divider(),

            const SizedBox(height: 20),

            const Text(
              "App Version",
              style: TextStyle(fontSize: 14, color: Colors.black54),
            ),
            const Text(
              "1.0.0",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),

            const Spacer(),

            SizedBox(
              width: double.infinity,
              height: 50,
              child: OutlinedButton(
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Colors.red),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const LogoutScreen()),
                  );
                },
                child: const Text(
                  "Logout",
                  style: TextStyle(
                      fontSize: 18,
                      color: Colors.red,
                      fontWeight: FontWeight.w600),
                ),
              ),
            ),

            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
