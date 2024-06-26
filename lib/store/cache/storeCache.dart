import 'package:get_storage/get_storage.dart';
import 'package:polkawallet_plugin_acala/common/constants/index.dart';

class StoreCache {
  static final _storage = () => GetStorage(plugin_cache_key);

  final tokens = {}.val('tokens', getBox: _storage);

  final swapPair = {}.val('swapPair', getBox: _storage);

  final aggregatedAssets = {}.val('aggregatedAssets', getBox: _storage);

  final accounts = {}.val('accounts', getBox: _storage);
}
