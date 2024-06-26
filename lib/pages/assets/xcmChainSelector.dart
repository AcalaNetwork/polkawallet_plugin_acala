import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:polkawallet_plugin_acala/common/constants/base.dart';
import 'package:polkawallet_plugin_acala/polkawallet_plugin_acala.dart';
import 'package:polkawallet_plugin_acala/utils/i18n/index.dart';
import 'package:polkawallet_sdk/utils/i18n.dart';
import 'package:polkawallet_ui/components/currencyWithIcon.dart';
import 'package:polkawallet_ui/components/tokenIcon.dart';
import 'package:polkawallet_ui/components/v3/bottomSheetContainer.dart';
import 'package:polkawallet_ui/components/v3/roundedCard.dart';
import 'package:polkawallet_ui/utils/index.dart';

class XcmChainSelector extends StatelessWidget {
  XcmChainSelector(
    this.plugin, {
    required this.fromChains,
    required this.toChains,
    required this.crossChainIcons,
    required this.from,
    required this.to,
    required this.fromConnecting,
    required this.onChanged,
  });
  final PluginAcala plugin;
  final List<String> fromChains;
  final List<String> toChains;
  final String from;
  final String to;
  final bool fromConnecting;
  final Map<String, Widget> crossChainIcons;
  final Function(List<String>) onChanged;

  void _switch() {
    if (from != plugin_name_acala) {
      onChanged([plugin_name_acala, from]);
    } else {
      onChanged([fromChains[0], from]);
    }
  }

  Future<void> _selectChain(BuildContext context, int index,
      Map<String, Widget> crossChainIcons, List<String> options) async {
    final dic = I18n.of(context)!.getDic(i18n_full_dic_acala, 'acala')!;
    final current = index == 0 ? from : to;

    showModalBottomSheet(
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        return BottomSheetContainer(
          title: Text(dic['cross.chain.select']!),
          content: ChainSelector(
            plugin,
            selected: current,
            options: options,
            crossChainIcons: crossChainIcons,
            onSelect: (chain) {
              if (chain != current) {
                if (chain != plugin_name_acala) {
                  onChanged([
                    index == 0
                        ? chain
                        : current == plugin_name_acala
                            ? plugin_name_acala
                            : from,
                    index == 1
                        ? chain
                        : current == plugin_name_acala
                            ? plugin_name_acala
                            : to,
                  ]);
                } else {
                  _switch();
                }
              }

              Navigator.of(context).pop();
            },
          ),
        );
      },
      context: context,
    );
  }

  @override
  Widget build(BuildContext context) {
    final dic = I18n.of(context)!.getDic(i18n_full_dic_acala, 'acala')!;

    final crossChainIcons = Map<String, Widget>.from(
        plugin.store!.assets.crossChainIcons.map((k, v) => MapEntry(
            k.toUpperCase(),
            (v as String).contains('.svg')
                ? SvgPicture.network(v)
                : Image.network(v))));

    final labelStyle = Theme.of(context)
        .textTheme
        .headline4
        ?.copyWith(fontWeight: FontWeight.bold);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(dic['cross.chain.from'] ?? '', style: labelStyle),
              GestureDetector(
                child: RoundedCard(
                  padding: EdgeInsets.fromLTRB(8, 10, 0, 8),
                  margin: EdgeInsets.only(bottom: 8, top: 3),
                  child: CurrencyWithIcon(
                    (from.length > 8 ? '${from.substring(0, 8)}...' : from)
                        .toUpperCase(),
                    Stack(
                      children: [
                        TokenIcon(from, crossChainIcons, size: 28),
                        Visibility(
                            child: fromConnecting
                                ? Container(
                                    padding: EdgeInsets.all(4),
                                    decoration: BoxDecoration(
                                        color:
                                            Color.fromARGB(150, 205, 205, 205),
                                        borderRadius: BorderRadius.all(
                                            Radius.circular(16))),
                                    child: CupertinoActivityIndicator(),
                                  )
                                : Container())
                      ],
                    ),
                    textStyle: TextStyle(fontSize: UI.getTextSize(14, context)),
                    trailing: fromChains.length == 0
                        ? null
                        : Icon(Icons.keyboard_arrow_down_rounded,
                            color: Theme.of(context).unselectedWidgetColor),
                  ),
                ),
                onTap: fromChains.length == 0
                    ? null
                    : () => _selectChain(context, 0, crossChainIcons,
                        [plugin_name_acala, ...fromChains]),
              )
            ],
          ),
        ),
        Expanded(
          flex: 0,
          child: GestureDetector(
            child: Container(
              padding: EdgeInsets.fromLTRB(10, 10, 10, 10),
              margin: EdgeInsets.only(bottom: 15),
              child: Image.asset(
                  "packages/polkawallet_plugin_acala/assets/images/xcm_to.png",
                  width: 13),
            ),
            onTap: fromChains.length > 0 ? _switch : null,
          ),
        ),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(dic['cross.chain'] ?? '', style: labelStyle),
              GestureDetector(
                child: RoundedCard(
                  padding: EdgeInsets.fromLTRB(8, 10, 0, 8),
                  margin: EdgeInsets.only(bottom: 8, top: 3),
                  child: CurrencyWithIcon(
                    (to.length > 8 ? '${to.substring(0, 8)}...' : to)
                        .toUpperCase(),
                    TokenIcon(to, crossChainIcons, size: 28),
                    textStyle: TextStyle(fontSize: UI.getTextSize(14, context)),
                    trailing: toChains.length == 1 && fromChains.length == 0
                        ? null
                        : Icon(
                            Icons.keyboard_arrow_down_rounded,
                            color: Theme.of(context).unselectedWidgetColor,
                          ),
                  ),
                ),
                onTap: toChains.length == 1 && fromChains.length == 0
                    ? null
                    : () => _selectChain(
                        context,
                        1,
                        crossChainIcons,
                        fromChains.length > 0
                            ? [plugin_name_acala, ...toChains]
                            : toChains),
              )
            ],
          ),
        )
      ],
    );
  }
}

class ChainSelector extends StatelessWidget {
  ChainSelector(this.plugin,
      {required this.options,
      required this.crossChainIcons,
      required this.selected,
      required this.onSelect});
  final PluginAcala plugin;
  final List<String> options;
  final Map<String, Widget> crossChainIcons;
  final String selected;
  final Function(String) onSelect;

  @override
  Widget build(BuildContext context) {
    return ListView(
      children: options.map((i) {
        return ListTile(
          selected: i == selected,
          title: CurrencyWithIcon(
            i.toUpperCase(),
            TokenIcon(i, crossChainIcons),
            textStyle: Theme.of(context).textTheme.headline4,
          ),
          trailing: Icon(
            Icons.arrow_forward_ios,
            size: 18,
            color: Theme.of(context).unselectedWidgetColor,
          ),
          onTap: () {
            onSelect(i);
          },
        );
      }).toList(),
    );
  }
}
