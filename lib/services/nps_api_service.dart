import 'package:http/http.dart' as http;
import 'package:csv/csv.dart';
import '../models/psp_game.dart';

class NpsApiService {
  static const String pspGamesUrl = 'http://nopaystation.com/tsv/PSP_GAMES.tsv';
  static const String pspDlcsUrl = 'http://nopaystation.com/tsv/PSP_DLCS.tsv';

  Future<List<PspGame>> fetchPspGames() async {
    return _fetchAndParse(pspGamesUrl, isDlc: false);
  }

  Future<List<PspGame>> fetchPspDlcs() async {
    return _fetchAndParse(pspDlcsUrl, isDlc: true);
  }

  Future<List<PspGame>> _fetchAndParse(String url, {required bool isDlc}) async {
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
            .map((row) => PspGame.fromCsv(row, isDlc: isDlc))
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
