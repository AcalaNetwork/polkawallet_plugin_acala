import 'dart:convert';

import 'package:polkawallet_plugin_acala/api/types/dexPoolInfoData.dart';
import 'package:polkawallet_plugin_acala/polkawallet_plugin_acala.dart';
import 'package:polkawallet_plugin_acala/utils/assets.dart';
import 'package:polkawallet_plugin_acala/utils/format.dart';
import 'package:polkawallet_ui/utils/format.dart';

class TxSwapData extends _TxSwapData {
  static const String actionTypeSwapFilter = 'Swap';
  static const String actionTypeAddLiquidityFilter = 'Add Liquidity';
  static const String actionTypeRemoveLiquidityFilter = 'Remove Liquidity';
  static const String actionTypeAddProvisionFilter = 'Add Provision';

  static TxSwapData fromJson(Map json, PluginAcala plugin) {
    final data = TxSwapData();
    data.action = json['__typename'].toString();
    data.hash = json['extrinsicId'];

    switch (data.action) {
      case "Swap":
        final tokenPair = AssetsUtils.getBalancePairFromTokenNameId(
            plugin, [json['token0Id'], json['token1Id']]);
        data.tokenPay = tokenPair[0].symbol;
        data.tokenReceive = tokenPair[1].symbol;
        data.amountPay = Fmt.priceFloorBigInt(
            Fmt.balanceInt(json['token0InAmount'].toString()),
            tokenPair[0].decimals ?? 12,
            lengthMax: 6);
        data.amountReceive = Fmt.priceFloorBigInt(
            Fmt.balanceInt(json['token1OutAmount'].toString()),
            tokenPair[1].decimals ?? 12,
            lengthMax: 6);
        break;
      case "AddProvision":
      case "AddLiquidity":
      case "RemoveLiquidity":
        final tokenPair = AssetsUtils.getBalancePairFromTokenNameId(
            plugin, [json['token0Id'], json['token1Id']]);
        data.tokenPay = tokenPair[0].symbol;
        data.tokenReceive = tokenPair[1].symbol;
        data.amountPay = Fmt.priceFloorBigInt(
            Fmt.balanceInt(json['token0Amount'].toString()),
            tokenPair[0].decimals ?? 12,
            lengthMax: 6);
        data.amountReceive = Fmt.priceFloorBigInt(
            Fmt.balanceInt(json['token1Amount'].toString()),
            tokenPair[1].decimals ?? 12,
            lengthMax: 6);
        data.amountShare = json['shareAmount'] != null
            ? Fmt.priceFloorBigInt(
                Fmt.balanceInt(json['shareAmount'].toString()),
                tokenPair[0].decimals ?? 12,
                lengthMax: 6)
            : '';
        break;
    }

    data.time = (json['timestamp'] as String).replaceAll(' ', '');
    data.isSuccess = true;
    return data;
  }

  static TxSwapData fromTaigaJson(Map json, PluginAcala plugin) {
    final data = TxSwapData();
    data.action = json['__typename'].toString();
    data.hash = json['extrinsicId'];
    data.isTaiga = true;

    switch (data.action) {
      case "Swap":
        final tokenPay = AssetsUtils.tokenDataFromCurrencyId(
            plugin, jsonDecode(json['inputAsset']));
        final tokenReceive = AssetsUtils.tokenDataFromCurrencyId(
            plugin, jsonDecode(json['outputAsset']));
        data.tokenPay = tokenPay.symbol;
        data.tokenReceive = tokenReceive.symbol;

        if (tokenPay.symbol == 'LDOT') {
          data.amountPay = Fmt.priceFloor(
              Fmt.bigIntToDouble(Fmt.balanceInt(json['inputAmount']),
                      tokenPay.decimals ?? 12) /
                  Fmt.bigIntToDouble(
                      Fmt.balanceInt(json['block']['liquidExchangeRate']), 18),
              lengthMax: 6);
        } else {
          data.amountPay = Fmt.priceFloorBigInt(
              Fmt.balanceInt(json['inputAmount']), tokenPay.decimals ?? 12,
              lengthMax: 6);
        }

        if (tokenReceive.symbol == 'LDOT') {
          data.amountReceive = Fmt.priceFloor(
              Fmt.bigIntToDouble(Fmt.balanceInt(json['outputAmount']),
                      tokenPay.decimals ?? 12) /
                  Fmt.bigIntToDouble(
                      Fmt.balanceInt(json['block']['liquidExchangeRate']), 18),
              lengthMax: 6);
        } else {
          data.amountReceive = Fmt.priceFloorBigInt(
              Fmt.balanceInt(json['outputAmount']), tokenReceive.decimals ?? 12,
              lengthMax: 6);
        }

        break;
      case "Mint":
        final taigaData = plugin.store!.earn.taigaTokenPairs.firstWhere(
            (element) => element.tokenNameId == "sa://${json['poolId']}",
            orElse: () => DexPoolData());
        final tokenPair = taigaData.tokens
            ?.map((e) => AssetsUtils.tokenDataFromCurrencyId(plugin, e))
            .toList();

        tokenPair?.forEach((element) {
          final index = tokenPair.indexOf(element);
          final amount;
          if (element.symbol == 'LDOT') {
            amount = Fmt.priceFloor(
                Fmt.bigIntToDouble(
                        Fmt.balanceInt(
                            json['inputAmounts'].toString().split(",")[index]),
                        tokenPair[index].decimals ?? 12) /
                    Fmt.bigIntToDouble(
                        Fmt.balanceInt(json['block']['liquidExchangeRate']),
                        18),
                lengthMax: 6);
          } else {
            amount = Fmt.priceFloorBigInt(
                Fmt.balanceInt(
                    json['inputAmounts'].toString().split(",")[index]),
                tokenPair[index].decimals ?? 12,
                lengthMax: 6);
          }
          data.amounts.add(_Token()
            ..amount = amount
            ..symbol = element.symbol);
        });
        break;
      case "ProportionRedeem":
      case "SingleRedeem":
      case "MultiRedeem":
        final tokenPay = AssetsUtils.getBalanceFromTokenNameId(
            plugin, "sa://${json['poolId']}");
        data.tokenPay = tokenPay.symbol;
        data.amountPay = Fmt.priceFloorBigInt(
            Fmt.balanceInt(json['inputAmount']), tokenPay.decimals ?? 12,
            lengthMax: 6);
        break;
    }

    data.time = (json['timestamp'] as String).replaceAll(' ', '');
    return data;
  }
}

abstract class _TxSwapData {
  String? block;
  String? hash;
  String? action;
  String? tokenPay;
  String? tokenReceive;
  String? amountPay;
  String? amountReceive;
  String? amountShare;
  late String time;
  bool? isSuccess;
  bool isTaiga = false;
  List<_Token> amounts = [];
}

class _Token {
  String? symbol;
  String? amount;

  String toTokenString() {
    return "$amount ${PluginFmt.tokenView(symbol)}";
  }
}
