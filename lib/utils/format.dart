import 'package:flutter/material.dart';
import 'package:polkawallet_plugin_acala/common/constants/index.dart';
import 'package:polkawallet_plugin_acala/polkawallet_plugin_acala.dart';
import 'package:polkawallet_plugin_acala/utils/assets.dart';
import 'package:polkawallet_sdk/plugin/store/balances.dart';
import 'package:polkawallet_ui/utils/format.dart';

class PluginFmt {
  static String tokenView(String? token) {
    if (token == acala_stable_coin) {
      return acala_stable_coin_view;
    }
    if (token == acala_token_lc_dot) {
      return acala_token_lc_dot_view;
    }
    if (token == acala_token_usdc) {
      return acala_token_usdc_view;
    }
    if (token?.contains('-') ?? false) {
      return '${token!.split('-').map((e) => PluginFmt.tokenView(e)).join('-')} LP';
    }
    return token ?? '';
  }

  static LiquidityShareInfo calcLiquidityShare(
      List<double> pool, List<double> user) {
    final xRate = pool[1] == 0.0 ? 0 : pool[0] / pool[1];
    final totalShare = pool[0] + pool[1] * xRate;

    final userShare = user[0] + user[1] * xRate;
    return LiquidityShareInfo(userShare, userShare / totalShare);
  }

  static List<TokenBalanceData?> getAllDexTokens(PluginAcala plugin) {
    final List<TokenBalanceData?> tokens = [];
    plugin.store!.earn.dexPools.forEach((e) {
      e.tokens!.forEach((currencyId) {
        final token = AssetsUtils.tokenDataFromCurrencyId(plugin, currencyId);
        if (tokens.indexWhere((i) => i!.tokenNameId == token.tokenNameId) < 0) {
          tokens.add(token);
        }
      });
    });
    return tokens;
  }

  static BigInt getAccountED(PluginAcala plugin) {
    final nativeED = Fmt.balanceInt(
        plugin.networkConst['balances']['existentialDeposit'].toString());
    final unavailable = Fmt.balanceInt(
            (plugin.balances.native?.reservedBalance ?? 0).toString()) +
        Fmt.balanceInt((plugin.balances.native?.frozenMisc ?? 0).toString());
    return unavailable > nativeED ? BigInt.zero : (nativeED - unavailable);
  }

  static String? getPool(PluginAcala? plugin, dynamic pool) {
    if (pool['dex'] != null) {
      return List.from(pool['dex']['dexShare'])
          .map((e) => AssetsUtils.tokenDataFromCurrencyId(plugin, e).symbol)
          .join('-');
    } else if (pool['loans'] != null) {
      return AssetsUtils.tokenDataFromCurrencyId(plugin, pool['loans'])
          .tokenNameId;
    } else {
      return null;
    }
  }

  static Size boundingTextSize(String text, TextStyle? style) {
    if (text.isEmpty) {
      return Size.zero;
    }
    final TextPainter textPainter = TextPainter(
        textDirection: TextDirection.ltr,
        text: TextSpan(text: text, style: style))
      ..layout();
    return textPainter.size;
  }
}

class LiquidityShareInfo {
  LiquidityShareInfo(this.lp, this.ratio);
  final double lp;
  final double ratio;
}
