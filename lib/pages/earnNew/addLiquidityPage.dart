import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:polkawallet_plugin_acala/api/types/dexPoolInfoData.dart';
import 'package:polkawallet_plugin_acala/common/components/InsufficientACAWarn.dart';
import 'package:polkawallet_plugin_acala/common/constants/index.dart';
import 'package:polkawallet_plugin_acala/pages/swapNew/swapPage.dart';
import 'package:polkawallet_plugin_acala/polkawallet_plugin_acala.dart';
import 'package:polkawallet_plugin_acala/utils/assets.dart';
import 'package:polkawallet_plugin_acala/utils/format.dart';
import 'package:polkawallet_plugin_acala/utils/i18n/index.dart';
import 'package:polkawallet_sdk/api/types/txInfoData.dart';
import 'package:polkawallet_sdk/storage/keyring.dart';
import 'package:polkawallet_sdk/utils/i18n.dart';
import 'package:polkawallet_ui/components/connectionChecker.dart';
import 'package:polkawallet_ui/components/listTail.dart';
import 'package:polkawallet_ui/components/txButton.dart';
import 'package:polkawallet_ui/components/v3/back.dart';
import 'package:polkawallet_ui/components/v3/plugin/pluginButton.dart';
import 'package:polkawallet_ui/components/v3/plugin/pluginInputBalance.dart';
import 'package:polkawallet_ui/components/v3/plugin/pluginRadioButton.dart';
import 'package:polkawallet_ui/components/v3/plugin/pluginScaffold.dart';
import 'package:polkawallet_ui/components/v3/plugin/roundedPluginCard.dart';
import 'package:polkawallet_ui/pages/txConfirmPage.dart';
import 'package:polkawallet_ui/utils/consts.dart';
import 'package:polkawallet_ui/utils/format.dart';
import 'package:polkawallet_ui/utils/index.dart';

class AddLiquidityPage extends StatefulWidget {
  AddLiquidityPage(this.plugin, this.keyring);
  final PluginAcala plugin;
  final Keyring keyring;

  static const String route = '/acala/earn/deposit';
  static const String actionDeposit = 'deposit';

  @override
  _AddLiquidityPageState createState() => _AddLiquidityPageState();
}

class _AddLiquidityPageState extends State<AddLiquidityPage> {
  final TextEditingController _amountLeftCtrl = new TextEditingController();
  final TextEditingController _amountRightCtrl = new TextEditingController();

  Timer? _timer;
  double _price = 0;
  bool _withStake = true;
  bool _withStakeAll = false;

  int _inputIndex = 0;
  BigInt? _maxInputLeft;
  BigInt? _maxInputRight;
  String? _errorLeft;
  String? _errorRight;

  TxFeeEstimateResult? _fee;

  Future<void> _refreshData() async {
    if (widget.plugin.sdk.api.connectedNode != null) {
      _getTxFee();

      await widget.plugin.service!.earn.updateAllDexPoolInfo();

      final args = ModalRoute.of(context)!.settings.arguments as Map?;
      final poolIndex = widget.plugin.store?.earn.dexPools
              .indexWhere((e) => e.tokenNameId == args?['poolId']) ??
          0;

      if (poolIndex > -1 && mounted) {
        final pool = widget.plugin.store?.earn.dexPools[poolIndex];
        final balancePair = pool!.tokens!
            .map((e) => AssetsUtils.tokenDataFromCurrencyId(widget.plugin, e))
            .toList();
        setState(() {
          final poolInfo =
              widget.plugin.store!.earn.dexPoolInfoMap[pool.tokenNameId]!;
          _price = Fmt.bigIntToDouble(
                  poolInfo.amountRight, balancePair[1].decimals ?? 12) /
              Fmt.bigIntToDouble(
                  poolInfo.amountLeft, balancePair[0].decimals ?? 12);
        });
        _timer = Timer(Duration(seconds: 30), () {
          _refreshData();
        });
      }
    }
  }

  Future<void> _onSupplyAmountChange(String supply,
      {bool isSetMax = false}) async {
    final value = supply.trim();
    double v = 0;
    try {
      v = value.isEmpty ? 0 : double.parse(value);
    } catch (e) {}
    setState(() {
      _inputIndex = 0;
      _amountRightCtrl.text = v == 0 ? '' : (v * _price).toStringAsFixed(8);
      // clear max input on amount changes
      if (!isSetMax) {
        _maxInputLeft = null;
      }
    });
    _onValidate();
  }

