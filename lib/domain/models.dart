enum TransactionType { income, expense, transfer }

enum AccountInstitution {
  generic,
  nubank,
  inter,
  caixa,
  itau,
  bradesco,
  santander,
  bancoDoBrasil,
}

class Account {
  const Account({
    required this.id,
    required this.name,
    required this.openingBalanceInCents,
    required this.createdAt,
    this.institution = AccountInstitution.generic,
  });

  final String id;
  final String name;
  final int openingBalanceInCents;
  final DateTime createdAt;
  final AccountInstitution institution;
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
    this.scheduleType = TransactionScheduleType.single,
    this.seriesId,
    this.installmentNumber = 1,
    this.installmentCount = 1,
    this.isSettled = true,
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
  final TransactionScheduleType scheduleType;
  final String? seriesId;
  final int installmentNumber;
  final int installmentCount;
  final bool isSettled;
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
  });

  final String id;
  final String cardId;
  final String description;
  final int amountInCents;
  final DateTime purchasedOn;
  final int installments;
  final DateTime createdAt;
}

enum InvestmentType { fixedIncome, stock, fund, etf, crypto, other }

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
  });

  final String id;
  final String category;
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
  });

  final String id;
  final String name;
  final int amountInCents;
  final int billingDay;
  final String category;
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

class FinancialGoal {
  const FinancialGoal({
    required this.id,
    required this.name,
    required this.targetInCents,
    required this.savedInCents,
    required this.createdAt,
    this.deadline,
    this.iconKey = 'savings',
  });

  final String id;
  final String name;
  final int targetInCents;
  final int savedInCents;
  final DateTime? deadline;
  final String iconKey;
  final DateTime createdAt;
}
