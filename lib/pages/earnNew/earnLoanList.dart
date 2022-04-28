import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:polkawallet_plugin_acala/api/earn/types/incentivesData.dart';
import 'package:polkawallet_plugin_acala/api/types/loanType.dart';
import 'package:polkawallet_plugin_acala/common/constants/index.dart';
import 'package:polkawallet_plugin_acala/pages/loanNew/loanDepositPage.dart';
import 'package:polkawallet_plugin_acala/polkawallet_plugin_acala.dart';
import 'package:polkawallet_plugin_acala/utils/assets.dart';
import 'package:polkawallet_plugin_acala/utils/format.dart';
import 'package:polkawallet_plugin_acala/utils/i18n/index.dart';
import 'package:polkawallet_sdk/plugin/store/balances.dart';
import 'package:polkawallet_sdk/storage/keyring.dart';
import 'package:polkawallet_sdk/utils/i18n.dart';
import 'package:polkawallet_ui/components/listTail.dart';
import 'package:polkawallet_ui/components/tapTooltip.dart';
import 'package:polkawallet_ui/components/v3/plugin/pluginInfoItem.dart';
import 'package:polkawallet_ui/components/v3/plugin/pluginOutlinedButtonSmall.dart';
import 'package:polkawallet_ui/components/v3/plugin/pluginTokenIcon.dart';
import 'package:polkawallet_ui/components/v3/plugin/roundedPluginCard.dart';
import 'package:polkawallet_ui/components/v3/txButton.dart';
import 'package:polkawallet_ui/pages/v3/txConfirmPage.dart';
import 'package:polkawallet_ui/utils/format.dart';

class EarnLoanList extends StatefulWidget {
  EarnLoanList(this.plugin, this.keyring);
  final PluginAcala plugin;
  final Keyring keyring;

  @override
  _EarnLoanListState createState() => _EarnLoanListState();
}

class _EarnLoanListState extends State<EarnLoanList> {
  bool _loading = true;

  Future<void> _fetchData() async {
    await widget.plugin.service!.loan
        .queryLoanTypes(widget.keyring.current.address);

    widget.plugin.service!.assets.queryMarketPrices();

    if (mounted) {
      setState(() {
        _loading = false;
      });

      // we have a global [subscribeAccountLoans] in plugin_acala,
      // so we don't need to do the subscribe here.
      // widget.plugin.service!.loan
      //     .subscribeAccountLoans(widget.keyring.current.address);
    }
  }

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance!.addPostFrameCallback((_) {
      _fetchData();
    });
  }

  @override
  Widget build(BuildContext context) {
    final incentiveTokenSymbol = widget.plugin.networkState.tokenSymbol![0];
    return Observer(
      builder: (_) {
        final loans = widget.plugin.store!.loan.loans.values.toList();
        loans.retainWhere((loan) =>
            loan.debits > BigInt.zero || loan.collaterals > BigInt.zero);

        return _loading
            ? ListView(
                padding: EdgeInsets.all(16),
                children: [
                  Center(
                    child: Container(
                      height: MediaQuery.of(context).size.width,
                      child: ListTail(
                        isEmpty: true,
                        isLoading: true,
                        color: Colors.white,
                      ),
                    ),
                  )
                ],
              )
            : CollateralIncentiveList(
                plugin: widget.plugin,
                tokenIcons: widget.plugin.tokenIcons,
                incentives: widget.plugin.store!.earn.incentives.loans,
                rewards: widget.plugin.store!.loan.collateralRewards,
                incentiveTokenSymbol: incentiveTokenSymbol,
                dexIncentiveLoyaltyEndBlock:
                    widget.plugin.store!.earn.dexIncentiveLoyaltyEndBlock,
              );
      },
    );
  }
}

class CollateralIncentiveList extends StatelessWidget {
  CollateralIncentiveList({
    required this.plugin,
    this.incentives,
    this.rewards,
    this.tokenIcons,
    this.incentiveTokenSymbol,
    this.dexIncentiveLoyaltyEndBlock,
  });

  final PluginAcala plugin;
  final Map<String?, List<IncentiveItemData>>? incentives;
  final Map<String?, CollateralRewardData>? rewards;
  final Map<String, Widget>? tokenIcons;
  final String? incentiveTokenSymbol;
  final List<dynamic>? dexIncentiveLoyaltyEndBlock;

