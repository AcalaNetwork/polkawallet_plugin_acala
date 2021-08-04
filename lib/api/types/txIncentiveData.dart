import 'dart:convert';

import 'package:polkawallet_plugin_acala/utils/format.dart';
import 'package:polkawallet_ui/utils/format.dart';

class TxDexIncentiveData extends _TxDexIncentiveData {
  static const String actionStake = 'DepositDexShare';
  static const String actionUnStake = 'WithdrawDexShare';
  static const String actionClaimRewards = 'PayoutRewards';
  static TxDexIncentiveData fromJson(Map<String, dynamic> json,
      String stableCoinSymbol, List<String> symbols, List<int> decimals) {
    final data = TxDexIncentiveData();
    data.block = json['extrinsic']['block']['number'];
    data.hash = json['extrinsic']['id'];
    data.event = json['type'];

    final jsonData = jsonDecode(json['data']);

    switch (data.event) {
      case actionClaimRewards:
        final pair = (jsonDecode(jsonData[1]['value'])['dexIncentive']
                ['dexShare'] as List)
            .map((e) => e['token'])
            .toList();
        final poolId = pair.join('-');
        final rewardToken = jsonDecode(jsonData[2]['value'])['token'];
        data.poolId = poolId;
        data.amountShare =
            '${Fmt.balance(jsonData[3]['value'], decimals[symbols.indexOf(rewardToken)])} ${PluginFmt.tokenView(rewardToken)}';
        break;
      case actionStake:
      case actionUnStake:
        final pair = (jsonDecode(jsonData[1]['value'])['dexShare'] as List)
            .map((e) => e['token'])
            .toList();
        final poolId = pair.join('-');
        final shareTokenView = PluginFmt.tokenView(poolId);
        data.poolId = poolId;
        data.amountShare =
            '${Fmt.balance(jsonData[2]['value'], decimals[symbols.indexOf(pair[0])])} $shareTokenView';
        break;
    }
    data.time = json['extrinsic']['timestamp'] as String;
    data.isSuccess = json['extrinsic']['isSuccess'];
    return data;
  }
}

abstract class _TxDexIncentiveData {
  String block;
  String hash;
  String event;
  String poolId;
  String amountShare;
  String time;
  bool isSuccess = true;
}
