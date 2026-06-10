import 'package:flutter/material.dart';

class FeedbackPage extends StatefulWidget {
  const FeedbackPage({super.key});

  @override
  State<FeedbackPage> createState() => _FeedbackPageState();
}

class _FeedbackPageState extends State<FeedbackPage> {
  final TextEditingController _saranCtrl = TextEditingController();
  final TextEditingController _kesanCtrl = TextEditingController();

  void _submitFeedback() {
    if (_saranCtrl.text.isEmpty || _kesanCtrl.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text("Harap isi Kesan dan Saran terlebih dahulu!")),
      );
      return;
    }

    // Simulasi pengiriman data
    FocusScope.of(context).unfocus();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
            "Kesan & Saran untuk Mata Kuliah TPM berhasil dikirim! Terimakasih."),
        backgroundColor: Color(0xFF7DA7D9),
      ),
    );
    _saranCtrl.clear();
    _kesanCtrl.clear();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F5F7),
      appBar: AppBar(
        title: const Text("Feedback TPM",
            style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
        backgroundColor: const Color(0xFF7DA7D9),
        centerTitle: true,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFF7DA7D9).withOpacity(0.1),
                borderRadius: BorderRadius.circular(15),
                border: Border.all(color: const Color(0xFF7DA7D9)),
              ),
              child: const Row(
                children: [
                  Icon(Icons.school, color: Color(0xFF7DA7D9), size: 40),
                  SizedBox(width: 15),
                  Expanded(
                    child: Text(
                      "Halaman ini didedikasikan untuk memenuhi syarat Evaluasi Mata Kuliah TPM.",
                      style: TextStyle(
                          color: Colors.black87, fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 30),
            const Text("Kesan Mata Kuliah TPM:",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            TextField(
              controller: _kesanCtrl,
              maxLines: 4,
              decoration: InputDecoration(
                hintText:
                    "Tuliskan kesan Anda selama mengikuti mata kuliah ini...",
                filled: true,
                fillColor: Colors.white,
                border:
                    OutlineInputBorder(borderRadius: BorderRadius.circular(15)),
              ),
            ),
            const SizedBox(height: 20),
            const Text("Saran Mata Kuliah TPM:",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            TextField(
              controller: _saranCtrl,
              maxLines: 4,
              decoration: InputDecoration(
                hintText: "Tuliskan saran Anda untuk perbaikan ke depannya...",
                filled: true,
                fillColor: Colors.white,
                border:
                    OutlineInputBorder(borderRadius: BorderRadius.circular(15)),
              ),
            ),
            const SizedBox(height: 30),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF7DA7D9),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15)),
                ),
                onPressed: _submitFeedback,
                child: const Text("Kirim Feedback",
                    style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
