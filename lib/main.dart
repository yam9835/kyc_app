import 'dart:convert';
import 'dart:typed_data';
import 'dart:html' as html; // For DigiLocker web redirection

import 'package:flutter/material.dart';
import 'package:image_picker_web/image_picker_web.dart';
import 'package:http/http.dart' as http;

void main() {
  runApp(const KycApp());
}

class KycApp extends StatelessWidget {
  const KycApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Lightweight KYC App',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
        fontFamily: "Arial",
      ),
      home: const LandingPage(),
    );
  }
}

// Landing Page
class LandingPage extends StatelessWidget {
  const LandingPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFE3F2FD), Color(0xFFBBDEFB)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                "Welcome to Bharat KYC",
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Colors.blueAccent,
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                "Secure • Simple • Fast",
                style: TextStyle(
                  fontSize: 22,
                  color: Colors.black54,
                ),
              ),
              const SizedBox(height: 50),

              ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const InstructionsPage()),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blueAccent,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                ),
                child: const Text("📜 Instructions", style: TextStyle(fontSize: 20)),
              ),
              const SizedBox(height: 20),

              ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const UploadPage()),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                ),
                child: const Text("📂 Upload KYC Documents", style: TextStyle(fontSize: 20)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Instructions Page
class InstructionsPage extends StatelessWidget {
  const InstructionsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("INSTRUCTIONS")),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFE3F2FD), Color(0xFFBBDEFB)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: ListView(
            children: const [
              Text(
                "Steps to Complete Your KYC",
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  decoration: TextDecoration.underline,
                ),
              ),
              SizedBox(height: 15),
              Text("1️⃣ Upload ONE government ID (Aadhaar, PAN, VoterID, or Driving License).", style: TextStyle(fontSize: 18)),
              SizedBox(height: 10),
              Text("2️⃣ Upload your recent Selfie for face verification.", style: TextStyle(fontSize: 18)),
              SizedBox(height: 10),
              Text("3️⃣ (Optional) You can connect DigiLocker for instant verification.", style: TextStyle(fontSize: 18)),
              SizedBox(height: 10),
              Text("4️⃣ Our system performs liveness and face match checks.", style: TextStyle(fontSize: 18)),
              SizedBox(height: 10),
              Text("5️⃣ You can retry if offline or poor internet.", style: TextStyle(fontSize: 18)),
              SizedBox(height: 20),
              Text(
                "⚠️ Ensure documents are clear and your face is well-lit.",
                style: TextStyle(color: Colors.red, fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Upload Page
class UploadPage extends StatefulWidget {
  const UploadPage({super.key});

  @override
  State<UploadPage> createState() => _UploadPageState();
}

class _UploadPageState extends State<UploadPage> {
  Uint8List? _idImage;
  Uint8List? _selfieImage;
  bool _isVerifying = false;
  String _verificationResult = "";

  // Pick ID
  Future<void> _pickIdDoc() async {
    final bytes = await ImagePickerWeb.getImageAsBytes();
    if (bytes != null) setState(() => _idImage = bytes);
  }

  // Pick Selfie
  Future<void> _pickSelfie() async {
    final bytes = await ImagePickerWeb.getImageAsBytes();
    if (bytes != null) setState(() => _selfieImage = bytes);
  }

  // Face verification via backend
  Future<void> _verifyFace() async {
    if (_idImage == null || _selfieImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("⚠️ Please upload both ID and Selfie")),
      );
      return;
    }

    setState(() {
      _isVerifying = true;
      _verificationResult = "";
    });

    try {
      String idBase64 = base64Encode(_idImage!);
      String selfieBase64 = base64Encode(_selfieImage!);

      final response = await http.post(
        Uri.parse("http://localhost:5000/verify-face"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "id_image": idBase64,
          "selfie_image": selfieBase64,
        }),
      );

      if (response.statusCode == 200) {
        final result = jsonDecode(response.body);
        setState(() {
          if (result["match"] == true) {
            _verificationResult = "✅ Face Match Successful";
          } else {
            _verificationResult = "❌ Face Match Failed";
            if (result["error"] != null) {
              _verificationResult += "\n⚠️ ${result["error"]}";
            }
          }
        });
      } else {
        setState(() {
          _verificationResult = "⚠️ Server error: ${response.statusCode}";
        });
      }
    } catch (e) {
      setState(() {
        _verificationResult = "⚠️ Error: $e";
      });
    } finally {
      setState(() => _isVerifying = false);
    }
  }

  // Submit KYC
  void _submitKyc() {
    if (_verificationResult.contains("✅")) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("✅ KYC Submitted Successfully")),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("⚠️ Complete face verification first")),
      );
    }
  }

  // DigiLocker
  void _openDigiLocker() {
    const url = "http://localhost:5000/digilocker/auth";
    html.window.open(url, "_self");
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Upload KYC Documents")),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFE3F2FD), Color(0xFFBBDEFB)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(30),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Step 1: ID Upload
                const Text(
                  "Step 1: Upload Government ID",
                  style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, decoration: TextDecoration.underline),
                ),
                const SizedBox(height: 15),
                ElevatedButton.icon(
                  onPressed: _pickIdDoc,
                  icon: const Icon(Icons.upload_file),
                  label: const Text("Upload Aadhaar / PAN / VoterID"),
                ),
                if (_idImage != null) ...[
                  const SizedBox(height: 10),
                  Image.memory(_idImage!, height: 160),
                ],
                const SizedBox(height: 40),

                // Step 2: Selfie Upload
                const Text(
                  "Step 2: Upload Selfie",
                  style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, decoration: TextDecoration.underline),
                ),
                const SizedBox(height: 15),
                ElevatedButton.icon(
                  onPressed: _pickSelfie,
                  icon: const Icon(Icons.camera_alt),
                  label: const Text("Upload Photo"),
                ),
                if (_selfieImage != null) ...[
                  const SizedBox(height: 10),
                  Image.memory(_selfieImage!, height: 160),
                ],
                const SizedBox(height: 40),

                // Step 3: Face Authentication
                const Text(
                  "Step 3: Face Authentication",
                  style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, decoration: TextDecoration.underline),
                ),
                const SizedBox(height: 10),
                if (_isVerifying)
                  const CircularProgressIndicator()
                else if (_verificationResult.isNotEmpty)
                  Text(
                    _verificationResult,
                    style: TextStyle(
                      fontSize: 18,
                      color: _verificationResult.contains("✅") ? Colors.green : Colors.red,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  )
                else
                  const Text(
                    "⚠️ Liveness & Face Match checks will run here.",
                    style: TextStyle(fontSize: 18),
                    textAlign: TextAlign.center,
                  ),
                const SizedBox(height: 20),
                ElevatedButton.icon(
                  onPressed: _verifyFace,
                  icon: const Icon(Icons.verified_user),
                  label: const Text("Run Face Verification"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                    foregroundColor: Colors.white,
                  ),
                ),
                const SizedBox(height: 30),

                // DigiLocker
                ElevatedButton.icon(
                  onPressed: _openDigiLocker,
                  icon: const Icon(Icons.account_balance_wallet),
                  label: const Text("Login with DigiLocker"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.deepPurple,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                  ),
                ),
                const SizedBox(height: 40),

                // Submit KYC
                ElevatedButton(
                  onPressed: _submitKyc,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 50, vertical: 18),
                  ),
                  child: const Text("Submit KYC", style: TextStyle(fontSize: 20)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
