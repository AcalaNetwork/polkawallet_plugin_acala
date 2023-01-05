import 'package:mobx/mobx.dart';
import 'package:polkawallet_plugin_acala/store/cache/storeCache.dart';
import 'package:polkawallet_sdk/storage/types/ethWalletData.dart';
import 'package:polkawallet_sdk/storage/types/keyPairData.dart';

part 'accounts.g.dart';

class AccountsStore extends _AccountsStore with _$AccountsStore {
  AccountsStore(StoreCache? storage) : super(storage);
}

abstract class _AccountsStore with Store {
  _AccountsStore(this.cache);

  final StoreCache? cache;
  final String etherKey = 'evm_key';

  @observable
  EthWalletData? ethWalletData;

  @observable
  ObservableMap<String?, Map?> addressIndexMap = ObservableMap<String?, Map?>();

  @observable
  ObservableMap<String?, String?> addressIconsMap =
      ObservableMap<String?, String?>();

  @action
  void setAddressIconsMap(List list) {
    list.forEach((i) {
      addressIconsMap[i[0]] = i[1];
    });
  }

  @action
  void setAddressIndex(List list) {
    list.forEach((i) {
      addressIndexMap[i['accountId']] = i;
    });
  }

  @action
  Future<void> setEthWalletData(
      EthWalletData? ethWalletData, KeyPairData? current) async {
    this.ethWalletData = ethWalletData;
    if (ethWalletData != null) {
      final cached = (await cache!.accounts.getBox!().read(etherKey)) ?? {};
      cached[current!.address] = ethWalletData.toJson();
      cache!.accounts.getBox!().write(etherKey, cached);
    }
  }

  @action
  Future<void> loadCache(KeyPairData acc) async {
    final cached = cache!.accounts.getBox!().read(etherKey);
    if (cached != null && cached[acc.address] != null) {
      ethWalletData = EthWalletData.fromJson(cached[acc.address]);
    }
  }
}
