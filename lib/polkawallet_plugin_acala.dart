library polkawallet_plugin_acala;

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get_storage/get_storage.dart';
import 'package:polkawallet_plugin_acala/api/acalaApi.dart';
import 'package:polkawallet_plugin_acala/api/acalaService.dart';
import 'package:polkawallet_plugin_acala/common/constants/base.dart';
import 'package:polkawallet_plugin_acala/common/constants/index.dart';
import 'package:polkawallet_plugin_acala/common/constants/nodeList.dart';
import 'package:polkawallet_plugin_acala/pages/acalaEntry.dart';
import 'package:polkawallet_plugin_acala/pages/assets/nativeTokenTransfers.dart';
import 'package:polkawallet_plugin_acala/pages/assets/tokenDetailPage.dart';
import 'package:polkawallet_plugin_acala/pages/assets/transferDetailPage.dart';
import 'package:polkawallet_plugin_acala/pages/assets/transferPage.dart';
import 'package:polkawallet_plugin_acala/pages/currencySelectPage.dart';
import 'package:polkawallet_plugin_acala/pages/earn/LPStakePage.dart';
import 'package:polkawallet_plugin_acala/pages/earn/addLiquidityPage.dart';
import 'package:polkawallet_plugin_acala/pages/earn/earnDetailPage.dart';
import 'package:polkawallet_plugin_acala/pages/earn/earnHistoryPage.dart';
import 'package:polkawallet_plugin_acala/pages/earn/earnPage.dart';
import 'package:polkawallet_plugin_acala/pages/earn/earnTxDetailPage.dart';
import 'package:polkawallet_plugin_acala/pages/earn/withdrawLiquidityPage.dart';
import 'package:polkawallet_plugin_acala/pages/gov/democracy/proposalDetailPage.dart';
import 'package:polkawallet_plugin_acala/pages/gov/democracy/referendumVotePage.dart';
import 'package:polkawallet_plugin_acala/pages/gov/democracyPage.dart';
import 'package:polkawallet_plugin_acala/pages/gov/governance.dart';
import 'package:polkawallet_plugin_acala/pages/homa/homaHistoryPage.dart';
import 'package:polkawallet_plugin_acala/pages/homa/homaPage.dart';
import 'package:polkawallet_plugin_acala/pages/homa/homaTxDetailPage.dart';
import 'package:polkawallet_plugin_acala/pages/homa/mintPage.dart';
import 'package:polkawallet_plugin_acala/pages/homa/redeemPage.dart';
import 'package:polkawallet_plugin_acala/pages/loan/loanAdjustPage.dart';
import 'package:polkawallet_plugin_acala/pages/loan/loanCreatePage.dart';
import 'package:polkawallet_plugin_acala/pages/loan/loanDepositPage.dart';
import 'package:polkawallet_plugin_acala/pages/loan/loanDetailPage.dart';
import 'package:polkawallet_plugin_acala/pages/loan/loanHistoryPage.dart';
import 'package:polkawallet_plugin_acala/pages/loan/loanPage.dart';
import 'package:polkawallet_plugin_acala/pages/loan/loanTxDetailPage.dart';
import 'package:polkawallet_plugin_acala/pages/newUIRoutes.dart';
import 'package:polkawallet_plugin_acala/pages/nft/nftBurnPage.dart';
import 'package:polkawallet_plugin_acala/pages/nft/nftDetailPage.dart';
import 'package:polkawallet_plugin_acala/pages/nft/nftTransferPage.dart';
import 'package:polkawallet_plugin_acala/pages/nft/nfts.dart';
import 'package:polkawallet_plugin_acala/pages/swap/bootstrapPage.dart';
import 'package:polkawallet_plugin_acala/pages/swap/swapDetailPage.dart';
import 'package:polkawallet_plugin_acala/pages/swap/swapHistoryPage.dart';
import 'package:polkawallet_plugin_acala/pages/swap/swapPage.dart';
import 'package:polkawallet_plugin_acala/service/graphql.dart';
import 'package:polkawallet_plugin_acala/service/index.dart';
import 'package:polkawallet_plugin_acala/store/cache/storeCache.dart';
import 'package:polkawallet_plugin_acala/store/index.dart';
import 'package:polkawallet_plugin_acala/utils/InstrumentItemWidget.dart';
import 'package:polkawallet_plugin_acala/utils/InstrumentWidget.dart';
import 'package:polkawallet_plugin_acala/utils/assets.dart';
import 'package:polkawallet_plugin_acala/utils/i18n/index.dart';
import 'package:polkawallet_plugin_acala/utils/types/aggregatedAssetsData.dart';
import 'package:polkawallet_sdk/api/types/networkParams.dart';
import 'package:polkawallet_sdk/plugin/homeNavItem.dart';
import 'package:polkawallet_sdk/plugin/index.dart';
import 'package:polkawallet_sdk/plugin/store/balances.dart';
import 'package:polkawallet_sdk/storage/keyring.dart';
import 'package:polkawallet_sdk/storage/types/keyPairData.dart';
import 'package:polkawallet_sdk/utils/i18n.dart';
import 'package:polkawallet_ui/pages/accountQrCodePage.dart';
import 'package:polkawallet_ui/pages/txConfirmPage.dart';

