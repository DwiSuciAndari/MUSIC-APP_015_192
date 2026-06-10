import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'home_page.dart';
import 'search_page.dart';
import 'chat_page.dart';
import 'profile_page.dart';
import 'wishlist_page.dart';
import 'feedback_page.dart';
import 'wishlist_controller.dart';

class MainPage extends StatefulWidget {
  const MainPage({super.key});

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  int currentIndex = 0;

  @override
  void initState() {
    super.initState();
    // Daftarkan controller di sini agar bisa diakses oleh semua halaman
    Get.put(WishlistController());
  }

  final List<Widget> pages = [
    const HomeDashboard(), // Menggunakan isi konten aslinya agar menu tidak double
    const SearchPage(),
    const ChatPage(),
    const WishlistPage(),
    const FeedbackPage(), // <-- Menggunakan FeedbackPage yang benar
    const ProfilePage(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: pages[currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: currentIndex,
        selectedItemColor:
            const Color(0xFF7DA7D9), // Sesuaikan dengan tema biru aplikasi
        // Untuk tipe shifting, warna diatur per item, bukan global
        unselectedItemColor: Colors.grey,
        type: BottomNavigationBarType
            .shifting, // Diubah agar bisa memuat > 5 item
        elevation: 10,
        onTap: (index) {
          setState(() {
            currentIndex = index;
          });
        },
        items: const [
          BottomNavigationBarItem(
              icon: Icon(Icons.grid_view_rounded),
              label: "Home",
              backgroundColor: Color(0xFF7DA7D9)),
          BottomNavigationBarItem(
              icon: Icon(Icons.search),
              label: "Discover",
              backgroundColor: Color(0xFF6a99c9)),
          BottomNavigationBarItem(
              icon: Icon(Icons.headphones),
              label: "AI DJ",
              backgroundColor: Color(0xFFF7A6B8)),
          BottomNavigationBarItem(
              icon: Icon(Icons.favorite_rounded),
              label: "Wishlist",
              backgroundColor: Colors.pinkAccent),
          BottomNavigationBarItem(
              icon: Icon(Icons.feedback_rounded),
              label: "Feedback TPM",
              backgroundColor: Colors.teal),
          BottomNavigationBarItem(
              icon: Icon(Icons.person),
              label: "Profile",
              backgroundColor: Color(0xFF5D4037)),
        ],
      ),
    );
  }
}
