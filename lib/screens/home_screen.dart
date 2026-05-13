import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/psp_game.dart';
import '../services/nps_api_service.dart';
import '../widgets/game_card.dart';
import 'settings_screen.dart';
import 'downloads_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final NpsApiService _apiService = NpsApiService();

  List<PspGame> _allData = [];
  List<PspGame> _filteredData = [];

  bool _isLoading = true;
  String? _gameFolder;
  String _searchQuery = '';
  String _selectedRegion = 'All';

  final List<String> _regions = ['All', 'US', 'EU', 'JP', 'ASIA'];

  int _currentPage = 0;
  final int _itemsPerPage = 20;

  @override
  void initState() {
    super.initState();
    _checkFolderAndLoad();
  }

  Future<void> _checkFolderAndLoad() async {
    final prefs = await SharedPreferences.getInstance();
    final folder = prefs.getString('game_folder');
    setState(() {
      _gameFolder = folder;
    });

    if (folder != null && folder.isNotEmpty) {
      _loadData();
    } else {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      _allData = await _apiService.fetchPspGames();
      _applyFilters();
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _applyFilters() {
    setState(() {
      _currentPage = 0;

      _filteredData = _allData.where((g) {
        final matchesSearch =
            g.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
            g.titleId.toLowerCase().contains(_searchQuery.toLowerCase());
        final matchesRegion =
            _selectedRegion == 'All' || g.region == _selectedRegion;

        return matchesSearch && matchesRegion;
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    final isFolderSet = _gameFolder != null && _gameFolder!.isNotEmpty;

    return Scaffold(
      appBar: AppBar(
        title: const Text('NPS Browser'),
        actions: [
          IconButton(
            icon: const Icon(Icons.download),
            tooltip: 'Downloads',
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const DownloadsScreen()),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            tooltip: 'Settings',
            onPressed: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const SettingsScreen()),
              );
              _checkFolderAndLoad();
            },
          ),
        ],
      ),
      body: isFolderSet
          ? Column(
              children: [
                _buildFilters(),
                Expanded(
                  child: _isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : _buildGrid(_filteredData),
                ),
              ],
            )
          : Center(
              child: Padding(
                padding: const EdgeInsets.all(30.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.folder_open, size: 80, color: Colors.blueAccent),
                    const SizedBox(height: 20),
                    const Text(
                      'Game Folder Not Set',
                      style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      'Please select your PSP/GAME folder to start browsing and downloading games.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey),
                    ),
                    const SizedBox(height: 30),
                    ElevatedButton.icon(
                      onPressed: () async {
                        await Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const SettingsScreen()),
                        );
                        _checkFolderAndLoad();
                      },
                      icon: const Icon(Icons.settings),
                      label: const Text('SET PSP/GAME FOLDER'),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildFilters() {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Column(
        children: [
          TextField(
            decoration: InputDecoration(
              hintText: 'Search games...',
              prefixIcon: const Icon(Icons.search),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            onChanged: (value) {
              _searchQuery = value;
              _applyFilters();
            },
          ),
          const SizedBox(height: 12),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: _regions.map((region) {
                return Padding(
                  padding: const EdgeInsets.only(right: 8.0),
                  child: ChoiceChip(
                    label: Text(region),
                    selected: _selectedRegion == region,
                    onSelected: (selected) {
                      if (selected) {
                        setState(() {
                          _selectedRegion = region;
                          _applyFilters();
                        });
                      }
                    },
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGrid(List<PspGame> list) {
    if (list.isEmpty) {
      return const Center(child: Text('No results found.'));
    }

    final maxPage = (list.length / _itemsPerPage).ceil();
    final startIndex = _currentPage * _itemsPerPage;
    final endIndex = (startIndex + _itemsPerPage < list.length)
        ? startIndex + _itemsPerPage
        : list.length;
    final pageItems = list.sublist(startIndex, endIndex);

    return Column(
      children: [
        Expanded(
          child: GridView.builder(
            padding: const EdgeInsets.all(8),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 0.6,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
            ),
            itemCount: pageItems.length,
            itemBuilder: (context, index) {
              return GameCard(game: pageItems[index]);
            },
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          color: Theme.of(context).cardColor,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                icon: const Icon(Icons.chevron_left),
                onPressed: _currentPage > 0
                    ? () {
                        setState(() {
                          _currentPage--;
                        });
                      }
                    : null,
              ),
              Text(
                'Page ${_currentPage + 1} of $maxPage',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              IconButton(
                icon: const Icon(Icons.chevron_right),
                onPressed: _currentPage < maxPage - 1
                    ? () {
                        setState(() {
                          _currentPage++;
                        });
                      }
                    : null,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
