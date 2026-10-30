import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:organiza/domain/models.dart';
import 'package:organiza/presentation/basic_pages.dart';

void main() {
  testWidgets('configurações renomeiam e confirmam arquivo de categoria',
      (tester) async {
    final category = FinanceCategory(
      id: 'custom',
      name: 'Padaria',
      type: TransactionType.expense,
      createdAt: DateTime(2026, 1, 1),
    );
    String? newName;
    String? archivedId;
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: SettingsPage(
          onThemeChanged: (_) {},
          onAccentChanged: (_) {},
          quickPages: const [0, 1, 6, 8],
          onQuickPagesChanged: (_) {},
          profileName: '',
          profileIncomeInCents: 0,
          onEditProfile: () {},
          onExportBackup: () async {},
          onRestoreBackup: () async {},
          onConfigureAutomaticBackup: () async {},
          onDisableAutomaticBackup: () async {},
          onRunAutomaticBackup: () async {},
          financeCategories: [category],
          onRenameFinanceCategory: (id, name) => newName = name,
          onArchiveFinanceCategory: (id) => archivedId = id,
        ),
      ),
    ));
    await tester.ensureVisible(find.byTooltip('Renomear Padaria'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Renomear Padaria'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'Alimentação especial');
    await tester.tap(find.text('Salvar'));
    await tester.pumpAndSettle();
    expect(newName, 'Alimentação especial');

    await tester.ensureVisible(find.byTooltip('Arquivar Padaria'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Arquivar Padaria'));
    await tester.pumpAndSettle();
    expect(archivedId, isNull);
    await tester.tap(find.text('Cancelar'));
    await tester.pumpAndSettle();
    expect(archivedId, isNull);
    await tester.tap(find.byTooltip('Arquivar Padaria'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Arquivar'));
    await tester.pumpAndSettle();
    expect(archivedId, 'custom');
  });
}
