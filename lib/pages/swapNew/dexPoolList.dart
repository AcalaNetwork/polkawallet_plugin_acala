import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:polkawallet_plugin_acala/api/types/dexPoolInfoData.dart';
import 'package:polkawallet_plugin_acala/pages/earnNew/addLiquidityPage.dart';
import 'package:polkawallet_plugin_acala/pages/earnNew/taigaAddLiquidityPage.dart';
import 'package:polkawallet_plugin_acala/pages/earnNew/taigaWithdrawLiquidityPage.dart';
import 'package:polkawallet_plugin_acala/pages/earnNew/withdrawLiquidityPage.dart';
import 'package:polkawallet_plugin_acala/polkawallet_plugin_acala.dart';
import 'package:polkawallet_plugin_acala/utils/assets.dart';
import 'package:polkawallet_plugin_acala/utils/format.dart';
import 'package:polkawallet_plugin_acala/utils/i18n/index.dart';
import 'package:polkawallet_sdk/plugin/store/balances.dart';
import 'package:polkawallet_sdk/storage/keyring.dart';
import 'package:polkawallet_sdk/utils/i18n.dart';
import 'package:polkawallet_ui/components/listTail.dart';
import 'package:polkawallet_ui/components/v3/numberLoader.dart';
import 'package:polkawallet_ui/components/v3/plugin/pluginInfoItem.dart';
import 'package:polkawallet_ui/components/v3/plugin/pluginOutlinedButtonSmall.dart';
import 'package:polkawallet_ui/components/v3/plugin/pluginTokenIcon.dart';
import 'package:polkawallet_ui/components/v3/plugin/roundedPluginCard.dart';
import 'package:polkawallet_ui/utils/consts.dart';
import 'package:polkawallet_ui/utils/format.dart';
import 'package:polkawallet_ui/utils/index.dart';

class DexPoolList extends StatefulWidget {
  DexPoolList(this.plugin, this.keyring);
  final PluginAcala plugin;
  final Keyring keyring;

  @override
  _DexPoolListState createState() => _DexPoolListState();
}

class _DexPoolListState extends State<DexPoolList> {
  final GlobalKey<RefreshIndicatorState> _refreshKey =
      new GlobalKey<RefreshIndicatorState>();

  Map _poolInfoMap = {};

  Future<void> _updateData() async {
    await widget.plugin.service!.earn.getDexPools();
    final pools = widget.plugin.store!.earn.dexPools.toList();
    final List? res = await widget.plugin.sdk.webView!.evalJavascript(
        'Promise.all([${pools.map((e) => 'api.query.dex.liquidityPool(${jsonEncode(e.tokens)})').join(',')}])');
    final poolInfoMap = {};
    pools.asMap().forEach((i, e) {
      poolInfoMap[e.tokenNameId] = res![i];
    });
    _queryTaigaPoolInfo();
    if (mounted) {
      setState(() {
        _poolInfoMap = poolInfoMap;
      });
    }
  }

  Future<void> _queryTaigaPoolInfo() async {
    final info = await widget.plugin.api!.earn
        .getTaigaPoolInfo(widget.keyring.current.address!);
    widget.plugin.store!.earn.setTaigaPoolInfo(info);
    final data = await widget.plugin.api!.earn.getTaigaTokenPairs();
    widget.plugin.store!.earn.setTaigaTokenPairs(data!);
  }

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _refreshKey.currentState!.show();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Observer(builder: (_) {
      final taigaDexPools = widget.plugin.store!.earn.taigaPoolInfoMap;
      final taigaTokenPairs =
          widget.plugin.store!.earn.taigaTokenPairs.toList();
      final dexPools = taigaDexPools.length > 0 && taigaTokenPairs.length > 0
          ? taigaTokenPairs
          : [];
      dexPools.retainWhere((e) => e.provisioning == null);
      dexPools.addAll(widget.plugin.store!.earn.dexPools.toList());
      return RefreshIndicator(
        color: Colors.black,
        backgroundColor: Colors.white,
        key: _refreshKey,
        onRefresh: _updateData,
        child: dexPools.length == 0
            ? ListView(
                padding: EdgeInsets.all(16),
                children: [
                  Center(
                    child: Container(
                      height: MediaQuery.of(context).size.width,
                      child: ListTail(
                        isEmpty: true,
                        isLoading: false,
                        color: Colors.white,
                      ),
                    ),
                  )
                ],
              )
            : ListView.builder(
                padding: EdgeInsets.all(16),
                itemCount: dexPools.length,
                itemBuilder: (_, i) {
                  //taiga
                  if (dexPools[i].tokenNameId == "sa://0" ||
                      dexPools[i].tokenNameId == "sa://1") {
                    return _TaigaDexPoolCard(
                      plugin: widget.plugin,
                      pool: dexPools[i],
                      tokenIcons: widget.plugin.tokenIcons,
                    );
                  }
                  final poolAmount =
                      _poolInfoMap[dexPools[i].tokenNameId] as List?;
                  return _DexPoolCard(
                    plugin: widget.plugin,
                    pool: dexPools[i],
                    poolAmount: poolAmount,
                    tokenIcons: widget.plugin.tokenIcons,
                  );
                },
              ),
      );
    });
  }
}

