import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:polkawallet_plugin_acala/api/types/dexPoolInfoData.dart';
import 'package:polkawallet_plugin_acala/pages/earnNew/earnDetailPage.dart';
import 'package:polkawallet_plugin_acala/polkawallet_plugin_acala.dart';
import 'package:polkawallet_plugin_acala/utils/assets.dart';
import 'package:polkawallet_plugin_acala/utils/format.dart';
import 'package:polkawallet_plugin_acala/utils/i18n/index.dart';
import 'package:polkawallet_sdk/utils/i18n.dart';
import 'package:polkawallet_ui/components/connectionChecker.dart';
import 'package:polkawallet_ui/components/v3/dialog.dart';
import 'package:polkawallet_ui/components/v3/index.dart' as v3;
import 'package:polkawallet_ui/components/v3/plugin/pluginIconButton.dart';
import 'package:polkawallet_ui/components/v3/plugin/pluginPopLoadingWidget.dart';
import 'package:polkawallet_ui/components/v3/plugin/pluginTokenIcon.dart';
import 'package:polkawallet_ui/components/v3/plugin/roundedPluginCard.dart';
import 'package:polkawallet_ui/utils/consts.dart';
import 'package:polkawallet_ui/utils/format.dart';
import 'package:polkawallet_ui/utils/index.dart';

class EarnDexList extends StatefulWidget {
  EarnDexList(this.plugin);
  final PluginAcala plugin;

  @override
  _EarnDexListState createState() => _EarnDexListState();
}

class _EarnDexListState extends State<EarnDexList> {
  Timer? _timer;

  bool _loading = true;
  bool _partake = false;
  String _sort = 'earn.dex.sort0';

  TextEditingController _controller = TextEditingController();
  String _search = '';

  Future<void> _fetchData() async {
    await widget.plugin.service!.earn.updateAllDexPoolInfo();

    widget.plugin.service!.gov.updateBestNumber();
    _loading = false;
    if (mounted) {
      setState(() {});

      _timer = Timer(Duration(seconds: 30), () {
        _fetchData();
      });
    }
  }

