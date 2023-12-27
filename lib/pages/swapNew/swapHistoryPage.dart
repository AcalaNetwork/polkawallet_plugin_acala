import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:intl/intl.dart';
import 'package:polkawallet_plugin_acala/api/history/types/historyData.dart';
import 'package:polkawallet_plugin_acala/api/types/txSwapData.dart';
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

class SwapHistoryPage extends StatefulWidget {
  SwapHistoryPage(this.plugin, this.keyring);
  final PluginAcala plugin;
  final Keyring keyring;

  static const String route = '/karura/swap/txs';

  @override
  State<SwapHistoryPage> createState() => _SwapHistoryPageState();
}

class _SwapHistoryPageState extends State<SwapHistoryPage> {
  String filterString = PluginFilterWidget.pluginAllFilter;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
      widget.plugin.service?.history.getSwaps();
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
        body: Observer(
          builder: (_) {
            final originList = widget.plugin.store?.history.swaps;
            final isLoading = originList == null;
            if (isLoading) {
              return PluginPopLoadingContainer(loading: true);
            }

            final list;
            switch (filterString) {
              case TxSwapData.actionTypeSwapFilter:
                list = originList!
                    .where((element) => element.event?.contains('Swap') == true)
                    .toList();
                break;
              case TxSwapData.actionTypeAddLiquidityFilter:
                list = originList!
                    .where((element) => RegExp(r'AddLiquidity|Mint')
                        .hasMatch(element.event ?? ''))
                    .toList();
                break;
              case TxSwapData.actionTypeRemoveLiquidityFilter:
                list = originList!
                    .where((element) => RegExp(
                            r'RemoveLiquidity|ProportionRedeem|SingleRedeem|MultiRedeem')
                        .hasMatch(element.event ?? ''))
                    .toList();
                break;
              case TxSwapData.actionTypeAddProvisionFilter:
                list = originList!
                    .where((element) =>
                        element.event?.contains('AddProvision') == true)
                    .toList();
                break;
              default:
                list = originList;
            }

            return SafeArea(
                child: Column(children: [
              PluginFilterWidget(
                options: [
                  PluginFilterWidget.pluginAllFilter,
                  TxSwapData.actionTypeSwapFilter,
                  TxSwapData.actionTypeAddLiquidityFilter,
                  TxSwapData.actionTypeRemoveLiquidityFilter,
                  TxSwapData.actionTypeAddProvisionFilter,
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
                      isLoading: isLoading,
                      color: Colors.white,
                    );
                  }

                  final HistoryData detail = list[i];
                  TransferIconType type = TransferIconType.swap;
                  String action = (detail.event?.split('.') ?? ['', ''])[1];
                  final time =
                      (detail.data!['timestamp'] as String).replaceAll(' ', '');
                  switch (action) {
                    case "RemoveLiquidity":
                      type = TransferIconType.remove_liquidity;
                      break;
                    case "AddProvision":
                      type = TransferIconType.add_provision;
                      break;
                    case "AddLiquidity":
                      type = TransferIconType.add_liquidity;
                      break;
                    case "Swap":
                      type = TransferIconType.swap;
                      break;
                    //taiga
                    case "Mint":
                      type = TransferIconType.add_liquidity;
                      action = "AddLiquidity";
                      break;
                    case "ProportionRedeem":
                    case "SingleRedeem":
                    case "MultiRedeem":
                      type = TransferIconType.remove_liquidity;
                      action = "RemoveLiquidity";
                      break;
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
                          Text(detail.message ?? "",
                              textAlign: TextAlign.start,
                              style: Theme.of(context)
                                  .textTheme
                                  .headline5
                                  ?.copyWith(color: Colors.white))
                        ],
                      ),
                      subtitle: Text(
                          Fmt.dateTime(DateFormat("yyyy-MM-ddTHH:mm:ss")
                              .parse(time, true)),
                          style: Theme.of(context)
                              .textTheme
                              .headline5
                              ?.copyWith(
                                  color: Colors.white,
                                  fontSize: UI.getTextSize(10, context))),
                      leading: TransferIcon(
                          type: type,
                          darkBgColor: Color(0xFF494a4c),
                          bgColor: Color(0x57FFFFFF)),
                      onTap: () {
                        if (detail.resolveLinks != null) {
                          UI.launchURL(detail.resolveLinks!);
                        }
                      },
                    ),
                  );
                },
              )),
            ]));
          },
        ));
  }
}