class _TaigaDexPoolCard extends StatelessWidget {
  _TaigaDexPoolCard({this.plugin, this.pool, this.tokenIcons});

  final PluginAcala? plugin;
  final DexPoolData? pool;
  final Map<String, Widget>? tokenIcons;

  @override
  Widget build(BuildContext context) {
    final dic = I18n.of(context)!.getDic(i18n_full_dic_acala, 'acala')!;

    final balancePair = pool!.tokens!
        .map((e) => AssetsUtils.tokenDataFromCurrencyId(plugin, e))
        .toList();
    final tokenPairView =
        balancePair.map((e) => PluginFmt.tokenView(e.symbol)).join('-');

    final taigaPoolInfo =
        plugin!.store!.earn.taigaPoolInfoMap[pool!.tokenNameId];

    var unstaked = false;
    var staked = false;
    var canClaim = false;
    final balance =
        AssetsUtils.getBalanceFromTokenNameId(plugin!, pool!.tokenNameId);
    if (Fmt.balanceInt(balance.amount) > BigInt.zero) {
      unstaked = true;
    }
    if (BigInt.parse(taigaPoolInfo?.userShares ?? "0") > BigInt.zero) {
      staked = true;
    }

    var claim = BigInt.zero;
    taigaPoolInfo?.reward.forEach((e) {
      claim += BigInt.parse(e);
    });
    if (claim > BigInt.zero) {
      canClaim = true;
    }

    var ratio = [];
    for (int i = 1; i < balancePair.length; i++) {
      if (Fmt.balanceDouble(pool!.balances![0], balancePair[0].decimals!) > 0) {
        ratio.add((Fmt.balanceDouble(
                    pool!.balances![i], balancePair[i].decimals!) /
                Fmt.balanceDouble(pool!.balances![0], balancePair[0].decimals!))
            .toStringAsFixed(3));
      } else {
        ratio.add("0.0");
      }
    }

    List<List<TokenBalanceData>> balancePairLine = [];
    for (int i = 0; i < balancePair.length; i++) {
      if (i + 1 >= balancePair.length) {
        balancePairLine.add([balancePair[i]]);
      } else {
        balancePairLine.add([balancePair[i], balancePair[i + 1]]);
      }
      i++;
    }
    balancePair.forEach((element) {});
    return RoundedPluginCard(
      margin: EdgeInsets.only(bottom: 16),
      padding: EdgeInsets.symmetric(vertical: 11),
      color: Color(0x19FFFFFF),
      child: Column(
        children: [
          Padding(
              padding: EdgeInsets.only(left: 11, right: 13, bottom: 11),
              child: Row(
                children: [
                  Container(
                    child: PluginTokenIcon(
                      balance.symbol!,
                      tokenIcons!,
                      size: 26,
                      bgColor: Color(0xFF9E98E7),
                    ),
                    margin: EdgeInsets.only(right: 12),
                  ),
                  Expanded(
                      child: Text(
                    tokenPairView,
                    style: Theme.of(context).textTheme.headline3?.copyWith(
                        color: Colors.white,
                        fontSize: UI.getTextSize(18, context)),
                  )),
                  Row(
                    children: [
                      Visibility(
                          visible: unstaked,
                          child: Padding(
                              padding: EdgeInsets.only(left: 4),
                              child: Image.asset(
                                "packages/polkawallet_plugin_acala/assets/images/unstaked.png",
                                width: 22,
                              ))),
                      Visibility(
                          visible: staked,
                          child: Padding(
                              padding: EdgeInsets.only(left: 4),
                              child: Image.asset(
                                "packages/polkawallet_plugin_acala/assets/images/staked_1.png",
                                width: 22,
                              ))),
                      Visibility(
                          visible: canClaim,
                          child: Padding(
                              padding: EdgeInsets.only(left: 4),
                              child: Image.asset(
                                "packages/polkawallet_plugin_acala/assets/images/rewards.png",
                                width: 22,
                              ))),
                    ],
                  )
                ],
              )),
          Container(
            padding: EdgeInsets.symmetric(vertical: 10, horizontal: 12),
            color: Color(0xFF494b4e),
            child: Column(
              children: balancePairLine.map((i) {
                final indexI = balancePairLine.indexOf(i);
                return Padding(
                    padding: EdgeInsets.only(
                        bottom: indexI + 1 >= balancePairLine.length ? 0 : 10),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        ...i.map((e) {
                          final index = i.indexOf(e);
                          return PluginInfoItem(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            title: PluginFmt.tokenView(e.symbol),
                            content:
                                "${Fmt.priceFloorFormatter(Fmt.balanceDouble(pool!.balances![indexI * 2 + index], e.decimals!))}",
                          );
                        }).toList(),
                        Visibility(
                            visible: indexI + 1 >= balancePairLine.length,
                            child: PluginInfoItem(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              title: dic['boot.ratio'],
                              content: '1 : ${ratio.join(" : ")}',
                            )),
                      ],
                    ));
              }).toList(),
            ),
          ),
          Padding(
              padding: EdgeInsets.only(left: 11, right: 13, top: 11),
              child: Row(
                children: [
                  Expanded(
                    child: PluginOutlinedButtonSmall(
                      content: dic['dex.removeLiquidity'],
                      color: Color(0xFFcdcdce),
                      active: true,
                      onPressed: () => Navigator.of(context).pushNamed(
                          TaigaWithdrawLiquidityPage.route,
                          arguments: {'poolId': pool?.tokenNameId}),
                    ),
                  ),
                  Expanded(
                    child: PluginOutlinedButtonSmall(
                      margin: EdgeInsets.all(0),
                      content: dic['dex.addLiquidity'],
                      color: PluginColorsDark.primary,
                      active: true,
                      onPressed: () => Navigator.of(context).pushNamed(
                          TaigaAddLiquidityPage.route,
                          arguments: {'poolId': pool?.tokenNameId}),
                    ),
                  ),
                ],
              )),
        ],
      ),
    );
  }
}