class PluginAcala extends PolkawalletPlugin {
  PluginAcala({String name = plugin_name_acala})
      : basic = PluginBasicData(
          name: name,
          genesisHash: plugin_genesis_hash,
          ss58: true ? ss58_prefix_acala : 42,
          primaryColor: Colors.indigo,
          gradientColor: Colors.indigoAccent,
          backgroundImage: AssetImage(
              'packages/polkawallet_plugin_acala/assets/images/bg.png'),
          icon: SvgPicture.asset(
              'packages/polkawallet_plugin_acala/assets/images/logo1.svg'),
          iconDisabled: SvgPicture.asset(
            'packages/polkawallet_plugin_acala/assets/images/logo1.svg',
            color: Color(0xFF9E9E9E),
            width: 24,
          ),
          isTestNet: false,
          isXCMSupport: false,
          parachainId: '2000',
          jsCodeVersion: 23301,
        );

  @override
  final PluginBasicData basic;

  @override
  List<NetworkParams> get nodeList {
    return node_list.map((e) => NetworkParams.fromJson(e)).toList();
  }

  Map<String, Widget> _getTokenIcons() {
    final Map<String, Widget> all = {};
    acala_token_ids.forEach((token) {
      all[token] = Image.asset(
          'packages/polkawallet_plugin_acala/assets/images/tokens/$token.png');
    });
    return all;
  }

  @override
  Map<String, Widget> get tokenIcons => _getTokenIcons();

  @override
  List<TokenBalanceData> get noneNativeTokensAll {
    return store?.assets.tokenBalanceMap.values.toList() ?? [];
  }

  @override
  List<HomeNavItem> getNavItems(BuildContext context, Keyring keyring) {
    final dic = I18n.of(context)!.getDic(i18n_full_dic_acala, 'common')!;
    final modulesConfig =
        store?.setting.remoteConfig['modules'] ?? config_modules;
    final nftEnabled = (modulesConfig?.keys.length ?? 0) > 0 &&
        (modulesConfig?['nft'] ?? {})['enabled'] == true;
    return nftEnabled
        ? [
            HomeNavItem(
              text: "Defi",
              icon: Container(),
              iconActive: Container(),
              isAdapter: true,
              content: DefiWidget(this),
            ),
            HomeNavItem(
              text: "NFT",
              icon: Container(),
              iconActive: Container(),
              // content: NFTWidget(this),
              content: NFTs(this, keyring),
            ),
            HomeNavItem(
              text: dic['governance']!,
              icon: Container(),
              iconActive: Container(),
              // content: GovernanceWidget(this),
              content: Gov(this, keyring),
            )
          ]
        : [
            HomeNavItem(
              text: "Defi",
              icon: Container(),
              iconActive: Container(),
              isAdapter: true,
              content: DefiWidget(this),
            ),
            HomeNavItem(
              text: dic['governance']!,
              icon: Container(),
              iconActive: Container(),
              // content: GovernanceWidget(this),
              content: Gov(this, keyring),
            )
          ];
  }

  @override
  Widget? getAggregatedAssetsWidget(
      {String priceCurrency = 'USD',
      bool hideBalance = false,
      double rate = 1.0,
      Function? onSwitchBack,
      Function? onSwitchHideBalance}) {
    if (store == null) return null;

    return Observer(builder: (context) {
      if (store!.assets.aggregatedAssets!.keys.length == 0)
        return InstrumentWidget(
          [InstrumentData(0, []), InstrumentData(0, []), InstrumentData(0, [])],
          onSwitchBack!,
          onSwitchHideBalance!,
          hideBalance: hideBalance,
        );
      final Map<String, double> marketPrices = Map<String, double>();
      store!.assets.marketPrices.forEach((key, value) {
        marketPrices[key] = value * rate;
      });

      final data = AssetsUtils.aggregatedAssetsDataFromJson(
          store!.assets.aggregatedAssets!, balances, marketPrices);
      // // data.forEach((element) => print(element));
      // final total = data.map((e) => e.value).reduce((a, b) => a + b);
      // return Text('total: ${hideBalance ? '***' : total}');
      return InstrumentWidget(
        instrumentData(data, context, priceCurrency: priceCurrency),
        onSwitchBack!,
        onSwitchHideBalance!,
        hideBalance: hideBalance,
      );
    });
  }

