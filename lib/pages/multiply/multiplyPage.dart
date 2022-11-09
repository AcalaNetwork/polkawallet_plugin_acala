import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:polkawallet_plugin_acala/api/types/loanType.dart';
import 'package:polkawallet_plugin_acala/common/constants/index.dart';
import 'package:polkawallet_plugin_acala/pages/loanNew/loanTabBarWidget.dart';
import 'package:polkawallet_plugin_acala/pages/multiply/multiplyAdjustPanel.dart';
import 'package:polkawallet_plugin_acala/pages/multiply/multiplyCreatePage.dart';
import 'package:polkawallet_plugin_acala/pages/multiply/multiplyHistoryPage.dart';
import 'package:polkawallet_plugin_acala/pages/multiply/pieChartPainter.dart';
import 'package:polkawallet_plugin_acala/pages/types/loanPageParams.dart';
import 'package:polkawallet_plugin_acala/polkawallet_plugin_acala.dart';
import 'package:polkawallet_plugin_acala/utils/assets.dart';
import 'package:polkawallet_plugin_acala/utils/format.dart';
import 'package:polkawallet_plugin_acala/utils/i18n/index.dart';
import 'package:polkawallet_sdk/storage/keyring.dart';
import 'package:polkawallet_sdk/utils/i18n.dart';
import 'package:polkawallet_ui/components/connectionChecker.dart';
import 'package:polkawallet_ui/components/v3/infoItemRow.dart';
import 'package:polkawallet_ui/components/v3/plugin/pluginAccountInfoAction.dart';
import 'package:polkawallet_ui/components/v3/plugin/pluginButton.dart';
import 'package:polkawallet_ui/components/v3/plugin/pluginIconButton.dart';
import 'package:polkawallet_ui/components/v3/plugin/pluginPopLoadingWidget.dart';
import 'package:polkawallet_ui/components/v3/plugin/pluginScaffold.dart';
import 'package:polkawallet_ui/components/v3/plugin/pluginTokenIcon.dart';
import 'package:polkawallet_ui/utils/consts.dart';
import 'package:polkawallet_ui/utils/format.dart';
import 'package:polkawallet_ui/utils/index.dart';
import 'package:rive/rive.dart';

class MultiplyPage extends StatefulWidget {
  MultiplyPage(this.plugin, this.keyring, {Key? key}) : super(key: key);
  final PluginAcala plugin;
  final Keyring keyring;

  static const String route = '/acala/multiply';

  @override
  State<MultiplyPage> createState() => _MultiplyPageState();
}

class _MultiplyPageState extends State<MultiplyPage> {
  Map<String, PageController> _pageController = Map<String, PageController>();

  Future<void> _fetchData() async {
    widget.plugin.service!.earn.getDexIncentiveLoyaltyEndBlock();
    widget.plugin.service!.gov.updateBestNumber();
    await widget.plugin.service!.loan
        .queryLoanTypes(widget.keyring.current.address);

    widget.plugin.service!.assets.queryMarketPrices();

    widget.plugin.service!.loan
        .subscribeAccountLoans(widget.keyring.current.address);
  }

  @override
  void dispose() {
    super.dispose();
    widget.plugin.service!.loan.unsubscribeAccountLoans();
  }

