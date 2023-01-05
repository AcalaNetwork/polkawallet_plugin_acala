import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:polkawallet_plugin_acala/pages/earnNew/earnTaigaDetailPage.dart';
import 'package:polkawallet_plugin_acala/polkawallet_plugin_acala.dart';
import 'package:polkawallet_plugin_acala/utils/assets.dart';
import 'package:polkawallet_plugin_acala/utils/format.dart';
import 'package:polkawallet_plugin_acala/utils/i18n/index.dart';
import 'package:polkawallet_sdk/storage/keyring.dart';
import 'package:polkawallet_sdk/utils/i18n.dart';
import 'package:polkawallet_ui/components/connectionChecker.dart';
import 'package:polkawallet_ui/components/v3/plugin/pluginPopLoadingWidget.dart';
import 'package:polkawallet_ui/components/v3/plugin/pluginTokenIcon.dart';
import 'package:polkawallet_ui/components/v3/plugin/roundedPluginCard.dart';
import 'package:polkawallet_ui/utils/format.dart';
import 'package:polkawallet_ui/utils/index.dart';

class EarnTaigaList extends StatefulWidget {
  EarnTaigaList(this.plugin, this.keyring, {Key? key}) : super(key: key);
  final PluginAcala plugin;
  final Keyring keyring;

  @override
  State<EarnTaigaList> createState() => _EarnTaigaListState();
}

