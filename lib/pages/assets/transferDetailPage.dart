import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:polkawallet_plugin_acala/api/history/types/historyData.dart';
import 'package:polkawallet_plugin_acala/polkawallet_plugin_acala.dart';
import 'package:polkawallet_plugin_acala/utils/assets.dart';
import 'package:polkawallet_plugin_acala/utils/format.dart';
import 'package:polkawallet_plugin_acala/utils/i18n/index.dart';
import 'package:polkawallet_sdk/storage/keyring.dart';
import 'package:polkawallet_sdk/utils/i18n.dart';
import 'package:polkawallet_ui/components/v3/txDetail.dart';
import 'package:polkawallet_ui/utils/format.dart';

class TransferDetailPage extends StatelessWidget {
  TransferDetailPage(this.plugin, this.keyring);
  final PluginAcala plugin;
  final Keyring keyring;

  static final String route = '/assets/token/tx/detail';

  @override
  Widget build(BuildContext context) {
    final Map<String, String> dic =
        I18n.of(context)!.getDic(i18n_full_dic_acala, 'common')!;

    final HistoryData tx =
        ModalRoute.of(context)!.settings.arguments as HistoryData;

    final String? txType = tx.data?['from'] == keyring.current.address
        ? dic['transfer']
        : dic['receive'];

    String? networkName = plugin.basic.name;
    if (plugin.basic.isTestNet) {
      networkName = '${networkName!.split('-')[0]}-testnet';
    }
    final rewardToken = AssetsUtils.tokenDataFromCurrencyId(
        plugin, {'token': tx.data!['token']});
    final balance =
        AssetsUtils.getBalanceFromTokenNameId(plugin, tx.data!['token']);
    return TxDetail(
      current: keyring.current,
      success: true,
      action: txType,
      // blockNum: int.parse(tx.block),
      hash: tx.hash,
      blockTime: Fmt.dateTime(
          DateFormat("yyyy-MM-ddTHH:mm:ss").parse(tx.data!['timestamp'], true)),
      networkName: networkName,
      infoItems: <TxDetailInfoItem>[
        TxDetailInfoItem(
          label: dic['amount'],
          content: Text(
            '${tx.data!['from'] == keyring.current.address ? '-' : '+'}${Fmt.balance(tx.data!['amount'], rewardToken.decimals ?? 12, length: 6)} ${PluginFmt.tokenView(balance.symbol ?? "")}',
            style: Theme.of(context).textTheme.headline1,
          ),
        ),
        TxDetailInfoItem(
          label: 'From',
          content: Text(Fmt.address(tx.data!['from'])),
          copyText: tx.data!['from'],
        ),
        TxDetailInfoItem(
          label: 'To',
          content: Text(Fmt.address(tx.data!['to'])),
          copyText: tx.data!['to'],
        )
      ],
    );
  }
}
