import 'dart:async';
import 'dart:convert';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:polkawallet_plugin_acala/api/types/dexPoolInfoData.dart';
import 'package:polkawallet_plugin_acala/pages/swap/swapTokenInput.dart';
import 'package:polkawallet_plugin_acala/polkawallet_plugin_acala.dart';
import 'package:polkawallet_plugin_acala/utils/format.dart';
import 'package:polkawallet_plugin_acala/utils/i18n/index.dart';
import 'package:polkawallet_sdk/plugin/store/balances.dart';
import 'package:polkawallet_sdk/storage/keyring.dart';
import 'package:polkawallet_sdk/utils/i18n.dart';
import 'package:polkawallet_ui/components/infoItem.dart';
import 'package:polkawallet_ui/components/infoItemRow.dart';
import 'package:polkawallet_ui/components/outlinedButtonSmall.dart';
import 'package:polkawallet_ui/components/roundedCard.dart';
import 'package:polkawallet_ui/components/txButton.dart';
import 'package:polkawallet_ui/utils/format.dart';

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
  final _leftFocusNode = FocusNode();
  final _rightFocusNode = FocusNode();

  int _addTab = 0;

  List _userProvisioning;

  String _leftAmountError;
  String _rightAmountError;
  Timer _delayTimer;

  Future<void> _queryUserProvisioning() async {
    widget.plugin.service.earn.getBootstraps();

    final DexPoolData pool = ModalRoute.of(context).settings.arguments;
    final res = await widget.plugin.sdk.webView.evalJavascript(
        'api.query.dex.provisioningPool(${jsonEncode(pool.tokens)}, "${widget.keyring.current.address}")');
    if (mounted) {
      setState(() {
        _userProvisioning = res;
      });
    }
  }

  void _onAmountChange(int index, TokenBalanceData balance, String value) {
    final dic = I18n.of(context).getDic(i18n_full_dic_acala, 'common');

    final v = value.trim();
    String error;
    try {
      if (v.isEmpty || double.parse(v) == 0) {
        error = dic['amount.error'];
      }
    } catch (err) {
      error = dic['amount.error'];
    }
    if (error == null) {
      final input = double.parse(v);
      final DexPoolData pool = ModalRoute.of(context).settings.arguments;
      final min = Fmt.balanceDouble(
          pool.provisioning.minContribution[index].toString(),
          balance.decimals);
      if (input < min) {
        error = '${dic['min']} ${Fmt.priceCeil(min, lengthMax: 6)}';
      } else if (double.parse(v) >
          Fmt.bigIntToDouble(
              Fmt.balanceInt(balance?.amount ?? '0'), balance.decimals)) {
        error = dic['amount.low'];
      }
    }

    // update pool info while amount changes
    if (_delayTimer != null) {
      _delayTimer.cancel();
    }
    _delayTimer = Timer(Duration(milliseconds: 500), () {
      widget.plugin.service.earn.getBootstraps();
    });

    if (mounted) {
      if (index == 0 && _leftAmountError != error) {
        setState(() {
          _leftAmountError = error;
        });
      } else if (_rightAmountError != error) {
        setState(() {
          _rightAmountError = error;
        });
      }
    }
  }

  Future<TxConfirmParams> _onSubmit() async {
    final dicCommon = I18n.of(context).getDic(i18n_full_dic_acala, 'common');
    if (_addTab != 1 && _amountLeftCtrl.text.isEmpty) {
      setState(() {
        _leftAmountError = dicCommon['amount.error'];
      });
    }
    if (_addTab != 0 && _amountRightCtrl.text.isEmpty) {
      setState(() {
        _rightAmountError = dicCommon['amount.error'];
      });
    }
    if (_leftAmountError != null || _rightAmountError != null) {
      return null;
    }

    final dic = I18n.of(context).getDic(i18n_full_dic_acala, 'acala');
    final DexPoolData pool = ModalRoute.of(context).settings.arguments;
    final pair = pool.tokens.map((e) => e['token']).toList();

    final left = _amountLeftCtrl.text.trim();
    final right = _amountRightCtrl.text.trim();
    final leftAmount = left.isEmpty ? '0' : left;
    final rightAmount = right.isEmpty ? '0' : right;
    return TxConfirmParams(
      txTitle: dic['boot.provision.add'],
      module: 'dex',
      call: 'addProvision',
      txDisplay: {
        'pool': pair.join('-'),
        'amount${pair[0]}': leftAmount,
        'amount${pair[1]}': rightAmount,
      },
      params: [
        pool.tokens[0],
        pool.tokens[1],
        Fmt.tokenInt(leftAmount, pool.pairDecimals[0]).toString(),
        Fmt.tokenInt(rightAmount, pool.pairDecimals[1]).toString(),
      ],
    );
  }

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _refreshKey.currentState.show();
    });
  }

  @override
  Widget build(BuildContext context) {
    final dic = I18n.of(context).getDic(i18n_full_dic_acala, 'acala');
    final colorGrey = Theme.of(context).unselectedWidgetColor;

    final symbols = widget.plugin.networkState.tokenSymbol;
    final decimals = widget.plugin.networkState.tokenDecimals;

    final DexPoolData args = ModalRoute.of(context).settings.arguments;
    final pair = args.tokens.map((e) => e['token']).toList();
    final pairView = pair.map((e) => PluginFmt.tokenView(e)).toList();

    return Observer(builder: (_) {
      final pool = widget.plugin.store.earn.bootstraps.firstWhere(
          (e) => e.tokens.map((e) => e['token']).join('-') == pair.join('-'));

      final nowLeft = Fmt.balanceDouble(
          pool.provisioning.accumulatedProvision[0].toString(),
          pool.pairDecimals[0]);
      final nowRight = Fmt.balanceDouble(
          pool.provisioning.accumulatedProvision[1].toString(),
          pool.pairDecimals[1]);
      final myLeft = Fmt.balanceDouble(
          _userProvisioning != null ? _userProvisioning[0].toString() : '0',
          pool.pairDecimals[0]);
      final myRight = Fmt.balanceDouble(
          _userProvisioning != null ? _userProvisioning[1].toString() : '0',
          pool.pairDecimals[1]);
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

      final estShareLabel = '${dic['boot.my.est']}${dic['boot.my.share']}';
      final estTokenLabel = '${dic['boot.my.est']}${dic['boot.my.token']}';

      TokenBalanceData leftBalance;
      TokenBalanceData rightBalance;
      if (pair[0] == symbols[0]) {
        leftBalance = TokenBalanceData(
            symbol: pair[0],
            decimals: decimals[0],
            amount: (widget.plugin.balances.native?.availableBalance ?? 0)
                .toString());
        rightBalance =
            widget.plugin.store.assets.tokenBalanceMap[pair[1].toUpperCase()];
      } else if (pair[1] == symbols[0]) {
        rightBalance = TokenBalanceData(
            symbol: pair[1],
            decimals: decimals[0],
            amount: (widget.plugin.balances.native?.availableBalance ?? 0)
                .toString());
        leftBalance =
            widget.plugin.store.assets.tokenBalanceMap[pair[0].toUpperCase()];
      } else {
        leftBalance =
            widget.plugin.store.assets.tokenBalanceMap[pair[0].toUpperCase()];
        rightBalance =
            widget.plugin.store.assets.tokenBalanceMap[pair[1].toUpperCase()];
      }

      return Scaffold(
        appBar: AppBar(
            title: Text('${pairView.join('-')} ${dic['boot.title']}'),
            centerTitle: true),
        body: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: RefreshIndicator(
                  key: _refreshKey,
                  onRefresh: _queryUserProvisioning,
                  child: ListView(
                    padding: EdgeInsets.all(16),
                    children: [
                      RoundedCard(
                        padding: EdgeInsets.all(16),
                        child: Column(
                          children: [
                            Container(
                              margin: EdgeInsets.only(bottom: 16),
                              child: Text(dic['boot.my']),
                            ),
                            Text(
                              Fmt.priceFloor(myLeft) +
                                  '${pairView[0]} + ' +
                                  Fmt.priceFloor(myRight) +
                                  pairView[1],
                              style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: colorGrey,
                                  letterSpacing: -0.8),
                            ),
                            Container(
                              margin: EdgeInsets.only(top: 24),
                              child: Row(
                                children: [
                                  InfoItem(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.center,
                                    title: estShareLabel,
                                    content: Fmt.ratio(poolInfo.ratio),
                                  ),
                                  InfoItem(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.center,
                                    title: estTokenLabel,
                                    content: Fmt.priceFloor(poolInfo.lp,
                                        lengthMax: 6),
                                  )
                                ],
                              ),
                            )
                          ],
                        ),
                      ),
                      RoundedCard(
                        padding: EdgeInsets.all(16),
                        margin: EdgeInsets.only(top: 16),
                        child: Column(
                          children: [
                            Container(
                              margin: EdgeInsets.only(bottom: 16),
                              child: Text(dic['boot.provision.add']),
                            ),
                            Container(
                              margin: EdgeInsets.only(bottom: 8),
                              child: Row(
                                children: [
                                  OutlinedButtonSmall(
                                    content: pairView[0],
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
                                  OutlinedButtonSmall(
                                    content: pairView[1],
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
                                  OutlinedButtonSmall(
                                    content: '${pairView[0]} + ${pairView[1]}',
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
                            _addTab != 1
                                ? Column(
                                    children: [
                                      Container(
                                        margin: EdgeInsets.only(top: 8),
                                        child: SwapTokenInput(
                                          title: dic['earn.deposit'],
                                          inputCtrl: _amountLeftCtrl,
                                          focusNode: _leftFocusNode,
                                          balance: leftBalance,
                                          tokenIconsMap:
                                              widget.plugin.tokenIcons,
                                          onInputChange: (v) => _onAmountChange(
                                              0, leftBalance, v),
                                        ),
                                      ),
                                      _ErrorMessage(_leftAmountError),
                                    ],
                                  )
                                : Container(),
                            _addTab == 2 ? Icon(Icons.add) : Container(),
                            _addTab != 0
                                ? Column(
                                    children: [
                                      Container(
                                        margin: EdgeInsets.only(top: 8),
                                        child: SwapTokenInput(
                                          title: dic['earn.deposit'],
                                          inputCtrl: _amountRightCtrl,
                                          focusNode: _rightFocusNode,
                                          balance: rightBalance,
                                          tokenIconsMap:
                                              widget.plugin.tokenIcons,
                                          onInputChange: (v) => _onAmountChange(
                                              1, rightBalance, v),
                                        ),
                                      ),
                                      _ErrorMessage(_rightAmountError),
                                    ],
                                  )
                                : Container(),
                            Container(
                              margin: EdgeInsets.only(top: 8),
                              child: InfoItemRow(estShareLabel,
                                  '+${Fmt.ratio(poolInfoAfter.ratio)}'),
                            ),
                            InfoItemRow(estTokenLabel,
                                '+${Fmt.priceFloor(poolInfoAfter.lp, lengthMax: 6)}'),
                          ],
                        ),
                      )
                    ],
                  ),
                ),
              ),
              Container(
                margin: EdgeInsets.all(16),
                child: TxButton(
                  text: dic['boot.provision.add'],
                  getTxParams: _onSubmit,
                  onFinish: (res) {
                    if (res != null) {
                      _refreshKey.currentState.show();
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

class _ErrorMessage extends StatelessWidget {
  _ErrorMessage(this.error);
  final error;
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(left: 16, top: 4),
      child: error == null
          ? null
          : Row(children: [
              Text(
                error,
                style: TextStyle(fontSize: 12, color: Colors.red),
              )
            ]),
    );
  }
}
