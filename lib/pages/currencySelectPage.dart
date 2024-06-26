import 'package:flutter/material.dart';
import 'package:polkawallet_plugin_acala/polkawallet_plugin_acala.dart';
import 'package:polkawallet_plugin_acala/utils/format.dart';
import 'package:polkawallet_plugin_acala/utils/i18n/index.dart';
import 'package:polkawallet_sdk/plugin/store/balances.dart';
import 'package:polkawallet_sdk/utils/i18n.dart';
import 'package:polkawallet_ui/components/currencyWithIcon.dart';
import 'package:polkawallet_ui/components/tokenIcon.dart';
import 'package:polkawallet_ui/components/v3/back.dart';

class CurrencySelectPage extends StatelessWidget {
  CurrencySelectPage(this.plugin);
  final PluginAcala plugin;
  static const String route = '/assets/currency';

  @override
  Widget build(BuildContext context) {
    /// the arguments can be List<TokenBalanceData> or List<String>.
    final List currencyIds =
        ModalRoute.of(context)!.settings.arguments as List<dynamic>;
    return Scaffold(
      appBar: AppBar(
        title: Text(I18n.of(context)!
            .getDic(i18n_full_dic_acala, 'common')!['currency.select']!),
        centerTitle: true,
        leading: BackBtn(),
      ),
      body: SafeArea(
        child: ListView(
          children: currencyIds.map((i) {
            final symbol =
                i.runtimeType == String ? i : (i as TokenBalanceData).symbol;
            return ListTile(
              title: CurrencyWithIcon(
                PluginFmt.tokenView(symbol ?? ''),
                TokenIcon(symbol ?? '', plugin.tokenIcons),
                textStyle: Theme.of(context).textTheme.headline4,
              ),
              trailing: Icon(
                Icons.arrow_forward_ios,
                size: 18,
              ),
              onTap: () {
                Navigator.of(context).pop(i);
              },
            );
          }).toList(),
        ),
      ),
    );
  }
}
