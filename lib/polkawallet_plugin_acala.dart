library polkawallet_plugin_acala;

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get_storage/get_storage.dart';
import 'package:polkawallet_plugin_acala/api/acalaApi.dart';
import 'package:polkawallet_plugin_acala/api/acalaService.dart';
import 'package:polkawallet_plugin_acala/common/constants.dart';
import 'package:polkawallet_plugin_acala/pages/acalaEntry.dart';
import 'package:polkawallet_plugin_acala/pages/assets/tokenDetailPage.dart';
import 'package:polkawallet_plugin_acala/pages/assets/transferPage.dart';
import 'package:polkawallet_plugin_acala/pages/currencySelectPage.dart';
import 'package:polkawallet_plugin_acala/pages/earn/LPStakePage.dart';
import 'package:polkawallet_plugin_acala/pages/earn/addLiquidityPage.dart';
import 'package:polkawallet_plugin_acala/pages/earn/earnHistoryPage.dart';
import 'package:polkawallet_plugin_acala/pages/earn/earnPage.dart';
import 'package:polkawallet_plugin_acala/pages/earn/withdrawLiquidityPage.dart';
import 'package:polkawallet_plugin_acala/pages/homa/homaHistoryPage.dart';
import 'package:polkawallet_plugin_acala/pages/homa/homaPage.dart';
import 'package:polkawallet_plugin_acala/pages/homa/mintPage.dart';
import 'package:polkawallet_plugin_acala/pages/homa/redeemPage.dart';
import 'package:polkawallet_plugin_acala/pages/loan/loanAdjustPage.dart';
import 'package:polkawallet_plugin_acala/pages/loan/loanCreatePage.dart';
import 'package:polkawallet_plugin_acala/pages/loan/loanHistoryPage.dart';
import 'package:polkawallet_plugin_acala/pages/loan/loanPage.dart';
import 'package:polkawallet_plugin_acala/pages/nft/nftPage.dart';
import 'package:polkawallet_plugin_acala/pages/swap/swapHistoryPage.dart';
import 'package:polkawallet_plugin_acala/pages/swap/swapPage.dart';
import 'package:polkawallet_plugin_acala/service/index.dart';
import 'package:polkawallet_plugin_acala/store/cache/storeCache.dart';
import 'package:polkawallet_plugin_acala/store/index.dart';
import 'package:polkawallet_sdk/api/types/networkParams.dart';
import 'package:polkawallet_sdk/plugin/homeNavItem.dart';
import 'package:polkawallet_sdk/plugin/index.dart';
import 'package:polkawallet_sdk/plugin/store/balances.dart';
import 'package:polkawallet_sdk/storage/keyring.dart';
import 'package:polkawallet_sdk/storage/types/keyPairData.dart';
import 'package:polkawallet_ui/pages/accountQrCodePage.dart';
import 'package:polkawallet_ui/pages/txConfirmPage.dart';

class PluginAcala extends PolkawalletPlugin {
  @override
  final basic = PluginBasicData(
    name: 'acala-tc6',
    ss58: 42,
    primaryColor: Colors.indigo,
    gradientColor: Color(0xFF4B68F9),
    backgroundImage:
        AssetImage('packages/polkawallet_plugin_acala/assets/images/bg.png'),
    icon:
        Image.asset('packages/polkawallet_plugin_acala/assets/images/logo.png'),
    iconDisabled: Image.asset(
        'packages/polkawallet_plugin_acala/assets/images/logo_gray.png'),
    jsCodeVersion: 20101,
  );

  @override
  List<NetworkParams> get nodeList {
    return node_list.map((e) => NetworkParams.fromJson(e)).toList();
  }

  Map<String, Widget> _basicIcons = {
    'KAR': Image.asset(
        'packages/polkawallet_plugin_acala/assets/images/tokens/KAR.png'),
    'ACA': Image.asset(
        'packages/polkawallet_plugin_acala/assets/images/tokens/ACA.png'),
    'AUSD': Image.asset(
        'packages/polkawallet_plugin_acala/assets/images/tokens/AUSD.png'),
    'KUSD': Image.asset(
        'packages/polkawallet_plugin_acala/assets/images/tokens/KUSD.png'),
    'DOT': Image.asset(
        'packages/polkawallet_plugin_acala/assets/images/tokens/DOT.png'),
    'LDOT': Image.asset(
        'packages/polkawallet_plugin_acala/assets/images/tokens/LDOT.png'),
    'KSM': Image.asset(
        'packages/polkawallet_plugin_acala/assets/images/tokens/KSM.png'),
    'LKSM': Image.asset(
        'packages/polkawallet_plugin_acala/assets/images/tokens/LKSM.png'),
    'RENBTC': Image.asset(
        'packages/polkawallet_plugin_acala/assets/images/tokens/RENBTC.png'),
    'XBTC': Image.asset(
        'packages/polkawallet_plugin_acala/assets/images/tokens/XBTC.png'),
    'POLKABTC': Image.asset(
        'packages/polkawallet_plugin_acala/assets/images/tokens/POLKABTC.png'),
    'PLM': Image.asset(
        'packages/polkawallet_plugin_acala/assets/images/tokens/PLM.png'),
    'PHA': Image.asset(
        'packages/polkawallet_plugin_acala/assets/images/tokens/PHA.png'),
  };

