import 'package:polkawallet_plugin_acala/api/history/types/historyData.dart';
import 'package:polkawallet_plugin_acala/polkawallet_plugin_acala.dart';
import 'package:polkawallet_plugin_acala/utils/assets.dart';
import 'package:polkawallet_plugin_acala/utils/format.dart';
import 'package:polkawallet_ui/utils/format.dart';

const earn_actions_map = {
  'incentives.AddLiquidity': 'earn.AddLiquidity',
  'incentives.RemoveLiquidity': 'earn.RemoveLiquidity',
  'incentives.DepositDexShare': 'earn.DepositDexShare',
  'incentives.WithdrawDexShare': 'earn.WithdrawDexShare',
  'incentives.ClaimRewards': 'earn.ClaimRewards',
};

class TxDexIncentiveData extends _TxDexIncentiveData {
  static const String actionStake = 'incentives.DepositDexShare';
  static const String actionUnStake = 'incentives.WithdrawDexShare';
  static const String actionClaimRewards = 'incentives.ClaimRewards';
  static const String actionPayoutRewards = 'incentives.PayoutRewards';

  static const String actionStakeFilter = 'Stake LP';
  static const String actionUnStakeFilter = 'Unstake LP';
  static const String actionClaimRewardsFilter = 'Claim Rewards';
  static const String actionPayoutRewardsFilter = 'Payout Rewards';

  static TxDexIncentiveData fromHistory(
      HistoryData history, PluginAcala plugin) {
    final data = TxDexIncentiveData();
    data.hash = history.hash;
    data.event = history.event;
    data.resolveLinks = history.resolveLinks;

    final token = AssetsUtils.tokenDataFromCurrencyId(
        plugin, {'token': history.data!['tokenId']});
    final shareTokenView = PluginFmt.tokenView(token.symbol);
    data.poolId = shareTokenView.replaceAll('LP', '').trim();

    switch (data.event) {
      case TxDexIncentiveData.actionClaimRewards:
        data.amountShare =
            '${Fmt.balance(history.data!['actualAmount'], token.decimals!, length: 6)} $shareTokenView';
        break;
      case TxDexIncentiveData.actionPayoutRewards:
        data.amountShare =
            '${Fmt.balance(history.data!['actualPayout'], token.decimals!, length: 6)} $shareTokenView';
        break;
      default:
        data.amountShare =
            '${Fmt.balance(history.data!['amount'], token.decimals!, length: 6)} $shareTokenView';
    }

    data.time = (history.data!['timestamp'] as String).replaceAll(' ', '');
    data.isSuccess = true;
    return data;
  }
}

abstract class _TxDexIncentiveData {
  String? block;
  String? hash;
  String? resolveLinks;
  String? event;
  late String poolId;
  String? amountShare;
  late String time;
  bool? isSuccess = true;
}
