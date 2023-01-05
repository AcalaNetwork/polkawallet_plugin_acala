import 'dart:math';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:polkawallet_plugin_acala/api/types/loanType.dart';
import 'package:polkawallet_plugin_acala/common/constants/index.dart';
import 'package:polkawallet_plugin_acala/pages/swapNew/bootstrapPage.dart';
import 'package:polkawallet_plugin_acala/polkawallet_plugin_acala.dart';
import 'package:polkawallet_plugin_acala/utils/assets.dart';
import 'package:polkawallet_plugin_acala/utils/format.dart';
import 'package:polkawallet_plugin_acala/utils/i18n/index.dart';
import 'package:polkawallet_sdk/plugin/store/balances.dart';
import 'package:polkawallet_sdk/storage/keyring.dart';
import 'package:polkawallet_sdk/utils/i18n.dart';
import 'package:polkawallet_ui/components/infoItemRow.dart';
import 'package:polkawallet_ui/components/v3/dialog.dart';
import 'package:polkawallet_ui/components/v3/plugin/pluginButton.dart';
import 'package:polkawallet_ui/components/v3/plugin/pluginInputBalance.dart';
import 'package:polkawallet_ui/components/v3/plugin/pluginPageTitleTaps.dart';
import 'package:polkawallet_ui/components/v3/plugin/pluginScaffold.dart';
import 'package:polkawallet_ui/components/v3/txButton.dart';
import 'package:polkawallet_ui/pages/v3/txConfirmPage.dart';
import 'package:polkawallet_ui/utils/consts.dart';
import 'package:polkawallet_ui/utils/format.dart';
import 'package:polkawallet_ui/utils/index.dart';

class LoanAdjustPage extends StatefulWidget {
  LoanAdjustPage(this.plugin, this.keyring, {Key? key}) : super(key: key);
  final PluginAcala plugin;
  final Keyring keyring;
  static const String route = 'acala/loan/adjust';

  @override
  State<LoanAdjustPage> createState() => _LoanAdjustPageState();
}

class _LoanAdjustPageState extends State<LoanAdjustPage> {
  int _tab = 0;
  List<String> _tabTitle = [];
  LoanData? _loan;
  LoanData? _editorLoan;
  String _type = "";
  bool _selectRadio = true;

  TextEditingController _firstController = TextEditingController();
  TextEditingController _lastController = TextEditingController();
  String? _error1;
  String? _error2;

