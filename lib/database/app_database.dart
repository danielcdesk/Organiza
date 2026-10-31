import 'dart:io';

import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:sqlite3/sqlite3.dart';
import 'package:uuid/uuid.dart';

import '../domain/models.dart';

/// Owns schema migrations and keeps user data on the local machine only.
class AppDatabase {
  AppDatabase._(this._database, {this.filePath});

  final Database _database;
  int _transactionDepth = 0;
  final String? filePath;
  static int get currentSchemaVersion => _schemaVersion;
  static const _schemaVersion = 19;
  static const _auditTables = <String>[
    'transactions',
    'accounts',
    'credit_cards',
    'card_purchases',
    'investments',
    'budgets',
    'subscriptions',
    'financial_goals',
    'shopping_items',
    'tasks',
  ];
  static const _auditTriggerNames = <String>{
    'audit_transactions_insert',
    'audit_transactions_update',
    'audit_accounts_insert',
    'audit_accounts_update',
    'audit_credit_cards_insert',
    'audit_credit_cards_update',
    'audit_card_purchases_insert',
    'audit_card_purchases_update',
    'audit_investments_insert',
    'audit_investments_update',
    'audit_budgets_insert',
    'audit_budgets_update',
    'audit_subscriptions_insert',
    'audit_subscriptions_update',
    'audit_financial_goals_insert',
    'audit_financial_goals_update',
    'audit_shopping_items_insert',
    'audit_shopping_items_update',
    'audit_tasks_insert',
    'audit_tasks_update',
  };
  static const _backupTables = <String>[
    'accounts',
    'transactions',
    'tasks',
    'credit_cards',
    'card_purchases',
    'card_installment_payments',
    'card_invoices',
    'card_invoice_payments',
    'investments',
    'budgets',
    'subscriptions',
    'salary_allocation',
    'financial_goals',
    'finance_categories',
    'finance_subcategories',
    'shopping_items',
    'salary_schedules',
    'app_settings',
    'goal_categories',
  ];

  static Future<AppDatabase> open() async {
    final appDirectory = await _applicationDataDirectory();
    final folder = Directory(path.join(appDirectory.path, 'Organiza'));
    if (!folder.existsSync()) folder.createSync(recursive: true);
    await _copyLegacyDatabaseIfNeeded(folder);
    return openFile(File(path.join(folder.path, 'organiza.db')));
  }

  /// Opens a private database or a staged restore, optionally without upgrading it.
  static AppDatabase openFile(File file, {bool migrate = true}) {
    file.parent.createSync(recursive: true);
    final database = sqlite3.open(file.absolute.path);
    try {
      _configure(database, persistent: true);
      final instance = AppDatabase._(database, filePath: file.absolute.path);
      if (migrate) instance._migrate();
      return instance;
    } catch (_) {
      database.close();
      rethrow;
    }
  }

  static AppDatabase openInMemory() {
    final database = sqlite3.openInMemory();
    _configure(database, persistent: false);
    final instance = AppDatabase._(database);
    instance._migrate();
    return instance;
  }

  static AppDatabase openInMemoryFromVersion1ForTest() {
    final database = sqlite3.openInMemory();
    _configure(database, persistent: false);
    database.execute('''
      CREATE TABLE accounts (
        id TEXT PRIMARY KEY NOT NULL,
        name TEXT NOT NULL,
        opening_balance_cents INTEGER NOT NULL,
        created_at TEXT NOT NULL
      );
      CREATE TABLE transactions (
        id TEXT PRIMARY KEY NOT NULL,
        account_id TEXT NOT NULL REFERENCES accounts(id),
        destination_account_id TEXT REFERENCES accounts(id),
        type TEXT NOT NULL CHECK(type IN ('income', 'expense', 'transfer')),
        amount_cents INTEGER NOT NULL CHECK(amount_cents > 0),
        description TEXT NOT NULL,
        occurred_on TEXT NOT NULL,
        created_at TEXT NOT NULL
      );
      CREATE INDEX idx_transactions_occurred_on ON transactions(occurred_on);
      CREATE INDEX idx_transactions_account_id ON transactions(account_id);
      CREATE TABLE tasks (
        id TEXT PRIMARY KEY NOT NULL,
        title TEXT NOT NULL,
        due_on TEXT,
        is_done INTEGER NOT NULL DEFAULT 0 CHECK(is_done IN (0, 1)),
        created_at TEXT NOT NULL
      );
      PRAGMA user_version = 1;
    ''');
    final instance = AppDatabase._(database);
    instance._migrate();
    return instance;
  }

  static AppDatabase openInMemoryFromVersion15ForTest() {
    final instance = _emptyAtVersion(15);
    instance._database.execute('''
      INSERT INTO credit_cards VALUES
        ('card-v15', 'Principal', 'visa', '4242', 500000, 10, 17, 4285658943, '2026-09-10T00:00:00.000');
      INSERT INTO card_purchases VALUES
        ('purchase-v15', 'card-v15', 'Notebook', 120000, '2026-09-10T00:00:00.000', 3, '2026-09-10T00:00:00.000');
    ''');
    instance._migrate();
    return instance;
  }

  static AppDatabase openInMemoryAtVersionForTest(int version) =>
      _emptyAtVersion(version);

  static AppDatabase _emptyAtVersion(int version) {
    if (version < 1 || version > _schemaVersion) {
      throw const FormatException('Versão de schema não suportada.');
    }
    final database = sqlite3.openInMemory();
    _configure(database, persistent: false);
    final instance = AppDatabase._(database);
    try {
      instance.transaction(() => instance._applyMigrations(0, version));
      return instance;
    } catch (_) {
      database.close();
      rethrow;
    }
  }

  int get schemaVersion =>
      _database.select('PRAGMA user_version').first['user_version'] as int;

  String _activeRowPredicate([String? alias]) => schemaVersion >= 19
      ? '${alias == null ? '' : '$alias.'}deleted_at IS NULL'
      : '1 = 1';

  static List<String> _tablesForVersion(int version) => _backupTables
      .where((table) =>
          version >=
          switch (table) {
            'accounts' || 'transactions' || 'tasks' => 1,
            'credit_cards' || 'card_purchases' => 2,
            'investments' => 3,
            'budgets' => 4,
            'subscriptions' => 5,
            'salary_allocation' => 6,
            'financial_goals' => 7,
            'finance_categories' || 'finance_subcategories' => 8,
            'shopping_items' => 9,
            'salary_schedules' || 'app_settings' || 'goal_categories' => 11,
            'card_installment_payments' => 16,
            'card_invoices' || 'card_invoice_payments' => 18,
            _ => throw StateError('Tabela sem versão conhecida.'),
          })
      .toList(growable: false);

  Map<String, int> get tableCounts => Map.unmodifiable({
        for (final table in _tablesForVersion(schemaVersion))
          table: _database
              .select('SELECT COUNT(*) AS total FROM "$table"')
              .single['total'] as int,
      });

  /// Copies committed SQLite state, including data currently in a WAL file.
  Future<void> createConsistentCopy(File destination) async {
    if (destination.existsSync() ||
        (filePath != null &&
            path.equals(destination.absolute.path, filePath!))) {
      throw ArgumentError('O destino da cópia deve ser um arquivo novo.');
    }
    destination.parent.createSync(recursive: true);
    final copy = sqlite3.open(destination.absolute.path);
    try {
      await _database.backup(copy, nPage: -1).drain<void>();
      AppDatabase._(copy).validateIntegrity();
    } catch (_) {
      copy.close();
      if (destination.existsSync()) destination.deleteSync();
      rethrow;
    }
    copy.close();
  }

  /// Rejects unexpected user tables, columns and executable schema objects.
  void validateIntegrity() {
    final version = schemaVersion;
    if (version < 1 || version > _schemaVersion) {
      throw const FormatException('Versão de schema não suportada.');
    }
    final objects = _database.select(
      "SELECT type, name FROM sqlite_master WHERE name NOT LIKE 'sqlite_%'",
    );
    final expectedTriggers = version >= 19 ? _auditTriggerNames : <String>{};
    final actualTriggers = objects
        .where((row) => row['type'] == 'trigger')
        .map((row) => row['name'] as String)
        .toSet();
    if (objects.any((row) => row['type'] == 'view') ||
        actualTriggers.any((name) => !expectedTriggers.contains(name)) ||
        actualTriggers.length != expectedTriggers.length) {
      throw const FormatException('O banco contém objetos não reconhecidos.');
    }
    final expectedTables = _tablesForVersion(version).toSet();
    final actualTables = objects
        .where((row) => row['type'] == 'table')
        .map((row) => row['name'] as String)
        .toSet();
    if (actualTables.length != expectedTables.length ||
        !actualTables.containsAll(expectedTables)) {
      throw const FormatException('O banco contém tabelas incompatíveis.');
    }
    final expected = _emptyAtVersion(version);
    try {
      for (final table in expectedTables) {
        final columns = _tableColumns(table);
        final expectedColumns = expected._tableColumns(table);
        if (columns.length != expectedColumns.length ||
            !columns.containsAll(expectedColumns)) {
          throw FormatException('Colunas incompatíveis na tabela $table.');
        }
      }
    } finally {
      expected.close();
    }
    final foreignKeys = _database.select('PRAGMA foreign_key_check');
    if (foreignKeys.isNotEmpty) {
      throw const FormatException('O banco viola integridade referencial.');
    }
    final integrity = _database.select('PRAGMA integrity_check');
    if (integrity.length != 1 || integrity.single.values.single != 'ok') {
      throw const FormatException(
          'O banco falhou na verificação de integridade.');
    }
  }

  /// Converts only existing references, committing profile and shopping together.
  void rewriteImagePaths(Map<String, String> replacements) {
    if (replacements.isEmpty) return;
    final cases = List.filled(replacements.length, 'WHEN ? THEN ?').join(' ');
    final placeholders = List.filled(replacements.length, '?').join(', ');
    final parameters = <Object?>[
      for (final entry in replacements.entries) ...[entry.key, entry.value],
      ...replacements.keys,
    ];
    transaction(() {
      _database.execute(
        'UPDATE app_settings SET value = CASE value $cases ELSE value END '
        "WHERE key = 'profile_photo_path' AND value IN ($placeholders)",
        parameters,
      );
      _database.execute(
        'UPDATE shopping_items SET image_path = CASE image_path $cases ELSE image_path END '
        'WHERE image_path IN ($placeholders)',
        parameters,
      );
    });
  }

  void _createPreMigrationCopy() {
    final backup = File('$filePath.pre-v$_schemaVersion.bak');
    if (backup.existsSync()) {
      backup.renameSync(
        '$filePath.pre-v$_schemaVersion.${DateTime.now().microsecondsSinceEpoch}.bak',
      );
    }
    _database.execute('VACUUM INTO ?', [backup.path]);
    final copied = sqlite3.open(backup.path, mode: OpenMode.readOnly);
    try {
      AppDatabase._(copied).validateIntegrity();
    } finally {
      copied.close();
    }
  }

