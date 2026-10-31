import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:organiza/application/organiza_store.dart';
import 'package:organiza/domain/models.dart';
import 'package:organiza/presentation/basic_pages.dart';
import 'package:organiza/presentation/dialogs.dart';
import 'package:organiza/presentation/organiza_theme.dart';

void main() {
  testWidgets('conta pode ser arquivada, reativada e excluída do patrimônio',
      (tester) async {
    tester.view.physicalSize = const Size(900, 1200);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final store = OrganizaStore.inMemory();
    addTearDown(store.dispose);
    store.addAccount('Principal', 50000);
    final account = store.accounts.single;

    await tester.pumpWidget(MaterialApp(
      theme: OrganizaTheme.dark(),
      home: Scaffold(
        body: AnimatedBuilder(
          animation: store,
          builder: (context, _) => AccountsPage(
            store: store,
            hideValues: false,
            onAdd: () {},
            onDelete: store.deleteAccount,
            onEditBalance: (_) {},
            onEdit: (_) {},
          ),
        ),
      ),
    ));
    await tester.pumpAndSettle();

    expect(find.textContaining('BRL 500.00'), findsOneWidget);
    await tester.tap(find.byType(Checkbox));
    await tester.pumpAndSettle();
    expect(store.accounts.single.includeInNetWorth, isFalse);
    expect(store.balance, 50000);

    await tester.tap(find.byTooltip('Ações da conta'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Arquivar conta'));
    await tester.pumpAndSettle();
    expect(store.accounts.single.archivedAt, isNotNull);
    expect(store.activeAccounts, isEmpty);
    expect(store.balance, 50000);
    expect(find.textContaining('Arquivada'), findsOneWidget);

    await tester.tap(find.byTooltip('Ações da conta'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Reativar conta'));
    await tester.pumpAndSettle();
    expect(store.accounts.single.archivedAt, isNull);
    expect(store.activeAccounts.single.id, account.id);
    expect(store.balance, 50000);
  });

  testWidgets('formulário salva o tipo escolhido para a conta', (tester) async {
    AccountInput? result;
    await tester.pumpWidget(MaterialApp(
      theme: OrganizaTheme.dark(),
      home: Builder(builder: (context) {
        return Scaffold(
          body: TextButton(
            onPressed: () async {
              result = await showDialog<AccountInput>(
                context: context,
                builder: (_) => const AccountDialog(),
              );
            },
            child: const Text('Abrir'),
          ),
        );
      }),
    ));
    await tester.tap(find.text('Abrir'));
    await tester.pumpAndSettle();

    await tester.tap(find.byType(DropdownButtonFormField<AccountType>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Poupança').last);
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).first, 'Reserva');
    await tester.tap(find.text('Salvar conta'));
    await tester.pumpAndSettle();

    expect(result?.type, AccountType.savings);
    expect(result?.name, 'Reserva');
  });
}