class _DexPoolCard extends StatelessWidget {
  _DexPoolCard({this.plugin, this.pool, this.poolAmount, this.tokenIcons});

  final PluginAcala? plugin;
  final DexPoolData? pool;
  final List? poolAmount;
  final Map<String, Widget>? tokenIcons;

  @override
  Widget build(BuildContext context) {
    final dic = I18n.of(context)!.getDic(i18n_full_dic_acala, 'acala')!;

    final balancePair = pool!.tokens!
        .map((e) => AssetsUtils.tokenDataFromCurrencyId(plugin, e))
        .toList();
    final tokenPairView =
        balancePair.map((e) => PluginFmt.tokenView(e.symbol)).join('-');

    double? amountLeft;
    double? amountRight;
    double ratio = 0;
    if (poolAmount != null) {
      amountLeft = Fmt.balanceDouble(
          poolAmount![0].toString(), balancePair[0].decimals!);
      amountRight = Fmt.balanceDouble(
          poolAmount![1].toString(), balancePair[1].decimals!);
      ratio = amountLeft > 0 ? amountRight / amountLeft : 0;
    }

    final poolInfo = plugin!.store!.earn.dexPoolInfoMap[pool!.tokenNameId];
    bool canClaim = false;
    (poolInfo?.reward?.incentive ?? []).forEach((e) {
      final amount = double.parse(e['amount']);
      if (amount > 0.001) {
        canClaim = true;
      }
    });

    bool unstaked = false;
    final balance =
        AssetsUtils.getBalanceFromTokenNameId(plugin!, pool!.tokenNameId);
    if (Fmt.balanceInt(balance.amount) > BigInt.zero) {
      unstaked = true;
    }

    return RoundedPluginCard(
      margin: EdgeInsets.only(bottom: 16),
      padding: EdgeInsets.symmetric(vertical: 11),
      color: Color(0x19FFFFFF),
      child: Column(
        children: [
          Padding(
              padding: EdgeInsets.only(left: 11, right: 13, bottom: 11),
              child: Row(
                children: [
                  Container(
                    child: PluginTokenIcon(
                        balancePair.map((e) => e.symbol).join('-'), tokenIcons!,
                        size: 26),
                    margin: EdgeInsets.only(right: 12),
                  ),
                  Expanded(
                      child: Text(
                    tokenPairView,
                    style: Theme.of(context).textTheme.headline3?.copyWith(
                        color: Colors.white,
                        fontSize: UI.getTextSize(18, context)),
                  )),
                  Row(
                    children: [
                      Visibility(
                          visible: unstaked,
                          child: Padding(
                              padding: EdgeInsets.only(left: 4),
                              child: Image.asset(
                                "packages/polkawallet_plugin_acala/assets/images/unstaked.png",
                                width: 22,
                              ))),
                      Visibility(
                          visible:
                              (poolInfo?.shares ?? BigInt.zero) != BigInt.zero,
                          child: Padding(
                              padding: EdgeInsets.only(left: 4),
                              child: Image.asset(
                                "packages/polkawallet_plugin_acala/assets/images/staked_1.png",
                                width: 22,
                              ))),
                      Visibility(
                          visible: canClaim,
                          child: Padding(
                              padding: EdgeInsets.only(left: 4),
                              child: Image.asset(
                                "packages/polkawallet_plugin_acala/assets/images/rewards.png",
                                width: 22,
                              ))),
                    ],
                  )
                ],
              )),
          Container(
            padding: EdgeInsets.symmetric(vertical: 10, horizontal: 12),
            color: Color(0xFF494b4e),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                    child: Column(
                  children: [
                    Text(
                      PluginFmt.tokenView(balancePair[0].symbol),
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: Colors.white, fontWeight: FontWeight.w600),
                    ),
                    NumberLoader(
                        margin: EdgeInsets.only(top: 8),
                        child: Text(
                          Fmt.priceFloor(amountLeft),
                          style: Theme.of(context)
                              .textTheme
                              .headlineMedium
                              ?.copyWith(color: Colors.white),
                        ),
                        isLoading: amountLeft == null),
                  ],
                )),
                Expanded(
                    child: Column(
                  children: [
                    Text(
                      PluginFmt.tokenView(balancePair[1].symbol),
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: Colors.white, fontWeight: FontWeight.w600),
                    ),
                    NumberLoader(
                        margin: EdgeInsets.only(top: 8),
                        child: Text(
                          Fmt.priceFloor(amountRight),
                          style: Theme.of(context)
                              .textTheme
                              .headlineMedium
                              ?.copyWith(color: Colors.white),
                        ),
                        isLoading: amountRight == null),
                  ],
                )),
                Expanded(
                    child: Column(
                  children: [
                    Text(
                      dic['boot.ratio']!,
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: Colors.white, fontWeight: FontWeight.w600),
                    ),
                    NumberLoader(
                        margin: EdgeInsets.only(top: 8),
                        child: Text(
                          '1 : ${ratio.toStringAsFixed(4)}',
                          style: Theme.of(context)
                              .textTheme
                              .headlineMedium
                              ?.copyWith(color: Colors.white),
                        ),
                        isLoading: ratio == 0),
                  ],
                )),
              ],
            ),
          ),
          Padding(
              padding: EdgeInsets.only(left: 11, right: 13, top: 11),
              child: Row(
                children: [
                  Expanded(
                    child: PluginOutlinedButtonSmall(
                      content: dic['dex.removeLiquidity'],
                      color: Color(0xFFcdcdce),
                      active: true,
                      onPressed: () => Navigator.of(context).pushNamed(
                          WithdrawLiquidityPage.route,
                          arguments: pool),
                    ),
                  ),
                  Expanded(
                    child: PluginOutlinedButtonSmall(
                      content: dic['dex.addLiquidity'],
                      margin: EdgeInsets.zero,
                      color: PluginColorsDark.primary,
                      active: true,
                      onPressed: () => Navigator.of(context).pushNamed(
                          AddLiquidityPage.route,
                          arguments: {'poolId': pool?.tokenNameId}),
                    ),
                  ),
                ],
              )),
        ],
      ),
    );
  }
}
