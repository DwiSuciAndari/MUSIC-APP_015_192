import 'dart:async';
import 'package:flutter/material.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

const primaryBlue = Color(0xFF7DA7D9);
const softPink = Color(0xFFF7A6B8);
const bg = Color(0xFFF4F5F7);

class NetworkPage extends StatefulWidget {
  const NetworkPage({super.key});

  @override
  State<NetworkPage> createState() => _NetworkPageState();
}

class _NetworkPageState extends State<NetworkPage> {
  String status = "Mengecek jaringan...";
  IconData netIcon = Icons.wifi_find;
  Color netColor = Colors.grey;

  int score = 0;
  bool isOnline = false;

  StreamSubscription? _subscription;

  @override
  void initState() {
    super.initState();
    checkNetwork();

    _subscription = Connectivity().onConnectivityChanged.listen((result) {
      _updateStatus(result is List ? result.first : result);
    });
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  Future<void> checkNetwork() async {
    var result = await Connectivity().checkConnectivity();
    _updateStatus(result is List ? result.first : result);
  }

  void _updateStatus(dynamic result) {
    setState(() {
      if (result == ConnectivityResult.none) {
        status = "Offline / Terputus ❌";
        netIcon = Icons.wifi_off_rounded;
        netColor = softPink;
        isOnline = false;
      } else if (result == ConnectivityResult.wifi) {
        status = "WiFi Terhubung 📶";
        netIcon = Icons.wifi_rounded;
        netColor = primaryBlue;
        _incrementScore();
      } else if (result == ConnectivityResult.mobile) {
        status = "Seluler Aktif 📱";
        netIcon = Icons.cell_tower_rounded;
        netColor = primaryBlue;
        _incrementScore();
      } else {
        status = "Online ✔";
        netIcon = Icons.public;
        netColor = primaryBlue;
        _incrementScore();
      }
    });

    if (mounted) {
      // Sembunyikan notif sebelumnya biar gak numpuk
      ScaffoldMessenger.of(context).hideCurrentSnackBar();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(netIcon, color: Colors.white, size: 28),
              const SizedBox(width: 15),
              Expanded(
                child: Text(
                  status,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
          backgroundColor: netColor,
          behavior: SnackBarBehavior.floating, // Bikin notifikasinya melayang
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          margin: const EdgeInsets.all(20),
          duration: const Duration(seconds: 3), // Hilang otomatis dalam 3 detik
          elevation: 10,
        ),
      );
    }
  }

  void _incrementScore() {
    if (!isOnline) {
      score++;
      isOnline = true;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        title: const Text("Network Sensor",
            style: TextStyle(fontWeight: FontWeight.w600)),
        backgroundColor: primaryBlue,
        foregroundColor: Colors.white,
        centerTitle: true,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 500),
                width: 160,
                height: 160,
                decoration: BoxDecoration(
                  color: isOnline ? Colors.white : softPink.withOpacity(0.2),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: netColor.withOpacity(isOnline ? 0.3 : 0.1),
                      blurRadius: isOnline ? 30 : 10,
                      spreadRadius: isOnline ? 10 : 0,
                    ),
                  ],
                ),
                child: Center(
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 300),
                    child: Icon(
                      netIcon,
                      key: ValueKey<IconData>(netIcon),
                      size: 70,
                      color: netColor,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 40),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(25),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.04),
                      blurRadius: 15,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Text(
                      "Status Jaringan",
                      style:
                          TextStyle(fontSize: 14, color: Colors.grey.shade600),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      status,
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: netColor,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 20),
                      child: Divider(),
                    ),
                    Text(
                      "Skor Reconnect",
                      style:
                          TextStyle(fontSize: 14, color: Colors.grey.shade600),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      "$score",
                      style: const TextStyle(
                        fontSize: 36,
                        fontWeight: FontWeight.w900,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 5),
                    const Text(
                      "Matikan dan nyalakan lagi koneksimu\nuntuk menambah skor!",
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
