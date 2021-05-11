import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:polkawallet_plugin_acala/api/types/loanType.dart';
import 'package:polkawallet_plugin_acala/common/constants.dart';
import 'package:polkawallet_plugin_acala/pages/currencySelectPage.dart';
import 'package:polkawallet_plugin_acala/pages/loan/loanInfoPanel.dart';
import 'package:polkawallet_plugin_acala/polkawallet_plugin_acala.dart';
import 'package:polkawallet_plugin_acala/utils/format.dart';
import 'package:polkawallet_plugin_acala/utils/i18n/index.dart';
import 'package:polkawallet_sdk/storage/keyring.dart';
import 'package:polkawallet_sdk/utils/i18n.dart';
import 'package:polkawallet_ui/components/roundedButton.dart';
import 'package:polkawallet_ui/components/tokenIcon.dart';
import 'package:polkawallet_ui/components/txButton.dart';
import 'package:polkawallet_ui/pages/txConfirmPage.dart';
import 'package:polkawallet_ui/utils/format.dart';
import 'package:polkawallet_ui/utils/i18n.dart';
import 'package:polkawallet_ui/utils/index.dart';

class LoanCreatePage extends StatefulWidget {
  LoanCreatePage(this.plugin, this.keyring);
  final PluginAcala plugin;
  final Keyring keyring;

  static const String route = '/acala/loan/create';

  @override
  _LoanCreatePageState createState() => _LoanCreatePageState();
}