  void _pruneMigrationCopies() {
    final file = File(filePath!);
    final pattern = RegExp(
      '^${RegExp.escape(path.basename(file.path))}\\.pre-v[0-9]+(?:\\.[0-9]+)?\\.bak\$',
    );
    final copies = file.parent
        .listSync(followLinks: false)
        .whereType<File>()
        .where((copy) => pattern.hasMatch(path.basename(copy.path)))
        .toList()
      ..sort((a, b) => b.lastModifiedSync().compareTo(a.lastModifiedSync()));
    for (final old in copies.skip(3)) {
      old.deleteSync();
    }
  }

  /// Exports every user table as a versioned, JSON-compatible snapshot.
  ///
  /// Historical snapshots retain their original schema and are upgraded in a
  /// separate database before any live row is replaced.
  Map<String, Object?> exportSnapshot() {
    _database.execute('BEGIN IMMEDIATE');
    try {
      final snapshot = <String, Object?>{
        'schemaVersion': schemaVersion,
        'tables': <String, Object?>{
          for (final table in _tablesForVersion(schemaVersion))
            table: _rows(table),
        },
      };
      _database.execute('COMMIT');
      return snapshot;
    } catch (_) {
      _database.execute('ROLLBACK');
      rethrow;
    }
  }

  /// Replaces all user tables atomically after validating the snapshot.
  void restoreSnapshot(Map<String, dynamic> snapshot) {
    final version = snapshot['schemaVersion'];
    if (version is! int || version < 1 || version > schemaVersion) {
      throw const FormatException('Versão de schema do backup incompatível.');
    }
    if (version < schemaVersion) {
      final staged = _emptyAtVersion(version);
      try {
        staged._restoreMatchingSnapshot(snapshot);
        staged._migrate();
        _restoreMatchingSnapshot(
          Map<String, dynamic>.from(staged.exportSnapshot()),
        );
      } finally {
        staged.close();
      }
      return;
    }
    _restoreMatchingSnapshot(snapshot);
  }

  void _restoreMatchingSnapshot(Map<String, dynamic> snapshot) {
    final rawTables = snapshot['tables'];
    if (rawTables is! Map) {
      throw const FormatException('Backup sem a seção de tabelas.');
    }
    final expectedTables = _tablesForVersion(schemaVersion);
    if (rawTables.keys.any((key) => !expectedTables.contains(key))) {
      throw const FormatException('Backup contém tabela desconhecida.');
    }
    final tables = <String, List<Map<String, dynamic>>>{};
    for (final table in expectedTables) {
      final rawRows = rawTables[table];
      if (rawRows is! List) {
        throw FormatException('Backup sem a tabela $table.');
      }
      tables[table] = rawRows.map<Map<String, dynamic>>((row) {
        if (row is! Map) {
          throw FormatException('Linha inválida na tabela $table.');
        }
        return Map<String, dynamic>.from(row);
      }).toList();
    }

    _database.execute('BEGIN IMMEDIATE');
    try {
      // Snapshot table order is historical, not dependency order. Validate
      // every foreign key before commit after all parent rows are restored.
      _database.execute('PRAGMA defer_foreign_keys = ON');
      for (final table in expectedTables.reversed) {
        _database.execute('DELETE FROM "$table"');
      }
      for (final table in expectedTables) {
        final columns = _tableColumns(table);
        for (final row in tables[table]!) {
          if (row.keys.any((key) => !columns.contains(key))) {
            throw FormatException('Coluna desconhecida na tabela $table.');
          }
          if (row.isEmpty) continue;
          final names = row.keys.toList();
          final placeholders = List.filled(names.length, '?').join(', ');
          _database.execute(
            'INSERT INTO "$table" (${names.join(', ')}) VALUES ($placeholders)',
            names.map((name) => row[name]).toList(),
          );
        }
      }
      validateIntegrity();
      _database.execute('COMMIT');
    } catch (_) {
      _database.execute('ROLLBACK');
      rethrow;
    }
  }

  List<Map<String, Object?>> _rows(String table) => _database
      .select('SELECT * FROM "$table"')
      .map((row) => <String, Object?>{
            for (final key in row.keys) key: row[key],
          })
      .toList();

  Set<String> _tableColumns(String table) => _database
      .select('PRAGMA table_info("$table")')
      .map((row) => row['name'] as String)
      .toSet();

  void _migrate() {
    final current = schemaVersion;
    if (current > _schemaVersion) {
      throw StateError(
          'O banco foi criado por uma versão mais recente do Organiza.');
    }
    if (current == _schemaVersion) {
      validateIntegrity();
      return;
    }
    if (current > 0) validateIntegrity();
    if (current > 0 && filePath != null) _createPreMigrationCopy();
    transaction(() {
      _applyMigrations(current, _schemaVersion);
      validateIntegrity();
    });
    if (filePath != null) _pruneMigrationCopies();
  }

