import 'package:polkawallet_plugin_karura/api/acalaApi.dart';
import 'package:polkawallet_plugin_karura/api/types/stakingPoolInfoData.dart';
import 'package:polkawallet_plugin_karura/polkawallet_plugin_karura.dart';
import 'package:polkawallet_plugin_karura/store/index.dart';
import 'package:polkawallet_sdk/storage/keyring.dart';

class ServiceHoma {
  ServiceHoma(this.plugin, this.keyring)
      : api = plugin.api,
        store = plugin.store;

  final PluginKarura plugin;
  final Keyring keyring;
  final AcalaApi api;
  final PluginStore store;

  Future<HomaLitePoolInfoData> queryHomaLiteStakingPool() async {
    final res = await api.homa.queryHomaLiteStakingPool();
    store.homa.setHomaLitePoolInfoData(res);
    return res;
  }
}