  @override
  Widget build(BuildContext context) {
    final dicCommon = I18n.of(context)!.getDic(i18n_full_dic_acala, 'common');
    final dic = I18n.of(context)!.getDic(i18n_full_dic_acala, 'acala');
    final argsJson = ModalRoute.of(context)!.settings.arguments as Map? ?? {};
    final args = LoanPageParams.fromJson(argsJson);

    return Observer(builder: (_) {
      final loans = widget.plugin.store!.loan.loans.values.toList();
      loans.retainWhere((loan) =>
          loan.debits > BigInt.zero || loan.collaterals > BigInt.zero);
      final isDataLoading = widget.plugin.store!.loan.loansLoading &&
          (loans.length == 0 ||
              // do not show loan card if collateralRatio was not calculated.
              (loans.length > 0 && loans[0].collateralRatio <= 0));

      final List<LoanType> loanTypes = [], otherType = [];
      widget.plugin.store!.loan.loanTypes.forEach((element) {
        if (element.maximumTotalDebitValue != BigInt.zero) {
          if (loans.indexWhere((loan) =>
                  loan.token?.tokenNameId == element.token?.tokenNameId) >=
              0) {
            loanTypes.add(element);
          } else {
            otherType.add(element);
          }
        }
      });
      loanTypes.addAll(otherType);
      loanTypes.removeWhere((e) =>
          collateralFilterList.indexWhere((i) => e.token?.symbol == i) > -1);

      int initialLoanTypeIndex = 0;
      if (args.loanType != null) {
        initialLoanTypeIndex =
            loanTypes.indexWhere((e) => e.token?.tokenNameId == args.loanType);
      }

      return PluginScaffold(
          appBar: PluginAppBar(
            title: Text(dicCommon!['multiply.title']!),
            actions: [
              Container(
                margin: EdgeInsets.only(right: 12),
                child: PluginIconButton(
                  onPressed: () => Navigator.of(context)
                      .pushNamed(MultiplyHistoryPage.route),
                  icon: Image.asset(
                    'packages/polkawallet_plugin_acala/assets/images/history.png',
                    width: 16,
                  ),
                ),
              ),
              PluginAccountInfoAction(widget.keyring)
            ],
          ),
          body: isDataLoading
              ? PluginPopLoadingContainer(
                  loading: true,
                  child:
                      ConnectionChecker(widget.plugin, onConnected: _fetchData))
              : Container(
                  width: double.infinity,
                  height: double.infinity,
                  margin: EdgeInsets.only(top: 16),
                  child: SafeArea(
                      child: LoanTabBarWidget(
                    initialTab:
                        initialLoanTypeIndex > -1 ? initialLoanTypeIndex : 0,
                    data: loanTypes.map((e) {
                      final _loans = loans.where(
                          (data) => data.token!.symbol == e.token!.symbol);
                      LoanData? loan = _loans.length > 0 ? _loans.first : null;
                      Widget child = CreateVaultWidget(
                          e.token!.symbol!, widget.plugin, onPressed: () async {
                        final res = await Navigator.of(context).pushNamed(
                            MultiplyCreatePage.route,
                            arguments: e.token);
                        if (res != null) {
                          _fetchData();
                        }
                      });
                      if (loan != null) {
                        if (_pageController[loan.token!.symbol] == null) {
                          _pageController[loan.token!.symbol!] =
                              PageController();
                        }
                        child = PageView(
                          scrollDirection: Axis.vertical,
                          controller: _pageController[loan.token!.symbol!],
                          children: [
                            Column(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                LoanView(
                                    loan,
                                    widget.plugin.store!.assets
                                            .prices[loan.token!.tokenNameId] ??
                                        BigInt.zero,
                                    widget.plugin),
                                GestureDetector(
                                    onTap: () {
                                      _pageController[loan.token!.symbol!]!
                                          .animateToPage(
                                        1,
                                        duration: Duration(milliseconds: 400),
                                        curve: Curves.ease,
                                      );
                                    },
                                    child: Padding(
                                        padding: EdgeInsets.only(bottom: 22),
                                        child: Row(
                                          children: [
                                            Text(
                                              dic![
                                                  'loan.multiply.adjustMultiple']!,
                                              style: Theme.of(context)
                                                  .textTheme
                                                  .headline3
                                                  ?.copyWith(
                                                      fontSize: UI.getTextSize(
                                                          18, context),
                                                      color: PluginColorsDark
                                                          .headline1),
                                            ),
                                            Padding(
                                              padding: EdgeInsets.only(left: 5),
                                              child: Image.asset(
                                                "packages/polkawallet_plugin_acala/assets/images/adjust_multiple.png",
                                                width: 10,
                                              ),
                                            )
                                          ],
                                        )))
                              ],
                            ),
                            MultiplyAdjustPanel(
                                widget.plugin, widget.keyring, e, () {
                              _fetchData();
                            }),
                          ],
                        );
                      }
                      return LoanTabBarWidgetData(
                        PluginTokenIcon(
                          e.token!.symbol!,
                          widget.plugin.tokenIcons,
                          size: 34,
                        ),
                        child,
                      );
                    }).toList(),
                  ))));
    });
  }
}

