import 'package:balance/core/database/dao/transactions_dao.dart';
import 'package:balance/core/database/database.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:balance/core/database/dao/groups_dao.dart';
import 'package:balance/main.dart';

class GroupPage extends StatefulWidget {
  final String groupId;
  const GroupPage(this.groupId, {Key? key}) : super(key: key);

  @override
  State<StatefulWidget> createState() => _GroupPageState();
}

class _GroupPageState extends State<GroupPage> {
  late final GroupsDao _groupsDao = getIt.get<GroupsDao>();
  late final TransactionsDao _transaction = getIt.get<TransactionsDao>();

  final _incomeController = TextEditingController();
  final _editController = TextEditingController();
  final _expenseController = TextEditingController();

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
          title: const Text("Group details"),
        ),
        body: ListView(
          children: [
            StreamBuilder<Group?>(
              stream: _groupsDao.watchGroup(widget.groupId),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Text("Loading...");
                }
                return Column(
                  mainAxisSize: MainAxisSize.max,
                  children: [
                    Text(snapshot.data?.name ?? ""),
                    Text(snapshot.data?.balance.toString() ?? ""),
                    Row(children: [
                      Expanded(
                        child: TextFormField(
                          controller: _incomeController,
                          keyboardType: const TextInputType.numberWithOptions(
                              decimal: true),
                          inputFormatters: [
                            FilteringTextInputFormatter.allow(RegExp(r"[0-9]"))
                          ],
                          decoration: const InputDecoration(
                            contentPadding: EdgeInsets.symmetric(vertical: 10),
                            suffixText: "\$",
                          ),
                        ),
                      ),
                      TextButton(
                          onPressed: () {
                            final amount = int.parse(_incomeController.text);
                            final balance = snapshot.data?.balance ?? 0;
                            _groupsDao.adjustBalance(
                                balance + amount, widget.groupId);
                            _incomeController.text = "";
                            _transaction.insertTransaction(
                                widget.groupId, amount, 'income');
                          },
                          child: const Text("Add income")),
                    ]),
                    Row(children: [
                      Expanded(
                        child: TextFormField(
                          controller: _expenseController,
                          keyboardType: const TextInputType.numberWithOptions(
                              decimal: true),
                          inputFormatters: [
                            FilteringTextInputFormatter.allow(RegExp(r"[0-9]"))
                          ],
                          decoration: const InputDecoration(
                            contentPadding: EdgeInsets.symmetric(vertical: 10),
                            suffixText: "\$",
                          ),
                        ),
                      ),
                      TextButton(
                          onPressed: () {
                            final amount = int.parse(_expenseController.text);
                            final balance = snapshot.data?.balance ?? 0;
                            _groupsDao.adjustBalance(
                                balance - amount, widget.groupId);
                            _expenseController.text = "";
                            _transaction.insertTransaction(
                                widget.groupId, amount, 'expense');
                          },
                          child: const Text("Add expense")),
                    ]),
                    StreamBuilder<List<Transaction>>(
                      stream: _transaction
                          .watchAllTransactionsForGroup(widget.groupId),
                      builder: (context, transsnapshot) {
                        if (!transsnapshot.hasData) {
                          return const Text("Loading...");
                        }
                        return ListView.builder(
                          shrinkWrap: true,
                          itemCount: transsnapshot.requireData.length,
                          itemBuilder: (context, index) {
                            final transaction =
                                transsnapshot.requireData[index];
                            return InkWell(
                              onTap: () {
                                showEditDialog(context, transaction, snapshot);
                              },
                              child: ListTile(
                                  // title: Text('Transaction ID: ${transaction.id}'),
                                  title: transaction.type == 'income'
                                      ? Text('Amount: +${transaction.amount}')
                                      : Text('Amount: -${transaction.amount}')),
                            );
                          },
                        );
                      },
                    )
                  ],
                );
              },
            ),
          ],
        ),
      );

  void showEditDialog(BuildContext context, Transaction transaction,
      AsyncSnapshot<Group?> snapshot) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          content: TextFormField(
            controller: _editController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r"[0-9]"))
            ],
            decoration: const InputDecoration(
              contentPadding: EdgeInsets.symmetric(vertical: 10),
              suffixText: "\$",
            ),
          ),
          actions: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                InkWell(
                    onTap: () {
                      _editController.text.isNotEmpty
                          ? updateTransaction(transaction, snapshot)
                          : null;

                      _editController.text = "";
                      Navigator.of(context).pop(true);
                    },
                    child: const Text('ok')),
                InkWell(
                    onTap: () {
                      _editController.text = "";
                      Navigator.of(context).pop(true);
                    },
                    child: const Text('cancel')),
              ],
            )
          ],
        );
      },
    );
  }

  void updateTransaction(
      Transaction transaction, AsyncSnapshot<Group?> snapshot) {
    _groupsDao.adjustBalance(
        transaction.type == 'income'
            ? (snapshot.data!.balance -
                transaction.amount +
                int.parse(_editController.text))
            : snapshot.data!.balance +
                transaction.amount -
                int.parse(_editController.text),
        widget.groupId);
    _transaction.adjustTransaction(
        int.parse(_editController.text), transaction.id);
  }
}
