import 'dart:developer';

import 'package:polkawallet_plugin_acala/api/earn/acalaServiceEarn.dart';
import 'package:polkawallet_plugin_acala/api/earn/types/incentivesData.dart';
import 'package:polkawallet_plugin_acala/api/types/dexPoolInfoData.dart';
import 'package:polkawallet_plugin_acala/pages/types/taigaPoolInfoData.dart';

class AcalaApiEarn {
  AcalaApiEarn(this.service);

  final AcalaServiceEarn service;

  Future<Map?> getTaigaMintAmount(
      String poolId, List<String> input, double slippage) async {
    final Map? res = await service.getTaigaMintAmount(poolId, input, slippage);
    //{"minAmount":"99215063014","params":[0,["98963000000","0"],"99215063014"]}
    return res;
  }

  Future<Map?> getTaigaRedeemAmount(
      String poolId, String input, double slippage) async {
    final Map? res =
        await service.getTaigaRedeemAmount(poolId, input, slippage);
    // {"minAmount":["23693477297","384434880258"],"params":[0,"69679144669",["23693477297","45491610738"]]}
    return res;
  }

  Future<List<DexPoolData>?> getTaigaTokenPairs() async {
    final List? res = await service.getTaigaTokenPairs();
    return res?.map((e) => DexPoolData.fromJson(e)).toList();
  }

  Future<Map<String, TaigaPoolInfoData>> getTaigaPoolInfo(
      String address) async {
    final Map? res = await service.getTaigaPoolInfo(address);
    log(res.toString());
    Map<String, TaigaPoolInfoData> data = {};
    res?.forEach(
        (key, value) => data.addAll({key: TaigaPoolInfoData.fromJson(value)}));
    return data;
  }

  Future<IncentivesData> queryIncentives() async {
    final res =
        await (service.queryIncentives() as Future<Map<dynamic, dynamic>>);
    return IncentivesData.fromJson(res);
  }

  Future<Map?> queryDexIncentiveLoyaltyEndBlock() async {
    return service.queryDexIncentiveLoyaltyEndBlock();
  }

  Future<int> getBlockDuration() async {
    return service.getBlockDuration();
  }

  Future<Map?> getIncentiveDeductionCurrency(Map pool) async {
    final res = await service.getIncentiveDeductionCurrency(pool);
    return res;
  }
}