  List<String> getTabTitle() {
    final dic = I18n.of(context)!.getDic(i18n_full_dic_acala, 'acala')!;
    if (_type == "collateral") {
      return [dic['loan.deposit']!, dic['loan.withdraw']!];
    }
    return [dic['loan.mint']!, dic['loan.payback']!];
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final data = ModalRoute.of(context)!.settings.arguments as Map;
      setState(() {
        _loan = data["loan"];
        _editorLoan = _loan!.deepCopy();
        _type = data['type'];
        _tabTitle = getTabTitle();
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final dic = I18n.of(context)!.getDic(i18n_full_dic_acala, 'acala')!;
    final textStyle = Theme.of(context).textTheme.headline5?.copyWith(
        color: PluginColorsDark.headline1,
        fontSize: UI.getTextSize(12, context),
        height: 2.0);

    final balancePair = _editorLoan == null
        ? []
        : AssetsUtils.getBalancePairFromTokenNameId(widget.plugin,
            [_editorLoan!.token!.tokenNameId, acala_stable_coin]);
    return PluginScaffold(
        appBar: PluginAppBar(
          title: Text(_type == "collateral"
              ? dic['v3.loan.adjustCollateral']!
              : "${dic['v3.loan.adjustMinted']} ${PluginFmt.tokenView(acala_stable_coin)}"),
        ),
        body: SafeArea(
            child: _editorLoan == null
                ? Container()
                : Padding(
                    padding: EdgeInsets.all(16),
                    child: Column(
                      children: [
                        Container(
                          margin: EdgeInsets.only(bottom: 8),
                          child: PluginPageTitleTaps(
                            names: _tabTitle,
                            activeTab: _tab,
                            onTap: (i) {
                              if (i != _tab) {
                                setState(() {
                                  _error1 = null;
                                  _error2 = null;
                                  _firstController.text = "";
                                  _lastController.text = "";
                                  _editorLoan = _loan!.deepCopy();
                                  if (i == 0) {
                                    _selectRadio = true;
                                  } else {
                                    _selectRadio = false;
                                  }
                                  _tab = i;
                                });
                              }
                            },
                          ),
                        ),
                        Expanded(
                          child: SingleChildScrollView(
                            child: Padding(
                                padding: EdgeInsets.only(top: 20),
                                child: Column(
                                  children: [
                                    buildFirstInputView(),
                                    InfoItemRow(
                                      "${dic['v3.loan.requiredSafety']}",
                                      "${Fmt.priceFloorBigIntFormatter(_editorLoan!.requiredCollateral, _editorLoan!.token!.decimals!, lengthMax: 4)} ${PluginFmt.tokenView(_editorLoan!.token!.symbol)}",
                                      labelStyle: textStyle,
                                      contentStyle: textStyle,
                                    ),
                                    buildLastInputView(),
                                    InfoItemRow(
                                      "${dic['v3.loan.currentCollateral']}:",
                                      "${Fmt.priceFloorBigIntFormatter(_editorLoan!.collaterals, _editorLoan!.token!.decimals!, lengthMax: 4)} ${PluginFmt.tokenView(_editorLoan!.token!.symbol)}",
                                      labelStyle: textStyle,
                                      contentStyle: textStyle,
                                    ),
                                    InfoItemRow(
                                      "${dic['v3.loan.currentMinted']}:",
                                      "${Fmt.priceFloorBigIntFormatter(_editorLoan!.debits, balancePair[1]!.decimals!, lengthMax: 4)} ${PluginFmt.tokenView(acala_stable_coin)}",
                                      labelStyle: textStyle,
                                      contentStyle: textStyle,
                                    ),
                                    InfoItemRow(
                                      "${dic['v3.loan.newCollateralRatio']}:",
                                      "${Fmt.ratio(_editorLoan?.collateralRatio ?? 2)}",
                                      labelStyle: textStyle,
                                      contentStyle: textStyle,
                                    ),
                                    InfoItemRow(
                                      "${dic['v3.loan.newLiquidationPrice']}:",
                                      "\$ ${Fmt.priceFloorBigInt(_editorLoan!.liquidationPrice, acala_price_decimals, lengthMax: 4)}",
                                      labelStyle: textStyle,
                                      contentStyle: textStyle,
                                    ),
                                  ],
                                )),
                          ),
                        ),
                        Padding(
                            padding: EdgeInsets.only(top: 37, bottom: 38),
                            child: PluginButton(
                              title: '${dic['v3.loan.submit']}',
                              onPressed: () {
                                if (_error1 == null &&
                                    (!_selectRadio ||
                                        _selectRadio && _error2 == null)) {
                                  _onSubmit();
                                }
                              },
                            )),
                      ],
                    ))));
  }

  Widget buildLastInputView() {
    if (_editorLoan == null ||
        _loan?.type.maximumTotalDebitValue == BigInt.zero) {
      return Container();
    }
    var titleTag = '';
    String seleteRadioTest = '';
    final dic = I18n.of(context)!.getDic(i18n_full_dic_acala, 'acala')!;
    if (_tab == 0) {
      if (_type != 'collateral') {
        titleTag = dic['loan.deposit']!;
        seleteRadioTest = dic['v3.loan.depositMeanwhile']!;
      } else {
        titleTag = dic['loan.mint']!;
        seleteRadioTest = dic['v3.loan.mintMeanwhile']!;
      }
    } else {
      if (_type != 'collateral') {
        titleTag = dic['loan.withdraw']!;
        seleteRadioTest = dic['v3.loan.withdrawMeanwhile']!;
      } else {
        titleTag = dic['loan.payback']!;
        seleteRadioTest = dic['v3.loan.paybackMeanwhile']!;
      }
    }
    final banlance = getBalance(titleTag);

    final textStyle = Theme.of(context).textTheme.headline5?.copyWith(
        color: PluginColorsDark.headline1,
        fontSize: UI.getTextSize(14, context));
    return Padding(
        padding: EdgeInsets.only(bottom: 10),
        child: Column(
          children: [
            GestureDetector(
                onTap: () {
                  if (_selectRadio) {
                    _inputChage(titleTag, "0");
                  } else {
                    _inputChage(titleTag, _lastController.text);
                  }
                  setState(() {
                    _selectRadio = !_selectRadio;
                  });
                },
                child: Container(
                    margin: EdgeInsets.only(top: 16),
                    width: double.infinity,
                    padding: EdgeInsets.symmetric(vertical: 6),
                    decoration: BoxDecoration(
                        color: _selectRadio
                            ? Color(0xA6D8D8D8)
                            : Color(0xFFD8D8D8),
                        borderRadius: BorderRadius.circular(4)),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          _selectRadio ? Icons.remove_circle : Icons.add_circle,
                          color: Color(0xFF616161),
                          size: 12,
                        ),
                        Padding(
                            padding: EdgeInsets.only(left: 2),
                            child: Text(
                              "$seleteRadioTest (${PluginFmt.tokenView(banlance.symbol)})",
                              style: textStyle?.copyWith(
                                  color: Color(0xFF24262A), height: 1.3),
                            )),
                      ],
                    ))),
            Visibility(
                visible: _selectRadio,
                child: Column(
                  children: [
                    Padding(
                        padding: EdgeInsets.only(top: 16),
                        child: PluginInputBalance(
                          key: Key("2"),
                          tokenViewFunction: (value) {
                            return PluginFmt.tokenView(value);
                          },
                          titleTag: titleTag,
                          balanceLabel: titleTag == dic['loan.mint']
                              ? dic['v3.loan.canMint']
                              : null,
                          inputCtrl: _lastController,
                          onSetMax: Fmt.bigIntToDouble(
                                          BigInt.parse(banlance.amount!),
                                          banlance.decimals!) >
                                      0.000001 &&
                                  titleTag != dic['loan.mint']
                              ? (max) {
                                  var value = Fmt.bigIntToDouble(
                                          max, banlance.decimals!)
                                      .toString();
                                  var error = _validateAmount(
                                      value,
                                      banlance.amount!,
                                      banlance.decimals!,
                                      titleTag,
                                      valueBigint: max);
                                  setState(() {
                                    _lastController.text = value;
                                    _error2 = null;
                                  });
                                  if (error == null) {
                                    _inputChage(titleTag, _lastController.text,
                                        isMax: true);
                                  }
                                  if (titleTag == dic['loan.payback']!) {
                                    final withdrawBalance =
                                        getBalance(dic['loan.withdraw']!);
                                    var error = _validateAmount(
                                        _firstController.text,
                                        withdrawBalance.amount!,
                                        withdrawBalance.decimals!,
                                        dic['loan.withdraw']!);
                                    setState(() {
                                      _error1 = error;
                                    });
                                  } else if (titleTag == dic['loan.deposit']!) {
                                    final withdrawBalance =
                                        getBalance(dic['loan.mint']!);
                                    var error = _validateAmount(
                                        _firstController.text,
                                        withdrawBalance.amount!,
                                        withdrawBalance.decimals!,
                                        dic['loan.mint']!);
                                    setState(() {
                                      _error1 = error;
                                    });
                                  }
                                }
                              : null,
                          onClear: () {
                            setState(() {
                              _lastController.text = "";
                              _error2 = null;
                            });
                            _inputChage(titleTag, _lastController.text);
                            if (titleTag == dic['loan.payback']!) {
                              final withdrawBalance =
                                  getBalance(dic['loan.withdraw']!);
                              var error = _validateAmount(
                                  _firstController.text,
                                  withdrawBalance.amount!,
                                  withdrawBalance.decimals!,
                                  dic['loan.withdraw']!);
                              setState(() {
                                _error1 = error;
                              });
                            } else if (titleTag == dic['loan.deposit']!) {
                              final withdrawBalance =
                                  getBalance(dic['loan.mint']!);
                              var error = _validateAmount(
                                  _firstController.text,
                                  withdrawBalance.amount!,
                                  withdrawBalance.decimals!,
                                  dic['loan.mint']!);
                              setState(() {
                                _error1 = error;
                              });
                            }
                          },
                          onInputChange: (v) {
                            var error = _validateAmount(v, banlance.amount!,
                                banlance.decimals!, titleTag);
                            setState(() {
                              _error2 = error;
                            });
                            if (error == null) {
                              _inputChage(titleTag, _lastController.text);
                              if (titleTag == dic['loan.payback']!) {
                                final withdrawBalance =
                                    getBalance(dic['loan.withdraw']!);
                                var error = _validateAmount(
                                    _firstController.text,
                                    withdrawBalance.amount!,
                                    withdrawBalance.decimals!,
                                    dic['loan.withdraw']!);
                                setState(() {
                                  _error1 = error;
                                });
                              } else if (titleTag == dic['loan.deposit']!) {
                                final withdrawBalance =
                                    getBalance(dic['loan.mint']!);
                                var error = _validateAmount(
                                    _firstController.text,
                                    withdrawBalance.amount!,
                                    withdrawBalance.decimals!,
                                    dic['loan.mint']!);
                                setState(() {
                                  _error1 = error;
                                });
                              }
                            }
                          },
                          balance: banlance,
                          tokenIconsMap: widget.plugin.tokenIcons,
                        )),
                    ErrorMessage(_error2,
                        margin: EdgeInsets.symmetric(vertical: 2)),
                    Padding(
                      padding: EdgeInsets.only(top: 16),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            width: 20,
                            height: 4,
                            decoration: BoxDecoration(
                                borderRadius:
                                    BorderRadius.all(Radius.circular(2)),
                                color: Color(0x73D8D8D8)),
                          ),
                          Container(
                            margin: EdgeInsets.only(left: 6, right: 6),
                            width: 83,
                            height: 4,
                            decoration: BoxDecoration(
                                borderRadius:
                                    BorderRadius.all(Radius.circular(2)),
                                color: Color(0x73D8D8D8)),
                          ),
                          Container(
                            width: 20,
                            height: 4,
                            decoration: BoxDecoration(
                                borderRadius:
                                    BorderRadius.all(Radius.circular(2)),
                                color: Color(0x73D8D8D8)),
                          )
                        ],
                      ),
                    )
                  ],
                ))
          ],
        ));
  }

  Widget buildFirstInputView() {
    if (_editorLoan == null) {
      return Container();
    }
    var titleTag = '';
    final dic = I18n.of(context)!.getDic(i18n_full_dic_acala, 'acala')!;
    if (_tab == 0) {
      if (_type == 'collateral') {
        titleTag = dic['loan.deposit']!;
      } else {
        titleTag = dic['loan.mint']!;
      }
    } else {
      if (_type == 'collateral') {
        titleTag = dic['loan.withdraw']!;
      } else {
        titleTag = dic['loan.payback']!;
      }
    }
    final banlance = getBalance(titleTag);

    final totalDebitInCDP = _loan!.type.debitShareToDebit(widget.plugin.store!
            .loan.totalCDPs[_loan!.type.token!.tokenNameId]?.debit ??
        BigInt.zero);
    final totalDebitLimit = _loan!.type.maximumTotalDebitValue > totalDebitInCDP
        ? _loan!.type.maximumTotalDebitValue - totalDebitInCDP
        : BigInt.zero;
    return Padding(
        padding: EdgeInsets.only(bottom: 10),
        child: Column(
          children: [
            PluginInputBalance(
              key: Key("1"),
              tokenViewFunction: (value) {
                return PluginFmt.tokenView(value);
              },
              titleTag: titleTag,
              balanceLabel:
                  titleTag == dic['loan.mint'] ? dic['v3.loan.canMint'] : null,
              inputCtrl: _firstController,
              onSetMax: Fmt.bigIntToDouble(BigInt.parse(banlance.amount!),
                              banlance.decimals!) >
                          0.000001 &&
                      titleTag != dic['loan.mint']
                  ? (max) {
                      var value = Fmt.bigIntToDouble(max, banlance.decimals!)
                          .toString();
                      var error = _validateAmount(
                          value, banlance.amount!, banlance.decimals!, titleTag,
                          valueBigint: max);
                      setState(() {
                        _firstController.text = value;
                        _error1 = error;
                      });
                      if (error == null) {
                        _inputChage(titleTag, _firstController.text,
                            isMax: true);
                      }
                      if (titleTag == dic['loan.payback']!) {
                        final withdrawBalance =
                            getBalance(dic['loan.withdraw']!);
                        var error = _validateAmount(
                            _lastController.text,
                            withdrawBalance.amount!,
                            withdrawBalance.decimals!,
                            dic['loan.withdraw']!);
                        setState(() {
                          _error2 = error;
                        });
                      } else if (titleTag == dic['loan.deposit']!) {
                        final withdrawBalance = getBalance(dic['loan.mint']!);
                        var error = _validateAmount(
                            _lastController.text,
                            withdrawBalance.amount!,
                            withdrawBalance.decimals!,
                            dic['loan.mint']!);
                        setState(() {
                          _error2 = error;
                        });
                      }
                    }
                  : null,
              onClear: () {
                setState(() {
                  _firstController.text = "";
                  _error1 = null;
                });
                _inputChage(titleTag, _firstController.text);
                if (titleTag == dic['loan.payback']!) {
                  final withdrawBalance = getBalance(dic['loan.withdraw']!);
                  var error = _validateAmount(
                      _lastController.text,
                      withdrawBalance.amount!,
                      withdrawBalance.decimals!,
                      dic['loan.withdraw']!);
                  setState(() {
                    _error2 = error;
                  });
                } else if (titleTag == dic['loan.deposit']!) {
                  final withdrawBalance = getBalance(dic['loan.mint']!);
                  var error = _validateAmount(
                      _lastController.text,
                      withdrawBalance.amount!,
                      withdrawBalance.decimals!,
                      dic['loan.mint']!);
                  setState(() {
                    _error2 = error;
                  });
                }
              },
              onInputChange: (v) {
                var error = _validateAmount(
                    v, banlance.amount!, banlance.decimals!, titleTag,
                    totalDebitLimit: totalDebitLimit);
                setState(() {
                  _error1 = error;
                });
                if (error == null) {
                  _inputChage(titleTag, _firstController.text);
                  if (titleTag == dic['loan.payback']!) {
                    final withdrawBalance = getBalance(dic['loan.withdraw']!);
                    var error = _validateAmount(
                        _lastController.text,
                        withdrawBalance.amount!,
                        withdrawBalance.decimals!,
                        dic['loan.withdraw']!);
                    setState(() {
                      _error2 = error;
                    });
                  } else if (titleTag == dic['loan.deposit']!) {
                    final withdrawBalance = getBalance(dic['loan.mint']!);
                    var error = _validateAmount(
                        _lastController.text,
                        withdrawBalance.amount!,
                        withdrawBalance.decimals!,
                        dic['loan.mint']!);
                    setState(() {
                      _error2 = error;
                    });
                  }
                }
              },
              balance: banlance,
              tokenIconsMap: widget.plugin.tokenIcons,
            ),
            ErrorMessage(_error1, margin: EdgeInsets.symmetric(vertical: 2)),
          ],
        ));
  }

  TokenBalanceData getBalance(String titleTag) {
    final dic = I18n.of(context)!.getDic(i18n_full_dic_acala, 'acala')!;
    String symbol = '';
    int decimals = 12;
    String amount = '';
    final balancePair = AssetsUtils.getBalancePairFromTokenNameId(
        widget.plugin, [_editorLoan!.token!.tokenNameId, acala_stable_coin]);
    if (titleTag == dic['loan.payback']!) {
      symbol = acala_stable_coin;
      decimals = balancePair[1].decimals ?? 12;
      amount = (Fmt.balanceInt(balancePair[1].amount) -
                      Fmt.balanceInt(balancePair[1].minBalance) >
                  _loan!.debits
              ? _loan!.debits
              : Fmt.balanceInt(balancePair[1].amount) -
                          Fmt.balanceInt(balancePair[1].minBalance) >
                      BigInt.zero
                  ? Fmt.balanceInt(balancePair[1].amount) -
                      Fmt.balanceInt(balancePair[1].minBalance)
                  : BigInt.zero)
          .toString();
    } else if (titleTag == dic['loan.mint']!) {
      symbol = acala_stable_coin;
      decimals = balancePair[1].decimals ?? 12;
      amount = (_editorLoan!.maxToBorrow - _loan!.debits > BigInt.zero
              ? _editorLoan!.maxToBorrow - _loan!.debits
              : BigInt.zero)
          .toString();
    } else if (titleTag == dic['loan.deposit']!) {
      symbol = _editorLoan!.token!.symbol!;
      decimals = _editorLoan!.token?.decimals ?? 12;
      amount = balancePair[0].amount!;
    } else if (titleTag == dic['loan.withdraw']!) {
      symbol = _editorLoan!.token!.symbol!;
      decimals = _editorLoan!.token?.decimals ?? 12;
      var requiredCollateral = BigInt.zero;
      if (_loan!.price > BigInt.zero && _loan!.debitInUSD > BigInt.zero) {
        final stableCoinDecimals = widget
            .plugin.store!.assets.tokenBalanceMap[acala_stable_coin]!.decimals!;
        final collateralDecimals = _loan!.token!.decimals!;
        requiredCollateral = BigInt.from(_loan!.debitInUSD *
            (_loan!.type.requiredCollateralRatio + Fmt.tokenInt("0.01", 18)) /
            _loan!.price /
            pow(10, stableCoinDecimals - collateralDecimals));
      }
      amount = (_editorLoan!.requiredCollateral == BigInt.zero
              ? _loan!.collaterals
              : _loan!.collaterals - _editorLoan!.requiredCollateral >
                      BigInt.zero
                  ? _loan!.collaterals - requiredCollateral
                  : BigInt.zero)
          .toString();
    }
    return TokenBalanceData(symbol: symbol, decimals: decimals, amount: amount);
  }

  String? _validateAmount(
      String value, String max, int decimals, String titleTag,
      {BigInt? valueBigint, BigInt? totalDebitLimit}) {
    // final assetDic = I18n.of(context)!.getDic(i18n_full_dic_acala, 'common');
    final dic = I18n.of(context)!.getDic(i18n_full_dic_acala, 'acala');

    String v = value.trim();
    if (v.length == 0) {
      return null;
    }
    final error = Fmt.validatePrice(v, context);
    if (error != null) {
      return error;
    }

    BigInt debit = valueBigint ?? Fmt.tokenInt(v, decimals);
    if (debit > BigInt.parse(max)) {
      return '${dic!['loan.max']} ${Fmt.priceFloorBigIntFormatter(BigInt.parse(max), decimals)}';
    }

    if (titleTag == dic!['loan.payback']! || titleTag == dic['loan.mint']!) {
      final minimumDebitValue =
          Fmt.bigIntToDouble(_loan!.type.minimumDebitValue, decimals);
      final debits = titleTag == dic['loan.payback']!
          ? _loan!.debits - debit
          : _loan!.debits + debit;
      if (debits > BigInt.zero && debits < _loan!.type.minimumDebitValue) {
        return '${dic['loan.warn1']}$minimumDebitValue ${PluginFmt.tokenView(acala_stable_coin)}';
      }

      if (titleTag == dic['loan.mint'] &&
          debits > (totalDebitLimit ?? BigInt.zero)) {
        return dic['loan.max.sys'];
      }
    }
    return null;
  }

  void _inputChage(String titleTag, String v, {bool isMax = false}) {
    if (v.trim().isEmpty) {
      v = '0';
    }
    final dic = I18n.of(context)!.getDic(i18n_full_dic_acala, 'acala')!;
    final balancePair = AssetsUtils.getBalancePairFromTokenNameId(
        widget.plugin, [_editorLoan!.token!.tokenNameId, acala_stable_coin]);
    if (titleTag == dic['loan.payback']!) {
      if (v == "0") {
        _valueChange(debits: _loan!.debits);
        return;
      }
      final debits = Fmt.tokenInt(v, balancePair[1].decimals!);
      _valueChange(
          debits: double.parse(v) ==
                  Fmt.bigIntToDouble(_loan!.debits, balancePair[1].decimals!)
              ? BigInt.zero
              : _loan!.debits - debits);
    } else if (titleTag == dic['loan.mint']!) {
      if (v == "0") {
        _valueChange(debits: _loan!.debits);
        return;
      }
      final debits = Fmt.tokenInt(v, balancePair[1].decimals!);
      _valueChange(debits: _loan!.debits + debits);
    } else if (titleTag == dic['loan.deposit']!) {
      if (v == "0") {
        _valueChange(collaterals: _loan!.collaterals);
        return;
      }
      final collaterals = Fmt.tokenInt(v, balancePair[0].decimals!);
      _valueChange(collaterals: _loan!.collaterals + collaterals);
    } else if (titleTag == dic['loan.withdraw']!) {
      if (v == "0") {
        _valueChange(collaterals: _loan!.collaterals);
        return;
      }
      final collaterals = Fmt.tokenInt(v, balancePair[0].decimals!);
      _valueChange(
          collaterals: isMax && _editorLoan!.debits == BigInt.zero
              ? BigInt.zero
              : _loan!.collaterals - collaterals);
    }
  }

  void _valueChange({BigInt? debits, BigInt? collaterals}) {
    final tokenPrice =
        widget.plugin.store!.assets.prices[_editorLoan!.token!.tokenNameId] ??
            BigInt.zero;
    final stableCoinDecimals = widget
        .plugin.store!.assets.tokenBalanceMap[acala_stable_coin]!.decimals!;
    final collateralDecimals = _editorLoan!.token!.decimals!;
    if (debits != null && debits != _editorLoan!.debits) {
      if (debits == _loan!.debits) {
        setState(() {
          _editorLoan!.debits = debits;
          _editorLoan!.debitShares = _loan!.debitShares;
          _editorLoan!.debitInUSD = _loan!.debitInUSD;
          _editorLoan!.collateralInUSD = _loan!.collateralInUSD;
          _editorLoan!.collateralRatio = _loan!.collateralRatio;
          _editorLoan!.requiredCollateral = _loan!.requiredCollateral;
          _editorLoan!.liquidationPrice = _loan!.liquidationPrice;
        });
        return;
      }
      setState(() {
        _editorLoan!.debits = debits;
        _editorLoan!.debitShares = _editorLoan!.type.debitToDebitShare(debits);
        _editorLoan!.debitInUSD = _editorLoan!.debits;
        _editorLoan!.collateralInUSD = _editorLoan!.type.tokenToUSD(
            _editorLoan!.collaterals, tokenPrice,
            stableCoinDecimals: stableCoinDecimals,
            collateralDecimals: collateralDecimals);
        _editorLoan!.collateralRatio = _editorLoan!.type.calcCollateralRatio(
            _editorLoan!.debitInUSD, _editorLoan!.collateralInUSD);
        _editorLoan!.requiredCollateral = _editorLoan!.type
            .calcRequiredCollateral(_editorLoan!.debitInUSD, tokenPrice,
                stableCoinDecimals: stableCoinDecimals,
                collateralDecimals: collateralDecimals);
        _editorLoan!.liquidationPrice = _editorLoan!.type.calcLiquidationPrice(
            _editorLoan!.debitInUSD, _editorLoan!.collaterals,
            stableCoinDecimals: stableCoinDecimals,
            collateralDecimals: collateralDecimals);
      });
    }

    if (collaterals != null && collaterals != _editorLoan!.collaterals) {
      if (debits == _loan!.collaterals) {
        setState(() {
          _editorLoan!.collaterals = collaterals;
          _editorLoan!.collateralInUSD = _loan!.collateralInUSD;
          _editorLoan!.maxToBorrow = _loan!.maxToBorrow;
          _editorLoan!.collateralRatio = _loan!.collateralRatio;
          _editorLoan!.liquidationPrice = _loan!.liquidationPrice;
        });
        return;
      }
      setState(() {
        _editorLoan!.collaterals = collaterals;
        _editorLoan!.collateralInUSD = _editorLoan!.type.tokenToUSD(
            _editorLoan!.collaterals, tokenPrice,
            stableCoinDecimals: stableCoinDecimals,
            collateralDecimals: collateralDecimals);
        _editorLoan!.maxToBorrow = _editorLoan!.type.calcMaxToBorrow(
            _editorLoan!.collaterals, tokenPrice,
            stableCoinDecimals: stableCoinDecimals,
            collateralDecimals: collateralDecimals);
        _editorLoan!.collateralRatio = _editorLoan!.type.calcCollateralRatio(
            _editorLoan!.debitInUSD, _editorLoan!.collateralInUSD);
        _editorLoan!.liquidationPrice = _editorLoan!.type.calcLiquidationPrice(
            _editorLoan!.debitInUSD, _editorLoan!.collaterals,
            stableCoinDecimals: stableCoinDecimals,
            collateralDecimals: collateralDecimals);
      });
    }
  }

  Future<void> _onSubmit() async {
    final params = await _getTxParams(_editorLoan!, _loan!);
    if (params == null) return null;

    final res = (await Navigator.of(context).pushNamed(TxConfirmPage.route,
        arguments: TxConfirmParams(
          module: 'honzon',
          call: _loan!.debits == BigInt.zero
              ? 'adjustLoan'
              : 'adjustLoanByDebitValue',
          txTitle: "adjust Vault",
          txDisplayBold: params['detail'],
          params: params['params'],
          isPlugin: true,
        ))) as Map?;
    if (res != null) {
      Navigator.of(context).pop(res);
    }
  }

  Future<Map?> _getTxParams(LoanData loan, LoanData originalLoan) async {
    final collaterals = loan.collaterals - originalLoan.collaterals;
    final debitShares = loan.debitShares - originalLoan.debitShares;
    var debits = loan.debits - originalLoan.debits;

    if (collaterals == BigInt.zero && debits == BigInt.zero) {
      return null;
    }

    if (loan.type.debitShareToDebit(loan.debitShares) == BigInt.zero &&
        loan.collaterals > BigInt.zero &&
        loan.debits != originalLoan.debits) {
      final dic = I18n.of(context)!.getDic(i18n_full_dic_acala, 'acala');
      await showCupertinoDialog(
          context: context,
          builder: (_) {
            return PolkawalletAlertDialog(
              content: Text(dic!['v3.loan.paybackMessage']!),
              actions: <Widget>[
                PolkawalletActionSheetAction(
                  child: Text(dic['v3.loan.iUnderstand']!),
                  onPressed: () => Navigator.of(context).pop(false),
                )
              ],
            );
          });
    }

    final balancePair = AssetsUtils.getBalancePairFromTokenNameId(
        widget.plugin, [loan.token!.tokenNameId, acala_stable_coin]);
    final dic = I18n.of(context)!.getDic(i18n_full_dic_acala, 'acala');
    final Map<String, Widget> detail = Map<String, Widget>();
    if (collaterals != BigInt.zero) {
      var dicValue = 'loan.deposit';
      if (collaterals < BigInt.zero) {
        dicValue = 'loan.withdraw';
      }
      if (loan.debits == BigInt.zero &&
          loan.collaterals > BigInt.zero &&
          loan.collaterals <
              Fmt.balanceInt(loan.token!.minBalance) * BigInt.from(100)) {
        showCupertinoDialog(
            context: context,
            builder: (_) {
              return PolkawalletAlertDialog(
                content: Text(
                    "${I18n.of(context)!.getDic(i18n_full_dic_acala, 'acala')!['homa.pool.min']} ${Fmt.priceFloorBigInt(Fmt.balanceInt(loan.token!.minBalance) * BigInt.from(100), loan.token!.decimals!, lengthFixed: 4)} ${PluginFmt.tokenView(loan.token!.symbol)}"),
                actions: <Widget>[
                  PolkawalletActionSheetAction(
                    child: Text(I18n.of(context)!.getDic(
                        i18n_full_dic_acala, 'common')!['upgrading.btn']!),
                    onPressed: () => Navigator.of(context).pop(false),
                  )
                ],
              );
            });
        return null;
      }
      detail[dic![dicValue]!] = Text(
        '${Fmt.priceFloorBigInt(collaterals.abs(), balancePair[0].decimals!, lengthMax: 8)} ${PluginFmt.tokenView(loan.token!.symbol)}',
        style: Theme.of(context)
            .textTheme
            .headline1
            ?.copyWith(color: Colors.white),
      );
    }

    var debitS = debitShares;
    if (debitShares != BigInt.zero) {
      var dicValue = 'loan.mint';

      if (loan.type.maximumTotalDebitValue == BigInt.zero) return null;

      if (originalLoan.debits == BigInt.zero &&
          debits < loan.type.minimumDebitValue) {
        final minimumDebitValue = Fmt.bigIntToDouble(
            loan.type.minimumDebitValue, balancePair[1].decimals!);
        if (loan.maxToBorrow < loan.type.minimumDebitValue) {
          final dic = I18n.of(context)!.getDic(i18n_full_dic_acala, 'acala');
          showCupertinoDialog(
              context: context,
              builder: (_) {
                return PolkawalletAlertDialog(
                  content: Text(
                      "${dic!['v3.loan.errorMessage5']}$minimumDebitValue${dic['v3.loan.errorMessage6']}"),
                  actions: <Widget>[
                    PolkawalletActionSheetAction(
                      child: Text(I18n.of(context)!.getDic(
                          i18n_full_dic_acala, 'common')!['upgrading.btn']!),
                      onPressed: () => Navigator.of(context).pop(false),
                    )
                  ],
                );
              });
          return null;
        }
        final bool canContinue = await UI.confirm(context,
            '${dic!['loan.warn4']}$minimumDebitValue ${dic['loan.warn5']}');
        if (!canContinue) return null;
        debitS = loan.type.debitToDebitShare(
            loan.type.minimumDebitValue + BigInt.from(10000));
      }
      if (debitShares < BigInt.zero) {
        dicValue = 'loan.payback';

        // // pay less if less than 1 debit(aUSD) will be left,
        // // make sure tx success by leaving more than 1 debit(aUSD).
        // print(originalLoan.debits - debits.abs());
        // if (originalLoan.debits - debits.abs() > BigInt.zero &&
        //     originalLoan.debits - debits.abs() < loan.type.minimumDebitValue) {
        //   final minimumDebitValue = Fmt.bigIntToDouble(
        //       loan.type.minimumDebitValue, balancePair[1]!.decimals!);
        //   final bool canContinue = await (_confirmPaybackParams(
        //           '${dic!['loan.warn1']}$minimumDebitValue${dic['loan.warn2']}$minimumDebitValue${dic['loan.warn3']}')
        //       as Future<bool>);
        //   if (!canContinue) return null;
        //   debitSubtract = loan.type.debitToDebitShare(
        //       loan.type.minimumDebitValue - originalLoan.debits);
        // }

        final BigInt balanceStableCoin = Fmt.balanceInt(balancePair[1].amount) -
            Fmt.balanceInt(balancePair[1].minBalance);
        if (balanceStableCoin <= debits.abs()) {
          debitS = loan.type.debitToDebitShare(
              balanceStableCoin ~/ BigInt.from(1000000) - balanceStableCoin);
        }
      }
      detail[dic![dicValue]!] = Text(
        '${Fmt.priceFloorBigInt(loan.type.debitShareToDebit(debitS).abs(), balancePair[1].decimals!, lengthMax: 8)} ${PluginFmt.tokenView(acala_stable_coin)}',
        style: Theme.of(context)
            .textTheme
            .headline1
            ?.copyWith(color: Colors.white),
      );
    }

    return {
      'detail': detail,
      'params': [
        loan.token!.currencyId,
        collaterals != BigInt.zero ? collaterals.toString() : 0,
        originalLoan.debits == BigInt.zero
            ? debitS.toString()
            : debitS == debitShares
                ? loan.debits == BigInt.zero
                    ? (debits + debits ~/ BigInt.from(10000)).toString()
                    : debits.toString()
                : loan.type.debitShareToDebit(debitS).toString()
      ]
    };
  }
}
