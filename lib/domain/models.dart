enum TransactionType { income, expense, transfer }

enum TransactionSystemType { cardPayment }

/// Tables eligible for logical deletion. Values are kept explicit so callers
/// can never pass arbitrary SQL identifiers to the persistence layer.
enum SoftDeleteEntity {
  transaction('transactions'),
  account('accounts'),
  creditCard('credit_cards'),
  cardPurchase('card_purchases'),
  investment('investments'),
  budget('budgets'),
  subscription('subscriptions'),
  financialGoal('financial_goals'),
  shoppingItem('shopping_items'),
  task('tasks');

  const SoftDeleteEntity(this.tableName);
  final String tableName;
}

enum CardInvoiceStatus { open, closed, partiallyPaid, paid }

enum AccountInstitution {
  generic,
  nubank,
  inter,
  caixa,
  itau,
  bradesco,
  santander,
  bancoDoBrasil,
  bancoPan,
  picpay,
  mercadoPago,
  neon,
  original,
  safra,
  sicredi,
  sicoob,
  bv,
  xp,
  custom,
}

class Account {
  const Account({
    required this.id,
    required this.name,
    required this.openingBalanceInCents,
    required this.createdAt,
    this.institution = AccountInstitution.generic,
    this.customInstitutionName,
    this.customIconKey,
  });

  final String id;
  final String name;
  final int openingBalanceInCents;
  final DateTime createdAt;
  final AccountInstitution institution;
  final String? customInstitutionName;
  final String? customIconKey;
}

class TransactionRecord {
  const TransactionRecord({
    required this.id,
    required this.accountId,
    required this.type,
    required this.amountInCents,
    required this.description,
    required this.occurredOn,
    required this.createdAt,
    this.destinationAccountId,
    this.category = 'Outros',
    this.subcategory = 'Geral',
    this.categoryId,
    this.subcategoryId,
    this.scheduleType = TransactionScheduleType.single,
    this.seriesId,
    this.installmentNumber = 1,
    this.installmentCount = 1,
    this.isSettled = true,
    this.systemType,
  });

  final String id;
  final String accountId;
  final String? destinationAccountId;
  final TransactionType type;
  final int amountInCents;
  final String description;
  final DateTime occurredOn;
  final DateTime createdAt;
  final String category;
  final String subcategory;
  final String? categoryId;
  final String? subcategoryId;
  final TransactionScheduleType scheduleType;
  final String? seriesId;
  final int installmentNumber;
  final int installmentCount;
  final bool isSettled;
  final TransactionSystemType? systemType;
}

enum TransactionScheduleType { single, recurring, installment }

class TaskItem {
  const TaskItem({
    required this.id,
    required this.title,
    required this.createdAt,
    this.dueOn,
    this.isDone = false,
  });

  final String id;
  final String title;
  final DateTime? dueOn;
  final bool isDone;
  final DateTime createdAt;
}

enum ShoppingPriority { low, normal, high }

class ShoppingItem {
  const ShoppingItem({
    required this.id,
    required this.name,
    required this.quantity,
    required this.createdAt,
    this.estimatedUnitPriceInCents,
    this.priority = ShoppingPriority.normal,
    this.isPurchased = false,
    this.imagePath,
    this.description = '',
  });

  final String id;
  final String name;
  final int quantity;
  final int? estimatedUnitPriceInCents;
  final ShoppingPriority priority;
  final bool isPurchased;
  final String? imagePath;
  final String description;
  final DateTime createdAt;

  int get estimatedTotalInCents => quantity * (estimatedUnitPriceInCents ?? 0);
}

enum CardBrand { visa, mastercard, elo, amex, other }

class CreditCard {
  const CreditCard({
    required this.id,
    required this.name,
    required this.brand,
    required this.lastFour,
    required this.limitInCents,
    required this.closingDay,
    required this.dueDay,
    required this.colorValue,
    required this.createdAt,
  });

  final String id;
  final String name;
  final CardBrand brand;
  final String lastFour;
  final int limitInCents;
  final int closingDay;
  final int dueDay;
  final int colorValue;
  final DateTime createdAt;
}

class CardPurchase {
  const CardPurchase({
    required this.id,
    required this.cardId,
    required this.description,
    required this.amountInCents,
    required this.purchasedOn,
    required this.installments,
    required this.createdAt,
    this.paidInstallments = const {},
    this.category = 'Outros',
    this.subcategory = 'Geral',
    this.categoryId,
    this.subcategoryId,
  });

  final String id;
  final String cardId;
  final String description;
  final int amountInCents;
  final DateTime purchasedOn;
  final int installments;
  final DateTime createdAt;
  final Set<int> paidInstallments;
  final String category;
  final String subcategory;
  final String? categoryId;
  final String? subcategoryId;

  int get paidInstallmentCount => paidInstallments.length;
  int get remainingInstallmentCount => installments - paidInstallments.length;
  double get installmentPaymentProgress =>
      installments == 0 ? 0 : paidInstallments.length / installments;
}

