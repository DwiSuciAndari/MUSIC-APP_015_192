import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'wishlist_controller.dart';
import 'detail_page.dart';

class WishlistPage extends StatelessWidget {
  const WishlistPage({super.key});

  @override
  Widget build(BuildContext context) {
    final WishlistController wishlistController = Get.put(WishlistController());

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Wishlist Saya ❤️",
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        backgroundColor: const Color(0xFF8FAADC),
        elevation: 1,
        automaticallyImplyLeading: false, // Menghilangkan tombol back
      ),
      body: Obx(() {
        // Obx akan otomatis me-refresh UI jika ada lagu yang ditambah/dihapus
        if (wishlistController.likedSongs.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.favorite_border, size: 80, color: Colors.grey),
                SizedBox(height: 16),
                Text(
                  "Wishlist masih kosong",
                  style: TextStyle(fontSize: 18, color: Colors.grey),
                ),
                Text(
                  "Sukailah lagu untuk menambahkannya di sini.",
                  style: TextStyle(color: Colors.grey),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          itemCount: wishlistController.likedSongs.length,
          itemBuilder: (context, index) {
            final song = wishlistController.likedSongs[index];
            return Card(
              margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: ListTile(
                contentPadding: const EdgeInsets.all(10),
                leading: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.network(
                    song['album']['cover_small'],
                    width: 50,
                    height: 50,
                    fit: BoxFit.cover,
                  ),
                ),
                title: Text(
                  song['title'],
                  style: const TextStyle(fontWeight: FontWeight.bold),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                subtitle: Text(song['artist']['name']),
                trailing: IconButton(
                  icon: const Icon(Icons.favorite_rounded,
                      color: Colors.redAccent),
                  onPressed: () => wishlistController.toggleLike(song),
                ),
                onTap: () => Navigator.push(context,
                    MaterialPageRoute(builder: (_) => DetailPage(song: song))),
              ),
            );
          },
        );
      }),
    );
  }
}
