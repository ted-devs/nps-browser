import 'package:http/http.dart' as http;
import 'package:csv/csv.dart';
import 'dart:isolate';
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
        
        // Parsing thousands of rows can block the UI thread.
        // Offload it to a separate isolate.
        return await Isolate.run(() {
          final rows = const CsvDecoder(
            fieldDelimiter: '\t',
          ).convert(rawTsv);

          if (rows.isEmpty) return <PspGame>[];

          final seenIds = <String>{};
          return rows
              .skip(1) // Skip header row
              .map((row) => PspGame.fromCsv(row))
              .where((g) {
                final isLinkValid = g.pkgLink.startsWith('http');
                final uniqueKey = '${g.titleId}_${g.region}';
                if (isLinkValid && !seenIds.contains(uniqueKey)) {
                  seenIds.add(uniqueKey);
                  return true;
                }
                return false;
              })
              .toList();
        });
      }
      return [];
    } catch (e) {
      print('Error fetching NPS data: $e');
      return [];
    }
  }
}
