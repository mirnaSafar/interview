import 'package:balance/core/database/database.dart';
import 'package:balance/core/database/tables/transactions.dart';
import 'package:drift/drift.dart';
import 'package:injectable/injectable.dart';
import 'package:uuid/uuid.dart';

part 'transactions_dao.g.dart';

@lazySingleton
@DriftAccessor(tables: [Transactions])
class TransactionsDao extends DatabaseAccessor<Database>
    with _$TransactionsDaoMixin {
  TransactionsDao(Database db) : super(db);
  // Future<void> insertTransaction(Transaction transaction) {
  //   return into(transactions).insert(transaction);
  // }

  Stream<List<Transaction>> watchAllTransactionsForGroup(String groupId) {
    return (select(transactions)..where((tbl) => tbl.groupId.equals(groupId)))
        .watch();
  }

  deleteTransactionById(transactionId) {
    transactions.deleteWhere((tbl) => tbl.id.equals(transactionId));
  }

  Future adjustTransaction(int amount, String id) async {
    final companion = TransactionsCompanion(amount: Value(amount));
    return (update(transactions)..where((tbl) => tbl.id.equals(id)))
        .write(companion);
  }

  Future insertTransaction(String id, int amount, String type) {
    return into(transactions).insert(TransactionsCompanion.insert(
        amount: Value(amount),
        type: type,
        id: const Uuid().v1(),
        createdAt: DateTime.now(),
        groupId: id));
  }

  // Future adjustBalance(int balance, String groupId) async {
  //   const companion = TransactionsCompanion();
  //   return (update(transactions)..where((tbl) => tbl.id.equals(groupId)))
  //       .write(companion);
  // }

  // Stream<List> watch() =>
  //     select(Transactions as ResultSetImplementation<HasResultSet, dynamic>)
  //         .watch();

  // Stream<Transaction?> watchAllTransactions(String groupId) {
  //   return (select(transactions)..where((tbl) => tbl.groupId.equals(groupId)))
  //       .watchSingleOrNull();
  // }
}
