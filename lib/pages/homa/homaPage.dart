import 'dart:async';

import 'package:charts_flutter/flutter.dart' as charts;
import 'package:flutter/cupertino.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:polkawallet_plugin_acala/api/types/txHomaData.dart';
import 'package:polkawallet_plugin_acala/common/constants/base.dart';
import 'package:polkawallet_plugin_acala/common/constants/index.dart';
import 'package:polkawallet_plugin_acala/pages/homa/mintPage.dart';
import 'package:polkawallet_plugin_acala/pages/homa/redeemPage.dart';
import 'package:polkawallet_plugin_acala/polkawallet_plugin_acala.dart';
import 'package:polkawallet_plugin_acala/utils/i18n/index.dart';
import 'package:polkawallet_sdk/storage/keyring.dart';
import 'package:polkawallet_sdk/utils/i18n.dart';
import 'package:polkawallet_ui/components/infoItem.dart';
import 'package:polkawallet_ui/components/roundedCard.dart';
import 'package:polkawallet_ui/components/tokenIcon.dart';
import 'package:polkawallet_ui/components/txButton.dart';
import 'package:polkawallet_ui/pages/txConfirmPage.dart';
import 'package:polkawallet_ui/utils/format.dart';
import 'package:polkawallet_ui/utils/index.dart';

class HomaPage extends StatefulWidget {
  HomaPage(this.plugin, this.keyring);
  final PluginAcala plugin;
  final Keyring keyring;

  static const String route = '/acala/homa';

  @override
  _HomaPageState createState() => _HomaPageState();
}

class _HomaPageState extends State<HomaPage> {
  Timer _timer;

  Future<void> _refreshData() async {
    await widget.plugin.service.homa.queryHomaLiteStakingPool();

    if (_timer != null) {
      _timer.cancel();
    }
    _timer = Timer(Duration(seconds: 20), () {
      _refreshData();
    });
  }

  Future<void> _onSubmitWithdraw(int liquidDecimal) async {
    final userInfo = widget.plugin.store.homa.userInfo;
    final String receive =
        Fmt.priceFloorBigInt(userInfo.unbonded, liquidDecimal, lengthMax: 3);

    final res = (await Navigator.of(context).pushNamed(TxConfirmPage.route,
        arguments: TxConfirmParams(
          module: 'homa',
          call: 'withdrawRedemption',
          txTitle: I18n.of(context)
              .getDic(i18n_full_dic_acala, 'acala')['homa.redeem'],
          txDisplay: {
            "amountReceive": receive,
          },
          params: [],
        ))) as Map;
    if (res != null) {
      res['time'] = DateTime.now().millisecondsSinceEpoch;
      res['action'] = TxHomaData.actionWithdrawRedemption;
      res['amountPay'] = '0';
      res['amountReceive'] = receive;
      widget.plugin.store.homa.addHomaTx(res, widget.keyring.current.pubKey);
    }
  }

