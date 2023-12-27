import 'package:flutter/material.dart';
import 'package:polkawallet_plugin_acala/pages/earnNew/LPStakePage.dart';
import 'package:polkawallet_plugin_acala/pages/earnNew/addLiquidityPage.dart';
import 'package:polkawallet_plugin_acala/pages/earnNew/earnDetailPage.dart';
import 'package:polkawallet_plugin_acala/pages/earnNew/earnHistoryPage.dart';
import 'package:polkawallet_plugin_acala/pages/earnNew/earnPage.dart';
import 'package:polkawallet_plugin_acala/pages/earnNew/earnTaigaDetailPage.dart';
import 'package:polkawallet_plugin_acala/pages/earnNew/earnTxDetailPage.dart';
import 'package:polkawallet_plugin_acala/pages/earnNew/inviteFriendsPage.dart';
import 'package:polkawallet_plugin_acala/pages/earnNew/taigaAddLiquidityPage.dart';
import 'package:polkawallet_plugin_acala/pages/earnNew/taigaWithdrawLiquidityPage.dart';
import 'package:polkawallet_plugin_acala/pages/earnNew/withdrawLiquidityPage.dart';
import 'package:polkawallet_plugin_acala/pages/governanceNew/governancePage.dart';
import 'package:polkawallet_plugin_acala/pages/governanceNew/referendumVotePage.dart';
import 'package:polkawallet_plugin_acala/pages/homaNew/completedPage.dart';
import 'package:polkawallet_plugin_acala/pages/homaNew/homaHistoryPage.dart';
import 'package:polkawallet_plugin_acala/pages/homaNew/homaPage.dart';
import 'package:polkawallet_plugin_acala/pages/homaNew/homaTxDetailPage.dart';
import 'package:polkawallet_plugin_acala/pages/homaNew/mintPage.dart';
import 'package:polkawallet_plugin_acala/pages/homaNew/redeemPage.dart';
import 'package:polkawallet_plugin_acala/pages/loanNew/loanAdjustPage.dart';
import 'package:polkawallet_plugin_acala/pages/loanNew/loanCreatePage.dart';
import 'package:polkawallet_plugin_acala/pages/loanNew/loanDepositPage.dart';
import 'package:polkawallet_plugin_acala/pages/loanNew/loanHistoryPage.dart';
import 'package:polkawallet_plugin_acala/pages/loanNew/loanPage.dart';
import 'package:polkawallet_plugin_acala/pages/loanNew/loanTxDetailPage.dart';
import 'package:polkawallet_plugin_acala/pages/nftNew/nftPage.dart';
import 'package:polkawallet_plugin_acala/pages/nftNew/nftTransferPage.dart';
import 'package:polkawallet_plugin_acala/pages/swapNew/bootstrapPage.dart';
import 'package:polkawallet_plugin_acala/pages/swapNew/swapDetailPage.dart';
import 'package:polkawallet_plugin_acala/pages/swapNew/swapHistoryPage.dart';
import 'package:polkawallet_plugin_acala/pages/swapNew/swapPage.dart';
import 'package:polkawallet_plugin_acala/polkawallet_plugin_acala.dart';
import 'package:polkawallet_sdk/storage/keyring.dart';

Map<String, WidgetBuilder> getNewUiRoutes(PluginAcala plugin, Keyring keyring) {
  /// use new pages in testnet for now.
  final isTest = true;
  return isTest
      ? {
          //homa
          HomaPage.route: (_) => HomaPage(plugin, keyring),
          MintPage.route: (_) => MintPage(plugin, keyring),
          RedeemPage.route: (_) => RedeemPage(plugin, keyring),
          HomaHistoryPage.route: (_) => HomaHistoryPage(plugin, keyring),

          HomaTxDetailPage.route: (_) => HomaTxDetailPage(plugin, keyring),
          CompletedPage.route: (_) => CompletedPage(plugin),

          //loan
          LoanPage.route: (_) => LoanPage(plugin, keyring),
          LoanCreatePage.route: (_) => LoanCreatePage(plugin, keyring),
          LoanHistoryPage.route: (_) => LoanHistoryPage(plugin, keyring),
          LoanDepositPage.route: (_) => LoanDepositPage(plugin, keyring),
          LoanTxDetailPage.route: (_) => LoanTxDetailPage(plugin, keyring),
          LoanAdjustPage.route: (_) => LoanAdjustPage(plugin, keyring),

          //swap
          SwapPage.route: (_) => SwapPage(plugin, keyring),
          SwapHistoryPage.route: (_) => SwapHistoryPage(plugin, keyring),
          BootstrapPage.route: (_) => BootstrapPage(plugin, keyring),
          SwapDetailPage.route: (_) => SwapDetailPage(plugin, keyring),

          //earn
          EarnPage.route: (_) => EarnPage(plugin, keyring),
          AddLiquidityPage.route: (_) => AddLiquidityPage(plugin, keyring),
          WithdrawLiquidityPage.route: (_) =>
              WithdrawLiquidityPage(plugin, keyring),
          EarnHistoryPage.route: (_) => EarnHistoryPage(plugin, keyring),
          EarnDetailPage.route: (_) => EarnDetailPage(plugin, keyring),
          LPStakePage.route: (_) => LPStakePage(plugin, keyring),
          InviteFriendsPage.route: (_) => InviteFriendsPage(plugin, keyring),
          EarnTxDetailPage.route: (_) => EarnTxDetailPage(plugin, keyring),
          EarnTaigaDetailPage.route: (_) =>
              EarnTaigaDetailPage(plugin, keyring),
          TaigaAddLiquidityPage.route: (_) =>
              TaigaAddLiquidityPage(plugin, keyring),
          TaigaWithdrawLiquidityPage.route: (_) =>
              TaigaWithdrawLiquidityPage(plugin, keyring),

          //nft
          NftPage.route: (_) => NftPage(plugin, keyring),
          NFTTransferPage.route: (_) => NFTTransferPage(plugin, keyring),

          //governanceNew
          GovernancePage.route: (_) => GovernancePage(plugin, keyring),
          ReferendumVotePage.route: (_) => ReferendumVotePage(plugin, keyring),
        }
      : {};
}
