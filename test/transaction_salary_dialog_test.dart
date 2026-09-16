import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:organiza/application/organiza_store.dart';
import 'package:organiza/domain/models.dart';
import 'package:organiza/presentation/dialogs.dart';

void main() {
  testWidgets('salário mensal não pede parcelas nem descrição', (tester) async {
    final store = OrganizaStore.inMemory();
    addTearDown(store.dispose);
    store.addAccount('Principal', 0);
    TransactionInput? result;
    await tester.pumpWidget(MaterialApp(
        home: Scaffold(
            body: Builder(
                builder: (context) => TextButton(
                    onPressed: () async {
                      result = await showDialog<TransactionInput>(
                          context: context,
                          builder: (_) => TransactionDialog(
                              accounts: store.accounts,
                              categories: store.financeCategories,
                              subcategories: store.financeSubcategories,
                              onCreateCategory: store.addFinanceCategory,
                              onCreateSubcategory:
                                  store.addFinanceSubcategory));
                    },
                    child: const Text('Abrir'))))));
    await tester.tap(find.text('Abrir'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Despesa').first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Receita').last);
    await tester.pumpAndSettle();
    await tester.tap(find.byType(DropdownButtonFormField<String>).at(1));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Salário').last);
    await tester.pumpAndSettle();
    final scheduleField =
        find.byType(DropdownButtonFormField<TransactionScheduleType>);
    await tester.ensureVisible(scheduleField);
    await tester.pumpAndSettle();
    await tester.tap(scheduleField);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Recorrente mensal').last);
    await tester.pumpAndSettle();
    expect(find.text('Número de parcelas'), findsNothing);
    expect(find.text('Quantidade de meses'), findsNothing);
    expect(find.text('Parcelado'), findsNothing);
    await tester.enterText(find.byType(TextField).last, '3000');
    await tester.tap(find.text('Salvar transação'));
    await tester.pumpAndSettle();
    expect(result, isNotNull);
    expect(result!.type, TransactionType.income);
    expect(result!.category, 'Salário');
    expect(result!.description, isEmpty);
    expect(result!.scheduleType, TransactionScheduleType.recurring);
    expect(result!.repeatCount, 1);
  });
}
