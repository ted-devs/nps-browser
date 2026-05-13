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
  String _dlcFolder = '';

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _gameFolder = prefs.getString('gameFolder') ?? '';
      _dlcFolder = prefs.getString('dlcFolder') ?? '';
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
      await prefs.setString('gameFolder', selectedDirectory);
      setState(() {
        _gameFolder = selectedDirectory;
      });
    }
  }

  Future<void> _pickDlcFolder() async {
    await _requestPermissions();
    String? selectedDirectory = await FilePicker.getDirectoryPath();
    if (selectedDirectory != null) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('dlcFolder', selectedDirectory);
      setState(() {
        _dlcFolder = selectedDirectory;
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
          ListTile(
            title: const Text('DLC Folder (SAVEDATA)'),
            subtitle: Text(_dlcFolder.isEmpty ? 'Not set' : _dlcFolder),
            trailing: const Icon(Icons.folder_open),
            onTap: _pickDlcFolder,
          ),
        ],
      ),
    );
  }
}