class LoanView extends StatelessWidget {
  LoanView(this._loan, this._prices, this.plugin, {Key? key}) : super(key: key);
  LoanData _loan;
  BigInt _prices;
  final PluginAcala plugin;

  @override
  Widget build(BuildContext context) {
    final dic = I18n.of(context)!.getDic(i18n_full_dic_acala, 'acala');
    final sumInUSD = _loan.collateralInUSD + _loan.debitInUSD;
    final balancePair = AssetsUtils.getBalancePairFromTokenNameId(
        plugin, [_loan.token!.tokenNameId, acala_stable_coin]);
    final loanType = plugin.store!.loan.loanTypes
        .firstWhere((i) => i.token!.tokenNameId == _loan.token!.tokenNameId);
    return Column(
      children: [
        Container(
          width: double.infinity,
          height: 244,
          padding: EdgeInsets.only(left: 20, top: 12, right: 20, bottom: 15),
          margin: EdgeInsets.only(bottom: 31),
          decoration: BoxDecoration(
              color: Color(0x1AFFFFFF),
              borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(8),
                  topRight: Radius.circular(8),
                  bottomRight: Radius.circular(8))),
          child: Column(
            children: [
              Stack(
                children: [
                  Align(
                    alignment: Alignment.center,
                    child: Container(
                      width: 150,
                      height: 150,
                      child: CustomPaint(
                        painter: pieChartPainter(
                            _loan.collateralInUSD / sumInUSD,
                            _loan.debitInUSD / sumInUSD),
                      ),
                    ),
                  ),
                  Visibility(
                      visible: _loan.debits != BigInt.zero &&
                          _loan.collateralRatio <
                              Fmt.bigIntToDouble(
                                      _loan.type.liquidationRatio, 18) +
                                  0.05,
                      child: Align(
                          alignment: Alignment.topRight,
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 12,
                                height: 12,
                                decoration: BoxDecoration(
                                  color: Colors.transparent,
                                  borderRadius:
                                      BorderRadius.all(Radius.circular(6.0)),
                                  border: Border.all(
                                      width: 2,
                                      color: PluginColorsDark.primary),
                                ),
                              ),
                              Padding(
                                  padding: EdgeInsets.only(left: 5),
                                  child: Text(
                                    dic!['loan.multiply.highRisk']!,
                                    style: Theme.of(context)
                                        .textTheme
                                        .headline5
                                        ?.copyWith(
                                            fontSize:
                                                UI.getTextSize(12, context),
                                            color: PluginColorsDark.headline1),
                                  ))
                            ],
                          )))
                ],
              ),
              Padding(
                  padding: EdgeInsets.only(top: 4),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.all(Radius.circular(6.0)),
                        ),
                      ),
                      Padding(
                          padding: EdgeInsets.only(left: 5),
                          child: Text(
                            "${dic['loan.multiply.debt']} ${Fmt.priceFloorBigIntFormatter(_loan.debits, balancePair[1].decimals!)} $acala_stable_coin_view",
                            style: Theme.of(context)
                                .textTheme
                                .headline5
                                ?.copyWith(
                                    fontSize: UI.getTextSize(12, context),
                                    color: PluginColorsDark.headline1),
                          ))
                    ],
                  )),
              Padding(
                  padding: EdgeInsets.only(top: 18),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                          color: Colors.white.withAlpha(76),
                          borderRadius: BorderRadius.all(Radius.circular(6.0)),
                        ),
                      ),
                      Padding(
                          padding: EdgeInsets.only(left: 5),
                          child: Text(
                            "${dic['loan.collateral']} ${Fmt.priceFloorBigIntFormatter(_loan.collaterals, _loan.token!.decimals!)} ${PluginFmt.tokenView(_loan.token!.symbol)} (≈\$${Fmt.priceFloorFormatter(Fmt.bigIntToDouble(_loan.collaterals, _loan.token!.decimals!) * Fmt.bigIntToDouble(_prices, acala_price_decimals))})",
                            style: Theme.of(context)
                                .textTheme
                                .headline5
                                ?.copyWith(
                                    fontSize: UI.getTextSize(12, context),
                                    color: PluginColorsDark.headline1),
                          ))
                    ],
                  )),
            ],
          ),
        ),
        Row(
          children: [
            Expanded(
                child: Column(
              children: [
                Container(
                  padding: EdgeInsets.fromLTRB(8, 5, 8, 2),
                  width: double.infinity,
                  decoration: BoxDecoration(
                      color: Color(0x1AFFFFFF),
                      borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(8),
                          topRight: Radius.circular(8))),
                  child: Text(
                    dic['loan.multiply.totalExposure']!,
                    style: Theme.of(context).textTheme.headline5?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: PluginColorsDark.headline1),
                  ),
                ),
                Container(
                  padding: EdgeInsets.fromLTRB(8, 0, 8, 0),
                  height: 76,
                  width: double.infinity,
                  decoration: BoxDecoration(
                      color: Color(0x2BFFFFFF),
                      borderRadius: const BorderRadius.only(
                          bottomLeft: Radius.circular(8),
                          bottomRight: Radius.circular(8))),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            "${Fmt.priceFloorBigIntFormatter(_loan.collaterals, _loan.token!.decimals!)} ${PluginFmt.tokenView(_loan.token!.symbol)}",
                            style: Theme.of(context)
                                .textTheme
                                .headline3
                                ?.copyWith(color: PluginColorsDark.headline1),
                          ),
                          Text(
                            "≈\$${Fmt.priceFloorFormatter(Fmt.bigIntToDouble(_loan.collaterals, _loan.token!.decimals!) * Fmt.bigIntToDouble(_prices, acala_price_decimals))}",
                            style: Theme.of(context)
                                .textTheme
                                .headline5
                                ?.copyWith(color: PluginColorsDark.headline1),
                          )
                        ],
                      )
                    ],
                  ),
                )
              ],
            )),
            Container(width: 22),
            Expanded(
                child: Column(
              children: [
                Container(
                  padding: EdgeInsets.fromLTRB(8, 5, 8, 2),
                  width: double.infinity,
                  decoration: BoxDecoration(
                      color: Color(0x1AFFFFFF),
                      borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(8),
                          topRight: Radius.circular(8))),
                  child: Text(
                    "${dic['loan.liquidate']} (${PluginFmt.tokenView(_loan.token!.symbol)})",
                    style: Theme.of(context).textTheme.headline5?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: PluginColorsDark.headline1),
                  ),
                ),
                Container(
                  padding: EdgeInsets.fromLTRB(8, 0, 0, 11),
                  width: double.infinity,
                  height: 76,
                  decoration: BoxDecoration(
                      color: Color(0x2BFFFFFF),
                      borderRadius: const BorderRadius.only(
                          bottomLeft: Radius.circular(8),
                          bottomRight: Radius.circular(8))),
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              "\$${Fmt.priceFloorBigIntFormatter(_prices, acala_price_decimals)}",
                              style: Theme.of(context)
                                  .textTheme
                                  .headline3
                                  ?.copyWith(color: PluginColorsDark.green),
                            ),
                            Text(
                              "/\$${Fmt.priceFloorBigInt(_loan.liquidationPrice, acala_price_decimals)}",
                              style: Theme.of(context)
                                  .textTheme
                                  .headline3
                                  ?.copyWith(color: PluginColorsDark.headline1),
                            )
                          ],
                        )
                      ]),
                )
              ],
            ))
          ],
        ),
        Container(height: 20),
        Row(
          children: [
            Expanded(
                child: Column(
              children: [
                Container(
                  padding: EdgeInsets.fromLTRB(8, 5, 8, 2),
                  width: double.infinity,
                  decoration: BoxDecoration(
                      color: Color(0x1AFFFFFF),
                      borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(8),
                          topRight: Radius.circular(8))),
                  child: Text(
                    dic['collateral.interest']!,
                    style: Theme.of(context).textTheme.headline5?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: PluginColorsDark.headline1),
                  ),
                ),
                Container(
                  padding: EdgeInsets.fromLTRB(8, 0, 8, 0),
                  height: 76,
                  width: double.infinity,
                  decoration: BoxDecoration(
                      color: Color(0x2BFFFFFF),
                      borderRadius: const BorderRadius.only(
                          bottomLeft: Radius.circular(8),
                          bottomRight: Radius.circular(8))),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        "${Fmt.ratio(loanType.stableFeeYear)}",
                        style: Theme.of(context)
                            .textTheme
                            .headline3
                            ?.copyWith(color: PluginColorsDark.headline1),
                      ),
                    ],
                  ),
                )
              ],
            )),
            Container(width: 22),
            Expanded(
                child: Column(
              children: [
                Container(
                  padding: EdgeInsets.fromLTRB(8, 5, 8, 2),
                  width: double.infinity,
                  decoration: BoxDecoration(
                      color: Color(0x1AFFFFFF),
                      borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(8),
                          topRight: Radius.circular(8))),
                  child: Text(
                    dic['loan.ratio']!,
                    style: Theme.of(context).textTheme.headline5?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: PluginColorsDark.headline1),
                  ),
                ),
                Container(
                  padding: EdgeInsets.fromLTRB(8, 0, 0, 11),
                  width: double.infinity,
                  height: 76,
                  decoration: BoxDecoration(
                      color: Color(0x2BFFFFFF),
                      borderRadius: const BorderRadius.only(
                          bottomLeft: Radius.circular(8),
                          bottomRight: Radius.circular(8))),
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          "${Fmt.ratio(_loan.collateralRatio)}",
                          style: Theme.of(context)
                              .textTheme
                              .headline3
                              ?.copyWith(color: PluginColorsDark.headline1),
                        ),
                      ]),
                )
              ],
            ))
          ],
        )
      ],
    );
  }
}

