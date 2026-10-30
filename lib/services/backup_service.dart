import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import 'package:cryptography/cryptography.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';

/// JSON backup transport. Import confirmation and integrity checks belong to UI flows.
class BackupService {
  const BackupService();

  static const maxPayloadBytes = 128 * 1024 * 1024;
  static const maxEnvelopeBytes = 180 * 1024 * 1024;

  /// Encrypts ZIP bytes. The entire versioned header is authenticated as AAD.
  Future<Map<String, dynamic>> encryptBytes(
    Uint8List content,
    String password,
  ) async {
    _validatePassword(password);
    if (content.length > maxPayloadBytes) {
      throw ArgumentError('O backup excede o limite de tamanho.');
    }
    final random = Random.secure();
    final salt = List<int>.generate(16, (_) => random.nextInt(256));
    final metadata = <String, dynamic>{
      'format': _encryptedFormat,
      'version': 2,
      'contentType': 'application/zip',
      'exportedAt': DateTime.now().toUtc().toIso8601String(),
      'kdf': 'Argon2id',
      'kdfMemory': _kdfMemory,
      'kdfIterations': _kdfIterations,
      'kdfParallelism': _kdfParallelism,
      'cipher': 'AES-256-GCM',
      'salt': base64Encode(salt),
      'payloadSize': content.length,
    };
    final box = await AesGcm.with256bits().encrypt(
      content,
      secretKey: await _deriveKey(password, salt),
      aad: utf8.encode(jsonEncode(metadata)),
    );
    return {...metadata, 'box': base64Encode(box.concatenation())};
  }

  Future<Uint8List> decryptBytes(
    Map<String, dynamic> envelope,
    String password,
  ) async {
    _validatePassword(password);
    const keys = [
      'format',
      'version',
      'contentType',
      'exportedAt',
      'kdf',
      'kdfMemory',
      'kdfIterations',
      'kdfParallelism',
      'cipher',
      'salt',
      'payloadSize',
    ];
    final size = envelope['payloadSize'];
    final stamp = envelope['exportedAt'];
    if (envelope.length != keys.length + 1 ||
        !keys.every(envelope.containsKey) ||
        envelope['format'] != _encryptedFormat ||
        envelope['version'] != 2 ||
        envelope['contentType'] != 'application/zip' ||
        envelope['kdf'] != 'Argon2id' ||
        envelope['cipher'] != 'AES-256-GCM' ||
        envelope['kdfMemory'] != _kdfMemory ||
        envelope['kdfIterations'] != _kdfIterations ||
        envelope['kdfParallelism'] != _kdfParallelism ||
        size is! int ||
        size < 0 ||
        size > maxPayloadBytes ||
        stamp is! String ||
        stamp.length > 40 ||
        DateTime.tryParse(stamp) == null) {
      throw const FormatException(
          'Cabeçalho do backup inválido ou incompatível.');
    }
    final salt = _decodeBase64(envelope['salt'], 'salt', maxBytes: 16);
    final boxBytes =
        _decodeBase64(envelope['box'], 'box', maxBytes: maxPayloadBytes + 28);
    if (salt.length != 16 || boxBytes.length != size + 28) {
      throw const FormatException('Tamanho do backup inválido.');
    }
    final metadata = <String, dynamic>{
      for (final key in keys) key: envelope[key]
    };
    final cipher = AesGcm.with256bits();
    final box = SecretBox.fromConcatenation(boxBytes,
        nonceLength: cipher.nonceLength,
        macLength: cipher.macAlgorithm.macLength);
    try {
      final payload = await cipher.decrypt(box,
          secretKey: await _deriveKey(password, salt),
          aad: utf8.encode(jsonEncode(metadata)));
      if (payload.length != size) {
        throw const FormatException('Tamanho do backup inválido.');
      }
      return Uint8List.fromList(payload);
    } on SecretBoxAuthenticationError {
      throw const FormatException('Senha incorreta ou backup adulterado.');
    }
  }

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
    await _validateFileSize(file);
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
    await _validateFileSize(file);
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
        envelope['kdfMemory'] != _kdfMemory ||
        envelope['kdfIterations'] != _kdfIterations ||
        envelope['kdfParallelism'] != _kdfParallelism ||
        envelope['cipher'] != 'AES-256-GCM') {
      throw const FormatException(
          'Formato de backup criptografado incompatível.');
    }
    final salt = _decodeBase64(envelope['salt'], 'salt', maxBytes: 16);
    final boxBytes =
        _decodeBase64(envelope['box'], 'box', maxBytes: maxPayloadBytes + 28);
    if (salt.length != 16 || boxBytes.length < 28) {
      throw const FormatException('Tamanho do backup inválido.');
    }
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

  static Future<void> _validateFileSize(File file) async {
    if (await file.length() > maxEnvelopeBytes) {
      throw const FormatException('O backup excede o limite de tamanho.');
    }
  }

  static List<int> _decodeBase64(Object? value, String field,
      {required int maxBytes}) {
    if (value is! String || value.isEmpty) {
      throw FormatException('Campo $field ausente no backup.');
    }
    if (value.length > ((maxBytes + 2) ~/ 3) * 4) {
      throw const FormatException('O backup excede o limite de tamanho.');
    }
    try {
      final bytes = base64Decode(value);
      if (bytes.length > maxBytes) {
        throw const FormatException('O backup excede o limite de tamanho.');
      }
      return bytes;
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