  @override
  Map<String, Widget> get tokenIcons => {
        ..._basicIcons,
        'AUSD-DOT': TokenIcon('AUSD-DOT', _basicIcons),
        'AUSD-LDOT': TokenIcon('AUSD-LDOT', _basicIcons),
        'AUSD-XBTC': TokenIcon('AUSD-XBTC', _basicIcons),
        'AUSD-RENBTC': TokenIcon('AUSD-RENBTC', _basicIcons),
        'AUSD-POLKABTC': TokenIcon('AUSD-POLKABTC', _basicIcons),
        'AUSD-PHA': TokenIcon('AUSD-PHA', _basicIcons),
        'AUSD-PLM': TokenIcon('AUSD-PLM', _basicIcons),
        'ACA-AUSD': TokenIcon('ACA-AUSD', _basicIcons),
      };

  @override
  List<HomeNavItem> getNavItems(BuildContext context, Keyring keyring) {
    return [
      HomeNavItem(
        text: 'Acala',
        icon: SvgPicture.asset(
          'packages/polkawallet_plugin_acala/assets/images/logo.svg',
          color: Theme.of(context).disabledColor,
        ),
        iconActive: SvgPicture.asset(
            'packages/polkawallet_plugin_acala/assets/images/logo.svg'),
        content: AcalaEntry(this, keyring),
      )
    ];
  }

  @override
  Map<String, WidgetBuilder> getRoutes(Keyring keyring) {
    return {
      TxConfirmPage.route: (_) =>
          TxConfirmPage(this, keyring, _service.getPassword),
      CurrencySelectPage.route: (_) => CurrencySelectPage(this),
      AccountQrCodePage.route: (_) => AccountQrCodePage(this, keyring),

      TokenDetailPage.route: (_) => TokenDetailPage(this, keyring),
      TransferPage.route: (_) => TransferPage(this, keyring),

      // loan pages
      LoanPage.route: (_) => LoanPage(this, keyring),
      LoanCreatePage.route: (_) => LoanCreatePage(this, keyring),
      LoanAdjustPage.route: (_) => LoanAdjustPage(this, keyring),
      LoanHistoryPage.route: (_) => LoanHistoryPage(this, keyring),
      // swap pages
      SwapPage.route: (_) => SwapPage(this, keyring),
      SwapHistoryPage.route: (_) => SwapHistoryPage(this, keyring),
      // earn pages
      EarnPage.route: (_) => EarnPage(this, keyring),
      EarnHistoryPage.route: (_) => EarnHistoryPage(this, keyring),
      LPStakePage.route: (_) => LPStakePage(this, keyring),
      AddLiquidityPage.route: (_) => AddLiquidityPage(this, keyring),
      WithdrawLiquidityPage.route: (_) => WithdrawLiquidityPage(this, keyring),
      // homa pages
      HomaPage.route: (_) => HomaPage(this, keyring),
      MintPage.route: (_) => MintPage(this, keyring),
      HomaRedeemPage.route: (_) => HomaRedeemPage(this, keyring),
      HomaHistoryPage.route: (_) => HomaHistoryPage(this, keyring),
      // NFT pages
      NFTPage.route: (_) => NFTPage(this, keyring),
    };
  }

  @override
  Future<String> loadJSCode() => rootBundle.loadString(
      'packages/polkawallet_plugin_acala/lib/js_service_acala/dist/main.js');

  AcalaApi _api;
  AcalaApi get api => _api;

  final StoreCache _cache = StoreCache();
  PluginStore _store;
  PluginService _service;
  PluginStore get store => _store;
  PluginService get service => _service;

  Future<void> _subscribeTokenBalances(KeyPairData acc) async {
    _api.assets.subscribeTokenBalances(basic.name, acc.address, (data) {
      _store.assets.setTokenBalanceMap(data, acc.pubKey);

      _updateTokenBalances(data);
    });

    final airdrops = await _api.assets.queryAirdropTokens(acc.address);
    balances
        .setExtraTokens([ExtraTokenData(title: 'Airdrop', tokens: airdrops)]);

    final nft = await _api.assets.queryNFTs(acc.address);
    _store.assets.setNFTs(nft);
  }

  void _updateTokenBalances(List<TokenBalanceData> data) {
    data.removeWhere((e) => e.symbol.contains('-') && e.amount == '0');
    balances.setTokens(data);
  }

  void _loadCacheData(KeyPairData acc) {
    balances.setExtraTokens([]);
    _store.assets.setNFTs([]);

    try {
      _store.assets.loadCache(acc.pubKey);
      _updateTokenBalances(_store.assets.tokenBalanceMap.values.toList());

      _store.loan.loadCache(acc.pubKey);
      _store.swap.loadCache(acc.pubKey);
      _store.earn.loadCache(acc.pubKey);
      _store.homa.loadCache(acc.pubKey);
      print('acala plugin cache data loaded');
    } catch (err) {
      print(err);
      print('load acala cache data failed');
    }
  }

  @override
  Future<void> onWillStart(Keyring keyring) async {
    _api = AcalaApi(AcalaService(this));

    await GetStorage.init(acala_plugin_cache_key);

    _store = PluginStore(_cache);
    _loadCacheData(keyring.current);

    _service = PluginService(this, keyring);
  }

  @override
  Future<void> onStarted(Keyring keyring) async {
    _service.connected = true;

    if (keyring.current.address != null) {
      _subscribeTokenBalances(keyring.current);
    }
  }

  @override
  Future<void> onAccountChanged(KeyPairData acc) async {
    _loadCacheData(acc);

    if (_service.connected) {
      _api.assets.unsubscribeTokenBalances(basic.name, acc.address);
      _subscribeTokenBalances(acc);
    }
  }
}
