import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/notif_service.dart';

const primaryBlue = Color(0xFF7DA7D9);
const softPink = Color(0xFFF7A6B8);
const deepBrown = Color(0xFF5D4037);
const bg = Color(0xFFF4F5F7);

class PaymentConfirmationPage extends StatefulWidget {
  final String planName;
  final double amount;
  final String currency;

  const PaymentConfirmationPage({
    super.key,
    required this.planName,
    required this.amount,
    required this.currency,
  });

  @override
  State<PaymentConfirmationPage> createState() =>
      _PaymentConfirmationPageState();
}

class _PaymentConfirmationPageState extends State<PaymentConfirmationPage> {
  String _selectedMethod = "QRIS";
  bool _isProcessing = false;

  final List<Map<String, dynamic>> _paymentMethods = [
    {"name": "QRIS", "icon": Icons.qr_code_2_rounded},
    {"name": "GoPay", "icon": Icons.account_balance_wallet_rounded},
    {"name": "Virtual Account BCA", "icon": Icons.account_balance_rounded},
    {"name": "Kartu Kredit / Debit", "icon": Icons.credit_card_rounded},
  ];

  String _getCurrencySymbol(String currency) {
    switch (currency) {
      case 'USD':
        return '\$';
      case 'IDR':
        return 'Rp ';
      case 'MYR':
        return 'RM ';
      case 'JPY':
        return '¥';
      case 'KRW':
        return '₩';
      case 'EUR':
        return '€';
      default:
        return '$currency ';
    }
  }

  void _processPayment() async {
    setState(() => _isProcessing = true);

    // Simulasi loading/proses transaksi selama 2.5 detik
    await Future.delayed(const Duration(milliseconds: 2500));

    if (!mounted) return;
    setState(() => _isProcessing = false);

    // Simpan status premium ke memori HP
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isPremium', true);
    await prefs.setString('premiumPlan', widget.planName);

    // Panggil notifikasi sistem
    NotifService.show(
      "Pembayaran Sukses! 🎉",
      "Paket ${widget.planName} kamu sudah aktif. Selamat menikmati fitur Premium!",
    );

    // Tampilkan dialog sukses
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.check_circle_rounded,
                color: Colors.green, size: 80),
            const SizedBox(height: 20),
            const Text("Pembayaran Berhasil!",
                style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: deepBrown)),
            const SizedBox(height: 10),
            Text("Selamat! ${widget.planName} kamu sudah aktif.",
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.grey)),
            const SizedBox(height: 20),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryBlue,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15)),
                minimumSize: const Size(double.infinity, 45),
              ),
              onPressed: () {
                // Lempar kembali ke halaman paling awal (Home)
                Navigator.of(context).popUntil((route) => route.isFirst);
              },
              child: const Text("Selesai & Mulai Eksplorasi",
                  style: TextStyle(
                      color: Colors.white, fontWeight: FontWeight.bold)),
            )
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    int decimals = ['IDR', 'KRW', 'JPY'].contains(widget.currency) ? 0 : 2;
    String formattedAmount = NumberFormat.currency(
            symbol: _getCurrencySymbol(widget.currency),
            decimalDigits: decimals)
        .format(widget.amount);

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        title: const Text("Konfirmasi Bayar",
            style: TextStyle(fontWeight: FontWeight.w600, color: Colors.white)),
        backgroundColor: primaryBlue,
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // -- Ringkasan Pesanan --
            const Text("Ringkasan Pesanan",
                style: TextStyle(
                    color: deepBrown,
                    fontSize: 18,
                    fontWeight: FontWeight.bold)),
            const SizedBox(height: 15),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                      color: Colors.black.withOpacity(0.03),
                      blurRadius: 10,
                      offset: const Offset(0, 4))
                ],
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                        color: softPink.withOpacity(0.2),
                        shape: BoxShape.circle),
                    child: const Icon(Icons.workspace_premium_rounded,
                        color: softPink, size: 30),
                  ),
                  const SizedBox(width: 15),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(widget.planName,
                            style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                                color: deepBrown)),
                        const SizedBox(height: 5),
                        const Text("Akses penuh ke semua fitur Premium",
                            style: TextStyle(color: Colors.grey, fontSize: 12)),
                      ],
                    ),
                  )
                ],
              ),
            ),
            const SizedBox(height: 30),

            // -- Total Tagihan --
            const Text("Total Tagihan",
                style: TextStyle(
                    color: deepBrown,
                    fontSize: 18,
                    fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: primaryBlue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(15),
                border: Border.all(color: primaryBlue.withOpacity(0.5)),
              ),
              child: Text(
                formattedAmount,
                textAlign: TextAlign.center,
                style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w900,
                    color: primaryBlue),
              ),
            ),
            const SizedBox(height: 30),

            // -- Metode Pembayaran --
            const Text("Pilih Metode",
                style: TextStyle(
                    color: deepBrown,
                    fontSize: 18,
                    fontWeight: FontWeight.bold)),
            const SizedBox(height: 15),
            ..._paymentMethods.map((method) {
              bool isSelected = _selectedMethod == method['name'];
              return GestureDetector(
                onTap: () => setState(() => _selectedMethod = method['name']),
                child: Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isSelected ? Colors.white : Colors.transparent,
                    borderRadius: BorderRadius.circular(15),
                    border: Border.all(
                        color: isSelected ? primaryBlue : Colors.grey.shade300,
                        width: 2),
                    boxShadow: isSelected
                        ? [
                            BoxShadow(
                                color: primaryBlue.withOpacity(0.1),
                                blurRadius: 10)
                          ]
                        : [],
                  ),
                  child: Row(
                    children: [
                      Icon(method['icon'],
                          color: isSelected ? primaryBlue : Colors.grey,
                          size: 28),
                      const SizedBox(width: 15),
                      Expanded(
                        child: Text(method['name'],
                            style: TextStyle(
                                fontWeight: isSelected
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                                color: isSelected
                                    ? primaryBlue
                                    : Colors.grey.shade700)),
                      ),
                      if (isSelected)
                        const Icon(Icons.check_circle_rounded,
                            color: primaryBlue),
                    ],
                  ),
                ),
              );
            }).toList(),

            const SizedBox(height: 40),

            // -- Tombol Bayar --
            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: softPink,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20)),
                  elevation: 0,
                ),
                onPressed: _isProcessing ? null : _processPayment,
                child: _isProcessing
                    ? const SizedBox(
                        height: 24,
                        width: 24,
                        child: CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 2))
                    : const Text("Bayar Sekarang",
                        style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white)),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