class _LoanCreatePageState extends State<LoanCreatePage> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _amountCtrl = new TextEditingController();
  final TextEditingController _amountCtrl2 = new TextEditingController();

  String _token = 'DOT';

  BigInt _amountCollateral = BigInt.zero;
  BigInt _amountDebit = BigInt.zero;

  BigInt _maxToBorrow = BigInt.zero;
  double _currentRatio = 0;
  BigInt _liquidationPrice = BigInt.zero;

  bool _autoValidate = false;

  void _updateState(LoanType loanType, BigInt collateral, BigInt debit,
      {int stableCoinDecimals, int collateralDecimals}) {
    final tokenPrice = widget.plugin.store.assets.prices[_token];
    final collateralInUSD = loanType.tokenToUSD(collateral, tokenPrice,
        stableCoinDecimals: stableCoinDecimals,
        collateralDecimals: collateralDecimals);
    final debitInUSD = debit;
    setState(() {
      _liquidationPrice = loanType.calcLiquidationPrice(debitInUSD, collateral,
          stableCoinDecimals: stableCoinDecimals,
          collateralDecimals: collateralDecimals);
      _currentRatio = loanType.calcCollateralRatio(debitInUSD, collateralInUSD);
    });
  }

  void _onAmount1Change(String value, LoanType loanType, BigInt price,
      {int stableCoinDecimals, int collateralDecimals}) {
    String v = value.trim();
    if (v.isEmpty) return;

    BigInt collateral = Fmt.tokenInt(v, collateralDecimals);
    setState(() {
      _amountCollateral = collateral;
      _maxToBorrow = loanType.calcMaxToBorrow(collateral, price,
          stableCoinDecimals: stableCoinDecimals,
          collateralDecimals: collateralDecimals);
    });

    if (_amountDebit > BigInt.zero) {
      _updateState(loanType, collateral, _amountDebit,
          stableCoinDecimals: stableCoinDecimals,
          collateralDecimals: collateralDecimals);
    }

    _checkAutoValidate();
  }

  void _onAmount2Change(String value, LoanType loanType, int stableCoinDecimals,
      int collateralDecimals) {
    String v = value.trim();
    if (v.isEmpty) return;

    BigInt debits = Fmt.tokenInt(v, stableCoinDecimals);

    setState(() {
      _amountDebit = debits;
    });

    if (_amountCollateral > BigInt.zero) {
      _updateState(loanType, _amountCollateral, debits,
          stableCoinDecimals: stableCoinDecimals,
          collateralDecimals: collateralDecimals);
    }

    _checkAutoValidate();
  }

  void _checkAutoValidate({String value1, String value2}) {
    if (_autoValidate) return;
    if (value1 == null) {
      value1 = _amountCtrl.text.trim();
    }
    if (value2 == null) {
      value2 = _amountCtrl2.text.trim();
    }
    if (value1.isNotEmpty && value2.isNotEmpty) {
      setState(() {
        _autoValidate = true;
      });
    }
  }

  String _validateAmount1(
      String value, BigInt available, int collateralDecimals) {
    final dic = I18n.of(context).getDic(i18n_full_dic_acala, 'common');

    String v = value.trim();
    try {
      if (v.isEmpty || double.parse(v) == 0) {
        return dic['amount.error'];
      }
    } catch (err) {
      return dic['amount.error'];
    }
    BigInt collateral = Fmt.tokenInt(v, collateralDecimals);
    if (collateral > available) {
      return dic['amount.low'];
    }
    return null;
  }

  String _validateAmount2(String value, max, int stableCoinDecimals) {
    final assetDic = I18n.of(context).getDic(i18n_full_dic_acala, 'common');
    final dic = I18n.of(context).getDic(i18n_full_dic_acala, 'acala');

    String v = value.trim();
    try {
      if (v.isEmpty || double.parse(v) < 1) {
        return assetDic['amount.error'];
      }
    } catch (err) {
      return assetDic['amount.error'];
    }
    BigInt debits = Fmt.tokenInt(v, stableCoinDecimals);
    if (debits >= _maxToBorrow) {
      return '${dic['loan.max']} $max';
    }
    return null;
  }

  Map _getTxParams(LoanType loanType,
      {int stableCoinDecimals, int collateralDecimals}) {
    BigInt debitShare = loanType.debitToDebitShare(_amountDebit);
    return {
      'detail': {
        "colleterals": Fmt.token(_amountCollateral, collateralDecimals),
        "debits": Fmt.token(_amountDebit, stableCoinDecimals),
      },
      'params': [
        {'token': _token},
        _amountCollateral.toString(),
        debitShare.toString(),
      ]
    };
  }

  Future<void> _onSubmit(String pageTitle, LoanType loanType,
      {int stableCoinDecimals, int collateralDecimals}) async {
    final params = _getTxParams(loanType,
        stableCoinDecimals: stableCoinDecimals,
        collateralDecimals: collateralDecimals);
    final res = (await Navigator.of(context).pushNamed(TxConfirmPage.route,
        arguments: TxConfirmParams(
          module: 'honzon',
          call: 'adjustLoan',
          txTitle: pageTitle,
          txDisplay: params['detail'],
          params: params['params'],
        ))) as Map;
    if (res != null) {
      Navigator.of(context).pop(res);
    }
  }

  @override
  void dispose() {
    _amountCtrl.dispose();
    _amountCtrl2.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Observer(builder: (_) {
      final dic = I18n.of(context).getDic(i18n_full_dic_acala, 'acala');
      final assetDic = I18n.of(context).getDic(i18n_full_dic_acala, 'common');
      final symbols = widget.plugin.networkState.tokenSymbol;
      final decimals = widget.plugin.networkState.tokenDecimals;
      final stableCoinDecimals = decimals[symbols.indexOf('AUSD')];

      final collateralDecimals = decimals[symbols.indexOf(_token)];

      final pageTitle = '${dic['loan.create']} $_token';

      final loans = widget.plugin.store.loan.loans.values.toList();
      loans.retainWhere((loan) =>
      loan.debits > BigInt.zero || loan.collaterals > BigInt.zero);
      final tokenOptions =
          widget.plugin.store.loan.loanTypes.map((e) => e.token).toList();
      tokenOptions.retainWhere((e) =>
      loans.map((i) => i.token)
              .toList()
              .indexOf(e) <
          0);

      final price = widget.plugin.store.assets.prices[_token];

      final loanType = widget.plugin.store.loan.loanTypes
          .firstWhere((i) => i.token == _token);
      final balance = Fmt.balanceInt(
          widget.plugin.store.assets.tokenBalanceMap[_token]?.amount);
      final available = balance;

      final balanceView =
          Fmt.priceFloorBigInt(available, collateralDecimals, lengthMax: 4);
      final maxToBorrow =
          Fmt.priceFloorBigInt(_maxToBorrow, stableCoinDecimals);

      return Scaffold(
        appBar: AppBar(
          title: Text(pageTitle),
          centerTitle: true,
        ),
        body: Builder(builder: (BuildContext context) {
          return SafeArea(
            child: Column(
              children: <Widget>[
                CurrencySelector(
                  tokenOptions: tokenOptions,
                  tokenIcons: widget.plugin.tokenIcons,
                  token: _token,
                  price: widget.plugin.store.assets.prices[_token],
                  onSelect: (res) {
                    if (res != null) {
                      setState(() {
                        _token = res;
                      });
                    }
                  },
                ),
                Expanded(
                  child: Form(
                    key: _formKey,
                    autovalidateMode: _autoValidate
                        ? AutovalidateMode.onUserInteraction
                        : AutovalidateMode.disabled,
                    child: ListView(
                      padding: EdgeInsets.all(16),
                      children: <Widget>[
                        LoanInfoPanel(
                          price: price,
                          liquidationRatio: loanType.liquidationRatio,
                          requiredRatio: loanType.requiredCollateralRatio,
                          currentRatio: _currentRatio,
                          liquidationPrice: _liquidationPrice,
                        ),
                        Padding(
                          padding: EdgeInsets.only(top: 16),
                          child: Text(dic['loan.amount.collateral']),
                        ),
                        TextFormField(
                          decoration: InputDecoration(
                            hintText: assetDic['amount'],
                            labelText:
                                '${assetDic['amount']} (${assetDic['amount.available']}: $balanceView $_token)',
                          ),
                          inputFormatters: [
                            UI.decimalInputFormatter(collateralDecimals)
                          ],
                          controller: _amountCtrl,
                          keyboardType:
                              TextInputType.numberWithOptions(decimal: true),
                          validator: (v) => _validateAmount1(
                              v, available, collateralDecimals),
                          onChanged: (v) => _onAmount1Change(v, loanType, price,
                              stableCoinDecimals: stableCoinDecimals,
                              collateralDecimals: collateralDecimals),
                        ),
                        Padding(
                          padding: EdgeInsets.only(top: 16),
                          child: Text(dic['loan.amount.debit']),
                        ),
                        TextFormField(
                          decoration: InputDecoration(
                            hintText: assetDic['amount'],
                            labelText:
                                '${assetDic['amount']}(${dic['loan.max']}: $maxToBorrow)',
                          ),
                          inputFormatters: [
                            UI.decimalInputFormatter(stableCoinDecimals)
                          ],
                          controller: _amountCtrl2,
                          keyboardType:
                              TextInputType.numberWithOptions(decimal: true),
                          validator: (v) => _validateAmount2(
                              v, maxToBorrow, stableCoinDecimals),
                          onChanged: (v) => _onAmount2Change(v, loanType,
                              stableCoinDecimals, collateralDecimals),
                        ),
                      ],
                    ),
                  ),
                ),
                Padding(
                  padding: EdgeInsets.all(16),
                  child: RoundedButton(
                    text: I18n.of(context)
                        .getDic(i18n_full_dic_ui, 'common')['tx.submit'],
                    onPressed: () {
                      if (_formKey.currentState.validate()) {
                        _onSubmit(pageTitle, loanType,
                            stableCoinDecimals: stableCoinDecimals,
                            collateralDecimals: collateralDecimals);
                      }
                    },
                  ),
                ),
              ],
            ),
          );
        }),
      );
    });
  }
}