  void _applyMigrations(int current, int target) {
    if (current < 1 && target >= 1) {
      _database.execute('''
        CREATE TABLE accounts (
          id TEXT PRIMARY KEY NOT NULL,
          name TEXT NOT NULL,
          opening_balance_cents INTEGER NOT NULL,
          created_at TEXT NOT NULL
        );
        CREATE TABLE transactions (
          id TEXT PRIMARY KEY NOT NULL,
          account_id TEXT NOT NULL REFERENCES accounts(id),
          destination_account_id TEXT REFERENCES accounts(id),
          type TEXT NOT NULL CHECK(type IN ('income', 'expense', 'transfer')),
          amount_cents INTEGER NOT NULL CHECK(amount_cents > 0),
          description TEXT NOT NULL,
          occurred_on TEXT NOT NULL,
          created_at TEXT NOT NULL
        );
        CREATE INDEX idx_transactions_occurred_on ON transactions(occurred_on);
        CREATE INDEX idx_transactions_account_id ON transactions(account_id);
        CREATE TABLE tasks (
          id TEXT PRIMARY KEY NOT NULL,
          title TEXT NOT NULL,
          due_on TEXT,
          is_done INTEGER NOT NULL DEFAULT 0 CHECK(is_done IN (0, 1)),
          created_at TEXT NOT NULL
        );
      ''');
      _database.execute('PRAGMA user_version = 1');
    }
    if (current < 2 && target >= 2) {
      _database.execute('''
        CREATE TABLE credit_cards (
          id TEXT PRIMARY KEY NOT NULL,
          name TEXT NOT NULL,
          brand TEXT NOT NULL,
          last_four TEXT NOT NULL CHECK(length(last_four) = 4),
          limit_cents INTEGER NOT NULL CHECK(limit_cents > 0),
          closing_day INTEGER NOT NULL CHECK(closing_day BETWEEN 1 AND 28),
          due_day INTEGER NOT NULL CHECK(due_day BETWEEN 1 AND 28),
          color_value INTEGER NOT NULL,
          created_at TEXT NOT NULL
        );
        CREATE TABLE card_purchases (
          id TEXT PRIMARY KEY NOT NULL,
          card_id TEXT NOT NULL REFERENCES credit_cards(id) ON DELETE RESTRICT,
          description TEXT NOT NULL,
          amount_cents INTEGER NOT NULL CHECK(amount_cents > 0),
          purchased_on TEXT NOT NULL,
          installments INTEGER NOT NULL DEFAULT 1 CHECK(installments BETWEEN 1 AND 48),
          created_at TEXT NOT NULL
        );
        CREATE INDEX idx_card_purchases_card_date
          ON card_purchases(card_id, purchased_on DESC);
      ''');
      _database.execute('PRAGMA user_version = 2');
    }
    if (current < 3 && target >= 3) {
      _database.execute('''
        ALTER TABLE accounts
          ADD COLUMN institution TEXT NOT NULL DEFAULT 'generic';
        CREATE TABLE investments (
          id TEXT PRIMARY KEY NOT NULL,
          name TEXT NOT NULL,
          type TEXT NOT NULL,
          invested_amount_cents INTEGER NOT NULL CHECK(invested_amount_cents > 0),
          current_value_cents INTEGER NOT NULL CHECK(current_value_cents >= 0),
          created_at TEXT NOT NULL
        );
        CREATE INDEX idx_investments_created_at
          ON investments(created_at DESC);
      ''');
      _database.execute('PRAGMA user_version = 3');
    }
    if (current < 4 && target >= 4) {
      _database.execute('''
        ALTER TABLE transactions
          ADD COLUMN category TEXT NOT NULL DEFAULT 'Outros';
        CREATE TABLE budgets (
          id TEXT PRIMARY KEY NOT NULL,
          category TEXT NOT NULL,
          limit_cents INTEGER NOT NULL CHECK(limit_cents > 0),
          year INTEGER NOT NULL CHECK(year BETWEEN 2000 AND 2100),
          month INTEGER NOT NULL CHECK(month BETWEEN 1 AND 12),
          created_at TEXT NOT NULL
        );
        CREATE UNIQUE INDEX idx_budgets_category_period
          ON budgets(category, year, month);
      ''');
      _database.execute('PRAGMA user_version = 4');
    }
    if (current < 5 && target >= 5) {
      _database.execute('''
        ALTER TABLE transactions
          ADD COLUMN subcategory TEXT NOT NULL DEFAULT 'Geral';
        CREATE TABLE subscriptions (
          id TEXT PRIMARY KEY NOT NULL,
          name TEXT NOT NULL,
          amount_cents INTEGER NOT NULL CHECK(amount_cents > 0),
          billing_day INTEGER NOT NULL CHECK(billing_day BETWEEN 1 AND 31),
          category TEXT NOT NULL,
          is_active INTEGER NOT NULL DEFAULT 1 CHECK(is_active IN (0, 1)),
          created_at TEXT NOT NULL
        );
        CREATE INDEX idx_subscriptions_active ON subscriptions(is_active, billing_day);
      ''');
      _database.execute('PRAGMA user_version = 5');
    }
    if (current < 6 && target >= 6) {
      _database.execute('''
        CREATE TABLE salary_allocation (
          id INTEGER PRIMARY KEY NOT NULL CHECK(id = 1),
          essentials_percent INTEGER NOT NULL,
          goals_percent INTEGER NOT NULL,
          free_percent INTEGER NOT NULL,
          CHECK(essentials_percent + goals_percent + free_percent = 100)
        );
        INSERT INTO salary_allocation(id, essentials_percent, goals_percent, free_percent)
        VALUES (1, 50, 30, 20);
      ''');
      _database.execute('PRAGMA user_version = 6');
    }
    if (current < 7 && target >= 7) {
      _database.execute('''
        CREATE TABLE financial_goals (
          id TEXT PRIMARY KEY NOT NULL,
          name TEXT NOT NULL,
          target_cents INTEGER NOT NULL CHECK(target_cents > 0),
          saved_cents INTEGER NOT NULL DEFAULT 0 CHECK(saved_cents >= 0),
          deadline TEXT,
          icon_key TEXT NOT NULL DEFAULT 'savings',
          created_at TEXT NOT NULL
        );
        CREATE INDEX idx_financial_goals_deadline
          ON financial_goals(deadline ASC, created_at DESC);
      ''');
      _database.execute('PRAGMA user_version = 7');
    }
    if (current < 8 && target >= 8) {
      _database.execute('''
        ALTER TABLE transactions
          ADD COLUMN schedule_type TEXT NOT NULL DEFAULT 'single';
        ALTER TABLE transactions ADD COLUMN series_id TEXT;
        ALTER TABLE transactions
          ADD COLUMN installment_number INTEGER NOT NULL DEFAULT 1;
        ALTER TABLE transactions
          ADD COLUMN installment_count INTEGER NOT NULL DEFAULT 1;
        ALTER TABLE transactions
          ADD COLUMN is_settled INTEGER NOT NULL DEFAULT 1 CHECK(is_settled IN (0, 1));
        ALTER TABLE investments ADD COLUMN fixed_income_type TEXT;
        ALTER TABLE investments ADD COLUMN institution_name TEXT;
        ALTER TABLE investments ADD COLUMN maturity_date TEXT;
        CREATE TABLE finance_categories (
          id TEXT PRIMARY KEY NOT NULL,
          name TEXT NOT NULL,
          type TEXT NOT NULL CHECK(type IN ('income', 'expense')),
          is_system INTEGER NOT NULL DEFAULT 0 CHECK(is_system IN (0, 1)),
          created_at TEXT NOT NULL
        );
        CREATE UNIQUE INDEX idx_finance_categories_name_type
          ON finance_categories(name COLLATE NOCASE, type);
        CREATE TABLE finance_subcategories (
          id TEXT PRIMARY KEY NOT NULL,
          category_id TEXT NOT NULL REFERENCES finance_categories(id) ON DELETE CASCADE,
          name TEXT NOT NULL,
          is_system INTEGER NOT NULL DEFAULT 0 CHECK(is_system IN (0, 1)),
          created_at TEXT NOT NULL
        );
        CREATE UNIQUE INDEX idx_finance_subcategories_name_category
          ON finance_subcategories(category_id, name COLLATE NOCASE);
      ''');
      _seedDefaultCategories();
      _database.execute('PRAGMA user_version = 8');
    }
    if (current < 9 && target >= 9) {
      _database.execute('''
        CREATE TABLE shopping_items (
          id TEXT PRIMARY KEY NOT NULL,
          name TEXT NOT NULL,
          quantity INTEGER NOT NULL CHECK(quantity BETWEEN 1 AND 9999),
          estimated_unit_price_cents INTEGER CHECK(estimated_unit_price_cents >= 0),
          priority TEXT NOT NULL DEFAULT 'normal' CHECK(priority IN ('low', 'normal', 'high')),
          is_purchased INTEGER NOT NULL DEFAULT 0 CHECK(is_purchased IN (0, 1)),
          created_at TEXT NOT NULL
        );
        CREATE INDEX idx_shopping_items_state_priority
          ON shopping_items(is_purchased, priority, created_at DESC);
      ''');
      _database.execute('PRAGMA user_version = 9');
    }
    if (current < 10 && target >= 10) {
      _database.execute('''
        ALTER TABLE investments ADD COLUMN quoted_rate_bps INTEGER
          CHECK(quoted_rate_bps BETWEEN -10000 AND 100000);
        ALTER TABLE investments ADD COLUMN quoted_rate_period TEXT
          CHECK(quoted_rate_period IN ('monthly', 'annual'));
      ''');
      _database.execute('PRAGMA user_version = 10');
    }
    if (current < 11 && target >= 11) {
      _database.execute('''
        ALTER TABLE investments ADD COLUMN yield_payment_day INTEGER
          CHECK(yield_payment_day BETWEEN 1 AND 31);
        CREATE TABLE salary_schedules (
          id TEXT PRIMARY KEY NOT NULL,
          account_id TEXT NOT NULL REFERENCES accounts(id) ON DELETE RESTRICT,
          amount_cents INTEGER NOT NULL CHECK(amount_cents > 0),
          description TEXT NOT NULL,
          subcategory TEXT NOT NULL,
          first_due_on TEXT NOT NULL,
          payment_day INTEGER NOT NULL CHECK(payment_day BETWEEN 1 AND 31),
          created_at TEXT NOT NULL
        );
        CREATE INDEX idx_salary_series_month ON transactions(series_id, occurred_on);
        CREATE TABLE app_settings (key TEXT PRIMARY KEY NOT NULL, value TEXT NOT NULL);
        ALTER TABLE financial_goals ADD COLUMN category TEXT NOT NULL DEFAULT 'Reserva';
        CREATE TABLE goal_categories (name TEXT PRIMARY KEY NOT NULL);
        INSERT INTO goal_categories(name) VALUES
          ('Reserva'), ('Casa'), ('Viagem'), ('Estudos'), ('Veículo'), ('Outros');
      ''');
      _seedDefaultCategories();
      _database.execute('PRAGMA user_version = 11');
    }
    if (current < 12 && target >= 12) {
      _database
          .execute('ALTER TABLE shopping_items ADD COLUMN image_path TEXT');
      _database.execute('PRAGMA user_version = 12');
    }
    if (current < 13 && target >= 13) {
      _database.execute('''
        ALTER TABLE accounts ADD COLUMN custom_institution_name TEXT;
        ALTER TABLE accounts ADD COLUMN custom_icon_key TEXT;
      ''');
      _database.execute('PRAGMA user_version = 13');
    }
    if (current < 14 && target >= 14) {
      _database.execute(
          "ALTER TABLE shopping_items ADD COLUMN description TEXT NOT NULL DEFAULT ''");
      _database.execute('PRAGMA user_version = 14');
    }
    if (current < 15 && target >= 15) {
      _database.execute('''
        DELETE FROM transactions
        WHERE series_id IS NOT NULL
          AND rowid NOT IN (
            SELECT MIN(rowid)
            FROM transactions
            WHERE series_id IS NOT NULL
            GROUP BY series_id, occurred_on
          );
        CREATE UNIQUE INDEX IF NOT EXISTS idx_salary_series_date_unique
          ON transactions(series_id, occurred_on)
          WHERE series_id IS NOT NULL;
      ''');
      _database.execute('PRAGMA user_version = 15');
    }
    if (current < 16 && target >= 16) {
      _database.execute('''
        CREATE TABLE card_installment_payments (
          purchase_id TEXT NOT NULL
            REFERENCES card_purchases(id) ON DELETE CASCADE,
          installment_number INTEGER NOT NULL CHECK(installment_number BETWEEN 1 AND 48),
          paid_on TEXT NOT NULL,
          PRIMARY KEY (purchase_id, installment_number)
        );
      ''');
      _database.execute('PRAGMA user_version = 16');
    }
    if (current < 17 && target >= 17) {
      _addColumnIfMissing('transactions', 'category_id',
          'TEXT REFERENCES finance_categories(id) ON DELETE SET NULL');
      _addColumnIfMissing('transactions', 'subcategory_id',
          'TEXT REFERENCES finance_subcategories(id) ON DELETE SET NULL');
      _addColumnIfMissing('budgets', 'category_id',
          'TEXT REFERENCES finance_categories(id) ON DELETE SET NULL');
      _addColumnIfMissing('subscriptions', 'category_id',
          'TEXT REFERENCES finance_categories(id) ON DELETE SET NULL');
      _addColumnIfMissing('finance_categories', 'archived_at', 'TEXT');
      _addColumnIfMissing('financial_goals', 'goal_category_name',
          'TEXT REFERENCES goal_categories(name) ON UPDATE CASCADE ON DELETE RESTRICT');
      _database.execute('''
        CREATE INDEX IF NOT EXISTS idx_transactions_category_date
          ON transactions(category_id, occurred_on);
        CREATE INDEX IF NOT EXISTS idx_transactions_subcategory_date
          ON transactions(subcategory_id, occurred_on);
        CREATE INDEX IF NOT EXISTS idx_budgets_category_id_period
          ON budgets(category_id, year, month);
        CREATE INDEX IF NOT EXISTS idx_subscriptions_category
          ON subscriptions(category_id);
      ''');
      _backfillCategoryIds();
      _database.execute('PRAGMA user_version = 17');
    }
    if (current < 18 && target >= 18) {
      _addColumnIfMissing('transactions', 'system_type',
          "TEXT CHECK(system_type IS NULL OR system_type IN ('card_payment'))");
      _addColumnIfMissing('card_purchases', 'category_id',
          'TEXT REFERENCES finance_categories(id) ON DELETE SET NULL');
      _addColumnIfMissing('card_purchases', 'subcategory_id',
          'TEXT REFERENCES finance_subcategories(id) ON DELETE SET NULL');
      _database.execute('''
        CREATE TABLE IF NOT EXISTS card_invoices (
          id TEXT PRIMARY KEY NOT NULL,
          card_id TEXT NOT NULL REFERENCES credit_cards(id) ON DELETE RESTRICT,
          reference_year INTEGER NOT NULL,
          reference_month INTEGER NOT NULL CHECK(reference_month BETWEEN 1 AND 12),
          closing_on TEXT NOT NULL,
          due_on TEXT NOT NULL,
          status TEXT NOT NULL CHECK(status IN ('open','closed','partially_paid','paid')),
          created_at TEXT NOT NULL,
          updated_at TEXT NOT NULL,
          UNIQUE(card_id, reference_year, reference_month)
        );
        CREATE TABLE IF NOT EXISTS card_invoice_payments (
          id TEXT PRIMARY KEY NOT NULL,
          invoice_id TEXT NOT NULL REFERENCES card_invoices(id) ON DELETE CASCADE,
          account_id TEXT NOT NULL REFERENCES accounts(id) ON DELETE RESTRICT,
          transaction_id TEXT REFERENCES transactions(id) ON DELETE SET NULL,
          amount_cents INTEGER NOT NULL CHECK(amount_cents > 0),
          paid_on TEXT NOT NULL,
          created_at TEXT NOT NULL
        );
        CREATE INDEX IF NOT EXISTS idx_card_purchases_category_date
          ON card_purchases(category_id, purchased_on);
        CREATE INDEX IF NOT EXISTS idx_card_purchases_subcategory_date
          ON card_purchases(subcategory_id, purchased_on);
        CREATE INDEX IF NOT EXISTS idx_card_invoices_card_period
          ON card_invoices(card_id, reference_year, reference_month);
        CREATE INDEX IF NOT EXISTS idx_card_invoice_payments_invoice
          ON card_invoice_payments(invoice_id);
      ''');
      for (final row in _database.select(
          'SELECT id, created_at FROM card_purchases WHERE category_id IS NULL')) {
        final createdAt = DateTime.parse(row['created_at'] as String);
        final category = _resolveCategory('Outros', 'expense', createdAt);
        final subcategory =
            _resolveSubcategory('Geral', category.$1, createdAt);
        _database.execute(
            'UPDATE card_purchases SET category_id = ?, subcategory_id = ? WHERE id = ?',
            [category.$1, subcategory.$1, row['id']]);
      }
      _database.execute('PRAGMA user_version = 18');
    }
    if (current < 19 && target >= 19) {
      for (final table in _auditTables) {
        _addColumnIfMissing(table, 'updated_at', "TEXT NOT NULL DEFAULT ''");
        _addColumnIfMissing(table, 'deleted_at', 'TEXT');
        _database.execute('''
          UPDATE "$table"
          SET updated_at = created_at
          WHERE updated_at IS NULL OR updated_at = ''
        ''');
        _database.execute('''
          CREATE TRIGGER IF NOT EXISTS "audit_${table}_insert"
          AFTER INSERT ON "$table"
          WHEN NEW.updated_at = ''
          BEGIN
            UPDATE "$table" SET updated_at = NEW.created_at
            WHERE rowid = NEW.rowid;
          END
        ''');
        _database.execute('''
          CREATE TRIGGER IF NOT EXISTS "audit_${table}_update"
          AFTER UPDATE ON "$table"
          WHEN NEW.updated_at = OLD.updated_at
          BEGIN
            UPDATE "$table"
            SET updated_at = strftime('%Y-%m-%dT%H:%M:%fZ', 'now')
            WHERE rowid = NEW.rowid;
          END
        ''');
      }
      _database.execute('PRAGMA user_version = 19');
    }
  }

