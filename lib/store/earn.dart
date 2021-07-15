import 'package:mobx/mobx.dart';
import 'package:polkawallet_plugin_acala/api/types/dexPoolInfoData.dart';
import 'package:polkawallet_plugin_acala/store/cache/storeCache.dart';

part 'earn.g.dart';

class EarnStore extends _EarnStore with _$EarnStore {
  EarnStore(StoreCache cache) : super(cache);
}

abstract class _EarnStore with Store {
  _EarnStore(this.cache);

  final StoreCache cache;

  @observable
  Map<String, double> swapPoolRewards = Map<String, double>();

  @observable
  Map<String, double> swapPoolSavingRewards = Map<String, double>();

  @observable
  List<DexPoolData> dexPools = [];

  @observable
  List<DexPoolData> bootstraps = [];

  @observable
  ObservableMap<String, DexPoolInfoData> dexPoolInfoMap =
      ObservableMap<String, DexPoolInfoData>();

  @action
  void setDexPools(List<DexPoolData> list) {
    dexPools = list;
  }

  @action
  void setBootstraps(List<DexPoolData> list) {
    bootstraps = list;
  }

  @action
  void setDexPoolInfo(Map<String, DexPoolInfoData> data) {
    dexPoolInfoMap.addAll(data);
  }

  @action
  void setDexPoolRewards(Map<String, Map<String, double>> data) {
    swapPoolRewards = data['incentives'];
    swapPoolSavingRewards = data['savingRates'];
  }

  @action
  void loadCache(String pubKey) {
    if (pubKey == null || pubKey.isEmpty) return;

    dexPoolInfoMap = ObservableMap<String, DexPoolInfoData>();
  }
}
