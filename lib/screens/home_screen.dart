import 'package:flutter/material.dart';
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
  String _searchQuery = '';
  String _selectedRegion = 'All';
  String _selectedType = 'Games';

  final List<String> _regions = ['All', 'US', 'EU', 'JP', 'ASIA'];
  final List<String> _types = ['All', 'Games', 'DLCs'];

  int _currentPage = 0;
  final int _itemsPerPage = 60;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final results = await Future.wait([
        _apiService.fetchPspGames(),
        _apiService.fetchPspDlcs(),
      ]);
      _allData = [...results[0], ...results[1]];
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

        bool matchesType = true;
        if (_selectedType == 'Games') {
          matchesType = !g.isDlc;
        } else if (_selectedType == 'DLCs') {
          matchesType = g.isDlc;
        }

        return matchesSearch && matchesRegion && matchesType;
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
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
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const SettingsScreen()),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          _buildFilters(),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _buildGrid(_filteredData),
          ),
        ],
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
              hintText: 'Search title or ID...',
              prefixIcon: const Icon(Icons.search),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              contentPadding: const EdgeInsets.symmetric(vertical: 0),
            ),
            onChanged: (val) {
              _searchQuery = val;
              _applyFilters();
            },
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              Row(
                children: [
                  const Text(
                    'Region:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(width: 8),
                  DropdownButton<String>(
                    value: _selectedRegion,
                    items: _regions.map((String value) {
                      return DropdownMenuItem<String>(
                        value: value,
                        child: Text(value),
                      );
                    }).toList(),
                    onChanged: (String? newValue) {
                      if (newValue != null) {
                        _selectedRegion = newValue;
                        _applyFilters();
                      }
                    },
                  ),
                ],
              ),
              Row(
                children: [
                  const Text(
                    'Type:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(width: 8),
                  DropdownButton<String>(
                    value: _selectedType,
                    items: _types.map((String value) {
                      return DropdownMenuItem<String>(
                        value: value,
                        child: Text(value),
                      );
                    }).toList(),
                    onChanged: (String? newValue) {
                      if (newValue != null) {
                        _selectedType = newValue;
                        _applyFilters();
                      }
                    },
                  ),
                ],
              ),
            ],
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
              childAspectRatio: 0.7,
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