  void _addColumnIfMissing(String table, String column, String definition) {
    if (!_tableColumns(table).contains(column)) {
      _database
          .execute('ALTER TABLE "$table" ADD COLUMN "$column" $definition');
    }
  }

  void _backfillCategoryIds() {
    const uuid = Uuid();
    final categories = <String, String>{};
    for (final row
        in _database.select('SELECT id, name, type FROM finance_categories')) {
      categories[
              '${row['type']}:${(row['name'] as String).trim().toLowerCase()}'] =
          row['id'] as String;
    }
    String categoryId(String raw, String type) {
      final name = raw.trim().isEmpty ? 'Outros' : raw.trim();
      final key = '$type:${name.toLowerCase()}';
      final existing = categories[key];
      if (existing != null) return existing;
      final id = uuid.v4();
      _database.execute(
          'INSERT INTO finance_categories(id, name, type, is_system, created_at) '
          'VALUES (?, ?, ?, 0, ?)',
          [id, name, type, DateTime.utc(1970).toIso8601String()]);
      categories[key] = id;
      return id;
    }

    final subcategories = <String, String>{};
    for (final row in _database
        .select('SELECT id, category_id, name FROM finance_subcategories')) {
      subcategories[
              '${row['category_id']}:${(row['name'] as String).trim().toLowerCase()}'] =
          row['id'] as String;
    }
    String subcategoryId(String raw, String parentId) {
      final name = raw.trim().isEmpty ? 'Geral' : raw.trim();
      final key = '$parentId:${name.toLowerCase()}';
      final existing = subcategories[key];
      if (existing != null) return existing;
      final id = uuid.v4();
      _database.execute(
          'INSERT INTO finance_subcategories(id, category_id, name, is_system, created_at) '
          'VALUES (?, ?, ?, 0, ?)',
          [id, parentId, name, DateTime.utc(1970).toIso8601String()]);
      subcategories[key] = id;
      return id;
    }

    for (final row in _database.select(
        "SELECT id, type, category, subcategory FROM transactions WHERE type IN ('income', 'expense')")) {
      final parent =
          categoryId(row['category'] as String, row['type'] as String);
      final child = subcategoryId(row['subcategory'] as String, parent);
      _database.execute(
          'UPDATE transactions SET category_id = ?, subcategory_id = ? WHERE id = ?',
          [parent, child, row['id']]);
    }
    for (final row in _database.select('SELECT id, category FROM budgets')) {
      _database.execute('UPDATE budgets SET category_id = ? WHERE id = ?',
          [categoryId(row['category'] as String, 'expense'), row['id']]);
    }
    for (final row
        in _database.select('SELECT id, category FROM subscriptions')) {
      _database.execute('UPDATE subscriptions SET category_id = ? WHERE id = ?',
          [categoryId(row['category'] as String, 'expense'), row['id']]);
    }
    final goals = <String, String>{};
    for (final row in _database.select('SELECT name FROM goal_categories')) {
      final name = row['name'] as String;
      goals[name.trim().toLowerCase()] = name;
    }
    for (final row
        in _database.select('SELECT id, category FROM financial_goals')) {
      final raw = (row['category'] as String).trim();
      final name = raw.isEmpty ? 'Outros' : raw;
      final key = name.toLowerCase();
      var canonical = goals[key];
      if (canonical == null) {
        canonical = name;
        _database
            .execute('INSERT INTO goal_categories(name) VALUES (?)', [name]);
        goals[key] = name;
      }
      _database.execute(
          'UPDATE financial_goals SET goal_category_name = ? WHERE id = ?',
          [canonical, row['id']]);
    }
  }

  static Future<Directory> _applicationDataDirectory() async {
    if (Platform.isWindows) {
      final local = Platform.environment['LOCALAPPDATA'];
      if (local != null && local.isNotEmpty) return Directory(local);
    }
    return getApplicationSupportDirectory();
  }

  static Future<void> _copyLegacyDatabaseIfNeeded(
      Directory targetFolder) async {
    if (!Platform.isWindows) return;
    final target = File(path.join(targetFolder.path, 'organiza.db'));
    if (target.existsSync()) return;
    final legacyRoot = await getApplicationSupportDirectory();
    final legacyFolder = Directory(path.join(legacyRoot.path, 'Organiza'));
    final legacyDatabase = File(path.join(legacyFolder.path, 'organiza.db'));
    if (!legacyDatabase.existsSync() ||
        path.normalize(targetFolder.path).toLowerCase() ==
            path.normalize(legacyFolder.path).toLowerCase()) {
      return;
    }
    await legacyDatabase.copy(target.path);
    for (final suffix in const ['-wal', '-shm']) {
      final sidecar = File('${legacyDatabase.path}$suffix');
      if (sidecar.existsSync()) await sidecar.copy('${target.path}$suffix');
    }
  }

  static void _configure(Database database, {required bool persistent}) {
    database.execute('PRAGMA foreign_keys = ON');
    database.execute('PRAGMA recursive_triggers = OFF');
    database.execute('PRAGMA busy_timeout = 5000');
    database.execute('PRAGMA synchronous = NORMAL');
    if (persistent) database.execute('PRAGMA journal_mode = WAL');
  }

  void _seedDefaultCategories() {
    final defaults = <(String, String, TransactionType, List<String>)>[
      (
        'expense_food',
        'Alimentação',
        TransactionType.expense,
        [
          'Mercado',
          'Restaurantes',
          'Delivery',
          'Padaria',
          'Açougue',
          'Feira',
          'Bar e bebidas',
          'Cafeterias'
        ]
      ),
      (
        'expense_home',
        'Moradia',
        TransactionType.expense,
        ['Aluguel', 'Condomínio', 'Energia', 'Internet', 'Manutenção']
      ),
      (
        'expense_transport',
        'Transporte',
        TransactionType.expense,
        ['Combustível', 'Aplicativos', 'Transporte público', 'Manutenção']
      ),
      (
        'expense_services',
        'Contas e serviços',
        TransactionType.expense,
        ['Água', 'Energia', 'Internet', 'Telefone', 'Seguros']
      ),
      (
        'expense_health',
        'Saúde',
        TransactionType.expense,
        ['Farmácia', 'Consultas', 'Exames', 'Academia']
      ),
      (
        'expense_education',
        'Educação',
        TransactionType.expense,
        ['Cursos', 'Livros', 'Material']
      ),
      (
        'expense_leisure',
        'Lazer',
        TransactionType.expense,
        ['Streaming', 'Viagens', 'Eventos', 'Hobbies']
      ),
      (
        'expense_other',
        'Outros',
        TransactionType.expense,
        ['Geral', 'Presentes', 'Imprevistos']
      ),
      (
        'expense_pets',
        'Pets',
        TransactionType.expense,
        ['Ração', 'Veterinário', 'Higiene']
      ),
      (
        'expense_clothing',
        'Vestuário',
        TransactionType.expense,
        ['Roupas', 'Calçados', 'Acessórios']
      ),
      (
        'expense_taxes',
        'Impostos e taxas',
        TransactionType.expense,
        ['IPTU', 'IPVA', 'Tarifas bancárias']
      ),
      (
        'expense_family',
        'Família',
        TransactionType.expense,
        ['Filhos', 'Cuidados', 'Apoio familiar']
      ),
      (
        'expense_donations',
        'Doações',
        TransactionType.expense,
        ['Instituições', 'Pessoas']
      ),
      (
        'expense_work',
        'Trabalho',
        TransactionType.expense,
        ['Equipamentos', 'Software', 'Deslocamento']
      ),
      (
        'income_salary',
        'Salário',
        TransactionType.income,
        ['Salário mensal', 'Adiantamento', '13º salário', 'Bônus']
      ),
      (
        'income_freelance',
        'Freelance',
        TransactionType.income,
        ['Projeto', 'Consultoria', 'Serviço']
      ),
      (
        'income_investments',
        'Rendimentos',
        TransactionType.income,
        ['Juros', 'Dividendos', 'Aluguel', 'Resgate']
      ),
      (
        'income_other',
        'Outros',
        TransactionType.income,
        ['Geral', 'Presente', 'Prêmio', 'Cashback']
      ),
    ];
    final createdAt = DateTime(2026).toIso8601String();
    for (final (id, name, type, subcategories) in defaults) {
      _database.execute(
        '''INSERT OR IGNORE INTO finance_categories(
          id, name, type, is_system, created_at
        ) VALUES (?, ?, ?, 1, ?)''',
        [id, name, type.name, createdAt],
      );
      for (var index = 0; index < subcategories.length; index++) {
        _database.execute(
          '''INSERT OR IGNORE INTO finance_subcategories(
            id, category_id, name, is_system, created_at
          ) VALUES (?, ?, ?, 1, ?)''',
          ['${id}_$index', id, subcategories[index], createdAt],
        );
      }
    }
  }

  List<Account> loadAccounts() => _database
      .select('SELECT * FROM accounts WHERE ${_activeRowPredicate()} '
          'ORDER BY created_at ASC')
      .map((row) => Account(
            id: row['id'] as String,
            name: row['name'] as String,
            openingBalanceInCents: row['opening_balance_cents'] as int,
            createdAt: DateTime.parse(row['created_at'] as String),
            institution:
                AccountInstitution.values.byName(row['institution'] as String),
            customInstitutionName: row['custom_institution_name'] as String?,
            customIconKey: row['custom_icon_key'] as String?,
          ))
      .toList();

