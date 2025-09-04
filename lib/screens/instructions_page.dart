import 'package:flutter/material.dart';

class InstructionsPage extends StatelessWidget {
  const InstructionsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("KYC Instructions")),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "📌 Please follow these steps:",
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                decoration: TextDecoration.underline,
              ),
            ),
            const SizedBox(height: 15),
            const Text("1️⃣ Take a selfie clearly showing your face."),
            const Text("2️⃣ Upload your Aadhaar/PAN document photo."),
            const Text("3️⃣ We will verify your face with the document photo."),
            const SizedBox(height: 30),
            Center(
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pushNamed(context, '/upload');
                },
                child: const Text("Proceed to Upload"),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
