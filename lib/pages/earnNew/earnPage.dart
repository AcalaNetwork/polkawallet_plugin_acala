import 'package:flutter/material.dart';
import 'package:polkawallet_plugin_acala/pages/earnNew/earnDexList.dart';
import 'package:polkawallet_plugin_acala/pages/earnNew/earnHistoryPage.dart';
import 'package:polkawallet_plugin_acala/pages/earnNew/earnLoanList.dart';
import 'package:polkawallet_plugin_acala/pages/earnNew/earnTaigaList.dart';
import 'package:polkawallet_plugin_acala/pages/types/earnPageParams.dart';
import 'package:polkawallet_plugin_acala/polkawallet_plugin_acala.dart';
import 'package:polkawallet_plugin_acala/utils/i18n/index.dart';
import 'package:polkawallet_sdk/storage/keyring.dart';
import 'package:polkawallet_sdk/utils/i18n.dart';
import 'package:polkawallet_ui/components/connectionChecker.dart';
import 'package:polkawallet_ui/components/v3/plugin/pluginAccountInfoAction.dart';
import 'package:polkawallet_ui/components/v3/plugin/pluginIconButton.dart';
import 'package:polkawallet_ui/components/v3/plugin/pluginPageTitleTaps.dart';
import 'package:polkawallet_ui/components/v3/plugin/pluginScaffold.dart';

class EarnPage extends StatefulWidget {
  EarnPage(this.plugin, this.keyring);
  final PluginAcala plugin;
  final Keyring keyring;

  static const String route = '/acala/earn';

  @override
  _EarnPageState createState() => _EarnPageState();
}

class _EarnPageState extends State<EarnPage> {
  int _tab = 0;

  Future<void> _fetchData() async {
    widget.plugin.service!.earn.getDexIncentiveLoyaltyEndBlock();
  }

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final argsJson = ModalRoute.of(context)!.settings.arguments as Map? ?? {};
      final args = EarnPageParams.fromJson(argsJson);
      if (args.tab != null) {
        setState(() {
          _tab = int.parse(args.tab!);
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final dic = I18n.of(context)!.getDic(i18n_full_dic_acala, 'acala')!;

    return PluginScaffold(
      appBar: PluginAppBar(
        title: Text(dic['earn.title']!),
        centerTitle: true,
        actions: [
          ConnectionChecker(
            widget.plugin,
            onConnected: _fetchData,
          ),
          Container(
            padding: EdgeInsets.only(right: 12),
            child: PluginIconButton(
              icon: Image.asset(
                'packages/polkawallet_plugin_acala/assets/images/history.png',
                width: 16,
              ),
              onPressed: () =>
                  Navigator.of(context).pushNamed(EarnHistoryPage.route),
            ),
          ),
          PluginAccountInfoAction(widget.keyring)
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Container(
              margin: EdgeInsets.all(16),
              child: PluginPageTitleTaps(
                names: [dic['earn.loan']!, dic['earn.dex']!, dic['airdrop']!],
                isSpaceBetween: true,
                activeTab: _tab,
                // fontSize: 20,
                // lineWidth: 6,
                onTap: (i) {
                  setState(() {
                    _tab = i;
                  });
                },
              ),
            ),
            Expanded(
              child: _tab == 0
                  ? EarnLoanList(widget.plugin, widget.keyring)
                  : _tab == 1
                      ? EarnDexList(widget.plugin)
                      : EarnTaigaList(widget.plugin, widget.keyring),
            )
          ],
        ),
      ),
    );
  }
}
