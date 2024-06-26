import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:intl/intl.dart';
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
import 'package:polkawallet_plugin_acala/api/types/txHomaData.dart';
import 'package:polkawallet_plugin_acala/pages/homaNew/homaTxDetailPage.dart';

class HomaHistoryPage extends StatefulWidget {
  HomaHistoryPage(this.plugin, this.keyring);
  final PluginAcala plugin;
  final Keyring keyring;

  static const String route = '/acala/homa/txs';

  @override
  State<HomaHistoryPage> createState() => _HomaHistoryPageState();
}

class _HomaHistoryPageState extends State<HomaHistoryPage> {
  String filterString = PluginFilterWidget.pluginAllFilter;
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
      widget.plugin.service!.history.getHomas();
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
        child: Observer(
          builder: (_) {
            final originList = widget.plugin.store?.history.homas;

            if (originList == null) {
              return PluginPopLoadingContainer(loading: true);
            }

            final list;
            switch (filterString) {
              case TxHomaData.actionMintFilter:
                list = originList
                    .where((element) => element.event == TxHomaData.actionMint)
                    .toList();
                break;
              case TxHomaData.actionRequestedRedeemFilter:
                list = originList
                    .where(
                        (element) => element.event == TxHomaData.actionRedeem)
                    .toList();
                break;
              case TxHomaData.actionFastRedeemFilter:
                list = originList
                    .where((element) =>
                        element.event == TxHomaData.actionRedeemedByFastMatch)
                    .toList();
                break;
              case TxHomaData.actionUnbondFilter:
                list = originList
                    .where((element) =>
                        element.event == TxHomaData.actionRedeemedByUnbond)
                    .toList();
                break;
              default:
                list = originList;
            }

            return Column(children: [
              PluginFilterWidget(
                options: [
                  PluginFilterWidget.pluginAllFilter,
                  TxHomaData.actionMintFilter,
                  TxHomaData.actionRequestedRedeemFilter,
                  TxHomaData.actionFastRedeemFilter,
                  TxHomaData.actionUnbondFilter,
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

                    final history = list[i];
                    final TxHomaData detail = TxHomaData.fromHistory(history);
                    String amountTail = history.message ?? "";
                    TransferIconType type = TransferIconType.redeem;

                    switch (detail.action) {
                      case TxHomaData.actionMint:
                        type = TransferIconType.mint;
                        break;
                      case TxHomaData.actionRedeem:
                      case TxHomaData.actionLiteRedeem:
                        break;
                      case TxHomaData.actionRedeemedByUnbond:
                        break;
                      case TxHomaData.actionRedeemedByFastMatch:
                        break;
                      case TxHomaData.actionRedeemed:
                      case TxHomaData.actionLiteRedeemed:
                        break;
                      case TxHomaData.actionWithdrawRedemption:
                        break;
                      case TxHomaData.actionRedeemCancel:
                        break;
                    }

                    return Container(
                      decoration: BoxDecoration(
                        color: Color(0x14ffffff),
                        border: Border(
                            bottom: BorderSide(
                                width: 0.5, color: Color(0x24ffffff))),
                      ),
                      child: ListTile(
                        dense: true,
                        title: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${dic[detail.action]}',
                              style: Theme.of(context)
                                  .textTheme
                                  .headline5
                                  ?.copyWith(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w600),
                            ),
                            Text(amountTail,
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
                            type: type, bgColor: Color(0x57FFFFFF)),
                        onTap: () => Navigator.of(context).pushNamed(
                            HomaTxDetailPage.route,
                            arguments: detail),
                      ),
                    );
                  },
                ),
              ),
            ]);
          },
        ),
      ),
    );
  }
}