  List<TransactionRecord> loadTransactions() => _database
      .select(schemaVersion < 17
          ? '''SELECT *, category AS resolved_category, subcategory AS resolved_subcategory,
              NULL AS category_id, NULL AS subcategory_id,
              NULL AS system_type
             FROM transactions WHERE ${_activeRowPredicate()}
             ORDER BY occurred_on DESC, created_at DESC'''
          : '''SELECT t.*, ${schemaVersion < 18 ? 'NULL AS system_type,' : ''}
              COALESCE(c.name, t.category) AS resolved_category,
             COALESCE(sc.name, t.subcategory) AS resolved_subcategory
             FROM transactions t
             LEFT JOIN finance_categories c ON c.id = t.category_id
             LEFT JOIN finance_subcategories sc ON sc.id = t.subcategory_id
             WHERE ${_activeRowPredicate('t')}
             ORDER BY t.occurred_on DESC, t.created_at DESC''')
      .map((row) => TransactionRecord(
            id: row['id'] as String,
            accountId: row['account_id'] as String,
            destinationAccountId: row['destination_account_id'] as String?,
            type: TransactionType.values.byName(row['type'] as String),
            amountInCents: row['amount_cents'] as int,
            description: row['description'] as String,
            category: row['resolved_category'] as String? ?? 'Outros',
            subcategory: row['resolved_subcategory'] as String? ?? 'Geral',
            categoryId: row['category_id'] as String?,
            subcategoryId: row['subcategory_id'] as String?,
            systemType: row['system_type'] == null
                ? null
                : TransactionSystemType.values.byName(
                    row['system_type'] == 'card_payment'
                        ? 'cardPayment'
                        : row['system_type'] as String),
            scheduleType: TransactionScheduleType.values
                .byName(row['schedule_type'] as String),
            seriesId: row['series_id'] as String?,
            installmentNumber: row['installment_number'] as int,
            installmentCount: row['installment_count'] as int,
            isSettled: (row['is_settled'] as int) == 1,
            occurredOn: DateTime.parse(row['occurred_on'] as String),
            createdAt: DateTime.parse(row['created_at'] as String),
          ))
      .toList();

  List<TaskItem> loadTasks() => _database
      .select('SELECT * FROM tasks WHERE ${_activeRowPredicate()} '
          'ORDER BY is_done ASC, due_on ASC, created_at DESC')
      .map((row) => TaskItem(
            id: row['id'] as String,
            title: row['title'] as String,
            dueOn: row['due_on'] == null
                ? null
                : DateTime.parse(row['due_on'] as String),
            isDone: (row['is_done'] as int) == 1,
            createdAt: DateTime.parse(row['created_at'] as String),
          ))
      .toList();

  List<ShoppingItem> loadShoppingItems() => _database
      .select('SELECT * FROM shopping_items WHERE ${_activeRowPredicate()} '
          'ORDER BY is_purchased ASC, created_at DESC')
      .map((row) => ShoppingItem(
            id: row['id'] as String,
            name: row['name'] as String,
            quantity: row['quantity'] as int,
            estimatedUnitPriceInCents:
                row['estimated_unit_price_cents'] as int?,
            priority: ShoppingPriority.values.byName(row['priority'] as String),
            isPurchased: (row['is_purchased'] as int) == 1,
            imagePath: row['image_path'] as String?,
            description: row['description'] as String? ?? '',
            createdAt: DateTime.parse(row['created_at'] as String),
          ))
      .toList();

  List<CreditCard> loadCreditCards() => _database
      .select('SELECT * FROM credit_cards WHERE ${_activeRowPredicate()} '
          'ORDER BY created_at ASC')
      .map((row) => CreditCard(
            id: row['id'] as String,
            name: row['name'] as String,
            brand: CardBrand.values.byName(row['brand'] as String),
            lastFour: row['last_four'] as String,
            limitInCents: row['limit_cents'] as int,
            closingDay: row['closing_day'] as int,
            dueDay: row['due_day'] as int,
            colorValue: row['color_value'] as int,
            createdAt: DateTime.parse(row['created_at'] as String),
          ))
      .toList();

  List<CardPurchase> loadCardPurchases() {
    final paidInstallments = <String, Set<int>>{};
    for (final row in _database.select(
      '''SELECT p.purchase_id, p.installment_number
         FROM card_installment_payments p
         JOIN card_purchases c ON c.id = p.purchase_id
         WHERE ${_activeRowPredicate('c')}''',
    )) {
      paidInstallments
          .putIfAbsent(row['purchase_id'] as String, () => <int>{})
          .add(row['installment_number'] as int);
    }
    return _database
        .select(schemaVersion < 18
            ? '''SELECT *, 'Outros' AS resolved_category,
                 'Geral' AS resolved_subcategory,
                 NULL AS category_id, NULL AS subcategory_id
                 FROM card_purchases WHERE ${_activeRowPredicate()}
                 ORDER BY purchased_on DESC, created_at DESC'''
            : '''SELECT p.*, COALESCE(c.name, 'Outros') AS resolved_category,
                 COALESCE(sc.name, 'Geral') AS resolved_subcategory
                 FROM card_purchases p
                 LEFT JOIN finance_categories c ON c.id = p.category_id
                 LEFT JOIN finance_subcategories sc ON sc.id = p.subcategory_id
                 WHERE ${_activeRowPredicate('p')}
                 ORDER BY p.purchased_on DESC, p.created_at DESC''')
        .map((row) => CardPurchase(
              id: row['id'] as String,
              cardId: row['card_id'] as String,
              description: row['description'] as String,
              amountInCents: row['amount_cents'] as int,
              purchasedOn: DateTime.parse(row['purchased_on'] as String),
              installments: row['installments'] as int,
              createdAt: DateTime.parse(row['created_at'] as String),
              paidInstallments:
                  paidInstallments[row['id'] as String] ?? const <int>{},
              category: row['resolved_category'] as String,
              subcategory: row['resolved_subcategory'] as String,
              categoryId: row['category_id'] as String?,
              subcategoryId: row['subcategory_id'] as String?,
            ))
        .toList();
  }

  List<CardInvoice> loadCardInvoices() => _database
      .select('SELECT * FROM card_invoices '
          'ORDER BY reference_year DESC, reference_month DESC, card_id')
      .map((row) => CardInvoice(
            id: row['id'] as String,
            cardId: row['card_id'] as String,
            referenceYear: row['reference_year'] as int,
            referenceMonth: row['reference_month'] as int,
            closingOn: DateTime.parse(row['closing_on'] as String),
            dueOn: DateTime.parse(row['due_on'] as String),
            status: switch (row['status'] as String) {
              'open' => CardInvoiceStatus.open,
              'closed' => CardInvoiceStatus.closed,
              'partially_paid' => CardInvoiceStatus.partiallyPaid,
              'paid' => CardInvoiceStatus.paid,
              _ => throw const FormatException('Status de fatura inválido.'),
            },
            createdAt: DateTime.parse(row['created_at'] as String),
            updatedAt: DateTime.parse(row['updated_at'] as String),
          ))
      .toList();

  List<CardInvoicePayment> loadCardInvoicePayments() => _database
      .select('SELECT * FROM card_invoice_payments ORDER BY paid_on DESC')
      .map((row) => CardInvoicePayment(
            id: row['id'] as String,
            invoiceId: row['invoice_id'] as String,
            accountId: row['account_id'] as String,
            transactionId: row['transaction_id'] as String?,
            amountInCents: row['amount_cents'] as int,
            paidOn: DateTime.parse(row['paid_on'] as String),
            createdAt: DateTime.parse(row['created_at'] as String),
          ))
      .toList();

  List<InvestmentPosition> loadInvestments() => _database
      .select('SELECT * FROM investments WHERE ${_activeRowPredicate()} '
          'ORDER BY created_at DESC')
      .map((row) => InvestmentPosition(
            id: row['id'] as String,
            name: row['name'] as String,
            type: InvestmentType.values.byName(row['type'] as String),
            investedAmountInCents: row['invested_amount_cents'] as int,
            currentValueInCents: row['current_value_cents'] as int,
            fixedIncomeType: row['fixed_income_type'] == null
                ? null
                : FixedIncomeType.values
                    .byName(row['fixed_income_type'] as String),
            institutionName: row['institution_name'] as String?,
            maturityDate: row['maturity_date'] == null
                ? null
                : DateTime.parse(row['maturity_date'] as String),
            quotedRateBasisPoints: row['quoted_rate_bps'] as int?,
            quotedRatePeriod: row['quoted_rate_period'] == null
                ? null
                : InvestmentRatePeriod.values
                    .byName(row['quoted_rate_period'] as String),
            yieldPaymentDay: row['yield_payment_day'] as int?,
            createdAt: DateTime.parse(row['created_at'] as String),
          ))
      .toList();

  List<Budget> loadBudgets() => _database
      .select(schemaVersion < 17
          ? '''SELECT *, category AS resolved_category, NULL AS category_id
             FROM budgets WHERE ${_activeRowPredicate()}
             ORDER BY year DESC, month DESC, created_at DESC'''
          : '''SELECT b.*, COALESCE(c.name, b.category) AS resolved_category
             FROM budgets b LEFT JOIN finance_categories c ON c.id = b.category_id
             WHERE ${_activeRowPredicate('b')}
             ORDER BY b.year DESC, b.month DESC, b.created_at DESC''')
      .map((row) => Budget(
            id: row['id'] as String,
            category: row['resolved_category'] as String,
            categoryId: row['category_id'] as String?,
            limitInCents: row['limit_cents'] as int,
            year: row['year'] as int,
            month: row['month'] as int,
            createdAt: DateTime.parse(row['created_at'] as String),
          ))
      .toList();

  List<Subscription> loadSubscriptions() => _database
      .select(schemaVersion < 17
          ? '''SELECT *, category AS resolved_category, NULL AS category_id
             FROM subscriptions WHERE ${_activeRowPredicate()}
             ORDER BY is_active DESC, billing_day ASC, created_at DESC'''
          : '''SELECT s.*, COALESCE(c.name, s.category) AS resolved_category
             FROM subscriptions s LEFT JOIN finance_categories c ON c.id = s.category_id
             WHERE ${_activeRowPredicate('s')}
             ORDER BY s.is_active DESC, s.billing_day ASC, s.created_at DESC''')
      .map((row) => Subscription(
            id: row['id'] as String,
            name: row['name'] as String,
            amountInCents: row['amount_cents'] as int,
            billingDay: row['billing_day'] as int,
            category: row['resolved_category'] as String,
            categoryId: row['category_id'] as String?,
            isActive: (row['is_active'] as int) == 1,
            createdAt: DateTime.parse(row['created_at'] as String),
          ))
      .toList();

  SalaryAllocation loadSalaryAllocation() {
    final row =
        _database.select('SELECT * FROM salary_allocation WHERE id = 1').single;
    return SalaryAllocation(
      essentialsPercent: row['essentials_percent'] as int,
      goalsPercent: row['goals_percent'] as int,
      freePercent: row['free_percent'] as int,
    );
  }