  Future<void> _onTargetAmountChange(String target,
      {bool isSetMax = false}) async {
    final value = target.trim();
    double v = 0;
    try {
      v = value.isEmpty ? 0 : double.parse(value);
    } catch (e) {}
    setState(() {
      _inputIndex = 1;
      _amountLeftCtrl.text = v == 0 ? '' : (v / _price).toStringAsFixed(8);
      // clear max input on amount changes
      if (!isSetMax) {
        _maxInputRight = null;
      }
    });
    _onValidate();
  }

  String? _onValidateInput(int index) {
    if (index == 0 && _maxInputLeft != null) return null;
    if (index == 1 && _maxInputRight != null) return null;

    final dic = I18n.of(context)!.getDic(i18n_full_dic_acala, 'common');
    final args = ModalRoute.of(context)!.settings.arguments as Map?;
    final pool = widget.plugin.store?.earn.dexPools
        .firstWhere((e) => e.tokenNameId == args?['poolId']);
    final balancePair = pool?.tokens!
        .map((e) => AssetsUtils.tokenDataFromCurrencyId(widget.plugin, e))
        .toList();

    final v =
        index == 0 ? _amountLeftCtrl.text.trim() : _amountRightCtrl.text.trim();
    final balance = balancePair![index];

    String? error = Fmt.validatePrice(v, context);
    if (error == null) {
      if ((index == 0 && _maxInputLeft == null) ||
          (index == 1 && _maxInputRight == null)) {
        BigInt available = Fmt.balanceInt(balance.amount ?? '0');
        // limit user's input for tx fee if token is KAR
        if (balance.symbol == acala_token_ids[0]) {
          final accountED = PluginFmt.getAccountED(widget.plugin);
          available -= accountED +
              Fmt.balanceInt(_fee?.partialFee?.toString()) * BigInt.two;
        }
        if (double.parse(v) >
            Fmt.bigIntToDouble(available, balance.decimals ?? 12)) {
          error = dic!['amount.low'];
        }
      }
    }

    // check if user's lp token balance meet existential deposit.
    final balanceLP =
        widget.plugin.store!.assets.tokenBalanceMap[pool?.tokenNameId];
    final balanceInt = Fmt.balanceInt(balanceLP?.amount ?? '0');
    if (error == null && index == 0 && balanceInt == BigInt.zero) {
      double min = 0;
      final poolInfo =
          widget.plugin.store!.earn.dexPoolInfoMap[pool?.tokenNameId]!;
      min = Fmt.balanceInt(balanceLP?.minBalance ?? '0') /
          poolInfo.issuance! *
          Fmt.bigIntToDouble(
              poolInfo.amountLeft, balancePair[0].decimals ?? 12);

      final inputLeft = _inputIndex == 0
          ? double.parse(_amountLeftCtrl.text.trim())
          : (double.parse(_amountRightCtrl.text.trim()) / _price);
      if (inputLeft < min) {
        error = '${dic!['amount.min']} ${Fmt.priceCeil(min, lengthMax: 6)}';
      }
    }

    return error;
  }

  bool _onValidate() {
    final errorLeft = _onValidateInput(0);
    if (errorLeft != null) {
      setState(() {
        _errorLeft = errorLeft;
        _maxInputLeft = null;
        _maxInputRight = null;
        _errorRight = null;
      });
      return false;
    }
    final errorRight = _onValidateInput(1);
    if (errorRight != null) {
      setState(() {
        _errorLeft = null;
        _maxInputLeft = null;
        _maxInputRight = null;
        _errorRight = errorRight;
      });
      return false;
    }
    setState(() {
      _errorLeft = null;
      _errorRight = null;
    });
    return true;
  }

  void _onSetLeftMax(BigInt max, int decimals) {
    final amount = Fmt.bigIntToDouble(max, decimals).toStringAsFixed(6);
    setState(() {
      _amountLeftCtrl.text = amount;
      _maxInputLeft = max;
      _maxInputRight = null;
    });
    _onSupplyAmountChange(amount, isSetMax: true);
  }