  @override
  void dispose() {
    if (_timer != null) {
      _timer!.cancel();
      _timer = null;
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final dic = I18n.of(context)!.getDic(i18n_full_dic_acala, 'acala');

    return Observer(builder: (_) {
      final incentivesV2 = widget.plugin.store!.earn.incentives;

      var dexPools = widget.plugin.store!.earn.dexPools.toList();

      if (dexPools.length > 0) {
        final List<DexPoolData> datas = [];
        final List<DexPoolData> otherDatas = [];
        for (int i = 0; i < dexPools.length; i++) {
          double incentive = 0;
          double rewards = 0;
          double savingRewards = 0;
          double? loyaltyBonus = 0;
          double? savingLoyaltyBonus = 0;

          if (incentivesV2.dex != null) {
            (incentivesV2.dex![dexPools[i].tokenNameId!] ?? []).forEach((e) {
              incentive += e.amount ?? 0;
              rewards += e.apr ?? 0;
              loyaltyBonus = e.deduction;
            });
          }

          dexPools[i].rewards = rewards + savingRewards;
          dexPools[i].rewardsLoyalty = rewards * (1 - loyaltyBonus!) +
              savingRewards * (1 - savingLoyaltyBonus);

          double userReward = 0;
          final poolInfo =
              widget.plugin.store!.earn.dexPoolInfoMap[dexPools[i].tokenNameId];
          (poolInfo?.reward?.incentive ?? []).forEach((e) {
            userReward = double.parse(e['amount']);
          });

          if (dexPools[i].provisioning == null &&
              (incentive > 0 || userReward > 0)) {
            if (_search.trim().isNotEmpty) {
              final balancePair = dexPools[i]
                  .tokens!
                  .map((e) =>
                      AssetsUtils.tokenDataFromCurrencyId(widget.plugin, e))
                  .toList();

              var tokenSymbol = balancePair.map((e) => e.symbol).join('-');
              if (!PluginFmt.tokenView(tokenSymbol)
                  .toUpperCase()
                  .contains(_search.trim().toUpperCase())) {
                continue;
              }
            }
            if (dexPools[i].tokenNameId!.indexOf("ACA") >= 0) {
              datas.add(dexPools[i]);
            } else {
              otherDatas.add(dexPools[i]);
            }
          }
        }

        if (_sort == 'earn.dex.sort0') {
          datas.sort((left, right) => right.rewards!.compareTo(left.rewards!));
          otherDatas
              .sort((left, right) => right.rewards!.compareTo(left.rewards!));
          datas.addAll(otherDatas);
        } else if (_sort == 'earn.dex.sort1') {
          datas.addAll(otherDatas);
          datas.sort((left, right) => right.rewards!.compareTo(left.rewards!));
        } else if (_sort == 'earn.dex.sort2') {
          datas.addAll(otherDatas);
          datas.sort((left, right) {
            final poolInfoLeft =
                widget.plugin.store!.earn.dexPoolInfoMap[left.tokenNameId];
            final poolInfoRight =
                widget.plugin.store!.earn.dexPoolInfoMap[right.tokenNameId];

            final tokenPairLeft = left.tokens!
                .map((e) =>
                    AssetsUtils.tokenDataFromCurrencyId(widget.plugin, e))
                .toList();
            BigInt? issuance = BigInt.zero;
            BigInt? shareTotal = BigInt.zero;
            double leftPrice = 0, rightPrice = 0;

            if (poolInfoLeft != null) {
              issuance = poolInfoLeft.issuance;
              shareTotal = poolInfoLeft.sharesTotal;

              leftPrice = Fmt.bigIntToDouble(
                      poolInfoLeft.amountLeft, tokenPairLeft[0].decimals!) *
                  AssetsUtils.getMarketPrice(
                      widget.plugin, tokenPairLeft[0].symbol ?? '');

              rightPrice = Fmt.bigIntToDouble(
                      poolInfoLeft.amountRight, tokenPairLeft[1].decimals!) *
                  AssetsUtils.getMarketPrice(
                      widget.plugin, tokenPairLeft[1].symbol ?? '');
            }
            final leftLP = (leftPrice + rightPrice) * (shareTotal! / issuance!);

            final tokenPairRight = right.tokens!
                .map((e) =>
                    AssetsUtils.tokenDataFromCurrencyId(widget.plugin, e))
                .toList();
            issuance = BigInt.zero;
            shareTotal = BigInt.zero;
            leftPrice = 0;
            rightPrice = 0;

            if (poolInfoRight != null) {
              issuance = poolInfoRight.issuance;
              shareTotal = poolInfoRight.sharesTotal;

              leftPrice = Fmt.bigIntToDouble(
                      poolInfoRight.amountLeft, tokenPairRight[0].decimals!) *
                  AssetsUtils.getMarketPrice(
                      widget.plugin, tokenPairRight[0].symbol ?? '');

              rightPrice = Fmt.bigIntToDouble(
                      poolInfoRight.amountRight, tokenPairRight[1].decimals!) *
                  AssetsUtils.getMarketPrice(
                      widget.plugin, tokenPairRight[1].symbol ?? '');
            }
            final rightLP =
                (leftPrice + rightPrice) * (shareTotal! / issuance!);
            return rightLP.compareTo(leftLP);
          });
        } else if (_sort == 'earn.dex.sort3') {
          datas.addAll(otherDatas);
          datas.sort((left, right) {
            final poolInfoLeft =
                widget.plugin.store!.earn.dexPoolInfoMap[left.tokenNameId];
            final poolInfoRight =
                widget.plugin.store!.earn.dexPoolInfoMap[right.tokenNameId];
            var rewardPriceLeft = 0.0;
            poolInfoLeft!.reward!.incentive.forEach((e) {
              double amount = double.parse(e['amount']);
              if (amount < 0) {
                amount = 0;
              }
              final rewardToken = AssetsUtils.getBalanceFromTokenNameId(
                  widget.plugin, e['tokenNameId']);
              rewardPriceLeft += AssetsUtils.getMarketPrice(
                      widget.plugin, rewardToken.symbol ?? '') *
                  amount;
            });

            var rewardPriceRight = 0.0;
            poolInfoRight!.reward!.incentive.forEach((e) {
              double amount = double.parse(e['amount']);
              if (amount < 0) {
                amount = 0;
              }
              final rewardToken = AssetsUtils.getBalanceFromTokenNameId(
                  widget.plugin, e['tokenNameId']);
              rewardPriceRight += AssetsUtils.getMarketPrice(
                      widget.plugin, rewardToken.symbol ?? '') *
                  amount;
            });
            return rewardPriceRight.compareTo(rewardPriceLeft);
          });
        }
        dexPools = datas;
      }
      if (_partake) {
        dexPools.retainWhere((element) =>
            (widget.plugin.store!.earn.dexPoolInfoMap[element.tokenNameId]!
                    .shares ??
                BigInt.zero) !=
            BigInt.zero);
      }
      return Column(children: [
        ConnectionChecker(widget.plugin, onConnected: _fetchData),
        Container(
            margin: EdgeInsets.only(left: 16, right: 16, bottom: 14, top: 5),
            padding: EdgeInsets.only(left: 8, top: 4, bottom: 5, right: 8),
            decoration: BoxDecoration(
                color: PluginColorsDark.cardColor,
                borderRadius: BorderRadius.all(Radius.circular(6))),
            child: Row(
              children: [
                Expanded(
                    child: TextField(
                  controller: _controller,
                  textInputAction: TextInputAction.search,
                  style: Theme.of(context)
                      .textTheme
                      .headline5
                      ?.copyWith(color: PluginColorsDark.headline1),
                  decoration: InputDecoration(
                      isDense: true,
                      hintText: dic!['earn.dex.searchPools'],
                      border: InputBorder.none,
                      hintStyle: Theme.of(context)
                          .textTheme
                          .headline5
                          ?.copyWith(
                              color: PluginColorsDark.headline1.withAlpha(127)),
                      contentPadding: EdgeInsets.zero),
                  onSubmitted: (value) {
                    setState(() {
                      _search = value;
                    });
                  },
                  onChanged: (value) {
                    setState(() {
                      _search = _controller.text;
                    });
                  },
                )),
                GestureDetector(
                  child: Icon(
                    Icons.search,
                    color: Color(0xFF979797),
                    size: 16,
                  ),
                  onTap: () {
                    setState(() {
                      _search = _controller.text;
                    });
                  },
                )
              ],
            )),
        Padding(
            padding: EdgeInsets.only(left: 16, right: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                GestureDetector(
                  child: Row(
                    children: [
                      Container(
                        margin: EdgeInsets.only(right: 12),
                        child: Text(
                          dic['earn.staked']!,
                          style: Theme.of(context)
                              .textTheme
                              .headline4
                              ?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: PluginColorsDark.headline1),
                        ),
                      ),
                      Container(
                          height: 20,
                          child: v3.CupertinoSwitch(
                            value: _partake,
                            isPlugin: true,
                            onChanged: (v) {
                              setState(() {
                                _partake = v;
                              });
                            },
                          )),
                    ],
                  ),
                  onTap: () {
                    setState(() {
                      _partake = !_partake;
                    });
                  },
                ),
                PluginIconButton(
                  icon: SvgPicture.asset(
                    'assets/images/icon_screening.svg',
                    color: PluginColorsDark.headline1,
                    width: 22,
                  ),
                  onPressed: () {
                    showCupertinoModalPopup(
                      context: context,
                      builder: (context) {
                        final sortType = [
                          dic['earn.dex.sort0'],
                          dic['earn.dex.sort1'],
                          dic['earn.dex.sort2'],
                          dic['earn.dex.sort3']
                        ];
                        return PolkawalletActionSheet(
                          actions: <Widget>[
                            ...sortType.map((element) {
                              final index = sortType.indexOf(element);
                              return PolkawalletActionSheetAction(
                                onPressed: () {
                                  if ('earn.dex.sort$index' != _sort) {
                                    setState(() {
                                      _sort = 'earn.dex.sort$index';
                                    });
                                  }
                                  Navigator.pop(context);
                                },
                                child: Text(
                                  element!,
                                  style: TextStyle(
                                      color: element == dic[_sort]
                                          ? Color(0xFFFE0000)
                                          : Color(0xFF007AFE)),
                                ),
                              );
                            }).toList()
                          ],
                        );
                      },
                    );
                  },
                )
              ],
            )),
        Expanded(
            child: dexPools.length == 0
                ? PluginPopLoadingContainer(loading: _loading)
                : GridView.builder(
                    padding: EdgeInsets.all(16),
                    itemCount: dexPools.length,
                    itemBuilder: (_, i) {
                      final tokenPair = dexPools[i]
                          .tokens!
                          .map((e) => AssetsUtils.tokenDataFromCurrencyId(
                              widget.plugin, e))
                          .toList();

                      final tokenSymbol =
                          tokenPair.map((e) => e.symbol).join('-');

                      final rewardsEmpty = incentivesV2.dex == null;

                      final poolInfo = widget.plugin.store!.earn
                          .dexPoolInfoMap[dexPools[i].tokenNameId];

                      bool canClaim = false;
                      (poolInfo?.reward?.incentive ?? []).forEach((e) {
                        final amount = double.parse(e['amount']);
                        if (amount > 0.0001) {
                          canClaim = true;
                        }
                      });

                      bool unstaked = false;
                      final balance = AssetsUtils.getBalanceFromTokenNameId(
                          widget.plugin, dexPools[i].tokenNameId);
                      if (Fmt.balanceInt(balance.amount) > BigInt.zero) {
                        unstaked = true;
                      }

                      final balancePair = dexPools[i]
                          .tokens!
                          .map((e) => AssetsUtils.tokenDataFromCurrencyId(
                              widget.plugin, e))
                          .toList();

                      BigInt? issuance = BigInt.zero;
                      BigInt? shareTotal = BigInt.zero;
                      double leftPrice = 0, rightPrice = 0;

                      if (poolInfo != null) {
                        issuance = poolInfo.issuance;
                        shareTotal = poolInfo.sharesTotal;

                        leftPrice = Fmt.bigIntToDouble(
                                poolInfo.amountLeft, balancePair[0].decimals!) *
                            AssetsUtils.getMarketPrice(
                                widget.plugin, balancePair[0].symbol ?? '');

                        rightPrice = Fmt.bigIntToDouble(poolInfo.amountRight,
                                balancePair[1].decimals!) *
                            AssetsUtils.getMarketPrice(
                                widget.plugin, balancePair[1].symbol ?? '');
                      }

                      return GestureDetector(
                        child: RoundedPluginCard(
                            borderRadius: const BorderRadius.all(
                                const Radius.circular(9)),
                            child: Column(
                              children: [
                                Container(
                                  width: double.infinity,
                                  alignment: Alignment.centerLeft,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.only(
                                        topLeft: Radius.circular(9),
                                        topRight: Radius.circular(9)),
                                  ),
                                  padding: EdgeInsets.only(
                                      left: 12, top: 7, right: 8, bottom: 9),
                                  child: Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      PluginTokenIcon(
                                        tokenSymbol,
                                        widget.plugin.tokenIcons,
                                        size: 24,
                                      ),
                                      Row(
                                        children: [
                                          Visibility(
                                              visible: unstaked,
                                              child: Padding(
                                                  padding:
                                                      EdgeInsets.only(left: 4),
                                                  child: Image.asset(
                                                    "packages/polkawallet_plugin_acala/assets/images/unstaked.png",
                                                    width: 22,
                                                  ))),
                                          Visibility(
                                              visible: (poolInfo?.shares ??
                                                      BigInt.zero) !=
                                                  BigInt.zero,
                                              child: Padding(
                                                  padding:
                                                      EdgeInsets.only(left: 4),
                                                  child: Image.asset(
                                                    "packages/polkawallet_plugin_acala/assets/images/staked_1.png",
                                                    width: 22,
                                                  ))),
                                          Visibility(
                                              visible: canClaim,
                                              child: Padding(
                                                  padding:
                                                      EdgeInsets.only(left: 4),
                                                  child: Image.asset(
                                                    "packages/polkawallet_plugin_acala/assets/images/rewards.png",
                                                    width: 22,
                                                  ))),
                                        ],
                                      )
                                    ],
                                  ),
                                ),
                                Expanded(
                                    child: Container(
                                  width: double.infinity,
                                  padding: EdgeInsets.only(
                                      left: 12, top: 6, right: 12),
                                  decoration: BoxDecoration(
                                      borderRadius: BorderRadius.only(
                                          bottomLeft: Radius.circular(9),
                                          bottomRight: Radius.circular(9)),
                                      color: Color(0xFF494b4e)),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        PluginFmt.tokenView(tokenSymbol),
                                        style: Theme.of(context)
                                            .textTheme
                                            .headline4
                                            ?.copyWith(
                                                color: Color(0xBDFFFFFF),
                                                fontWeight: FontWeight.w600),
                                      ),
                                      Padding(
                                          padding: EdgeInsets.only(top: 17),
                                          child: Text(
                                            dic['earn.apy']!,
                                            style: Theme.of(context)
                                                .textTheme
                                                .headline3
                                                ?.copyWith(
                                                    color: Colors.white,
                                                    fontWeight: FontWeight.bold,
                                                    height: 1.0,
                                                    fontSize: UI.getTextSize(
                                                        24, context)),
                                          )),
                                      Text(
                                        rewardsEmpty
                                            ? '--.--%'
                                            : Fmt.ratio(dexPools[i].rewards),
                                        style: Theme.of(context)
                                            .textTheme
                                            .headline3
                                            ?.copyWith(
                                                color: Colors.white,
                                                fontWeight: FontWeight.bold,
                                                height: 1.0,
                                                fontSize: UI.getTextSize(
                                                    24, context)),
                                      ),
                                      Text(
                                        '${dic['earn.staked']} \$${Fmt.priceCeil((leftPrice + rightPrice) * (shareTotal! / issuance!))}',
                                        style: Theme.of(context)
                                            .textTheme
                                            .headline5
                                            ?.copyWith(
                                                color: Color(0xBDFFFFFF)),
                                      ),
                                    ],
                                  ),
                                )),
                              ],
                            )),
                        onTap: () => Navigator.of(context).pushNamed(
                            EarnDetailPage.route,
                            arguments: {'poolId': dexPools[i].tokenNameId}),
                      );
                    },
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        mainAxisSpacing: 24,
                        crossAxisSpacing: 20,
                        childAspectRatio: 168 / 190.0),
                  ))
      ]);
    });
  }
}
