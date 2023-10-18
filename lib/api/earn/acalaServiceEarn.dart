import 'dart:async';
import 'dart:convert';

import 'package:polkawallet_plugin_acala/polkawallet_plugin_acala.dart';

class AcalaServiceEarn {
  AcalaServiceEarn(this.plugin);

  final PluginAcala plugin;

  Future<Map?> getTaigaMintAmount(
      String poolId, List<String> input, double slippage) async {
    final Map? res = await plugin.sdk.webView!.evalJavascript(
        'acala.getTaigaMintAmount("$poolId",${jsonEncode(input)},$slippage)');
    return res;
  }

  Future<Map?> getTaigaRedeemAmount(
      String poolId, String input, double slippage) async {
    final Map? res = await plugin.sdk.webView!.evalJavascript(
        'acala.getTaigaRedeemAmount("$poolId","$input",$slippage)');
    return res;
  }

  Future<List?> getTaigaTokenPairs() async {
    final List? res =
        await plugin.sdk.webView!.evalJavascript('acala.getTaigaTokenPairs()');
    return res;
  }

  Future<Map?> getTaigaPoolInfo(String address) async {
    try {
      final Map? res = await plugin.sdk.webView!
          .evalJavascript('acala.getTaigaPoolInfo(api, "$address")');
      return res;
    } catch (error) {
      print(error);
      return {};
    }
  }

  Future<Map?> queryIncentives() async {
    final Map? res =
        await plugin.sdk.webView!.evalJavascript('acala.queryIncentives(api)');
    return res;
  }

  Future<Map?> queryDexIncentiveLoyaltyEndBlock() async {
    final res = await plugin.sdk.webView!
        .evalJavascript('acala.queryDexIncentiveLoyaltyEndBlock(api)');
    return res;
  }

  Future<int> getBlockDuration() async {
    final res =
        await plugin.sdk.webView!.evalJavascript('acala.getBlockDuration()');
    return res;
  }

  Future<Map?> getIncentiveDeductionCurrency(Map pool) async {
    final res = await plugin.sdk.webView!.evalJavascript(
        'acala.queryIncentiveDeductionCurrency(api, ${jsonEncode(pool)})');
    return res;
  }
}
