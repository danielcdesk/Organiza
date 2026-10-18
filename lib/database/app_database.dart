import 'dart:io';

import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:sqlite3/sqlite3.dart';

import '../domain/models.dart';
import '../domain/business_date.dart';
import '../domain/app_route.dart';

/// Owns schema migrations and keeps user data on the local machine only.
class AppDatabase {
  AppDatabase._(this._database);

  final Database _database;
  static const _schemaVersion = 20;
  static const _backupTables = <String>[
    'accounts',
    'transactions',
    'tasks',
    'credit_cards',
    'card_purchases',
    'card_invoices',
    'card_invoice_items',
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
    'salary_schedule_exceptions',
    'app_settings',
    'goal_categories',
  ];

  static Future<AppDatabase> open() async {
    final appDirectory = await _applicationDataDirectory();
    final folder = Directory(path.join(appDirectory.path, 'Organiza'));
    if (!folder.existsSync()) folder.createSync(recursive: true);
    await _copyLegacyDatabaseIfNeeded(folder);
    final database = sqlite3.open(path.join(folder.path, 'organiza.db'));
    _configure(database, persistent: true);
    final instance = AppDatabase._(database);
    instance._migrate();
    return instance;
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

  static AppDatabase openInMemoryFromVersion15WithCardForTest() {
    final database = sqlite3.openInMemory();
    _configure(database, persistent: false);
    database.execute('''
      CREATE TABLE accounts (
        id TEXT PRIMARY KEY NOT NULL, name TEXT NOT NULL,
        opening_balance_cents INTEGER NOT NULL, created_at TEXT NOT NULL
      );
      CREATE TABLE transactions (
        id TEXT PRIMARY KEY NOT NULL, account_id TEXT NOT NULL,
        destination_account_id TEXT, type TEXT NOT NULL,
        amount_cents INTEGER NOT NULL, description TEXT NOT NULL,
        occurred_on TEXT NOT NULL, created_at TEXT NOT NULL,
        category TEXT NOT NULL DEFAULT 'Outros',
        subcategory TEXT NOT NULL DEFAULT 'Geral',
        schedule_type TEXT NOT NULL DEFAULT 'single', series_id TEXT,
        installment_number INTEGER NOT NULL DEFAULT 1,
        installment_count INTEGER NOT NULL DEFAULT 1,
        is_settled INTEGER NOT NULL DEFAULT 1
      );
      CREATE TABLE subscriptions (id TEXT PRIMARY KEY NOT NULL);
      CREATE TABLE finance_categories (
        id TEXT PRIMARY KEY NOT NULL, name TEXT NOT NULL,
        type TEXT NOT NULL, is_system INTEGER NOT NULL DEFAULT 0,
        created_at TEXT NOT NULL
      );
      CREATE TABLE credit_cards (
        id TEXT PRIMARY KEY NOT NULL, name TEXT NOT NULL, brand TEXT NOT NULL,
        last_four TEXT NOT NULL CHECK(length(last_four) = 4),
        limit_cents INTEGER NOT NULL CHECK(limit_cents > 0),
        closing_day INTEGER NOT NULL CHECK(closing_day BETWEEN 1 AND 28),
        due_day INTEGER NOT NULL CHECK(due_day BETWEEN 1 AND 28),
        color_value INTEGER NOT NULL, created_at TEXT NOT NULL
      );
      CREATE TABLE card_purchases (
        id TEXT PRIMARY KEY NOT NULL,
        card_id TEXT NOT NULL REFERENCES credit_cards(id) ON DELETE RESTRICT,
        description TEXT NOT NULL, amount_cents INTEGER NOT NULL,
        purchased_on TEXT NOT NULL, installments INTEGER NOT NULL,
        created_at TEXT NOT NULL
      );
      CREATE INDEX idx_card_purchases_card_date
        ON card_purchases(card_id, purchased_on DESC);
      INSERT INTO credit_cards VALUES
        ('legacy-card', 'Cartão antigo', 'visa', '4242', 100000, 10, 17, 123, '2025-01-01');
      INSERT INTO card_purchases VALUES
        ('legacy-purchase', 'legacy-card', 'Compra antiga', 2500, '2025-01-02', 1, '2025-01-02');
      INSERT INTO accounts VALUES ('legacy-account', 'Legada', 0, '2025-01-01');
      INSERT INTO transactions(id, account_id, destination_account_id, type, amount_cents,
        description, occurred_on, created_at) VALUES
        ('legacy-transaction', 'legacy-account', NULL, 'expense', 100, 'Data antiga',
         '2025-01-02T23:45:00.000-03:00', '2025-01-02');
      PRAGMA user_version = 15;
    ''');
    final instance = AppDatabase._(database);
    instance._migrate();
    return instance;
  }

  int get schemaVersion =>
      _database.select('PRAGMA user_version').first['user_version'] as int;

  /// Exports every user table as a versioned, JSON-compatible snapshot.
  ///
  /// The snapshot is intentionally separate from the SQLite file so it can be
  /// encrypted and validated before a restore. It is only accepted for the
  /// current schema version; older database files must first pass the normal
  /// SQLite migration path.
  Map<String, Object?> exportSnapshot() {
    _database.execute('BEGIN IMMEDIATE');
    try {
      final snapshot = <String, Object?>{
        'schemaVersion': schemaVersion,
        'tables': <String, Object?>{
          for (final table in _backupTables) table: _rows(table),
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
    if (version != schemaVersion) {
      throw FormatException(
          'Backup usa o schema $version; esta instalação usa $schemaVersion.');
    }
    final rawTables = snapshot['tables'];
    if (rawTables is! Map) {
      throw const FormatException('Backup sem a seção de tabelas.');
    }
    final tables = <String, List<Map<String, dynamic>>>{};
    for (final table in _backupTables) {
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
      for (final table in _backupTables.reversed) {
        _database.execute('DELETE FROM "$table"');
      }
      for (final table in _backupTables) {
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
      final foreignKeys = _database.select('PRAGMA foreign_key_check');
      if (foreignKeys.isNotEmpty) {
        throw const FormatException('Backup viola integridade referencial.');
      }
      final integrity = _database.select('PRAGMA integrity_check').first.values;
      if (integrity.isEmpty || integrity.first != 'ok') {
        throw const FormatException(
            'Backup falhou na verificação de integridade.');
      }
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
    final current =
        _database.select('PRAGMA user_version').first['user_version'] as int;
    if (current > _schemaVersion) {
      throw StateError(
          'O banco foi criado por uma versão mais recente do Organiza.');
    }
    if (current < 1) {
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
    if (current < 2) {
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
    if (current < 3) {
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
    if (current < 4) {
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
    if (current < 5) {
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
    if (current < 6) {
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
    if (current < 7) {
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
    if (current < 8) {
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
    if (current < 9) {
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
    if (current < 10) {
      _database.execute('''
        ALTER TABLE investments ADD COLUMN quoted_rate_bps INTEGER
          CHECK(quoted_rate_bps BETWEEN -10000 AND 100000);
        ALTER TABLE investments ADD COLUMN quoted_rate_period TEXT
          CHECK(quoted_rate_period IN ('monthly', 'annual'));
      ''');
      _database.execute('PRAGMA user_version = 10');
    }
    if (current < 11) {
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
    if (current < 12) {
      _database
          .execute('ALTER TABLE shopping_items ADD COLUMN image_path TEXT');
      _database.execute('PRAGMA user_version = 12');
    }
    if (current < 13) {
      _database.execute('''
        ALTER TABLE accounts ADD COLUMN custom_institution_name TEXT;
        ALTER TABLE accounts ADD COLUMN custom_icon_key TEXT;
      ''');
      _database.execute('PRAGMA user_version = 13');
    }
    if (current < 14) {
      _database.execute(
          "ALTER TABLE shopping_items ADD COLUMN description TEXT NOT NULL DEFAULT ''");
      _database.execute('PRAGMA user_version = 14');
    }
    if (current < 15) {
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
    if (current < 16) {
      _database.execute('ALTER TABLE subscriptions ADD COLUMN icon_key TEXT');
      _database.execute('PRAGMA user_version = 16');
    }
    if (current < 17) {
      transaction(() {
        _database.execute(
            'ALTER TABLE transactions ADD COLUMN card_invoice_id TEXT');
        _database.execute('''
          CREATE TABLE credit_cards_new (
            id TEXT PRIMARY KEY NOT NULL, name TEXT NOT NULL, brand TEXT NOT NULL,
            last_four TEXT NOT NULL CHECK(length(last_four) = 4),
            limit_cents INTEGER NOT NULL CHECK(limit_cents > 0),
            closing_day INTEGER NOT NULL CHECK(closing_day BETWEEN 1 AND 31),
            due_day INTEGER NOT NULL CHECK(due_day BETWEEN 1 AND 31),
            color_value INTEGER NOT NULL, created_at TEXT NOT NULL
          );
          INSERT INTO credit_cards_new SELECT * FROM credit_cards;
          CREATE TABLE card_purchases_new (
            id TEXT PRIMARY KEY NOT NULL,
            card_id TEXT NOT NULL REFERENCES credit_cards_new(id) ON DELETE RESTRICT,
            description TEXT NOT NULL,
            amount_cents INTEGER NOT NULL CHECK(amount_cents > 0),
            purchased_on TEXT NOT NULL,
            installments INTEGER NOT NULL DEFAULT 1 CHECK(installments BETWEEN 1 AND 48),
            created_at TEXT NOT NULL,
            category TEXT NOT NULL DEFAULT 'Outros',
            subcategory TEXT NOT NULL DEFAULT 'Geral'
          );
          INSERT INTO card_purchases_new(
            id, card_id, description, amount_cents, purchased_on, installments, created_at
          ) SELECT id, card_id, description, amount_cents, purchased_on, installments, created_at
            FROM card_purchases;
          DROP TABLE card_purchases;
          DROP TABLE credit_cards;
          ALTER TABLE credit_cards_new RENAME TO credit_cards;
          ALTER TABLE card_purchases_new RENAME TO card_purchases;
          CREATE INDEX idx_card_purchases_card_date
            ON card_purchases(card_id, purchased_on DESC);
          CREATE TABLE card_invoices (
            id TEXT PRIMARY KEY NOT NULL,
            card_id TEXT NOT NULL REFERENCES credit_cards(id) ON DELETE RESTRICT,
            cycle_start TEXT NOT NULL,
            closing_date TEXT NOT NULL,
            due_date TEXT NOT NULL,
            status TEXT NOT NULL CHECK(status IN ('open', 'closed', 'paid')),
            created_at TEXT NOT NULL,
            UNIQUE(card_id, closing_date)
          );
          CREATE INDEX idx_card_invoices_due ON card_invoices(status, due_date);
          CREATE TABLE card_invoice_items (
            id TEXT PRIMARY KEY NOT NULL,
            invoice_id TEXT NOT NULL REFERENCES card_invoices(id) ON DELETE CASCADE,
            purchase_id TEXT NOT NULL REFERENCES card_purchases(id) ON DELETE RESTRICT,
            installment_number INTEGER NOT NULL CHECK(installment_number > 0),
            amount_cents INTEGER NOT NULL CHECK(amount_cents > 0),
            UNIQUE(purchase_id, installment_number)
          );
          CREATE TABLE card_invoice_payments (
            id TEXT PRIMARY KEY NOT NULL,
            invoice_id TEXT NOT NULL UNIQUE REFERENCES card_invoices(id) ON DELETE RESTRICT,
            transaction_id TEXT NOT NULL UNIQUE REFERENCES transactions(id) ON DELETE RESTRICT,
            paid_on TEXT NOT NULL,
            amount_cents INTEGER NOT NULL CHECK(amount_cents > 0)
          );
        ''');
        _database.execute('PRAGMA user_version = 17');
      });
    }
    if (current < 18) {
      transaction(() {
        for (final (table, column) in const <(String, String)>[
          ('transactions', 'occurred_on'),
          ('tasks', 'due_on'),
          ('financial_goals', 'deadline'),
          ('investments', 'maturity_date'),
          ('salary_schedules', 'first_due_on'),
          ('card_purchases', 'purchased_on'),
          ('card_invoices', 'cycle_start'),
          ('card_invoices', 'closing_date'),
          ('card_invoices', 'due_date'),
          ('card_invoice_payments', 'paid_on'),
        ]) {
          if (!_tableColumns(table).contains(column)) continue;
          _database.execute('''
            UPDATE "$table" SET "$column" = substr("$column", 1, 10)
            WHERE "$column" IS NOT NULL AND length("$column") > 10
          ''');
        }
        _database.execute('PRAGMA user_version = 18');
      });
    }
    if (current < 19) {
      transaction(() {
        _database.execute('''
          CREATE TABLE salary_schedule_exceptions (
            id TEXT PRIMARY KEY NOT NULL,
            schedule_id TEXT NOT NULL REFERENCES salary_schedules(id) ON DELETE CASCADE,
            occurred_on TEXT NOT NULL,
            created_at TEXT NOT NULL,
            UNIQUE(schedule_id, occurred_on)
          );
        ''');
        _database.execute('PRAGMA user_version = 19');
      });
    }
    if (current < 20) {
      transaction(() {
        if (!_tableColumns('finance_categories').contains('essentiality')) {
          _database.execute('''ALTER TABLE finance_categories
            ADD COLUMN essentiality TEXT NOT NULL DEFAULT 'unclassified'
            CHECK(essentiality IN ('essential', 'nonEssential', 'unclassified'))''');
        }
        if (!_tableColumns('transactions').contains('income_source')) {
          _database.execute(
              'ALTER TABLE transactions ADD COLUMN income_source TEXT');
        }
        if (!_tableColumns('transactions').contains('essentiality_override')) {
          _database.execute('''ALTER TABLE transactions
            ADD COLUMN essentiality_override TEXT
            CHECK(essentiality_override IN ('essential', 'nonEssential', 'unclassified'))''');
        }
        _database.execute('PRAGMA user_version = 20');
      });
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
    final createdAt = DateTime.utc(2026).toIso8601String();
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
      .select('SELECT * FROM accounts ORDER BY created_at ASC')
      .map((row) => Account(
            id: row['id'] as String,
            name: row['name'] as String,
            openingBalanceInCents: row['opening_balance_cents'] as int,
            createdAt: DateTime.parse(row['created_at'] as String).toUtc(),
            institution:
                AccountInstitution.values.byName(row['institution'] as String),
            customInstitutionName: row['custom_institution_name'] as String?,
            customIconKey: row['custom_icon_key'] as String?,
          ))
      .toList();

  List<TransactionRecord> loadTransactions() => _database
      .select(
          'SELECT * FROM transactions ORDER BY occurred_on DESC, created_at DESC')
      .map((row) => TransactionRecord(
            id: row['id'] as String,
            accountId: row['account_id'] as String,
            destinationAccountId: row['destination_account_id'] as String?,
            type: TransactionType.values.byName(row['type'] as String),
            amountInCents: row['amount_cents'] as int,
            description: row['description'] as String,
            category: row['category'] as String? ?? 'Outros',
            subcategory: row['subcategory'] as String? ?? 'Geral',
            scheduleType: TransactionScheduleType.values
                .byName(row['schedule_type'] as String),
            seriesId: row['series_id'] as String?,
            installmentNumber: row['installment_number'] as int,
            installmentCount: row['installment_count'] as int,
            isSettled: (row['is_settled'] as int) == 1,
            cardInvoiceId: row['card_invoice_id'] as String?,
            incomeSource: row['income_source'] as String?,
            essentialityOverride: row['essentiality_override'] == null
                ? null
                : ExpenseEssentiality.values.byName(
                    row['essentiality_override'] as String),
            occurredOn: BusinessDate.parse(row['occurred_on'] as String),
            createdAt: DateTime.parse(row['created_at'] as String).toUtc(),
          ))
      .toList();

  List<TaskItem> loadTasks() => _database
      .select(
          'SELECT * FROM tasks ORDER BY is_done ASC, due_on ASC, created_at DESC')
      .map((row) => TaskItem(
            id: row['id'] as String,
            title: row['title'] as String,
            dueOn: row['due_on'] == null
                ? null
                : BusinessDate.parse(row['due_on'] as String),
            isDone: (row['is_done'] as int) == 1,
            createdAt: DateTime.parse(row['created_at'] as String).toUtc(),
          ))
      .toList();

  List<ShoppingItem> loadShoppingItems() => _database
      .select(
          'SELECT * FROM shopping_items ORDER BY is_purchased ASC, created_at DESC')
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
            createdAt: DateTime.parse(row['created_at'] as String).toUtc(),
          ))
      .toList();

  List<CreditCard> loadCreditCards() => _database
      .select('SELECT * FROM credit_cards ORDER BY created_at ASC')
      .map((row) => CreditCard(
            id: row['id'] as String,
            name: row['name'] as String,
            brand: CardBrand.values.byName(row['brand'] as String),
            lastFour: row['last_four'] as String,
            limitInCents: row['limit_cents'] as int,
            closingDay: row['closing_day'] as int,
            dueDay: row['due_day'] as int,
            colorValue: row['color_value'] as int,
            createdAt: DateTime.parse(row['created_at'] as String).toUtc(),
          ))
      .toList();

  List<CardPurchase> loadCardPurchases() => _database
      .select(
          'SELECT * FROM card_purchases ORDER BY purchased_on DESC, created_at DESC')
      .map((row) => CardPurchase(
            id: row['id'] as String,
            cardId: row['card_id'] as String,
            description: row['description'] as String,
            amountInCents: row['amount_cents'] as int,
            purchasedOn: BusinessDate.parse(row['purchased_on'] as String),
            installments: row['installments'] as int,
            createdAt: DateTime.parse(row['created_at'] as String).toUtc(),
            category: row['category'] as String? ?? 'Outros',
            subcategory: row['subcategory'] as String? ?? 'Geral',
          ))
      .toList();

  List<CardInvoice> loadCardInvoices() => _database
      .select('''
    SELECT i.*, COALESCE(SUM(ii.amount_cents), 0) AS total_cents,
           p.paid_on, t.account_id AS payment_account_id
    FROM card_invoices i
    LEFT JOIN card_invoice_items ii ON ii.invoice_id = i.id
    LEFT JOIN card_invoice_payments p ON p.invoice_id = i.id
    LEFT JOIN transactions t ON t.id = p.transaction_id
    GROUP BY i.id ORDER BY i.closing_date DESC
  ''')
      .map((row) => CardInvoice(
            id: row['id'] as String,
            cardId: row['card_id'] as String,
            cycleStart: BusinessDate.parse(row['cycle_start'] as String),
            closingDate: BusinessDate.parse(row['closing_date'] as String),
            dueDate: BusinessDate.parse(row['due_date'] as String),
            status: CardInvoiceStatus.values.byName(row['status'] as String),
            totalInCents: row['total_cents'] as int,
            paidOn: row['paid_on'] == null
                ? null
                : BusinessDate.parse(row['paid_on'] as String),
            paymentAccountId: row['payment_account_id'] as String?,
          ))
      .toList();

  List<TransactionRecord> loadCardInstallmentTransactions() => _database
      .select('''
        SELECT ii.id, p.description, ii.amount_cents, p.category, p.subcategory,
               i.closing_date, i.created_at, i.id AS invoice_id
        FROM card_invoice_items ii
        JOIN card_purchases p ON p.id = ii.purchase_id
        JOIN card_invoices i ON i.id = ii.invoice_id
      ''')
      .map((row) => TransactionRecord(
            id: 'card-installment-${row['id']}',
            accountId: 'card',
            type: TransactionType.expense,
            amountInCents: row['amount_cents'] as int,
            description: row['description'] as String,
            category: row['category'] as String,
            subcategory: row['subcategory'] as String,
            occurredOn: BusinessDate.parse(row['closing_date'] as String),
            createdAt: DateTime.parse(row['created_at'] as String).toUtc(),
          ))
      .toList();

  List<InvestmentPosition> loadInvestments() => _database
      .select('SELECT * FROM investments ORDER BY created_at DESC')
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
                : BusinessDate.parse(row['maturity_date'] as String),
            quotedRateBasisPoints: row['quoted_rate_bps'] as int?,
            quotedRatePeriod: row['quoted_rate_period'] == null
                ? null
                : InvestmentRatePeriod.values
                    .byName(row['quoted_rate_period'] as String),
            yieldPaymentDay: row['yield_payment_day'] as int?,
            createdAt: DateTime.parse(row['created_at'] as String).toUtc(),
          ))
      .toList();

  List<Budget> loadBudgets() => _database
      .select(
          'SELECT * FROM budgets ORDER BY year DESC, month DESC, created_at DESC')
      .map((row) => Budget(
            id: row['id'] as String,
            category: row['category'] as String,
            limitInCents: row['limit_cents'] as int,
            year: row['year'] as int,
            month: row['month'] as int,
            createdAt: DateTime.parse(row['created_at'] as String).toUtc(),
          ))
      .toList();

  List<Subscription> loadSubscriptions() => _database
      .select(
          'SELECT * FROM subscriptions ORDER BY is_active DESC, billing_day ASC, created_at DESC')
      .map((row) => Subscription(
            id: row['id'] as String,
            name: row['name'] as String,
            amountInCents: row['amount_cents'] as int,
            billingDay: row['billing_day'] as int,
            category: row['category'] as String,
            isActive: (row['is_active'] as int) == 1,
            createdAt: DateTime.parse(row['created_at'] as String).toUtc(),
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
      .select(
          'SELECT * FROM financial_goals ORDER BY deadline IS NULL, deadline ASC, created_at DESC')
      .map((row) => FinancialGoal(
            id: row['id'] as String,
            name: row['name'] as String,
            targetInCents: row['target_cents'] as int,
            savedInCents: row['saved_cents'] as int,
            deadline: row['deadline'] == null
                ? null
                : BusinessDate.parse(row['deadline'] as String),
            iconKey: row['icon_key'] as String,
            category: row['category'] as String,
            createdAt: DateTime.parse(row['created_at'] as String).toUtc(),
          ))
      .toList();

  List<String> loadGoalCategories() => _database
      .select('SELECT name FROM goal_categories ORDER BY name COLLATE NOCASE')
      .map((row) => row['name'] as String)
      .toList();

  List<AppRoute> loadMobileQuickPages() {
    final rows = _database.select(
        "SELECT value FROM app_settings WHERE key = 'mobile_quick_pages'");
    const fallback = <AppRoute>[
      AppRoute.overview,
      AppRoute.finances,
      AppRoute.organization,
      AppRoute.reports,
    ];
    if (rows.isEmpty) return fallback;
    final tokens = (rows.first['value'] as String).split(',');
    final normalized = <AppRoute>[];
    for (final token in tokens) {
      final route = AppRoute.fromId(token) ??
          (int.tryParse(token) == null
              ? null
              : AppRoute.fromLegacyIndex(int.parse(token)));
      if (route == null || !route.quick || normalized.contains(route)) continue;
      normalized.add(route);
    }
    if (normalized.length > 4) normalized.removeRange(4, normalized.length);
    for (final route in fallback) {
      if (normalized.length == 4) break;
      if (!normalized.contains(route)) normalized.add(route);
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

  void saveMobileQuickPages(List<AppRoute> pages) => _database.execute(
      "INSERT OR REPLACE INTO app_settings(key, value) VALUES ('mobile_quick_pages', ?)",
      [pages.map((route) => route.id).join(',')]);

  List<SalarySchedule> loadSalarySchedules() => _database
      .select('SELECT * FROM salary_schedules ORDER BY created_at')
      .map((row) => SalarySchedule(
            id: row['id'] as String,
            accountId: row['account_id'] as String,
            amountInCents: row['amount_cents'] as int,
            description: row['description'] as String,
            subcategory: row['subcategory'] as String,
            firstDueOn: BusinessDate.parse(row['first_due_on'] as String),
            paymentDay: row['payment_day'] as int,
            createdAt: DateTime.parse(row['created_at'] as String).toUtc(),
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
        BusinessDate.serialize(item.firstDueOn),
        item.paymentDay,
        item.createdAt.toUtc().toIso8601String()
      ]);

  void deleteSalarySchedule(String id) =>
      _database.execute('DELETE FROM salary_schedules WHERE id = ?', [id]);

  void updateSalarySchedule(SalarySchedule item) => _database.execute('''
    UPDATE salary_schedules SET account_id = ?, amount_cents = ?, description = ?,
      subcategory = ?, first_due_on = ?, payment_day = ? WHERE id = ?
  ''', [
        item.accountId,
        item.amountInCents,
        item.description,
        item.subcategory,
        BusinessDate.serialize(item.firstDueOn),
        item.paymentDay,
        item.id,
      ]);

  bool isSalaryOccurrenceSkipped(String scheduleId, DateTime date) =>
      _database.select('''SELECT 1 FROM salary_schedule_exceptions
        WHERE schedule_id = ? AND occurred_on = ? LIMIT 1''',
          [scheduleId, BusinessDate.serialize(date)]).isNotEmpty;

  void skipSalaryOccurrence(
          String id, String scheduleId, DateTime date, DateTime createdAt) =>
      _database.execute('''INSERT OR IGNORE INTO salary_schedule_exceptions(
        id, schedule_id, occurred_on, created_at
      ) VALUES (?, ?, ?, ?)''', [
        id,
        scheduleId,
        BusinessDate.serialize(date),
        createdAt.toUtc().toIso8601String(),
      ]);

  void unskipSalaryOccurrence(String scheduleId, DateTime date) =>
      _database.execute('''DELETE FROM salary_schedule_exceptions
        WHERE schedule_id = ? AND occurred_on = ?''',
          [scheduleId, BusinessDate.serialize(date)]);

  void insertGoalCategory(String name) =>
      _database.execute('INSERT INTO goal_categories(name) VALUES (?)', [name]);

  List<FinanceCategory> loadFinanceCategories() => _database
      .select('SELECT * FROM finance_categories ORDER BY is_system DESC, name')
      .map((row) => FinanceCategory(
            id: row['id'] as String,
            name: row['name'] as String,
            type: TransactionType.values.byName(row['type'] as String),
            isSystem: (row['is_system'] as int) == 1,
            essentiality: ExpenseEssentiality.values
                .byName(row['essentiality'] as String),
            createdAt: DateTime.parse(row['created_at'] as String).toUtc(),
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
            createdAt: DateTime.parse(row['created_at'] as String).toUtc(),
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
          account.createdAt.toUtc().toIso8601String(),
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

  void insertTransaction(TransactionRecord item) => _database.execute(
        '''INSERT INTO transactions(
          id, account_id, destination_account_id, type, amount_cents,
          description, category, subcategory, occurred_on, created_at,
          schedule_type, series_id, installment_number, installment_count, is_settled,
          card_invoice_id, income_source, essentiality_override
        ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)''',
        [
          item.id,
          item.accountId,
          item.destinationAccountId,
          item.type.name,
          item.amountInCents,
          item.description,
          item.category,
          item.subcategory,
          BusinessDate.serialize(item.occurredOn),
          item.createdAt.toUtc().toIso8601String(),
          item.scheduleType.name,
          item.seriesId,
          item.installmentNumber,
          item.installmentCount,
          item.isSettled ? 1 : 0,
          item.cardInvoiceId,
          item.incomeSource,
          item.essentialityOverride?.name,
        ],
      );

  void insertTask(TaskItem item) => _database.execute(
        'INSERT INTO tasks(id, title, due_on, is_done, created_at) VALUES (?, ?, ?, ?, ?)',
        [
          item.id,
          item.title,
          item.dueOn == null ? null : BusinessDate.serialize(item.dueOn!),
          item.isDone ? 1 : 0,
          item.createdAt.toUtc().toIso8601String()
        ],
      );

  void setTaskDone(String id, bool value) => _database.execute(
        'UPDATE tasks SET is_done = ? WHERE id = ?',
        [value ? 1 : 0, id],
      );

  void deleteTask(String id) =>
      _database.execute('DELETE FROM tasks WHERE id = ?', [id]);

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
          item.createdAt.toUtc().toIso8601String(),
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

  void deleteShoppingItem(String id) =>
      _database.execute('DELETE FROM shopping_items WHERE id = ?', [id]);

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
          card.createdAt.toUtc().toIso8601String(),
        ],
      );

  void updateCreditCard(CreditCard card) => _database.execute('''
    UPDATE credit_cards SET name = ?, brand = ?, last_four = ?, limit_cents = ?,
      closing_day = ?, due_day = ?, color_value = ? WHERE id = ?
  ''', [
        card.name,
        card.brand.name,
        card.lastFour,
        card.limitInCents,
        card.closingDay,
        card.dueDay,
        card.colorValue,
        card.id
      ]);

  void deleteCreditCard(String id) {
    final hasPurchases = _database
        .select('SELECT 1 FROM card_purchases WHERE card_id = ? LIMIT 1', [id]);
    final hasInvoices = _database
        .select('SELECT 1 FROM card_invoices WHERE card_id = ? LIMIT 1', [id]);
    if (hasPurchases.isNotEmpty || hasInvoices.isNotEmpty) {
      throw StateError(
          'Não é possível excluir um cartão com compras ou faturas.');
    }
    _database.execute('DELETE FROM credit_cards WHERE id = ?', [id]);
  }

  void insertCardPurchase(CardPurchase purchase) => _database.execute(
        '''INSERT INTO card_purchases(
          id, card_id, description, amount_cents, purchased_on, installments, created_at,
          category, subcategory
        ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)''',
        [
          purchase.id,
          purchase.cardId,
          purchase.description,
          purchase.amountInCents,
          BusinessDate.serialize(purchase.purchasedOn),
          purchase.installments,
          purchase.createdAt.toUtc().toIso8601String(),
          purchase.category,
          purchase.subcategory,
        ],
      );

  void updateCardPurchase(CardPurchase purchase) => _database.execute('''
    UPDATE card_purchases SET card_id = ?, description = ?, amount_cents = ?,
      purchased_on = ?, installments = ?, category = ?, subcategory = ? WHERE id = ?
  ''', [
        purchase.cardId,
        purchase.description,
        purchase.amountInCents,
        BusinessDate.serialize(purchase.purchasedOn),
        purchase.installments,
        purchase.category,
        purchase.subcategory,
        purchase.id
      ]);

  void deleteCardPurchase(String id) =>
      _database.execute('DELETE FROM card_purchases WHERE id = ?', [id]);

  void clearUnpaidInvoiceItems() => _database.execute('''
    DELETE FROM card_invoice_items WHERE invoice_id IN (
      SELECT id FROM card_invoices WHERE status != 'paid'
    )
  ''');

  void deleteEmptyUnpaidInvoices() => _database.execute('''
    DELETE FROM card_invoices WHERE status != 'paid'
      AND id NOT IN (SELECT invoice_id FROM card_invoice_items)
  ''');

  void closeExpiredCardInvoices(DateTime today) => _database.execute('''
    UPDATE card_invoices SET status = 'closed'
    WHERE status = 'open' AND closing_date < ?
  ''', [_dateOnly(today)]);

  String ensureCardInvoice({
    required String id,
    required String cardId,
    required DateTime cycleStart,
    required DateTime closingDate,
    required DateTime dueDate,
    required CardInvoiceStatus status,
    required DateTime createdAt,
  }) {
    final date = _dateOnly(closingDate);
    final existing = _database.select(
        'SELECT id FROM card_invoices WHERE card_id = ? AND closing_date = ?',
        [cardId, date]);
    if (existing.isNotEmpty) {
      final existingId = existing.first['id'] as String;
      _database.execute(
          '''UPDATE card_invoices SET cycle_start = ?, due_date = ?,
        status = CASE WHEN status = 'paid' THEN 'paid' ELSE ? END WHERE id = ?''',
          [_dateOnly(cycleStart), _dateOnly(dueDate), status.name, existingId]);
      return existingId;
    }
    _database.execute('''INSERT INTO card_invoices(
      id, card_id, cycle_start, closing_date, due_date, status, created_at
    ) VALUES (?, ?, ?, ?, ?, ?, ?)''', [
      id,
      cardId,
      _dateOnly(cycleStart),
      date,
      _dateOnly(dueDate),
      status.name,
      createdAt.toUtc().toIso8601String()
    ]);
    return id;
  }

  void insertCardInvoiceItem({
    required String id,
    required String invoiceId,
    required String purchaseId,
    required int installmentNumber,
    required int amountInCents,
  }) =>
      _database.execute('''INSERT INTO card_invoice_items(
    id, invoice_id, purchase_id, installment_number, amount_cents
  ) VALUES (?, ?, ?, ?, ?)''',
          [id, invoiceId, purchaseId, installmentNumber, amountInCents]);

  bool hasCardInvoiceItem(String purchaseId, int installmentNumber) =>
      _database.select('''SELECT 1 FROM card_invoice_items
        WHERE purchase_id = ? AND installment_number = ? LIMIT 1''',
          [purchaseId, installmentNumber]).isNotEmpty;

  void markCardInvoicePaid({
    required String id,
    required String invoiceId,
    required String transactionId,
    required DateTime paidOn,
    required int amountInCents,
  }) {
    _database.execute('''INSERT INTO card_invoice_payments(
      id, invoice_id, transaction_id, paid_on, amount_cents
    ) VALUES (?, ?, ?, ?, ?)''',
        [id, invoiceId, transactionId, _dateOnly(paidOn), amountInCents]);
    _database.execute(
        "UPDATE card_invoices SET status = 'paid' WHERE id = ?", [invoiceId]);
  }

  String? cardInvoicePaymentTransaction(String invoiceId) {
    final rows = _database.select(
        'SELECT transaction_id FROM card_invoice_payments WHERE invoice_id = ?',
        [invoiceId]);
    return rows.isEmpty ? null : rows.first['transaction_id'] as String;
  }

  void reverseCardInvoicePayment(String invoiceId) {
    final transactionId = cardInvoicePaymentTransaction(invoiceId);
    if (transactionId == null) throw StateError('Pagamento não encontrado.');
    _database.execute(
        'DELETE FROM card_invoice_payments WHERE invoice_id = ?', [invoiceId]);
    _database.execute('DELETE FROM transactions WHERE id = ?', [transactionId]);
    _database.execute(
        "UPDATE card_invoices SET status = 'closed' WHERE id = ?", [invoiceId]);
  }

  void assertCardPurchaseHasNoPaidInvoice(String id) {
    final rows = _database.select('''SELECT 1 FROM card_invoice_items ii
      JOIN card_invoices i ON i.id = ii.invoice_id
      WHERE ii.purchase_id = ? AND i.status = 'paid' LIMIT 1''', [id]);
    if (rows.isNotEmpty) {
      throw StateError(
          'Estorne o pagamento da fatura antes de alterar esta compra.');
    }
  }

  static String _dateOnly(DateTime date) => BusinessDate.serialize(date);

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
          investment.createdAt.toUtc().toIso8601String(),
          investment.fixedIncomeType?.name,
          investment.institutionName,
          investment.maturityDate == null
              ? null
              : BusinessDate.serialize(investment.maturityDate!),
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
          investment.maturityDate == null
              ? null
              : BusinessDate.serialize(investment.maturityDate!),
          investment.quotedRateBasisPoints,
          investment.quotedRatePeriod?.name,
          investment.yieldPaymentDay,
          investment.id,
        ],
      );

  void insertFinanceCategory(FinanceCategory category) => _database.execute(
        '''INSERT INTO finance_categories(id, name, type, is_system, created_at, essentiality)
        VALUES (?, ?, ?, ?, ?, ?)''',
        [
          category.id,
          category.name,
          category.type.name,
          category.isSystem ? 1 : 0,
          category.createdAt.toUtc().toIso8601String(),
          category.essentiality.name,
        ],
      );

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
          subcategory.createdAt.toUtc().toIso8601String(),
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

  void updateTransactionRecord(TransactionRecord item) => _database.execute('''
    UPDATE transactions SET account_id = ?, destination_account_id = ?,
      amount_cents = ?, description = ?, category = ?, subcategory = ?,
      occurred_on = ?, is_settled = ?, income_source = ?,
      essentiality_override = ? WHERE id = ?
  ''', [
        item.accountId,
        item.destinationAccountId,
        item.amountInCents,
        item.description,
        item.category,
        item.subcategory,
        BusinessDate.serialize(item.occurredOn),
        item.isSettled ? 1 : 0,
        item.incomeSource,
        item.essentialityOverride?.name,
        item.id,
      ]);

  void setFinanceCategoryEssentiality(
      String id, ExpenseEssentiality value) =>
      _database.execute('UPDATE finance_categories SET essentiality = ? WHERE id = ?',
          [value.name, id]);

  void deleteTransactionRows(Iterable<String> ids) {
    for (final id in ids) {
      _database.execute('DELETE FROM transactions WHERE id = ?', [id]);
    }
  }

  void insertBudget(Budget budget) => _database.execute(
        '''INSERT INTO budgets(id, category, limit_cents, year, month, created_at)
        VALUES (?, ?, ?, ?, ?, ?)''',
        [
          budget.id,
          budget.category,
          budget.limitInCents,
          budget.year,
          budget.month,
          budget.createdAt.toUtc().toIso8601String(),
        ],
      );

  void insertSubscription(Subscription subscription) => _database.execute(
        '''INSERT INTO subscriptions(id, name, amount_cents, billing_day, category, is_active, created_at)
        VALUES (?, ?, ?, ?, ?, ?, ?)''',
        [
          subscription.id,
          subscription.name,
          subscription.amountInCents,
          subscription.billingDay,
          subscription.category,
          subscription.isActive ? 1 : 0,
          subscription.createdAt.toUtc().toIso8601String(),
        ],
      );

  void updateSubscription(Subscription item) => _database.execute(
          '''UPDATE subscriptions SET name = ?, amount_cents = ?, billing_day = ?,
      category = ?, is_active = ? WHERE id = ?''',
          [
            item.name,
            item.amountInCents,
            item.billingDay,
            item.category,
            item.isActive ? 1 : 0,
            item.id
          ]);

  void setSubscriptionActive(String id, bool active) => _database.execute(
      'UPDATE subscriptions SET is_active = ? WHERE id = ?',
      [active ? 1 : 0, id]);

  void insertFinancialGoal(FinancialGoal goal) => _database.execute(
        '''INSERT INTO financial_goals(
          id, name, target_cents, saved_cents, deadline, icon_key, created_at, category
        ) VALUES (?, ?, ?, ?, ?, ?, ?, ?)''',
        [
          goal.id,
          goal.name,
          goal.targetInCents,
          goal.savedInCents,
          goal.deadline == null ? null : BusinessDate.serialize(goal.deadline!),
          goal.iconKey,
          goal.createdAt.toUtc().toIso8601String(),
          goal.category,
        ],
      );

  void updateFinancialGoalSaved(String id, int savedInCents) =>
      _database.execute(
        'UPDATE financial_goals SET saved_cents = ? WHERE id = ?',
        [savedInCents, id],
      );

  void deleteAccount(String id) =>
      _database.execute('DELETE FROM accounts WHERE id = ?', [id]);

  void deleteTransaction(String id) =>
      _database.execute('DELETE FROM transactions WHERE id = ?', [id]);
  void deleteBudget(String id) =>
      _database.execute('DELETE FROM budgets WHERE id = ?', [id]);
  void deleteSubscription(String id) =>
      _database.execute('DELETE FROM subscriptions WHERE id = ?', [id]);
  void deleteFinancialGoal(String id) =>
      _database.execute('DELETE FROM financial_goals WHERE id = ?', [id]);
  void deleteInvestment(String id) =>
      _database.execute('DELETE FROM investments WHERE id = ?', [id]);

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
    _database.execute('BEGIN IMMEDIATE');
    try {
      operation();
      _database.execute('COMMIT');
    } catch (_) {
      _database.execute('ROLLBACK');
      rethrow;
    }
  }

  void close() => _database.close();
}
