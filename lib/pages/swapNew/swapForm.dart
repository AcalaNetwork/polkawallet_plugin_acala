import 'dart:async';
import 'dart:math';

import 'package:decimal/decimal.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:polkawallet_plugin_acala/api/types/swapOutputData.dart';
import 'package:polkawallet_plugin_acala/common/components/InsufficientACAWarn.dart';
import 'package:polkawallet_plugin_acala/common/constants/index.dart';
import 'package:polkawallet_plugin_acala/pages/swapNew/bootstrapPage.dart';
import 'package:polkawallet_plugin_acala/pages/swapNew/swapPage.dart';
import 'package:polkawallet_plugin_acala/polkawallet_plugin_acala.dart';
import 'package:polkawallet_plugin_acala/utils/assets.dart';
import 'package:polkawallet_plugin_acala/utils/format.dart';
import 'package:polkawallet_plugin_acala/utils/i18n/index.dart';
import 'package:polkawallet_sdk/api/types/txInfoData.dart';
import 'package:polkawallet_sdk/storage/keyring.dart';
import 'package:polkawallet_sdk/utils/i18n.dart';
import 'package:polkawallet_ui/components/txButton.dart';
import 'package:polkawallet_ui/components/v3/index.dart' as v3;
import 'package:polkawallet_ui/components/v3/plugin/pluginButton.dart';
import 'package:polkawallet_ui/components/v3/plugin/pluginInputBalance.dart';
import 'package:polkawallet_ui/components/v3/plugin/pluginOutlinedButtonSmall.dart';
import 'package:polkawallet_ui/components/v3/plugin/pluginTokenIcon.dart';
import 'package:polkawallet_ui/pages/txConfirmPage.dart';
import 'package:polkawallet_ui/utils/format.dart';
import 'package:polkawallet_ui/utils/i18n.dart';
import 'package:polkawallet_ui/utils/index.dart';
import 'package:rive/rive.dart';

class SwapForm extends StatefulWidget {
  SwapForm(this.plugin, this.keyring, {this.initialSwapPair});
  final PluginAcala plugin;
  final Keyring keyring;
  final List<String>? initialSwapPair;

  @override
  _SwapFormState createState() => _SwapFormState();
}

