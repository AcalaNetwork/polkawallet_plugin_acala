import 'package:flutter/material.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import 'package:intl/intl.dart';
import 'package:polkawallet_plugin_acala/polkawallet_plugin_acala.dart';
import 'package:polkawallet_plugin_acala/utils/i18n/index.dart';
import 'package:polkawallet_sdk/storage/keyring.dart';
import 'package:polkawallet_sdk/utils/i18n.dart';
import 'package:polkawallet_ui/components/TransferIcon.dart';
import 'package:polkawallet_ui/components/listTail.dart';
import 'package:polkawallet_ui/components/v3/plugin/pluginLoadingWidget.dart';
import 'package:polkawallet_ui/components/v3/plugin/pluginScaffold.dart';
import 'package:polkawallet_ui/utils/format.dart';
import 'package:polkawallet_plugin_acala/api/types/txLoanData.dart';
import 'package:polkawallet_plugin_acala/common/constants/index.dart';
import 'package:polkawallet_plugin_acala/common/constants/subQuery.dart';
import 'package:polkawallet_plugin_acala/utils/format.dart';
import 'package:polkawallet_plugin_acala/pages/loanNew/loanTxDetailPage.dart';

class LoanHistoryPage extends StatelessWidget {
  LoanHistoryPage(this.plugin, this.keyring);
  final PluginAcala plugin;
  final Keyring keyring;

  static const String route = '/acala/loan/txs';

  @override
  Widget build(BuildContext context) {
    final dic = I18n.of(context)!.getDic(i18n_full_dic_acala, 'acala')!;
    return PluginScaffold(
      appBar: PluginAppBar(
        title: Text(dic['loan.txs']!),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Query(
            options: QueryOptions(
              document: gql(loanQuery),
              fetchPolicy: FetchPolicy.noCache,
              variables: <String, String?>{
                'account': keyring.current.address,
              },
            ),
            builder: (
              QueryResult result, {
              Future<QueryResult?> Function()? refetch,
              FetchMore? fetchMore,
            }) {
              if (result.data == null) {
                return Container(
                  height: MediaQuery.of(context).size.height / 3,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [PluginLoadingWidget()],
                  ),
                );
              }
              final list = List.of(result.data!['updatePositions']['nodes'])
                  .map((i) =>
                      TxLoanData.fromJson(i as Map, acala_stable_coin, plugin))
                  .toList();
              return ListView.builder(
                itemCount: list.length + 1,
                itemBuilder: (BuildContext context, int i) {
                  if (i == list.length) {
                    return ListTail(
                      isEmpty: list.length == 0,
                      isLoading: false,
                      color: Colors.white,
                    );
                  }

                  final TxLoanData detail = list[i];

                  TransferIconType type = TransferIconType.mint;
                  var describe =
                      "mint ${detail.amountDebit} ${PluginFmt.tokenView(acala_stable_coin_view)} by ${detail.amountCollateral} ${PluginFmt.tokenView(detail.token)}";
                  if (detail.actionType == TxLoanData.actionTypeDeposit) {
                    type = TransferIconType.deposit;
                    describe =
                        "deposit ${detail.amountCollateral} ${PluginFmt.tokenView(detail.token)}";
                  } else if (detail.actionType ==
                      TxLoanData.actionTypeWithdraw) {
                    type = TransferIconType.withdraw;
                    describe =
                        "withdraw ${detail.amountCollateral} ${PluginFmt.tokenView(detail.token)}";
                  } else if (detail.actionType ==
                      TxLoanData.actionTypePayback) {
                    type = TransferIconType.payback;
                    describe =
                        "payback ${detail.amountDebit} ${PluginFmt.tokenView(acala_stable_coin_view)} from collateral（${PluginFmt.tokenView(detail.token)}）";
                  } else if (detail.actionType == TxLoanData.actionTypeCreate) {
                    describe =
                        "${detail.amountDebit} ${PluginFmt.tokenView(acala_stable_coin_view)}  to create vault（${PluginFmt.tokenView(detail.token)}）";
                  } else if (detail.actionType == TxLoanData.actionLiquidate) {
                    describe =
                        "confiscate ${detail.amountCollateral} ${PluginFmt.tokenView(detail.token)} and ${detail.amountDebit} ${PluginFmt.tokenView(acala_stable_coin_view)}";
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
                            dic['loan.${detail.actionType}']!,
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
                          style: Theme.of(context)
                              .textTheme
                              .headline5
                              ?.copyWith(color: Colors.white, fontSize: 10)),
                      leading: TransferIcon(
                          type: detail.isSuccess == false
                              ? TransferIconType.failure
                              : type,
                          bgColor: detail.isSuccess == false
                              ? Color(0xFFD7D7D7)
                              : Color(0x57FFFFFF)),
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
              );
            }),
      ),
    );
  }
}