  List<InstrumentData> instrumentData(
      List<AggregatedAssetsData> data, BuildContext context,
      {String priceCurrency = 'USD'}) {
    final List<InstrumentData> datas = [];
    InstrumentData totalBalance1 = InstrumentData(0, [],
        title: I18n.of(context)!
            .getDic(i18n_full_dic_acala, 'acala')!["v3.myDefi"]!);
    datas.add(totalBalance1);

    final total = data.map((e) => e.value).reduce((a, b) => a! + b!);
    InstrumentData totalBalance = InstrumentData(total ?? 0, [],
        currencySymbol: _currencySymbol(priceCurrency),
        title: I18n.of(context)!
            .getDic(i18n_full_dic_acala, 'acala')!["v3.myDefi"]!);
    data.forEach((element) {
      totalBalance.items.add(InstrumentItemData(
          _instrumentColor(element.category),
          element.category!,
          element.value!,
          _instrumentIconName(element.category)));
    });
    datas.add(totalBalance);
    datas.add(totalBalance1);
    return datas;
  }

  String _currencySymbol(String priceCurrency) {
    switch (priceCurrency) {
      case "USD":
        return "\$";
      case "CNY":
        return "￥";
      default:
        return "\$";
    }
  }

  Color _instrumentColor(String? category) {
    switch (category) {
      case "Tokens":
        return Color(0xFF5E5C59);
      case "Vaults":
        return Color(0xFFCE623C);
      case "LP Staking":
        return Color(0xFF768FE1);
      case "Rewards":
        return Color(0xFFFFC952);
      default:
        return Color(0xFFFFC952);
    }
  }

  String _instrumentIconName(String? category) {
    switch (category) {
      case "Tokens":
        return "packages/polkawallet_plugin_acala/assets/images/icon_instrument_black.png";
      case "Vaults":
        return "packages/polkawallet_plugin_acala/assets/images/icon_instrument_orange.png";
      case "LP Staking":
        return "packages/polkawallet_plugin_acala/assets/images/icon_instrument_blue.png";
      case "Rewards":
        return "packages/polkawallet_plugin_acala/assets/images/icon_instrument_yellow.png";
      default:
        return "packages/polkawallet_plugin_acala/assets/images/icon_instrument_yellow.png";
    }
  }

  @override
  Widget? getNativeTokenTransfers(
      {required String address, int transferType = 0}) {
    return NativeTokenTransfers(this, address, transferType);
  }

  @override
  Map<String, WidgetBuilder> getRoutes(Keyring keyring) {
    return {
      TxConfirmPage.route: (_) => TxConfirmPage(
          this,
          keyring,
          _service!.getPassword as Future<String> Function(
              BuildContext, KeyPairData)),
      CurrencySelectPage.route: (_) => CurrencySelectPage(this),
      AccountQrCodePage.route: (_) => AccountQrCodePage(this, keyring),

      TokenDetailPage.route: (_) => ClientProvider(
            child: Builder(
              builder: (_) => TokenDetailPage(this, keyring),
            ),
            uri: GraphQLConfig['httpUri']!,
          ),
      TransferPage.route: (_) => TransferPage(this, keyring),
      TransferDetailPage.route: (_) => TransferDetailPage(this, keyring),

      // loan pages
      LoanPage.route: (_) => LoanPage(this, keyring),
      LoanDetailPage.route: (_) => LoanDetailPage(this, keyring),
      LoanTxDetailPage.route: (_) => LoanTxDetailPage(this, keyring),
      LoanCreatePage.route: (_) => LoanCreatePage(this, keyring),
      LoanAdjustPage.route: (_) => LoanAdjustPage(this, keyring),
      LoanDepositPage.route: (_) => LoanDepositPage(this, keyring),
      LoanHistoryPage.route: (_) => ClientProvider(
            child: Builder(
              builder: (_) => LoanHistoryPage(this, keyring),
            ),
            uri: GraphQLConfig['httpUri']!,
          ),
      // swap pages
      SwapPage.route: (_) => SwapPage(this, keyring),
      SwapHistoryPage.route: (_) => ClientProvider(
            child: Builder(
              builder: (_) => SwapHistoryPage(this, keyring),
            ),
            uri: GraphQLConfig['httpUri']!,
          ),
      SwapDetailPage.route: (_) => SwapDetailPage(this, keyring),
      BootstrapPage.route: (_) => BootstrapPage(this, keyring),
      // earn pages
      EarnPage.route: (_) => EarnPage(this, keyring),
      EarnDetailPage.route: (_) => EarnDetailPage(this, keyring),
      EarnHistoryPage.route: (_) => ClientProvider(
            child: Builder(
              builder: (_) => EarnHistoryPage(this, keyring),
            ),
            uri: GraphQLConfig['httpUri']!,
          ),
      EarnTxDetailPage.route: (_) => EarnTxDetailPage(this, keyring),
      LPStakePage.route: (_) => LPStakePage(this, keyring),
      AddLiquidityPage.route: (_) => AddLiquidityPage(this, keyring),
      WithdrawLiquidityPage.route: (_) => WithdrawLiquidityPage(this, keyring),
      // homa pages
      HomaPage.route: (_) => HomaPage(this, keyring),
      MintPage.route: (_) => MintPage(this, keyring),
      RedeemPage.route: (_) => RedeemPage(this, keyring),
      HomaHistoryPage.route: (_) => ClientProvider(
            child: Builder(
              builder: (_) => HomaHistoryPage(this, keyring),
            ),
            uri: GraphQLConfig['httpUri']!,
          ),
      HomaTxDetailPage.route: (_) => HomaTxDetailPage(this, keyring),
      // NFT pages
      NFTDetailPage.route: (_) => NFTDetailPage(this, keyring),
      NFTTransferPage.route: (_) => NFTTransferPage(this, keyring),
      NFTBurnPage.route: (_) => NFTBurnPage(this, keyring),
      // Gov pages
      DemocracyPage.route: (_) => DemocracyPage(this, keyring),
      ReferendumVotePage.route: (_) => ReferendumVotePage(this, keyring),
      ProposalDetailPage.route: (_) => ProposalDetailPage(this, keyring),

      AcalaEntry.route: (_) => AcalaEntry(this, keyring),
      //new ui
      ...getNewUiRoutes(this, keyring)
    };
  }

