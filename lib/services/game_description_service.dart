import 'package:http/http.dart' as http;
import 'dart:convert';

class GameDescriptionService {
  static Future<String?> getDescription(String gameName) async {
    try {
      // Step 1: Search for the game to get the correct Wikipedia title
      final searchUrl = Uri.parse(
          'https://en.wikipedia.org/w/api.php?action=query&format=json&list=search&srsearch=$gameName psp game');
      
      final searchResponse = await http.get(searchUrl);
      if (searchResponse.statusCode != 200) return null;

      final searchData = json.decode(searchResponse.body);
      final searchResults = searchData['query']['search'] as List;

      if (searchResults.isEmpty) return null;

      // Use the first result's title
      final wikiTitle = searchResults[0]['title'];
      
      // Step 2: Get the summary (extract) for that title
      final summaryUrl = Uri.parse(
          'https://en.wikipedia.org/api/rest_v1/page/summary/${Uri.encodeComponent(wikiTitle)}');
      
      final summaryResponse = await http.get(summaryUrl);
      if (summaryResponse.statusCode != 200) return null;

      final summaryData = json.decode(summaryResponse.body);
      return summaryData['extract'];
    } catch (e) {
      print('Error fetching description: $e');
      return null;
    }
  }
}