  Future<bool> _confirmMint() async {
    final dic = I18n.of(context).getDic(i18n_full_dic_acala, 'acala');
    return showCupertinoDialog(
        context: context,
        builder: (_) {
          return CupertinoAlertDialog(
            title: Text(dic['cross.warn']),
            content: RichText(
              text: TextSpan(
                children: [
                  TextSpan(
                    text: dic['homa.mint.warn'],
                    style: TextStyle(color: Colors.black87),
                  ),
                  TextSpan(
                    text: dic['homa.mint.warn.here'],
                    style: TextStyle(color: Theme.of(context).primaryColor),
                    recognizer: new TapGestureRecognizer()
                      ..onTap = () {
                        UI.launchURL(
                            'https://wiki.acala.network/karura/defi-hub/liquid-staking');
                      },
                  ),
                ],
              ),
            ),
            actions: [
              CupertinoButton(
                child: Text(I18n.of(context)
                    .getDic(i18n_full_dic_acala, 'common')['cancel']),
                onPressed: () {
                  Navigator.of(context).pop(false);
                },
              ),
              CupertinoButton(
                child: Text(I18n.of(context)
                    .getDic(i18n_full_dic_acala, 'common')['ok']),
                onPressed: () {
                  Navigator.of(context).pop(true);
                },
              ),
            ],
          );
        });
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _refreshData();
    });
  }

  @override
  void dispose() {
    if (_timer != null) {
      _timer.cancel();
      _timer = null;
    }
    super.dispose();
  }

  @override
  Widget build(_) {
    return Observer(
      builder: (BuildContext context) {
        final dic = I18n.of(context).getDic(i18n_full_dic_acala, 'acala');
        final isKar = widget.plugin.basic.name == plugin_name_karura;
        final symbols = widget.plugin.networkState.tokenSymbol;
        final decimals = widget.plugin.networkState.tokenDecimals;

        // final bool enabled =
        //     !isKar || ModalRoute.of(context).settings.arguments;
        final enabled = true;
        final stakeSymbol = relay_chain_token_symbol[widget.plugin.basic.name];

        final poolInfo = widget.plugin.store.homa.poolInfo;
        final staked = poolInfo.staked ?? BigInt.zero;
        final cap = poolInfo.cap ?? BigInt.zero;
        final amountLeft = cap - staked;
        final liquidTokenIssuance = poolInfo.liquidTokenIssuance ?? BigInt.zero;

        final List<charts.Series> seriesList = [
          new charts.Series<num, int>(
            id: 'chartData',
            domainFn: (_, i) => i,
            colorFn: (_, i) => i == 0
                ? charts.MaterialPalette.red.shadeDefault
                : charts.MaterialPalette.gray.shade100,
            measureFn: (num i, _) => i,
            data: [
              staked.toDouble(),
              amountLeft.toDouble(),
            ],
          )
        ];

        final nativeDecimal = decimals[symbols.indexOf(stakeSymbol)];
        final liquidDecimal = decimals[symbols.indexOf('L$stakeSymbol')];

        final minStake = Fmt.balanceInt(widget
                .plugin.networkConst['homaLite']['minimumMintThreshold']
                .toString()) +
            Fmt.balanceInt(
                widget.plugin.networkConst['homaLite']['mintFee'].toString());

        final primary = Theme.of(context).primaryColor;
        final white = Theme.of(context).cardColor;

        return Scaffold(
          appBar: AppBar(
            title: Text('${dic['homa.title']} $stakeSymbol'),
            centerTitle: true,
            elevation: 0.0,
          ),
          body: SafeArea(
            child: Column(
              children: <Widget>[
                Expanded(
                  child: ListView(
                    children: <Widget>[
                      Stack(
                        children: <Widget>[
                          Container(
                            width: MediaQuery.of(context).size.width,
                            height: 180,
                            decoration: BoxDecoration(
                                gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [primary, white],
                              stops: [0.4, 0.9],
                            )),
                          ),
                          RoundedCard(
                            margin: EdgeInsets.all(16),
                            padding: EdgeInsets.all(16),
                            child: Column(
                              children: <Widget>[
                                Text('$stakeSymbol ${dic['homa.pool']}'),
                                Row(
                                  children: [
                                    Expanded(
                                      child: Stack(
                                        alignment: AlignmentDirectional.center,
                                        children: [
                                          Container(
                                            height: MediaQuery.of(context)
                                                    .size
                                                    .width /
                                                3,
                                            child: charts.PieChart(seriesList,
                                                animate: false,
                                                defaultRenderer: new charts
                                                        .ArcRendererConfig(
                                                    arcWidth: 10)),
                                          ),
                                          TokenIcon(stakeSymbol,
                                              widget.plugin.tokenIcons),
                                        ],
                                      ),
                                    ),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            dic['homa.pool.bonded'],
                                            style: TextStyle(fontSize: 12),
                                          ),
                                          Text(
                                            Fmt.token(staked, nativeDecimal),
                                            style: Theme.of(context)
                                                .textTheme
                                                .headline4,
                                          ),
                                          Container(
                                            margin: EdgeInsets.only(top: 8),
                                            child: Text(
                                              dic['homa.pool.cap'],
                                              style: TextStyle(fontSize: 12),
                                            ),
                                          ),
                                          Text(
                                            Fmt.token(cap, nativeDecimal),
                                            style: Theme.of(context)
                                                .textTheme
                                                .headline4,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                                Divider(height: 24),
                                Row(
                                  children: <Widget>[
                                    InfoItem(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.center,
                                      title: dic['homa.pool.min'],
                                      content:
                                          '> ${Fmt.token(minStake, nativeDecimal)}',
                                    ),
                                    InfoItem(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.center,
                                      title:
                                          'L$stakeSymbol ${dic['homa.pool.issuance']}',
                                      content: Fmt.token(
                                          liquidTokenIssuance, liquidDecimal),
                                    ),
                                  ],
                                )
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                (poolInfo.liquidTokenIssuance ?? BigInt.zero) >= BigInt.zero
                    ? Row(
                        children: <Widget>[
                          Expanded(
                            child: Container(
                              color: false
                                  ? primary
                                  : Theme.of(context).disabledColor,
                              child: TextButton(
                                child: Text(
                                  '${dic['homa.redeem']} $stakeSymbol',
                                  style: TextStyle(color: white),
                                ),
                                onPressed: false
                                    ? () => Navigator.of(context)
                                        .pushNamed(HomaRedeemPage.route)
                                    : null,
                              ),
                            ),
                          ),
                          Expanded(
                            child: Container(
                              color: enabled && staked < cap
                                  ? Theme.of(context).accentColor
                                  : Theme.of(context).disabledColor,
                              child: TextButton(
                                child: Text(
                                  '${dic['homa.mint']} L$stakeSymbol',
                                  style: TextStyle(color: white),
                                ),
                                onPressed: enabled && staked < cap
                                    ? () async {
                                        if (!(await _confirmMint())) return;

                                        Navigator.of(context)
                                            .pushNamed(MintPage.route);
                                      }
                                    : null,
                              ),
                            ),
                          ),
                        ],
                      )
                    : Container(),
              ],
            ),
          ),
        );
      },
    );
  }
}
