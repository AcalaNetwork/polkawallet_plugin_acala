import 'package:flutter/material.dart';
import 'package:polkawallet_plugin_acala/pages/earnNew/earnRebondPage.dart';
import 'package:polkawallet_plugin_acala/polkawallet_plugin_acala.dart';
import 'package:polkawallet_plugin_acala/utils/i18n/index.dart';
import 'package:polkawallet_sdk/storage/keyring.dart';
import 'package:polkawallet_sdk/utils/i18n.dart';
import 'package:polkawallet_ui/components/txButton.dart';
import 'package:polkawallet_ui/components/v3/plugin/pluginOutlinedButtonSmall.dart';
import 'package:polkawallet_ui/components/v3/plugin/pluginScaffold.dart';
import 'package:polkawallet_ui/components/v3/plugin/roundedPluginCard.dart';
import 'package:polkawallet_ui/pages/v3/txConfirmPage.dart';
import 'package:polkawallet_ui/utils/format.dart';
import 'package:polkawallet_ui/utils/index.dart';

class EarningUnbondPage extends StatefulWidget {
  EarningUnbondPage(this.plugin, this.keyring);
  final PluginAcala plugin;
  final Keyring keyring;

  static const String route = '/karura/earn/unbond';

  @override
  State<EarningUnbondPage> createState() => _EarningUnbondPageState();
}

class _EarningUnbondPageState extends State<EarningUnbondPage> {
  Future<void> _doWithdraw(BigInt amount) async {
    final dic = I18n.of(context)!.getDic(i18n_full_dic_acala, 'acala')!;

    final params = TxConfirmParams(
      module: 'earn',
      call: 'withdrawUnbonded',
      txTitle: dic['earn.unbond.withdraw'],
      txDisplay: {
        dic['loan.amount']:
            '≈ ${Fmt.priceFloorBigInt(amount, 12, lengthMax: 4)} ACA',
      },
      params: [],
      isPlugin: true,
    );
    final res = await Navigator.of(context)
        .pushNamed(TxConfirmPage.route, arguments: params);
    if (res != null) {
      Navigator.of(context).pop(res);
    }
  }

  @override
  Widget build(BuildContext context) {
    final dic = I18n.of(context)!.getDic(i18n_full_dic_acala, 'acala')!;

    final bestNumber = widget.plugin.store!.gov.bestNumber;
    final args =
        ModalRoute.of(context)?.settings.arguments as List<List<BigInt>>;
    BigInt queued = BigInt.zero;
    BigInt ended = BigInt.zero;
    args.forEach((e) {
      if (e[1] > bestNumber) {
        queued += e[0];
      } else {
        ended += e[0];
      }
    });

    final titleStyle =
        Theme.of(context).textTheme.headline5?.copyWith(color: Colors.white70);
    final contentStyle =
        Theme.of(context).textTheme.headline5?.copyWith(color: Colors.white);
    return PluginScaffold(
        appBar: PluginAppBar(
          title: Text(dic['earn.unbond.title']!),
        ),
        body: Column(
          children: [
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
                    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 11),
                    child: Text(dic['earn.unbond.queue']!,
                        style: Theme.of(context).textTheme.headline3?.copyWith(
                            fontSize: UI.getTextSize(18, context),
                            color: Colors.white)),
                  ),
                  Container(
                    padding: EdgeInsets.all(16),
                    color: Color(0xFF494b4e),
                    child: Column(
                      children: [
                        ...args.map((e) {
                          return Row(
                            children: [
                              Expanded(
                                  child: Text(
                                      e[1] - bestNumber > BigInt.zero
                                          ? Fmt.blockToTime(
                                              (e[1] - bestNumber).toInt(),
                                              widget.plugin.store!.earn
                                                  .blockDuration)
                                          : dic['earn.unbond.ready']!,
                                      style: titleStyle)),
                              Text(Fmt.priceFloorBigInt(e[0], 12) + ' ACA',
                                  style: contentStyle)
                            ],
                          );
                        }),
                        Divider(thickness: 0.5),
                        Row(
                          children: [
                            Expanded(
                                child: Text(dic['earn.unbond.total']!,
                                    style: titleStyle)),
                            Text(Fmt.priceFloorBigInt(queued, 12) + ' ACA',
                                style: contentStyle)
                          ],
                        ),
                        Row(
                          children: [
                            Expanded(
                                child: Text(dic['earn.unbond.total.withdraw']!,
                                    style: titleStyle)),
                            Text(Fmt.priceFloorBigInt(ended, 12) + ' ACA',
                                style: contentStyle)
                          ],
                        )
                      ],
                    ),
                  ),
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
                              content: dic['earn.unbond.withdraw'],
                              color: Color(0xFFFF7849),
                              active: true,
                              padding: EdgeInsets.only(top: 8, bottom: 8),
                              margin: EdgeInsets.zero,
                              onPressed: ended > BigInt.zero
                                  ? () => _doWithdraw(ended)
                                  : null,
                            ),
                          ),
                          Container(width: 15),
                          Expanded(
                            child: PluginOutlinedButtonSmall(
                              content: dic['earn.unbond.restake'],
                              color: Color(0xFFFF7849),
                              active: true,
                              padding: EdgeInsets.only(top: 8, bottom: 8),
                              margin: EdgeInsets.zero,
                              onPressed: () async {
                                final res = await Navigator.of(context)
                                    .pushNamed(EarningRebondPage.route,
                                        arguments: args);
                                if (res != null) {
                                  Navigator.of(context).pop(res);
                                }
                              },
                            ),
                          ),
                        ],
                      ))
                ],
              ),
            )
          ],
        ));
  }
}
