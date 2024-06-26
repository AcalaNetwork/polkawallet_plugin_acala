import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:polkawallet_plugin_acala/api/types/nftData.dart';
import 'package:polkawallet_plugin_acala/common/components/videoPlayerContainer.dart';
import 'package:polkawallet_plugin_acala/polkawallet_plugin_acala.dart';
import 'package:polkawallet_plugin_acala/utils/i18n/index.dart';
import 'package:polkawallet_sdk/storage/keyring.dart';
import 'package:polkawallet_sdk/storage/types/keyPairData.dart';
import 'package:polkawallet_sdk/utils/i18n.dart';
import 'package:polkawallet_ui/components/infoItemRow.dart';
import 'package:polkawallet_ui/components/v3/addressTextFormField.dart';
import 'package:polkawallet_ui/components/v3/plugin/pluginAddressFormItem.dart';
import 'package:polkawallet_ui/components/v3/plugin/pluginIconButton.dart';
import 'package:polkawallet_ui/components/v3/plugin/pluginScaffold.dart';
import 'package:polkawallet_ui/components/v3/plugin/pluginTagCard.dart';
import 'package:polkawallet_ui/components/v3/plugin/pluginTxButton.dart';
import 'package:polkawallet_ui/pages/scanPage.dart';
import 'package:polkawallet_ui/utils/consts.dart';
import 'package:polkawallet_ui/utils/format.dart';
import 'package:polkawallet_ui/utils/index.dart';

class NFTTransferPage extends StatefulWidget {
  NFTTransferPage(this.plugin, this.keyring);
  final PluginAcala plugin;
  final Keyring keyring;

  static const String route = '/acala/nft/transfer';

  @override
  _NFTTransferPageState createState() => _NFTTransferPageState();
}

