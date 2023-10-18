import 'package:polkawallet_plugin_acala/polkawallet_plugin_acala.dart';
import 'package:polkawallet_plugin_acala/utils/types/aggregatedAssetsData.dart';
import 'package:polkawallet_sdk/plugin/store/balances.dart';

class AssetsUtils {
  static const categoryTokens = 'Tokens';
  static const categoryStaking = 'Staking';
  static const categoryLP = 'LP Staking';
  static const categoryLPFree = 'LP Free';
  static const categoryRewards = 'Rewards';

  static List<AggregatedAssetsData> aggregatedAssetsDataFromJson(
      PluginAcala plugin, Map assetsMap, BalancesStore balances) {
    AggregatedAssetsData _getDataItem(String k) {
      final data = AggregatedAssetsData();
      data.category = k;
      data.assets =
          List<AggregatedAssetsItemData>.from(assetsMap[k].keys.map((key) {
        final item = AggregatedAssetsItemData();
        item.token = key;
        item.amount = double.parse(assetsMap[k][key].toString());
        item.value = getMarketPrice(plugin, key) * item.amount;
        return item;
      }).toList());
      data.value = data.assets.length > 0
          ? data.assets.map((e) => e.value).reduce((v, e) => v! + e!)
          : 0;
      return data;
    }

    final lpFreeMapInt = {};
    balances.tokens.forEach((e) {
      if (e.id!.contains('-')) {
        final amount = BigInt.tryParse(e.amount!) ?? BigInt.zero;
        if (amount > BigInt.zero) {
          lpFreeMapInt[e.id] = amount;
        }
      }
    });

    final List<AggregatedAssetsData> list = [
      _getDataItem(categoryRewards),
      _getDataItem(categoryLP),
      _getDataItem(categoryStaking),
      _getDataItem(categoryTokens),
      _getDataItem(categoryLPFree),
    ];

    if (assetsMap[categoryLPFree].keys.length > 0) {
      final lpFreeValueItem = AggregatedAssetsItemData();
      lpFreeValueItem.token = 'FreeLP';
      lpFreeValueItem.amount = 0;
      lpFreeValueItem.value = list
          .firstWhere((e) => e.category == categoryLPFree)
          .assets
          .map((e) => e.value)
          .reduce((a, b) => a! + b!);
      final tokensData = list.firstWhere((e) => e.category == categoryTokens);
      tokensData.assets.add(lpFreeValueItem);
      tokensData.value = tokensData.value! + lpFreeValueItem.value!;
    }

    return list.sublist(0, 4);
  }

  static TokenBalanceData tokenDataFromCurrencyId(
      PluginAcala? plugin, Map currencyId) {
    if (currencyId['token'] != null || currencyId['Token'] != null) {
      return getBalanceFromTokenNameId(
          plugin!, currencyId['token'] ?? currencyId['Token']);
    }
    if (currencyId.length > 0 && currencyId[currencyId.keys.first] != null) {
      final currencyIdKey = currencyId.keys.first as String;
      final list = (plugin!.store!.assets.tokenBalanceMap.values.length >=
                  plugin.store!.assets.allTokens.length
              ? plugin.store!.assets.tokenBalanceMap.values
              : plugin.store!.assets.allTokens)
          .toList();
      final i = list.indexWhere((e) =>
          (e.currencyId?.keys.toList() ?? [''])[0].toLowerCase() ==
              currencyIdKey.toLowerCase() &&
          e.id == currencyId[currencyIdKey].toString());
      return i > -1 ? list[i] : TokenBalanceData();
    }
    return TokenBalanceData();
  }

  static TokenBalanceData getBalanceFromTokenNameId(
      PluginAcala plugin, String? tokenNameId) {
    if (tokenNameId == plugin.networkState.tokenSymbol![0]) {
      return TokenBalanceData(
          id: tokenNameId,
          symbol: tokenNameId,
          tokenNameId: tokenNameId,
          currencyId: {'Token': tokenNameId},
          type: 'Token',
          minBalance: plugin.networkConst['balances']['existentialDeposit'],
          decimals: plugin.networkState.tokenDecimals![0],
          amount: (plugin.balances.native?.availableBalance ?? 0).toString());
    }
    if (plugin.store!.assets.tokenBalanceMap[tokenNameId] != null) {
      return plugin.store!.assets.tokenBalanceMap[tokenNameId]!;
    }
    final tokenDataIndex = plugin.store!.assets.allTokens
        .indexWhere((e) => e.tokenNameId == tokenNameId);
    return tokenDataIndex < 0
        ? TokenBalanceData()
        : plugin.store!.assets.allTokens[tokenDataIndex];
  }

  static List<TokenBalanceData> getBalancePairFromTokenNameId(
      PluginAcala plugin, List<String?> tokenNameIdPair) {
    return tokenNameIdPair
        .map((e) => getBalanceFromTokenNameId(plugin, e))
        .toList();
  }

  static double getMarketPrice(PluginAcala plugin, String tokenSymbol) {
    final market =
        plugin.store!.assets.marketPrices[tokenSymbol]?.toDouble() ?? 0;
    return market == 0
        ? plugin.store!.assets.dexPrices[tokenSymbol] ?? 0
        : market;
  }
}
