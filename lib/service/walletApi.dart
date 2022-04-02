import 'dart:convert';

import 'package:http/http.dart';

class WalletApi {
  static const String _endpoint = 'https://api.polkawallet.io';
  static const String _configEndpoint = 'https://acala.polkawallet-cloud.com';
  static const String _cdnEndpoint = 'https://cdn.polkawallet-cloud.com';

  static Future<Map?> getTokenPrice() async {
    final url =
        '$_cdnEndpoint/lastPrice.json?t=${DateTime.now().millisecondsSinceEpoch}';
    try {
      Response res = await get(Uri.parse(url));
      if (res == null) {
        return null;
      } else {
        return jsonDecode(utf8.decode(res.bodyBytes));
      }
    } catch (err) {
      print(err);
      return null;
    }
  }

  static Future<Map?> getRemoteConfig() async {
    final url = '$_configEndpoint/config/acalaConfig.json';
    // final url = '$_endpoint/config/acalaConfig.json';
    try {
      Response res = await get(Uri.parse(url));
      if (res == null) {
        return null;
      } else {
        return jsonDecode(utf8.decode(res.bodyBytes));
      }
    } catch (err) {
      print(err);
      return null;
    }
  }

  static Future<Map?> getTokenIcons() async {
    try {
      Response res =
          await get(Uri.parse('https://resources.acala.network/tokens.json'));
      if (res == null) {
        return null;
      } else {
        return jsonDecode(utf8.decode(res.bodyBytes));
      }
    } catch (err) {
      print(err);
      return null;
    }
  }

  static Future<Map?> getCrossChainIcons() async {
    try {
      Response res =
          await get(Uri.parse('https://resources.acala.network/chains.json'));
      if (res == null) {
        return null;
      } else {
        return jsonDecode(utf8.decode(res.bodyBytes));
      }
    } catch (err) {
      print(err);
      return null;
    }
  }

  static Future<Map?> getDemocracyReferendumInfo(int id,
      {String network = 'acala'}) async {
    try {
      final res = await post(
          Uri.parse(
              'https://$network.api.subscan.io/api/scan/democracy/referendum'),
          headers: {"Content-Type": "application/json", "Accept": "*/*"},
          body: jsonEncode({'referendum_index': id}));
      // ignore: unnecessary_null_comparison
      if (res == null) {
        return null;
      } else {
        return jsonDecode(res.body) as Map;
      }
    } catch (err) {
      print(err);
      return null;
    }
  }
}