class _SwapFormState extends State<SwapForm>
    with SingleTickerProviderStateMixin {
  final TextEditingController _amountPayCtrl = new TextEditingController();
  final TextEditingController _amountReceiveCtrl = new TextEditingController();
  final TextEditingController _amountSlippageCtrl = new TextEditingController();

  final _slippageFocusNode = FocusNode();

  String? _error;
  String? _errorReceive;
  String? _interfaceError;
  double _slippage = 0.005;
  bool _slippageSettingVisible = false;
  String? _slippageError;
  List<String?> _swapPair = [];
  int _swapMode = 0; // 0 for 'EXACT_INPUT' and 1 for 'EXACT_OUTPUT'
  double? _swapRatio = 0;
  SwapOutputData _swapOutput = SwapOutputData();

  TxFeeEstimateResult? _fee;
  BigInt? _maxInput;

  // use a _timer to update page data consistently
  Timer? _timer;
  // use another _timer to control swap amount query
  Timer? _delayTimer;

  bool rateReversed = false;
  bool _detailShow = false;

  AnimationController? _animationController;
  Animation<double>? _animation;
  double angle = 0;

  bool _isLoading = false;

  Future<void> _getTxFee() async {
    final sender = TxSenderData(
        widget.keyring.current.address, widget.keyring.current.pubKey);
    final txInfo = TxInfoData('balances', 'transfer', sender);
    final fee = await widget.plugin.sdk.api.tx
        .estimateFees(txInfo, [widget.keyring.current.address, '10000000000']);
    if (mounted) {
      setState(() {
        _fee = fee;
      });
    }
  }

  Future<void> _switchPair() async {
    final pay = _amountPayCtrl.text;
    setState(() {
      _maxInput = null;
      _swapPair = [_swapPair[1], _swapPair[0]];
      _amountPayCtrl.text = _amountReceiveCtrl.text;
      _amountReceiveCtrl.text = pay;
      _swapMode = _swapMode == 0 ? 1 : 0;
    });
    widget.plugin.store!.swap
        .setSwapPair(_swapPair, widget.keyring.current.pubKey);

    await _updateSwapAmount();
  }

  bool _onCheckBalance() {
    if (_interfaceError != null) {
      return false;
    }
    final dic = I18n.of(context)!.getDic(i18n_full_dic_acala, 'common');
    final v = _amountPayCtrl.text.trim();
    final balancePair =
        AssetsUtils.getBalancePairFromTokenNameId(widget.plugin, _swapPair);

    String? error = Fmt.validatePrice(v, context);
    String? errorReceive;

    if (error == null) {
      if (_maxInput == null) {
        BigInt available = Fmt.balanceInt(balancePair[0].amount ?? '0');
        // limit user's input for tx fee if token is KAR
        if (balancePair[0].symbol == acala_token_ids[0]) {
          final accountED = PluginFmt.getAccountED(widget.plugin);
          available -= accountED +
              Fmt.balanceInt(_fee?.partialFee?.toString()) * BigInt.two;
        }
        if (double.parse(v) >
            Fmt.bigIntToDouble(available, balancePair[0].decimals!)) {
          error = dic!['amount.low'];
        }
      }

      // check if user's receive token balance meet existential deposit.
      final decimalReceive = balancePair[1].decimals!;
      final receiveMin = Fmt.balanceDouble(
          AssetsUtils.getBalanceFromTokenNameId(widget.plugin, _swapPair[1])
              .minBalance!,
          decimalReceive);
      if ((Fmt.balanceDouble(balancePair[1].amount!, decimalReceive) == 0.0) &&
          double.parse(_amountReceiveCtrl.text) < receiveMin) {
        errorReceive =
            '${dic!['amount.min']} ${Fmt.priceCeil(receiveMin, lengthMax: 6)}';
      }
    }
    setState(() {
      _error = error;
      _errorReceive = errorReceive;
    });
    return error == null && _errorReceive == null;
  }

  void _onSupplyAmountChange(String v) {
    String supply = v.trim();
    setState(() {
      _swapMode = 0;
      _maxInput = null;
    });

    _onInputChange(supply);
  }

  void _onTargetAmountChange(String v) {
    String target = v.trim();
    setState(() {
      _swapMode = 1;
      _maxInput = null;
    });

    _onInputChange(target);
  }

  void _onInputChange(String input) {
    setState(() {
      _isLoading = true;
    });
    if (_delayTimer != null) {
      _delayTimer!.cancel();
    }
    _delayTimer = Timer(Duration(milliseconds: 500), () {
      if (_swapMode == 0) {
        _calcSwapAmount(input, null);
      } else {
        _calcSwapAmount(null, input);
      }
    });
  }

  Future<void> _updateSwapAmount() async {
    if (_swapMode == 0) {
      if (_amountPayCtrl.text.trim().isNotEmpty) {
        await _calcSwapAmount(_amountPayCtrl.text.trim(), null);
      }
    } else {
      if (_amountReceiveCtrl.text.trim().isNotEmpty) {
        await _calcSwapAmount(null, _amountReceiveCtrl.text.trim());
      }
    }
  }

  void _setUpdateTimer() {
    if (widget.plugin.sdk.api.connectedNode != null) {
      _updateSwapAmount();
    }

    if (mounted) {
      _timer = Timer(Duration(seconds: 10), () {
        _setUpdateTimer();
      });
    }
  }

  Future<void> _calcSwapAmount(String? supply, String? target) async {
    if (_swapPair.length < 2) return;
    _interfaceError = null;

    widget.plugin.service!.assets.queryMarketPrices(withDexPrice: false);

    supply = supply != null ? Decimal.parse(supply).toString() : supply;
    target = target != null ? Decimal.parse(target).toString() : target;
    try {
      if (supply == null) {
        final inputAmount = double.tryParse(target!);
        if (inputAmount == 0.0) return;

        final output = await widget.plugin.api!.swap.queryTokenSwapAmount(
          supply,
          target.isEmpty ? '1' : target,
          _swapPair,
          _slippage.toString(),
        );
        if (mounted) {
          setState(() {
            if (target!.isNotEmpty) {
              _amountPayCtrl.text = output.amount.toString();
            } else {
              _amountPayCtrl.text = '';
            }
            _swapRatio = target.isEmpty
                ? output.amount
                : double.parse(target) / output.amount!;
            _swapOutput = output;
          });
          _onCheckBalance();
        }
      } else if (target == null) {
        final inputAmount = double.tryParse(supply);
        if (inputAmount == 0.0) return;

        final output = await widget.plugin.api!.swap.queryTokenSwapAmount(
          supply.isEmpty ? '1' : supply,
          target,
          _swapPair,
          _slippage.toString(),
        );
        if (mounted) {
          setState(() {
            if (supply!.isNotEmpty) {
              _amountReceiveCtrl.text = output.amount.toString();
            } else {
              _amountReceiveCtrl.text = '';
            }
            _swapRatio = supply.isEmpty
                ? output.amount
                : output.amount! / double.parse(supply);
            _swapOutput = output;
          });
          _onCheckBalance();
        }
      }
      setState(() {
        _isLoading = false;
      });
    } on Exception catch (err) {
      setState(() {
        _interfaceError = err.toString().split(':')[1];
        _isLoading = false;
      });
    }
  }

  void _onSetSlippage() {
    setState(() {
      _slippageSettingVisible = !_slippageSettingVisible;
    });
  }

  void _onSlippageChange(String v) {
    final Map? dic = I18n.of(context)!.getDic(i18n_full_dic_acala, 'acala');
    if (v.trim().isEmpty) {
      setState(() {
        _slippageError = null;
      });
      _updateSlippage(0.005, custom: true);
      return;
    }
    try {
      double value = double.parse(v.trim());
      if (value >= 50 || value < 0.1) {
        setState(() {
          _slippageError = dic!['dex.slippage.error'];
        });
      } else {
        setState(() {
          _slippageError = null;
        });
        _updateSlippage(value / 100, custom: true);
      }
    } catch (err) {
      setState(() {
        _slippageError = dic!['dex.slippage.error'];
      });
    }
  }

  Future<void> _updateSlippage(double input, {bool custom = false}) async {
    if (!custom) {
      _slippageFocusNode.unfocus();
      setState(() {
        _amountSlippageCtrl.text = '';
        _slippageError = null;
      });
    }
    setState(() {
      _slippage = input;
    });
    if (_swapMode == 0) {
      await _calcSwapAmount(_amountPayCtrl.text.trim(), null);
    } else {
      await _calcSwapAmount(null, _amountReceiveCtrl.text.trim());
    }
  }

  void _onSetMax(BigInt max, int decimals, {BigInt? nativeKeepAlive}) {
    // keep some KAR for tx fee
    BigInt input = _swapPair[0] == acala_token_ids[0] &&
            (max - nativeKeepAlive! > BigInt.zero)
        ? max - nativeKeepAlive
        : max;

    var amount = Fmt.bigIntToDouble(input, decimals).toStringAsFixed(6);

    final inputString =
        Fmt.bigIntToDouble(input, decimals).toString().split(".");
    if (inputString.length > 1 && inputString[1].length > 6) {
      amount = "${inputString[0]}.${inputString[1].substring(0, 6)}";
    }
    setState(() {
      _swapMode = 0;
      _amountPayCtrl.text = amount;
      _maxInput = input;
      _error = null;
      _errorReceive = null;
    });
    _onInputChange(Fmt.bigIntToDouble(input, decimals).toStringAsFixed(20));
  }

  Future<void> _onSubmit(List<int?> pairDecimals, double minMax) async {
    if (_onCheckBalance() && !_isLoading) {
      final dic = I18n.of(context)!.getDic(i18n_full_dic_acala, 'acala')!;

      final pay = Decimal.parse(_amountPayCtrl.text.trim()).toString();
      final receive = Decimal.parse(_amountReceiveCtrl.text.trim()).toString();
      final res = await Navigator.of(context).pushNamed(TxConfirmPage.route,
          arguments: TxConfirmParams(
              module: _swapOutput.tx!["section"],
              call: _swapOutput.tx!["method"],
              txTitle: dic['dex.title'],
              txDisplayBold: {
                dic['dex.pay']!: Text(
                  '$pay ${PluginFmt.tokenView(AssetsUtils.getBalanceFromTokenNameId(widget.plugin, _swapPair[0]).symbol)}',
                  style: Theme.of(context)
                      .textTheme
                      .headline1
                      ?.copyWith(color: Colors.white),
                ),
                dic['dex.receive']!: Text(
                  '$receive ${PluginFmt.tokenView(AssetsUtils.getBalanceFromTokenNameId(widget.plugin, _swapPair[1]).symbol)}',
                  style: Theme.of(context)
                      .textTheme
                      .headline1
                      ?.copyWith(color: Colors.white),
                ),
              },
              params: _swapOutput.tx!["params"],
              txHex: _swapOutput.tx!["txHex"],
              isPlugin: true,
              onStatusChange: (status) {
                if (status ==
                    I18n.of(context)!
                        .getDic(i18n_full_dic_ui, 'common')!['tx.Ready']) {
                  setState(() {
                    _amountReceiveCtrl.text = "";
                    _amountPayCtrl.text = "";
                    _detailShow = false;
                    _error = null;
                    _errorReceive = null;
                  });
                }
              }));
      if (res != null) {
        widget.plugin.updateBalances(widget.keyring.current);
      }
    }
  }

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      _getTxFee();

      final cachedSwapPair =
          widget.plugin.store!.swap.swapPair(widget.keyring.current.pubKey);
      if (widget.initialSwapPair != null &&
          widget.initialSwapPair?.length == 2) {
        setState(() {
          _swapPair = widget.initialSwapPair!;
        });
      } else if (cachedSwapPair.length > 0 &&
          AssetsUtils.getBalanceFromTokenNameId(
                      widget.plugin, cachedSwapPair[0])
                  .symbol !=
              null &&
          AssetsUtils.getBalanceFromTokenNameId(
                      widget.plugin, cachedSwapPair[1])
                  .symbol !=
              null) {
        setState(() {
          _swapPair = cachedSwapPair;
        });
      } else {
        final tokens = PluginFmt.getAllDexTokens(widget.plugin);
        if (tokens.length > 1) {
          setState(() {
            _swapPair =
                tokens.sublist(0, 2).map((e) => e!.tokenNameId).toList();
          });
        } else {
          setState(() {
            _swapPair = [
              widget.plugin.networkState.tokenSymbol![0],
              relay_chain_token_symbol
            ];
          });
        }
      }

      _setUpdateTimer();
    });

    _animationController = AnimationController(
        duration: const Duration(milliseconds: 300), vsync: this);
    _animation = Tween(begin: 0.0, end: pi).animate(_animationController!)
      ..addListener(() {
        setState(() {
          angle = _animation!.value;
        });
      });
  }

  @override
  void dispose() {
    _amountPayCtrl.dispose();
    _amountReceiveCtrl.dispose();
    _slippageFocusNode.dispose();

    if (_timer != null) {
      _timer!.cancel();
      _timer = null;
    }

    super.dispose();
  }

  @override
  Widget build(_) {
    return Observer(
      builder: (BuildContext context) {
        final dic = I18n.of(context)!.getDic(i18n_full_dic_acala, 'acala')!;
        final dicGov = I18n.of(context)!.getDic(i18n_full_dic_acala, 'gov')!;

        final currencyOptionsLeft = PluginFmt.getAllDexTokens(widget.plugin);
        final currencyOptionsRight = currencyOptionsLeft.toList();
        final List<String?> swapPair = _swapPair.length > 1
            ? _swapPair
            : currencyOptionsLeft.length > 2
                ? currencyOptionsLeft
                    .sublist(0, 2)
                    .map((e) => e!.tokenNameId)
                    .toList()
                : [];

        if (widget.plugin.sdk.api.connectedNode == null ||
            swapPair.length < 2) {
          return ListView(
            children: [SwapSkeleton()],
          );
        }

        if (swapPair.length > 1) {
          currencyOptionsLeft.retainWhere((i) => i!.tokenNameId != swapPair[0]);
          currencyOptionsRight
              .retainWhere((i) => i!.tokenNameId != swapPair[1]);
        }

        final balancePair =
            AssetsUtils.getBalancePairFromTokenNameId(widget.plugin, swapPair);
        final nativeBalance = Fmt.balanceInt(
            widget.plugin.balances.native!.availableBalance.toString());
        final accountED = PluginFmt.getAccountED(widget.plugin);
        final nativeKeepAlive = accountED +
            Fmt.balanceInt((_fee?.partialFee ?? 0).toString()) * BigInt.two;
        final isNativeTokenLow = nativeBalance < nativeKeepAlive;

        double minMax = 0;
        if (_swapOutput.amount != null) {
          minMax = _swapMode == 0
              ? _swapOutput.amount! * (1 - _slippage)
              : _swapOutput.amount! * (1 + _slippage);
        }

        final showExchangeRate = swapPair.length > 1 &&
            _amountPayCtrl.text.isNotEmpty &&
            _amountReceiveCtrl.text.isNotEmpty &&
            double.parse(_amountReceiveCtrl.text.trim()) > 0;

        String? amountLowError;
        if (swapPair.length > 1 &&
            _amountPayCtrl.text.isNotEmpty &&
            _amountReceiveCtrl.text.isNotEmpty &&
            double.parse(_amountReceiveCtrl.text.trim()) == 0) {
          amountLowError = dic['v3.loan.amountLowError'];
        }

        final labelStyle = Theme.of(context)
            .textTheme
            .headline5
            ?.copyWith(color: Colors.white);

        final tokensAll = ['ACA', 'KAR', 'DOT', 'KSM', 'AUSD'];

        return ListView(
          padding: EdgeInsets.all(16),
          children: <Widget>[
            Visibility(
              visible: isNativeTokenLow,
              child: InsufficientACAWarn(),
            ),
            Stack(alignment: Alignment.center, children: [
              Column(
                children: [
                  PluginInputBalance(
                      key: Key("1"),
                      titleTag: dic['dex.pay'],
                      tokenViewFunction: (value) {
                        return PluginFmt.tokenView(value);
                      },
                      margin: EdgeInsets.only(bottom: 7),
                      inputCtrl: _amountPayCtrl,
                      tokenOptions: currencyOptionsLeft,
                      quickTokenOptions: currencyOptionsLeft
                          .where((element) => (tokensAll
                                  .contains(element?.symbol?.toUpperCase()) ||
                              tokensAll.contains(element?.name?.toUpperCase())))
                          .toList(),
                      tokenSelectTitle: dic['v3.swap.selectToken']!,
                      getMarketPrice: (tokenSymbol) =>
                          AssetsUtils.getMarketPrice(
                              widget.plugin, tokenSymbol),
                      onInputChange: _onSupplyAmountChange,
                      onTokenChange: (token) {
                        setState(() {
                          _swapPair = token.tokenNameId == swapPair[1]
                              ? [token.tokenNameId, swapPair[0]]
                              : [token.tokenNameId, swapPair[1]];
                          _maxInput = null;
                          _isLoading = true;
                        });
                        widget.plugin.store!.swap.setSwapPair(
                            _swapPair, widget.keyring.current.pubKey);
                        _updateSwapAmount();
                      },
                      onClear: () {
                        setState(() {
                          _maxInput = null;
                          _amountPayCtrl.text = '';
                        });
                      },
                      balance: balancePair[0],
                      tokenIconsMap: widget.plugin.tokenIcons,
                      onSetMax:
                          Fmt.balanceInt(balancePair[0].amount) > BigInt.zero &&
                                  balancePair[0].symbol != acala_token_ids[0]
                              ? (max) {
                                  _onSetMax(
                                      Fmt.balanceInt(balancePair[0].amount),
                                      balancePair[0].decimals!,
                                      nativeKeepAlive: nativeKeepAlive);
                                }
                              : null,
                      type: InputBalanceType.swapType,
                      bgBorderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(4),
                          topRight: Radius.circular(4))),
                  PluginInputBalance(
                    key: Key("2"),
                    margin: EdgeInsets.zero,
                    titleTag: dic['dex.receiveEstimate'],
                    tokenViewFunction: (value) {
                      return PluginFmt.tokenView(value);
                    },
                    inputCtrl: _amountReceiveCtrl,
                    tokenOptions: currencyOptionsRight,
                    quickTokenOptions: currencyOptionsRight
                        .where((element) => (tokensAll
                                .contains(element?.symbol?.toUpperCase()) ||
                            tokensAll.contains(element?.name?.toUpperCase())))
                        .toList(),
                    tokenSelectTitle: dic['v3.swap.selectToken']!,
                    getMarketPrice: (tokenSymbol) =>
                        AssetsUtils.getMarketPrice(widget.plugin, tokenSymbol),
                    onInputChange: _onTargetAmountChange,
                    onTokenChange: (token) {
                      setState(() {
                        _swapPair = token.tokenNameId == swapPair[0]
                            ? [swapPair[1], token.tokenNameId]
                            : [swapPair[0], token.tokenNameId];
                        _maxInput = null;
                        _isLoading = true;
                      });
                      widget.plugin.store!.swap.setSwapPair(
                          _swapPair, widget.keyring.current.pubKey);
                      _updateSwapAmount();
                    },
                    // onSetMax: Fmt.balanceInt(balancePair[0]!.amount) > BigInt.zero
                    //     ? (v) => _onSetMax(v, balancePair[0]!.decimals!,
                    //         nativeKeepAlive: nativeKeepAlive)
                    //     : null,
                    onClear: () {
                      setState(() {
                        _maxInput = null;
                        _amountReceiveCtrl.text = '';
                      });
                    },
                    balance: balancePair[1],
                    tokenIconsMap: widget.plugin.tokenIcons,
                    type: InputBalanceType.swapType,
                    bgBorderRadius: const BorderRadius.only(
                        bottomLeft: Radius.circular(4),
                        bottomRight: Radius.circular(4)),
                  ),
                ],
              ),
              GestureDetector(
                child: _isLoading
                    ? Container(
                        width: 36,
                        height: 36,
                        padding: EdgeInsets.all(6),
                        decoration: BoxDecoration(
                            color: Color(0xFF212224),
                            borderRadius:
                                BorderRadius.all(Radius.circular(10))),
                        child: RiveAnimation.asset(
                            'packages/polkawallet_plugin_karura/assets/images/swap_loading.riv'),
                      )
                    : Image.asset(
                        'packages/polkawallet_plugin_acala/assets/images/swap_switch.png',
                        width: 36),
                onTap: _swapPair.length > 1 && !_isLoading
                    ? () => _switchPair()
                    : null,
              ),
            ]),
            ErrorMessage(
              _error ?? _errorReceive ?? _interfaceError ?? amountLowError,
              margin: EdgeInsets.symmetric(vertical: 2),
            ),
            Visibility(
                visible: showExchangeRate && _interfaceError == null,
                child: Container(
                  margin: EdgeInsets.only(top: 16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text("${dic['collateral.exchangeRate']}:",
                          style: labelStyle),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: <Widget>[
                          Text(
                            '1 ${PluginFmt.tokenView(balancePair[rateReversed ? 1 : 0].symbol)} = ${(rateReversed ? 1 / _swapRatio! : _swapRatio)!.toStringAsFixed(6)} ${PluginFmt.tokenView(balancePair[rateReversed ? 0 : 1].symbol)}',
                            style: Theme.of(context)
                                .textTheme
                                .headline5
                                ?.copyWith(color: Colors.white),
                          ),
                          GestureDetector(
                              onTap: () {
                                setState(() {
                                  rateReversed = !rateReversed;
                                });
                              },
                              child: Container(
                                margin: EdgeInsets.only(left: 4),
                                child: Image.asset(
                                    'packages/polkawallet_plugin_acala/assets/images/swap_repeat.png',
                                    width: 20),
                              )),
                        ],
                      )
                    ],
                  ),
                )),
            Container(
              margin: EdgeInsets.only(right: 1, bottom: 7, top: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: <Widget>[
                  Text("${dic['dex.slippage']!}:", style: labelStyle),
                  GestureDetector(
                      child: Padding(
                          padding: EdgeInsets.all(5),
                          child: Row(
                            children: [
                              Padding(
                                padding: EdgeInsets.only(right: 4),
                                child: Text(
                                  Fmt.ratio(_slippage),
                                  style: labelStyle,
                                ),
                              ),
                              Image.asset(
                                  "packages/polkawallet_plugin_acala/assets/images/swap_set.png",
                                  width: 18)
                            ],
                          )),
                      onTap: _onSetSlippage),
                ],
              ),
            ),
            Visibility(
                visible: _slippageSettingVisible,
                child: Container(
                  margin: EdgeInsets.only(left: 8, top: 24, bottom: 3),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: <Widget>[
                      PluginOutlinedButtonSmall(
                        padding:
                            EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                        color: Color(0xFFFF7849),
                        unActiveTextcolor: Colors.white,
                        activeTextcolor: Colors.white,
                        content: '0.1 %',
                        minSize: 24,
                        active: _slippage == 0.001,
                        onPressed: () => _updateSlippage(0.001),
                      ),
                      PluginOutlinedButtonSmall(
                        padding:
                            EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                        color: Color(0xFFFF7849),
                        unActiveTextcolor: Colors.white,
                        activeTextcolor: Colors.white,
                        content: '0.5 %',
                        minSize: 24,
                        active: _slippage == 0.005,
                        onPressed: () => _updateSlippage(0.005),
                      ),
                      PluginOutlinedButtonSmall(
                        padding:
                            EdgeInsets.symmetric(horizontal: 8, vertical: 1),
                        color: Color(0xFFFF7849),
                        unActiveTextcolor: Colors.white,
                        activeTextcolor: Colors.white,
                        content: '1 %',
                        minSize: 24,
                        active: _slippage == 0.01,
                        onPressed: () => _updateSlippage(0.01),
                      ),
                      Container(
                        width: 137,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: <Widget>[
                            CupertinoTextField(
                              textAlign: TextAlign.right,
                              style: Theme.of(context)
                                  .textTheme
                                  .headline4
                                  ?.copyWith(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w300),
                              padding: EdgeInsets.fromLTRB(4, 3, 4, 3),
                              placeholder:
                                  "${I18n.of(context)!.getDic(i18n_full_dic_acala, 'common')!['custom']}  ${Fmt.ratio(_slippage)}",
                              placeholderStyle: Theme.of(context)
                                  .textTheme
                                  .headline4
                                  ?.copyWith(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w400),
                              inputFormatters: [UI.decimalInputFormatter(6)!],
                              keyboardType: TextInputType.numberWithOptions(
                                  decimal: true),
                              decoration: BoxDecoration(
                                borderRadius:
                                    BorderRadius.all(Radius.circular(4)),
                                color: Color(0x24FFFFFF),
                              ),
                              controller: _amountSlippageCtrl,
                              focusNode: _slippageFocusNode,
                              onChanged: _onSlippageChange,
                              // suffix: Container(
                              //   padding: EdgeInsets.only(right: 8),
                              //   child: Text(
                              //     '%',
                              //     style: TextStyle(
                              //         color: _slippageFocusNode.hasFocus
                              //             ? primary
                              //             : grey),
                              //   ),
                              // ),
                            ),
                            Visibility(
                                visible: _slippageError != null,
                                child: Text(
                                  _slippageError ?? "",
                                  style: TextStyle(
                                      color: Theme.of(context).errorColor,
                                      fontSize: UI.getTextSize(10, context)),
                                ))
                          ],
                        ),
                      )
                    ],
                  ),
                )),
            Visibility(
                visible: showExchangeRate &&
                    _swapOutput.amount != null &&
                    _interfaceError == null,
                child: Padding(
                    padding: EdgeInsets.only(top: 20),
                    child: Row(children: [
                      GestureDetector(
                        child: Container(
                            color: Colors.transparent,
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  dicGov['detail']!,
                                  style: labelStyle,
                                ),
                                Padding(
                                  padding: EdgeInsets.only(
                                      left: 6, top: 5, bottom: 5, right: 10),
                                  child: Transform.rotate(
                                      angle: angle,
                                      child: SvgPicture.asset(
                                        "packages/polkawallet_ui/assets/images/triangle_bottom.svg",
                                        color: Color(0xFFFF7849),
                                      )),
                                )
                              ],
                            )),
                        onTap: () {
                          if (!_detailShow) {
                            _animationController!.forward();
                          } else {
                            _animationController!.reverse();
                          }
                          setState(() {
                            _detailShow = !_detailShow;
                          });
                        },
                      )
                    ]))),
            Visibility(
                visible:
                    showExchangeRate && _detailShow && _interfaceError == null,
                child: Container(
                  // decoration: BoxDecoration(
                  //     color: Color(0x24FFFFFF),
                  //     borderRadius: BorderRadius.only(
                  //         bottomLeft: Radius.circular(8),
                  //         topRight: Radius.circular(8),
                  //         bottomRight: Radius.circular(8))),
                  margin: EdgeInsets.only(top: 12),
                  // padding:
                  //     EdgeInsets.only(left: 10, right: 10, bottom: 32, top: 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: <Widget>[
                      Container(
                        margin: EdgeInsets.only(bottom: 8),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: <Widget>[
                            Expanded(
                              child: Text(
                                  dic[_swapMode == 0 ? 'dex.min' : 'dex.max']!,
                                  style: labelStyle),
                            ),
                            Text(
                                '${minMax.toStringAsFixed(6)} ${showExchangeRate ? PluginFmt.tokenView(balancePair[_swapMode == 0 ? 1 : 0].symbol) : ''}',
                                style: labelStyle),
                          ],
                        ),
                      ),
                      Container(
                        margin: EdgeInsets.only(bottom: 8),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: <Widget>[
                            Expanded(
                              child:
                                  Text(dic['dex.impact']!, style: labelStyle),
                            ),
                            Text(
                                '<${_swapOutput.priceImpact?.map((e) => Fmt.ratio(e)).toList().join("~")}',
                                style: labelStyle),
                          ],
                        ),
                      ),
                      Visibility(
                          visible: _swapOutput.fee != null,
                          child: Container(
                            margin: EdgeInsets.only(bottom: 8),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: <Widget>[
                                Expanded(
                                  child:
                                      Text(dic['dex.fee']!, style: labelStyle),
                                ),
                                Column(
                                  children: (_swapOutput.fee ?? []).map((e) {
                                    final index = _swapOutput.fee!.indexOf(e);
                                    return Text(
                                        "$e ${PluginFmt.tokenView(AssetsUtils.getBalanceFromTokenNameId(widget.plugin, _swapOutput.feeToken?[index]).symbol).toString()}",
                                        style:
                                            labelStyle?.copyWith(height: 1.4));
                                  }).toList(),
                                )
                              ],
                            ),
                          )),
                      Visibility(
                          visible: (_swapOutput.path?.length ?? 0) > 0,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child:
                                    Text(dic['dex.route']!, style: labelStyle),
                              ),
                              v3.PopupMenuButton(
                                  offset: Offset(0, 35),
                                  color: Color(0xFF404142),
                                  padding: EdgeInsets.zero,
                                  elevation: 3,
                                  onShow: () {
                                    FocusManager.instance.primaryFocus
                                        ?.unfocus();
                                  },
                                  onCanceled: () {
                                    FocusManager.instance.primaryFocus
                                        ?.unfocus();
                                  },
                                  onSelected: (value) {
                                    FocusManager.instance.primaryFocus
                                        ?.unfocus();
                                  },
                                  itemWidth:
                                      _getRouteWidth(_swapOutput.path ?? []),
                                  shape: const RoundedRectangleBorder(
                                    borderRadius: BorderRadius.all(
                                      Radius.circular(10),
                                    ),
                                  ),
                                  itemBuilder: (BuildContext context) {
                                    return <v3.PopupMenuEntry<String>>[
                                      v3.PopupMenuItem(
                                        padding: EdgeInsets.all(12),
                                        child: RouteWidget(widget.plugin,
                                            path: _swapOutput.path),
                                        value: '0',
                                      ),
                                    ];
                                  },
                                  child: Container(
                                    decoration: BoxDecoration(
                                        color: Color(0x1AFFFFFF),
                                        border: Border.all(
                                            color: const Color(0x59FFFFFF),
                                            width: 0.58),
                                        borderRadius: BorderRadius.all(
                                            Radius.circular(15.05))),
                                    child: Row(
                                      children: [
                                        PluginTokenIcon(balancePair[0].symbol!,
                                            widget.plugin.tokenIcons,
                                            size: 21),
                                        Padding(
                                          padding: EdgeInsets.symmetric(
                                              horizontal: 3),
                                          child: Image.asset(
                                              "packages/polkawallet_plugin_acala/assets/images/swap_to.png",
                                              width: 14),
                                        ),
                                        PluginTokenIcon(balancePair[1].symbol!,
                                            widget.plugin.tokenIcons,
                                            size: 21)
                                      ],
                                    ),
                                  )),
                            ],
                          ))
                    ],
                  ),
                )),
            Padding(
                padding: EdgeInsets.only(bottom: 18, top: 130),
                child: PluginButton(
                  title: dic['dex.title']!,
                  onPressed: _swapRatio == 0
                      ? null
                      : () => _onSubmit(
                          balancePair.map((e) => e.decimals).toList(), minMax),
                ))
          ],
        );
      },
    );
  }

  double _getRouteWidth(List<PathData> path) {
    double width = 0;
    path.forEach((element) {
      final iconsWidth = element.path!.length * 20 + 7;
      var networkWidth = 18 / 63.0 * 259; //acala
      if (element.dex == "nuts") {
        networkWidth = 18 / 213.0 * 625;
      }
      width += iconsWidth > networkWidth ? iconsWidth : networkWidth;
    });
    return width + (path.length - 1) * 35 + 24;
  }
}