  @override
  Future<String> loadJSCode() => rootBundle.loadString(
      'packages/polkawallet_plugin_acala/lib/js_service_acala/dist/main.js');

  AcalaApi? _api;
  AcalaApi? get api => _api;

  StoreCache? _cache;
  PluginStore? _store;
  PluginService? _service;
  PluginStore? get store => _store;
  PluginService? get service => _service;

  Future<void> _subscribeTokenBalances(KeyPairData acc) async {
    _api!.assets.subscribeTokenBalances(acc.address, (data) {
      _store!.assets.setTokenBalanceMap(data, acc.pubKey);

      balances.setTokens(data);
    });

    _service!.assets.queryAggregatedAssets();

    _subscribeOraclePricesWithLoans(acc);

    final nft = await _api!.assets.queryNFTs(acc.address);
    if (nft != null) {
      _store!.assets.setNFTs(nft);
    }
  }

  // we use this oracle price for lcDOT value calculation
  Future<void> _subscribeOraclePricesWithLoans(KeyPairData acc) async {
    await _service?.loan.queryLoanTypes(acc.address);
    _service?.loan.subscribeAccountLoans(acc.address);
  }

  void _loadCacheData(KeyPairData acc) {
    balances.setExtraTokens([]);
    _store!.assets.setNFTs([]);

    try {
      loadBalances(acc);

      _store!.assets.loadCache(acc.pubKey);
      final tokens = _store!.assets.tokenBalanceMap.values.toList();
      final tokensConfig =
          service!.plugin.store!.setting.remoteConfig['tokens'] ?? {};
      if (tokensConfig['invisible'] != null) {
        final invisible = List.of(tokensConfig['invisible']);
        if (invisible.length > 0) {
          tokens.removeWhere(
              (token) => invisible.contains(token.symbol?.toUpperCase()));
        }
      }
      balances.setTokens(tokens, isFromCache: true);

      _store!.loan.loadCache(acc.pubKey);
      _store!.swap.loadCache(acc.pubKey);
      _store!.earn.setDexPoolInfo({}, reset: true);
      _store!.earn.setBootstraps([]);
      _store!.homa.setUserInfo(null);
      print('acala plugin cache data loaded');
    } catch (err) {
      print(err);
      print('load acala cache data failed');
    }
  }

  @override
  Future<void> onWillStart(Keyring keyring) async {
    _api = AcalaApi(AcalaService(this));

    await GetStorage.init(plugin_cache_key);

    _cache = StoreCache();
    _store = PluginStore(_cache);
    _service = PluginService(this, keyring);

    _loadCacheData(keyring.current);

    // fetch tokens config here for subscribe all tokens balances
    _service!.fetchRemoteConfig();
  }

  @override
  Future<void> onStarted(Keyring keyring) async {
    _service!.connected = true;

    if (keyring.current.address != null) {
      _subscribeTokenBalances(keyring.current);
    }
  }

  @override
  Future<void> onAccountChanged(KeyPairData acc) async {
    _loadCacheData(acc);

    if (_service!.connected) {
      _api!.assets.unsubscribeTokenBalances(acc.address);
      _service?.loan.unsubscribeAccountLoans();

      _subscribeTokenBalances(acc);
    }
  }

  @override
  Future<void> dispose() async {
    _service?.loan.unsubscribeAccountLoans();
  }
}