  Future<void> _onClaimReward(
      BuildContext context, TokenBalanceData token, String rewardView) async {
    final dic = I18n.of(context)!.getDic(i18n_full_dic_acala, 'acala')!;
    double? loyaltyBonus = 0;
    if (incentives![token.tokenNameId] != null) {
      loyaltyBonus = incentives![token.tokenNameId]![0].deduction;
    }

    final bestNumber = plugin!.store!.gov.bestNumber;
    var blockNumber;
    dexIncentiveLoyaltyEndBlock!.forEach((e) {
      if (token.tokenNameId == PluginFmt.getPool(plugin, e['pool'])) {
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
            return CupertinoAlertDialog(
              title: Text(dic['earn.claim']!),
              content: Text.rich(TextSpan(children: [
                TextSpan(
                    text: I18n.of(context)!.locale.toString().contains('zh')
                        ? "即刻领取收益将造成"
                        : "The immediate claim will burn ",
                    style: Theme.of(context)
                        .textTheme
                        .bodyText1
                        ?.copyWith(color: Colors.black, fontSize: 13)),
                TextSpan(
                    text: Fmt.ratio(loyaltyBonus),
                    style: Theme.of(context)
                        .textTheme
                        .bodyText1
                        ?.copyWith(color: Color(0xFFFF3B30), fontSize: 13)),
                TextSpan(
                    text: I18n.of(context)!.locale.toString().contains('zh')
                        ? "的收益损失。"
                        : " of the total rewards.You will be able to claim the full reward in ",
                    style: Theme.of(context)
                        .textTheme
                        .bodyText1
                        ?.copyWith(color: Colors.black, fontSize: 13)),
                TextSpan(
                    text: Fmt.blockToTime(blocksToEnd ?? 0, 12500,
                        locale: I18n.of(context)!.locale.toString()),
                    style: Theme.of(context)
                        .textTheme
                        .bodyText1
                        ?.copyWith(color: Color(0xFFFF3B30), fontSize: 13)),
                I18n.of(context)!.locale.toString().contains('zh')
                    ? TextSpan(
                        text: "后，您可以领取全额收益",
                        style: Theme.of(context)
                            .textTheme
                            .bodyText1
                            ?.copyWith(color: Colors.black, fontSize: 13))
                    : TextSpan(),
              ])),
              actions: <Widget>[
                CupertinoDialogAction(
                  child: Text(dic['homa.redeem.cancel']!),
                  onPressed: () => Navigator.of(context).pop(false),
                ),
                CupertinoDialogAction(
                  child: Text(dic['homa.confirm']!),
                  onPressed: () => Navigator.of(context).pop(true),
                )
              ],
            );
          });
    }

    if (isClaim) {
      final pool = {'Loans': token.currencyId};
      final params = TxConfirmParams(
        module: 'incentives',
        call: 'claimRewards',
        txTitle: dic['earn.claim'],
        txDisplay: {
          dic['loan.amount']: '≈ $rewardView',
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
    final List<String?> tokensAll = incentives!.keys.toList();
    tokensAll.addAll(rewards!.keys.toList());
    final tokenIds = tokensAll.toSet().toList();
    tokenIds.removeWhere((e) => e == relay_chain_token_symbol);
    tokenIds.retainWhere((e) =>
        incentives![e] != null ||
        (rewards![e]?.reward != null && rewards![e]!.reward!.length > 0));

    if (tokenIds.length == 0) {
      return ListTail(
        isEmpty: true,
        isLoading: false,
        color: Colors.white,
      );
    }
    final tokens = tokenIds
        .map((e) => AssetsUtils.getBalanceFromTokenNameId(plugin!, e))
        .toList();

    return ListView.builder(
        padding: EdgeInsets.only(bottom: 32),
        itemCount: tokens.length,
        itemBuilder: (_, i) {
          final token = tokens[i];
          double apy = 0;
          if (incentives![token.tokenNameId] != null) {
            incentives![token.tokenNameId]!.forEach((e) {
              if (e.tokenNameId != 'Any') {
                apy += e.apr ?? 0;
              }
            });
          }

          bool canClaim = false;
          final reward = rewards![token.tokenNameId];
          final rewardView = reward != null && reward.reward!.length > 0
              ? reward.reward!.map((e) {
                  double amount = double.parse(e['amount']);
                  if (amount < 0) {
                    amount = 0;
                  }
                  if (amount > 0.0001) {
                    canClaim = true;
                  }
                  final rewardToken = AssetsUtils.getBalanceFromTokenNameId(
                      plugin, e['tokenNameId']);
                  return '${Fmt.priceFloor(amount)} ${PluginFmt.tokenView(rewardToken.symbol)}';
                }).join(' + ')
              : '0.00';

          final deposit =
              Fmt.priceFloorBigInt(reward?.shares, token.decimals ?? 12);

          final incentiveEndIndex = plugin.store?.earn.dexIncentiveEndBlock
              .indexWhere((e) =>
                  token.tokenNameId == PluginFmt.getPool(plugin, e['pool']));
          final incentiveEndBlock = (incentiveEndIndex ?? -1) < 0
              ? null
              : plugin.store?.earn.dexIncentiveEndBlock[incentiveEndIndex!]
                  ['blockNumber'];

          final incentiveEndBlocks = incentiveEndBlock != null
              ? incentiveEndBlock - plugin.store!.gov.bestNumber.toInt()
              : null;
          final incentiveEndTime = DateTime.now().add(Duration(
              seconds: (plugin.store!.earn.blockDuration /
                      1000 *
                      (incentiveEndBlocks ?? 0))
                  .toInt()));

          return RoundedPluginCard(
            borderRadius: const BorderRadius.all(const Radius.circular(14)),
            margin: EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: Column(
              children: [
                Container(
                  width: double.infinity,
                  alignment: Alignment.centerLeft,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(14),
                        topRight: Radius.circular(14)),
                  ),
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 15),
                  child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                            margin: EdgeInsets.only(right: 12),
                            child: PluginTokenIcon(
                              token.symbol!,
                              tokenIcons!,
                              size: 26,
                            )),
                        Text(PluginFmt.tokenView(token.symbol),
                            style: Theme.of(context)
                                .textTheme
                                .headline3
                                ?.copyWith(fontSize: 18, color: Colors.white)),
                        Expanded(
                          child: incentiveEndBlock == null
                              ? Container()
                              : Container(
                                  margin: EdgeInsets.only(right: 16, top: 4),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.end,
                                    children: [
                                      TapTooltip(
                                        message:
                                            '${dic['earn.incentive.est']} ${Fmt.dateTime(incentiveEndTime).split(' ')[0]}',
                                        child: Row(
                                          children: [
                                            Container(
                                              margin: EdgeInsets.only(right: 2),
                                              child: Icon(
                                                Icons.access_time_rounded,
                                                color: Colors.white,
                                                size: 14,
                                              ),
                                            ),
                                            Text(
                                              dic['earn.incentive.end']!,
                                              style: TextStyle(
                                                  fontSize: 12,
                                                  color: Colors.white),
                                            ),
                                            Text(
                                              ' ${Fmt.priceFloor(double.parse(incentiveEndBlocks.toString()), lengthFixed: 0)} ${dic['earn.incentive.blocks']}',
                                              style: TextStyle(
                                                  fontSize: 12,
                                                  color: Color(0xFFFF7849)),
                                            )
                                          ],
                                        ),
                                      )
                                    ],
                                  ),
                                ),
                        ),
                        Visibility(
                            visible: canClaim,
                            child: Padding(
                                padding: EdgeInsets.only(left: 4),
                                child: Image.asset(
                                  "packages/polkawallet_plugin_acala/assets/images/rewards.png",
                                  width: 24,
                                ))),
                      ]),
                ),
                Container(
                    width: double.infinity,
                    color: Color(0xFF494b4e),
                    padding: EdgeInsets.symmetric(vertical: 20),
                    child: Column(
                      children: [
                        Container(
                          margin: EdgeInsets.only(bottom: 16),
                          child: PluginInfoItem(
                            isExpanded: false,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            title: dic['earn.reward'],
                            content: rewardView,
                            titleStyle:
                                Theme.of(context).textTheme.headline5?.copyWith(
                                      color: Colors.white,
                                      height: 1.0,
                                    ),
                            style: Theme.of(context)
                                .textTheme
                                .headline5
                                ?.copyWith(
                                    color: Colors.white,
                                    fontSize: 24,
                                    height: 1.5,
                                    fontWeight: FontWeight.bold),
                          ),
                        ),
                        Row(
                          children: [
                            PluginInfoItem(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              title:
                                  "${dic['loan.collateral']} (${PluginFmt.tokenView(token.symbol)})",
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
                                      fontSize: 20,
                                      height: 1.5,
                                      fontWeight: FontWeight.bold),
                            ),
                            PluginInfoItem(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              title: dic['earn.apy'],
                              content: Fmt.ratio(apy),
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
                                      fontSize: 20,
                                      height: 1.5,
                                      fontWeight: FontWeight.bold),
                            ),
                          ],
                        )
                      ],
                    )),
                Container(
                    width: double.infinity,
                    padding: EdgeInsets.symmetric(vertical: 13, horizontal: 8),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.only(
                          bottomLeft: Radius.circular(14),
                          bottomRight: Radius.circular(14)),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: PluginOutlinedButtonSmall(
                            content: dic['loan.withdraw'],
                            color: Color(0xFFFF7849),
                            active: true,
                            padding: EdgeInsets.only(top: 8, bottom: 8),
                            margin: EdgeInsets.zero,
                            onPressed: (reward?.shares ?? BigInt.zero) >
                                    BigInt.zero
                                ? () => Navigator.of(context).pushNamed(
                                      LoanDepositPage.route,
                                      arguments: LoanDepositPageParams(
                                          LoanDepositPage.actionTypeWithdraw,
                                          token),
                                    )
                                : null,
                          ),
                        ),
                        Container(width: 15),
                        Expanded(
                          child: PluginOutlinedButtonSmall(
                            content: dic['loan.deposit'],
                            color: Color(0xFFFF7849),
                            active: true,
                            padding: EdgeInsets.only(top: 8, bottom: 8),
                            margin: EdgeInsets.zero,
                            onPressed: () => Navigator.of(context).pushNamed(
                              LoanDepositPage.route,
                              arguments: LoanDepositPageParams(
                                  LoanDepositPage.actionTypeDeposit, token),
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
                                ? () =>
                                    _onClaimReward(context, token, rewardView)
                                : null,
                          ),
                        ),
                      ],
                    )),
              ],
            ),
          );
        });
  }
}