  void _onSetRightMax(BigInt max, int decimals) {
    final amount = Fmt.bigIntToDouble(max, decimals).toStringAsFixed(6);
    setState(() {
      _amountRightCtrl.text = amount;
      _maxInputLeft = null;
      _maxInputRight = max;
    });
    _onTargetAmountChange(amount, isSetMax: true);
  }

  Future<void> _onSubmit(int? decimalsLeft, int? decimalsRight) async {
    if (_onValidate()) {
      final dic = I18n.of(context)!.getDic(i18n_full_dic_acala, 'acala');
      final args = ModalRoute.of(context)!.settings.arguments as Map?;
      final pool = widget.plugin.store!.earn.dexPools
          .firstWhere((e) => e.tokenNameId == args?['poolId']);

      final amountLeft = _amountLeftCtrl.text.trim();
      final amountRight = _amountRightCtrl.text.trim();

      final params = [
        pool.tokens![0],
        pool.tokens![1],
        _maxInputLeft != null
            ? _maxInputLeft.toString()
            : Fmt.tokenInt(amountLeft, decimalsLeft!).toString(),
        _maxInputRight != null
            ? _maxInputRight.toString()
            : Fmt.tokenInt(amountRight, decimalsRight!).toString(),
        '0',
        _withStake,
      ];

      final tokenPair = pool.tokens!
          .map((e) => AssetsUtils.tokenDataFromCurrencyId(widget.plugin, e))
          .toList();
      if (_withStakeAll) {
        final balance =
            widget.plugin.store!.assets.tokenBalanceMap[pool.tokenNameId];
        final balanceInt = Fmt.balanceInt(balance?.amount);
        final batchTxs = [
          'api.tx.dex.addLiquidity(...${jsonEncode(params)})',
          'api.tx.incentives.depositDexShare({DEXShare: ${jsonEncode(pool.tokens)}}, "$balanceInt")',
        ];
        final res = (await Navigator.of(context).pushNamed(TxConfirmPage.route,
            arguments: TxConfirmParams(
              module: 'utility',
              call: 'batch',
              txTitle: I18n.of(context)!
                  .getDic(i18n_full_dic_acala, 'acala')!['earn.add'],
              txDisplay: {
                dic!['earn.pool']:
                    '${tokenPair[0].symbol}-${tokenPair[1].symbol}',
                "": dic['earn.withStake.info'],
                dic['earn.withStake.all']: '+ ' +
                    Fmt.priceFloorBigInt(balanceInt, balance?.decimals ?? 12,
                        lengthMax: 4) +
                    ' LP',
              },
              txDisplayBold: {
                "Token 1": Text(
                  '$amountLeft ${PluginFmt.tokenView(tokenPair[0].symbol)}',
                  style: Theme.of(context)
                      .textTheme
                      .headline1
                      ?.copyWith(color: Colors.white),
                ),
                "Token 2": Text(
                  '$amountRight ${PluginFmt.tokenView(tokenPair[1].symbol)}',
                  style: Theme.of(context)
                      .textTheme
                      .headline1
                      ?.copyWith(color: Colors.white),
                ),
              },
              params: [],
              rawParams: '[[${batchTxs.join(',')}]]',
              isPlugin: true,
            ))) as Map?;
        if (res != null) {
          Navigator.of(context).pop(res);
        }
      } else {
        final txDisplay = {
          dic!['earn.pool']: '${tokenPair[0].symbol}-${tokenPair[1].symbol}'
        };
        if (_withStake) {
          txDisplay[''] = dic['earn.withStake.info']!;
        }
        final res = (await Navigator.of(context).pushNamed(TxConfirmPage.route,
            arguments: TxConfirmParams(
              module: 'dex',
              call: 'addLiquidity',
              txTitle: I18n.of(context)!
                  .getDic(i18n_full_dic_acala, 'acala')!['earn.add'],
              txDisplay: txDisplay,
              txDisplayBold: {
                "Token 1": Text(
                  '$amountLeft ${PluginFmt.tokenView(tokenPair[0].symbol)}',
                  style: Theme.of(context)
                      .textTheme
                      .headline1
                      ?.copyWith(color: Colors.white),
                ),
                "Token 2": Text(
                  '$amountRight ${PluginFmt.tokenView(tokenPair[1].symbol)}',
                  style: Theme.of(context)
                      .textTheme
                      .headline1
                      ?.copyWith(color: Colors.white),
                ),
              },
              params: params,
              isPlugin: true,
            ))) as Map?;
        if (res != null) {
          Navigator.of(context).pop(res);
        }
      }
    }
  }

