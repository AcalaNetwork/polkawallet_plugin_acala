import 'package:json_annotation/json_annotation.dart';

import 'package:polkawallet_ui/utils/format.dart';

part 'dexPoolInfoData.g.dart';

class DexPoolInfoData extends _DexPoolInfoData {
  static DexPoolInfoData fromJson(Map<String, dynamic> json) {
    DexPoolInfoData data = DexPoolInfoData();
    data.token = json['token'];
    data.amountLeft = Fmt.balanceInt(json['pool'][0].toString());
    data.amountRight = Fmt.balanceInt(json['pool'][1].toString());
    data.sharesTotal = Fmt.balanceInt(json['sharesTotal'].toString());
    data.shares = Fmt.balanceInt(json['shares'].toString());
    data.proportion = double.parse(json['proportion'].toString());
    data.reward = LPRewardData(
      double.parse(json['reward']['incentive']),
      double.parse(json['reward']['saving']),
    );
    data.issuance = Fmt.balanceInt(json['issuance'].toString());
    return data;
  }
}

abstract class _DexPoolInfoData {
  String token;
  BigInt amountLeft;
  BigInt amountRight;
  BigInt sharesTotal;
  BigInt shares;
  LPRewardData reward;
  double proportion;
  BigInt issuance;
}

class LPRewardData {
  LPRewardData(this.incentive, this.saving);
  double incentive;
  double saving;
}

@JsonSerializable()
class DexPoolData extends _DexPoolData {
  static DexPoolData fromJson(Map<String, dynamic> json) =>
      _$DexPoolDataFromJson(json);
  Map<String, dynamic> toJson() => _$DexPoolDataToJson(this);
}

abstract class _DexPoolData {
  int decimals;
  List tokens;
}