class CurrencySelector extends StatelessWidget {
  CurrencySelector({
    this.tokenOptions,
    this.tokenIcons,
    this.token,
    this.price,
    this.onSelect,
  });
  final List<String> tokenOptions;
  final Map<String, Widget> tokenIcons;
  final String token;
  final BigInt price;
  final Function(String) onSelect;
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 16.0, // has the effect of softening the shadow
            spreadRadius: 4.0, // has the effect of extending the shadow
            offset: Offset(
              2.0, // horizontal, move right 10
              2.0, // vertical, move down 10
            ),
          )
        ],
      ),
      child: ListTile(
        dense: true,
        leading: TokenIcon(token, tokenIcons),
        title: Text(
          PluginFmt.tokenView(token),
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Theme.of(context).primaryColor,
          ),
        ),
        subtitle: price != null
            ? Text(
                '\$${Fmt.token(price, acala_price_decimals)}',
                style: TextStyle(
                  fontSize: 12,
                  color: Theme.of(context).unselectedWidgetColor,
                ),
              )
            : null,
        trailing: Icon(Icons.arrow_forward_ios, size: 18),
        onTap: () async {
          final res = await Navigator.of(context).pushNamed(
            CurrencySelectPage.route,
            arguments: tokenOptions,
          );
          if (res != null) {
            onSelect(res);
          }
        },
      ),
    );
  }
}