class _EarnTaigaListState extends State<EarnTaigaList> {
  bool _loading = true;
  Future<void> _queryTaigaPoolInfo() async {
    final info = await widget.plugin.api!.earn
        .getTaigaPoolInfo(widget.keyring.current.address!);
    widget.plugin.store!.earn.setTaigaPoolInfo(info);
    final data = await widget.plugin.api!.earn.getTaigaTokenPairs();
    widget.plugin.store!.earn.setTaigaTokenPairs(data!);
    setState(() {
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final dic = I18n.of(context)!.getDic(i18n_full_dic_acala, 'acala')!;
    return Observer(builder: (_) {
      final dexPools = widget.plugin.store!.earn.taigaPoolInfoMap;
      final taigaTokenPairs = widget.plugin.store!.earn.taigaTokenPairs;
      return Column(
        children: [
          ConnectionChecker(
            widget.plugin,
            onConnected: _queryTaigaPoolInfo,
          ),
          Expanded(
              child: dexPools.length == 0 || taigaTokenPairs.length == 0
                  ? PluginPopLoadingContainer(loading: _loading)
                  : GridView.builder(
                      padding: EdgeInsets.all(16),
                      itemCount: dexPools.length,
                      itemBuilder: (_, i) {
                        final taigaPoolInfo =
                            dexPools[dexPools.keys.toList()[i]];

                        final balance = AssetsUtils.getBalanceFromTokenNameId(
                            widget.plugin, dexPools.keys.toList()[i]);
                        final price = AssetsUtils.getMarketPrice(
                            widget.plugin, balance.symbol!);

                        final tokenSymbol = balance.symbol;

                        var apy = 0.0;
                        taigaPoolInfo?.apy.forEach((key, value) {
                          apy += value;
                        });

                        final taigaData = taigaTokenPairs.firstWhere(
                            (element) =>
                                element.tokenNameId ==
                                dexPools.keys.toList()[i]);

                        var totalStaked = 0.0;
                        if (tokenSymbol == "tDOT") {
                          totalStaked = Fmt.balanceDouble(
                                  taigaPoolInfo?.totalShares ?? "",
                                  balance.decimals!) *
                              price;
                        }

                        var unstaked = false;
                        var staked = false;
                        var canClaim = false;
                        if (balance.amount != null &&
                            Fmt.balanceInt(balance.amount) > BigInt.zero) {
                          unstaked = true;
                        }
                        if (BigInt.parse(taigaPoolInfo!.userShares) >
                            BigInt.zero) {
                          staked = true;
                        }
                        var claim = BigInt.zero;
                        taigaPoolInfo.reward.forEach((e) {
                          claim += BigInt.parse(e);
                        });
                        if (claim > BigInt.zero) {
                          canClaim = true;
                        }

                        return GestureDetector(
                          child: RoundedPluginCard(
                              borderRadius: const BorderRadius.all(
                                  const Radius.circular(9)),
                              child: Column(
                                children: [
                                  Container(
                                    width: double.infinity,
                                    alignment: Alignment.centerLeft,
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.only(
                                          topLeft: Radius.circular(9),
                                          topRight: Radius.circular(9)),
                                    ),
                                    padding: EdgeInsets.only(
                                        left: 12, top: 7, right: 8, bottom: 9),
                                    child: Row(
                                      children: [
                                        PluginTokenIcon(
                                          tokenSymbol ?? "",
                                          widget.plugin.tokenIcons,
                                          size: 24,
                                          bgColor: Color(0xFF9E98E7),
                                        ),
                                        Expanded(
                                            child: Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.end,
                                          children: [
                                            Visibility(
                                                visible: unstaked,
                                                child: Padding(
                                                    padding: EdgeInsets.only(
                                                        left: 4),
                                                    child: Image.asset(
                                                      "packages/polkawallet_plugin_acala/assets/images/unstaked.png",
                                                      width: 22,
                                                    ))),
                                            Visibility(
                                                visible: staked,
                                                child: Padding(
                                                    padding: EdgeInsets.only(
                                                        left: 4),
                                                    child: Image.asset(
                                                      "packages/polkawallet_plugin_acala/assets/images/staked_1.png",
                                                      width: 22,
                                                    ))),
                                            Visibility(
                                                visible: canClaim,
                                                child: Padding(
                                                    padding: EdgeInsets.only(
                                                        left: 4),
                                                    child: Image.asset(
                                                      "packages/polkawallet_plugin_acala/assets/images/rewards.png",
                                                      width: 22,
                                                    ))),
                                          ],
                                        ))
                                      ],
                                    ),
                                  ),
                                  Expanded(
                                      child: Container(
                                    width: double.infinity,
                                    padding: EdgeInsets.only(
                                        left: 12, top: 6, right: 12),
                                    decoration: BoxDecoration(
                                        borderRadius: BorderRadius.only(
                                            bottomLeft: Radius.circular(9),
                                            bottomRight: Radius.circular(9)),
                                        color: Color(0xFF494b4e)),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          PluginFmt.tokenView(tokenSymbol),
                                          style: Theme.of(context)
                                              .textTheme
                                              .headline4
                                              ?.copyWith(
                                                  color: Color(0xBDFFFFFF),
                                                  fontWeight: FontWeight.w600),
                                        ),
                                        Padding(
                                            padding: EdgeInsets.only(top: 17),
                                            child: Text(
                                              dic['earn.apy']!,
                                              style: Theme.of(context)
                                                  .textTheme
                                                  .headline3
                                                  ?.copyWith(
                                                      color: Colors.white,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      height: 1.0,
                                                      fontSize: UI.getTextSize(
                                                          24, context)),
                                            )),
                                        Text(
                                          Fmt.ratio(apy),
                                          style: Theme.of(context)
                                              .textTheme
                                              .headline3
                                              ?.copyWith(
                                                  color: Colors.white,
                                                  fontWeight: FontWeight.bold,
                                                  height: 1.0,
                                                  fontSize: UI.getTextSize(
                                                      24, context)),
                                        ),
                                        Padding(
                                            padding: EdgeInsets.only(top: 6),
                                            child: Text(
                                              '${dic['dex.lp']} \$${Fmt.priceFloor(totalStaked)}',
                                              style: Theme.of(context)
                                                  .textTheme
                                                  .headline5
                                                  ?.copyWith(
                                                      color: Color(0xBDFFFFFF)),
                                            )),
                                      ],
                                    ),
                                  )),
                                ],
                              )),
                          onTap: () => Navigator.of(context).pushNamed(
                              EarnTaigaDetailPage.route,
                              arguments: {'poolId': taigaData.tokenNameId}),
                        );
                      },
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          mainAxisSpacing: 24,
                          crossAxisSpacing: 20,
                          childAspectRatio: 168 / 190.0),
                    ))
        ],
      );
    });
  }
}