  List<FinancialGoal> loadFinancialGoals() => _database
      .select(schemaVersion < 17
          ? '''SELECT *, category AS resolved_category FROM financial_goals
             WHERE ${_activeRowPredicate()}
             ORDER BY deadline IS NULL, deadline ASC, created_at DESC'''
          : '''SELECT *, COALESCE(goal_category_name, category) AS resolved_category
             FROM financial_goals WHERE ${_activeRowPredicate()}
             ORDER BY deadline IS NULL, deadline ASC, created_at DESC''')
      .map((row) => FinancialGoal(
            id: row['id'] as String,
            name: row['name'] as String,
            targetInCents: row['target_cents'] as int,
            savedInCents: row['saved_cents'] as int,
            deadline: row['deadline'] == null
                ? null
                : DateTime.parse(row['deadline'] as String),
            iconKey: row['icon_key'] as String,
            category: row['resolved_category'] as String,
            createdAt: DateTime.parse(row['created_at'] as String),
          ))
      .toList();

  List<String> loadGoalCategories() => _database
      .select('SELECT name FROM goal_categories ORDER BY name COLLATE NOCASE')
      .map((row) => row['name'] as String)
      .toList();

  List<int> loadMobileQuickPages() {
    final rows = _database.select(
        "SELECT value FROM app_settings WHERE key = 'mobile_quick_pages'");
    if (rows.isEmpty) return [0, 1, 6, 8];
    final parsed =
        (rows.first['value'] as String).split(',').map(int.tryParse).toList();
    if (parsed.length != 4 ||
        parsed.contains(null) ||
        parsed.any((value) => value! < 0 || value > 11 || value == 9)) {
      return [0, 1, 6, 8];
    }
    final normalized = <int>[];
    for (final page in parsed.cast<int>()) {
      final mapped = page == 4 ? 6 : page;
      if (!normalized.contains(mapped)) normalized.add(mapped);
    }
    for (final fallback in [0, 1, 6, 8]) {
      if (normalized.length == 4) break;
      if (!normalized.contains(fallback)) normalized.add(fallback);
    }
    return normalized;
  }

  String? loadPreference(String key) {
    final rows =
        _database.select('SELECT value FROM app_settings WHERE key = ?', [key]);
    return rows.isEmpty ? null : rows.first['value'] as String;
  }

  void savePreference(String key, String value) => _database.execute(
      'INSERT OR REPLACE INTO app_settings(key, value) VALUES (?, ?)',
      [key, value]);

  void saveMobileQuickPages(List<int> pages) => _database.execute(
      "INSERT OR REPLACE INTO app_settings(key, value) VALUES ('mobile_quick_pages', ?)",
      [pages.join(',')]);

  List<SalarySchedule> loadSalarySchedules() => _database
      .select('SELECT * FROM salary_schedules ORDER BY created_at')
      .map((row) => SalarySchedule(
            id: row['id'] as String,
            accountId: row['account_id'] as String,
            amountInCents: row['amount_cents'] as int,
            description: row['description'] as String,
            subcategory: row['subcategory'] as String,
            firstDueOn: DateTime.parse(row['first_due_on'] as String),
            paymentDay: row['payment_day'] as int,
            createdAt: DateTime.parse(row['created_at'] as String),
          ))
      .toList();

  void insertSalarySchedule(SalarySchedule item) =>
      _database.execute('''INSERT INTO salary_schedules
      (id, account_id, amount_cents, description, subcategory, first_due_on, payment_day, created_at)
      VALUES (?, ?, ?, ?, ?, ?, ?, ?)''', [
        item.id,
        item.accountId,
        item.amountInCents,
        item.description,
        item.subcategory,
        item.firstDueOn.toIso8601String(),
        item.paymentDay,
        item.createdAt.toIso8601String()
      ]);

  void deleteSalarySchedule(String id) =>
      _database.execute('DELETE FROM salary_schedules WHERE id = ?', [id]);

  void insertGoalCategory(String name) =>
      _database.execute('INSERT INTO goal_categories(name) VALUES (?)', [name]);

  void renameGoalCategory(String oldName, String newName) {
    final clean = newName.trim();
    if (clean.isEmpty) throw ArgumentError('Informe o nome da categoria.');
    transaction(() {
      _database.execute('UPDATE goal_categories SET name = ? WHERE name = ?',
          [clean, oldName]);
      _database.execute(
          'UPDATE financial_goals SET category = ? WHERE category = ?',
          [clean, oldName]);
    });
  }

  List<FinanceCategory> loadFinanceCategories() => _database
      .select(schemaVersion < 17
          ? 'SELECT * FROM finance_categories ORDER BY is_system DESC, name'
          : 'SELECT * FROM finance_categories WHERE archived_at IS NULL '
              'ORDER BY is_system DESC, name')
      .map((row) => FinanceCategory(
            id: row['id'] as String,
            name: row['name'] as String,
            type: TransactionType.values.byName(row['type'] as String),
            isSystem: (row['is_system'] as int) == 1,
            createdAt: DateTime.parse(row['created_at'] as String),
          ))
      .toList();

  List<FinanceSubcategory> loadFinanceSubcategories() => _database
      .select(
          'SELECT * FROM finance_subcategories ORDER BY is_system DESC, name')
      .map((row) => FinanceSubcategory(
            id: row['id'] as String,
            categoryId: row['category_id'] as String,
            name: row['name'] as String,
            isSystem: (row['is_system'] as int) == 1,
            createdAt: DateTime.parse(row['created_at'] as String),
          ))
      .toList();

  void insertAccount(Account account) => _database.execute(
        '''INSERT INTO accounts(
          id, name, opening_balance_cents, created_at, institution,
          custom_institution_name, custom_icon_key
        ) VALUES (?, ?, ?, ?, ?, ?, ?)''',
        [
          account.id,
          account.name,
          account.openingBalanceInCents,
          account.createdAt.toIso8601String(),
          account.institution.name,
          account.customInstitutionName,
          account.customIconKey,
        ],
      );

  void updateAccountDetails({
    required String id,
    required String name,
    required AccountInstitution institution,
    String? customInstitutionName,
    String? customIconKey,
  }) =>
      _database.execute(
        '''UPDATE accounts SET
          name = ?, institution = ?, custom_institution_name = ?, custom_icon_key = ?
        WHERE id = ?''',
        [name, institution.name, customInstitutionName, customIconKey, id],
      );

  void updateAccountOpeningBalance(String id, int cents) => _database.execute(
      'UPDATE accounts SET opening_balance_cents = ? WHERE id = ?',
      [cents, id]);

  (String, String) _resolveCategory(String raw, String type, DateTime createdAt,
      {String? preferredId, bool allowArchived = false}) {
    if (preferredId != null) {
      final rows = _database.select(
          'SELECT id, name, type, archived_at FROM finance_categories WHERE id = ?',
          [preferredId]);
      if (rows.length != 1 || rows.single['type'] != type) {
        throw ArgumentError('Categoria incompatível com o lançamento.');
      }
      if (rows.single['archived_at'] != null && !allowArchived) {
        throw ArgumentError('A categoria está arquivada.');
      }
      return (preferredId, rows.single['name'] as String);
    }
    final name = raw.trim().isEmpty ? 'Outros' : raw.trim();
    final matches = _database.select(
        'SELECT id, name, archived_at FROM finance_categories WHERE type = ?',
        [type]);
    for (final row in matches) {
      if ((row['name'] as String).trim().toLowerCase() == name.toLowerCase()) {
        if (row['archived_at'] != null) {
          throw ArgumentError('A categoria está arquivada.');
        }
        return (row['id'] as String, row['name'] as String);
      }
    }
    final id = const Uuid().v4();
    _database.execute(
        'INSERT INTO finance_categories(id, name, type, is_system, created_at) '
        'VALUES (?, ?, ?, 0, ?)',
        [id, name, type, createdAt.toIso8601String()]);
    return (id, name);
  }

  (String, String) _resolveSubcategory(
      String raw, String parentId, DateTime createdAt,
      {String? preferredId}) {
    if (preferredId != null) {
      final rows = _database.select(
          'SELECT id, name, category_id FROM finance_subcategories WHERE id = ?',
          [preferredId]);
      if (rows.length != 1 || rows.single['category_id'] != parentId) {
        throw ArgumentError('Subcategoria incompatível com a categoria.');
      }
      return (preferredId, rows.single['name'] as String);
    }
    final name = raw.trim().isEmpty ? 'Geral' : raw.trim();
    final matches = _database.select(
        'SELECT id, name FROM finance_subcategories WHERE category_id = ?',
        [parentId]);
    for (final row in matches) {
      if ((row['name'] as String).trim().toLowerCase() == name.toLowerCase()) {
        return (row['id'] as String, row['name'] as String);
      }
    }
    final id = const Uuid().v4();
    _database.execute(
        'INSERT INTO finance_subcategories(id, category_id, name, is_system, created_at) '
        'VALUES (?, ?, ?, 0, ?)',
        [id, parentId, name, createdAt.toIso8601String()]);
    return (id, name);
  }

  void renameFinanceCategory(String id, String newName) {
    final clean = newName.trim();
    if (clean.isEmpty) throw ArgumentError('Informe o nome da categoria.');
    transaction(() {
      final rows = _database
          .select('SELECT id FROM finance_categories WHERE id = ?', [id]);
      if (rows.isEmpty) throw ArgumentError('Categoria não encontrada.');
      _database.execute(
          'UPDATE finance_categories SET name = ? WHERE id = ?', [clean, id]);
      _database.execute(
          'UPDATE transactions SET category = ? WHERE category_id = ?',
          [clean, id]);
      _database.execute(
          'UPDATE budgets SET category = ? WHERE category_id = ?', [clean, id]);
      _database.execute(
          'UPDATE subscriptions SET category = ? WHERE category_id = ?',
          [clean, id]);
    });
  }

  void archiveFinanceCategory(String id, {DateTime? at}) {
    _database.execute(
        'UPDATE finance_categories SET archived_at = ? '
        'WHERE id = ? AND is_system = 0 AND archived_at IS NULL',
        [(at ?? DateTime.now()).toUtc().toIso8601String(), id]);
  }

