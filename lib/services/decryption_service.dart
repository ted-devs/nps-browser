import 'dart:ffi';
import 'dart:io';
import 'dart:isolate';
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

  /// Decrypts a PKG file to ISO.
  /// 
  /// [pkgPath]: The path to the downloaded .pkg file.
  /// [outputDir]: The directory where the extracted files should be placed.
  /// [zrif]: Optional zRIF string.
  /// Returns true if successful.
  Future<bool> decryptPkg(String pkgPath, String outputDir, {String? zrif}) async {
    return await Isolate.run(() async {
       final service = DecryptionService();
       service.initialize();
       return service._decryptPkgInternal(pkgPath, outputDir, zrif: zrif);
    });
  }

  // Actually, let's use Isolate.run properly.
  // Wait, I need to check if the user is on a version that supports Isolate.run.
  // Most modern apps are.

  Future<bool> _decryptPkgInternal(String pkgPath, String outputDir, {String? zrif}) async {
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
  }
}