  Future<String> _getTxFee() async {
    if (_fee?.partialFee != null) {
      return _fee!.partialFee.toString();
    }

    final sender = TxSenderData(
        widget.keyring.current.address, widget.keyring.current.pubKey);
    final fee = await widget.plugin.sdk.api.tx
        .estimateFees(TxInfoData('dex', 'addLiquidity', sender), [
      {'Token': widget.plugin.networkState.tokenSymbol![0]},
      {'Token': relay_chain_token_symbol},
      '1000000000000',
      '100000000000',
      '0',
      true,
    ]);
    if (mounted) {
      setState(() {
        _fee = fee;
      });
    }
    return fee.partialFee.toString();
  }

  @override
  void dispose() {
    if (_timer != null) {
      _timer!.cancel();
      _timer = null;
    }

    _amountLeftCtrl.dispose();
    _amountRightCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(_) {
    return Observer(
      builder: (BuildContext context) {
        final dic = I18n.of(context)!.getDic(i18n_full_dic_acala, 'acala')!;
        final args = ModalRoute.of(context)!.settings.arguments as Map?;

        if (widget.plugin.sdk.api.connectedNode == null ||
            widget.plugin.store!.earn.dexPools.length == 0) {
          return Scaffold(
            appBar: AppBar(
              title: Text(dic['earn.add']!),
              centerTitle: true,
              leading: BackBtn(),
            ),
            body: SafeArea(
              child: ListView(children: [
                ConnectionChecker(widget.plugin, onConnected: _refreshData),
                SwapSkeleton()
              ]),
            ),
          );
        }

        final poolIndex = widget.plugin.store!.earn.dexPools
            .indexWhere((e) => e.tokenNameId == args?['poolId']);
        if (poolIndex < 0) {
          return PluginScaffold(
            appBar: PluginAppBar(
              title: Text(dic['earn.add']!),
              centerTitle: true,
            ),
            body: SafeArea(
              child: ListView(children: [
                Center(
                    child: ListTail(
                  isEmpty: true,
                  isLoading: false,
                  color: Colors.white,
                ))
              ]),
            ),
          );
        }

        final pool = widget.plugin.store!.earn.dexPools[poolIndex];
        final tokenPair = pool.tokens!
            .map((e) => AssetsUtils.tokenDataFromCurrencyId(widget.plugin, e))
            .toList();
        final tokenPairView = [
          PluginFmt.tokenView(tokenPair[0].symbol),
          PluginFmt.tokenView(tokenPair[1].symbol)
        ];

        final nativeBalance = Fmt.balanceInt(
            widget.plugin.balances.native!.availableBalance.toString());
        final accountED = PluginFmt.getAccountED(widget.plugin);

        double userShare = 0;

        double amountLeft = 0;
        double amountRight = 0;
        double issuance = 0;

        final poolInfo =
            widget.plugin.store!.earn.dexPoolInfoMap[pool.tokenNameId];
        if (poolInfo != null) {
          amountLeft = Fmt.bigIntToDouble(
              poolInfo.amountLeft, tokenPair[0].decimals ?? 12);
          amountRight = Fmt.bigIntToDouble(
              poolInfo.amountRight, tokenPair[1].decimals ?? 12);

          issuance = Fmt.bigIntToDouble(
              poolInfo.issuance, tokenPair[0].decimals ?? 12);

          String input = _amountLeftCtrl.text.trim();
          try {
            final double amountInput =
                double.parse(input.isEmpty ? '0' : input);
            userShare = amountInput / (amountLeft + amountInput);
          } catch (_) {
            // parse double failed
          }
        }

        const slippage = 0.005;
        if (userShare > 0) {
          userShare = userShare * (1 - slippage);
        }

        return PluginScaffold(
          appBar: PluginAppBar(
            title: Text(dic['earn.add']!),
            centerTitle: true,
          ),
          body: SafeArea(
              child: ListView(
            padding: EdgeInsets.only(top: 16, left: 16, right: 16),
            children: <Widget>[
              ConnectionChecker(widget.plugin, onConnected: _refreshData),
              Visibility(
                visible: nativeBalance - accountED <
                    Fmt.balanceInt((_fee?.partialFee ?? 0).toString()) *
                        BigInt.two,
                child: InsufficientACAWarn(),
              ),
              PluginInputBalance(
                tokenViewFunction: (value) {
                  return PluginFmt.tokenView(value);
                },
                inputCtrl: _amountLeftCtrl,
                titleTag: 'token 1',
                onInputChange: (v) => _onSupplyAmountChange(v),
                onSetMax: tokenPair[0].symbol == acala_token_ids[0]
                    ? null
                    : (v) => _onSetLeftMax(v, tokenPair[0].decimals ?? 12),
                onClear: () {
                  setState(() {
                    _maxInputLeft = null;
                    _amountLeftCtrl.text = '';
                  });
                },
                balance: tokenPair[0],
                tokenIconsMap: widget.plugin.tokenIcons,
              ),
              Container(
                margin: EdgeInsets.only(top: 2),
                child: _errorLeft == null
                    ? null
                    : Row(children: [
                        Text(
                          _errorLeft!,
                          style: TextStyle(
                              fontSize: UI.getTextSize(12, context),
                              color: Colors.red),
                        )
                      ]),
              ),
              Padding(
                  padding: EdgeInsets.only(top: 22),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.add,
                        color: Colors.white,
                        size: 32,
                      )
                    ],
                  )),
              PluginInputBalance(
                tokenViewFunction: (value) {
                  return PluginFmt.tokenView(value);
                },
                inputCtrl: _amountRightCtrl,
                titleTag: 'token 2',
                onInputChange: (v) => _onTargetAmountChange(v),
                onSetMax: tokenPair[1].symbol == acala_token_ids[0]
                    ? null
                    : (v) => _onSetRightMax(v, tokenPair[1].decimals ?? 12),
                onClear: () {
                  setState(() {
                    _maxInputRight = null;
                    _amountRightCtrl.text = '';
                  });
                },
                balance: tokenPair[1],
                tokenIconsMap: widget.plugin.tokenIcons,
              ),
              Container(
                margin: EdgeInsets.only(top: 2),
                child: _errorRight == null
                    ? null
                    : Row(children: [
                        Text(
                          _errorRight!,
                          style: TextStyle(
                              fontSize: UI.getTextSize(12, context),
                              color: Colors.red),
                        )
                      ]),
              ),
              Padding(
                  padding: EdgeInsets.only(top: 24),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Expanded(
                        child: Text(
                          dic['v3.earn.lpTokenReceived']!,
                          style: Theme.of(context)
                              .textTheme
                              .headline4
                              ?.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600),
                        ),
                      ),
                      Text(
                          '${Fmt.doubleFormat(issuance * userShare, length: 4)} LP Token',
                          textAlign: TextAlign.right,
                          style:
                              Theme.of(context).textTheme.headline4?.copyWith(
                                    color: Colors.white,
                                  )),
                    ],
                  )),
              Padding(
                  padding: EdgeInsets.only(top: 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Expanded(
                        child: Text(
                          dic['dex.rate']!,
                          style: Theme.of(context)
                              .textTheme
                              .headline4
                              ?.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600),
                        ),
                      ),
                      Text(
                          '1 ${tokenPairView[0]} = ${Fmt.doubleFormat(_price, length: 4)} ${tokenPairView[1]}\n1 ${tokenPairView[1]} = ${Fmt.doubleFormat(1 / _price, length: 4)} ${tokenPairView[0]}',
                          textAlign: TextAlign.right,
                          style:
                              Theme.of(context).textTheme.headline4?.copyWith(
                                    color: Colors.white,
                                  )),
                    ],
                  )),
              Padding(
                  padding: EdgeInsets.only(top: 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Expanded(
                        child: Text(
                          dic['earn.pool']!,
                          style: Theme.of(context)
                              .textTheme
                              .headline4
                              ?.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600),
                        ),
                      ),
                      Text(
                          '${Fmt.doubleFormat(amountLeft)} ${tokenPairView[0]}\n+ ${Fmt.doubleFormat(amountRight)} ${tokenPairView[1]}',
                          textAlign: TextAlign.right,
                          style:
                              Theme.of(context).textTheme.headline4?.copyWith(
                                    color: Colors.white,
                                  )),
                    ],
                  )),
              Padding(
                  padding: EdgeInsets.only(top: 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: <Widget>[
                      Expanded(
                        child: Text(
                          dic['earn.share']!,
                          style: Theme.of(context)
                              .textTheme
                              .headline4
                              ?.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600),
                        ),
                      ),
                      Text(Fmt.ratio(userShare),
                          style:
                              Theme.of(context).textTheme.headline4?.copyWith(
                                    color: Colors.white,
                                  )),
                    ],
                  )),
              StakeLPTips(
                widget.plugin,
                pool: pool,
                poolSymbol: tokenPair.join('-'),
                switchActive: _withStake,
                switch1Active: _withStakeAll,
                onSwitch: (v) {
                  setState(() {
                    _withStake = v;
                  });
                },
                onSwitch1: (v) {
                  setState(() {
                    _withStakeAll = v;
                    if (v && !_withStake) {
                      _withStake = v;
                    }
                  });
                },
              ),
              Padding(
                  padding: EdgeInsets.only(top: 37, bottom: 38),
                  child: PluginButton(
                    title: dic['earn.add']!,
                    onPressed: () =>
                        _onSubmit(tokenPair[0].decimals, tokenPair[1].decimals),
                  )),
            ],
          )),
        );
      },
    );
  }
}

