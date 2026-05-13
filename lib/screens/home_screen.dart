import 'package:flutter/material.dart';
import '../models/psp_game.dart';
import '../services/nps_api_service.dart';
import '../widgets/game_card.dart';
import 'settings_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final NpsApiService _apiService = NpsApiService();
  
  List<PspGame> _games = [];
  List<PspGame> _dlcs = [];
  
  List<PspGame> _filteredGames = [];
  List<PspGame> _filteredDlcs = [];

  bool _isLoading = true;
  String _searchQuery = '';
  String _selectedRegion = 'All';

  int _gamesPage = 0;
  int _dlcsPage = 0;
  final int _itemsPerPage = 60;

  final List<String> _regions = ['All', 'USA', 'EUR', 'JPN', 'ASA'];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final results = await Future.wait([
        _apiService.fetchPspGames(),
        _apiService.fetchPspDlcs(),
      ]);
      _games = results[0];
      _dlcs = results[1];
      _applyFilters();
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _applyFilters() {
    setState(() {
      _gamesPage = 0;
      _dlcsPage = 0;
      
      _filteredGames = _games.where((g) {
        final matchesSearch = g.name.toLowerCase().contains(_searchQuery.toLowerCase()) || 
                              g.titleId.toLowerCase().contains(_searchQuery.toLowerCase());
        final matchesRegion = _selectedRegion == 'All' || g.region == _selectedRegion;
        return matchesSearch && matchesRegion;
      }).toList();

      _filteredDlcs = _dlcs.where((g) {
        final matchesSearch = g.name.toLowerCase().contains(_searchQuery.toLowerCase()) || 
                              g.titleId.toLowerCase().contains(_searchQuery.toLowerCase());
        final matchesRegion = _selectedRegion == 'All' || g.region == _selectedRegion;
        return matchesSearch && matchesRegion;
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
            icon: const Icon(Icons.settings),
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SettingsScreen())),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Games'),
            Tab(text: 'DLCs'),
          ],
        ),
      ),
      body: Column(
        children: [
          _buildFilters(),
          Expanded(
            child: _isLoading 
                ? const Center(child: CircularProgressIndicator())
                : TabBarView(
                    controller: _tabController,
                    children: [
                      _buildGrid(_filteredGames, false),
                      _buildGrid(_filteredDlcs, true),
                    ],
                  ),
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
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              contentPadding: const EdgeInsets.symmetric(vertical: 0),
            ),
            onChanged: (val) {
              _searchQuery = val;
              _applyFilters();
            },
          ),
          const SizedBox(height: 8),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: _regions.map((region) {
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4.0),
                  child: ChoiceChip(
                    label: Text(region),
                    selected: _selectedRegion == region,
                    onSelected: (selected) {
                      if (selected) {
                        _selectedRegion = region;
                        _applyFilters();
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

  Widget _buildGrid(List<PspGame> list, bool isDlc) {
    if (list.isEmpty) {
      return const Center(child: Text('No results found.'));
    }

    final currentPage = isDlc ? _dlcsPage : _gamesPage;
    final maxPage = (list.length / _itemsPerPage).ceil();
    final startIndex = currentPage * _itemsPerPage;
    final endIndex = (startIndex + _itemsPerPage < list.length) ? startIndex + _itemsPerPage : list.length;
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
                onPressed: currentPage > 0
                    ? () {
                        setState(() {
                          if (isDlc) {
                            _dlcsPage--;
                          } else {
                            _gamesPage--;
                          }
                        });
                      }
                    : null,
              ),
              Text('Page ${currentPage + 1} of $maxPage', style: const TextStyle(fontWeight: FontWeight.bold)),
              IconButton(
                icon: const Icon(Icons.chevron_right),
                onPressed: currentPage < maxPage - 1
                    ? () {
                        setState(() {
                          if (isDlc) {
                            _dlcsPage++;
                          } else {
                            _gamesPage++;
                          }
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
