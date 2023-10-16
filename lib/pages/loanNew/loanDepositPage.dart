import 'package:flutter/material.dart';
import 'package:polkawallet_plugin_acala/common/constants/index.dart';
import 'package:polkawallet_plugin_acala/pages/swapNew/bootstrapPage.dart';
import 'package:polkawallet_plugin_acala/polkawallet_plugin_acala.dart';
import 'package:polkawallet_plugin_acala/utils/assets.dart';
import 'package:polkawallet_plugin_acala/utils/format.dart';
import 'package:polkawallet_plugin_acala/utils/i18n/index.dart';
import 'package:polkawallet_sdk/plugin/store/balances.dart';
import 'package:polkawallet_sdk/storage/keyring.dart';
import 'package:polkawallet_sdk/utils/i18n.dart';
import 'package:polkawallet_ui/components/txButton.dart';
import 'package:polkawallet_ui/components/v3/plugin/pluginButton.dart';
import 'package:polkawallet_ui/components/v3/plugin/pluginInputBalance.dart';
import 'package:polkawallet_ui/components/v3/plugin/pluginScaffold.dart';
import 'package:polkawallet_ui/pages/txConfirmPage.dart';
import 'package:polkawallet_ui/utils/format.dart';
import 'package:polkawallet_ui/utils/i18n.dart';

class LoanDepositPage extends StatefulWidget {
  LoanDepositPage(this.plugin, this.keyring);
  final PluginAcala plugin;
  final Keyring keyring;

  static const String route = '/acala/loan/deposit';
  static const String actionTypeDeposit = 'deposit';
  static const String actionTypeWithdraw = 'withdraw';

  @override
  _LoanDepositPageState createState() => _LoanDepositPageState();
}

class LoanDepositPageParams {
  LoanDepositPageParams(this.actionType, this.token);
  final String actionType;
  final TokenBalanceData token;
}

class _LoanDepositPageState extends State<LoanDepositPage> {
  TokenBalanceData? _token;

  final TextEditingController _amountCtrl = new TextEditingController();

  BigInt _amountCollateral = BigInt.zero;

  String? _error1;

  void _onAmount1Change(
    String value,
    BigInt? price,
    int? stableCoinDecimals,
    int? collateralDecimals, {
    required BigInt available,
    BigInt? max,
  }) {
    String v = value.trim();
    if (v.isEmpty) return;

    BigInt collateral =
        max != null ? max : Fmt.tokenInt(v, collateralDecimals!);
    setState(() {
      _amountCollateral = collateral;
    });

    if (max == null) {
      var error = _validateAmount1(value, collateralDecimals, available);
      setState(() {
        _error1 = error;
      });
    }
  }

  String? _validateAmount1(
      String value, int? collateralDecimals, BigInt available) {
    final dic = I18n.of(context)!.getDic(i18n_full_dic_acala, 'common');

    final error = Fmt.validatePrice(value, context);
    if (error != null) {
      return error;
    }
    final valueInt = Fmt.tokenInt(value, collateralDecimals!);
    if (valueInt > available) {
      return dic!['amount.low'];
    }

    final params = ModalRoute.of(context)!.settings.arguments as Map;
    final balancePair = AssetsUtils.getBalancePairFromTokenNameId(
        widget.plugin, [params['tokenNameId']]);

    final deposit = widget.plugin.store!.loan
            .collateralRewards[params['tokenNameId']]?.shares ??
        BigInt.zero;
    BigInt collateral;
    final token = _token ?? balancePair[0];
    final _loan = widget.plugin.store!.loan.loans[params['tokenNameId']];

    final minLabel = I18n.of(context)!
        .getDic(i18n_full_dic_acala, 'acala')!['homa.pool.min'];
    final minBond = widget.plugin.networkConst['earning']['minBond'];
    final minBondInt = Fmt.balanceInt(minBond.toString());
    if (params["type"] == LoanDepositPage.actionTypeDeposit) {
      collateral = valueInt + deposit;
      if (valueInt > BigInt.zero && valueInt < minBondInt) {
        return '$minLabel  ${Fmt.priceFloorBigInt(minBondInt, 12)}';
      }
    } else {
      collateral = deposit - valueInt;
    }
    if ((_loan == null || _loan.debits == BigInt.zero) &&
        collateral > BigInt.zero &&
        collateral < minBondInt) {
      final minLabel = I18n.of(context)!
          .getDic(i18n_full_dic_acala, 'acala')!['homa.pool.min'];
      return '$minLabel  ${Fmt.priceFloorBigInt(minBondInt, collateralDecimals)}';
    }
    return null;
  }

  Future<Map?> _getTxParams(int? stableCoinDecimals) async {
    if (_amountCtrl.text.trim().length == 0 ||
        double.parse(_amountCtrl.text.trim()) == 0) {
      return null;
    }
    final params = ModalRoute.of(context)!.settings.arguments as Map;
    final dic = I18n.of(context)!.getDic(i18n_full_dic_acala, 'acala');
    final balancePair = AssetsUtils.getBalancePairFromTokenNameId(
        widget.plugin, [params["tokenNameId"]]);
    switch (params["type"]) {
      case LoanDepositPage.actionTypeDeposit:
        return {
          'detail': {
            'Stake': Text(
              '${_amountCtrl.text.trim()} ${PluginFmt.tokenView(balancePair[0].symbol)}',
              style: Theme.of(context)
                  .textTheme
                  .headline1
                  ?.copyWith(color: Colors.white),
            ),
          },
          'params': [_amountCollateral.toString()]
        };
      case LoanDepositPage.actionTypeWithdraw:
        return {
          'detail': {
            'Unstake': Text(
              '${_amountCtrl.text.trim()} ${PluginFmt.tokenView(balancePair[0].symbol)}',
              style: Theme.of(context)
                  .textTheme
                  .headline1
                  ?.copyWith(color: Colors.white),
            ),
          },
          'params': [_amountCollateral.toString()]
        };
      default:
        return {};
    }
  }

