import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:organiza/database/app_database.dart';
import 'package:path/path.dart' as path;
import 'package:sqlite3/sqlite3.dart';

void main() {
  test(
      'schema 16 repairs a missing table and preserves the legacy subscription column',
      () async {
    final folder = await Directory.systemTemp.createTemp('organiza-schema16-');
    addTearDown(() => folder.delete(recursive: true));
    final file = File(path.join(folder.path, 'organiza.db'));
    final old = AppDatabase.openInMemoryAtVersionForTest(16);
    await old.createConsistentCopy(file);
    old.close();
    final raw = sqlite3.open(file.path);
    raw.execute('DROP TABLE card_installment_payments');
    raw.execute(
        "ALTER TABLE subscriptions ADD COLUMN icon_key TEXT NOT NULL DEFAULT 'savings'");
    raw.execute('''
      INSERT INTO subscriptions
        (id, name, amount_cents, billing_day, category, is_active, created_at, icon_key)
      VALUES ('legacy-subscription', 'Streaming', 1500, 10, 'Lazer', 1,
        '2026-01-01T00:00:00.000', 'movie');
    ''');
    raw.close();

    final upgraded = AppDatabase.openFile(file);
    expect(upgraded.schemaVersion, AppDatabase.currentSchemaVersion);
    expect(upgraded.tableCounts, contains('card_installment_payments'));
    upgraded.close();
    final migrated = sqlite3.open(file.path, mode: OpenMode.readOnly);
    addTearDown(migrated.close);
    expect(
      migrated.select('SELECT icon_key FROM subscriptions WHERE id = ?',
          ['legacy-subscription']).single['icon_key'],
      'movie',
    );
  });
}
