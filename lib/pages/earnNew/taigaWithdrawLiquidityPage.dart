import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:polkawallet_plugin_acala/pages/swapNew/bootstrapPage.dart';
import 'package:polkawallet_plugin_acala/polkawallet_plugin_acala.dart';
import 'package:polkawallet_plugin_acala/utils/assets.dart';
import 'package:polkawallet_plugin_acala/utils/format.dart';
import 'package:polkawallet_plugin_acala/utils/i18n/index.dart';
import 'package:polkawallet_sdk/storage/keyring.dart';
import 'package:polkawallet_sdk/utils/i18n.dart';
import 'package:polkawallet_ui/components/connectionChecker.dart';
import 'package:polkawallet_ui/components/listTail.dart';
import 'package:polkawallet_ui/components/v3/plugin/PluginTxButton.dart';
import 'package:polkawallet_ui/components/v3/plugin/pluginAccountInfoAction.dart';
import 'package:polkawallet_ui/components/v3/plugin/pluginButton.dart';
import 'package:polkawallet_ui/components/v3/plugin/pluginInfoItem.dart';
import 'package:polkawallet_ui/components/v3/plugin/pluginScaffold.dart';
import 'package:polkawallet_ui/components/v3/plugin/pluginTagCard.dart';
import 'package:polkawallet_ui/components/v3/plugin/pluginTextTag.dart';
import 'package:polkawallet_ui/pages/v3/txConfirmPage.dart';
import 'package:polkawallet_ui/utils/consts.dart';
import 'package:polkawallet_ui/utils/format.dart';
import 'package:polkawallet_ui/utils/index.dart';

class TaigaWithdrawLiquidityPage extends StatefulWidget {
  TaigaWithdrawLiquidityPage(this.plugin, this.keyring, {Key? key})
      : super(key: key);
  final PluginAcala plugin;
  final Keyring keyring;

  static const String route = '/acala/earn/taigaWithdrawLiquidity';

  @override
  State<TaigaWithdrawLiquidityPage> createState() =>
      _TaigaWithdrawLiquidityPageState();
}

