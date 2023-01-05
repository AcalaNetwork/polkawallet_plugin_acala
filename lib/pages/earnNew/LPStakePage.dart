import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:polkawallet_plugin_acala/api/types/dexPoolInfoData.dart';
import 'package:polkawallet_plugin_acala/common/constants/index.dart';
import 'package:polkawallet_plugin_acala/pages/swapNew/bootstrapPage.dart';
import 'package:polkawallet_plugin_acala/polkawallet_plugin_acala.dart';
import 'package:polkawallet_plugin_acala/utils/assets.dart';
import 'package:polkawallet_plugin_acala/utils/format.dart';
import 'package:polkawallet_plugin_acala/utils/i18n/index.dart';
import 'package:polkawallet_sdk/api/types/txInfoData.dart';
import 'package:polkawallet_sdk/plugin/store/balances.dart';
import 'package:polkawallet_sdk/storage/keyring.dart';
import 'package:polkawallet_sdk/utils/i18n.dart';
import 'package:polkawallet_ui/components/connectionChecker.dart';
import 'package:polkawallet_ui/components/txButton.dart';
import 'package:polkawallet_ui/components/v3/plugin/pluginButton.dart';
import 'package:polkawallet_ui/components/v3/plugin/pluginInputBalance.dart';
import 'package:polkawallet_ui/components/v3/plugin/pluginRadioButton.dart';
import 'package:polkawallet_ui/components/v3/plugin/pluginScaffold.dart';
import 'package:polkawallet_ui/pages/txConfirmPage.dart';
import 'package:polkawallet_ui/utils/format.dart';
import 'package:polkawallet_ui/utils/index.dart';

class LPStakePageParams {
  LPStakePageParams(this.pool, this.action);
  final String action;
  final DexPoolData pool;
}

class LPStakePage extends StatefulWidget {
  LPStakePage(this.plugin, this.keyring);
  final PluginAcala plugin;
  final Keyring keyring;

  static const String route = '/acala/earn/stake';
  static const String actionStake = 'stake';
  static const String actionUnStake = 'unStake';

  @override
  _LPStakePage createState() => _LPStakePage();
}

class _LPStakePage extends State<LPStakePage> {
  final TextEditingController _amountCtrl = new TextEditingController();

  final TextEditingController _amountLeftCtrl = new TextEditingController();
  final TextEditingController _amountRightCtrl = new TextEditingController();

  int _inputIndex = 0;
  BigInt? _maxInputLeft;
  BigInt? _maxInputRight;
  String? _errorLeft;
  String? _errorRight;
  double _price = 0;

  TxFeeEstimateResult? _fee;

  Timer? _timer;

  bool switchActive = true;

  bool _isMax = false;

  String? _error1;

  String? _validateAmount(String value, BigInt? available, int? decimals) {
    final dic = I18n.of(context)!.getDic(i18n_full_dic_acala, 'common');

    String v = value.trim();
    final error = Fmt.validatePrice(value, context);
    if (error != null) {
      return error;
    }
    BigInt input = Fmt.tokenInt(v, decimals!);
    if (!_isMax && input > available!) {
      return dic!['amount.low'];
    }
    final LPStakePageParams args =
        ModalRoute.of(context)!.settings.arguments as LPStakePageParams;
    final balance =
        widget.plugin.store!.assets.tokenBalanceMap[args.pool.tokenNameId];
    final balanceInt = Fmt.balanceInt(balance?.amount ?? '0');
    if (balanceInt == BigInt.zero) {
      final min = Fmt.balanceInt(balance?.minBalance ?? '0');
      if (input < min) {
        return '${dic!['amount.min']} ${Fmt.priceCeilBigInt(min, decimals, lengthMax: 6)}';
      }
    }
    return null;
  }

  void _onSetMax(BigInt? max, int? decimals) {
    setState(() {
      _amountCtrl.text = Fmt.bigIntToDouble(max, decimals!).toStringAsFixed(6);
      _isMax = true;
    });
  }

