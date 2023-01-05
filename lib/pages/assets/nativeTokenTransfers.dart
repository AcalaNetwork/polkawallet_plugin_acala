import 'package:flutter/cupertino.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:polkawallet_plugin_acala/pages/assets/tokenDetailPage.dart';
import 'package:polkawallet_plugin_acala/polkawallet_plugin_acala.dart';
import 'package:polkawallet_plugin_acala/utils/assets.dart';
import 'package:polkawallet_ui/components/listTail.dart';
import 'package:polkawallet_ui/components/v3/plugin/pluginLoadingWidget.dart';

class NativeTokenTransfers extends StatefulWidget {
  const NativeTokenTransfers(this.plugin, this.account, this.transferType,
      {Key? key})
      : super(key: key);
  final PluginAcala plugin;
  final int transferType;
  final String account;
  @override
  State<NativeTokenTransfers> createState() => _NativeTokenTransfersState();
}

class _NativeTokenTransfersState extends State<NativeTokenTransfers> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      widget.plugin.service!.history.getTransfers('ACA');
    });
  }

  @override
  Widget build(BuildContext context) {
    return Observer(builder: (_) {
      final nativeToken =
          AssetsUtils.getBalanceFromTokenNameId(widget.plugin, 'ACA');
      final list = widget.plugin.store?.history.transfersMap['ACA'];
      final txs = list?.toList();
      if (widget.transferType > 0) {
        txs?.retainWhere((e) =>
            (widget.transferType == 1 ? e.data!['to'] : e.data!['from']) ==
            widget.account);
      }
      return txs == null
          ? Container(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [PluginLoadingWidget()],
              ),
            )
          : ListView.builder(
              itemCount: txs.length + 1,
              itemBuilder: (_, i) {
                if (i == txs.length) {
                  return ListTail(isEmpty: txs.length == 0, isLoading: false);
                }
                return TransferListItem(
                  data: txs[i],
                  token: nativeToken,
                  isOut: txs[i].data!['from'] == widget.account,
                );
              },
            );
    });
  }
}
