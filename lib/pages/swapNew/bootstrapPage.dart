import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:polkawallet_plugin_acala/api/types/dexPoolInfoData.dart';
import 'package:polkawallet_plugin_acala/common/constants/index.dart';
import 'package:polkawallet_plugin_acala/pages/swapNew/swapTokenInput.dart';
import 'package:polkawallet_plugin_acala/polkawallet_plugin_acala.dart';
import 'package:polkawallet_plugin_acala/utils/assets.dart';
import 'package:polkawallet_plugin_acala/utils/format.dart';
import 'package:polkawallet_plugin_acala/utils/i18n/index.dart';
import 'package:polkawallet_sdk/storage/keyring.dart';
import 'package:polkawallet_sdk/utils/i18n.dart';
import 'package:polkawallet_ui/components/infoItemRow.dart';
import 'package:polkawallet_ui/components/v3/plugin/pluginInfoItem.dart';
import 'package:polkawallet_ui/components/v3/plugin/pluginOutlinedButtonSmall.dart';
import 'package:polkawallet_ui/components/v3/plugin/pluginScaffold.dart';
import 'package:polkawallet_ui/components/v3/plugin/pluginTagCard.dart';
import 'package:polkawallet_ui/components/v3/plugin/pluginTxButton.dart';
import 'package:polkawallet_ui/utils/format.dart';
import 'package:polkawallet_ui/utils/index.dart';

class BootstrapPage extends StatefulWidget {
  BootstrapPage(this.plugin, this.keyring);
  final PluginAcala plugin;
  final Keyring keyring;

  static const String route = '/acala/dex/bootstrap';

  @override
  _BootstrapPageState createState() => _BootstrapPageState();
}

class _BootstrapPageState extends State<BootstrapPage> {
  final GlobalKey<RefreshIndicatorState> _refreshKey =
      new GlobalKey<RefreshIndicatorState>();

  final TextEditingController _amountLeftCtrl = new TextEditingController();
  final TextEditingController _amountRightCtrl = new TextEditingController();

  int _addTab = 0;

  List? _userProvisioning;

  String? _leftAmountError;
  String? _rightAmountError;
  Timer? _delayTimer;

  Future<void> _queryData() async {
    final pools = await widget.plugin.api!.swap.getBootstraps();
    final DexPoolData args =
        ModalRoute.of(context)!.settings.arguments as DexPoolData;
    final poolIndex =
        pools.indexWhere((element) => args.tokenNameId == element.tokenNameId);
    if (poolIndex < 0) {
      Navigator.of(context).pop(true);
      return;
    }
    widget.plugin.store!.earn.setBootstraps(pools);

    final List res = await Future.wait([
      widget.plugin.sdk.webView!.evalJavascript(
          'api.query.dex.provisioningPool(${jsonEncode(args.tokens)}, "${widget.keyring.current.address}")'),
      widget.plugin.service!.assets.queryMarketPrices(),
    ]);

    if (mounted) {
      setState(() {
        _userProvisioning = res[0];
      });
    }
  }

  void _onAmountChange(int index, String value) {
    final dic = I18n.of(context)!.getDic(i18n_full_dic_acala, 'common');
    final DexPoolData args =
        ModalRoute.of(context)!.settings.arguments as DexPoolData;
    final balancePair = args.tokens!
        .map((e) => AssetsUtils.tokenDataFromCurrencyId(widget.plugin, e))
        .toList();
    final balance = balancePair[index];

    final v = value.trim();
    String? error = Fmt.validatePrice(v, context);

    if (error == null) {
      final input = double.parse(v);
      final DexPoolData pool =
          ModalRoute.of(context)!.settings.arguments as DexPoolData;
      final min = Fmt.balanceDouble(
          pool.provisioning!.minContribution![index].toString(),
          balance.decimals!);
      if (input < min) {
        error = '${dic!['min']} ${Fmt.priceCeil(min, lengthMax: 6)}';
      } else if (double.parse(v) >
          Fmt.bigIntToDouble(
              Fmt.balanceInt(balance.amount ?? '0'), balance.decimals!)) {
        error = dic!['amount.low'];
      }
    }

    // update pool info while amount changes
    if (_delayTimer != null) {
      _delayTimer!.cancel();
    }
    _delayTimer = Timer(Duration(milliseconds: 500), () {
      widget.plugin.service!.earn.getBootstraps();
    });

    if (mounted) {
      if (index == 0 && _leftAmountError != error) {
        setState(() {
          _leftAmountError = error;
        });
      } else if (index == 1 && _rightAmountError != error) {
        setState(() {
          _rightAmountError = error;
        });
      }
    }
  }

