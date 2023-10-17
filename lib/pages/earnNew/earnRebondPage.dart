import 'package:flutter/material.dart';
import 'package:polkawallet_plugin_acala/pages/swapNew/bootstrapPage.dart';
import 'package:polkawallet_plugin_acala/polkawallet_plugin_acala.dart';
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

class EarningRebondPage extends StatefulWidget {
  EarningRebondPage(this.plugin, this.keyring);
  final PluginAcala plugin;
  final Keyring keyring;

  static const String route = '/karura/earn/rebond';

  @override
  _EarningRebondPageState createState() => _EarningRebondPageState();
}

class _EarningRebondPageState extends State<EarningRebondPage> {
  final TextEditingController _amountCtrl = new TextEditingController();

  BigInt _amountBigInt = BigInt.zero;

  String? _error1;

  void _onAmount1Change(
    String value, {
    required BigInt available,
    BigInt? max,
  }) {
    String v = value.trim();
    if (v.isEmpty) return;

    BigInt collateral = max != null ? max : Fmt.tokenInt(v, 12);
    setState(() {
      _amountBigInt = collateral;
    });

    if (max == null) {
      var error = _validateAmount1(value, available);
      setState(() {
        _error1 = error;
      });
    }
  }

  String? _validateAmount1(String value, BigInt available) {
    final dic = I18n.of(context)!.getDic(i18n_full_dic_acala, 'common');

    final error = Fmt.validatePrice(value, context);
    if (error != null) {
      return error;
    }
    final valueInt = Fmt.tokenInt(value, 12);
    if (valueInt > available) {
      return dic!['amount.low'];
    }

    final minLabel = I18n.of(context)!
        .getDic(i18n_full_dic_acala, 'acala')!['homa.pool.min'];
    final minBond = widget.plugin.networkConst['earning']['minBond'];
    final minBondInt = Fmt.balanceInt(minBond.toString());
    if (valueInt > BigInt.zero && valueInt < minBondInt) {
      return '$minLabel  ${Fmt.priceFloorBigInt(minBondInt, 12)}';
    }
    return null;
  }

  Future<Map?> _getTxParams() async {
    if (_amountCtrl.text.trim().length == 0 ||
        double.parse(_amountCtrl.text.trim()) == 0) {
      return null;
    }

    return {
      'detail': {
        'Restake': Text(
          '${_amountCtrl.text.trim()} ACA',
          style: Theme.of(context)
              .textTheme
              .headline1
              ?.copyWith(color: Colors.white),
        ),
      },
      'params': [_amountBigInt.toString()]
    };
  }

  Future<void> _onSubmit() async {
    final params = await _getTxParams();
    if (params == null) return null;

    final res = (await Navigator.of(context).pushNamed(TxConfirmPage.route,
        arguments: TxConfirmParams(
          module: 'earning',
          call: 'rebond',
          txTitle: 'Restake',
          txDisplayBold: params['detail'],
          params: params['params'],
          isPlugin: true,
        ))) as Map?;
    if (res != null) {
      Navigator.of(context).pop(res);
    }
  }

  @override
  void dispose() {
    _amountCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    var dic = I18n.of(context)!.getDic(i18n_full_dic_acala, 'acala')!;

    final args =
        ModalRoute.of(context)?.settings.arguments as List<List<BigInt>>;
    BigInt available = BigInt.zero;
    args.forEach((e) {
      available += e[0];
    });

    final availableView = Fmt.priceFloorBigInt(available, 12, lengthMax: 8);

    return PluginScaffold(
      appBar: PluginAppBar(
        title: Text(dic['earn.unbond.restake']!),
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
                    titleTag: dic['earn.unbond.restake'],
                    balance: TokenBalanceData(
                        symbol: 'ACA',
                        decimals: 12,
                        amount: available.toString()),
                    tokenIconsMap: widget.plugin.tokenIcons,
                    onSetMax: (max) {
                      {
                        setState(() {
                          _error1 = null;
                          _amountBigInt = max;
                          _amountCtrl.text =
                              Fmt.bigIntToDouble(max, 12).toString();
                        });
                        _onAmount1Change(
                          availableView,
                          available: available,
                          max: max,
                        );
                      }
                    },
                    onClear: () {
                      setState(() {
                        _amountBigInt = BigInt.zero;
                        _amountCtrl.text = "0";
                      });
                      _onAmount1Change("0", available: available);
                    },
                    inputCtrl: _amountCtrl,
                    onInputChange: (v) =>
                        _onAmount1Change(v, available: available),
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
                      _onSubmit();
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
