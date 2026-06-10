import 'dart:convert';
import 'package:http/http.dart' as http;

Future<String> getLyrics(String title, String artist) async {
  try {
    title = title.replaceAll(RegExp(r"[^\w\s]"), "");
    artist = artist.replaceAll(RegExp(r"[^\w\s]"), "");

    final url = Uri.parse("https://api.lyrics.ovh/v1/$artist/$title");

    final res = await http.get(url);

    if (res.statusCode == 200) {
      final data = jsonDecode(res.body);

      if (data['lyrics'] != null &&
          data['lyrics'].toString().trim().isNotEmpty) {
        return data['lyrics'];
      } else {
        return "Lirik tidak ditemukan 😢";
      }
    } else {
      return "Lirik tidak tersedia 😢";
    }
  } catch (e) {
    return "Gagal ambil lirik 😢";
  }
}