  Future<TxConfirmParams?> _onSubmit() async {
    if (_addTab != 1 && _amountLeftCtrl.text.isEmpty) {
      setState(() {
        _leftAmountError = Fmt.validatePrice(_amountLeftCtrl.text, context);
      });
    }
    if (_addTab != 0 && _amountRightCtrl.text.isEmpty) {
      setState(() {
        _rightAmountError = Fmt.validatePrice(_amountRightCtrl.text, context);
      });
    }
    if (_leftAmountError != null || _rightAmountError != null) {
      return null;
    }

    final dic = I18n.of(context)!.getDic(i18n_full_dic_acala, 'acala')!;
    final DexPoolData pool =
        ModalRoute.of(context)!.settings.arguments as DexPoolData;
    final balancePair = pool.tokens!
        .map((e) => AssetsUtils.tokenDataFromCurrencyId(widget.plugin, e))
        .toList();

    final left = _amountLeftCtrl.text.trim();
    final right = _amountRightCtrl.text.trim();
    final leftAmount = left.isEmpty ? '0' : left;
    final rightAmount = right.isEmpty ? '0' : right;
    return TxConfirmParams(
        txTitle: dic['boot.provision.add'],
        module: 'dex',
        call: 'addProvision',
        txDisplay: {
          dic['earn.pool']: '${balancePair[0].symbol}-${balancePair[1].symbol}',
        },
        txDisplayBold: {
          "Token 1": Text(
            '$leftAmount ${balancePair[0].symbol}',
            style: Theme.of(context)
                .textTheme
                .headline1
                ?.copyWith(color: Colors.white),
          ),
          "Token 2": Text(
            '$rightAmount ${balancePair[1].symbol}',
            style: Theme.of(context)
                .textTheme
                .headline1
                ?.copyWith(color: Colors.white),
          ),
        },
        params: [
          pool.tokens![0],
          pool.tokens![1],
          Fmt.tokenInt(leftAmount, balancePair[0].decimals!).toString(),
          Fmt.tokenInt(rightAmount, balancePair[1].decimals!).toString(),
        ],
        isPlugin: true);
  }

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _refreshKey.currentState!.show();
    });
  }

  @override
  void dispose() {
    _amountLeftCtrl.dispose();
    _amountRightCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final dic = I18n.of(context)!.getDic(i18n_full_dic_acala, 'acala');

    final DexPoolData? args =
        ModalRoute.of(context)!.settings.arguments as DexPoolData?;
    return Observer(builder: (_) {
      final poolIndex = widget.plugin.store!.earn.bootstraps
          .indexWhere((e) => e.tokenNameId == args!.tokenNameId);
      if (poolIndex < 0) {
        return PluginScaffold(
            appBar: PluginAppBar(
                title: Text('${dic!['boot.title']}'), centerTitle: true),
            body: Container());
      }
      final pool = widget.plugin.store!.earn.bootstraps[poolIndex];
      final balancePair = pool.tokens!
          .map((e) => AssetsUtils.tokenDataFromCurrencyId(widget.plugin, e))
          .toList();
      final pairView =
          balancePair.map((e) => PluginFmt.tokenView(e.symbol)).toList();

      final nowLeft = Fmt.balanceDouble(
          pool.provisioning!.accumulatedProvision![0].toString(),
          balancePair[0].decimals!);
      final nowRight = Fmt.balanceDouble(
          pool.provisioning!.accumulatedProvision![1].toString(),
          balancePair[1].decimals!);
      final myLeft = Fmt.balanceDouble(
          _userProvisioning != null ? _userProvisioning![0].toString() : '0',
          balancePair[0].decimals!);
      final myRight = Fmt.balanceDouble(
          _userProvisioning != null ? _userProvisioning![1].toString() : '0',
          balancePair[1].decimals!);
      final poolInfo =
          PluginFmt.calcLiquidityShare([nowLeft, nowRight], [myLeft, myRight]);

      final addLeft = double.parse(_amountLeftCtrl.text.trim().isEmpty
          ? '0'
          : _amountLeftCtrl.text.trim());
      final addRight = double.parse(_amountRightCtrl.text.trim().isEmpty
          ? '0'
          : _amountRightCtrl.text.trim());
      final poolInfoAfter = PluginFmt.calcLiquidityShare(
          [nowLeft + addLeft, nowRight + addRight], [addLeft, addRight]);

      final estShareLabel = '${dic!['boot.my.est']} ${dic['boot.my.share']}';
      final estTokenLabel = '${dic['boot.my.est']} LP Tokens';

      final ratio =
          nowLeft > 0 ? (nowRight + addRight) / (nowLeft + addLeft) : 1.0;
      final ratioView1 =
          '1 ${pairView[0]} : ${Fmt.priceCeil(ratio, lengthMax: 6)} ${pairView[1]}';
      String ratioView2 = '';
      final nativeToken = widget.plugin.networkState.tokenSymbol![0];
      final relayChainToken = relay_chain_token_symbol;
      if (balancePair.map((e) => e.symbol).join('-').toUpperCase() ==
          '$nativeToken-$relayChainToken') {
        final relayChainTokenPrice =
            widget.plugin.store!.assets.marketPrices[relayChainToken];
        final priceView = relayChainTokenPrice == null
            ? '--.--'
            : Fmt.priceFloor(relayChainTokenPrice * ratio);
        ratioView2 += '1 ${pairView[0]} ≈ \$$priceView';
      }

      return PluginScaffold(
        appBar: PluginAppBar(
            title: Text('${pairView.join('-')} ${dic['boot.title']}'),
            centerTitle: true),
        body: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: RefreshIndicator(
                  color: Colors.black,
                  backgroundColor: Colors.white,
                  key: _refreshKey,
                  onRefresh: _queryData,
                  child: ListView(
                    padding: EdgeInsets.all(16),
                    children: [
                      PluginTagCard(
                        titleTag: dic['boot.my']!,
                        child: Column(
                          children: [
                            Container(
                                width: double.infinity,
                                padding: EdgeInsets.symmetric(vertical: 17),
                                decoration: BoxDecoration(
                                    color: Color(0xFF494b4e),
                                    borderRadius: BorderRadius.only(
                                        topRight: Radius.circular(8))),
                                alignment: Alignment.center,
                                child: Text(
                                  Fmt.priceFloor(myLeft) +
                                      '${pairView[0]} + ' +
                                      Fmt.priceFloor(myRight) +
                                      pairView[1],
                                  style: Theme.of(context)
                                      .textTheme
                                      .headline3
                                      ?.copyWith(
                                          color: Colors.white,
                                          fontSize:
                                              UI.getTextSize(24, context)),
                                )),
                            Container(
                              margin: EdgeInsets.only(top: 6, bottom: 10),
                              child: Row(
                                children: [
                                  PluginInfoItem(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.center,
                                    title: estShareLabel,
                                    content: Fmt.ratio(poolInfo.ratio),
                                    titleStyle: Theme.of(context)
                                        .textTheme
                                        .headline5
                                        ?.copyWith(color: Colors.white),
                                    style: Theme.of(context)
                                        .textTheme
                                        .headline4
                                        ?.copyWith(
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold),
                                  ),
                                  PluginInfoItem(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.center,
                                      title: estTokenLabel,
                                      content: Fmt.priceFloor(poolInfo.lp,
                                          lengthMax: 6),
                                      titleStyle: Theme.of(context)
                                          .textTheme
                                          .headline5
                                          ?.copyWith(color: Colors.white),
                                      style: Theme.of(context)
                                          .textTheme
                                          .headline4
                                          ?.copyWith(
                                              color: Colors.white,
                                              fontWeight: FontWeight.bold))
                                ],
                              ),
                            )
                          ],
                        ),
                      ),
                      PluginTagCard(
                        titleTag: dic['boot.provision.add']!,
                        padding: EdgeInsets.all(16),
                        margin: EdgeInsets.only(top: 16),
                        radius: Radius.circular(8),
                        backgroundColor: Color(0xFF494b4e),
                        child: Column(
                          children: [
                            Container(
                              margin: EdgeInsets.only(bottom: 8),
                              child: Row(
                                children: [
                                  PluginOutlinedButtonSmall(
                                    content: pairView[0],
                                    padding: EdgeInsets.symmetric(
                                        vertical: 2, horizontal: 10),
                                    activeTextcolor: Colors.white,
                                    unActiveTextcolor: Colors.white,
                                    color: Color(0xFFFF7849),
                                    active: _addTab == 0,
                                    onPressed: () {
                                      if (_addTab != 0) {
                                        setState(() {
                                          _addTab = 0;
                                          _amountRightCtrl.text = '';
                                          _rightAmountError = null;
                                        });
                                      }
                                    },
                                  ),
                                  PluginOutlinedButtonSmall(
                                    content: pairView[1],
                                    padding: EdgeInsets.symmetric(
                                        vertical: 2, horizontal: 10),
                                    activeTextcolor: Colors.white,
                                    unActiveTextcolor: Colors.white,
                                    color: Color(0xFFFF7849),
                                    active: _addTab == 1,
                                    onPressed: () {
                                      if (_addTab != 1) {
                                        setState(() {
                                          _addTab = 1;
                                          _amountLeftCtrl.text = '';
                                          _leftAmountError = null;
                                        });
                                      }
                                    },
                                  ),
                                  PluginOutlinedButtonSmall(
                                    content: '${pairView[0]} + ${pairView[1]}',
                                    padding: EdgeInsets.symmetric(
                                        vertical: 2, horizontal: 10),
                                    activeTextcolor: Colors.white,
                                    unActiveTextcolor: Colors.white,
                                    color: Color(0xFFFF7849),
                                    active: _addTab == 2,
                                    onPressed: () {
                                      if (_addTab != 2) {
                                        setState(() {
                                          _addTab = 2;
                                        });
                                      }
                                    },
                                  )
                                ],
                              ),
                            ),
                            Container(
                              child: Stack(
                                alignment: Alignment.center,
                                children: [
                                  Column(
                                    children: [
                                      Visibility(
                                          visible: _addTab != 1,
                                          child: Container(
                                            margin: EdgeInsets.only(top: 8),
                                            child: SwapTokenInput(
                                              title: dic['earn.add'],
                                              inputCtrl: _amountLeftCtrl,
                                              balance: balancePair[0],
                                              color: Color(0xFF3a3d40),
                                              borderRadius: _addTab == 2
                                                  ? BorderRadius.only(
                                                      topLeft:
                                                          Radius.circular(6),
                                                      topRight:
                                                          Radius.circular(6))
                                                  : const BorderRadius.all(
                                                      Radius.circular(6)),
                                              tokenIconsMap:
                                                  widget.plugin.tokenIcons,
                                              onInputChange: (v) =>
                                                  _onAmountChange(0, v),
                                              onClear: () {
                                                setState(() {
                                                  _amountLeftCtrl.text = '';
                                                });
                                                _onAmountChange(0, '0');
                                              },
                                            ),
                                          )),
                                      Visibility(
                                          visible: _addTab != 0,
                                          child: Container(
                                            margin: EdgeInsets.only(
                                                top: _addTab == 2 ? 0 : 8),
                                            child: SwapTokenInput(
                                              title: dic['earn.add'],
                                              color: _addTab == 2
                                                  ? Color(0xFF595a5d)
                                                  : Color(0xFF3a3d40),
                                              borderRadius: _addTab == 2
                                                  ? BorderRadius.only(
                                                      bottomLeft:
                                                          Radius.circular(6),
                                                      bottomRight:
                                                          Radius.circular(6))
                                                  : const BorderRadius.all(
                                                      Radius.circular(6)),
                                              inputCtrl: _amountRightCtrl,
                                              balance: balancePair[1],
                                              tokenIconsMap:
                                                  widget.plugin.tokenIcons,
                                              onInputChange: (v) =>
                                                  _onAmountChange(1, v),
                                              onClear: () {
                                                setState(() {
                                                  _amountRightCtrl.text = '';
                                                });
                                                _onAmountChange(1, '0');
                                              },
                                            ),
                                          )),
                                    ],
                                  ),
                                  Visibility(
                                      visible: _addTab == 2,
                                      child: Padding(
                                        padding: EdgeInsets.only(top: 7),
                                        child: Icon(Icons.add,
                                            color: Colors.white),
                                      )),
                                ],
                              ),
                            ),
                            ErrorMessage(_leftAmountError ?? _rightAmountError),
                            Container(
                              margin: EdgeInsets.only(top: 6),
                              child: Row(
                                children: [
                                  PluginInfoItem(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.center,
                                    title: ratioView1,
                                    content: ratioView2,
                                    style: Theme.of(context)
                                        .textTheme
                                        .headline5
                                        ?.copyWith(color: Colors.white),
                                    titleStyle: Theme.of(context)
                                        .textTheme
                                        .headline5
                                        ?.copyWith(color: Colors.white),
                                  )
                                ],
                              ),
                            ),
                            Container(
                              margin: EdgeInsets.only(top: 3),
                              child: InfoItemRow(
                                estShareLabel,
                                '+${Fmt.ratio(poolInfoAfter.ratio)}',
                                labelStyle: Theme.of(context)
                                    .textTheme
                                    .headline5
                                    ?.copyWith(color: Colors.white),
                                contentStyle: Theme.of(context)
                                    .textTheme
                                    .headline5
                                    ?.copyWith(color: Colors.white),
                              ),
                            ),
                            InfoItemRow(estTokenLabel,
                                '+${Fmt.priceFloor(poolInfoAfter.lp, lengthMax: 6)}',
                                labelStyle: Theme.of(context)
                                    .textTheme
                                    .headline5
                                    ?.copyWith(color: Colors.white),
                                contentStyle: Theme.of(context)
                                    .textTheme
                                    .headline5
                                    ?.copyWith(color: Colors.white)),
                          ],
                        ),
                      )
                    ],
                  ),
                ),
              ),
              Container(
                margin: EdgeInsets.all(16),
                child: PluginTxButton(
                  text: dic['boot.provision.add'],
                  getTxParams: _onSubmit,
                  onFinish: (res) {
                    if (res != null) {
                      _refreshKey.currentState!.show();
                    }
                  },
                ),
              ),
            ],
          ),
        ),
      );
    });
  }
}

class ErrorMessage extends StatelessWidget {
  ErrorMessage(this.error, {this.margin, this.isRight = false});
  final error;
  final EdgeInsetsGeometry? margin;
  final bool isRight;
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: error == null
          ? EdgeInsets.zero
          : margin ?? EdgeInsets.only(left: 16, top: 4),
      child: error == null
          ? null
          : Row(children: [
              Expanded(
                  child: Text(
                error,
                textAlign: isRight ? TextAlign.right : TextAlign.left,
                style: TextStyle(
                    fontSize: UI.getTextSize(12, context), color: Colors.red),
              ))
            ]),
    );
  }
}
