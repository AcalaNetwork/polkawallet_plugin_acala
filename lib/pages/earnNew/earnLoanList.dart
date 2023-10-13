import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:polkawallet_plugin_acala/api/earn/types/incentivesData.dart';
import 'package:polkawallet_plugin_acala/pages/loanNew/loanDepositPage.dart';
import 'package:polkawallet_plugin_acala/polkawallet_plugin_acala.dart';
import 'package:polkawallet_plugin_acala/service/walletApi.dart';
import 'package:polkawallet_plugin_acala/utils/assets.dart';
import 'package:polkawallet_plugin_acala/utils/format.dart';
import 'package:polkawallet_plugin_acala/utils/i18n/index.dart';
import 'package:polkawallet_sdk/plugin/store/balances.dart';
import 'package:polkawallet_sdk/storage/keyring.dart';
import 'package:polkawallet_sdk/utils/i18n.dart';
import 'package:polkawallet_ui/components/connectionChecker.dart';
import 'package:polkawallet_ui/components/v3/dialog.dart';
import 'package:polkawallet_ui/components/v3/infoItemRow.dart';
import 'package:polkawallet_ui/components/v3/plugin/pluginInfoItem.dart';
import 'package:polkawallet_ui/components/v3/plugin/pluginOutlinedButtonSmall.dart';
import 'package:polkawallet_ui/components/v3/plugin/pluginPopLoadingWidget.dart';
import 'package:polkawallet_ui/components/v3/plugin/pluginTokenIcon.dart';
import 'package:polkawallet_ui/components/v3/plugin/roundedPluginCard.dart';
import 'package:polkawallet_ui/components/v3/txButton.dart';
import 'package:polkawallet_ui/pages/v3/txConfirmPage.dart';
import 'package:polkawallet_ui/utils/format.dart';
import 'package:polkawallet_ui/utils/index.dart';

class EarnLoanList extends StatefulWidget {
  EarnLoanList(this.plugin, this.keyring);
  final PluginAcala plugin;
  final Keyring keyring;

  @override
  _EarnLoanListState createState() => _EarnLoanListState();
}

class _EarnLoanListState extends State<EarnLoanList> {
  bool _loading = true;

  BigInt _totalKar = BigInt.zero;
  BigInt _loyalty = BigInt.zero;
  BigInt _loyaltyUser = BigInt.zero;

  bool _fetching = false;

  Future<void> _fetchKarIssuance() async {
    final res = await widget.plugin.sdk.webView
        ?.evalJavascript('api.query.balances.totalIssuance()');
    setState(() {
      _totalKar = Fmt.balanceInt(res.toString());
    });
  }

  Future<void> _fetchLoyaltyBonus() async {
    final res = await WalletApi.getKarLoyalBonus();
    final loyaltyKar = Fmt.balanceInt((res ?? {})['data']);

    if (loyaltyKar > BigInt.zero) {
      setState(() {
        _loyalty = loyaltyKar;
      });
    }
  }

  Future<void> _updateLoyaltyBonusUser() async {
    setState(() {
      _fetching = true;
    });

    final res =
        await WalletApi.getKarLoyalBonusUser(widget.keyring.current.address!);
    final loyaltyUserList = (res ?? {})['data']['list'] as List;

    final karLoyaltyIndex =
        loyaltyUserList.indexWhere((e) => e['token'] == 'ACA');
    if (karLoyaltyIndex > -1) {
      final loyaltyUser =
          Fmt.balanceInt(loyaltyUserList[karLoyaltyIndex]['loyaltyBonus']);
      if (loyaltyUser > BigInt.zero) {
        setState(() {
          _loyaltyUser = loyaltyUser;
          _fetching = false;
        });
      }
    }
  }

  Future<void> _fetchData() async {
    _fetchKarIssuance();
    _fetchLoyaltyBonus();
    _updateLoyaltyBonusUser();

    widget.plugin.service!.gov.updateBestNumber();

    await widget.plugin.service!.earn.queryIncentives();

    widget.plugin.service!.assets.queryMarketPrices();

    if (mounted) {
      setState(() {
        _loading = false;
      });
    }
  }