class _TaigaWithdrawLiquidityPageState
    extends State<TaigaWithdrawLiquidityPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _amountCtrl = new TextEditingController();
  BigInt? _maxShare;

  Map<dynamic, dynamic>? _redeemAmount;
  String? _receivedError;

  bool _loading = true;
  Future<void> _queryTaigaPoolInfo() async {
    final info = await widget.plugin.api!.earn
        .getTaigaPoolInfo(widget.keyring.current.address!);
    widget.plugin.store!.earn.setTaigaPoolInfo(info);
    final data = await widget.plugin.api!.earn.getTaigaTokenPairs();
    widget.plugin.store!.earn.setTaigaTokenPairs(data!);
    setState(() {
      _loading = false;
    });
  }

  Future<void> _getTaigaRedeemAmount() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    final args = ModalRoute.of(context)!.settings.arguments as Map?;
    final taigaTokenPairs = widget.plugin.store!.earn.taigaTokenPairs;

    final taigaToken =
        taigaTokenPairs.where((e) => e.tokenNameId == args?['poolId']).first;
    final balance = AssetsUtils.getBalanceFromTokenNameId(
        widget.plugin, taigaToken.tokenNameId);

    final shareInputInt =
        _maxShare ?? Fmt.tokenInt(_amountCtrl.text.trim(), balance.decimals!);
    final info = await widget.plugin.api!.earn
        .getTaigaRedeemAmount(args?['poolId'], shareInputInt.toString(), 0.005);

    final tokenPair = taigaToken.tokens!
        .map((e) => AssetsUtils.tokenDataFromCurrencyId(widget.plugin, e))
        .toList();
    String? _error;
    tokenPair.forEach((element) {
      final index = tokenPair.indexOf(element);
      if (Fmt.balanceInt(element.amount) == BigInt.zero) {
        if (Fmt.balanceInt(element.minBalance) >
            Fmt.balanceInt(info!["output"][index])) {
          _error = I18n.of(context)!
              .getDic(i18n_full_dic_acala, 'acala')!['earn.taiga.edMessage'];
          return;
        }
      }
    });

    setState(() {
      _receivedError = _error;
      _redeemAmount = info;
    });
  }

  String? _validateInput(String? value) {
    final dic = I18n.of(context)!.getDic(i18n_full_dic_acala, 'common');

    final v = value!.trim();
    var error = Fmt.validatePrice(v, context);
    if (error != null) {
      return error;
    }

    final args = ModalRoute.of(context)!.settings.arguments as Map?;
    final taigaTokenPairs = widget.plugin.store!.earn.taigaTokenPairs;

    final taigaToken =
        taigaTokenPairs.where((e) => e.tokenNameId == args?['poolId']).first;
    final balance = AssetsUtils.getBalanceFromTokenNameId(
        widget.plugin, taigaToken.tokenNameId);

    final shareInputInt = _maxShare ?? Fmt.tokenInt(v, balance.decimals!);
    if (shareInputInt > BigInt.parse(balance.amount!)) {
      return dic!['amount.low'];
    }
    return null;
  }

  void _onAmountSelect(BigInt v, int? decimals, {bool isMax = false}) {
    setState(() {
      _maxShare = isMax ? v : null;
      _amountCtrl.text =
          Fmt.bigIntToDouble(v, decimals!).toStringAsFixed(decimals);
    });

    _getTaigaRedeemAmount();
  }

  Future<void> _onSubmit(int? shareDecimals) async {
    if (_formKey.currentState!.validate() && _receivedError == null) {
      final dic = I18n.of(context)!.getDic(i18n_full_dic_acala, 'acala')!;
      final args = ModalRoute.of(context)!.settings.arguments as Map?;
      final taigaTokenPairs = widget.plugin.store!.earn.taigaTokenPairs;
      final taigaToken =
          taigaTokenPairs.where((e) => e.tokenNameId == args?['poolId']).first;
      final tokenPair = taigaToken.tokens!
          .map((e) => AssetsUtils.tokenDataFromCurrencyId(widget.plugin, e))
          .toList();
      final poolTokenSymbol = tokenPair
          .map((e) => PluginFmt.tokenView(e.symbol))
          .toList()
          .join('-');
      final amount = _amountCtrl.text.trim();

      TxConfirmParams txParams = TxConfirmParams(
        module: 'stableAsset',
        call: 'redeemProportion',
        txTitle: I18n.of(context)!
            .getDic(i18n_full_dic_acala, 'acala')!['earn.remove'],
        txDisplay: {dic['earn.pool']: poolTokenSymbol},
        txDisplayBold: {
          dic['loan.amount']!: Text(
            '$amount LP',
            style: Theme.of(context)
                .textTheme
                .headline1
                ?.copyWith(color: Colors.white),
          ),
        },
        params: _redeemAmount!["params"],
        txHex: _redeemAmount!["txHex"],
        isPlugin: true,
      );

      final res = (await Navigator.of(context)
          .pushNamed(TxConfirmPage.route, arguments: txParams)) as Map?;
      if (res != null) {
        Navigator.of(context).pop(res);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final dic = I18n.of(context)!.getDic(i18n_full_dic_acala, 'acala')!;
    final dicAssets = I18n.of(context)!.getDic(i18n_full_dic_acala, 'common')!;
    final args = ModalRoute.of(context)!.settings.arguments as Map?;
    return PluginScaffold(
        appBar: PluginAppBar(
          title: Text(dic['earn.remove']!),
          actions: [PluginAccountInfoAction(widget.keyring)],
        ),
        body: Observer(builder: (_) {
          final dexPools = widget.plugin.store!.earn.taigaPoolInfoMap;
          final taigaTokenPairs = widget.plugin.store!.earn.taigaTokenPairs;

          final taigaToken = taigaTokenPairs
              .where((e) => e.tokenNameId == args?['poolId'])
              .first;
          final tokenPair = taigaToken.tokens!
              .map((e) => AssetsUtils.tokenDataFromCurrencyId(widget.plugin, e))
              .toList();

          final taigaPool = dexPools[args?['poolId']];
          final balance = AssetsUtils.getBalanceFromTokenNameId(
              widget.plugin, taigaToken.tokenNameId);
          var totalBalance = BigInt.parse(taigaPool!.userShares) +
              BigInt.parse(balance.amount!);

          final shareEmpty = totalBalance == BigInt.zero;
          final shareInputInt = _amountCtrl.text.trim().isNotEmpty
              ? Fmt.tokenInt(_amountCtrl.text.trim(), balance.decimals!)
              : BigInt.zero;

          BigInt shareInt10 = BigInt.zero;
          BigInt shareInt25 = BigInt.zero;
          BigInt shareInt50 = BigInt.zero;
          BigInt shareFromInt = BigInt.parse(balance.amount!);

          shareInt10 = BigInt.from(shareFromInt / BigInt.from(10));
          shareInt25 = BigInt.from(shareFromInt / BigInt.from(4));
          shareInt50 = BigInt.from(shareFromInt / BigInt.from(2));

          List<String> poolSize = [];
          taigaToken.balances?.forEach((element) {
            final index = taigaToken.balances!.indexOf(element);
            poolSize.add(
                "${index == 0 ? '' : '+ '}${Fmt.balance(element, tokenPair[index].decimals!)} ${PluginFmt.tokenView(tokenPair[index].symbol)}");
          });

          List<String> tokenReceived = [];
          if (_redeemAmount != null) {
            tokenPair.forEach((element) {
              final index = tokenPair.indexOf(element);
              tokenReceived.add(
                  "${Fmt.priceFloorBigInt(BigInt.parse(_redeemAmount!["output"][index]), element.decimals!, lengthMax: 4)} ${PluginFmt.tokenView(element.symbol)}");
            });
          }
          return SafeArea(
              child: Padding(
                  padding: EdgeInsets.all(16),
                  child: SingleChildScrollView(
                      child: Column(children: [
                    ConnectionChecker(
                      widget.plugin,
                      onConnected: _queryTaigaPoolInfo,
                    ),
                    dexPools.length == 0 || taigaTokenPairs.length == 0
                        ? ListView(
                            padding: EdgeInsets.all(16),
                            children: [
                              Center(
                                child: Container(
                                  height: MediaQuery.of(context).size.width,
                                  child: ListTail(
                                    isEmpty: true,
                                    isLoading: _loading,
                                    color: Colors.white,
                                  ),
                                ),
                              )
                            ],
                          )
                        : Column(
                            children: [
                              Column(children: [
                                Visibility(
                                    visible: totalBalance > BigInt.zero,
                                    child: PluginTagCard(
                                      titleTag:
                                          '${PluginFmt.tokenView(tokenPair.map((e) => e.symbol).join('-'))} ${dicAssets['balance']}',
                                      padding: EdgeInsets.fromLTRB(8, 16, 8, 8),
                                      margin: EdgeInsets.only(bottom: 16),
                                      child: Container(
                                        margin: EdgeInsets.only(bottom: 4),
                                        child: Row(
                                          children: [
                                            PluginInfoItem(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.center,
                                              title: dicAssets['amount.all'],
                                              titleStyle: Theme.of(context)
                                                  .textTheme
                                                  .headline4
                                                  ?.copyWith(
                                                      color: Colors.white),
                                              content: Fmt.priceFloorBigInt(
                                                  BigInt.parse(taigaPool
                                                          .userShares) +
                                                      BigInt.parse(
                                                          balance.amount!),
                                                  balance.decimals!),
                                            ),
                                            PluginInfoItem(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.center,
                                              title: dicAssets['amount.staked'],
                                              titleStyle: Theme.of(context)
                                                  .textTheme
                                                  .headline4
                                                  ?.copyWith(
                                                      color: Colors.white),
                                              content: Fmt.priceFloorBigInt(
                                                  BigInt.parse(
                                                      taigaPool.userShares),
                                                  balance.decimals!),
                                            ),
                                            PluginInfoItem(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.center,
                                              title: dicAssets['amount.free'],
                                              titleStyle: Theme.of(context)
                                                  .textTheme
                                                  .headline4
                                                  ?.copyWith(
                                                      color: Colors.white),
                                              content: Fmt.priceFloorBigInt(
                                                  BigInt.parse(balance.amount!),
                                                  balance.decimals!),
                                            )
                                          ],
                                        ),
                                      ),
                                    )),
                                Padding(
                                    padding: EdgeInsets.only(bottom: 20),
                                    child: Column(
                                      children: [
                                        Stack(
                                          children: [
                                            PluginTextTag(
                                              padding: EdgeInsets.only(
                                                  left: I18n.of(context)!
                                                          .locale
                                                          .toString()
                                                          .contains('zh')
                                                      ? 45
                                                      : 70,
                                                  right: 12),
                                              title: PluginFmt.tokenView(
                                                  balance.symbol),
                                              backgroundColor:
                                                  Color(0xFF974DE4),
                                              style: Theme.of(context)
                                                  .textTheme
                                                  .headline4
                                                  ?.copyWith(
                                                      fontWeight:
                                                          FontWeight.w600,
                                                      color: Colors.white),
                                            ),
                                            PluginTextTag(
                                              title: dic['v3.earn.amount']!,
                                            ),
                                          ],
                                        ),
                                        Container(
                                          width: double.infinity,
                                          padding: EdgeInsets.only(
                                              top: 14, left: 20),
                                          decoration: BoxDecoration(
                                              color: const Color(0xFF3c3d40),
                                              borderRadius: BorderRadius.only(
                                                  bottomLeft:
                                                      Radius.circular(4),
                                                  topRight: Radius.circular(4),
                                                  bottomRight:
                                                      Radius.circular(4))),
                                          child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: <Widget>[
                                                Form(
                                                  key: _formKey,
                                                  autovalidateMode:
                                                      AutovalidateMode
                                                          .onUserInteraction,
                                                  child: TextFormField(
                                                    style: Theme.of(context)
                                                        .textTheme
                                                        .headline3
                                                        ?.copyWith(
                                                            color: Colors.white,
                                                            fontSize:
                                                                UI.getTextSize(
                                                                    36,
                                                                    context)),
                                                    decoration: InputDecoration(
                                                      contentPadding:
                                                          EdgeInsets.only(
                                                              right: 10),
                                                      border: InputBorder.none,
                                                      hintText:
                                                          '${dicAssets['balance']}: ${Fmt.priceFloorBigInt(BigInt.parse(balance.amount!), balance.decimals!, lengthMax: 4)}',
                                                      hintStyle: Theme.of(
                                                              context)
                                                          .textTheme
                                                          .headline5
                                                          ?.copyWith(
                                                              color: Color(
                                                                  0xffbcbcbc),
                                                              fontWeight:
                                                                  FontWeight
                                                                      .w300),
                                                      suffix: GestureDetector(
                                                        child: Icon(
                                                          CupertinoIcons
                                                              .clear_thick_circled,
                                                          color:
                                                              Color(0xFFD8D8D8),
                                                          size: 22,
                                                        ),
                                                        onTap: () {
                                                          setState(() {
                                                            _maxShare = null;
                                                            _amountCtrl.text =
                                                                '';
                                                          });
                                                        },
                                                      ),
                                                    ),
                                                    inputFormatters: [
                                                      UI.decimalInputFormatter(
                                                          balance.decimals!)!
                                                    ],
                                                    controller: _amountCtrl,
                                                    keyboardType: TextInputType
                                                        .numberWithOptions(
                                                            decimal: true),
                                                    validator: _validateInput,
                                                    onChanged: (v) {
                                                      _getTaigaRedeemAmount();
                                                      setState(() {
                                                        if (_maxShare != null) {
                                                          _maxShare = null;
                                                        }
                                                      });
                                                    },
                                                  ),
                                                ),
                                                Padding(
                                                    padding: EdgeInsets.only(
                                                        top: 10),
                                                    child: Row(
                                                      mainAxisAlignment:
                                                          MainAxisAlignment.end,
                                                      children: <Widget>[
                                                        CupertinoButton(
                                                            onPressed: shareEmpty
                                                                ? null
                                                                : () => _onAmountSelect(
                                                                    shareInt10,
                                                                    balance
                                                                        .decimals),
                                                            color: !shareEmpty &&
                                                                    shareInputInt ==
                                                                        shareInt10
                                                                ? PluginColorsDark
                                                                    .primary
                                                                : Color(
                                                                    0xFF505151),
                                                            disabledColor:
                                                                const Color(
                                                                    0xFF505151),
                                                            minSize: 26,
                                                            borderRadius:
                                                                const BorderRadius
                                                                        .only(
                                                                    topLeft: Radius
                                                                        .circular(
                                                                            9)),
                                                            padding: EdgeInsets
                                                                .symmetric(
                                                                    vertical: 2,
                                                                    horizontal:
                                                                        5),
                                                            child: Text(
                                                              '10%',
                                                              style: Theme.of(
                                                                      context)
                                                                  .textTheme
                                                                  .headline5
                                                                  ?.copyWith(
                                                                      fontWeight:
                                                                          FontWeight
                                                                              .w600,
                                                                      fontSize:
                                                                          12,
                                                                      color: !shareEmpty && shareInputInt == shareInt10
                                                                          ? Color(
                                                                              0xFF212123)
                                                                          : Colors
                                                                              .white),
                                                              textAlign:
                                                                  TextAlign
                                                                      .center,
                                                            )),
                                                        CupertinoButton(
                                                            onPressed: shareEmpty
                                                                ? null
                                                                : () => _onAmountSelect(
                                                                    shareInt25,
                                                                    balance
                                                                        .decimals),
                                                            color: !shareEmpty &&
                                                                    shareInputInt ==
                                                                        shareInt25
                                                                ? PluginColorsDark
                                                                    .primary
                                                                : Color(
                                                                    0xFF505151),
                                                            disabledColor:
                                                                const Color(
                                                                    0xFF505151),
                                                            minSize: 26,
                                                            borderRadius: null,
                                                            padding: EdgeInsets
                                                                .symmetric(
                                                                    vertical: 2,
                                                                    horizontal:
                                                                        5),
                                                            child: Text(
                                                              '25%',
                                                              style: Theme.of(
                                                                      context)
                                                                  .textTheme
                                                                  .headline5
                                                                  ?.copyWith(
                                                                      fontWeight:
                                                                          FontWeight
                                                                              .w600,
                                                                      fontSize:
                                                                          12,
                                                                      color: !shareEmpty && shareInputInt == shareInt25
                                                                          ? Color(
                                                                              0xFF212123)
                                                                          : Colors
                                                                              .white),
                                                              textAlign:
                                                                  TextAlign
                                                                      .center,
                                                            )),
                                                        CupertinoButton(
                                                            onPressed: shareEmpty
                                                                ? null
                                                                : () => _onAmountSelect(
                                                                    shareInt50,
                                                                    balance
                                                                        .decimals),
                                                            color: !shareEmpty &&
                                                                    shareInputInt ==
                                                                        shareInt50
                                                                ? PluginColorsDark
                                                                    .primary
                                                                : Color(
                                                                    0xFF505151),
                                                            disabledColor:
                                                                const Color(
                                                                    0xFF505151),
                                                            minSize: 26,
                                                            borderRadius: null,
                                                            padding: EdgeInsets
                                                                .symmetric(
                                                                    vertical: 2,
                                                                    horizontal:
                                                                        5),
                                                            child: Text(
                                                              '50%',
                                                              style: Theme.of(
                                                                      context)
                                                                  .textTheme
                                                                  .headline5
                                                                  ?.copyWith(
                                                                      fontWeight:
                                                                          FontWeight
                                                                              .w600,
                                                                      fontSize:
                                                                          12,
                                                                      color: !shareEmpty && shareInputInt == shareInt50
                                                                          ? Color(
                                                                              0xFF212123)
                                                                          : Colors
                                                                              .white),
                                                              textAlign:
                                                                  TextAlign
                                                                      .center,
                                                            )),
                                                        CupertinoButton(
                                                            onPressed: shareEmpty
                                                                ? null
                                                                : () => _onAmountSelect(
                                                                    shareFromInt,
                                                                    balance
                                                                        .decimals,
                                                                    isMax:
                                                                        true),
                                                            color: !shareEmpty &&
                                                                    shareInputInt ==
                                                                        shareFromInt
                                                                ? PluginColorsDark
                                                                    .primary
                                                                : Color(
                                                                    0xFF505151),
                                                            disabledColor:
                                                                const Color(
                                                                    0xFF505151),
                                                            minSize: 26,
                                                            borderRadius:
                                                                BorderRadius.only(
                                                                    bottomRight:
                                                                        Radius.circular(
                                                                            4)),
                                                            padding:
                                                                EdgeInsets.symmetric(
                                                                    vertical: 2,
                                                                    horizontal: 5),
                                                            child: Text(
                                                              '100%',
                                                              style: Theme.of(
                                                                      context)
                                                                  .textTheme
                                                                  .headline5
                                                                  ?.copyWith(
                                                                      fontWeight:
                                                                          FontWeight
                                                                              .w600,
                                                                      fontSize:
                                                                          12,
                                                                      color: !shareEmpty && shareInputInt == shareFromInt
                                                                          ? Color(
                                                                              0xFF212123)
                                                                          : Colors
                                                                              .white),
                                                              textAlign:
                                                                  TextAlign
                                                                      .center,
                                                            ))
                                                      ],
                                                    )),
                                              ]),
                                        ),
                                        Visibility(
                                            visible: tokenReceived.length != 0,
                                            child: PluginTagCard(
                                              titleTag:
                                                  dic['v3.earn.tokenReceived']!,
                                              padding: EdgeInsets.symmetric(
                                                  vertical: 19),
                                              margin: EdgeInsets.only(top: 16),
                                              radius: Radius.circular(4),
                                              child: Row(
                                                mainAxisAlignment:
                                                    MainAxisAlignment.center,
                                                children: [
                                                  Text(
                                                    tokenReceived.join(" + "),
                                                    style: Theme.of(context)
                                                        .textTheme
                                                        .bodyText1
                                                        ?.copyWith(
                                                            color: Colors.white,
                                                            fontWeight:
                                                                FontWeight
                                                                    .w600),
                                                  )
                                                ],
                                              ),
                                            )),
                                        ErrorMessage(
                                          _receivedError,
                                          margin:
                                              EdgeInsets.symmetric(vertical: 2),
                                        ),
                                        Padding(
                                          padding: EdgeInsets.only(top: 24),
                                          child: Row(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            mainAxisAlignment:
                                                MainAxisAlignment.spaceBetween,
                                            children: [
                                              Text(
                                                dic['earn.taiga.poolSize']!,
                                                style: Theme.of(context)
                                                    .textTheme
                                                    .headline5
                                                    ?.copyWith(
                                                        color: Colors.white,
                                                        fontWeight:
                                                            FontWeight.w600),
                                              ),
                                              Text(
                                                poolSize.join("\n"),
                                                textAlign: TextAlign.end,
                                                style: Theme.of(context)
                                                    .textTheme
                                                    .headline5
                                                    ?.copyWith(
                                                        color: Colors.white,
                                                        height: 1.7),
                                              )
                                            ],
                                          ),
                                        )
                                      ],
                                    )),
                              ]),
                              Padding(
                                  padding:
                                      EdgeInsets.only(top: 150, bottom: 38),
                                  child: PluginButton(
                                    title: dic['earn.remove']!,
                                    onPressed: () =>
                                        _onSubmit(balance.decimals),
                                  )),
                            ],
                          ),
                  ]))));
        }));
  }
}
