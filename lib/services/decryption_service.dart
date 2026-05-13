import 'dart:ffi';
import 'dart:io';
import 'package:ffi/ffi.dart';
import 'package:path/path.dart' as p;

typedef Pkg2ZipMainC = Int32 Function(Int32 argc, Pointer<Pointer<Utf8>> argv);
typedef Pkg2ZipMainDart = int Function(int argc, Pointer<Pointer<Utf8>> argv);

class DecryptionService {
  static final DecryptionService _instance = DecryptionService._internal();
  factory DecryptionService() => _instance;
  DecryptionService._internal();

  late DynamicLibrary _lib;
  late Pkg2ZipMainDart _pkg2zipMain;

  void initialize() {
    if (Platform.isAndroid) {
      _lib = DynamicLibrary.open('libpkg2zip.so');
    } else {
      // For future windows support
      _lib = DynamicLibrary.open('pkg2zip.dll');
    }
    _pkg2zipMain = _lib.lookupFunction<Pkg2ZipMainC, Pkg2ZipMainDart>('pkg2zip_main');
  }

  /// Decrypts a PKG file to ISO or extracts DLC.
  /// 
  /// [pkgPath]: The path to the downloaded .pkg file.
  /// [outputDir]: The directory where the extracted files should be placed.
  /// [zrif]: Optional zRIF string for Vita/DLC.
  /// Returns true if successful.
  Future<bool> decryptPkg(String pkgPath, String outputDir, {String? zrif}) async {
    // pkg2zip args:
    // pkg2zip [-x] [-l] [-c[N]] file.pkg [zRIF]
    // Note: pkg2zip usually creates a subfolder or puts it in the current working directory.
    // By default, pkg2zip creates 'pspemu/ISO' or 'addcont/...' in the CWD.
    // So we need to change the CWD of the Dart process temporarily, OR run it, then move the files.
    // Dart's Directory.current can be changed.
    
    var originalDir = Directory.current;
    try {
      Directory(outputDir).createSync(recursive: true);
      Directory.current = outputDir;

      List<String> args = ['pkg2zip', '-x', pkgPath];
      if (zrif != null && zrif.isNotEmpty) {
        args.add(zrif);
      }

      int argc = args.length;
      Pointer<Pointer<Utf8>> argv = calloc<Pointer<Utf8>>(argc);
      
      for (int i = 0; i < argc; i++) {
        argv[i] = args[i].toNativeUtf8();
      }

      // Run pkg2zip
      int result = _pkg2zipMain(argc, argv);

      // Free memory
      for (int i = 0; i < argc; i++) {
        calloc.free(argv[i]);
      }
      calloc.free(argv);

      // Now we might need to move files if pkg2zip created subdirectories like 'pspemu/ISO'
      // pkg2zip usually creates: `pspemu/ISO/Game Name [TitleID].iso`
      // We should flatten this if the user selected a specific PSP/GAME folder.
      _flattenPspemuFolder(outputDir);

      return result == 0;
    } catch (e) {
      print('Decryption failed: $e');
      return false;
    } finally {
      Directory.current = originalDir;
    }
  }

  void _flattenPspemuFolder(String baseDir) {
    // Check if pspemu/ISO exists
    var isoDir = Directory(p.join(baseDir, 'pspemu', 'ISO'));
    if (isoDir.existsSync()) {
      var files = isoDir.listSync(recursive: true).whereType<File>();
      for (var file in files) {
        if (file.path.toLowerCase().endsWith('.iso')) {
          file.renameSync(p.join(baseDir, p.basename(file.path)));
        }
      }
      // Clean up empty directories
      try { Directory(p.join(baseDir, 'pspemu')).deleteSync(recursive: true); } catch (_) {}
    }

    // Check if addcont exists (for DLC)
    var addcontDir = Directory(p.join(baseDir, 'addcont'));
    if (addcontDir.existsSync()) {
        // DLCs are usually in addcont/TitleID/DLC_ID
        // In PSP, DLCs go into PSP/GAME/TitleID.
        // Wait, pkg2zip puts Vita DLCs in addcont. For PSP, does it put it in pspemu/PSP/GAME?
        // Yes, pkg2zip puts PSP content in pspemu/PSP/GAME/TITLEID/
        var pspGameDir = Directory(p.join(baseDir, 'pspemu', 'PSP', 'GAME'));
        if (pspGameDir.existsSync()) {
            var items = pspGameDir.listSync();
            for (var item in items) {
                if (item is Directory) {
                    var targetDir = Directory(p.join(baseDir, p.basename(item.path)));
                    if (!targetDir.existsSync()) {
                        item.renameSync(targetDir.path);
                    }
                }
            }
            try { Directory(p.join(baseDir, 'pspemu')).deleteSync(recursive: true); } catch (_) {}
        }
    }
  }
}
