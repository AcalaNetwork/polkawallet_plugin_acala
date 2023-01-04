import 'package:polkawallet_plugin_acala/api/homa/acalaServiceHoma.dart';
import 'package:polkawallet_plugin_acala/api/types/homaNewEnvData.dart';
import 'package:polkawallet_plugin_acala/api/types/homaPendingRedeemData.dart';

class AcalaApiHoma {
  AcalaApiHoma(this.service);

  final AcalaServiceHoma service;

  Future<Map?> calcHomaNewMintAmount(double input) async {
    final Map? res = await service.calcHomaNewMintAmount(input);
    return res;
  }

  Future<Map?> calcHomaNewRedeemAmount(double input, bool isFastRedeem) async {
    return service.calcHomaNewRedeemAmount(input, isFastRedeem: isFastRedeem);
  }

  Future<HomaNewEnvData> queryHomaNewEnv() async {
    final dynamic res = await service.queryHomaNewEnv();
    return HomaNewEnvData.fromJson(res);
  }

  Future<HomaPendingRedeemData> queryHomaPendingRedeem(String? address) async {
    final res = await service.queryHomaPendingRedeem(address);
    return HomaPendingRedeemData.fromJson(Map<String, dynamic>.from(res ?? {}));
  }
}