class CardInvoice {
  const CardInvoice({
    required this.id,
    required this.cardId,
    required this.referenceYear,
    required this.referenceMonth,
    required this.closingOn,
    required this.dueOn,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String cardId;
  final int referenceYear;
  final int referenceMonth;
  final DateTime closingOn;
  final DateTime dueOn;
  final CardInvoiceStatus status;
  final DateTime createdAt;
  final DateTime updatedAt;
}

class CardInvoicePayment {
  const CardInvoicePayment({
    required this.id,
    required this.invoiceId,
    required this.accountId,
    required this.transactionId,
    required this.amountInCents,
    required this.paidOn,
    required this.createdAt,
  });

  final String id;
  final String invoiceId;
  final String accountId;
  final String? transactionId;
  final int amountInCents;
  final DateTime paidOn;
  final DateTime createdAt;
}

enum InvestmentType { fixedIncome, stock, fund, etf, crypto, other }

enum InvestmentRatePeriod { monthly, annual }

enum FixedIncomeType {
  cdb,
  lci,
  lca,
  treasurySelic,
  treasuryIpca,
  treasuryFixed,
  debenture,
  cri,
  cra,
  savings,
  other,
}

class InvestmentPosition {
  const InvestmentPosition({
    required this.id,
    required this.name,
    required this.type,
    required this.investedAmountInCents,
    required this.currentValueInCents,
    required this.createdAt,
    this.fixedIncomeType,
    this.institutionName,
    this.maturityDate,
    this.quotedRateBasisPoints,
    this.quotedRatePeriod,
    this.yieldPaymentDay,
  });

  final String id;
  final String name;
  final InvestmentType type;
  final int investedAmountInCents;
  final int currentValueInCents;
  final DateTime createdAt;
  final FixedIncomeType? fixedIncomeType;
  final String? institutionName;
  final DateTime? maturityDate;

  /// Taxa informada pelo usuário, em centésimos de ponto percentual.
  /// Não é o retorno realizado nem uma cotação automática.
  final int? quotedRateBasisPoints;
  final InvestmentRatePeriod? quotedRatePeriod;

  /// Dia mensal informado para crédito de rendimento; não altera o saldo.
  final int? yieldPaymentDay;
}

class SalarySchedule {
  const SalarySchedule(
      {required this.id,
      required this.accountId,
      required this.amountInCents,
      required this.description,
      required this.subcategory,
      required this.firstDueOn,
      required this.paymentDay,
      required this.createdAt});
  final String id;
  final String accountId;
  final int amountInCents;
  final String description;
  final String subcategory;
  final DateTime firstDueOn;
  final int paymentDay;
  final DateTime createdAt;
}

class FinanceCategory {
  const FinanceCategory({
    required this.id,
    required this.name,
    required this.type,
    required this.createdAt,
    this.isSystem = false,
  });

  final String id;
  final String name;
  final TransactionType type;
  final DateTime createdAt;
  final bool isSystem;
}

class FinanceSubcategory {
  const FinanceSubcategory({
    required this.id,
    required this.categoryId,
    required this.name,
    required this.createdAt,
    this.isSystem = false,
  });

  final String id;
  final String categoryId;
  final String name;
  final DateTime createdAt;
  final bool isSystem;
}

class Budget {
  const Budget({
    required this.id,
    required this.category,
    required this.limitInCents,
    required this.year,
    required this.month,
    required this.createdAt,
    this.categoryId,
  });

  final String id;
  final String category;
  final String? categoryId;
  final int limitInCents;
  final int year;
  final int month;
  final DateTime createdAt;
}

class Subscription {
  const Subscription({
    required this.id,
    required this.name,
    required this.amountInCents,
    required this.billingDay,
    required this.category,
    required this.createdAt,
    this.isActive = true,
    this.categoryId,
  });

  final String id;
  final String name;
  final int amountInCents;
  final int billingDay;
  final String category;
  final String? categoryId;
  final DateTime createdAt;
  final bool isActive;
}

class SalaryAllocation {
  const SalaryAllocation({
    required this.essentialsPercent,
    required this.goalsPercent,
    required this.freePercent,
  });

  final int essentialsPercent;
  final int goalsPercent;
  final int freePercent;

  static const defaults = SalaryAllocation(
    essentialsPercent: 50,
    goalsPercent: 30,
    freePercent: 20,
  );
}

/// A user-defined share of the configured monthly income.
///
/// [linkedCategories] connects real expenses to the same monthly limit, so
/// salary distribution and budget monitoring share one source of truth.
class SalaryAllocationBucket {
  const SalaryAllocationBucket({
    required this.id,
    required this.name,
    required this.percent,
    required this.iconKey,
    required this.colorValue,
    required this.sortOrder,
    required this.linkedCategories,
    this.isSystem = false,
  });

  final String id;
  final String name;
  final int percent;
  final String iconKey;
  final int colorValue;
  final int sortOrder;
  final List<String> linkedCategories;
  final bool isSystem;

  SalaryAllocationBucket copyWith({
    String? name,
    int? percent,
    String? iconKey,
    int? colorValue,
    int? sortOrder,
    List<String>? linkedCategories,
  }) =>
      SalaryAllocationBucket(
        id: id,
        name: name ?? this.name,
        percent: percent ?? this.percent,
        iconKey: iconKey ?? this.iconKey,
        colorValue: colorValue ?? this.colorValue,
        sortOrder: sortOrder ?? this.sortOrder,
        linkedCategories: linkedCategories ?? this.linkedCategories,
        isSystem: isSystem,
      );
}

class FinancialGoal {
  const FinancialGoal({
    required this.id,
    required this.name,
    required this.targetInCents,
    required this.savedInCents,
    required this.createdAt,
    this.deadline,
    this.iconKey = 'savings',
    this.category = 'Reserva',
  });

  final String id;
  final String name;
  final int targetInCents;
  final int savedInCents;
  final DateTime? deadline;
  final String iconKey;
  final String category;
  final DateTime createdAt;
}
