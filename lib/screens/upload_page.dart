import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../services/api_service.dart';
import 'package:flutter/foundation.dart'; // for kIsWeb
import 'dart:typed_data';

class UploadPage extends StatefulWidget {
  const UploadPage({super.key});

  @override
  State<UploadPage> createState() => _UploadPageState();
}

class _UploadPageState extends State<UploadPage> {
  File? selfie;
  File? documentPhoto;
  Uint8List? selfieBytes;
  Uint8List? documentBytes;

  bool isLoading = false;
  String result = "";

  final picker = ImagePicker();

  Future<void> pickImage(bool isSelfie) async {
    final pickedFile = await picker.pickImage(source: ImageSource.camera);

    if (pickedFile != null) {
      if (kIsWeb) {
        final bytes = await pickedFile.readAsBytes();
        setState(() {
          if (isSelfie) {
            selfieBytes = bytes;
          } else {
            documentBytes = bytes;
          }
        });
      } else {
        setState(() {
          if (isSelfie) {
            selfie = File(pickedFile.path);
          } else {
            documentPhoto = File(pickedFile.path);
          }
        });
      }
    }
  }

  Future<void> verifyFace() async {
    if ((selfie == null && selfieBytes == null) ||
        (documentPhoto == null && documentBytes == null)) {
      setState(() {
        result = "⚠️ Please upload both images.";
      });
      return;
    }

    setState(() {
      isLoading = true;
      result = "";
    });

    try {
      var response = await ApiService.verifyFace(selfie, documentPhoto);
      setState(() {
        result = response["verified"]
            ? "✅ Face Verified (Similarity: ${response["distance"]})"
            : "❌ Face Not Matched";
      });
    } catch (e) {
      setState(() {
        result = "Error: $e";
      });
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Upload & Verify Face")),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const Text(
              "📸 Upload Documents for KYC",
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                decoration: TextDecoration.underline,
              ),
            ),
            const SizedBox(height: 20),

            ElevatedButton(
              onPressed: () => pickImage(true),
              child: const Text("Take Selfie"),
            ),
            const SizedBox(height: 10),
            if (kIsWeb)
              selfieBytes != null
                  ? Image.memory(selfieBytes!, height: 120)
                  : const Text("No selfie selected")
            else
              selfie != null
                  ? Image.file(selfie!, height: 120)
                  : const Text("No selfie selected"),

            const SizedBox(height: 20),

            ElevatedButton(
              onPressed: () => pickImage(false),
              child: const Text("Upload Document Photo"),
            ),
            const SizedBox(height: 10),
            if (kIsWeb)
              documentBytes != null
                  ? Image.memory(documentBytes!, height: 120)
                  : const Text("No document photo selected")
            else
              documentPhoto != null
                  ? Image.file(documentPhoto!, height: 120)
                  : const Text("No document photo selected"),

            const SizedBox(height: 30),

            isLoading
                ? const CircularProgressIndicator()
                : ElevatedButton(
                    onPressed: verifyFace,
                    child: const Text("✅ Verify Face"),
                  ),

            const SizedBox(height: 20),
            Text(result, style: const TextStyle(fontSize: 18)),
          ],
        ),
      ),
    );
  }
}
