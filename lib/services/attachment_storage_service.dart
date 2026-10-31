import 'dart:io';
import 'dart:typed_data';

import 'package:cryptography/cryptography.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path/path.dart' as path;
import 'package:uuid/uuid.dart';

import 'app_storage_paths.dart';

class StoredAttachment {
  const StoredAttachment({
    required this.relativePath,
    required this.mimeType,
    required this.sizeBytes,
    required this.sha256,
  });
  final String relativePath;
  final String mimeType;
  final int sizeBytes;
  final String sha256;
}

/// Private, bounded storage for transaction receipts and supporting files.
class AttachmentStorageService {
  const AttachmentStorageService();

  static const maxBytes = 10 * 1024 * 1024;
  static const allowedExtensions = {
    '.jpg',
    '.jpeg',
    '.png',
    '.webp',
    '.gif',
    '.pdf'
  };

  Future<StoredAttachment?> pickAndStore() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: const ['jpg', 'jpeg', 'png', 'webp', 'gif', 'pdf'],
      withData: true,
    );
    if (result == null || result.files.isEmpty) return null;
    final selected = result.files.single;
    final ext = path.extension(selected.name).toLowerCase();
    if (!allowedExtensions.contains(ext) ||
        selected.size <= 0 ||
        selected.size > maxBytes) {
      return null;
    }
    final bytes = selected.bytes ??
        (selected.path == null
            ? null
            : await File(selected.path!).readAsBytes());
    if (bytes == null) return null;
    return storeBytes(bytes, ext);
  }

  Future<StoredAttachment> storeFile(File source) async {
    if (await FileSystemEntity.type(source.path, followLinks: false) !=
        FileSystemEntityType.file) {
      throw const FormatException('Selecione um arquivo regular.');
    }
    final extension = path.extension(source.path).toLowerCase();
    if (!allowedExtensions.contains(extension)) {
      throw const FormatException('Extensão de arquivo não permitida.');
    }
    if (await source.length() > maxBytes) {
      throw const FormatException('O arquivo excede 10 MiB.');
    }
    return storeBytes(await source.readAsBytes(), extension);
  }

  Future<StoredAttachment> storeBytes(
      List<int> source, String extension) async {
    final ext = extension.startsWith('.')
        ? extension.toLowerCase()
        : '.$extension'.toLowerCase();
    if (!allowedExtensions.contains(ext) ||
        source.isEmpty ||
        source.length > maxBytes) {
      throw const FormatException('Arquivo não permitido ou acima de 10 MiB.');
    }
    final bytes = Uint8List.fromList(source);
    final mime = _mimeFor(bytes);
    if (mime == null ||
        _extensionForMime(mime) != ext &&
            !(ext == '.jpeg' && mime == 'image/jpeg')) {
      throw const FormatException(
          'O conteúdo do arquivo não corresponde ao tipo permitido.');
    }
    await AppStoragePaths.initialize();
    final filename = '${const Uuid().v4()}$ext';
    final relative = 'attachments/$filename';
    final target = fileFor(relative);
    final pending = File('${target.path}.part');
    try {
      await pending.writeAsBytes(bytes, flush: true);
      await pending.rename(target.path);
    } finally {
      if (await pending.exists()) await pending.delete();
    }
    return StoredAttachment(
      relativePath: relative,
      mimeType: mime,
      sizeBytes: bytes.length,
      sha256: await _digest(bytes),
    );
  }

  File fileFor(String relativePath) =>
      AppStoragePaths.resolveAttachment(relativePath);

  Future<Uint8List> readVerified(
      {required String relativePath,
      required int sizeBytes,
      required String sha256}) async {
    final file = fileFor(relativePath);
    if (await FileSystemEntity.type(file.path, followLinks: false) !=
            FileSystemEntityType.file ||
        await file.length() != sizeBytes ||
        sizeBytes <= 0 ||
        sizeBytes > maxBytes) {
      throw const FormatException(
          'O anexo não está disponível ou foi alterado.');
    }
    final bytes = await file.readAsBytes();
    if (await _digest(bytes) != sha256) {
      throw const FormatException('A integridade do anexo não confere.');
    }
    return bytes;
  }

  Future<void> delete(String relativePath) async {
    final file = fileFor(relativePath);
    if (await file.exists()) await file.delete();
  }

  Future<void> deleteFile(String relativePath) => delete(relativePath);

  Future<String> sha256For(List<int> bytes) => _digest(bytes);

  static String? _mimeFor(List<int> b) {
    bool starts(List<int> prefix) =>
        b.length >= prefix.length &&
        List.generate(prefix.length, (i) => b[i] == prefix[i]).every((x) => x);
    if (starts([0xff, 0xd8, 0xff])) return 'image/jpeg';
    if (starts([137, 80, 78, 71, 13, 10, 26, 10])) return 'image/png';
    if (b.length >= 12 &&
        String.fromCharCodes(b.sublist(0, 4)) == 'RIFF' &&
        String.fromCharCodes(b.sublist(8, 12)) == 'WEBP') {
      return 'image/webp';
    }
    if (starts('GIF87a'.codeUnits) || starts('GIF89a'.codeUnits)) {
      return 'image/gif';
    }
    if (starts('%PDF-'.codeUnits)) return 'application/pdf';
    return null;
  }

  static String? _extensionForMime(String mime) => switch (mime) {
        'image/jpeg' => '.jpg',
        'image/png' => '.png',
        'image/webp' => '.webp',
        'image/gif' => '.gif',
        'application/pdf' => '.pdf',
        _ => null,
      };

  static Future<String> _digest(List<int> bytes) async =>
      (await Sha256().hash(bytes))
          .bytes
          .map((b) => b.toRadixString(16).padLeft(2, '0'))
          .join();
}