  void insertTransaction(TransactionRecord item) => transaction(() {
        if (schemaVersion < 17) {
          _database.execute(
              '''INSERT INTO transactions(id, account_id, destination_account_id,
              type, amount_cents, description, category, subcategory, occurred_on,
              created_at, schedule_type, series_id, installment_number,
              installment_count, is_settled)
              VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)''',
              [
                item.id,
                item.accountId,
                item.destinationAccountId,
                item.type.name,
                item.amountInCents,
                item.description,
                item.category,
                item.subcategory,
                item.occurredOn.toIso8601String(),
                item.createdAt.toIso8601String(),
                item.scheduleType.name,
                item.seriesId,
                item.installmentNumber,
                item.installmentCount,
                item.isSettled ? 1 : 0,
              ]);
          return;
        }
        final category = item.type == TransactionType.transfer ||
                item.systemType == TransactionSystemType.cardPayment
            ? (null, item.category)
            : _resolveCategory(item.category, item.type.name, item.createdAt,
                preferredId: item.categoryId);
        final subcategory = category.$1 == null
            ? (null, item.subcategory)
            : _resolveSubcategory(
                item.subcategory, category.$1!, item.createdAt,
                preferredId: item.subcategoryId);
        _database.execute(
          '''INSERT INTO transactions(
          id, account_id, destination_account_id, type, amount_cents,
          description, category, subcategory, occurred_on, created_at,
          schedule_type, series_id, installment_number, installment_count, is_settled,
          category_id, subcategory_id
        ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)''',
          [
            item.id,
            item.accountId,
            item.destinationAccountId,
            item.type.name,
            item.amountInCents,
            item.description,
            category.$2,
            subcategory.$2,
            item.occurredOn.toIso8601String(),
            item.createdAt.toIso8601String(),
            item.scheduleType.name,
            item.seriesId,
            item.installmentNumber,
            item.installmentCount,
            item.isSettled ? 1 : 0,
            category.$1,
            subcategory.$1,
          ],
        );
        if (schemaVersion >= 18 && item.systemType != null) {
          _database.execute(
              'UPDATE transactions SET system_type = ? WHERE id = ?',
              ['card_payment', item.id]);
        }
      });

  void insertTask(TaskItem item) => _database.execute(
        'INSERT INTO tasks(id, title, due_on, is_done, created_at) VALUES (?, ?, ?, ?, ?)',
        [
          item.id,
          item.title,
          item.dueOn?.toIso8601String(),
          item.isDone ? 1 : 0,
          item.createdAt.toIso8601String()
        ],
      );

  void setTaskDone(String id, bool value) => _database.execute(
        'UPDATE tasks SET is_done = ? WHERE id = ?',
        [value ? 1 : 0, id],
      );

  void deleteTask(String id) =>
      softDelete(SoftDeleteEntity.task, id, DateTime.now().toUtc());

  void insertShoppingItem(ShoppingItem item) => _database.execute(
        '''INSERT INTO shopping_items(
          id, name, quantity, estimated_unit_price_cents, priority, is_purchased,
          image_path, description, created_at
        ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)''',
        [
          item.id,
          item.name,
          item.quantity,
          item.estimatedUnitPriceInCents,
          item.priority.name,
          item.isPurchased ? 1 : 0,
          item.imagePath,
          item.description,
          item.createdAt.toIso8601String(),
        ],
      );

  void setShoppingItemImage(String id, String? imagePath) => _database.execute(
        'UPDATE shopping_items SET image_path = ? WHERE id = ?',
        [imagePath, id],
      );

  void setShoppingItemPurchased(String id, bool value) => _database.execute(
        'UPDATE shopping_items SET is_purchased = ? WHERE id = ?',
        [value ? 1 : 0, id],
      );

  void updateShoppingItem(ShoppingItem item) => _database.execute(
        '''UPDATE shopping_items SET name = ?, quantity = ?,
          estimated_unit_price_cents = ?, priority = ?, is_purchased = ?,
          image_path = ?, description = ? WHERE id = ?''',
        [
          item.name,
          item.quantity,
          item.estimatedUnitPriceInCents,
          item.priority.name,
          item.isPurchased ? 1 : 0,
          item.imagePath,
          item.description,
          item.id,
        ],
      );

  void deleteShoppingItem(String id) =>
      softDelete(SoftDeleteEntity.shoppingItem, id, DateTime.now().toUtc());

  void insertCreditCard(CreditCard card) => _database.execute(
        '''INSERT INTO credit_cards(
          id, name, brand, last_four, limit_cents, closing_day, due_day, color_value, created_at
        ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)''',
        [
          card.id,
          card.name,
          card.brand.name,
          card.lastFour,
          card.limitInCents,
          card.closingDay,
          card.dueDay,
          card.colorValue,
          card.createdAt.toIso8601String(),
        ],
      );

  void insertCardPurchase(CardPurchase purchase) => transaction(() {
        final category = schemaVersion < 18
            ? (null, purchase.category)
            : _resolveCategory(purchase.category, 'expense', purchase.createdAt,
                preferredId: purchase.categoryId);
        final subcategory = category.$1 == null
            ? (null, purchase.subcategory)
            : _resolveSubcategory(
                purchase.subcategory, category.$1!, purchase.createdAt,
                preferredId: purchase.subcategoryId);
        _database.execute(
          schemaVersion < 18
              ? '''INSERT INTO card_purchases(id, card_id, description,
                   amount_cents, purchased_on, installments, created_at)
                   VALUES (?, ?, ?, ?, ?, ?, ?)'''
              : '''INSERT INTO card_purchases(id, card_id, description,
                   amount_cents, purchased_on, installments, created_at,
                   category_id, subcategory_id)
                   VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)''',
          [
            purchase.id,
            purchase.cardId,
            purchase.description,
            purchase.amountInCents,
            purchase.purchasedOn.toIso8601String(),
            purchase.installments,
            purchase.createdAt.toIso8601String(),
            if (schemaVersion >= 18) category.$1,
            if (schemaVersion >= 18) subcategory.$1,
          ],
        );
      });

  void insertCardInvoice(CardInvoice invoice) => _database.execute(
        '''INSERT INTO card_invoices(id, card_id, reference_year,
        reference_month, closing_on, due_on, status, created_at, updated_at)
        VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)''',
        [
          invoice.id,
          invoice.cardId,
          invoice.referenceYear,
          invoice.referenceMonth,
          invoice.closingOn.toIso8601String(),
          invoice.dueOn.toIso8601String(),
          switch (invoice.status) {
            CardInvoiceStatus.partiallyPaid => 'partially_paid',
            _ => invoice.status.name,
          },
          invoice.createdAt.toIso8601String(),
          invoice.updatedAt.toIso8601String(),
        ],
      );

  void updateCardInvoiceStatus(
          String id, CardInvoiceStatus status, DateTime updatedAt) =>
      _database.execute(
        'UPDATE card_invoices SET status = ?, updated_at = ? WHERE id = ?',
        [
          status == CardInvoiceStatus.partiallyPaid
              ? 'partially_paid'
              : status.name,
          updatedAt.toIso8601String(),
          id,
        ],
      );

  void insertCardInvoicePayment(CardInvoicePayment payment) =>
      _database.execute(
        '''INSERT INTO card_invoice_payments(id, invoice_id, account_id,
        transaction_id, amount_cents, paid_on, created_at)
        VALUES (?, ?, ?, ?, ?, ?, ?)''',
        [
          payment.id,
          payment.invoiceId,
          payment.accountId,
          payment.transactionId,
          payment.amountInCents,
          payment.paidOn.toIso8601String(),
          payment.createdAt.toIso8601String(),
        ],
      );

  void deleteCardInvoicePayment(String id) =>
      _database.execute('DELETE FROM card_invoice_payments WHERE id = ?', [id]);

  void setCardPurchaseInstallmentsPaid(
    String purchaseId,
    Set<int> paidInstallments,
    DateTime paidOn,
  ) {
    final purchase = _database.select(
      'SELECT installments FROM card_purchases WHERE id = ? '
      'AND ${_activeRowPredicate()}',
      [purchaseId],
    );
    if (purchase.isEmpty) throw ArgumentError('Compra não encontrada.');
    final installmentCount = purchase.single['installments'] as int;
    if (paidInstallments
        .any((number) => number < 1 || number > installmentCount)) {
      throw ArgumentError('Parcela inválida para esta compra.');
    }
    final current = _database
        .select(
          'SELECT installment_number FROM card_installment_payments WHERE purchase_id = ?',
          [purchaseId],
        )
        .map((row) => row['installment_number'] as int)
        .toSet();
    final toAdd = paidInstallments.difference(current);
    final toRemove = current.difference(paidInstallments);
    transaction(() {
      for (final installment in toRemove) {
        _database.execute(
          'DELETE FROM card_installment_payments WHERE purchase_id = ? AND installment_number = ?',
          [purchaseId, installment],
        );
      }
      for (final installment in toAdd) {
        _database.execute(
          'INSERT INTO card_installment_payments(purchase_id, installment_number, paid_on) VALUES (?, ?, ?)',
          [purchaseId, installment, paidOn.toIso8601String()],
        );
      }
    });
  }

  void insertInvestment(InvestmentPosition investment) => _database.execute(
        '''INSERT INTO investments(
          id, name, type, invested_amount_cents, current_value_cents, created_at,
          fixed_income_type, institution_name, maturity_date
          , quoted_rate_bps, quoted_rate_period, yield_payment_day
        ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)''',
        [
          investment.id,
          investment.name,
          investment.type.name,
          investment.investedAmountInCents,
          investment.currentValueInCents,
          investment.createdAt.toIso8601String(),
          investment.fixedIncomeType?.name,
          investment.institutionName,
          investment.maturityDate?.toIso8601String(),
          investment.quotedRateBasisPoints,
          investment.quotedRatePeriod?.name,
          investment.yieldPaymentDay,
        ],
      );

  void updateInvestment(InvestmentPosition investment) => _database.execute(
        '''UPDATE investments SET
          name = ?, type = ?, invested_amount_cents = ?, current_value_cents = ?,
          fixed_income_type = ?, institution_name = ?, maturity_date = ?,
          quoted_rate_bps = ?, quoted_rate_period = ?, yield_payment_day = ?
        WHERE id = ?''',
        [
          investment.name,
          investment.type.name,
          investment.investedAmountInCents,
          investment.currentValueInCents,
          investment.fixedIncomeType?.name,
          investment.institutionName,
          investment.maturityDate?.toIso8601String(),
          investment.quotedRateBasisPoints,
          investment.quotedRatePeriod?.name,
          investment.yieldPaymentDay,
          investment.id,
        ],
      );

  void insertFinanceCategory(FinanceCategory category) {
    if (schemaVersion >= 17) {
      final existing = _database.select(
          'SELECT name, archived_at FROM finance_categories WHERE type = ?',
          [category.type.name]);
      for (final row in existing) {
        if ((row['name'] as String).toLowerCase() ==
            category.name.toLowerCase()) {
          throw ArgumentError(row['archived_at'] == null
              ? 'Essa categoria já existe.'
              : 'Essa categoria está arquivada; escolha outro nome.');
        }
      }
    }
    _database.execute(
      '''INSERT INTO finance_categories(id, name, type, is_system, created_at)
        VALUES (?, ?, ?, ?, ?)''',
      [
        category.id,
        category.name,
        category.type.name,
        category.isSystem ? 1 : 0,
        category.createdAt.toIso8601String(),
      ],
    );
  }

