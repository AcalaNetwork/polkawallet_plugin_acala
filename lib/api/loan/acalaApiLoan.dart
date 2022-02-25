import 'package:polkawallet_plugin_acala/api/loan/acalaServiceLoan.dart';
import 'package:polkawallet_plugin_acala/api/types/loanType.dart';
import 'package:polkawallet_plugin_acala/utils/assets.dart';

class AcalaApiLoan {
  AcalaApiLoan(this.service);

  final AcalaServiceLoan service;

  Future<List?> queryAccountLoans(String address) async {
    final List? res = await service.queryAccountLoans(address);
    return res;
  }

  Future<List<LoanType>> queryLoanTypes() async {
    final res = await service.queryLoanTypes();
    return res
        .map((e) =>
            LoanType.fromJson(Map<String, dynamic>.of(e), service.plugin))
        .toList();
  }

  Future<List<TotalCDPData>> queryTotalCDPs(List<Map?> pools) async {
    final List res =
        await (service.queryTotalCDPs(pools) as Future<List<dynamic>>);
    int index = 0;
    return res.map((e) {
      e['tokenNameId'] = AssetsUtils.tokenDataFromCurrencyId(
              service.plugin, pools[index] ?? Map<dynamic, dynamic>())
          ?.tokenNameId;
      index++;
      return TotalCDPData.fromJson(e);
    }).toList();
  }

  Future<Map<String?, double>> queryCollateralLoyaltyBonus() async {
    return service.queryCollateralLoyaltyBonus();
  }

  Future<List<CollateralRewardData>> queryCollateralRewards(String address) async {
    final res = await service.queryCollateralRewards(address) as List;
    return res.map((e) => CollateralRewardData.fromJson(e)).toList();
  }
}