  Future<void> _onSubmit(String title, int? stableCoinDecimals) async {
    final params = await _getTxParams(stableCoinDecimals);
    if (params == null) return null;

    final res = (await Navigator.of(context).pushNamed(TxConfirmPage.route,
        arguments: TxConfirmParams(
          module: 'earning',
          call: params['detail']['Stake'] != null ? 'bond' : 'unbond',
          txTitle: title,
          txDisplayBold: params['detail'],
          params: params['params'],
          isPlugin: true,
        ))) as Map?;
    if (res != null) {
      Navigator.of(context).pop(res);
    }
  }

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final params = ModalRoute.of(context)!.settings.arguments as Map;

      final loan = widget.plugin.store!.loan.loans[params["tokenNameId"]];
      final balancePair = AssetsUtils.getBalancePairFromTokenNameId(
          widget.plugin, [params["tokenNameId"]]);
      setState(() {
        _amountCollateral = loan?.collaterals ?? BigInt.zero;
        _token = balancePair[0];
      });
    });
  }

  @override
  void dispose() {
    _amountCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    var dic = I18n.of(context)!.getDic(i18n_full_dic_acala, 'acala')!;

    final params = ModalRoute.of(context)!.settings.arguments as Map;
    final balancePair = AssetsUtils.getBalancePairFromTokenNameId(
        widget.plugin, [params['tokenNameId'], acala_stable_coin]);
    final token = _token ?? balancePair[0];

    final tokenOptions =
        widget.plugin.store!.loan.loanTypes.map((e) => e.token).toList();
    tokenOptions.retainWhere((e) {
      final incentive = widget.plugin.store!.earn.incentives.loans;
      return incentive != null &&
          incentive[e?.tokenNameId] != null &&
          (incentive[e?.tokenNameId]![0].amount ?? 0) > 0;
    });

    final loan = widget.plugin.store!.loan.loans[token.tokenNameId];
    final price = widget.plugin.store!.assets.prices[token.tokenNameId];

    final symbolView = PluginFmt.tokenView(token.symbol);
    String titleSuffix = ' $symbolView';

    final BigInt balance = Fmt.balanceInt(balancePair[0].amount);
    BigInt available = balance;

    if (params["type"] == LoanDepositPage.actionTypeWithdraw) {
      available = widget.plugin.store!.loan
              .collateralRewards[params['tokenNameId']]?.shares ??
          BigInt.zero;
      // max to withdraw
      // if (loan == null) {
      //   available = widget.plugin.store!.loan
      //           .collateralRewards[token.tokenNameId]?.shares ??
      //       BigInt.zero;
      // } else {
      //   available = loan.collaterals - loan.requiredCollateral > BigInt.zero
      //       ? loan.collaterals - loan.requiredCollateral
      //       : BigInt.zero;
      // }
    }

    final availableView =
        Fmt.priceFloorBigInt(available, balancePair[0].decimals!, lengthMax: 8);

    final pageTitle = '${dic['loan.${params["type"]}']}$titleSuffix';

    return PluginScaffold(
      appBar: PluginAppBar(
        title: Text(pageTitle),
        centerTitle: true,
      ),
      body: Builder(builder: (BuildContext context) {
        return SafeArea(
          child: Column(
            children: <Widget>[
              Expanded(
                  child: ListView(
                padding: EdgeInsets.only(top: 16, left: 16, right: 16),
                children: <Widget>[
                  PluginInputBalance(
                    tokenViewFunction: (value) {
                      return PluginFmt.tokenView(value);
                    },
                    titleTag: dic['loan.${params["type"]}'],
                    balance: TokenBalanceData(
                        symbol: balancePair[0].symbol,
                        decimals: balancePair[0].decimals!,
                        amount: available.toString()),
                    tokenIconsMap: widget.plugin.tokenIcons,
                    onSetMax:
                        (params["type"] == LoanDepositPage.actionTypeDeposit &&
                                token.symbol ==
                                    widget.plugin.networkState.tokenSymbol![0])
                            ? null
                            : (max) {
                                {
                                  setState(() {
                                    _error1 = null;
                                    _amountCollateral = max;
                                    _amountCtrl.text = Fmt.bigIntToDouble(
                                            max, balancePair[0].decimals!)
                                        .toString();
                                  });
                                  _onAmount1Change(
                                    availableView,
                                    price,
                                    balancePair[1].decimals,
                                    balancePair[0].decimals,
                                    available: max,
                                    max: max,
                                  );
                                }
                              },
                    onClear: () {
                      setState(() {
                        _amountCollateral = BigInt.zero;
                        _amountCtrl.text = "0";
                      });
                      _onAmount1Change("0", price, balancePair[1].decimals,
                          balancePair[0].decimals,
                          available: available);
                    },
                    inputCtrl: _amountCtrl,
                    onInputChange: (v) => _onAmount1Change(v, price,
                        balancePair[1].decimals, balancePair[0].decimals,
                        available: available),
                  ),
                  ErrorMessage(_error1,
                      margin: EdgeInsets.symmetric(vertical: 2)),
                ],
              )),
              Padding(
                padding: EdgeInsets.all(16),
                child: PluginButton(
                  title: I18n.of(context)!
                      .getDic(i18n_full_dic_ui, 'common')!['tx.submit']!,
                  onPressed: () {
                    if (_error1 == null) {
                      _onSubmit(pageTitle, balancePair[1].decimals);
                    }
                  },
                ),
              ),
            ],
          ),
        );
      }),
    );
  }
}
