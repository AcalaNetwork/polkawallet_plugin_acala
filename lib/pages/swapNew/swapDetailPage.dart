import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:polkawallet_plugin_acala/api/types/txSwapData.dart';
import 'package:polkawallet_plugin_acala/polkawallet_plugin_acala.dart';
import 'package:polkawallet_plugin_acala/utils/format.dart';
import 'package:polkawallet_plugin_acala/utils/i18n/index.dart';
import 'package:polkawallet_sdk/storage/keyring.dart';
import 'package:polkawallet_sdk/utils/i18n.dart';
import 'package:polkawallet_ui/components/v3/plugin/pluginTxDetail.dart';
import 'package:polkawallet_ui/utils/consts.dart';
import 'package:polkawallet_ui/utils/format.dart';
import 'package:polkawallet_ui/utils/index.dart';

class SwapDetailPage extends StatelessWidget {
  SwapDetailPage(this.plugin, this.keyring);
  final PluginAcala plugin;
  final Keyring keyring;

  static final String route = '/acala/swap/tx';

  @override
  Widget build(BuildContext context) {
    final Map<String, String> dic =
        I18n.of(context)!.getDic(i18n_full_dic_acala, 'acala')!;

    final TxSwapData tx =
        ModalRoute.of(context)!.settings.arguments as TxSwapData;
    final token0 = PluginFmt.tokenView(tx.tokenPay);
    final token1 = PluginFmt.tokenView(tx.tokenReceive);
    final tokenLP = '$token0-$token1 LP';

    final amountStyle = TextStyle(
        fontSize: UI.getTextSize(16, context),
        fontWeight: FontWeight.bold,
        color: PluginColorsDark.headline1);

    String? networkName = plugin.basic.name;
    if (plugin.basic.isTestNet) {
      networkName = '${networkName!.split('-')[0]}-testnet';
    }
    String action = tx.action ?? "";
    String event = tx.action ?? "";
    switch (tx.action) {
      //taiga
      case "Mint":
        action = "AddLiquidity";
        event = "Mint";
        break;
      case "ProportionRedeem":
        event = "ProportionRedeem";
        action = "RemoveLiquidity";
        break;
      case "SingleRedeem":
        event = "SingleRedeem";
        action = "RemoveLiquidity";
        break;
      case "MultiRedeem":
        event = "MultiRedeem";
        action = "RemoveLiquidity";
        break;
    }
    final List<TxDetailInfoItem> items = [
      TxDetailInfoItem(
        label: 'Event',
        content: Text(event,
            style: tx.isSuccess == null
                ? TextStyle(
                    fontFamily: UI.getFontFamily('TitilliumWeb', context),
                    fontSize: UI.getTextSize(30, context),
                    fontWeight: FontWeight.w600,
                    color: PluginColorsDark.headline1)
                : amountStyle),
      ),
      TxDetailInfoItem(
        label: dic['txs.action'],
        content: Text(dic['dex.$action']!, style: amountStyle),
      )
    ];
    switch (tx.action) {
      case "Swap":
        items.addAll([
          TxDetailInfoItem(
            label: dic['dex.pay'],
            content: Text('${tx.amountPay} $token0', style: amountStyle),
          ),
          TxDetailInfoItem(
            label: dic['dex.receive'],
            content: Text('${tx.amountReceive} $token1', style: amountStyle),
          )
        ]);
        break;
      case "AddProvision":
        items.add(TxDetailInfoItem(
            label: dic['dex.pay'],
            content: Text(
              '${tx.amountPay} $token0\n'
              '+ ${tx.amountReceive} $token1',
              style: amountStyle,
              textAlign: TextAlign.right,
            )));
        break;
      case "AddLiquidity":
        items.addAll([
          TxDetailInfoItem(
            label: dic['dex.pay'],
            content: Text(
                '${tx.amountPay} $token0\n'
                '+ ${tx.amountReceive} $token1',
                textAlign: TextAlign.right,
                style: amountStyle),
          ),
          TxDetailInfoItem(
            label: dic['dex.receive'],
            content: Text('${tx.amountShare} $tokenLP', style: amountStyle),
          )
        ]);
        break;
      case "RemoveLiquidity":
        items.addAll([
          TxDetailInfoItem(
            label: dic['dex.pay'],
            content: Text('${tx.amountShare} $tokenLP', style: amountStyle),
          ),
          TxDetailInfoItem(
            label: dic['dex.receive'],
            content: Text(
                '${tx.amountPay} $token0\n'
                '+ ${tx.amountReceive} $token1',
                textAlign: TextAlign.right,
                style: amountStyle),
          )
        ]);
        break;
      //taiga
      case "Mint":
        items.addAll([
          TxDetailInfoItem(
            label: dic['dex.pay'],
            content: Text(tx.amounts.map((e) => e.toTokenString()).join("\n+"),
                textAlign: TextAlign.right, style: amountStyle),
          ),
        ]);
        break;
      case "ProportionRedeem":
      case "SingleRedeem":
      case "MultiRedeem":
        items.addAll([
          TxDetailInfoItem(
            label: dic['dex.pay'],
            content: Text('${tx.amountPay} ${tx.tokenPay}', style: amountStyle),
          ),
        ]);
        break;
    }

    return PluginTxDetail(
      success: tx.isSuccess,
      action: dic['dex.${tx.action}'],
      // blockNum: int.parse(tx.block),
      hash: tx.hash,
      blockTime:
          Fmt.dateTime(DateFormat("yyyy-MM-ddTHH:mm:ss").parse(tx.time, true)),
      networkName: networkName,
      infoItems: items,
      current: keyring.current,
    );
  }
}
