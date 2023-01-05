import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:polkawallet_plugin_acala/common/constants/index.dart';
import 'package:polkawallet_plugin_acala/pages/homaNew/homaHistoryPage.dart';
import 'package:polkawallet_plugin_acala/pages/homaNew/mintPage.dart';
import 'package:polkawallet_plugin_acala/pages/homaNew/redeemPage.dart';
import 'package:polkawallet_plugin_acala/polkawallet_plugin_acala.dart';
import 'package:polkawallet_plugin_acala/utils/assets.dart';
import 'package:polkawallet_plugin_acala/utils/format.dart';
import 'package:polkawallet_plugin_acala/utils/i18n/index.dart';
import 'package:polkawallet_sdk/storage/keyring.dart';
import 'package:polkawallet_sdk/utils/i18n.dart';
import 'package:polkawallet_ui/components/connectionChecker.dart';
import 'package:polkawallet_ui/components/txButton.dart';
import 'package:polkawallet_ui/components/v3/dialog.dart';
import 'package:polkawallet_ui/components/v3/plugin/pluginAccountInfoAction.dart';
import 'package:polkawallet_ui/components/v3/plugin/pluginButton.dart';
import 'package:polkawallet_ui/components/v3/plugin/pluginIconButton.dart';
import 'package:polkawallet_ui/components/v3/plugin/pluginPopLoadingWidget.dart';
import 'package:polkawallet_ui/components/v3/plugin/pluginScaffold.dart';
import 'package:polkawallet_ui/pages/txConfirmPage.dart';
import 'package:polkawallet_ui/utils/consts.dart';
import 'package:polkawallet_ui/utils/format.dart';
import 'package:polkawallet_ui/utils/index.dart';
import 'package:rive/rive.dart';

class HomaPage extends StatefulWidget {
  HomaPage(this.plugin, this.keyring);
  final PluginAcala plugin;
  final Keyring keyring;

  static const String route = '/acala/homa';

  @override
  _HomaPageState createState() => _HomaPageState();
}

class _HomaPageState extends State<HomaPage> {
  Timer? _timer;

  Future<void> _refreshData() async {
    widget.plugin.service!.assets.queryMarketPrices();
    widget.plugin.service!.gov.updateBestNumber();

    await widget.plugin.service!.homa.queryHomaEnv();
    widget.plugin.service!.homa.queryHomaPendingRedeem();

    _queryTaigaPoolInfo();

    if (_timer == null) {
      _timer = Timer.periodic(Duration(seconds: 20), (timer) {
        _refreshData();
      });
    }
  }

  Future<void> _queryTaigaPoolInfo() async {
    if (widget.plugin.store!.earn.taigaPoolInfoMap.length == 0) {
      final info = await widget.plugin.api!.earn
          .getTaigaPoolInfo(widget.keyring.current.address!);
      widget.plugin.store!.earn.setTaigaPoolInfo(info);
      final data = await widget.plugin.api!.earn.getTaigaTokenPairs();
      widget.plugin.store!.earn.setTaigaTokenPairs(data!);
    }
  }

