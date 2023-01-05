import 'dart:math';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:polkawallet_plugin_acala/common/components/insufficientACAWarn.dart';
import 'package:polkawallet_plugin_acala/common/constants/index.dart';
import 'package:polkawallet_plugin_acala/pages/assets/transferFormXCM.dart';
import 'package:polkawallet_plugin_acala/pages/types/transferPageParams.dart';
import 'package:polkawallet_plugin_acala/polkawallet_plugin_acala.dart';
import 'package:polkawallet_plugin_acala/utils/assets.dart';
import 'package:polkawallet_plugin_acala/utils/format.dart';
import 'package:polkawallet_plugin_acala/utils/i18n/index.dart';
import 'package:polkawallet_sdk/api/types/txInfoData.dart';
import 'package:polkawallet_sdk/plugin/store/balances.dart';
import 'package:polkawallet_sdk/storage/keyring.dart';
import 'package:polkawallet_sdk/storage/types/keyPairData.dart';
import 'package:polkawallet_sdk/utils/i18n.dart';
import 'package:polkawallet_ui/components/connectionChecker.dart';
import 'package:polkawallet_ui/components/currencyWithIcon.dart';
import 'package:polkawallet_ui/components/tokenIcon.dart';
import 'package:polkawallet_ui/components/v3/MainTabBar.dart';
import 'package:polkawallet_ui/components/v3/addressFormItem.dart';
import 'package:polkawallet_ui/components/v3/addressIcon.dart';
import 'package:polkawallet_ui/components/v3/addressTextFormField.dart';
import 'package:polkawallet_ui/components/v3/back.dart';
import 'package:polkawallet_ui/components/v3/dialog.dart';
import 'package:polkawallet_ui/components/v3/index.dart' as v3;
import 'package:polkawallet_ui/components/v3/roundedCard.dart';
import 'package:polkawallet_ui/components/v3/txButton.dart';
import 'package:polkawallet_ui/pages/scanPage.dart';
import 'package:polkawallet_ui/utils/format.dart';
import 'package:polkawallet_ui/utils/i18n.dart';
import 'package:polkawallet_ui/utils/index.dart';

class TransferPage extends StatefulWidget {
  TransferPage(this.plugin, this.keyring);
  final PluginAcala plugin;
  final Keyring keyring;

  static final String route = '/assets/token/transfer';

  @override
  _TransferPageState createState() => _TransferPageState();
}

class _TransferPageState extends State<TransferPage> {
  int _tab = 0;

  final _formKey = GlobalKey<FormState>();

  final TextEditingController _amountCtrl = new TextEditingController();

  KeyPairData? _accountTo;
  List<KeyPairData> _accountOptions = [];
  TokenBalanceData? _token;

  bool _keepAlive = true;

  Map _accountSysInfo = {};

  String? _accountToError;

  TxFeeEstimateResult? _fee;
  BigInt? _amountMax;

  bool _submitting = false;

  Future<void> _getAccountSysInfo() async {
    final info = await widget.plugin.sdk.webView?.evalJavascript(
        'api.query.system.account("${widget.keyring.current.address}")');
    if (mounted && info != null) {
      setState(() {
        _accountSysInfo = info;
      });
    }
  }

  Future<String> _getTxFee({bool reload = false}) async {
    if (_fee?.partialFee != null && !reload) {
      return _fee!.partialFee.toString();
    }

    final sender = TxSenderData(
        widget.keyring.current.address, widget.keyring.current.pubKey);
    final txInfo = TxInfoData('currencies', 'transfer', sender);
    final fee = await widget.plugin.sdk.api.tx.estimateFees(txInfo, [
      widget.keyring.current.address,
      _token?.currencyId ?? {'Token': acala_stable_coin},
      '1000000000'
    ]);
    if (mounted) {
      setState(() {
        _fee = fee;
      });
    }
    return fee.partialFee.toString();
  }

  Future<void> _onScan() async {
    final to = await Navigator.of(context).pushNamed(ScanPage.route);
    if (to == null) return;
    final acc = KeyPairData();
    acc.address = (to as QRCodeResult).address!.address;
    acc.name = to.address!.name.isNotEmpty
        ? to.address!.name
        : Fmt.address(acc.address);
    final res =
        await widget.plugin.sdk.api.account.getAddressIcons([acc.address]);
    if (res != null) {
      acc.icon = res[0][1];
    }
    setState(() {
      _accountTo = acc;
    });
    print(_accountTo!.address);
  }

