import 'dart:async';

import 'package:polkawallet_plugin_acala/polkawallet_plugin_acala.dart';

class AcalaServiceHoma {
  AcalaServiceHoma(this.plugin);

  final PluginAcala plugin;

  Future<dynamic> queryHomaNewEnv() async {
    final dynamic res =
        await plugin.sdk.webView!.evalJavascript('acala.queryHomaNewEnv(api)');
    return res;
  }

  Future<Map?> calcHomaNewMintAmount(double input) async {
    final Map? res = await plugin.sdk.webView!
        .evalJavascript('acala.calcHomaNewMintAmount(api, $input)');
    return res;
  }

  Future<Map?> calcHomaNewRedeemAmount(double input,
      {bool isFastRedeem = false}) async {
    final Map? res = await plugin.sdk.webView!.evalJavascript(
        'acala.calcHomaNewRedeemAmount(api,$input,$isFastRedeem)');
    return res;
  }

  Future<Map?> queryHomaPendingRedeem(String? address) async {
    final Map? res = await plugin.sdk.webView!
        .evalJavascript('acala.queryHomaPendingRedeem(api,"$address")');
    return res;
  }
}
