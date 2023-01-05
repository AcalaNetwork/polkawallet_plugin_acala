import 'package:flutter/material.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import 'package:intl/intl.dart';
import 'package:polkawallet_plugin_acala/api/types/txSwapData.dart';
import 'package:polkawallet_plugin_acala/common/constants/base.dart';
import 'package:polkawallet_plugin_acala/common/constants/subQuery.dart';
import 'package:polkawallet_plugin_acala/pages/swapNew/swapDetailPage.dart';
import 'package:polkawallet_plugin_acala/polkawallet_plugin_acala.dart';
import 'package:polkawallet_plugin_acala/service/graphql.dart';
import 'package:polkawallet_plugin_acala/utils/format.dart';
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

  static const String route = '/acala/swap/txs';

  @override
  State<SwapHistoryPage> createState() => _SwapHistoryPageState();
}

class _SwapHistoryPageState extends State<SwapHistoryPage> {
  List<TxSwapData> _list = [];
  bool _isLoading = true;
  String filterString = PluginFilterWidget.pluginAllFilter;
  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      List<List<TxSwapData>> orgin =
          await Future.wait([querySwapHistory(), queryTaigaHistory()]);
      List<TxSwapData> list = orgin.expand((element) => element).toList()
        ..sort((left, right) => right.time.compareTo(left.time));
      setState(() {
        _isLoading = false;
        _list = list;
      });
    });
  }

  Future<List<TxSwapData>> querySwapHistory() async {
    final client = clientFor(uri: GraphQLConfig['defiUri']!);

    final result = await client.value.query(QueryOptions(
      document: gql(swapQuery),
      fetchPolicy: FetchPolicy.noCache,
      variables: <String, String?>{
        'account': widget.keyring.current.address,
      },
    ));

    List<TxSwapData> list = [];
    if (result.data != null) {
      list = List.of(result.data!['dexActions']['nodes'])
          .map((i) => TxSwapData.fromJson(i as Map, widget.plugin))
          .toList();
    }
    return list;
  }

  Future<List<TxSwapData>> queryTaigaHistory() async {
    List<TxSwapData> list = [];

    await _queryTaigaPoolInfo();

    final clientTaiga = clientFor(uri: GraphQLConfig['taigaUri']!);

    final resultTaiga = await clientTaiga.value.query(QueryOptions(
      document: gql(swapTaigaQuery),
      fetchPolicy: FetchPolicy.noCache,
      variables: <String, String?>{
        'address': widget.keyring.current.address,
      },
    ));
    if (resultTaiga.data != null) {
      resultTaiga.data!.forEach((key, value) {
        if (value is Map && value['nodes'] != null) {
          list.addAll(List.of(value['nodes'])
              .map((i) => TxSwapData.fromTaigaJson(i as Map, widget.plugin))
              .toList());
        }
      });
    }
    return list;
  }

  Future<void> _queryTaigaPoolInfo() async {
    if (widget.plugin.store!.earn.taigaTokenPairs.length == 0) {
      final info = await widget.plugin.api!.earn
          .getTaigaPoolInfo(widget.keyring.current.address!);
      widget.plugin.store!.earn.setTaigaPoolInfo(info);
      final data = await widget.plugin.api!.earn.getTaigaTokenPairs();
      widget.plugin.store!.earn.setTaigaTokenPairs(data!);
    }
  }

  @override
  Widget build(BuildContext context) {
    final dic = I18n.of(context)!.getDic(i18n_full_dic_acala, 'acala')!;

    final list;
    switch (filterString) {
      case TxSwapData.actionTypeSwapFilter:
        list = _list.where((element) => (element.action == 'swap')).toList();
        break;
      case TxSwapData.actionTypeAddLiquidityFilter:
        list = _list
            .where((element) =>
                (element.action == 'addLiquidity' || element.action == 'mint'))
            .toList();
        break;
      case TxSwapData.actionTypeRemoveLiquidityFilter:
        list = _list
            .where((element) => (element.action == 'removeLiquidity' ||
                element.action == 'proportionredeem' ||
                element.action == 'singleredeem' ||
                element.action == 'multiredeem'))
            .toList();
        break;
      case TxSwapData.actionTypeAddProvisionFilter:
        list = _list
            .where((element) => (element.action == 'addProvision'))
            .toList();
        break;
      default:
        list = _list;
    }

    return PluginScaffold(
        appBar: PluginAppBar(
          title: Text(dic['loan.txs']!),
          centerTitle: true,
        ),
        body: _isLoading
            ? PluginPopLoadingContainer(loading: true)
            : SafeArea(
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
                            isLoading: _isLoading,
                            color: Colors.white,
                          );
                        }

                        final TxSwapData detail = list[i];
                        TransferIconType type = TransferIconType.swap;
                        String describe = "";
                        String action = detail.action ?? "";
                        switch (detail.action) {
                          case "removeLiquidity":
                            type = TransferIconType.remove_liquidity;
                            describe =
                                "remove ${detail.amountReceive} ${PluginFmt.tokenView(detail.tokenReceive)} and ${detail.amountPay} ${PluginFmt.tokenView(detail.tokenPay)}";
                            break;
                          case "addProvision":
                            type = TransferIconType.add_provision;
                            describe =
                                "add ${detail.amountReceive} ${PluginFmt.tokenView(detail.tokenReceive)} and ${detail.amountPay} ${PluginFmt.tokenView(detail.tokenPay)} in boostrap";
                            break;
                          case "addLiquidity":
                            type = TransferIconType.add_liquidity;
                            describe =
                                "add ${detail.amountReceive} ${PluginFmt.tokenView(detail.tokenReceive)} and ${detail.amountPay} ${PluginFmt.tokenView(detail.tokenPay)}";
                            break;
                          case "swap":
                            type = TransferIconType.swap;
                            describe =
                                "swap  ${detail.amountReceive} ${PluginFmt.tokenView(detail.tokenReceive)} for ${detail.amountPay} ${PluginFmt.tokenView(detail.tokenPay)}";
                            break;
                          //taiga
                          case "mint":
                            type = TransferIconType.add_liquidity;
                            action = "addLiquidity";
                            describe =
                                "add ${detail.amounts.map((e) => e.toTokenString()).join(" + ")} to pool";
                            break;
                          case "proportionredeem":
                          case "singleredeem":
                          case "multiredeem":
                            type = TransferIconType.remove_liquidity;
                            action = "removeLiquidity";
                            describe =
                                "remove ${detail.amountPay} shares from ${PluginFmt.tokenView(detail.tokenPay)} pool";
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
                                  dic['dex.$action']! +
                                      (detail.isTaiga ? "(Taiga)" : ""),
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
                                    ?.copyWith(
                                        color: Colors.white,
                                        fontSize: UI.getTextSize(10, context))),
                            leading: TransferIcon(
                                type: detail.isSuccess == false
                                    ? TransferIconType.failure
                                    : type,
                                darkBgColor: detail.isTaiga
                                    ? Color(0xFF974DE4)
                                    : Color(0xFF494a4c),
                                bgColor: detail.isTaiga
                                    ? Color(0xFF974DE4)
                                    : detail.isSuccess == false
                                        ? Color(0xFFD7D7D7)
                                        : Color(0x57FFFFFF)),
                            onTap: () {
                              Navigator.pushNamed(
                                context,
                                SwapDetailPage.route,
                                arguments: detail,
                              );
                            },
                          ),
                        );
                      },
                    ),
                  ),
                ]),
              ));
  }
}
