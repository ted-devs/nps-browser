import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:permission_handler/permission_handler.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({Key? key}) : super(key: key);

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  String _gameFolder = '';
  bool _largerTiles = false;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _gameFolder = prefs.getString('game_folder') ?? '';
      _largerTiles = prefs.getBool('larger_tiles') ?? false;
    });
  }

  Future<void> _toggleLargerTiles(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('larger_tiles', value);
    setState(() {
      _largerTiles = value;
    });
  }

  Future<void> _requestPermissions() async {
    if (await Permission.manageExternalStorage.isDenied) {
      await Permission.manageExternalStorage.request();
    }
    if (await Permission.storage.isDenied) {
      await Permission.storage.request();
    }
  }

  Future<void> _pickGameFolder() async {
    await _requestPermissions();
    String? selectedDirectory = await FilePicker.getDirectoryPath();
    if (selectedDirectory != null) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('game_folder', selectedDirectory);
      setState(() {
        _gameFolder = selectedDirectory;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          const Text(
            'Storage Configuration',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.blueAccent),
          ),
          const SizedBox(height: 16),
          ListTile(
            title: const Text('Game Folder (ISOs)'),
            subtitle: Text(_gameFolder.isEmpty ? 'Not set (Required)' : _gameFolder),
            trailing: const Icon(Icons.folder_open),
            onTap: _pickGameFolder,
          ),
          const Divider(),
          const SizedBox(height: 16),
          const Text(
            'Interface Settings',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.blueAccent),
          ),
          const SizedBox(height: 8),
          SwitchListTile(
            title: const Text('Larger Tiles'),
            subtitle: const Text('Use a 2-column grid layout'),
            value: _largerTiles,
            onChanged: _toggleLargerTiles,
          ),
          const Divider(),
          const SizedBox(height: 16),
          const Text(
            'About',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.blueAccent),
          ),
          const SizedBox(height: 8),
          const ListTile(
            leading: Icon(Icons.info_outline, color: Colors.blueAccent),
            title: Text('NPS Browser'),
            subtitle: Text(
              'A high-performance PSP game manager and downloader. '
              'Browse, search, and download your favorite PSP titles directly to your device.',
            ),
          ),
          const ListTile(
            leading: Icon(Icons.person_outline, color: Colors.blueAccent),
            title: Text('Developer'),
            subtitle: Text('Talha Salman'),
          ),
          const ListTile(
            leading: Icon(Icons.verified_outlined, color: Colors.blueAccent),
            title: Text('Version'),
            subtitle: Text('0.0.2 (Release Candidate)'),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }
}
