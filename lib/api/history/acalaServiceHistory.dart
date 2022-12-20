import 'dart:async';
import 'dart:convert';

import 'package:polkawallet_plugin_acala/polkawallet_plugin_acala.dart';

class AcalaServiceHistory {
  AcalaServiceHistory(this.plugin);

  final PluginAcala plugin;

  Future<List?> queryHistory(
      String type, String? address, Map<String, dynamic> params) async {
    final List? list = await plugin.sdk.webView!.evalJavascript(
        'acala.getHistory("$type","$address",${jsonEncode(params)})');
    return list;
  }
}
