import 'dart:convert';

import 'package:polkawallet_plugin_acala/polkawallet_plugin_acala.dart';
import 'package:polkawallet_plugin_acala/store/cache/storeCache.dart';
import 'package:polkawallet_sdk/plugin/store/balances.dart';

class SwapStore {
  SwapStore(this.cache);

  final StoreCache? cache;

  Map<String?, List<String?>> _swapPair = Map<String?, List<String>>();

  List<TokenBalanceData> dexTokens = [];

  initDexTokens(PluginAcala plugin) async {
    dexTokens = (await plugin.api!.swap.getSwapTokens()) ?? [];
  }

  void setSwapPair(List<String?> value, String? pubKey) {
    _swapPair[pubKey] = value;
    if (value != cache!.swapPair.val[pubKey]) {
      final cached = cache!.swapPair.val;
      cached[pubKey] = jsonEncode(value);
      cache!.swapPair.val = cached;
    }
  }

  List<String?> swapPair(String? pubKey) {
    return _swapPair[pubKey] ?? [];
  }

  void loadCache(String? pubKey) {
    if (pubKey == null || pubKey.isEmpty) return;

    final _swapPair = cache!.swapPair.val;
    if (_swapPair[pubKey] != null) {
      var data = jsonDecode(_swapPair[pubKey]).cast<String>();
      setSwapPair([data[0], data[1]], pubKey);
    }
  }
}
