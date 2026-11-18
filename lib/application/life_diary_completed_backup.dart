import 'dart:convert';
import 'dart:math';

import 'package:cryptography/cryptography.dart';

import '../data/sqlite_life_diary_repository.dart';
import '../domain/life_diary_models.dart';

const _backupVersion = 1;
const _maxCiphertextLength = 65536;
final _backupIdPattern = RegExp(
  r'^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$',
);

/// One encrypted upload. Reuse it unchanged when retrying the same request.
/// Only [toRequestBody] is sent as the body. The recovery code stays with
/// the user and the backup ID and consent generation belong in the URL.
class PreparedLifeDiaryBackup {
  const PreparedLifeDiaryBackup._(
    this.backupId,
    this.generation,
    this._ciphertext,
    this.recoveryCode,
  );

  final String backupId;
  final int generation;
  final String _ciphertext;
  final String recoveryCode;

  Map<String, Object> toRequestBody() => {
    'format_version': _backupVersion,
    'ciphertext': _ciphertext,
  };
}

class LifeDiaryBackupReference {
  const LifeDiaryBackupReference._(this.generation, this.backupId, this._key);

  factory LifeDiaryBackupReference.parse(String code) {
    final parts = code.trim().split('.');
    if (parts.length != 4 ||
        parts[0] != 'ldentry1' ||
        !_backupIdPattern.hasMatch(parts[2])) {
      throw const FormatException('Invalid diary recovery code');
    }
    final generation = int.tryParse(parts[1]);
    if (generation == null || generation < 1) {
      throw const FormatException('Invalid diary recovery code');
    }
    List<int> key;
    try {
      key = base64Url.decode(parts[3]);
    } on FormatException {
      throw const FormatException('Invalid diary recovery code');
    }
    if (key.length != 32) {
      throw const FormatException('Invalid diary recovery code');
    }
    return LifeDiaryBackupReference._(generation, parts[2], SecretKey(key));
  }

  final int generation;
  final String backupId;
  final SecretKey _key;
}

/// Device-side encryption for an explicitly selected completed entry.
class LifeDiaryCompletedBackup {
  LifeDiaryCompletedBackup(this._repository);

  final SqliteLifeDiaryRepository _repository;
  final _cipher = AesGcm.with256bits();

  Future<PreparedLifeDiaryBackup> prepare({
    required String entryId,
    required String localOwnerId,
    required String accountId,
    required int generation,
  }) async {
    final entry = await _repository.findById(entryId);
    if (entry == null ||
        entry.ownerUserId != localOwnerId ||
        entry.status != LifeDiaryEntryStatus.completed) {
      throw StateError('Completed diary is unavailable');
    }

    final backupId = _newBackupId();
    final aad = _associatedData(accountId, generation, backupId);
    final payload = entry.toJson()..remove('owner_user_id');
    final key = await _cipher.newSecretKey();
    final box = await _cipher.encrypt(
      utf8.encode(jsonEncode(payload)),
      secretKey: key,
      aad: aad,
    );
    final ciphertext = base64Encode(box.concatenation());
    if (ciphertext.length > _maxCiphertextLength) {
      throw StateError('Encrypted diary exceeds the backup size limit');
    }

    final encodedKey = base64UrlEncode(await key.extractBytes());
    return PreparedLifeDiaryBackup._(
      backupId,
      generation,
      ciphertext,
      'ldentry1.$generation.$backupId.$encodedKey',
    );
  }

  Future<LifeDiaryRestoreResult> restore({
    required LifeDiaryBackupReference backup,
    required Map<String, Object?> response,
    required String localOwnerId,
    required String accountId,
  }) async {
    final encoded = response['ciphertext'];
    if (response['format_version'] != _backupVersion ||
        encoded is! String ||
        encoded.length > _maxCiphertextLength) {
      throw const FormatException('Invalid encrypted diary');
    }
    final bytes = base64Decode(encoded);
    if (bytes.length <= 28) {
      throw const FormatException('Invalid encrypted diary');
    }
    final box = SecretBox.fromConcatenation(
      bytes,
      nonceLength: 12,
      macLength: 16,
    );
    final plaintext = await _cipher.decrypt(
      box,
      secretKey: backup._key,
      aad: _associatedData(accountId, backup.generation, backup.backupId),
    );
    final payload = jsonDecode(utf8.decode(plaintext));
    if (payload is! Map<String, dynamic> ||
        payload['status'] != LifeDiaryEntryStatus.completed.wireValue ||
        payload.containsKey('owner_user_id')) {
      throw const FormatException('Invalid completed diary');
    }
    final entry = LifeDiaryEntry.fromJson({
      ...payload,
      'owner_user_id': localOwnerId,
    });
    return _repository.importCompletedBackup(entry);
  }
}

List<int> _associatedData(String accountId, int generation, String backupId) {
  if (accountId.isEmpty || generation < 1) {
    throw ArgumentError('Active account and backup consent generation required');
  }
  return utf8.encode(jsonEncode([
    'life-diary-completed-backup',
    _backupVersion,
    accountId,
    generation,
    backupId,
  ]));
}

String _newBackupId() {
  final random = Random.secure();
  final bytes = List.generate(16, (_) => random.nextInt(256));
  bytes[6] = (bytes[6] & 0x0f) | 0x40;
  bytes[8] = (bytes[8] & 0x3f) | 0x80;
  final hex = bytes.map((byte) => byte.toRadixString(16).padLeft(2, '0')).join();
  return '${hex.substring(0, 8)}-${hex.substring(8, 12)}-'
      '${hex.substring(12, 16)}-${hex.substring(16, 20)}-${hex.substring(20)}';
}
