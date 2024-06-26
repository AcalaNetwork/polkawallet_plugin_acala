import 'package:mobx/mobx.dart';
import 'package:polkawallet_plugin_acala/api/earn/types/incentivesData.dart';
import 'package:polkawallet_plugin_acala/api/types/dexPoolInfoData.dart';
import 'package:polkawallet_plugin_acala/pages/types/taigaPoolInfoData.dart';
import 'package:polkawallet_plugin_acala/store/cache/storeCache.dart';

part 'earn.g.dart';

class EarnStore extends _EarnStore with _$EarnStore {
  EarnStore(StoreCache? cache) : super(cache);
}

abstract class _EarnStore with Store {
  _EarnStore(this.cache);

  final StoreCache? cache;

  int blockDuration = 12000;

  @observable
  IncentivesData incentives = IncentivesData();

  @observable
  List<DexPoolData> dexPools = [];

  @observable
  List<DexPoolData> bootstraps = [];

  @observable
  ObservableMap<String?, DexPoolInfoData> dexPoolInfoMap =
      ObservableMap<String?, DexPoolInfoData>();

  @observable
  ObservableMap<String?, TaigaPoolInfoData> taigaPoolInfoMap =
      ObservableMap<String?, TaigaPoolInfoData>();

  @observable
  List<DexPoolData> taigaTokenPairs = [];

  @observable
  List<dynamic> dexIncentiveEndBlock = [];

  @observable
  List<dynamic> dexIncentiveLoyaltyEndBlock = [];

  @action
  void setDexIncentiveLoyaltyEndBlock(Map? data) {
    final result = List.of(data?['result'] ?? []);
    result.sort((a, b) => a['blockNumber'] - b['blockNumber']);
    final loyalty = List.of(data?['loyalty'] ?? []);
    loyalty.sort((a, b) => a['blockNumber'] - b['blockNumber']);

    dexIncentiveEndBlock = result;
    dexIncentiveLoyaltyEndBlock = loyalty;
  }

  @action
  void setDexPools(List<DexPoolData> list) {
    dexPools = list;
  }

  @action
  void setBootstraps(List<DexPoolData> list) {
    bootstraps = list;
  }

  @action
  void setDexPoolInfo(Map<String?, DexPoolInfoData> data,
      {bool reset = false}) {
    if (reset) {
      dexPoolInfoMap = ObservableMap<String?, DexPoolInfoData>();
    } else {
      dexPoolInfoMap.addAll(data);
    }
  }

  @action
  void setTaigaPoolInfo(Map<String?, TaigaPoolInfoData> data) {
    taigaPoolInfoMap.addAll(data);
  }

  @action
  void setTaigaTokenPairs(List<DexPoolData> data) {
    taigaTokenPairs = data;
  }

  @action
  void setIncentives(IncentivesData data) {
    incentives = data;
  }

  void setBlockDuration(int duration) {
    blockDuration = duration;
  }
}
