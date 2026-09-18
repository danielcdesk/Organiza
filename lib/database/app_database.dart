import 'dart:io';

import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:sqlite3/sqlite3.dart';

import '../domain/models.dart';

/// Owns schema migrations and keeps user data on the local machine only.
class AppDatabase {
  AppDatabase._(this._database);

  final Database _database;
  static const _schemaVersion = 11;

  static Future<AppDatabase> open() async {
    final appDirectory = await getApplicationSupportDirectory();
    final folder = Directory(path.join(appDirectory.path, 'Organiza'));
    if (!folder.existsSync()) folder.createSync(recursive: true);
    final database = sqlite3.open(path.join(folder.path, 'organiza.db'));
    database.execute('PRAGMA foreign_keys = ON');
    final instance = AppDatabase._(database);
    instance._migrate();
    return instance;
  }

  static AppDatabase openInMemory() {
    final database = sqlite3.openInMemory();
    database.execute('PRAGMA foreign_keys = ON');
    final instance = AppDatabase._(database);
    instance._migrate();
    return instance;
  }

  static AppDatabase openInMemoryFromVersion1ForTest() {
    final database = sqlite3.openInMemory();
    database.execute('PRAGMA foreign_keys = ON');
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

  int get schemaVersion =>
      _database.select('PRAGMA user_version').first['user_version'] as int;

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
      .select('SELECT * FROM accounts ORDER BY created_at ASC')
      .map((row) => Account(
            id: row['id'] as String,
            name: row['name'] as String,
            openingBalanceInCents: row['opening_balance_cents'] as int,
            createdAt: DateTime.parse(row['created_at'] as String),
            institution:
                AccountInstitution.values.byName(row['institution'] as String),
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
            occurredOn: DateTime.parse(row['occurred_on'] as String),
            createdAt: DateTime.parse(row['created_at'] as String),
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
                : DateTime.parse(row['due_on'] as String),
            isDone: (row['is_done'] as int) == 1,
            createdAt: DateTime.parse(row['created_at'] as String),
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
            createdAt: DateTime.parse(row['created_at'] as String),
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
            createdAt: DateTime.parse(row['created_at'] as String),
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
            purchasedOn: DateTime.parse(row['purchased_on'] as String),
            installments: row['installments'] as int,
            createdAt: DateTime.parse(row['created_at'] as String),
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
      .select(
          'SELECT * FROM budgets ORDER BY year DESC, month DESC, created_at DESC')
      .map((row) => Budget(
            id: row['id'] as String,
            category: row['category'] as String,
            limitInCents: row['limit_cents'] as int,
            year: row['year'] as int,
            month: row['month'] as int,
            createdAt: DateTime.parse(row['created_at'] as String),
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
      .select(
          'SELECT * FROM financial_goals ORDER BY deadline IS NULL, deadline ASC, created_at DESC')
      .map((row) => FinancialGoal(
            id: row['id'] as String,
            name: row['name'] as String,
            targetInCents: row['target_cents'] as int,
            savedInCents: row['saved_cents'] as int,
            deadline: row['deadline'] == null
                ? null
                : DateTime.parse(row['deadline'] as String),
            iconKey: row['icon_key'] as String,
            category: row['category'] as String,
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
        parsed.toSet().length != 4 ||
        parsed.any((value) => value! < 0 || value > 11 || value == 9)) {
      return [0, 1, 6, 8];
    }
    return parsed.cast<int>();
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

  List<FinanceCategory> loadFinanceCategories() => _database
      .select('SELECT * FROM finance_categories ORDER BY is_system DESC, name')
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
        'INSERT INTO accounts(id, name, opening_balance_cents, created_at, institution) VALUES (?, ?, ?, ?, ?)',
        [
          account.id,
          account.name,
          account.openingBalanceInCents,
          account.createdAt.toIso8601String(),
          account.institution.name,
        ],
      );

  void updateAccountOpeningBalance(String id, int cents) => _database.execute(
      'UPDATE accounts SET opening_balance_cents = ? WHERE id = ?',
      [cents, id]);

  void insertTransaction(TransactionRecord item) => _database.execute(
        '''INSERT INTO transactions(
          id, account_id, destination_account_id, type, amount_cents,
          description, category, subcategory, occurred_on, created_at,
          schedule_type, series_id, installment_number, installment_count, is_settled
        ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)''',
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
        ],
      );

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
      _database.execute('DELETE FROM tasks WHERE id = ?', [id]);

  void insertShoppingItem(ShoppingItem item) => _database.execute(
        '''INSERT INTO shopping_items(
          id, name, quantity, estimated_unit_price_cents, priority, is_purchased, created_at
        ) VALUES (?, ?, ?, ?, ?, ?, ?)''',
        [
          item.id,
          item.name,
          item.quantity,
          item.estimatedUnitPriceInCents,
          item.priority.name,
          item.isPurchased ? 1 : 0,
          item.createdAt.toIso8601String(),
        ],
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
          card.createdAt.toIso8601String(),
        ],
      );

  void insertCardPurchase(CardPurchase purchase) => _database.execute(
        '''INSERT INTO card_purchases(
          id, card_id, description, amount_cents, purchased_on, installments, created_at
        ) VALUES (?, ?, ?, ?, ?, ?, ?)''',
        [
          purchase.id,
          purchase.cardId,
          purchase.description,
          purchase.amountInCents,
          purchase.purchasedOn.toIso8601String(),
          purchase.installments,
          purchase.createdAt.toIso8601String(),
        ],
      );

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

  void insertFinanceCategory(FinanceCategory category) => _database.execute(
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

  void insertBudget(Budget budget) => _database.execute(
        '''INSERT INTO budgets(id, category, limit_cents, year, month, created_at)
        VALUES (?, ?, ?, ?, ?, ?)''',
        [
          budget.id,
          budget.category,
          budget.limitInCents,
          budget.year,
          budget.month,
          budget.createdAt.toIso8601String(),
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
          subscription.createdAt.toIso8601String(),
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
          goal.deadline?.toIso8601String(),
          goal.iconKey,
          goal.createdAt.toIso8601String(),
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

  void close() => _database.close();
}