class CreateVaultWidget extends StatelessWidget {
  const CreateVaultWidget(this.symbol, this.plugin, {this.onPressed, Key? key})
      : super(key: key);
  final String symbol;
  final Function()? onPressed;
  final PluginAcala plugin;

  @override
  Widget build(BuildContext context) {
    final dicCommon = I18n.of(context)!.getDic(i18n_full_dic_acala, 'common');
    final dic = I18n.of(context)!.getDic(i18n_full_dic_acala, 'acala')!;
    final loanType = plugin.store!.loan.loanTypes
        .firstWhere((i) => i.token!.symbol == symbol);
    final ratioRight = Fmt.bigIntToDouble(loanType.liquidationRatio, 18) * 100;

    final maxMultiple = ratioRight / (ratioRight - 100);
    final _amountCollateral = 100.0;
    final buyingCollateral = _amountCollateral * (maxMultiple - 1);

    final style = Theme.of(context)
        .textTheme
        .headline5
        ?.copyWith(color: PluginColorsDark.headline1);
    return Container(
      width: double.infinity,
      height: double.infinity,
      child: Stack(alignment: AlignmentDirectional.topCenter, children: [
        Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(children: [
              Container(
                  margin: EdgeInsets.only(top: 17, bottom: 12),
                  width: 120,
                  height: 120,
                  child: Stack(
                    children: [
                      RiveAnimation.asset(
                          'packages/polkawallet_plugin_acala/assets/images/cdp_multiply.riv'),
                      Container(
                        width: double.infinity,
                        height: double.infinity,
                        margin: EdgeInsets.all(10),
                        child: FittedBox(
                            fit: BoxFit.fill,
                            child: plugin.tokenIcons[symbol.toUpperCase()]),
                      )
                    ],
                  )),
              Text(
                "Vault ${PluginFmt.tokenView(symbol)}",
                style: Theme.of(context).textTheme.headline1?.copyWith(
                    fontSize: UI.getTextSize(26, context),
                    fontWeight: FontWeight.bold,
                    color: Color(0xFFFF6D37),
                    height: 1.1),
              ),
              Padding(
                padding: EdgeInsets.only(bottom: 16),
                child: Text(
                  I18n.of(context)!.locale.toString().contains('zh')
                      ? "最高倍率化 ${PluginFmt.tokenView(symbol)} 的选择"
                      : "Highest ${PluginFmt.tokenView(symbol)} multiple option",
                  style: Theme.of(context)
                      .textTheme
                      .headline5
                      ?.copyWith(color: Colors.white, height: 1.1),
                ),
              ),
              Container(
                padding: EdgeInsets.symmetric(vertical: 29),
                width: double.infinity,
                decoration: BoxDecoration(
                    color: Colors.white.withAlpha(20),
                    borderRadius: BorderRadius.all(Radius.circular(8))),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      "${dic['loan.multiply.with']} ${Fmt.priceFloor(_amountCollateral)} ${PluginFmt.tokenView(symbol)}",
                      style: Theme.of(context).textTheme.headline3?.copyWith(
                          color: PluginColorsDark.headline1,
                          fontSize: UI.getTextSize(18, context),
                          fontWeight: FontWeight.w300),
                    ),
                    Padding(
                        padding: EdgeInsets.only(top: 6),
                        child: Text(
                          "${dic['loan.multiply.message1']} ${Fmt.priceFloor(_amountCollateral + buyingCollateral)} ${PluginFmt.tokenView(symbol)} ${dic['loan.multiply.message2']}",
                          style: Theme.of(context)
                              .textTheme
                              .headline3
                              ?.copyWith(
                                  color: PluginColorsDark.headline1,
                                  fontSize: UI.getTextSize(18, context),
                                  fontWeight: FontWeight.w600),
                        )),
                  ],
                ),
              ),
              Padding(
                  padding: EdgeInsets.only(top: 24),
                  child: InfoItemRow(
                    dic['loan.multiply.maxMultiple']!,
                    maxMultiple.toStringAsFixed(2) + 'x',
                    labelStyle: style,
                    contentStyle: style,
                  )),
              InfoItemRow(
                dic['liquid.ratio']!,
                "${Fmt.ratio(Fmt.bigIntToDouble(loanType.liquidationRatio, 18))}",
                labelStyle: style,
                contentStyle: style,
              ),
              InfoItemRow(
                dic['loan.multiply.variableAnnualFee']!,
                "${Fmt.ratio(loanType.stableFeeYear)}",
                labelStyle: style,
                contentStyle: style,
              ),
            ]),
            Container(
                margin: EdgeInsets.only(bottom: 38),
                child: PluginButton(
                  title: dicCommon!['multiply.title']!,
                  onPressed: onPressed,
                ))
          ],
        ),
        Container(
          margin: EdgeInsets.only(left: 150),
          padding: EdgeInsets.symmetric(horizontal: 6, vertical: 4),
          decoration: BoxDecoration(
            color: Color(0xFF3F4042),
            borderRadius: BorderRadius.all(Radius.circular(4)),
          ),
          child: Text(
            I18n.of(context)!.locale.toString().contains('zh')
                ? "最大化 ${PluginFmt.tokenView(symbol)} 敞口"
                : "Max ${PluginFmt.tokenView(symbol)} exposure",
            style: Theme.of(context).textTheme.headline5?.copyWith(
                fontSize: UI.getTextSize(12, context),
                color: PluginColorsDark.headline1,
                fontWeight: FontWeight.w600),
          ),
        )
      ]),
    );
  }
}
