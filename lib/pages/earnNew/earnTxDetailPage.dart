import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:polkawallet_plugin_acala/api/types/txIncentiveData.dart';
import 'package:polkawallet_plugin_acala/polkawallet_plugin_acala.dart';
import 'package:polkawallet_plugin_acala/utils/i18n/index.dart';
import 'package:polkawallet_sdk/storage/keyring.dart';
import 'package:polkawallet_sdk/utils/i18n.dart';
import 'package:polkawallet_ui/components/v3/plugin/pluginTxDetail.dart';
import 'package:polkawallet_ui/utils/consts.dart';
import 'package:polkawallet_ui/utils/format.dart';
import 'package:polkawallet_ui/utils/index.dart';

class EarnTxDetailPage extends StatelessWidget {
  EarnTxDetailPage(this.plugin, this.keyring);
  final PluginAcala plugin;
  final Keyring keyring;

  static final String route = '/acala/earn/incentive/tx';

  @override
  Widget build(BuildContext context) {
    final dic = I18n.of(context)!.getDic(i18n_full_dic_acala, 'acala')!;
    final amountStyle = TextStyle(
        fontSize: UI.getTextSize(16, context),
        fontWeight: FontWeight.bold,
        color: PluginColorsDark.headline1);

    final TxDexIncentiveData tx =
        ModalRoute.of(context)!.settings.arguments as TxDexIncentiveData;

    String? networkName = plugin.basic.name;
    if (plugin.basic.isTestNet) {
      networkName = '${networkName!.split('-')[0]}-testnet';
    }
    return PluginTxDetail(
      current: keyring.current,
      success: tx.isSuccess,
      action: dic[earn_actions_map[tx.event]] ?? "",
      // blockNum: int.parse(tx.block),
      hash: tx.hash,
      resolveLinks: tx.resolveLinks,
      blockTime:
          Fmt.dateTime(DateFormat("yyyy-MM-ddTHH:mm:ss").parse(tx.time, true)),
      networkName: networkName,
      infoItems: [
        TxDetailInfoItem(
          label: 'Event',
          content: Text(tx.event?.replaceAll('incentives.', '') ?? "",
              style: amountStyle),
        ),
        TxDetailInfoItem(
          label: dic['txs.action'],
          content:
              Text(dic[earn_actions_map[tx.event]] ?? "", style: amountStyle),
        ),
      ],
    );
  }
}