class RouteWidget extends StatelessWidget {
  RouteWidget(this.plugin, {this.path, Key? key}) : super(key: key);

  final PluginAcala plugin;
  final List<PathData>? path;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 70,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        shrinkWrap: true,
        physics: NeverScrollableScrollPhysics(),
        itemCount: (path ?? []).length,
        separatorBuilder: (context, index) => Container(width: 35),
        itemBuilder: (context, index) {
          return Padding(
            padding: EdgeInsets.symmetric(vertical: 5),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Image.asset(
                    "packages/polkawallet_plugin_acala/assets/images/swapRoute/${path![index].dex == "acala" ? "acala" : "${path![index].dex}-tapio-icon"}.png",
                    height: 18),
                Padding(
                    padding: EdgeInsets.only(top: 15),
                    child: Stack(
                      children: path![index].path!.map((i) {
                        final indexI = path![index].path!.indexOf(i);
                        final token =
                            AssetsUtils.getBalanceFromTokenNameId(plugin, i);
                        return Padding(
                          child: PluginTokenIcon(
                              token.symbol!, plugin.tokenIcons,
                              size: 27),
                          padding: EdgeInsets.only(left: indexI * 20),
                        );
                      }).toList(),
                    ))
              ],
            ),
          );
        },
      ),
    );
  }
}