class StakeLPTips extends StatelessWidget {
  StakeLPTips(this.plugin,
      {this.poolSymbol,
      this.pool,
      this.switchActive,
      this.switch1Active,
      this.onSwitch,
      this.onSwitch1,
      this.color = const Color(0xFF3A3D40),
      this.padding,
      this.margin});
  final PluginAcala plugin;
  final String? poolSymbol;
  final DexPoolData? pool;
  final bool? switchActive;
  final bool? switch1Active;
  final Function(bool)? onSwitch;
  final Function(bool)? onSwitch1;
  final Color color;
  final EdgeInsetsGeometry? margin;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    final dic = I18n.of(context)!.getDic(i18n_full_dic_acala, 'acala');
    return Observer(builder: (_) {
      double rewardAPY = 0;

      if (plugin.store!.earn.incentives.dex != null) {
        (plugin.store!.earn.incentives.dex![pool!.tokenNameId!] ?? [])
            .forEach((e) {
          rewardAPY += e.apr ?? 0;
        });
      }
      final balanceInt = Fmt.balanceInt(
          plugin.store!.assets.tokenBalanceMap[pool!.tokenNameId]?.amount);

      final switch1Visible = balanceInt > BigInt.zero && onSwitch1 != null;
      return Column(
        children: [
          RoundedPluginCard(
              margin: this.margin ?? EdgeInsets.only(top: 32, bottom: 16),
              padding: this.padding ?? EdgeInsets.fromLTRB(8, 20, 8, 20),
              color: color,
              child: Column(children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Mining ${dic!['earn.apy']}: ',
                      style: Theme.of(context).textTheme.headline3?.copyWith(
                          fontSize: UI.getTextSize(26, context),
                          color: Colors.white),
                    ),
                    Text(
                      Fmt.ratio(rewardAPY),
                      style: Theme.of(context).textTheme.headline3?.copyWith(
                          fontSize: UI.getTextSize(26, context),
                          color: PluginColorsDark.primary),
                    ),
                  ],
                ),
                GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () {
                      onSwitch!(!switchActive!);
                    },
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        PluginRadioButton(value: switchActive!),
                        Padding(
                          padding: EdgeInsets.only(left: 4),
                          child: Text(dic['earn.withStake.info']!,
                              style: Theme.of(context)
                                  .textTheme
                                  .headline5
                                  ?.copyWith(
                                      color: Colors.white,
                                      fontSize: UI.getTextSize(14, context))),
                        )
                      ],
                    )),
              ])),
          Visibility(
              visible: switch1Visible,
              child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () {
                    onSwitch1!(!(switch1Active ?? false));
                  },
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      PluginRadioButton(value: switch1Active ?? false),
                      Padding(
                        padding: EdgeInsets.only(left: 4),
                        child: Text(dic['earn.withStake.all.txt']!,
                            style: Theme.of(context)
                                .textTheme
                                .headline5
                                ?.copyWith(
                                    color: Colors.white,
                                    fontSize: UI.getTextSize(14, context))),
                      )
                    ],
                  ))),
        ],
      );
    });
  }
}
