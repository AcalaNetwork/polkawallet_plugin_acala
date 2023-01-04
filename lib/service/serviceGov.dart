import 'package:polkawallet_plugin_acala/polkawallet_plugin_acala.dart';
import 'package:polkawallet_plugin_acala/service/walletApi.dart';
import 'package:polkawallet_plugin_acala/store/index.dart';
import 'package:polkawallet_sdk/api/api.dart';
import 'package:polkawallet_sdk/api/types/gov/proposalInfoData.dart';
import 'package:polkawallet_sdk/api/types/gov/treasuryOverviewData.dart';
import 'package:polkawallet_sdk/storage/keyring.dart';

class ServiceGov {
  ServiceGov(this.plugin, this.keyring)
      : api = plugin.sdk.api,
        store = plugin.store;

  final PluginAcala plugin;
  final Keyring keyring;
  final PolkawalletApi api;
  final PluginStore? store;

  Future<void> updateIconsAndIndices(List addresses) async {
    final ls = addresses.toList();
    ls.removeWhere((e) => store!.accounts.addressIconsMap.keys.contains(e));

    final List<List?> res = await Future.wait([
      api.account.getAddressIcons(ls),
      // api.account.queryIndexInfo(ls),
    ]);
    store!.accounts.setAddressIconsMap(res[0]!);
    // store!.accounts.setAddressIndex(res[1]!);
  }

  Future<void> subscribeBestNumber() async {
    api.setting.subscribeBestNumber((bestNum) {
      store!.gov.setBestNumber(BigInt.parse(bestNum.toString()));
    });
  }

  Future<void> unsubscribeBestNumber() async {
    api.setting.unsubscribeBestNumber();
  }

  Future<void> updateBestNumber() async {
    final bestNumber = await api.service.webView!
        .evalJavascript('api.derive.chain.bestNumber()');
    store!.gov.setBestNumber(BigInt.parse(bestNumber.toString()));
  }

  Future<List?> getReferendumVoteConvictions() async {
    final List? res = await api.gov.getReferendumVoteConvictions();
    store!.gov.setReferendumVoteConvictions(res);
    return res;
  }

  Future<List> queryReferendums() async {
    final data = await api.gov.queryReferendums(keyring.current.address!);
    store!.gov.setReferendums(data);
    return data;
  }

  Future<List> queryProposals() async {
    final data = await api.gov.queryProposals();
    store!.gov.setProposals(data);

    final List<String?> addresses = [];
    data.forEach((e) {
      addresses.add(e.proposer);
      addresses.addAll(e.seconds!);
    });
    updateIconsAndIndices(addresses);

    return data;
  }

  Future<void> queryReferendumStatus(List<int> ids) async {
    final data = await Future.wait(
        ids.map((e) => WalletApi.getDemocracyReferendumInfo(e)).toList());
    final res = {};
    data.forEach((e) {
      if ((e ?? {})['data'] != null) {
        final id = (e ?? {})['data']['info']['referendum_index'];
        res[id] = (e ?? {})['data']['info']['status'];
      }
    });
    store!.gov.setReferendumStatus(res);
  }

  Future<ProposalInfoData?> queryExternal() async {
    final data = await api.gov.queryNextExternal();

    if (data != null) {
      store!.gov.setExternal(data);

      updateIconsAndIndices([data.image!.proposer!]);
    }
    return data;
  }

  Future<TreasuryOverviewData> queryTreasuryOverview() async {
    final data = await api.gov.queryTreasuryOverview();
    store!.gov.setTreasuryOverview(data);

    final List<String?> addresses = [];
    final List<SpendProposalData> allProposals =
        store!.gov.treasuryOverview.proposals!.toList();
    allProposals.addAll(store!.gov.treasuryOverview.approvals!);
    allProposals.forEach((e) {
      addresses.add(e.proposal!.proposer);
      addresses.add(e.proposal!.beneficiary);
    });
    updateIconsAndIndices(addresses);

    return data;
  }

  Future<List> queryTreasuryTips() async {
    final data = await api.gov.queryTreasuryTips();
    store!.gov.setTreasuryTips(data);

    List<String?> addresses = [];
    store!.gov.treasuryTips.toList().forEach((e) {
      addresses.add(e.who);
      if (e.finder != null) {
        addresses.add(e.finder);
      }
    });
    updateIconsAndIndices(addresses);

    return data;
  }
}