  Future<void> _onClaimReward(Map<String?, List<IncentiveItemData>>? incentives,
      TokenBalanceData token, String rewardView) async {
    if (_fetching) return;

    final dic = I18n.of(context)!.getDic(i18n_full_dic_acala, 'acala')!;
    double? loyaltyBonus = 0;
    if (incentives![token.tokenNameId] != null) {
      loyaltyBonus = incentives[token.tokenNameId]![0].deduction;
    }

    final bestNumber = widget.plugin.store!.gov.bestNumber;
    var blockNumber;
    widget.plugin.store!.earn.dexIncentiveLoyaltyEndBlock.forEach((e) {
      if (token.tokenNameId == PluginFmt.getPool(widget.plugin, e['pool'])) {
        blockNumber = e['blockNumber'];
        return;
      }
    });
    final blocksToEnd =
        blockNumber != null ? blockNumber - bestNumber.toInt() : null;

    var isClaim = true;

    if (blocksToEnd != null && blocksToEnd > 0) {
      isClaim = await showCupertinoDialog(
          context: context,
          builder: (_) {
            return PolkawalletAlertDialog(
              title: Text(dic['earn.claim']!),
              content: Text.rich(TextSpan(children: [
                TextSpan(
                    text: I18n.of(context)!.locale.toString().contains('zh')
                        ? "即刻领取收益将造成"
                        : "The immediate claim will burn ",
                    style: Theme.of(context).textTheme.bodyText1?.copyWith(
                        color: Colors.black,
                        fontSize: UI.getTextSize(13, context))),
                TextSpan(
                    text: Fmt.ratio(loyaltyBonus),
                    style: Theme.of(context).textTheme.bodyText1?.copyWith(
                        color: Color(0xFFFF3B30),
                        fontSize: UI.getTextSize(13, context))),
                TextSpan(
                    text: I18n.of(context)!.locale.toString().contains('zh')
                        ? "的收益损失。"
                        : " of the total rewards.You will be able to claim the full reward in ",
                    style: Theme.of(context).textTheme.bodyText1?.copyWith(
                        color: Colors.black,
                        fontSize: UI.getTextSize(13, context))),
                TextSpan(
                    text: Fmt.blockToTime(blocksToEnd ?? 0, 12500,
                        locale: I18n.of(context)!.locale.toString()),
                    style: Theme.of(context).textTheme.bodyText1?.copyWith(
                        color: Color(0xFFFF3B30),
                        fontSize: UI.getTextSize(13, context))),
                I18n.of(context)!.locale.toString().contains('zh')
                    ? TextSpan(
                        text: "后，您可以领取全额收益",
                        style: Theme.of(context).textTheme.bodyText1?.copyWith(
                            color: Colors.black,
                            fontSize: UI.getTextSize(13, context)))
                    : TextSpan(),
              ])),
              actions: <Widget>[
                PolkawalletActionSheetAction(
                  child: Text(dic['homa.redeem.cancel']!),
                  onPressed: () => Navigator.of(context).pop(false),
                ),
                PolkawalletActionSheetAction(
                  isDefaultAction: true,
                  child: Text(dic['homa.confirm']!),
                  onPressed: () => Navigator.of(context).pop(true),
                )
              ],
            );
          });
    }

    final total = double.tryParse(rewardView.split(' ')[0]);
    final forego = (total ?? 0) * (loyaltyBonus ?? 0);
    final receive = (total ?? 0) * (1 - (loyaltyBonus ?? 0));
    isClaim = await showCupertinoDialog(
        context: context,
        builder: (_) {
          return PolkawalletAlertDialog(
            title: Text(dic['earn.claim']!),
            content: Column(
              children: [
                Text.rich(TextSpan(children: [
                  TextSpan(
                      text: I18n.of(context)!.locale.toString().contains('zh')
                          ? "即刻领取收益将造成"
                          : "The immediate claim will burn ",
                      style: Theme.of(context).textTheme.bodyText1?.copyWith(
                          color: Colors.black,
                          fontSize: UI.getTextSize(13, context))),
                  TextSpan(
                      text: Fmt.ratio(loyaltyBonus),
                      style: Theme.of(context).textTheme.bodyText1?.copyWith(
                          color: Color(0xFFFF3B30),
                          fontSize: UI.getTextSize(13, context))),
                  TextSpan(
                      text: I18n.of(context)!.locale.toString().contains('zh')
                          ? "的收益损失。"
                          : " of the total rewards.",
                      style: Theme.of(context).textTheme.bodyText1?.copyWith(
                          color: Colors.black,
                          fontSize: UI.getTextSize(13, context))),
                ])),
                Divider(color: Colors.black26, thickness: 0.5),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(dic['earn.reward']!),
                    Text(rewardView),
                  ],
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(dic['earn.loyalty.forego']!),
                    Text(Fmt.priceCeil(forego, lengthMax: 4) + ' ACA'),
                  ],
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(dic['earn.loyalty.receive']!),
                    Text(Fmt.priceFloor(receive, lengthMax: 4) + ' ACA'),
                  ],
                ),
              ],
            ),
            actions: <Widget>[
              PolkawalletActionSheetAction(
                child: Text(dic['homa.redeem.cancel']!),
                onPressed: () => Navigator.of(context).pop(false),
              ),
              PolkawalletActionSheetAction(
                isDefaultAction: true,
                child: Text(dic['homa.confirm']!),
                onPressed: () => Navigator.of(context).pop(true),
              )
            ],
          );
        });

    if (isClaim) {
      final pool = {'Earning': token.currencyId};
      final params = TxConfirmParams(
        module: 'incentives',
        call: 'claimRewards',
        txTitle: dic['earn.claim'],
        txDisplay: {
          dic['loan.amount']: '≈ ${Fmt.priceFloor(receive, lengthMax: 4)} ACA',
          dic['earn.stake.pool']: token.symbol,
        },
        params: [pool],
        isPlugin: true,
      );
      Navigator.of(context).pushNamed(TxConfirmPage.route, arguments: params);
    }
  }

  @override
  Widget build(BuildContext context) {
    final dic = I18n.of(context)!.getDic(i18n_full_dic_acala, 'acala')!;

    final token = AssetsUtils.getBalanceFromTokenNameId(widget.plugin, 'ACA');
    final incentives = widget.plugin.store!.earn.incentives.loans;
    double apy = 0;
    double emission = 0;
    if (incentives![token.tokenNameId] != null) {
      incentives[token.tokenNameId]!.forEach((e) {
        if (e.tokenNameId != 'Any') {
          apy += e.apr ?? 0;
          emission += e.amount ?? 0;
        }
      });
    }

    bool canClaim = false;
    final reward =
        widget.plugin.store!.loan.collateralRewards[token.tokenNameId];
    final rewardView = reward != null && reward.reward!.length > 0
        ? reward.reward!.map((e) {
            num amount = e['amount'];
            if (amount < 0) {
              amount = 0;
            }
            if (amount > 0.0001) {
              canClaim = true;
            }
            final rewardToken = AssetsUtils.getBalanceFromTokenNameId(
                widget.plugin, e['tokenNameId']);
            return '${Fmt.priceFloor(amount.toDouble(), lengthMax: 4)} ${PluginFmt.tokenView(rewardToken.symbol)}';
          }).join(' + ')
        : '0.00';

    final deposit = Fmt.priceFloorBigInt(reward?.shares, token.decimals ?? 12);

    return _loading
        ? PluginPopLoadingContainer(
            loading: true,
            child: ConnectionChecker(
              widget.plugin,
              onConnected: _fetchData,
            ))
        : RefreshIndicator(
            child: ListView(
              padding: EdgeInsets.only(bottom: 32),
              children: [
                RoundedPluginCard(
                  margin: EdgeInsets.fromLTRB(16, 16, 16, 0),
                  padding: EdgeInsets.all(16),
                  child: Column(
                    children: [
                      Row(children: [
                        Container(
                            margin: EdgeInsets.only(right: 12),
                            child: PluginTokenIcon(
                              token.symbol!,
                              widget.plugin.tokenIcons,
                              size: 26,
                            )),
                        Text(Fmt.ratio(apy),
                            style: Theme.of(context)
                                .textTheme
                                .headline3
                                ?.copyWith(
                                    fontSize: UI.getTextSize(20, context),
                                    color: Colors.white)),
                        Container(
                          margin: EdgeInsets.only(left: 8),
                          child: Text('APY',
                              style: Theme.of(context)
                                  .textTheme
                                  .labelMedium
                                  ?.copyWith(
                                      fontSize: UI.getTextSize(12, context),
                                      color: Colors.white)),
                        ),
                      ]),
                      Divider(),
                      InfoItemRow('ACA ${dic['earn.kar.volume']}',
                          '${Fmt.priceFloorBigInt(_totalKar, 12)} ACA'),
                      InfoItemRow(dic['earn.kar.pool']!,
                          '${Fmt.priceFloorBigInt(reward?.sharesTotal, 12)} ACA'),
                      InfoItemRow(
                          dic['earn.kar.rate']!,
                          Fmt.ratio((reward?.sharesTotal ?? BigInt.zero) /
                              _totalKar)),
                      Divider(),
                      InfoItemRow(dic['earn.kar.emission']!,
                          '${Fmt.priceFloor(emission / 365 * 31)} ACA/Month'),
                      InfoItemRow(dic['earn.kar.loyalty']!,
                          '${Fmt.priceFloorBigInt(_loyalty, 12)} ACA'),
                    ],
                  ),
                ),
                RoundedPluginCard(
                  margin: EdgeInsets.fromLTRB(16, 16, 16, 0),
                  child: Column(
                    children: [
                      Container(
                        width: double.infinity,
                        alignment: Alignment.centerLeft,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.only(
                              topLeft: Radius.circular(8),
                              topRight: Radius.circular(8)),
                        ),
                        padding:
                            EdgeInsets.symmetric(horizontal: 12, vertical: 11),
                        child: Text('My Balance',
                            style: Theme.of(context)
                                .textTheme
                                .headline3
                                ?.copyWith(
                                    fontSize: UI.getTextSize(18, context),
                                    color: Colors.white)),
                      ),
                      Container(
                          width: double.infinity,
                          color: Color(0xFF494b4e),
                          padding: EdgeInsets.only(top: 24, bottom: 10),
                          child: Column(
                            children: [
                              PluginInfoItem(
                                isExpanded: false,
                                crossAxisAlignment: CrossAxisAlignment.center,
                                title: dic['earn.reward'],
                                content: rewardView,
                                titleStyle: Theme.of(context)
                                    .textTheme
                                    .headline5
                                    ?.copyWith(
                                      color: Colors.white,
                                      height: 1.0,
                                    ),
                                style: Theme.of(context)
                                    .textTheme
                                    .headline5
                                    ?.copyWith(
                                        color: Colors.white,
                                        fontSize: UI.getTextSize(24, context),
                                        height: 1.5,
                                        fontWeight: FontWeight.bold),
                              ),
                              Container(
                                margin: EdgeInsets.only(bottom: 22),
                                child: Text(
                                  '(${Fmt.priceFloorBigInt(_loyaltyUser, 12, lengthMax: 4)} ACA ${dic['earn.loyalty.from']})',
                                  style: TextStyle(fontSize: 10),
                                ),
                              ),
                              Padding(
                                  padding: EdgeInsets.only(bottom: 16),
                                  child: Row(
                                    children: [
                                      PluginInfoItem(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.center,
                                        title:
                                            "Staked (${PluginFmt.tokenView(token.symbol)})",
                                        content: deposit,
                                        titleStyle: Theme.of(context)
                                            .textTheme
                                            .headline5
                                            ?.copyWith(
                                              color: Colors.white,
                                              height: 1.0,
                                            ),
                                        style: Theme.of(context)
                                            .textTheme
                                            .headline5
                                            ?.copyWith(
                                                color: Colors.white,
                                                fontSize:
                                                    UI.getTextSize(20, context),
                                                height: 1.5,
                                                fontWeight: FontWeight.bold),
                                      ),
                                      PluginInfoItem(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.center,
                                        title:
                                            '${dic['earn.available']} (${PluginFmt.tokenView(token.symbol)})',
                                        content: Fmt.priceFloorBigInt(
                                            Fmt.balanceInt(token.amount), 12),
                                        titleStyle: Theme.of(context)
                                            .textTheme
                                            .headline5
                                            ?.copyWith(
                                              color: Colors.white,
                                              height: 1.0,
                                            ),
                                        style: Theme.of(context)
                                            .textTheme
                                            .headline5
                                            ?.copyWith(
                                                color: Colors.white,
                                                fontSize:
                                                    UI.getTextSize(20, context),
                                                height: 1.5,
                                                fontWeight: FontWeight.bold),
                                      ),
                                    ],
                                  )),
                            ],
                          )),
                      Container(
                          width: double.infinity,
                          padding:
                              EdgeInsets.symmetric(vertical: 13, horizontal: 8),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.only(
                                bottomLeft: Radius.circular(8),
                                bottomRight: Radius.circular(8)),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: PluginOutlinedButtonSmall(
                                  content: 'Unstake',
                                  color: Color(0xFFFF7849),
                                  active: true,
                                  padding: EdgeInsets.only(top: 8, bottom: 8),
                                  margin: EdgeInsets.zero,
                                  onPressed: (reward?.shares ?? BigInt.zero) >
                                          BigInt.zero
                                      ? () => Navigator.of(context).pushNamed(
                                            LoanDepositPage.route,
                                            arguments: {
                                              "type": LoanDepositPage
                                                  .actionTypeWithdraw,
                                              "tokenNameId": token.tokenNameId
                                            },
                                          )
                                      : null,
                                ),
                              ),
                              Container(width: 15),
                              Expanded(
                                child: PluginOutlinedButtonSmall(
                                  content: 'Stake',
                                  color: Color(0xFFFF7849),
                                  active: true,
                                  padding: EdgeInsets.only(top: 8, bottom: 8),
                                  margin: EdgeInsets.zero,
                                  onPressed: () =>
                                      Navigator.of(context).pushNamed(
                                    LoanDepositPage.route,
                                    arguments: {
                                      "type": LoanDepositPage.actionTypeDeposit,
                                      "tokenNameId": token.tokenNameId
                                    },
                                  ),
                                ),
                              ),
                              Container(width: 15),
                              Expanded(
                                child: PluginOutlinedButtonSmall(
                                  content: dic['earn.claim'],
                                  color: Color(0xFFFF7849),
                                  active: canClaim,
                                  padding: EdgeInsets.only(top: 8, bottom: 8),
                                  margin: EdgeInsets.zero,
                                  onPressed: canClaim
                                      ? () => _onClaimReward(
                                          incentives, token, rewardView)
                                      : null,
                                ),
                              ),
                            ],
                          )),
                    ],
                  ),
                )
              ],
            ),
            onRefresh: _fetchData);
  }
}
