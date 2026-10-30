import 'dart:convert';
import 'dart:ffi';
import 'dart:io';

import 'package:ffi/ffi.dart';
import 'package:flutter/services.dart';
import 'package:path/path.dart' as path;

import 'app_storage_paths.dart';

abstract interface class SecretVault {
  Future<String?> read(String key);
  Future<void> write(String key, String value);
  Future<void> delete(String key);
}

/// Android Keystore and Windows DPAPI bind the backup password to this OS user.
class SystemSecretVault implements SecretVault {
  const SystemSecretVault();
  static const _channel = MethodChannel('com.danielcdesk.organiza/backup_folder');
  static const _backupKey = 'organiza.backup.password';

  static void _checkKey(String key) {
    if (key != _backupKey) throw ArgumentError('Chave de cofre desconhecida.');
  }

  @override
  Future<String?> read(String key) async {
    _checkKey(key);
    if (Platform.isAndroid) {
      return _channel.invokeMethod<String>('secretRead');
    }
    if (Platform.isWindows) {
      final file = await _secretFile();
      if (!await file.exists()) return null;
      return utf8.decode(_dpapi(await file.readAsBytes(), protect: false));
    }
    throw UnsupportedError('Cofre seguro indisponível nesta plataforma.');
  }

  @override
  Future<void> write(String key, String value) async {
    _checkKey(key);
    if (Platform.isAndroid) {
      await _channel.invokeMethod<void>('secretWrite', {'value': value});
      return;
    }
    if (Platform.isWindows) {
      final file = await _secretFile();
      final pending = File('${file.path}.pending');
      try {
        await pending.writeAsBytes(_dpapi(utf8.encode(value), protect: true),
            flush: true);
        if (await file.exists()) await file.delete();
        await pending.rename(file.path);
      } finally {
        if (await pending.exists()) await pending.delete();
      }
      return;
    }
    throw UnsupportedError('Cofre seguro indisponível nesta plataforma.');
  }

  @override
  Future<void> delete(String key) async {
    _checkKey(key);
    if (Platform.isAndroid) {
      await _channel.invokeMethod<void>('secretDelete');
      return;
    }
    if (Platform.isWindows) {
      final file = await _secretFile();
      if (await file.exists()) await file.delete();
      return;
    }
    throw UnsupportedError('Cofre seguro indisponível nesta plataforma.');
  }

  static Future<File> _secretFile() async {
    await AppStoragePaths.initialize();
    return File(path.join(
        AppStoragePaths.rootDirectory.path, 'backup-password.dpapi'));
  }

  static List<int> _dpapi(List<int> bytes, {required bool protect}) {
    final library = DynamicLibrary.open('crypt32.dll');
    final input = calloc<_DataBlob>();
    final output = calloc<_DataBlob>();
    final inputBytes = calloc<Uint8>(bytes.length);
    try {
      input.ref.length = bytes.length;
      input.ref.data = inputBytes;
      inputBytes.asTypedList(bytes.length).setAll(0, bytes);
      final int success;
      if (protect) {
        final call = library.lookupFunction<
            Int32 Function(Pointer<_DataBlob>, Pointer<Utf16>,
                Pointer<_DataBlob>, Pointer<Void>, Pointer<Void>, Uint32,
                Pointer<_DataBlob>),
            int Function(Pointer<_DataBlob>, Pointer<Utf16>,
                Pointer<_DataBlob>, Pointer<Void>, Pointer<Void>, int,
                Pointer<_DataBlob>)>('CryptProtectData');
        success = call(input, nullptr, nullptr, nullptr, nullptr, 0x1, output);
      } else {
        final call = library.lookupFunction<
            Int32 Function(Pointer<_DataBlob>, Pointer<Pointer<Utf16>>,
                Pointer<_DataBlob>, Pointer<Void>, Pointer<Void>, Uint32,
                Pointer<_DataBlob>),
            int Function(Pointer<_DataBlob>, Pointer<Pointer<Utf16>>,
                Pointer<_DataBlob>, Pointer<Void>, Pointer<Void>, int,
                Pointer<_DataBlob>)>('CryptUnprotectData');
        success = call(input, nullptr, nullptr, nullptr, nullptr, 0x1, output);
      }
      if (success == 0) throw StateError('Cofre do Windows indisponível.');
      return List<int>.of(output.ref.data.asTypedList(output.ref.length));
    } finally {
      if (output.ref.data != nullptr) {
        DynamicLibrary.open('kernel32.dll')
            .lookupFunction<Pointer<Void> Function(Pointer<Void>),
                Pointer<Void> Function(Pointer<Void>)>('LocalFree')(
          output.ref.data.cast<Void>());
      }
      calloc.free(inputBytes);
      calloc.free(input);
      calloc.free(output);
    }
  }
}

final class _DataBlob extends Struct {
  @Uint32()
  external int length;
  external Pointer<Uint8> data;
}