  void insertFinanceSubcategory(FinanceSubcategory subcategory) =>
      _database.execute(
        '''INSERT INTO finance_subcategories(
          id, category_id, name, is_system, created_at
        ) VALUES (?, ?, ?, ?, ?)''',
        [
          subcategory.id,
          subcategory.categoryId,
          subcategory.name,
          subcategory.isSystem ? 1 : 0,
          subcategory.createdAt.toIso8601String(),
        ],
      );

  void setTransactionSettled(String id, bool value) => _database.execute(
        'UPDATE transactions SET is_settled = ? WHERE id = ?',
        [value ? 1 : 0, id],
      );

  void updateTransactionDetails(String id, int cents, String description) =>
      _database.execute(
          'UPDATE transactions SET amount_cents = ?, description = ? WHERE id = ?',
          [cents, description, id]);

  void updateTransaction(TransactionRecord item) => transaction(() {
        if (schemaVersion < 17) {
          _database.execute(
              '''UPDATE transactions SET account_id = ?, destination_account_id = ?,
              type = ?, amount_cents = ?, description = ?, occurred_on = ?,
              category = ?, subcategory = ?, schedule_type = ?, series_id = ?,
              installment_number = ?, installment_count = ?, is_settled = ?
              WHERE id = ?''',
              [
                item.accountId,
                item.destinationAccountId,
                item.type.name,
                item.amountInCents,
                item.description,
                item.occurredOn.toIso8601String(),
                item.category,
                item.subcategory,
                item.scheduleType.name,
                item.seriesId,
                item.installmentNumber,
                item.installmentCount,
                item.isSettled ? 1 : 0,
                item.id,
              ]);
          return;
        }
        final existing = _database.select(
            'SELECT category_id FROM transactions WHERE id = ? '
            'AND ${_activeRowPredicate()}',
            [item.id]);
        final keepsCategory = existing.isNotEmpty &&
            existing.single['category_id'] == item.categoryId;
        final category = item.type == TransactionType.transfer
            ? (null, item.category)
            : _resolveCategory(item.category, item.type.name, item.createdAt,
                preferredId: item.categoryId, allowArchived: keepsCategory);
        final subcategory = category.$1 == null
            ? (null, item.subcategory)
            : _resolveSubcategory(
                item.subcategory, category.$1!, item.createdAt,
                preferredId: item.subcategoryId);
        _database.execute(
          '''UPDATE transactions SET
          account_id = ?, destination_account_id = ?, type = ?, amount_cents = ?,
          description = ?, occurred_on = ?, category = ?, subcategory = ?,
          schedule_type = ?, series_id = ?, installment_number = ?,
          installment_count = ?, is_settled = ?, category_id = ?, subcategory_id = ?
        WHERE id = ?''',
          [
            item.accountId,
            item.destinationAccountId,
            item.type.name,
            item.amountInCents,
            item.description,
            item.occurredOn.toIso8601String(),
            category.$2,
            subcategory.$2,
            item.scheduleType.name,
            item.seriesId,
            item.installmentNumber,
            item.installmentCount,
            item.isSettled ? 1 : 0,
            category.$1,
            subcategory.$1,
            item.id,
          ],
        );
      });

  void insertBudget(Budget budget) => transaction(() {
        if (schemaVersion < 17) {
          _database.execute(
              '''INSERT INTO budgets(id, category, limit_cents, year, month, created_at)
              VALUES (?, ?, ?, ?, ?, ?)''',
              [
                budget.id,
                budget.category,
                budget.limitInCents,
                budget.year,
                budget.month,
                budget.createdAt.toIso8601String(),
              ]);
          return;
        }
        final category = _resolveCategory(
            budget.category, 'expense', budget.createdAt,
            preferredId: budget.categoryId);
        _database.execute(
          '''INSERT INTO budgets(id, category, limit_cents, year, month, created_at, category_id)
        VALUES (?, ?, ?, ?, ?, ?, ?)''',
          [
            budget.id,
            category.$2,
            budget.limitInCents,
            budget.year,
            budget.month,
            budget.createdAt.toIso8601String(),
            category.$1,
          ],
        );
      });

  void insertSubscription(Subscription subscription) => transaction(() {
        if (schemaVersion < 17) {
          _database.execute(
              '''INSERT INTO subscriptions(id, name, amount_cents, billing_day,
              category, is_active, created_at) VALUES (?, ?, ?, ?, ?, ?, ?)''',
              [
                subscription.id,
                subscription.name,
                subscription.amountInCents,
                subscription.billingDay,
                subscription.category,
                subscription.isActive ? 1 : 0,
                subscription.createdAt.toIso8601String(),
              ]);
          return;
        }
        final category = _resolveCategory(
            subscription.category, 'expense', subscription.createdAt,
            preferredId: subscription.categoryId);
        _database.execute(
          '''INSERT INTO subscriptions(id, name, amount_cents, billing_day, category, is_active, created_at, category_id)
        VALUES (?, ?, ?, ?, ?, ?, ?, ?)''',
          [
            subscription.id,
            subscription.name,
            subscription.amountInCents,
            subscription.billingDay,
            category.$2,
            subscription.isActive ? 1 : 0,
            subscription.createdAt.toIso8601String(),
            category.$1,
          ],
        );
      });

  void updateSubscription(Subscription item) => transaction(() {
        if (schemaVersion < 17) {
          _database
              .execute('''UPDATE subscriptions SET name = ?, amount_cents = ?,
              billing_day = ?, category = ?, is_active = ? WHERE id = ?''', [
            item.name,
            item.amountInCents,
            item.billingDay,
            item.category,
            item.isActive ? 1 : 0,
            item.id,
          ]);
          return;
        }
        final existing = _database.select(
            'SELECT category_id FROM subscriptions WHERE id = ? '
            'AND ${_activeRowPredicate()}',
            [item.id]);
        final keepsCategory = existing.isNotEmpty &&
            existing.single['category_id'] == item.categoryId;
        final category = _resolveCategory(
            item.category, 'expense', item.createdAt,
            preferredId: item.categoryId, allowArchived: keepsCategory);
        _database.execute(
            '''UPDATE subscriptions SET name = ?, amount_cents = ?, billing_day = ?,
      category = ?, is_active = ?, category_id = ? WHERE id = ?''',
            [
              item.name,
              item.amountInCents,
              item.billingDay,
              category.$2,
              item.isActive ? 1 : 0,
              category.$1,
              item.id
            ]);
      });

  void setSubscriptionActive(String id, bool active) => _database.execute(
      'UPDATE subscriptions SET is_active = ? WHERE id = ?',
      [active ? 1 : 0, id]);

  void insertFinancialGoal(FinancialGoal goal) => transaction(() {
        var category = goal.category;
        if (schemaVersion >= 17) {
          final existing = _database.select('SELECT name FROM goal_categories');
          final match = existing.where((row) =>
              (row['name'] as String).toLowerCase() ==
              goal.category.trim().toLowerCase());
          if (match.isNotEmpty) {
            category = match.first['name'] as String;
          } else {
            category = goal.category.trim();
            if (category.isEmpty) category = 'Outros';
            insertGoalCategory(category);
          }
        }
        _database.execute(
          schemaVersion < 17
              ? '''INSERT INTO financial_goals(id, name, target_cents,
                   saved_cents, deadline, icon_key, created_at, category)
                   VALUES (?, ?, ?, ?, ?, ?, ?, ?)'''
              : '''INSERT INTO financial_goals(id, name, target_cents,
                   saved_cents, deadline, icon_key, created_at, category,
                   goal_category_name) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)''',
          [
            goal.id,
            goal.name,
            goal.targetInCents,
            goal.savedInCents,
            goal.deadline?.toIso8601String(),
            goal.iconKey,
            goal.createdAt.toIso8601String(),
            category,
            if (schemaVersion >= 17) category,
          ],
        );
      });

  void updateFinancialGoalSaved(String id, int savedInCents) =>
      _database.execute(
        'UPDATE financial_goals SET saved_cents = ? WHERE id = ?',
        [savedInCents, id],
      );

  bool softDelete(SoftDeleteEntity entity, String id, DateTime deletedAtUtc) {
    if (schemaVersion < 19) {
      throw StateError('Exclusão lógica exige o schema 19.');
    }
    final result = _database.select(
      'SELECT id FROM ${entity.tableName} WHERE id = ? AND deleted_at IS NULL',
      [id],
    );
    if (result.isEmpty) return false;
    _database.execute(
      'UPDATE ${entity.tableName} SET deleted_at = ? WHERE id = ? AND deleted_at IS NULL',
      [deletedAtUtc.toUtc().toIso8601String(), id],
    );
    return true;
  }

  bool restore(SoftDeleteEntity entity, String id) {
    if (schemaVersion < 19) {
      throw StateError('Restauração lógica exige o schema 19.');
    }
    final result = _database.select(
      'SELECT id FROM ${entity.tableName} WHERE id = ? AND deleted_at IS NOT NULL',
      [id],
    );
    if (result.isEmpty) return false;
    _database.execute(
      'UPDATE ${entity.tableName} SET deleted_at = NULL WHERE id = ? AND deleted_at IS NOT NULL',
      [id],
    );
    return true;
  }

  void deleteAccount(String id) =>
      softDelete(SoftDeleteEntity.account, id, DateTime.now().toUtc());

  void deleteTransaction(String id) =>
      softDelete(SoftDeleteEntity.transaction, id, DateTime.now().toUtc());
  void deleteBudget(String id) =>
      softDelete(SoftDeleteEntity.budget, id, DateTime.now().toUtc());
  void deleteSubscription(String id) =>
      softDelete(SoftDeleteEntity.subscription, id, DateTime.now().toUtc());
  void deleteFinancialGoal(String id) =>
      softDelete(SoftDeleteEntity.financialGoal, id, DateTime.now().toUtc());
  void deleteInvestment(String id) =>
      softDelete(SoftDeleteEntity.investment, id, DateTime.now().toUtc());

  void saveSalaryAllocation(SalaryAllocation allocation) => _database.execute(
        '''UPDATE salary_allocation
        SET essentials_percent = ?, goals_percent = ?, free_percent = ?
        WHERE id = 1''',
        [
          allocation.essentialsPercent,
          allocation.goalsPercent,
          allocation.freePercent
        ],
      );

  void transaction(void Function() operation) {
    final outermost = _transactionDepth == 0;
    final savepoint = 'organiza_nested_$_transactionDepth';
    _database.execute(outermost ? 'BEGIN IMMEDIATE' : 'SAVEPOINT $savepoint');
    _transactionDepth++;
    try {
      operation();
      _database.execute(outermost ? 'COMMIT' : 'RELEASE SAVEPOINT $savepoint');
    } catch (_) {
      if (outermost) {
        _database.execute('ROLLBACK');
      } else {
        _database.execute('ROLLBACK TO SAVEPOINT $savepoint');
        _database.execute('RELEASE SAVEPOINT $savepoint');
      }
      rethrow;
    } finally {
      _transactionDepth--;
    }
  }

  void close() => _database.close();
}
