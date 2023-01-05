import 'package:mobx/mobx.dart';
import 'package:polkawallet_plugin_acala/api/types/nftData.dart';
import 'package:polkawallet_plugin_acala/store/cache/storeCache.dart';
import 'package:polkawallet_sdk/plugin/store/balances.dart';

part 'assets.g.dart';

class AssetsStore extends _AssetsStore with _$AssetsStore {
  AssetsStore(StoreCache? cache) : super(cache);
}

abstract class _AssetsStore with Store {
  _AssetsStore(this.cache);

  final StoreCache? cache;

  List<TokenBalanceData> allTokens = [];

  @observable
  Map<String?, TokenBalanceData> tokenBalanceMap =
      Map<String, TokenBalanceData>();

  @observable
  Map<String?, BigInt> prices = {};

  @observable
  ObservableMap<String, num> marketPrices = ObservableMap();

  @observable
  Map<String, double> dexPrices = {};

  @observable
  List<NFTData> nft = [];

  @observable
  Map? aggregatedAssets = {};

  Map crossChainIcons = {};

  void setAllTokens(List<TokenBalanceData> tokens) {
    allTokens = tokens;
  }

  @action
  void setTokenBalanceMap(List<TokenBalanceData> list, String? pubKey,
      {bool shouldCache = true}) {
    final data = Map<String?, TokenBalanceData>();
    final dataForCache = {};
    list.forEach((e) {
      if (e.tokenNameId == null) return;

      data[e.tokenNameId] = e;

      dataForCache[e.tokenNameId] = {
        'id': e.id,
        'name': e.name,
        'symbol': e.symbol,
        'type': e.type,
        'tokenNameId': e.tokenNameId,
        'currencyId': e.currencyId,
        'fullName': e.fullName,
        'decimals': e.decimals,
        'minBalance': e.minBalance,
        'amount': e.amount,
        'detailPageRoute': e.detailPageRoute,
      };
    });
    tokenBalanceMap = data;

    if (shouldCache) {
      final cached = cache!.tokens.val;
      cached[pubKey] = dataForCache;
      cache!.tokens.val = cached;
    }
  }

  @action
  void setPrices(Map<String?, BigInt> data) {
    prices = data;
  }

  @action
  void setMarketPrices(Map<String, num> data) {
    marketPrices.addAll(data);
  }

  @action
  void setDexPrices(Map<String, double> data) {
    dexPrices = {...dexPrices, ...data};
  }

  @action
  void setNFTs(List<NFTData> list) {
    nft = list;
  }

  @action
  void setAggregatedAssets(Map? data, String? pubKey) {
    aggregatedAssets = data;

    final cached = cache!.aggregatedAssets.val;
    cached[pubKey] = data;
    cache!.aggregatedAssets.val = cached;
  }

  @action
  void loadCache(String? pubKey) {
    if (pubKey == null || pubKey.isEmpty) return;

    final cachedTokens = cache!.tokens.val;
    if (cachedTokens[pubKey] != null) {
      final tokens = cachedTokens[pubKey].values.toList();
      tokens.retainWhere((e) => e['tokenNameId'] != null);
      setTokenBalanceMap(
          List<TokenBalanceData>.from(tokens.map((e) => TokenBalanceData(
              id: e['id'],
              name: e['name'],
              symbol: e['symbol'],
              type: e['type'],
              tokenNameId: e['tokenNameId'],
              currencyId: e['currencyId'],
              fullName: e['fullName'],
              decimals: e['decimals'],
              minBalance: e['minBalance'],
              amount: e['amount'],
              detailPageRoute: e['detailPageRoute']))),
          pubKey,
          shouldCache: false);
    } else {
      tokenBalanceMap = Map<String, TokenBalanceData>();
    }

    final cachedAggregatedAssets = cache!.aggregatedAssets.val;
    if (cachedAggregatedAssets[pubKey] != null) {
      aggregatedAssets = cachedAggregatedAssets[pubKey];
    } else {
      aggregatedAssets = {};
    }
  }
}
