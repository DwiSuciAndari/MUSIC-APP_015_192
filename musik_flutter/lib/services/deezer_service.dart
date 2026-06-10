import 'dart:convert';
import 'package:http/http.dart' as http;

Future<List> searchMusic(String query) async {
  if (query.isEmpty) return [];

  final url = Uri.parse("https://api.deezer.com/search?q=$query");

  final res = await http.get(url);

  if (res.statusCode == 200) {
    final data = jsonDecode(res.body);
    return data['data'];
  } else {
    return [];
  }
}
