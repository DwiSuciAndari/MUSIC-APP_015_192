import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

class WishlistController extends GetxController {
  // Variabel list reaktif (.obs) untuk menyimpan lagu yang disukai
  var likedSongs = <dynamic>[].obs;

  @override
  void onInit() {
    super.onInit();
    loadLikedSongs(); // Muat data langsung saat controller dipanggil pertama kali
  }

  // Mengambil daftar lagu dari penyimpanan memori HP
  void loadLikedSongs() async {
    final prefs = await SharedPreferences.getInstance();
    List<String> liked = prefs.getStringList('liked_songs') ?? [];
    likedSongs.value = liked.map((item) => jsonDecode(item)).toList();
  }

  // Mengecek apakah sebuah lagu spesifik ada di wishlist
  bool isLiked(dynamic id) {
    return likedSongs.any((song) => song['id'] == id);
  }

  // Fungsi menambah atau menghapus lagu
  void toggleLike(dynamic song) async {
    final prefs = await SharedPreferences.getInstance();

    if (isLiked(song['id'])) {
      likedSongs.removeWhere((item) => item['id'] == song['id']);
      Get.snackbar(
        "Wishlist 💔",
        "Dihapus dari Wishlist",
        backgroundColor: Colors.grey.shade800,
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
      );
    } else {
      likedSongs.insert(0, song);
      Get.snackbar(
        "Wishlist ❤️",
        "Ditambahkan ke Wishlist",
        backgroundColor: Colors.pinkAccent,
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
      );
    }

    // Simpan versi terbarunya kembali ke SharedPreferences
    List<String> stringList =
        likedSongs.map((item) => jsonEncode(item)).toList();
    await prefs.setStringList('liked_songs', stringList);
  }
}