  Future<void> _onSubmit(BigInt? max, int? decimals) async {
    if (_error1 != null) return;

    final dic = I18n.of(context)!.getDic(i18n_full_dic_acala, 'acala')!;
    final LPStakePageParams params =
        ModalRoute.of(context)!.settings.arguments as LPStakePageParams;
    final isStake = params.action == LPStakePage.actionStake;

    final tokenPair = params.pool.tokens!
        .map((e) => AssetsUtils.tokenDataFromCurrencyId(widget.plugin, e))
        .toList();
    final poolTokenSymbol =
        tokenPair.map((e) => PluginFmt.tokenView(e.symbol)).toList().join('-');

    String input = _amountCtrl.text.trim();
    BigInt? amount = Fmt.tokenInt(input, decimals!);
    if (_isMax || max! - amount < BigInt.one) {
      amount = max;
      input = Fmt.token(max, decimals);
    }

    if (isStake && switchActive) {
      if (!_onValidate()) {
        return;
      }
      final addLiquidityParams = [
        params.pool.tokens![0],
        params.pool.tokens![1],
        _maxInputLeft != null
            ? _maxInputLeft.toString()
            : Fmt.tokenInt(
                    _amountLeftCtrl.text.trim(), tokenPair[0].decimals ?? 12)
                .toString(),
        _maxInputRight != null
            ? _maxInputRight.toString()
            : Fmt.tokenInt(
                    _amountRightCtrl.text.trim(), tokenPair[1].decimals ?? 12)
                .toString(),
        '0',
        true,
      ];
      final depositDexShareParams = [
        {'DEXShare': params.pool.tokens},
        amount.toString()
      ];
      final batchTxs = [
        'api.tx.dex.addLiquidity(...${jsonEncode(addLiquidityParams)})',
        'api.tx.incentives.depositDexShare(...${jsonEncode(depositDexShareParams)})',
      ];

      Map<String, Widget> txDisplayBold = {
        "Token 1": Text(
          '${_amountLeftCtrl.text.trim()} ${PluginFmt.tokenView(tokenPair[0].symbol)}',
          style: Theme.of(context)
              .textTheme
              .headline1
              ?.copyWith(color: Colors.white),
        ),
        "Token 2": Text(
          '${_amountRightCtrl.text.trim()} ${PluginFmt.tokenView(tokenPair[1].symbol)}',
          style: Theme.of(context)
              .textTheme
              .headline1
              ?.copyWith(color: Colors.white),
        ),
      };

      final res = (await Navigator.of(context).pushNamed(TxConfirmPage.route,
          arguments: TxConfirmParams(
            module: amount == BigInt.zero ? 'dex' : 'utility',
            call: amount == BigInt.zero ? 'addLiquidity' : 'batch',
            txTitle: '${dic['earn.${params.action}']} $poolTokenSymbol LP',
            txDisplay: {
              dic['earn.pool']: poolTokenSymbol,
              "": dic['v3.earn.addLiquidityEarn']
            },
            txDisplayBold: (amount == BigInt.zero
                ? {}
                : {
                    dic['loan.amount']!: Text(
                      '$input LP',
                      style: Theme.of(context)
                          .textTheme
                          .headline1
                          ?.copyWith(color: Colors.white),
                    )
                  })
              ..addAll(txDisplayBold),
            params: amount == BigInt.zero ? addLiquidityParams : [],
            rawParams:
                amount == BigInt.zero ? null : '[[${batchTxs.join(',')}]]',
            isPlugin: true,
          ))) as Map?;
      if (res != null) {
        Navigator.of(context).pop(res);
      }
    } else {
      if (input.trim() == "0" || input.trim().isEmpty) {
        return;
      }
      final res = (await Navigator.of(context).pushNamed(TxConfirmPage.route,
          arguments: TxConfirmParams(
            module: 'incentives',
            call: isStake ? 'depositDexShare' : 'withdrawDexShare',
            txTitle: '${dic['earn.${params.action}']} $poolTokenSymbol LP',
            txDisplay: {
              dic['earn.pool']: poolTokenSymbol,
            },
            txDisplayBold: {
              dic['loan.amount']!: Text(
                '$input LP',
                style: Theme.of(context)
                    .textTheme
                    .headline1
                    ?.copyWith(color: Colors.white),
              ),
            },
            params: [
              {'DEXShare': params.pool.tokens},
              amount.toString()
            ],
            isPlugin: true,
          ))) as Map?;
      if (res != null) {
        Navigator.of(context).pop(res);
      }
    }
  }

