import 'dart:math';

import 'package:polkawallet_plugin_acala/common/constants.dart';
import 'package:polkawallet_ui/utils/format.dart';

class LoanType extends _LoanType {
  static LoanType fromJson(Map<String, dynamic> json) {
    LoanType data = LoanType();
    data.token = json['currency']['token'];
    data.debitExchangeRate = BigInt.parse(json['debitExchangeRate'].toString());
    data.liquidationPenalty =
        BigInt.parse(json['liquidationPenalty'].toString());
    data.liquidationRatio = BigInt.parse(json['liquidationRatio'].toString());
    data.requiredCollateralRatio =
        BigInt.parse((json['requiredCollateralRatio'] ?? 0).toString());
    data.stabilityFee = BigInt.parse((json['stabilityFee'] ?? 0).toString());
    data.globalStabilityFee =
        BigInt.parse(json['globalStabilityFee'].toString());
    data.maximumTotalDebitValue =
        BigInt.parse(json['maximumTotalDebitValue'].toString());
    data.minimumDebitValue = BigInt.parse(json['minimumDebitValue'].toString());
    data.expectedBlockTime = int.parse(json['expectedBlockTime']);
    return data;
  }

  BigInt debitShareToDebit(BigInt debitShares) {
    return debitShares *
        debitExchangeRate ~/
        BigInt.from(pow(10, acala_price_decimals));
  }

  BigInt debitToDebitShare(BigInt debits) {
    return debits *
        BigInt.from(pow(10, acala_price_decimals)) ~/
        debitExchangeRate;
  }

  BigInt tokenToUSD(BigInt amount, price,
      {int stableCoinDecimals, int collateralDecimals}) {
    return amount *
        price ~/
        BigInt.from(pow(10,
            acala_price_decimals + collateralDecimals - stableCoinDecimals));
  }

  double calcCollateralRatio(BigInt debitInUSD, BigInt collateralInUSD) {
    if (debitInUSD + BigInt.two < minimumDebitValue) {
      return double.minPositive;
    }
    return collateralInUSD / debitInUSD;
  }

  BigInt calcLiquidationPrice(BigInt debit, BigInt collaterals,
      {int stableCoinDecimals, int collateralDecimals}) {
    return debit > BigInt.zero
        ? BigInt.from(debit *
            this.liquidationRatio /
            collaterals /
            pow(10, stableCoinDecimals - collateralDecimals))
        : BigInt.zero;
  }

  BigInt calcRequiredCollateral(BigInt debitInUSD, BigInt price,
      {int stableCoinDecimals, int collateralDecimals}) {
    if (price > BigInt.zero && debitInUSD > BigInt.zero) {
      return BigInt.from(debitInUSD *
          requiredCollateralRatio /
          price /
          pow(10, stableCoinDecimals - collateralDecimals));
    }
    return BigInt.zero;
  }

  BigInt calcMaxToBorrow(BigInt collaterals, tokenPrice,
      {int stableCoinDecimals, int collateralDecimals}) {
    return tokenToUSD(collaterals, tokenPrice,
            stableCoinDecimals: stableCoinDecimals,
            collateralDecimals: collateralDecimals) *
        BigInt.from(pow(10, acala_price_decimals)) ~/
        requiredCollateralRatio;
  }
}

abstract class _LoanType {
  String token = '';
  BigInt debitExchangeRate = BigInt.zero;
  BigInt liquidationPenalty = BigInt.zero;
  BigInt liquidationRatio = BigInt.zero;
  BigInt requiredCollateralRatio = BigInt.zero;
  BigInt stabilityFee = BigInt.zero;
  BigInt globalStabilityFee = BigInt.zero;
  BigInt maximumTotalDebitValue = BigInt.zero;
  BigInt minimumDebitValue = BigInt.zero;
  int expectedBlockTime = 0;
}

