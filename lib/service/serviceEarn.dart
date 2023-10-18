import 'package:polkawallet_plugin_acala/api/acalaApi.dart';
import 'package:polkawallet_plugin_acala/api/earn/types/incentivesData.dart';
import 'package:polkawallet_plugin_acala/api/types/dexPoolInfoData.dart';
import 'package:polkawallet_plugin_acala/polkawallet_plugin_acala.dart';
import 'package:polkawallet_plugin_acala/store/index.dart';
import 'package:polkawallet_plugin_acala/utils/assets.dart';
import 'package:polkawallet_sdk/storage/keyring.dart';
import 'package:polkawallet_ui/utils/format.dart';

class ServiceEarn {
  ServiceEarn(this.plugin, this.keyring)
      : api = plugin.api,
        store = plugin.store;

  final PluginAcala plugin;
  final Keyring keyring;
  final AcalaApi? api;
  final PluginStore? store;

  IncentivesData _calcIncentivesAPR(IncentivesData data) {
    /// the APY calc with block duration 12000, but other data use 12500.
    /// so we need to do (* 125 / 120) for APY.
    final pools = plugin.store!.earn.dexPools.toList();
    data.dex!.forEach((k, v) {
      final poolIndex = pools.indexWhere((e) => e.tokenNameId == k);
      if (poolIndex < 0) {
        return;
      }
      final pool = pools[poolIndex];
      final balancePair = pool.tokens!
          .map((e) => AssetsUtils.tokenDataFromCurrencyId(plugin, e))
          .toList();

      final poolInfo = store!.earn.dexPoolInfoMap[k];

      /// poolValue = LPAmountOfPool / LPIssuance * token0Issuance * token0Price * 2;
      final stakingPoolValue = (poolInfo?.sharesTotal ?? BigInt.zero) /
          (poolInfo?.issuance ?? BigInt.zero) *
          (Fmt.bigIntToDouble(
                      poolInfo?.amountLeft, balancePair[0].decimals ?? 12) *
                  AssetsUtils.getMarketPrice(
                      plugin, balancePair[0].symbol ?? '') +
              Fmt.bigIntToDouble(
                      poolInfo?.amountRight, balancePair[1].decimals ?? 12) *
                  AssetsUtils.getMarketPrice(
                      plugin, balancePair[1].symbol ?? ''));

      v.forEach((e) {
        final rewardToken =
            AssetsUtils.getBalanceFromTokenNameId(plugin, e.tokenNameId);

        /// rewardsRate = rewardsAmount * rewardsTokenPrice / poolValue;
        final rate = e.amount! *
            AssetsUtils.getMarketPrice(plugin, rewardToken.symbol ?? '') /
            stakingPoolValue;
        e.apr = rate > 0 ? rate * 125 / 120 : 0;
      });
    });

    final rewards = plugin.store!.loan.collateralRewards;
    data.loans!.forEach((k, v) {
      v.forEach((e) {
        if (e.tokenNameId != 'Any') {
          final poolToken = AssetsUtils.getBalanceFromTokenNameId(plugin, k);
          final rewardToken =
              AssetsUtils.getBalanceFromTokenNameId(plugin, e.tokenNameId);
          e.apr = AssetsUtils.getMarketPrice(plugin, rewardToken.symbol ?? '') *
              e.amount! /
              Fmt.bigIntToDouble(
                  rewards[k]?.sharesTotal, poolToken.decimals ?? 12) /
              AssetsUtils.getMarketPrice(plugin, poolToken.symbol ?? '') *
              125 /
              120;
        }
      });
    });

    return data;
  }

  Future<List<DexPoolData>> getDexPools() async {
    final pools = await api!.swap.getTokenPairs();
    store!.earn.setDexPools(pools);
    return pools;
  }

  Future<List<DexPoolData>> getBootstraps() async {
    final pools = await api!.swap.getBootstraps();
    store!.earn.setBootstraps(pools);
    return pools;
  }

  Future<void> queryIncentives() async {
    final res = await Future.wait([
      api!.earn.queryIncentives(),
      // we need collateral rewards data to calc incentive apy.
      plugin.service!.loan.queryCollateralRewards(keyring.current.address!),
    ]);

    store!.earn.setIncentives(_calcIncentivesAPR((res[0] as IncentivesData)));
  }

  Future<void> queryDexPoolInfo() async {
    final info = await api!.swap.queryDexPoolInfo(keyring.current.address);
    store!.earn.setDexPoolInfo(info);
  }

  double? getSwapFee() {
    return plugin.networkConst['dex']['getExchangeFee'][0] /
        plugin.networkConst['dex']['getExchangeFee'][1];
  }

  Future<void> updateAllDexPoolInfo() async {
    if (store!.earn.dexPools.length == 0) {
      await getDexPools();
    }

    await queryDexPoolInfo();
    plugin.service!.assets.queryMarketPrices();

    queryIncentives();
  }

  Future<void> getDexIncentiveLoyaltyEndBlock() async {
    if (store!.earn.dexIncentiveLoyaltyEndBlock.isEmpty) {
      store!.earn.setDexIncentiveLoyaltyEndBlock(
          await plugin.api!.earn.queryDexIncentiveLoyaltyEndBlock());
    }
  }

  Future<void> getBlockDuration() async {
    store!.earn.setBlockDuration(await plugin.api!.earn.getBlockDuration());
  }
}
