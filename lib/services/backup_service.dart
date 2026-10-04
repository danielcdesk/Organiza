import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:cryptography/cryptography.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';

/// JSON backup transport. Import confirmation and integrity checks belong to UI flows.
class BackupService {
  const BackupService();

  static const _encryptedFormat = 'organiza.encrypted-backup';
  static const _encryptedVersion = 1;
  static const _kdfMemory = 32 * 1000;
  static const _kdfIterations = 2;
  static const _kdfParallelism = 2;
  static const _kdfHashLength = 32;

  Future<File> exportJson(Map<String, Object?> content) async {
    final directory = await getApplicationDocumentsDirectory();
    final folder = Directory(path.join(directory.path, 'Organiza', 'exports'));
    if (!folder.existsSync()) folder.createSync(recursive: true);
    final stamp = DateTime.now().toIso8601String().replaceAll(':', '-');
    final file = File(path.join(folder.path, 'organiza-$stamp.json'));
    await file.writeAsString(const JsonEncoder.withIndent('  ').convert({
      'format': 'organiza.json',
      'version': 1,
      'exportedAt': DateTime.now().toIso8601String(),
      'content': content,
    }));
    return file;
  }

  Future<Map<String, dynamic>> validateJson(File file) async {
    final parsed = jsonDecode(await file.readAsString());
    if (parsed is! Map<String, dynamic> ||
        parsed['format'] != 'organiza.json' ||
        parsed['version'] != 1) {
      throw const FormatException(
          'Arquivo de backup inválido ou incompatível.');
    }
    return parsed;
  }

  /// Writes a password-protected AES-256-GCM backup envelope.
  Future<File> exportEncrypted(
    Map<String, Object?> content,
    String password, {
    File? destination,
  }) async {
    final envelope = await encryptContent(content, password);
    final file = destination ?? await _newExportFile(encrypted: true);
    await file.writeAsString(
      const JsonEncoder.withIndent('  ').convert(envelope),
      flush: true,
    );
    return file;
  }

  /// Encrypts a snapshot without touching the filesystem, which keeps the
  /// cryptographic format straightforward to test and reuse in restore flows.
  Future<Map<String, Object?>> encryptContent(
    Map<String, Object?> content,
    String password,
  ) async {
    _validatePassword(password);
    final cipher = AesGcm.with256bits();
    final random = Random.secure();
    final salt = List<int>.generate(16, (_) => random.nextInt(256));
    final key = await _deriveKey(password, salt);
    final payload = utf8.encode(jsonEncode(content));
    final secretBox = await cipher.encrypt(payload, secretKey: key);
    final digest = await Sha256().hash(payload);
    return {
      'format': _encryptedFormat,
      'version': _encryptedVersion,
      'exportedAt': DateTime.now().toUtc().toIso8601String(),
      'schemaVersion': content['schemaVersion'],
      'kdf': 'Argon2id',
      'kdfMemory': _kdfMemory,
      'kdfIterations': _kdfIterations,
      'kdfParallelism': _kdfParallelism,
      'cipher': 'AES-256-GCM',
      'salt': base64Encode(salt),
      'box': base64Encode(secretBox.concatenation()),
      'payloadSha256': base64Encode(digest.bytes),
    };
  }

  Future<Map<String, dynamic>> decryptEncrypted(
    File file,
    String password,
  ) async {
    final parsed = jsonDecode(await file.readAsString());
    if (parsed is! Map<String, dynamic>) {
      throw const FormatException('Backup criptografado inválido.');
    }
    return decryptContent(parsed, password);
  }

  /// Decrypts and authenticates an encrypted envelope. A wrong password or a
  /// modified file fails before any database write can happen.
  Future<Map<String, dynamic>> decryptContent(
    Map<String, dynamic> envelope,
    String password,
  ) async {
    _validatePassword(password);
    if (envelope['format'] != _encryptedFormat ||
        envelope['version'] != _encryptedVersion ||
        envelope['kdf'] != 'Argon2id' ||
        envelope['cipher'] != 'AES-256-GCM') {
      throw const FormatException(
          'Formato de backup criptografado incompatível.');
    }
    final salt = _decodeBase64(envelope['salt'], 'salt');
    final boxBytes = _decodeBase64(envelope['box'], 'box');
    final cipher = AesGcm.with256bits();
    final secretBox = SecretBox.fromConcatenation(
      boxBytes,
      nonceLength: cipher.nonceLength,
      macLength: cipher.macAlgorithm.macLength,
    );
    final key = await _deriveKey(password, salt);
    final payload = await cipher.decrypt(secretBox, secretKey: key);
    final digest = await Sha256().hash(payload);
    if (base64Encode(digest.bytes) != envelope['payloadSha256']) {
      throw const FormatException('Hash do backup não confere.');
    }
    final decoded = jsonDecode(utf8.decode(payload));
    if (decoded is! Map<String, dynamic>) {
      throw const FormatException('Conteúdo do backup inválido.');
    }
    return decoded;
  }

  Future<SecretKey> _deriveKey(String password, List<int> salt) => Argon2id(
        memory: _kdfMemory,
        iterations: _kdfIterations,
        parallelism: _kdfParallelism,
        hashLength: _kdfHashLength,
      ).deriveKeyFromPassword(password: password, nonce: salt);

  Future<File> _newExportFile({required bool encrypted}) async {
    final directory = await getApplicationDocumentsDirectory();
    final folder = Directory(path.join(directory.path, 'Organiza', 'exports'));
    if (!folder.existsSync()) folder.createSync(recursive: true);
    final stamp = DateTime.now().toIso8601String().replaceAll(':', '-');
    return File(path.join(
        folder.path, 'organiza-$stamp.${encrypted ? 'backup' : 'json'}'));
  }

  static List<int> _decodeBase64(Object? value, String field) {
    if (value is! String || value.isEmpty) {
      throw FormatException('Campo $field ausente no backup.');
    }
    try {
      return base64Decode(value);
    } on FormatException {
      throw FormatException('Campo $field não é Base64 válido.');
    }
  }

  static void _validatePassword(String password) {
    if (password.length < 8) {
      throw ArgumentError(
          'A senha do backup deve ter pelo menos 8 caracteres.');
    }
  }
}