  Future<void> _updateAddressIcon(String address) async {
    final res = await widget.plugin.sdk.api.account.getAddressIcons([address]);
    if (res != null && res.length > 0) {
      final acc = KeyPairData()
        ..address = _accountTo?.address
        ..icon = res[0][1];
      setState(() {
        _accountTo = acc;
      });
    }
  }

  void _onSwitchCheckAlive(bool res, bool isNoDeath) {
    final dic = I18n.of(context)!.getDic(i18n_full_dic_acala, 'common')!;

    if (!res) {
      showCupertinoDialog(
        context: context,
        builder: (BuildContext context) {
          return PolkawalletAlertDialog(
            title: Text(dic['note']!),
            content: Text(dic['transfer.note.msg1']!),
            actions: <Widget>[
              PolkawalletActionSheetAction(
                child: Text(I18n.of(context)!
                    .getDic(i18n_full_dic_ui, 'common')!['cancel']!),
                onPressed: () => Navigator.of(context).pop(),
              ),
              PolkawalletActionSheetAction(
                isDefaultAction: true,
                child: Text(I18n.of(context)!
                    .getDic(i18n_full_dic_ui, 'common')!['ok']!),
                onPressed: () {
                  Navigator.of(context).pop();

                  if (isNoDeath) {
                    showCupertinoDialog(
                      context: context,
                      builder: (BuildContext context) {
                        return PolkawalletAlertDialog(
                          title: Text(dic['note']!),
                          content: Text(dic['transfer.note.msg2']!),
                          actions: <Widget>[
                            PolkawalletActionSheetAction(
                              child: Text(I18n.of(context)!
                                  .getDic(i18n_full_dic_ui, 'common')!['ok']!),
                              onPressed: () => Navigator.of(context).pop(),
                            ),
                          ],
                        );
                      },
                    );
                  } else {
                    setState(() {
                      _keepAlive = res;
                    });
                  }
                },
              ),
            ],
          );
        },
      );
    } else {
      setState(() {
        _keepAlive = res;
      });
    }
  }

  Future<TxConfirmParams?> _getTxParams() async {
    if (_accountToError == null &&
        _formKey.currentState!.validate() &&
        !_submitting) {
      final dic = I18n.of(context)!.getDic(i18n_full_dic_acala, 'common')!;
      final tokenView = PluginFmt.tokenView(_token!.symbol);

      final params = [
        // params.to
        _accountTo!.address,
        // params.currencyId
        _token!.currencyId,
        // params.amount
        (_amountMax ?? Fmt.tokenInt(_amountCtrl.text.trim(), _token!.decimals!))
            .toString(),
      ];
      return TxConfirmParams(
        module: 'currencies',
        call: 'transfer',
        txTitle:
            '${I18n.of(context)!.getDic(i18n_full_dic_acala, 'acala')!['transfer']} $tokenView',
        txDisplay: {},
        txDisplayBold: {
          dic['amount']!: Text(
            Fmt.priceFloor(double.tryParse(_amountCtrl.text.trim()),
                    lengthMax: 8) +
                ' $tokenView',
            style: Theme.of(context).textTheme.headline1,
          ),
          dic['address']!: Row(
            children: [
              AddressIcon(_accountTo!.address, svg: _accountTo!.icon),
              Expanded(
                child: Container(
                  margin: EdgeInsets.fromLTRB(8, 16, 0, 16),
                  child: Text(
                    Fmt.address(_accountTo?.address, pad: 8),
                    style: Theme.of(context).textTheme.headline4,
                  ),
                ),
              ),
            ],
          ),
        },
        params: params,
      );
    }
    return null;
  }

