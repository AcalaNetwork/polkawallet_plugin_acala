import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:polkawallet_plugin_acala/api/types/txIncentiveData.dart';
import 'package:polkawallet_plugin_acala/common/constants/base.dart';
import 'package:polkawallet_plugin_acala/polkawallet_plugin_acala.dart';
import 'package:polkawallet_plugin_acala/utils/i18n/index.dart';
import 'package:polkawallet_sdk/storage/keyring.dart';
import 'package:polkawallet_sdk/utils/i18n.dart';
import 'package:polkawallet_ui/components/txDetail.dart';
import 'package:polkawallet_ui/utils/format.dart';

class EarnTxDetailPage extends StatelessWidget {
  EarnTxDetailPage(this.plugin, this.keyring);
  final PluginAcala plugin;
  final Keyring keyring;

  static final String route = '/acala/earn/incentive/tx';

  @override
  Widget build(BuildContext context) {
    final isKar = plugin.basic.name == plugin_name_karura;
    final dic = I18n.of(context).getDic(i18n_full_dic_acala, 'acala');
    final amountStyle = TextStyle(fontSize: 16, fontWeight: FontWeight.bold);

    final TxDexIncentiveData tx = ModalRoute.of(context).settings.arguments;

    String networkName = plugin.basic.name;
    if (plugin.basic.isTestNet) {
      networkName = '${networkName.split('-')[0]}-testnet';
    }
    return TxDetail(
      success: tx.isSuccess,
      action: tx.event,
      blockNum: int.parse(tx.block),
      hash: tx.hash,
      blockTime:
          Fmt.dateTime(DateFormat("yyyy-MM-ddTHH:mm:ss").parse(tx.time, true)),
      networkName: networkName,
      infoItems: [
        TxDetailInfoItem(
          label: 'Event',
          content: Text(tx.event, style: amountStyle),
        ),
        TxDetailInfoItem(
          label: dic['earn.stake.pool'],
          content: Text(tx.poolId, style: amountStyle),
        ),
        TxDetailInfoItem(
          label:
              I18n.of(context).getDic(i18n_full_dic_acala, 'common')['amount'],
          content: Text(tx.amountShare, style: amountStyle),
        )
      ],
    );
  }
}