  Future<void> _refreshData() async {
    if (widget.plugin.sdk.api.connectedNode != null) {
      _getTxFee();

      await widget.plugin.service!.earn.updateAllDexPoolInfo();

      if (mounted) {
        final args =
            ModalRoute.of(context)!.settings.arguments as LPStakePageParams;
        final pool = args.pool;
        final balancePair = pool.tokens!
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

  String? _onValidateInput(int index) {
    if (index == 0 && _maxInputLeft != null) return null;
    if (index == 1 && _maxInputRight != null) return null;

    final dic = I18n.of(context)!.getDic(i18n_full_dic_acala, 'common');
    final args =
        ModalRoute.of(context)!.settings.arguments as LPStakePageParams;
    final pool = args.pool;
    final balancePair = pool.tokens!
        .map((e) => AssetsUtils.tokenDataFromCurrencyId(widget.plugin, e))
        .toList();

    final v =
        index == 0 ? _amountLeftCtrl.text.trim() : _amountRightCtrl.text.trim();
    final balance = balancePair[index];

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
        widget.plugin.store!.assets.tokenBalanceMap[pool.tokenNameId];
    final balanceInt = Fmt.balanceInt(balanceLP?.amount ?? '0');
    if (error == null && index == 0 && balanceInt == BigInt.zero) {
      double min = 0;
      final poolInfo =
          widget.plugin.store!.earn.dexPoolInfoMap[pool.tokenNameId]!;
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

  Widget addLiquidity(List<TokenBalanceData?> tokenPair, DexPoolData pool) {
    final dic = I18n.of(context)!.getDic(i18n_full_dic_acala, 'acala')!;
    final tokenPairView = [
      PluginFmt.tokenView(tokenPair[0]!.symbol),
      PluginFmt.tokenView(tokenPair[1]!.symbol)
    ];

    double userShare = 0;
    double amountLeft = 0;
    double amountRight = 0;

    final poolInfo = widget.plugin.store!.earn.dexPoolInfoMap[pool.tokenNameId];
    if (poolInfo != null) {
      amountLeft =
          Fmt.bigIntToDouble(poolInfo.amountLeft, tokenPair[0]?.decimals ?? 12);
      amountRight = Fmt.bigIntToDouble(
          poolInfo.amountRight, tokenPair[1]?.decimals ?? 12);

      String input = _amountLeftCtrl.text.trim();
      try {
        final double amountInput = double.parse(input.isEmpty ? '0' : input);
        userShare = amountInput / (amountLeft + amountInput);
      } catch (_) {
        // parse double failed
      }
    }

    return Container(
      child: Column(
        children: [
          GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () {
                setState(() {
                  switchActive = !switchActive;
                });
              },
              child: Padding(
                padding: EdgeInsets.only(top: 12, bottom: 30),
                child: Row(
                  children: [
                    PluginRadioButton(value: switchActive),
                    Padding(
                      padding: EdgeInsets.only(left: 4),
                      child: Text(
                          "${dic['v3.earn.addLiquidityEarn']} (${dic['earn.fee']}:${Fmt.ratio(widget.plugin.service!.earn.getSwapFee())})",
                          style: Theme.of(context)
                              .textTheme
                              .headline5
                              ?.copyWith(
                                  color: Colors.white,
                                  fontSize: UI.getTextSize(14, context))),
                    )
                  ],
                ),
              )),
          Visibility(
              visible: switchActive,
              child: Column(children: [
                Stack(
                  alignment: Alignment.center,
                  children: [
                    Column(
                      children: [
                        PluginInputBalance(
                          tokenViewFunction: (value) {
                            return PluginFmt.tokenView(value);
                          },
                          inputCtrl: _amountLeftCtrl,
                          onInputChange: (v) => _onSupplyAmountChange(v),
                          getMarketPrice: (tokenSymbol) =>
                              AssetsUtils.getMarketPrice(
                                  widget.plugin, tokenSymbol),
                          onSetMax: tokenPair[0]!.symbol == acala_token_ids[0]
                              ? null
                              : (v) => _onSetLeftMax(
                                  v, tokenPair[0]?.decimals ?? 12),
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
                          height: 40,
                        ),
                        PluginInputBalance(
                          tokenViewFunction: (value) {
                            return PluginFmt.tokenView(value);
                          },
                          inputCtrl: _amountRightCtrl,
                          onInputChange: (v) => _onTargetAmountChange(v),
                          getMarketPrice: (tokenSymbol) =>
                              AssetsUtils.getMarketPrice(
                                  widget.plugin, tokenSymbol),
                          onSetMax: tokenPair[1]!.symbol == acala_token_ids[0]
                              ? null
                              : (v) => _onSetRightMax(
                                  v, tokenPair[1]?.decimals ?? 12),
                          onClear: () {
                            setState(() {
                              _maxInputRight = null;
                              _amountRightCtrl.text = '';
                            });
                          },
                          balance: tokenPair[1],
                          tokenIconsMap: widget.plugin.tokenIcons,
                        ),
                      ],
                    ),
                    Padding(
                        padding: EdgeInsets.only(
                            top: tokenPair[0]!.symbol != acala_token_ids[0]
                                ? 20
                                : 0),
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
                  ],
                ),
                Container(
                  margin: EdgeInsets.only(top: 24),
                  child: _errorLeft == null && _errorRight == null
                      ? null
                      : Row(children: [
                          Text(
                            _errorLeft == null
                                ? "${PluginFmt.tokenView(tokenPair[1]!.symbol)} $_errorRight"
                                : "${PluginFmt.tokenView(tokenPair[0]!.symbol)} $_errorLeft",
                            style: TextStyle(
                                fontSize: UI.getTextSize(12, context),
                                color: Colors.red),
                          )
                        ]),
                ),
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
              ]))
        ],
      ),
    );
  }

  @override
  void dispose() {
    _timer?.cancel();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final dic = I18n.of(context)!.getDic(i18n_full_dic_acala, 'acala')!;
    final assetDic = I18n.of(context)!.getDic(i18n_full_dic_acala, 'common');

    final LPStakePageParams args =
        ModalRoute.of(context)!.settings.arguments as LPStakePageParams;

    final tokenPair = args.pool.tokens!
        .map((e) => AssetsUtils.tokenDataFromCurrencyId(widget.plugin, e))
        .toList();
    final poolTokenSymbol =
        PluginFmt.tokenView(tokenPair.map((e) => e.symbol).join('-'));

    return PluginScaffold(
      appBar: PluginAppBar(
          title: Text('${dic['earn.${args.action}']} $poolTokenSymbol'),
          centerTitle: true),
      body: SafeArea(
        child: Observer(
          builder: (_) {
            final isStake = args.action == LPStakePage.actionStake;

            BigInt? balance = BigInt.zero;
            if (!isStake) {
              final poolInfo = widget
                  .plugin.store!.earn.dexPoolInfoMap[args.pool.tokenNameId]!;
              balance = poolInfo.shares;
            } else {
              balance = Fmt.balanceInt(widget.plugin.store!.assets
                      .tokenBalanceMap[args.pool.tokenNameId]?.amount ??
                  '0');
            }

            return Column(
              children: [
                Expanded(
                  child: ListView(
                    padding: EdgeInsets.only(left: 16, right: 16),
                    children: [
                      isStake
                          ? ConnectionChecker(widget.plugin,
                              onConnected: _refreshData)
                          : Container(),
                      PluginInputBalance(
                        tokenViewFunction: (value) {
                          return PluginFmt.tokenView(value);
                        },
                        titleTag: assetDic!['amount'],
                        inputCtrl: _amountCtrl,
                        onSetMax: (balance ?? BigInt.zero) > BigInt.zero
                            ? (max) => _onSetMax(max, tokenPair[0].decimals)
                            : null,
                        onInputChange: (v) {
                          var error = _validateAmount(
                              v, balance, tokenPair[0].decimals);
                          setState(() {
                            _error1 = error;
                            _isMax = false;
                          });
                        },
                        onClear: () {
                          setState(() {
                            _error1 = null;
                            _amountCtrl.text = "";
                            _isMax = false;
                          });
                        },
                        balance: TokenBalanceData(
                            symbol: tokenPair.map((e) => e.symbol).join('-'),
                            decimals: tokenPair[0].decimals ?? 12,
                            amount: balance.toString()),
                        tokenIconsMap: widget.plugin.tokenIcons,
                      ),
                      ErrorMessage(
                        _error1,
                        margin: EdgeInsets.zero,
                      ),
                      isStake
                          ? addLiquidity(tokenPair, args.pool)
                          : Container(),
                    ],
                  ),
                ),
                Padding(
                  padding: EdgeInsets.all(16),
                  child: PluginButton(
                    title: dic['earn.${args.action}']!,
                    onPressed: () => _onSubmit(balance, tokenPair[0].decimals),
                  ),
                )
              ],
            );
          },
        ),
      ),
    );
  }
}