  void _fetchData() {
    _getTxFee();
    _getAccountSysInfo();
  }

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final argsJson = ModalRoute.of(context)!.settings.arguments as Map? ?? {};
      final args = TransferPageParams.fromJson(argsJson);
      setState(() {
        _token = AssetsUtils.getBalanceFromTokenNameId(
            widget.plugin, args.tokenNameId);
        _accountOptions = widget.keyring.allWithContacts.toList();

        if (args.address != null) {
          _accountTo = KeyPairData()..address = args.address;
          _updateAddressIcon(args.address!);
        } else {
          _accountTo = widget.keyring.current;
        }

        if (args.isXCM != null) {
          _tab = args.isXCM == "true" ? 1 : 0;
        }
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
    final dic = I18n.of(context)!.getDic(i18n_full_dic_acala, 'common')!;
    final argsJson = ModalRoute.of(context)!.settings.arguments as Map? ?? {};
    final args = TransferPageParams.fromJson(argsJson);
    final token = _token ??
        AssetsUtils.getBalanceFromTokenNameId(widget.plugin, args.tokenNameId);

    // final tokensConfig =
    //     widget.plugin.store!.setting.remoteConfig['tokens'] ?? {};
    // final tokenXcmConfig =
    //     List<String>.from((tokensConfig['xcm'] ?? {})[token.tokenNameId] ?? []);
    // final tokenXcmFromConfig = List<String>.from(
    //     (tokensConfig['xcmFrom'] ?? {})[token.tokenNameId] ?? []);

    // TODO: remove cross-chain from this page
    final canCrossChain = false;
    // final canCrossChain =
    //     tokenXcmConfig.length > 0 || tokenXcmFromConfig.length > 0;

    return Scaffold(
        appBar: AppBar(
          title: Text(dic['transfer']!),
          centerTitle: true,
          leading: BackBtn(),
          actions: <Widget>[
            Visibility(
              visible: _tab == 0,
              child: v3.IconButton(
                  margin: EdgeInsets.only(right: 12),
                  icon: SvgPicture.asset(
                    'assets/images/scan.svg',
                    color: Theme.of(context).cardColor,
                    width: 24,
                  ),
                  onPressed: () => _onScan(),
                  isBlueBg: true),
            )
          ],
        ),
        body: SingleChildScrollView(
          child: Column(
            children: [
              canCrossChain
                  ? Container(
                      margin: EdgeInsets.symmetric(horizontal: 16.w),
                      child: MainTabBar(
                        tabs: {
                          dic['transfer.inner']!: false,
                          dic['transfer.cross']!: false
                        },
                        activeTab: _tab,
                        onTap: (i) {
                          setState(() {
                            _tab = i;
                          });
                        },
                      ),
                    )
                  : Container(),
              Visibility(
                  visible: _tab == 0,
                  child: Container(
                    margin: EdgeInsets.fromLTRB(16, 8, 16, 16),
                    child: Observer(
                      builder: (_) {
                        final dicAcala = I18n.of(context)!
                            .getDic(i18n_full_dic_acala, 'acala')!;

                        final tokenSymbol = token.symbol!.toUpperCase();
                        final tokenView = PluginFmt.tokenView(token.symbol);

                        final nativeTokenBalance = Fmt.balanceInt(
                                widget.plugin.balances.native?.freeBalance) -
                            Fmt.balanceInt(
                                widget.plugin.balances.native?.frozenFee);
                        final notTransferable = Fmt.balanceInt((widget.plugin
                                        .balances.native?.reservedBalance ??
                                    0)
                                .toString()) +
                            Fmt.balanceInt(
                                (widget.plugin.balances.native?.lockedBalance ??
                                        0)
                                    .toString());
                        final accountED = _keepAlive
                            ? PluginFmt.getAccountED(widget.plugin)
                            : BigInt.zero;
                        final isNativeTokenLow = nativeTokenBalance -
                                accountED <
                            Fmt.balanceInt((_fee?.partialFee ?? 0).toString()) *
                                BigInt.two;
                        final isAccountNormal =
                            (_accountSysInfo['consumers'] as int?) == 0 ||
                                ((_accountSysInfo['providers'] as int?) ?? 0) >
                                    0;

                        final balanceData =
                            AssetsUtils.getBalanceFromTokenNameId(
                                widget.plugin, token.tokenNameId);
                        final available = Fmt.balanceInt(balanceData.amount) -
                            Fmt.balanceInt(balanceData.locked);
                        final nativeToken =
                            widget.plugin.networkState.tokenSymbol![0];
                        final nativeTokenDecimals =
                            widget.plugin.networkState.tokenDecimals![widget
                                .plugin.networkState.tokenSymbol!
                                .indexOf(nativeToken)];
                        final existDeposit = token.tokenNameId == nativeToken
                            ? Fmt.balanceInt(widget.plugin
                                .networkConst['balances']['existentialDeposit']
                                .toString())
                            : Fmt.balanceInt(widget
                                .plugin
                                .store!
                                .assets
                                .tokenBalanceMap[token.tokenNameId]!
                                .minBalance);
                        final fee =
                            Fmt.balanceInt((_fee?.partialFee ?? 0).toString());
                        BigInt max = available;
                        if (tokenSymbol == nativeToken) {
                          max = notTransferable > BigInt.zero
                              ? notTransferable > accountED
                                  ? available - fee
                                  : available -
                                      (accountED - notTransferable) -
                                      fee
                              : available - accountED - fee;
                        }
                        if (max < BigInt.zero) {
                          max = BigInt.zero;
                        }

                        final labelStyle = Theme.of(context)
                            .textTheme
                            .headline4
                            ?.copyWith(fontWeight: FontWeight.bold);
                        final subTitleStyle = Theme.of(context)
                            .textTheme
                            .headline5
                            ?.copyWith(
                                height: 1,
                                fontWeight: FontWeight.w300,
                                fontSize: 12,
                                color: UI.isDarkTheme(context)
                                    ? Colors.white
                                    : Color(0xBF565554));
                        final infoValueStyle = Theme.of(context)
                            .textTheme
                            .headline5!
                            .copyWith(fontWeight: FontWeight.w600);

                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            ConnectionChecker(widget.plugin,
                                onConnected: _fetchData),
                            Text(dic['address.from'] ?? '', style: labelStyle),
                            Padding(
                                padding: EdgeInsets.only(top: 3),
                                child: AddressFormItem(widget.keyring.current)),
                            Container(height: 8.h),
                            Form(
                              key: _formKey,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  AddressTextFormField(
                                    widget.plugin.sdk.api,
                                    _accountOptions,
                                    labelText: dic['address'],
                                    labelStyle: labelStyle,
                                    hintText: dic['address'],
                                    initialValue: _accountTo,
                                    onChanged: (KeyPairData acc) async {
                                      setState(() {
                                        _accountTo = acc;
                                      });
                                    },
                                    sdk: widget.plugin.sdk,
                                    key: ValueKey<KeyPairData?>(_accountTo),
                                  ),
                                  Visibility(
                                      visible: _accountToError != null,
                                      child: Container(
                                        margin: EdgeInsets.only(top: 4),
                                        child: Text(_accountToError ?? "",
                                            style: TextStyle(
                                                fontSize:
                                                    UI.getTextSize(12, context),
                                                color: Colors.red)),
                                      )),
                                  Container(height: 10.h),
                                  v3.TextInputWidget(
                                    autovalidateMode:
                                        AutovalidateMode.onUserInteraction,
                                    decoration: v3.InputDecorationV3(
                                      hintText: dic['amount.hint'],
                                      labelText:
                                          '${dic['amount']} (${dic['balance']}: ${Fmt.priceFloorBigInt(
                                        available,
                                        token.decimals!,
                                        lengthMax: 6,
                                      )})',
                                      labelStyle: labelStyle,
                                      suffix: fee > BigInt.zero
                                          ? GestureDetector(
                                              child: Text(dic['amount.max']!,
                                                  style: TextStyle(
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      color: Theme.of(context)
                                                          .toggleableActiveColor)),
                                              onTap: () {
                                                setState(() {
                                                  _amountMax = max;
                                                  _amountCtrl.text =
                                                      Fmt.bigIntToDouble(max,
                                                              token.decimals!)
                                                          .toStringAsFixed(8);
                                                });
                                              },
                                            )
                                          : null,
                                    ),
                                    inputFormatters: [
                                      UI.decimalInputFormatter(token.decimals!)!
                                    ],
                                    controller: _amountCtrl,
                                    keyboardType:
                                        TextInputType.numberWithOptions(
                                            decimal: true),
                                    onChanged: (_) {
                                      setState(() {
                                        _amountMax = null;
                                      });
                                    },
                                    validator: (v) {
                                      final error =
                                          Fmt.validatePrice(v!, context);
                                      if (error != null) {
                                        return error;
                                      }

                                      final input = Fmt.tokenInt(
                                          v.trim(), token.decimals!);
                                      if (_amountMax == null &&
                                          Fmt.bigIntToDouble(
                                                  input, token.decimals!) >
                                              max /
                                                  BigInt.from(pow(
                                                      10, token.decimals!))) {
                                        return dic['amount.low'];
                                      }
                                      return null;
                                    },
                                  )
                                ],
                              ),
                            ),
                            Container(
                              margin: EdgeInsets.only(top: 8, bottom: 8),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: <Widget>[
                                  Container(
                                    margin: EdgeInsets.only(bottom: 4),
                                    child: Text(dic['currency']!,
                                        style: labelStyle),
                                  ),
                                  RoundedCard(
                                    padding: EdgeInsets.symmetric(
                                        horizontal: 12, vertical: 8),
                                    child: CurrencyWithIcon(
                                      tokenView,
                                      TokenIcon(tokenSymbol,
                                          widget.plugin.tokenIcons),
                                    ),
                                  )
                                ],
                              ),
                            ),
                            Visibility(
                              visible: isNativeTokenLow,
                              child: InsufficientACAWarn(),
                            ),
                            RoundedCard(
                              margin: EdgeInsets.only(top: 16.h),
                              padding: EdgeInsets.symmetric(vertical: 6),
                              child: Column(
                                children: [
                                  Container(
                                    padding:
                                        EdgeInsets.symmetric(horizontal: 16.w),
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.end,
                                      children: [
                                        Expanded(
                                          child: Container(
                                              padding:
                                                  EdgeInsets.only(right: 60),
                                              child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                mainAxisAlignment:
                                                    MainAxisAlignment.center,
                                                children: [
                                                  Text(
                                                      dicAcala[
                                                          'transfer.exist']!,
                                                      style:
                                                          labelStyle?.copyWith(
                                                              fontWeight:
                                                                  FontWeight
                                                                      .w400)),
                                                  Padding(
                                                      padding: EdgeInsets.only(
                                                          top: 2),
                                                      child: Text(
                                                          dicAcala[
                                                              'cross.exist.msg']!,
                                                          style: subTitleStyle
                                                              ?.copyWith(
                                                                  height:
                                                                      1.3))),
                                                ],
                                              )),
                                        ),
                                        Text(
                                            '${Fmt.priceCeilBigInt(existDeposit, token.decimals!, lengthMax: 6)} $tokenView',
                                            style: infoValueStyle),
                                      ],
                                    ),
                                  ),
                                  Visibility(
                                      visible: _fee?.partialFee != null,
                                      child: Column(children: [
                                        Padding(
                                            padding: EdgeInsets.symmetric(
                                                vertical: 6),
                                            child: Divider(height: 1)),
                                        Container(
                                          padding: EdgeInsets.symmetric(
                                              horizontal: 16.w),
                                          child: Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.end,
                                            children: [
                                              Expanded(
                                                child: Padding(
                                                  padding:
                                                      EdgeInsets.only(right: 4),
                                                  child: Text(
                                                      dicAcala['transfer.fee']!,
                                                      style:
                                                          labelStyle?.copyWith(
                                                              fontWeight:
                                                                  FontWeight
                                                                      .w400)),
                                                ),
                                              ),
                                              Text(
                                                  '${Fmt.priceCeilBigInt(Fmt.balanceInt((_fee?.partialFee ?? 0).toString()), nativeTokenDecimals, lengthMax: 6)} $nativeToken',
                                                  style: infoValueStyle),
                                            ],
                                          ),
                                        )
                                      ])),
                                  Visibility(
                                      visible: tokenSymbol == nativeToken &&
                                          available > BigInt.zero,
                                      child: Column(children: [
                                        Padding(
                                            padding: EdgeInsets.symmetric(
                                                vertical: 6),
                                            child: Divider(height: 1)),
                                        Container(
                                          padding: EdgeInsets.symmetric(
                                              horizontal: 16.w),
                                          child: Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.end,
                                            children: [
                                              Expanded(
                                                child: Container(
                                                    padding: EdgeInsets.only(
                                                        right: 60),
                                                    child: Column(
                                                      mainAxisSize:
                                                          MainAxisSize.min,
                                                      crossAxisAlignment:
                                                          CrossAxisAlignment
                                                              .start,
                                                      children: [
                                                        Text(
                                                          dic['transfer.alive']!,
                                                          style: labelStyle
                                                              ?.copyWith(
                                                                  fontWeight:
                                                                      FontWeight
                                                                          .w400),
                                                        ),
                                                        Padding(
                                                            padding:
                                                                EdgeInsets.only(
                                                                    top: 2),
                                                            child: Text(
                                                              dic['transfer.alive.msg']!,
                                                              style: subTitleStyle
                                                                  ?.copyWith(
                                                                      height:
                                                                          1.3),
                                                            )),
                                                      ],
                                                    )),
                                              ),
                                              v3.CupertinoSwitch(
                                                value: _keepAlive,
                                                // account is not allow_death if it has
                                                // locked/reserved balances
                                                onChanged: (v) =>
                                                    _onSwitchCheckAlive(
                                                        v,
                                                        !isAccountNormal ||
                                                            notTransferable >
                                                                BigInt.zero),
                                              )
                                            ],
                                          ),
                                        )
                                      ]))
                                ],
                              ),
                            ),
                            Container(
                              padding: EdgeInsets.only(top: 16),
                              child: TxButton(
                                text:
                                    widget.plugin.sdk.api.connectedNode == null
                                        ? dic['xcm.connecting']
                                        : dic['make'],
                                getTxParams: _getTxParams,
                                onFinish: (res) {
                                  if (res != null) {
                                    Navigator.of(context).pop(res);
                                  }
                                },
                              ),
                            )
                          ],
                        );
                      },
                    ),
                  )),
              Visibility(
                  visible: _tab == 1,
                  child: Container(
                    margin: EdgeInsets.fromLTRB(16, 8, 16, 16),
                    child: TransferFormXCM(widget.plugin, widget.keyring),
                  )),
            ],
          ),
        ));
  }
}