  void _onCancelRedeem() {
    showCupertinoDialog(
      context: context,
      builder: (BuildContext context) {
        final dic = I18n.of(context)!.getDic(i18n_full_dic_acala, 'acala')!;
        return PolkawalletAlertDialog(
          title: Text(dic['homa.confirm']!),
          content: Text(dic['homa.redeem.hint']!),
          actions: <Widget>[
            PolkawalletActionSheetAction(
              child: Text(
                dic['homa.redeem.cancel']!,
                style: TextStyle(
                  color: Theme.of(context).unselectedWidgetColor,
                ),
              ),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            PolkawalletActionSheetAction(
              isDefaultAction: true,
              child: Text(dic['homa.confirm']!),
              onPressed: () {
                Navigator.of(context).pop();
                _onSubmit();
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _onSubmit() async {
    var params = [0, 0];
    var module = 'homaLite';
    var call = 'requestRedeem';
    var txDisplay = {};
    final res = (await Navigator.of(context).pushNamed(TxConfirmPage.route,
        arguments: TxConfirmParams(
          module: module,
          call: call,
          txTitle:
              "${I18n.of(context)!.getDic(i18n_full_dic_acala, 'acala')!['homa.redeem.cancel']}${I18n.of(context)!.getDic(i18n_full_dic_acala, 'acala')!['homa.redeem']}$relay_chain_token_symbol",
          txDisplay: txDisplay,
          params: params,
          isPlugin: true,
        ))) as Map?;

    if (res != null) {
      _refreshData();
    }
  }

  Future<void> _claimRedeem(BuildContext context, num claimable) async {
    final dic = I18n.of(context)!.getDic(i18n_full_dic_acala, 'acala')!;
    final res = await Navigator.of(context).pushNamed(
      TxConfirmPage.route,
      arguments: TxConfirmParams(
        module: 'homa',
        call: 'claimRedemption',
        txTitle: '${dic['homa.claim']} $relay_chain_token_symbol',
        txDisplay: {},
        txDisplayBold: {
          dic['loan.amount']!: Text(
            '${Fmt.priceFloor(claimable as double?, lengthMax: 8)} $relay_chain_token_symbol',
            style: Theme.of(context)
                .textTheme
                .headline1
                ?.copyWith(color: Colors.white),
          ),
        },
        params: [widget.keyring.current.address],
        isPlugin: true,
      ),
    );
    if (res != null) {
      _refreshData();
    }
  }

  @override
  void dispose() {
    if (_timer != null) {
      _timer!.cancel();
      _timer = null;
    }
    super.dispose();
  }

  @override
  Widget build(_) {
    return Observer(builder: (BuildContext context) {
      final dic = I18n.of(context)!.getDic(i18n_full_dic_acala, 'acala')!;
      final stakeSymbol = relay_chain_token_symbol;

      if (widget.plugin.sdk.api.connectedNode == null) {
        return PluginScaffold(
            appBar: PluginAppBar(
              title: Text('${dic['homa.title']} $stakeSymbol'),
              actions: [
                Container(
                  margin: EdgeInsets.only(right: 16),
                  child: PluginIconButton(
                    onPressed: () =>
                        Navigator.of(context).pushNamed(HomaHistoryPage.route),
                    icon: Image.asset(
                      'packages/polkawallet_plugin_acala/assets/images/history.png',
                      width: 16,
                    ),
                  ),
                )
              ],
            ),
            body: PluginPopLoadingContainer(
              loading: true,
              child:
                  ConnectionChecker(widget.plugin, onConnected: _refreshData),
            ));
      }

      final env = widget.plugin.store?.homa.env;
      final balances = AssetsUtils.getBalancePairFromTokenNameId(
          widget.plugin, [stakeSymbol, 'L$stakeSymbol']);
      final balanceStakeToken =
          Fmt.balanceDouble(balances[0].amount ?? '0', balances[0].decimals!);
      final balanceLiquidToken =
          Fmt.balanceDouble(balances[1].amount ?? '0', balances[1].decimals!);
      double unbonding = 0;
      (widget.plugin.store?.homa.userInfo?.unbondings ?? []).forEach((e) {
        unbonding += e['amount'];
      });
      final claimable =
          (widget.plugin.store?.homa.userInfo?.claimable ?? 0).toDouble();

      final paddingHorizontal = 16.0;
      final riveTop = 22.0;
      final riveWidget =
          MediaQuery.of(context).size.width - paddingHorizontal * 2;
      final riveHeight = riveWidget / 360 * 292;

      final aprValue = (env?.apy ?? 0) * 100;
      bool isRewardsOpen = false;
      double rewardApr = 0;
      final rewards =
          widget.plugin.store!.earn.incentives.loans?['L$stakeSymbol'];
      if ((rewards ?? []).length > 0) {
        rewards?.forEach((e) {
          if ((e.amount ?? 0) > 0) {
            isRewardsOpen = true;
            rewardApr = e.apr ?? 0;
          }
        });
      }

      final dexPools = widget.plugin.store!.earn.taigaPoolInfoMap;
      double taigaApr = 0;
      dexPools["sa://0"]?.apy.forEach((key, value) {
        taigaApr += value;
      });

      final aprStyle = Theme.of(context).textTheme.headline4?.copyWith(
          fontSize: UI.getTextSize(20, context),
          fontWeight: FontWeight.bold,
          height: 0.9,
          color: Colors.white);

      final redeemRequest = Fmt.balanceDouble(
          (widget.plugin.store?.homa.userInfo?.redeemRequest ?? {})['amount'] ??
              '0',
          balances[0].decimals!);

      return PluginScaffold(
        appBar: PluginAppBar(
          title: Text('${dic['homa.title']} $stakeSymbol'),
          actions: [
            Container(
              margin: EdgeInsets.only(right: 12),
              child: PluginIconButton(
                onPressed: () =>
                    Navigator.of(context).pushNamed(HomaHistoryPage.route),
                icon: Image.asset(
                  'packages/polkawallet_plugin_acala/assets/images/history.png',
                  width: 16,
                ),
              ),
            ),
            PluginAccountInfoAction(widget.keyring)
          ],
        ),
        body: Container(
            width: double.infinity,
            height: double.infinity,
            margin: EdgeInsets.only(top: 20),
            padding: EdgeInsets.symmetric(horizontal: paddingHorizontal),
            child: Column(
              children: [
                ConnectionChecker(widget.plugin, onConnected: _refreshData),
                Expanded(
                    child: SingleChildScrollView(
                        child: Stack(
                  children: [
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                            width: double.infinity,
                            height: riveHeight,
                            margin: EdgeInsets.only(top: riveTop),
                            child: RiveAnimation.asset(
                              'packages/polkawallet_plugin_acala/assets/images/new_file.riv',
                              animations: const [
                                'Animation 1',
                                'Animation 2',
                                'Animation 3',
                                'Animation 4'
                              ],
                            )),
                        Align(
                            alignment: Alignment.topRight,
                            child: Container(
                              height: 28,
                              decoration: BoxDecoration(
                                  image: DecorationImage(
                                image: AssetImage(
                                    'packages/polkawallet_plugin_acala/assets/images/homa_left_bg.png'),
                              )),
                              padding:
                                  EdgeInsets.only(left: 45, right: 15, top: 2),
                              child: Text(
                                  '1 L$stakeSymbol ≈ ${Fmt.priceFloor(env?.exchangeRate ?? 1, lengthMax: 2)} $stakeSymbol',
                                  style: Theme.of(context)
                                      .appBarTheme
                                      .titleTextStyle
                                      ?.copyWith(
                                          fontSize: UI.getTextSize(14, context),
                                          color: Colors.white)),
                            ))
                      ],
                    ),
                    Row(
                      children: [
                        Container(
                          height: 28,
                          alignment: Alignment.center,
                          color: Colors.white,
                          padding: EdgeInsets.symmetric(horizontal: 5),
                          child: Text(
                            "${dic['v3.total']!} L$stakeSymbol",
                            style: Theme.of(context)
                                .appBarTheme
                                .titleTextStyle
                                ?.copyWith(
                                    fontSize: UI.getTextSize(16, context),
                                    color: Color(0xFF292929)),
                          ),
                        ),
                        Container(
                          height: 28,
                          alignment: Alignment.center,
                          color: Color(0x33FFFFFF),
                          padding: EdgeInsets.symmetric(horizontal: 5),
                          child: Text(
                            '${Fmt.priceFloor(env?.totalLiquidity ?? 0, lengthMax: 2)}',
                            style: Theme.of(context)
                                .appBarTheme
                                .titleTextStyle
                                ?.copyWith(
                                    fontSize: UI.getTextSize(16, context),
                                    color: Colors.white),
                          ),
                        ),
                        Container(
                          color: PluginColorsDark.primary,
                          height: 28,
                          width: 3,
                          margin: EdgeInsets.symmetric(horizontal: 3),
                        ),
                        Container(
                            color: Color(0x7fFC8156), height: 28, width: 3)
                      ],
                    ),
                    Align(
                      alignment: Alignment.topRight,
                      child: Container(
                          margin: EdgeInsets.only(
                              top: riveTop + riveHeight * 0.18,
                              right: paddingHorizontal +
                                  riveWidget * 0.19 -
                                  PluginFmt.boundingTextSize(
                                              aprValue.toStringAsFixed(2) + '%',
                                              aprStyle)
                                          .width /
                                      2),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                'APY',
                                style: Theme.of(context)
                                    .textTheme
                                    .headline4
                                    ?.copyWith(color: Colors.white),
                              ),
                              Text(
                                aprValue.toStringAsFixed(2) + '%',
                                style: aprStyle,
                              )
                            ],
                          )),
                    ),
                    Align(
                      alignment: Alignment.topLeft,
                      child: Container(
                        margin:
                            EdgeInsets.only(top: riveTop + riveHeight * 0.65),
                        width: riveWidget * 0.34,
                        height: riveWidget * 0.34 / 236 * 176,
                        padding: EdgeInsets.zero,
                        decoration: BoxDecoration(
                            image: DecorationImage(
                          image: AssetImage(
                              'packages/polkawallet_plugin_acala/assets/images/homa_total_staked_bg.png'),
                        )),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              padding: EdgeInsets.symmetric(
                                  horizontal: 5, vertical: 2),
                              color: PluginColorsDark.primary,
                              child: Text(
                                dic['v3.totalStaked']!,
                                style: Theme.of(context)
                                    .textTheme
                                    .headline4
                                    ?.copyWith(
                                        color: Color(0xFF252629),
                                        fontWeight: FontWeight.w600),
                              ),
                            ),
                            Container(
                                padding: EdgeInsets.fromLTRB(5, 4, 0, 0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      '${Fmt.priceFloorFormatter(env?.totalStaking ?? 0, lengthMax: 4)} $stakeSymbol',
                                      style: Theme.of(context)
                                          .textTheme
                                          .headline5
                                          ?.copyWith(color: Colors.white),
                                    ),
                                    Padding(
                                        padding: EdgeInsets.only(left: 8),
                                        child: Text(
                                          '≈ \$${Fmt.priceFloorFormatter((widget.plugin.store?.assets.marketPrices[stakeSymbol] ?? 0) * (env?.totalStaking ?? 0), lengthMax: 2)}',
                                          style: Theme.of(context)
                                              .textTheme
                                              .headline5
                                              ?.copyWith(color: Colors.white),
                                        ))
                                  ],
                                ))
                          ],
                        ),
                      ),
                    ),
                    Align(
                      alignment: Alignment.topLeft,
                      child: Container(
                        margin: EdgeInsets.only(top: riveTop + riveHeight + 22),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              width: 108,
                              height: 30,
                              padding: EdgeInsets.only(left: 5, top: 3),
                              decoration: BoxDecoration(
                                  image: DecorationImage(
                                image: AssetImage(
                                    'packages/polkawallet_plugin_acala/assets/images/homa_my_stats_bg.png'),
                              )),
                              child: Text(
                                dic['v3.myStats']!,
                                style: Theme.of(context)
                                    .textTheme
                                    .headline4
                                    ?.copyWith(
                                        color: Color(0xFF212123),
                                        fontWeight: FontWeight.w600),
                              ),
                            ),
                            Container(
                              width: double.infinity,
                              margin: EdgeInsets.only(bottom: 16),
                              padding: EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 19),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.only(
                                    topRight: Radius.circular(8),
                                    bottomLeft: Radius.circular(8),
                                    bottomRight: Radius.circular(8)),
                                border: Border.all(
                                    color: Colors.white.withAlpha(97),
                                    width: 1.5),
                              ),
                              child: Row(
                                children: [
                                  Expanded(
                                      child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Container(
                                        width: double.infinity,
                                        padding: EdgeInsets.only(
                                            left: 10, top: 6, bottom: 6),
                                        decoration: ShapeDecoration(
                                          color: Color(0x1AFFFFFF),
                                          shape: BeveledRectangleBorder(
                                              borderRadius: BorderRadius.only(
                                                  topLeft:
                                                      Radius.circular(10))),
                                        ),
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              "L$stakeSymbol:",
                                              style: Theme.of(context)
                                                  .textTheme
                                                  .headline4
                                                  ?.copyWith(
                                                      color: Colors.white,
                                                      fontWeight:
                                                          FontWeight.w600),
                                            ),
                                            Padding(
                                                padding:
                                                    EdgeInsets.only(top: 5),
                                                child: Text(
                                                  Fmt.priceFloorFormatter(
                                                      balanceLiquidToken,
                                                      lengthMax: 4),
                                                  style: Theme.of(context)
                                                      .textTheme
                                                      .headline4
                                                      ?.copyWith(
                                                          color: Colors.white),
                                                ))
                                          ],
                                        ),
                                      ),
                                      Container(
                                        width: double.infinity,
                                        padding: EdgeInsets.only(
                                            left: 10, top: 6, bottom: 6),
                                        margin: EdgeInsets.only(top: 15),
                                        decoration: ShapeDecoration(
                                          color: Color(0x1AFFFFFF),
                                          shape: BeveledRectangleBorder(
                                              borderRadius: BorderRadius.only(
                                                  topLeft:
                                                      Radius.circular(10))),
                                        ),
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              dic['v3.unbonding']!,
                                              style: Theme.of(context)
                                                  .textTheme
                                                  .headline4
                                                  ?.copyWith(
                                                      color: Colors.white,
                                                      fontWeight:
                                                          FontWeight.w600),
                                            ),
                                            Padding(
                                                padding:
                                                    EdgeInsets.only(top: 5),
                                                child: Text(
                                                  "${Fmt.priceFloorFormatter(unbonding, lengthMax: 4)} $stakeSymbol",
                                                  style: Theme.of(context)
                                                      .textTheme
                                                      .headline4
                                                      ?.copyWith(
                                                          color: Colors.white),
                                                ))
                                          ],
                                        ),
                                      )
                                    ],
                                  )),
                                  Container(
                                    width: 46,
                                  ),
                                  Expanded(
                                      child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Container(
                                        width: double.infinity,
                                        padding: EdgeInsets.only(
                                            left: 10, top: 6, bottom: 6),
                                        decoration: ShapeDecoration(
                                          color: Color(0x1AFFFFFF),
                                          shape: BeveledRectangleBorder(
                                              borderRadius: BorderRadius.only(
                                                  topLeft:
                                                      Radius.circular(10))),
                                        ),
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              "$stakeSymbol:",
                                              style: Theme.of(context)
                                                  .textTheme
                                                  .headline4
                                                  ?.copyWith(
                                                      color: Colors.white,
                                                      fontWeight:
                                                          FontWeight.w600),
                                            ),
                                            Padding(
                                                padding:
                                                    EdgeInsets.only(top: 5),
                                                child: Text(
                                                  Fmt.priceFloorFormatter(
                                                      balanceStakeToken,
                                                      lengthMax: 4),
                                                  style: Theme.of(context)
                                                      .textTheme
                                                      .headline4
                                                      ?.copyWith(
                                                          color: Colors.white),
                                                ))
                                          ],
                                        ),
                                      ),
                                      GestureDetector(
                                          onTap: () {
                                            if (claimable > 0) {
                                              _claimRedeem(context, claimable);
                                            }
                                          },
                                          child: Container(
                                            width: double.infinity,
                                            padding: EdgeInsets.only(
                                                left: 10, top: 6, bottom: 6),
                                            margin: EdgeInsets.only(top: 15),
                                            decoration: ShapeDecoration(
                                              color: PluginColorsDark.primary,
                                              shape: BeveledRectangleBorder(
                                                  borderRadius:
                                                      BorderRadius.only(
                                                          topLeft:
                                                              Radius.circular(
                                                                  10))),
                                            ),
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  dic['v3.claim']!,
                                                  style: Theme.of(context)
                                                      .textTheme
                                                      .headline4
                                                      ?.copyWith(
                                                          color: claimable > 0
                                                              ? Colors.black
                                                              : Colors.white,
                                                          fontWeight:
                                                              FontWeight.w600),
                                                ),
                                                Padding(
                                                    padding:
                                                        EdgeInsets.only(top: 5),
                                                    child: Text(
                                                      "${Fmt.priceFloorFormatter(claimable, lengthMax: 4)} $stakeSymbol",
                                                      style: Theme.of(context)
                                                          .textTheme
                                                          .headline4
                                                          ?.copyWith(
                                                              color: claimable >
                                                                      0
                                                                  ? Colors.black
                                                                  : Colors
                                                                      .white),
                                                    ))
                                              ],
                                            ),
                                          ))
                                    ],
                                  ))
                                ],
                              ),
                            ),
                            Visibility(
                                visible: redeemRequest > 0,
                                child: Padding(
                                    padding: EdgeInsets.only(bottom: 16),
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Row(
                                          children: [
                                            Padding(
                                                padding:
                                                    EdgeInsets.only(right: 8),
                                                child: RedeemRequestIcon()),
                                            Text(
                                              dic['homa.RedeemRequest']!,
                                              style: Theme.of(context)
                                                  .textTheme
                                                  .headline4
                                                  ?.copyWith(
                                                      color: Colors.white,
                                                      fontWeight:
                                                          FontWeight.w600),
                                            )
                                          ],
                                        ),
                                        Text(
                                          "${Fmt.priceFloor(redeemRequest, lengthMax: 4)} L$stakeSymbol",
                                          style: Theme.of(context)
                                              .textTheme
                                              .headline4
                                              ?.copyWith(
                                                  color: Colors.white,
                                                  fontWeight: FontWeight.w400),
                                        )
                                      ],
                                    ))),
                            Visibility(
                                visible: isRewardsOpen,
                                child: Container(
                                  margin: EdgeInsets.only(bottom: 16),
                                  child: RichText(
                                      text: TextSpan(
                                          text: dic['event.vault.rewards']!,
                                          style: Theme.of(context)
                                              .textTheme
                                              .headline4
                                              ?.copyWith(
                                                  color: Colors.white,
                                                  fontWeight: FontWeight.w400),
                                          children: [
                                        TextSpan(
                                            text:
                                                " ${(aprValue + rewardApr * 100 > taigaApr * 100 ? aprValue + rewardApr * 100 : taigaApr * 100).toStringAsFixed(2)}%!",
                                            style: Theme.of(context)
                                                .textTheme
                                                .headline4
                                                ?.copyWith(
                                                    color: PluginColorsDark
                                                        .primary,
                                                    fontWeight:
                                                        FontWeight.w400)),
                                      ])),
                                )),
                          ],
                        ),
                      ),
                    )
                  ],
                ))),
                Container(
                    margin: EdgeInsets.only(bottom: 34),
                    child: Row(
                      children: [
                        Expanded(
                            child: PluginButton(
                          title: '${dic['homa.redeem']} $stakeSymbol',
                          onPressed: () => Navigator.of(context)
                              .pushNamed(RedeemPage.route)
                              .then((value) {
                            if (value != null) {
                              _refreshData();
                            }
                          }),
                        )),
                        Container(
                          width: 16,
                        ),
                        Expanded(
                            child: PluginButton(
                          title: '${dic['homa.mint']} L$stakeSymbol',
                          backgroundColor: (env?.totalStaking ?? 0) <
                                  (env?.stakingSoftCap ?? 0)
                              ? null
                              : Color(0x54FFFFFF),
                          onPressed: (env?.totalStaking ?? 0) <
                                  (env?.stakingSoftCap ?? 0)
                              ? () async {
                                  // if (!(await _confirmMint())) return;

                                  Navigator.of(context)
                                      .pushNamed(MintPage.route, arguments: {
                                    "selectMethod": true
                                  }).then((value) {
                                    if (value != null) {
                                      _refreshData();
                                    }
                                  });
                                }
                              : null,
                        ))
                      ],
                    ))
              ],
            )),
      );
    });
  }
}

class RedeemRequestIcon extends StatefulWidget {
  RedeemRequestIcon({Key? key}) : super(key: key);

  @override
  _RedeemRequestIconState createState() => _RedeemRequestIconState();
}

class _RedeemRequestIconState extends State<RedeemRequestIcon>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Function(AnimationStatus) _listener;

  @override
  void initState() {
    _controller = AnimationController(
        vsync: this, duration: Duration(milliseconds: 1000));
    _controller.forward();

    _listener = (status) {
      if (status == AnimationStatus.completed) {
        _controller.reset();
        _controller.forward();
      }
    };
    super.initState();
  }

  @override
  void dispose() {
    _controller.removeStatusListener(_listener);
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 20,
      height: 20,
      child: RotationTransition(
        child: Image.asset(
          "packages/polkawallet_plugin_acala/assets/images/homa_redeem_request.png",
          width: 20,
        ),
        turns: _controller..addStatusListener(_listener),
      ),
    );
  }
}
