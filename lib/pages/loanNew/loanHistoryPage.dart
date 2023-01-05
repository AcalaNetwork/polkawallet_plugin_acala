import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:intl/intl.dart';
import 'package:polkawallet_plugin_acala/api/types/txLoanData.dart';
import 'package:polkawallet_plugin_acala/pages/loanNew/loanTxDetailPage.dart';
import 'package:polkawallet_plugin_acala/polkawallet_plugin_acala.dart';
import 'package:polkawallet_plugin_acala/utils/i18n/index.dart';
import 'package:polkawallet_sdk/storage/keyring.dart';
import 'package:polkawallet_sdk/utils/i18n.dart';
import 'package:polkawallet_ui/components/TransferIcon.dart';
import 'package:polkawallet_ui/components/listTail.dart';
import 'package:polkawallet_ui/components/v3/plugin/pluginFilterWidget.dart';
import 'package:polkawallet_ui/components/v3/plugin/pluginPopLoadingWidget.dart';
import 'package:polkawallet_ui/components/v3/plugin/pluginScaffold.dart';
import 'package:polkawallet_ui/utils/format.dart';
import 'package:polkawallet_ui/utils/index.dart';

class LoanHistoryPage extends StatefulWidget {
  LoanHistoryPage(this.plugin, this.keyring);
  final PluginAcala plugin;
  final Keyring keyring;

  static const String route = '/acala/loan/txs';

  @override
  State<LoanHistoryPage> createState() => _LoanHistoryPageState();
}

class _LoanHistoryPageState extends State<LoanHistoryPage> {
  String filterString = PluginFilterWidget.pluginAllFilter;
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
      widget.plugin.service!.history.getLoans();
    });
  }

  @override
  Widget build(BuildContext context) {
    final dic = I18n.of(context)!.getDic(i18n_full_dic_acala, 'acala')!;
    return PluginScaffold(
      appBar: PluginAppBar(
        title: Text(dic['loan.txs']!),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Observer(builder: (_) {
          final originList = widget.plugin.store?.history.loans;
          if (originList == null) {
            return PluginPopLoadingContainer(loading: true);
          }
          List<TxLoanData> historylist = originList
              .map((e) => TxLoanData.fromHistory(e, widget.plugin))
              .toList();

          final list;
          switch (filterString) {
            case TxLoanData.actionTypeDepositFilter:
              list = historylist
                  .where((element) =>
                      element.actionType == TxLoanData.actionTypeDeposit)
                  .toList();
              break;
            case TxLoanData.actionTypeWithdrawFilter:
              list = historylist
                  .where((element) =>
                      element.actionType == TxLoanData.actionTypeWithdraw)
                  .toList();
              break;
            case TxLoanData.actionTypeBorrowFilter:
              list = historylist
                  .where((element) =>
                      element.actionType == TxLoanData.actionTypeBorrow)
                  .toList();
              break;
            case TxLoanData.actionTypePaybackFilter:
              list = historylist
                  .where((element) =>
                      element.actionType == TxLoanData.actionTypePayback)
                  .toList();
              break;
            case TxLoanData.actionLiquidateFilter:
              list = historylist
                  .where((element) =>
                      element.actionType == TxLoanData.actionLiquidate)
                  .toList();
              break;
            default:
              list = historylist;
          }

          return Column(children: [
            PluginFilterWidget(
              options: [
                PluginFilterWidget.pluginAllFilter,
                TxLoanData.actionTypeDepositFilter,
                TxLoanData.actionTypeWithdrawFilter,
                TxLoanData.actionTypeBorrowFilter,
                TxLoanData.actionTypePaybackFilter,
                TxLoanData.actionLiquidateFilter,
              ],
              filter: (option) {
                setState(() {
                  filterString = option;
                });
              },
            ),
            Expanded(
                child: ListView.builder(
              itemCount: list.length + 1,
              itemBuilder: (BuildContext context, int i) {
                if (i == list.length) {
                  return ListTail(
                    isEmpty: list.length == 0,
                    isLoading: false,
                    color: Colors.white,
                  );
                }

                // final HistoryData history = list[i];
                final TxLoanData detail = list[i];
                TransferIconType type = TransferIconType.mint;
                var describe = detail.message ?? '';
                switch (detail.actionType) {
                  case TxLoanData.actionTypeDeposit:
                    type = TransferIconType.deposit;
                    break;
                  case TxLoanData.actionTypeWithdraw:
                    type = TransferIconType.withdraw;
                    break;
                  case TxLoanData.actionTypePayback:
                    type = TransferIconType.payback;
                    break;
                  default:
                    type = TransferIconType.mint;
                }

                return Container(
                  decoration: BoxDecoration(
                    color: Color(0x14ffffff),
                    border: Border(
                        bottom:
                            BorderSide(width: 0.5, color: Color(0x24ffffff))),
                  ),
                  child: ListTile(
                    dense: true,
                    title: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          dic['loan.${detail.actionType}'] ?? '',
                          style: Theme.of(context)
                              .textTheme
                              .headline5
                              ?.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600),
                        ),
                        Text(describe,
                            textAlign: TextAlign.start,
                            style: Theme.of(context)
                                .textTheme
                                .headline5
                                ?.copyWith(color: Colors.white))
                      ],
                    ),
                    subtitle: Text(
                        Fmt.dateTime(DateFormat("yyyy-MM-ddTHH:mm:ss")
                            .parse(detail.time, true)),
                        style: Theme.of(context).textTheme.headline5?.copyWith(
                            color: Colors.white,
                            fontSize: UI.getTextSize(10, context))),
                    leading:
                        TransferIcon(type: type, bgColor: Color(0x57FFFFFF)),
                    onTap: () {
                      Navigator.pushNamed(
                        context,
                        LoanTxDetailPage.route,
                        arguments: detail,
                      );
                    },
                  ),
                );
              },
            ))
          ]);
        }),
      ),
    );
  }
}
