import 'package:flutter_test/flutter_test.dart';
import 'package:organiza/database/app_database.dart';
import 'package:organiza/domain/models.dart';

void main() {
  test('meta usa categoria própria e renomeação preserva o vínculo', () {
    final database = AppDatabase.openInMemory();
    addTearDown(database.close);
    database.insertFinancialGoal(FinancialGoal(
      id: 'goal',
      name: 'Viagem',
      targetInCents: 10000,
      savedInCents: 1000,
      iconKey: 'travel',
      category: 'Viagem',
      createdAt: DateTime(2026, 1, 1),
    ));
    final row = (database.exportSnapshot()['tables']
        as Map<String, dynamic>)['financial_goals'] as List<dynamic>;
    expect(
        (row.single as Map<String, dynamic>)['goal_category_name'], 'Viagem');
    database.renameGoalCategory('Viagem', 'Passeios');
    expect(database.loadFinancialGoals().single.category, 'Passeios');
    expect(database.loadGoalCategories(), contains('Passeios'));
    database.validateIntegrity();
  });
}
