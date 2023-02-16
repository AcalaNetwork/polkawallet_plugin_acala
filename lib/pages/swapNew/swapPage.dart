import 'dart:async';

import 'package:flutter/material.dart';
import 'package:polkawallet_plugin_acala/pages/swapNew/bootstrapList.dart';
import 'package:polkawallet_plugin_acala/pages/swapNew/dexPoolList.dart';
import 'package:polkawallet_plugin_acala/pages/swapNew/swapForm.dart';
import 'package:polkawallet_plugin_acala/pages/swapNew/swapHistoryPage.dart';
import 'package:polkawallet_plugin_acala/pages/types/swapPageParams.dart';
import 'package:polkawallet_plugin_acala/polkawallet_plugin_acala.dart';
import 'package:polkawallet_plugin_acala/utils/i18n/index.dart';
import 'package:polkawallet_sdk/storage/keyring.dart';
import 'package:polkawallet_sdk/utils/i18n.dart';
import 'package:polkawallet_ui/components/connectionChecker.dart';
import 'package:polkawallet_ui/components/v3/plugin/pluginAccountInfoAction.dart';
import 'package:polkawallet_ui/components/v3/plugin/pluginIconButton.dart';
import 'package:polkawallet_ui/components/v3/plugin/pluginPageTitleTaps.dart';
import 'package:polkawallet_ui/components/v3/plugin/pluginScaffold.dart';
import 'package:skeleton_loader/skeleton_loader.dart';

class SwapPage extends StatefulWidget {
  SwapPage(this.plugin, this.keyring);
  final PluginAcala plugin;
  final Keyring keyring;

  static const String route = '/acala/dex';

  @override
  _SwapPageState createState() => _SwapPageState();
}

class _SwapPageState extends State<SwapPage> {
  int _tab = 0;

  bool _loading = true;

  Future<void> _updateData() async {
    if (widget.plugin.sdk.api.connectedNode != null) {
      await widget.plugin.service!.earn.getDexPools();
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    }
  }

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final argsJson = ModalRoute.of(context)!.settings.arguments as Map? ?? {};
      final args = SwapPageParams.fromJson(argsJson);
      if (args.tab != null) {
        setState(() {
          _tab = int.parse(args.tab!);
        });
      }
    });
  }

  @override
  Widget build(_) {
    final dic = I18n.of(context)!.getDic(i18n_full_dic_acala, 'acala')!;
    final args = ModalRoute.of(context)!.settings.arguments as Map?;
    if (args != null && args['swapPair'] != null) {}
    return PluginScaffold(
      extendBodyBehindAppBar: true,
      appBar: PluginAppBar(
        title: Text(dic['dex.title']!),
        actions: [
          Container(
            margin: EdgeInsets.only(right: 8),
            child: PluginIconButton(
              onPressed: () =>
                  Navigator.of(context).pushNamed(SwapHistoryPage.route),
              icon: Image.asset(
                'packages/polkawallet_plugin_acala/assets/images/history.png',
                width: 16,
              ),
            ),
          ),
          PluginAccountInfoAction(widget.keyring)
        ],
      ),
      body: SafeArea(
          child: Column(
        children: [
          Padding(
              padding: EdgeInsets.only(top: 15, left: 16, right: 16, bottom: 5),
              child: PluginPageTitleTaps(
                names: [dic['dex.title']!, dic['dex.lp']!, dic['boot.title']!],
                activeTab: _tab,
                isSpaceBetween: true,
                onTap: (i) {
                  if (i != _tab) {
                    setState(() {
                      _tab = i;
                    });
                  }
                },
              )),
          ConnectionChecker(widget.plugin, onConnected: _updateData),
          _loading
              ? SwapSkeleton()
              : Expanded(
                  child: _tab == 0
                      ? SwapForm(widget.plugin, widget.keyring,
                          initialSwapPair:
                              args != null ? args['swapPair'] : null)
                      : _tab == 1
                          ? DexPoolList(widget.plugin, widget.keyring)
                          : BootstrapList(widget.plugin, widget.keyring),
                ),
        ],
      )),
    );
  }
}

class SwapSkeleton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final highlightColor = Colors.white54;
    final baseColor = const Color(0xFF3A3B3D);
    return SkeletonLoader(
      builder: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Container(
            margin: EdgeInsets.only(left: 16, right: 16, top: 16),
            decoration: BoxDecoration(
                color: Colors.white54,
                borderRadius: BorderRadius.all(Radius.circular(4))),
            child: SkeletonLoader(
              builder: Container(
                padding:
                    EdgeInsets.only(left: 8, right: 6, top: 10, bottom: 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Container(
                            margin: EdgeInsets.only(bottom: 16),
                            width: 120,
                            height: 14,
                            color: Colors.white),
                        Expanded(
                          child: SizedBox(height: 14),
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Container(
                                width: 100, height: 14, color: Colors.white),
                            Container(
                                margin: EdgeInsets.only(top: 24, bottom: 4),
                                width: 60,
                                height: 14,
                                color: Colors.white)
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              items: 1,
              period: Duration(seconds: 2),
              highlightColor: highlightColor,
              baseColor: baseColor,
              direction: SkeletonDirection.ltr,
            ),
          ),
          Container(
            margin: EdgeInsets.only(left: 16, right: 16, top: 8, bottom: 24),
            decoration: BoxDecoration(
                color: Colors.white54,
                borderRadius: BorderRadius.all(Radius.circular(4))),
            child: SkeletonLoader(
              builder: Container(
                padding:
                    EdgeInsets.only(left: 8, right: 6, top: 10, bottom: 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Container(
                            margin: EdgeInsets.only(bottom: 16),
                            width: 120,
                            height: 14,
                            color: Colors.white),
                        Expanded(
                          child: SizedBox(height: 14),
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Container(
                                width: 100, height: 14, color: Colors.white),
                            Container(
                                margin: EdgeInsets.only(top: 24, bottom: 4),
                                width: 60,
                                height: 14,
                                color: Colors.white)
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              items: 1,
              period: Duration(seconds: 2),
              highlightColor: highlightColor,
              baseColor: baseColor,
              direction: SkeletonDirection.ltr,
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                  width: 120,
                  height: 14,
                  color: Colors.white,
                  margin: EdgeInsets.only(left: 16)),
              Container(
                  width: 80,
                  height: 14,
                  color: Colors.white,
                  margin: EdgeInsets.only(right: 16))
            ],
          ),
        ],
      ),
      items: 1,
      period: Duration(seconds: 2),
      highlightColor: highlightColor,
      baseColor: baseColor,
      direction: SkeletonDirection.ltr,
    );
  }
}
