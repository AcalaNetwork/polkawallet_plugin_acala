import 'package:flutter/material.dart';
import 'package:polkawallet_plugin_acala/common/constants/index.dart';
import 'package:polkawallet_plugin_acala/pages/earnNew/earnPage.dart';
import 'package:polkawallet_plugin_acala/pages/homaNew/homaPage.dart';
import 'package:polkawallet_plugin_acala/pages/loanNew/loanPage.dart';
import 'package:polkawallet_plugin_acala/pages/swapNew/swapPage.dart';
import 'package:polkawallet_plugin_acala/polkawallet_plugin_acala.dart';
import 'package:polkawallet_plugin_acala/utils/i18n/index.dart';
import 'package:polkawallet_sdk/storage/keyring.dart';
import 'package:polkawallet_sdk/utils/i18n.dart';
import 'package:polkawallet_ui/components/v3/back.dart';
import 'package:polkawallet_ui/components/v3/plugin/pluginItemCard.dart';
import 'package:polkawallet_ui/utils/index.dart';

class AcalaEntry extends StatelessWidget {
  AcalaEntry(this.plugin, this.keyring);

  final PluginAcala plugin;
  final Keyring keyring;

  static final route = '/acala/entry/temp';

  @override
  Widget build(BuildContext context) {
    final bodyHeight = MediaQuery.of(context).size.height -
        MediaQuery.of(context).padding.top -
        kToolbarHeight;
    return Scaffold(
      appBar: AppBar(
        title: Text('Acala'),
        centerTitle: true,
        leading: BackBtn(),
      ),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        child: Stack(
          alignment: Alignment.bottomLeft,
          children: [
            Image.asset(
              "packages/polkawallet_plugin_acala/assets/images/acala_entry_bg.png",
              width: double.infinity,
              fit: BoxFit.fill,
            ),
            Image.asset(
              "packages/polkawallet_plugin_acala/assets/images/acala_entry_3.png",
            ),
            Padding(
                padding: EdgeInsets.only(bottom: bodyHeight * 0.4),
                child: Align(
                    alignment: Alignment.centerRight,
                    child: ClipRect(
                        child: Align(
                            widthFactor: 0.8,
                            alignment: Alignment.centerLeft,
                            child: Image.asset(
                                "packages/polkawallet_plugin_acala/assets/images/acala_entry_1.png"))))),
            Padding(
                padding: EdgeInsets.only(bottom: bodyHeight * 0.25),
                child: ClipRect(
                    child: Align(
                        widthFactor: 0.85,
                        alignment: Alignment.centerRight,
                        child: Image.asset(
                            "packages/polkawallet_plugin_acala/assets/images/acala_entry_2.png")))),
            Container(
              padding: EdgeInsets.only(top: bodyHeight * 0.12),
              width: double.infinity,
              alignment: Alignment.topCenter,
              child: Text(
                "Under Construction",
                style: Theme.of(context).textTheme.headline1!.copyWith(
                    fontSize: UI.getTextSize(36, context), color: Colors.white),
              ),
            )
          ],
        ),
      ),
    );
  }
}

class DefiWidget extends StatelessWidget {
  DefiWidget(this.plugin);

  final PluginAcala plugin;

  final _liveModuleRoutes = {
    // 'multiply': MultiplyPage.route,
    'earn': EarnPage.route,
    'swap': SwapPage.route,
    'homa': HomaPage.route,
    'loan': LoanPage.route,
  };

  @override
  Widget build(BuildContext context) {
    final dic = I18n.of(context)!.getDic(i18n_full_dic_acala, 'common');
    final modulesConfig =
        plugin.store?.setting.remoteConfig['modules'] ?? config_modules;
    List liveModules = _liveModuleRoutes.keys.toList();

    liveModules.retainWhere(
        (e) => modulesConfig[e] == null || modulesConfig[e]['visible']);

    return SingleChildScrollView(
      physics: BouncingScrollPhysics(),
      child: Column(
        children: liveModules.map((e) {
          final enabled =
              modulesConfig[e] == null ? true : modulesConfig[e]['enabled'];
          return GestureDetector(
            child: PluginItemCard(
              margin: EdgeInsets.only(bottom: 16),
              title: dic!['$e.title']!,
              describe: dic['$e.brief'],
              icon: Image.asset(
                  "packages/polkawallet_plugin_acala/assets/images/icon_$e.png",
                  width: 18),
            ),
            onTap: () {
              if (enabled) {
                Navigator.of(context).pushNamed(_liveModuleRoutes[e]!);
              } else {
                Navigator.of(context).pushNamed(AcalaEntry.route);
              }
            },
          );
        }).toList(),
      ),
    );
  }
}