class LoanData extends _LoanData {
  static LoanData fromJson(Map<String, dynamic> json, LoanType type,
      BigInt tokenPrice, List<String> symbols, List<int> decimals) {
    final stableCoinDecimals = decimals[symbols.indexOf('AUSD')];

    LoanData data = LoanData();
    data.token = json['currency']['token'];
    data.type = type;
    data.price = tokenPrice;
    data.stableCoinPrice = Fmt.tokenInt('1', stableCoinDecimals);
    data.debitShares = BigInt.parse(json['debit'].toString());
    data.debits = type.debitShareToDebit(data.debitShares);
    data.collaterals = BigInt.parse(json['collateral'].toString());

    final collateralDecimals = decimals[symbols.indexOf(data.token)];

    data.debitInUSD = data.debits;
    data.collateralInUSD = type.tokenToUSD(data.collaterals, tokenPrice,
        stableCoinDecimals: stableCoinDecimals,
        collateralDecimals: collateralDecimals);
    data.collateralRatio =
        type.calcCollateralRatio(data.debitInUSD, data.collateralInUSD);

    data.requiredCollateral = type.calcRequiredCollateral(
        data.debitInUSD, tokenPrice,
        stableCoinDecimals: stableCoinDecimals,
        collateralDecimals: collateralDecimals);
    data.maxToBorrow = type.calcMaxToBorrow(data.collaterals, tokenPrice,
        stableCoinDecimals: stableCoinDecimals,
        collateralDecimals: collateralDecimals);
    data.stableFeeDay = data.calcStableFee(SECONDS_OF_DAY);
    data.stableFeeYear = data.calcStableFee(SECONDS_OF_YEAR);
    data.liquidationPrice = type.calcLiquidationPrice(
        data.debitInUSD, data.collaterals,
        stableCoinDecimals: stableCoinDecimals,
        collateralDecimals: collateralDecimals);
    return data;
  }
}

abstract class _LoanData {
  String token = '';
  LoanType type = LoanType();
  BigInt price = BigInt.zero;
  BigInt stableCoinPrice = BigInt.zero;
  BigInt debitShares = BigInt.zero;
  BigInt debits = BigInt.zero;
  BigInt collaterals = BigInt.zero;

  // computed properties
  BigInt debitInUSD = BigInt.zero;
  BigInt collateralInUSD = BigInt.zero;
  double collateralRatio = 0;
  BigInt requiredCollateral = BigInt.zero;
  BigInt maxToBorrow = BigInt.zero;
  double stableFeeDay = 0;
  double stableFeeYear = 0;
  BigInt liquidationPrice = BigInt.zero;

  double calcStableFee(int seconds) {
    int blocks = seconds * 1000 ~/ type.expectedBlockTime;
    double base = 1 +
        (type.globalStabilityFee + type.stabilityFee) /
            BigInt.from(pow(10, acala_price_decimals));
    return (pow(base, blocks) - 1);
  }
}

class CollateralIncentiveData extends _CollateralIncentiveData {
  static CollateralIncentiveData fromJson(List json) {
    final data = CollateralIncentiveData();
    data.token = json[0][0]['Token'];
    data.incentive = Fmt.balanceInt(json[1].toString());
    return data;
  }
}

abstract class _CollateralIncentiveData {
  String token;
  BigInt incentive;
}

class TotalCDPData extends _TotalCDPData {
  static TotalCDPData fromJson(Map json) {
    final data = TotalCDPData();
    data.token = json['token'];
    data.collateral = Fmt.balanceInt(json['collateral'].toString());
    data.debit = Fmt.balanceInt(json['debit'].toString());
    return data;
  }
}

abstract class _TotalCDPData {
  String token;
  BigInt collateral;
  BigInt debit;
}

class CollateralRewardData extends _CollateralRewardData {
  static CollateralRewardData fromJson(Map json) {
    final data = CollateralRewardData();
    data.token = json['token'];
    data.sharesTotal = Fmt.balanceInt(json['sharesTotal'].toString());
    data.shares = Fmt.balanceInt(json['shares'].toString());
    data.proportion = double.parse(json['proportion'].toString());
    data.reward = double.parse(json['reward']);
    return data;
  }
}

abstract class _CollateralRewardData {
  String token;
  BigInt sharesTotal;
  BigInt shares;
  double reward;
  double proportion;
}
