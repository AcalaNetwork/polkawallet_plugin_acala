import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:polkawallet_plugin_acala/api/earn/types/incentivesData.dart';
import 'package:polkawallet_plugin_acala/api/types/loanType.dart';
import 'package:polkawallet_plugin_acala/pages/earnNew/earningUnbondPage.dart';
import 'package:polkawallet_plugin_acala/pages/loanNew/loanDepositPage.dart';
import 'package:polkawallet_plugin_acala/pages/loanNew/loanInfoPanel.dart';
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
import 'package:polkawallet_ui/components/v3/plugin/pluginInfoItem.dart';
import 'package:polkawallet_ui/components/v3/plugin/pluginOutlinedButtonSmall.dart';
import 'package:polkawallet_ui/components/v3/plugin/pluginPopLoadingWidget.dart';
import 'package:polkawallet_ui/components/v3/plugin/pluginTokenIcon.dart';
import 'package:polkawallet_ui/components/v3/plugin/roundedPluginCard.dart';
import 'package:polkawallet_ui/components/v3/txButton.dart';
import 'package:polkawallet_ui/pages/v3/txConfirmPage.dart';
import 'package:polkawallet_ui/utils/consts.dart';
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
  TokenBalanceData? _deductionToken;

  BigInt _staked = BigInt.zero;
  BigInt _active = BigInt.zero;
  List<List<BigInt>> _unlocking = [];

  String _getRewardView(
    CollateralRewardData? reward, {
    double deduction = 0,
    String? onlyToken,
    bool isBurn = false,
  }) {
    if (reward != null && reward.reward!.length > 0) {
      if (onlyToken != null && isBurn) {
        reward.reward!.retainWhere((e) => e['tokenNameId'] == onlyToken);
      }
      final proportion = isBurn ? deduction : 1 - deduction;
      return reward.reward!.map((e) {
        num amount = e['amount'];
        if (amount < 0) {
          amount = 0;
        }
        return '${Fmt.priceFloor(amount.toDouble() * proportion, lengthMax: reward.reward!.length > 1 ? 2 : 4)} ${e['tokenNameId']}';
      }).join(' + ');
    }
    return '0.00';
  }

  Future<void> _fetchUserStaked() async {
    final res = await widget.plugin.sdk.webView?.evalJavascript(
        'api.query.earning.ledger("${widget.keyring.current.address}")');
    if (res != null && mounted) {
      setState(() {
        _staked = Fmt.balanceInt(res['total'].toString());
        _active = Fmt.balanceInt(res['active'].toString());
        _unlocking = List.of(res['unlocking'])
            .map((e) => [
                  Fmt.balanceInt(e['value'].toString()),
                  Fmt.balanceInt(e['unlockAt'].toString())
                ])
            .toList();
      });
    }
  }

  Future<void> _fetchKarIssuance() async {
    final res = await widget.plugin.sdk.webView
        ?.evalJavascript('api.query.balances.totalIssuance()');
    setState(() {
      _totalKar = Fmt.balanceInt(res.toString());
    });
  }

  Future<void> _fetchDeductionCurrency() async {
    final res = await widget.plugin.api!.earn.getIncentiveDeductionCurrency({
      'Earning': {'Token': 'KAR'}
    });
    if (res != null && mounted) {
      setState(() {
        _deductionToken =
            AssetsUtils.tokenDataFromCurrencyId(widget.plugin, res);
      });
    }
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
        });
      }
    }
  }

  Future<void> _fetchData() async {
    _fetchKarIssuance();
    _fetchLoyaltyBonus();
    _fetchDeductionCurrency();

    _updateLoyaltyBonusUser();
    _fetchUserStaked();

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
      TokenBalanceData token, CollateralRewardData? reward) async {
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
                    text: Fmt.blockToTime(blocksToEnd ?? 0,
                        widget.plugin.store!.earn.blockDuration,
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

    final receive = _getRewardView(reward,
        deduction: loyaltyBonus ?? 0, onlyToken: _deductionToken?.symbol);
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
                          ? "的${_deductionToken != null ? _deductionToken?.symbol : ''}收益损失。"
                          : " of the ${_deductionToken != null ? _deductionToken?.symbol : 'total'} rewards.",
                      style: Theme.of(context).textTheme.bodyText1?.copyWith(
                          color: Colors.black,
                          fontSize: UI.getTextSize(13, context))),
                ])),
                Divider(color: Colors.black26, thickness: 0.5),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(dic['earn.reward']!),
                    Expanded(
                        child: Text(
                      _getRewardView(reward),
                      textAlign: TextAlign.end,
                    )),
                  ],
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(dic['earn.loyalty.forego']!),
                    Expanded(
                        child: Text(
                            _getRewardView(reward,
                                deduction: loyaltyBonus ?? 0,
                                onlyToken: _deductionToken?.symbol,
                                isBurn: true),
                            textAlign: TextAlign.end)),
                  ],
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(dic['earn.loyalty.receive']!),
                    Expanded(child: Text(receive, textAlign: TextAlign.end)),
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
          dic['loan.amount']: '≈ $receive',
          dic['earn.stake.pool']: token.symbol,
        },
        params: [pool],
        isPlugin: true,
      );
      final res = await Navigator.of(context)
          .pushNamed(TxConfirmPage.route, arguments: params);
      if (res != null) {
        _fetchData();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final dic = I18n.of(context)!.getDic(i18n_full_dic_acala, 'acala')!;

    final token = AssetsUtils.getBalanceFromTokenNameId(widget.plugin, 'ACA');
    final incentives = widget.plugin.store!.earn.incentives.loans;
    double apy = 0;
    String emissionView = '';
    if (incentives != null && incentives[token.tokenNameId] != null) {
      incentives[token.tokenNameId]!.forEach((e) {
        if (e.tokenNameId != 'Any') {
          apy += e.apr ?? 0;
          if (emissionView.isEmpty) {
            emissionView =
                '${Fmt.priceFloor((e.amount ?? 0) / 365 * 31)} ${PluginFmt.tokenView(e.tokenNameId)}/Month';
          } else {
            emissionView +=
                '\n${Fmt.priceFloor((e.amount ?? 0) / 365 * 31)} ${PluginFmt.tokenView(e.tokenNameId)}/Month';
          }
        }
      });
    }

    final freeBalance =
        Fmt.balanceInt(widget.plugin.balances.native?.freeBalance.toString());
    final available = freeBalance - _staked;
    bool canClaim = false;
    final reward =
        widget.plugin.store!.loan.collateralRewards[token.tokenNameId];
    reward?.reward?.forEach((e) {
      final num amount = e['amount'];
      if (amount > 0.0001) {
        canClaim = true;
      }
    });

    final maxUnbondingChunks = Fmt.balanceInt(widget
        .plugin.networkConst['earning']['maxUnbondingChunks']
        ?.toString());
    final canUnbond = _unlocking.length < maxUnbondingChunks.toInt();

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
                      LoanInfoItemRow('ACA ${dic['earn.kar.volume']}',
                          '${Fmt.priceFloorBigInt(_totalKar, 12)} ACA'),
                      LoanInfoItemRow(dic['earn.kar.pool']!,
                          '${Fmt.priceFloorBigInt(reward?.sharesTotal, 12)} ACA'),
                      LoanInfoItemRow(
                          dic['earn.kar.rate']!,
                          Fmt.ratio((reward?.sharesTotal ?? BigInt.zero) /
                              _totalKar)),
                      Divider(),
                      LoanInfoItemRow(dic['earn.kar.emission']!, emissionView),
                      LoanInfoItemRow(dic['earn.kar.loyalty']!,
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
                        child: Text(dic['earn.kar.balance']!,
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
                                content: _getRewardView(reward),
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
                              Row(
                                children: [
                                  PluginInfoItem(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.center,
                                    title:
                                        "Staked (${PluginFmt.tokenView(token.symbol)})",
                                    content: Fmt.priceFloorBigInt(_active, 12),
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
                                    content:
                                        Fmt.priceFloorBigInt(available, 12),
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
                              ),
                              Visibility(
                                  visible: _staked - _active > BigInt.zero,
                                  child: Padding(
                                      padding:
                                          EdgeInsets.only(bottom: 8, left: 32),
                                      child: GestureDetector(
                                        child: Row(
                                          children: [
                                            Text(
                                              '${dic['earn.unbond.title']} ${Fmt.priceFloorBigInt(_staked - _active, 12)} ACA',
                                              style: TextStyle(
                                                  fontSize: 10,
                                                  color:
                                                      PluginColorsDark.primary),
                                            ),
                                            Padding(
                                              padding: EdgeInsets.only(left: 8),
                                              child: Icon(
                                                Icons.info_outline,
                                                size: 14,
                                                color: PluginColorsDark.primary,
                                              ),
                                            ),
                                          ],
                                        ),
                                        onTap: () async {
                                          final res =
                                              await Navigator.of(context)
                                                  .pushNamed(
                                                      EarningUnbondPage.route,
                                                      arguments: _unlocking);
                                          if (res != null) {
                                            _fetchData();
                                          }
                                        },
                                      ))),
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
                                      ? canUnbond
                                          ? () async {
                                              final res =
                                                  await Navigator.of(context)
                                                      .pushNamed(
                                                LoanDepositPage.route,
                                                arguments: {
                                                  "type": LoanDepositPage
                                                      .actionTypeWithdraw,
                                                  "tokenNameId":
                                                      token.tokenNameId
                                                },
                                              );
                                              if (res != null) {
                                                _fetchData();
                                              }
                                            }
                                          : () => showCupertinoDialog(
                                              context: context,
                                              builder: (_) =>
                                                  PolkawalletAlertDialog(
                                                    title: Text('Unstake'),
                                                    content: Text(dic[
                                                        'earn.unbond.max']!),
                                                    actions: [
                                                      PolkawalletActionSheetAction(
                                                        isDefaultAction: true,
                                                        child: Text(dic[
                                                            'homa.confirm']!),
                                                        onPressed: () =>
                                                            Navigator.of(
                                                                    context)
                                                                .pop(),
                                                      )
                                                    ],
                                                  ))
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
                                  onPressed: () async {
                                    final res =
                                        await Navigator.of(context).pushNamed(
                                      LoanDepositPage.route,
                                      arguments: {
                                        "type":
                                            LoanDepositPage.actionTypeDeposit,
                                        "tokenNameId": token.tokenNameId
                                      },
                                    );
                                    if (res != null) {
                                      _fetchData();
                                    }
                                  },
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
                                          incentives, token, reward)
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
