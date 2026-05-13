import 'package:http/http.dart' as http;
import 'package:csv/csv.dart';
import '../models/psp_game.dart';

class NpsApiService {
  static const String pspGamesUrl = 'http://nopaystation.com/tsv/PSP_GAMES.tsv';

  Future<List<PspGame>> fetchPspGames() async {
    return _fetchAndParse(pspGamesUrl);
  }

  Future<List<PspGame>> _fetchAndParse(String url) async {
    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final rawTsv = response.body;
        // The first row is the header, skip it.
        final rows = const CsvDecoder(
          fieldDelimiter: '\t',
        ).convert(rawTsv);

        if (rows.isEmpty) return [];

        return rows
            .skip(1) // Skip header row
            .map((row) => PspGame.fromCsv(row))
            .where((g) => g.pkgLink.startsWith('http'))
            .toList();
      }
      return [];
    } catch (e) {
      print('Error fetching NPS data: $e');
      return [];
    }
  }
}
