import 'package:flutter_test/flutter_test.dart';
import 'package:organiza/application/organiza_store.dart';
import 'package:organiza/domain/models.dart';

void main() {
  test('tags podem ser criadas, renomeadas, vinculadas e removidas', () {
    final store = OrganizaStore.inMemory();
    addTearDown(store.dispose);
    store.addAccount('Principal', 10000);
    store.addTransaction(
      accountId: store.accounts.single.id,
      type: TransactionType.expense,
      amountInCents: 1000,
      description: 'Mercado',
    );
    final transactionId = store.transactions.single.id;
    final home = store.createTag('Casa', colorValue: 0xFFAA3300);
    final grocery = store.createTag('Mercado');
    store.setTransactionTags(transactionId, {home.id, grocery.id});

    expect(store.tags.length, 2);
    expect(store.tagsForTransaction(transactionId).map((tag) => tag.id),
        [home.id, grocery.id]);

    store.updateTag(id: home.id, name: 'Moradia', colorValue: 0xFF3366AA);
    expect(store.tags.singleWhere((tag) => tag.id == home.id).name, 'Moradia');
    expect(store.tagsForTransaction(transactionId).first.name, 'Mercado');
    store.deleteTag(home.id);
    expect(store.tagsForTransaction(transactionId).map((tag) => tag.id),
        [grocery.id]);
  });

  test('nomes de tag não diferenciam maiúsculas e vínculo sobrevive desfazer',
      () {
    final store = OrganizaStore.inMemory();
    addTearDown(store.dispose);
    store.addAccount('Principal', 10000);
    store.addTransaction(
      accountId: store.accounts.single.id,
      type: TransactionType.expense,
      amountInCents: 1000,
      description: 'Farmácia',
    );
    final id = store.transactions.single.id;
    final tag = store.createTag('Saúde');
    expect(() => store.createTag('SAÚDE'), throwsArgumentError);
    store.setTransactionTags(id, {tag.id});

    store.deleteTransaction(id);
    expect(store.transactions, isEmpty);
    expect(
        store.restoreDeletedRecord(SoftDeleteEntity.transaction, id), isTrue);
    expect(store.tagsForTransaction(id).single.id, tag.id);
    expect(() => store.setTransactionTags(id, {'desconhecida'}),
        throwsArgumentError);
  });
}
