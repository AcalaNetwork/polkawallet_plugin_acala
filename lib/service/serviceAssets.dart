import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:polkawallet_plugin_acala/api/acalaApi.dart';
import 'package:polkawallet_plugin_acala/common/constants/index.dart';
import 'package:polkawallet_plugin_acala/polkawallet_plugin_acala.dart';
import 'package:polkawallet_plugin_acala/service/walletApi.dart';
import 'package:polkawallet_plugin_acala/store/index.dart';
import 'package:polkawallet_plugin_acala/utils/assets.dart';
import 'package:polkawallet_plugin_acala/utils/format.dart';
import 'package:polkawallet_sdk/plugin/store/balances.dart';
import 'package:polkawallet_sdk/storage/keyring.dart';
import 'package:polkawallet_ui/components/v3/plugin/pluginLoadingWidget.dart';
import 'package:polkawallet_ui/utils/format.dart';

class ServiceAssets {
  ServiceAssets(this.plugin, this.keyring)
      : api = plugin.api,
        store = plugin.store;

  final PluginAcala plugin;
  final Keyring keyring;
  final AcalaApi? api;
  final PluginStore? store;

  Future<void> queryMarketPrices({bool withDexPrice = true}) async {
    if (store!.earn.dexPools.length == 0) {
      await plugin.service?.earn.getDexPools();
    }

    if (withDexPrice) {
      queryDexPrices();
    }

    final prices = await plugin.api!.assets.getTokenPrices(
        plugin.store!.assets.allTokens.map((e) => e.symbol ?? '').toList());

    store!.assets.setMarketPrices(prices);
  }

  Future<void> queryDexPrices() async {
    final tokens = PluginFmt.getAllDexTokens(plugin);
    tokens.removeWhere((e) =>
        e?.tokenNameId == acala_stable_coin ||
        (e?.symbol ?? '').toLowerCase().contains('tai'));

    final output = await plugin.sdk.webView?.evalJavascript(
        'Promise.all([${tokens.map((e) => 'acala.calcTokenSwapAmount(apiRx, 1, null, ${jsonEncode([
                  e?.tokenNameId,
                  acala_stable_coin
                ])}, "0.05")').join(',')}])');

    final Map<String, double> prices = {};
    output.asMap().forEach((k, v) {
      prices[tokens[k]!.symbol!] = v?['amount'] ?? 0;
    });

    store?.assets.setDexPrices(prices);
  }

  Future<TokenBalanceData> updateTokenBalances(TokenBalanceData token) async {
    final res = await plugin.sdk.webView!.evalJavascript(
        'acala.getTokenBalance("${keyring.current.address}", "${token.tokenNameId}")');

    final balances =
        Map<String?, TokenBalanceData>.from(store!.assets.tokenBalanceMap);
    final data = TokenBalanceData(
        id: token.id,
        name: token.name,
        fullName: token.fullName,
        symbol: token.symbol,
        tokenNameId: token.tokenNameId,
        currencyId: token.currencyId,
        type: token.type,
        decimals: token.decimals,
        minBalance: token.minBalance,
        amount: res['free'].toString(),
        locked: res['frozen'].toString(),
        reserved: res['reserved'].toString(),
        detailPageRoute: token.detailPageRoute,
        price: AssetsUtils.getMarketPrice(plugin, token.symbol ?? ''),
        getPrice: () {
          return AssetsUtils.getMarketPrice(plugin, token.symbol ?? '');
        },
        priceCurrency: token.priceCurrency,
        priceRate: token.priceRate);
    balances[token.tokenNameId] = data;

    store!.assets
        .setTokenBalanceMap(balances.values.toList(), keyring.current.pubKey);
    plugin.balances.setTokens([data]);
    return data;
  }

  Future<void> queryAggregatedAssets() async {
    queryMarketPrices();
    final data =
        await plugin.api!.assets.queryAggregatedAssets(keyring.current.address);
    plugin.store!.assets.setAggregatedAssets(data, keyring.current.pubKey);
  }

  void calcLPTokenPrices() {
    final Map<String, double> prices = {};
    plugin.store!.earn.dexPoolInfoMap.values.forEach((e) {
      final pool = plugin.store!.earn.dexPools
          .firstWhere((i) => i.tokenNameId == e.tokenNameId);
      final tokenPair = pool.tokens!
          .map((id) => AssetsUtils.tokenDataFromCurrencyId(plugin, id))
          .toList();

      prices[tokenPair.map((e) => e.symbol).join('-')] =
          (Fmt.bigIntToDouble(e.amountLeft, tokenPair[0].decimals!) *
                      AssetsUtils.getMarketPrice(
                          plugin, tokenPair[0].symbol ?? '') +
                  Fmt.bigIntToDouble(e.amountRight, tokenPair[1].decimals!) *
                      AssetsUtils.getMarketPrice(
                          plugin, tokenPair[1].symbol ?? '')) /
              Fmt.bigIntToDouble(e.issuance, tokenPair[0].decimals!);
    });
    plugin.store!.assets.setMarketPrices(prices);
  }

  Future<void> queryIconsSrc() async {
    final data = await Future.wait(
        [WalletApi.getTokenIcons(), WalletApi.getCrossChainIcons()]);
    if (data[0] != null && data[1] != null) {
      final icons = Map.of(data[0]!);
      icons.removeWhere(
          (key, value) => plugin.tokenIcons.keys.toList().indexOf(key) > -1);
      plugin.tokenIcons.addAll(icons.map((k, v) {
        return MapEntry(
            (k as String).toUpperCase(),
            (v as String).contains('.svg')
                ? SvgPicture.network(
                    v,
                    placeholderBuilder: (context) => PluginLoadingWidget(),
                  )
                : Image.network(
                    v,
                    loadingBuilder: (context, child, loadingProgress) =>
                        loadingProgress == null ? child : PluginLoadingWidget(),
                    errorBuilder: (context, error, stackTrace) =>
                        Icon(Icons.image_not_supported),
                  ));
      }));

      store!.assets.crossChainIcons = data[1]!;
    }
  }
}