class _NFTTransferPageState extends State<NFTTransferPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _amountCtrl = new TextEditingController();

  KeyPairData? _accountTo;

  Future<void> _onScan() async {
    final to = await Navigator.of(context).pushNamed(ScanPage.route);
    if (to == null) return;
    final acc = KeyPairData();
    acc.address = (to as QRCodeResult).address!.address;
    acc.name = to.address!.name;
    final res =
        await widget.plugin.sdk.api.account.getAddressIcons([acc.address]);
    if (res != null) {
      acc.icon = res[0][1];
    }
    setState(() {
      _accountTo = acc;
    });
  }

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget.keyring.allWithContacts.length > 0) {
        setState(() {
          _accountTo = widget.keyring.allWithContacts[0];
        });
      }
    });
  }

  @override
  void dispose() {
    _amountCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final dic = I18n.of(context)!.getDic(i18n_full_dic_acala, 'acala')!;
    final dicCommon = I18n.of(context)!.getDic(i18n_full_dic_acala, 'common');

    return PluginScaffold(
      appBar: PluginAppBar(
        title: Text('NFT ${dic['nft.transfer']}'),
        centerTitle: true,
        actions: [
          Padding(
              padding: EdgeInsets.only(right: 8),
              child: PluginIconButton(
                icon: Center(
                    child: SvgPicture.asset(
                  'assets/images/scan.svg',
                  color: Colors.white,
                  width: 25,
                )),
                onPressed: _onScan,
              ))
        ],
      ),
      body: SafeArea(
        child: Observer(
          builder: (_) {
            final NFTData? item =
                ModalRoute.of(context)!.settings.arguments as NFTData?;
            final list = widget.plugin.store!.assets.nft.toList();
            list.retainWhere((e) => e.classId == item!.classId);

            return Column(
              children: [
                Expanded(
                  child: ListView(
                    padding: EdgeInsets.all(16),
                    children: [
                      PluginAddressFormItem(
                        label: I18n.of(context)!.getDic(
                            i18n_full_dic_acala, 'common')!['address.from'],
                        account: widget.keyring.current,
                      ),
                      Padding(
                          padding: EdgeInsets.only(top: 24),
                          child: AddressTextFormField(
                            widget.plugin.sdk.api,
                            widget.keyring.allWithContacts,
                            initialValue: _accountTo,
                            labelText: I18n.of(context)!.getDic(
                                i18n_full_dic_acala, 'common')!['address'],
                            onChanged: (acc) {
                              setState(() {
                                _accountTo = acc;
                              });
                            },
                            key: ValueKey<KeyPairData?>(_accountTo),
                            isHubTheme: true,
                            sdk: widget.plugin.sdk,
                          )),
                      Form(
                          key: _formKey,
                          child: PluginTagCard(
                            margin: EdgeInsets.only(top: 16),
                            titleTag: dic['v3.earn.amount'],
                            padding: EdgeInsets.only(
                                left: 16, right: 16, bottom: 27, top: 12),
                            child: TextFormField(
                              style: Theme.of(context)
                                  .textTheme
                                  .headline3
                                  ?.copyWith(
                                      color: Colors.white,
                                      fontSize: UI.getTextSize(40, context)),
                              decoration: InputDecoration(
                                contentPadding: EdgeInsets.zero,
                                border: InputBorder.none,
                                hintText:
                                    '${dic['nft.quantity']} (${dicCommon!['amount.transferable']}: ${list.length})',
                                hintStyle: Theme.of(context)
                                    .textTheme
                                    .headline5
                                    ?.copyWith(
                                        color: Color(0xffbcbcbc),
                                        fontWeight: FontWeight.w300),
                                suffix: GestureDetector(
                                  child: Icon(
                                    CupertinoIcons.clear_thick_circled,
                                    color: Color(0xFFD8D8D8),
                                    size: 22,
                                  ),
                                  onTap: () {
                                    setState(() {
                                      _amountCtrl.text = '';
                                    });
                                  },
                                ),
                              ),
                              inputFormatters: [
                                FilteringTextInputFormatter.allow(
                                    RegExp(r'[0-9]')),
                              ],
                              controller: _amountCtrl,
                              keyboardType: TextInputType.numberWithOptions(
                                  decimal: true),
                              validator: (v) {
                                if (v!.isEmpty) {
                                  return dicCommon['input.invalid'];
                                }
                                final count = int.parse(v.trim());
                                if (count < 1) {
                                  return dicCommon['input.invalid'];
                                }
                                if (count > list.length) {
                                  return dicCommon['amount.low'];
                                }
                                return null;
                              },
                            ),
                          )),
                      PluginTagCard(
                        titleTag: 'NFT',
                        padding: EdgeInsets.only(
                            left: 12, top: 12, right: 16, bottom: 12),
                        child: NFTFormItem(item, widget.plugin),
                        margin: EdgeInsets.only(top: 24),
                      ),
                    ],
                  ),
                ),
                Container(
                  margin: EdgeInsets.fromLTRB(16, 0, 16, 16),
                  child: PluginTxButton(
                    getTxParams: () async {
                      if (_formKey.currentState!.validate()) {
                        final count = int.parse(_amountCtrl.text.trim());
                        final txs = list
                            .sublist(0, count)
                            .map((e) =>
                                'api.tx.nft.transfer("${_accountTo!.address}", [${e.classId}, ${e.tokenId}])')
                            .toList();
                        return TxConfirmParams(
                            module: 'utility',
                            call: 'batch',
                            txTitle: 'NFT ${dic['nft.transfer']}',
                            txDisplay: {
                              'call': 'nft.transfer',
                              'to': Fmt.address(_accountTo!.address),
                              'classId': item!.classId,
                              'quantity': _amountCtrl.text.trim(),
                            },
                            params: [],
                            rawParams: '[[${txs.join(',')}]]',
                            isPlugin: true);
                      }
                      return null;
                    },
                    onFinish: (res) {
                      if (res != null) {
                        Navigator.of(context).pop(res);
                      }
                    },
                  ),
                )
              ],
            );
          },
        ),
      ),
    );
  }
}

class NFTFormItem extends StatelessWidget {
  NFTFormItem(this.item, this.plugin);
  final NFTData? item;
  final PluginAcala plugin;
  @override
  Widget build(BuildContext context) {
    final dic = I18n.of(context)!.getDic(i18n_full_dic_acala, 'acala');
    final style = Theme.of(context)
        .textTheme
        .headline5
        ?.copyWith(color: PluginColorsDark.headline1);

    final symbol = plugin.networkState.tokenSymbol![0];
    final decimal = plugin.networkState.tokenDecimals![0];
    final deposit = Fmt.balance(item!.deposit, decimal);
    final imageUrl = item!.metadata!['imageServiceUrl'] as String;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          height: 93,
          margin: EdgeInsets.only(right: 19),
          child: imageUrl.contains('.mp4')
              ? VideoPlayerContainer(imageUrl)
              : Image.network(imageUrl.endsWith('.gif')
                  ? imageUrl
                  : '$imageUrl?imageView2/2/w/400'),
        ),
        Expanded(
          child: Column(
            children: [
              InfoItemRow(dic!['nft.name']!, item!.metadata!['name'],
                  labelStyle: style, contentStyle: style),
              Padding(
                  padding: EdgeInsets.only(top: 5),
                  child: InfoItemRow(
                    dic['nft.deposit']!,
                    '$deposit $symbol',
                    labelStyle: style,
                    contentStyle: style,
                    crossAxisAlignment: CrossAxisAlignment.start,
                  )),
            ],
          ),
        )
      ],
    );
  }
}
