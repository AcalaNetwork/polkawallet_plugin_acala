import 'dart:math';

import 'package:card_swiper/card_swiper.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:polkawallet_plugin_acala/api/types/nftData.dart';
import 'package:polkawallet_plugin_acala/common/components/videoPlayerContainer.dart';
import 'package:polkawallet_plugin_acala/pages/nftNew/nftTransferPage.dart';
import 'package:polkawallet_plugin_acala/polkawallet_plugin_acala.dart';
import 'package:polkawallet_plugin_acala/utils/i18n/index.dart';
import 'package:polkawallet_sdk/storage/keyring.dart';
import 'package:polkawallet_sdk/utils/i18n.dart';
import 'package:polkawallet_ui/components/connectionChecker.dart';
import 'package:polkawallet_ui/components/infoItemRow.dart';
import 'package:polkawallet_ui/components/v3/dialog.dart';
import 'package:polkawallet_ui/components/v3/plugin/pluginAccountInfoAction.dart';
import 'package:polkawallet_ui/components/v3/plugin/pluginButton.dart';
import 'package:polkawallet_ui/components/v3/plugin/pluginIconButton.dart';
import 'package:polkawallet_ui/components/v3/plugin/pluginScaffold.dart';
import 'package:polkawallet_ui/utils/consts.dart';
import 'package:polkawallet_ui/utils/format.dart';
import 'package:polkawallet_ui/utils/i18n.dart';
import 'package:polkawallet_ui/utils/index.dart';

const nft_filter_name_all = 'All';

class NftPage extends StatefulWidget {
  NftPage(this.plugin, this.keyring, {Key? key}) : super(key: key);
  final PluginAcala plugin;
  final Keyring keyring;

  static const String route = '/acala/nft';
  @override
  State<NftPage> createState() => _NftPageState();
}

class _NftPageState extends State<NftPage> {
  final GlobalKey<RefreshIndicatorState> _refreshKey =
      new GlobalKey<RefreshIndicatorState>();

  final SwiperController _swiperController = SwiperController();

  int _currentIndex = 0;

  final List<String> filtersAll = [
    nft_filter_name_all,
    'Transferable',
    'Burnable',
    'Mintable',
    // 'ClassPropertiesMutable',
  ];
  String _filters = nft_filter_name_all;

  Future<void> _queryNFTs() async {
    final nft = await widget.plugin.api!.assets
        .queryNFTs(widget.keyring.current.address);
    widget.plugin.store!.assets.setNFTs(nft);
  }

  Future<void> _onTransfer(NFTData item) async {
    final res = await Navigator.of(context)
        .pushNamed(NFTTransferPage.route, arguments: item);
    if (res != null) {
      Navigator.of(context).pop(res);
    }
  }

  Widget buildHeaderView(Map<dynamic, dynamic> classes, List<NFTData> list) {
    final itemCardSize = 280 / 390 * MediaQuery.of(context).size.width;
    return Stack(
      alignment: Alignment.center,
      children: [
        Container(
            width: double.infinity,
            margin: EdgeInsets.only(top: 57, bottom: 24),
            height: itemCardSize,
            child: Swiper(
              outer: true,
              loop: false,
              physics: BouncingScrollPhysics(),
              controller: _swiperController,
              itemBuilder: (context, index) {
                final item = list.firstWhere(
                    (e) => e.classId == classes.keys.toList()[index]);
                final imageUrl = item.metadata!['imageServiceUrl'] ?? '';
                return Container(
                  decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.all(Radius.circular(8))),
                  child: Stack(
                    children: [
                      Container(
                        padding: EdgeInsets.all(10),
                        width: itemCardSize,
                        height: itemCardSize,
                        child: imageUrl.contains('.mp4')
                            ? VideoPlayerContainer(imageUrl)
                            : Image.network(
                                '$imageUrl?imageView2/2/w/400',
                              ),
                      ),
                      Align(
                          alignment: Alignment.topRight,
                          child: Container(
                            padding: EdgeInsets.symmetric(
                                horizontal: 10, vertical: 5),
                            decoration: BoxDecoration(
                                color: PluginColorsDark.primary,
                                borderRadius:
                                    BorderRadius.all(Radius.circular(8))),
                            child: Text(
                              'x${classes[item.classId]}',
                              style: TextStyle(
                                  fontSize: UI.getTextSize(20, context),
                                  color: PluginColorsDark.headline1,
                                  fontWeight: FontWeight.bold),
                            ),
                          ))
                    ],
                  ),
                );
              },
              itemCount: classes.length,
              viewportFraction: 280 / 390.0,
              scale: 0.9,
              fade: 0.3,
              itemWidth: itemCardSize,
              itemHeight: itemCardSize,
              onIndexChanged: (index) {
                setState(() {
                  _currentIndex = index;
                });
              },
            )),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _currentIndex - 1 >= 0
                ? GestureDetector(
                    onTap: () {
                      _swiperController.move(_currentIndex - 1);
                    },
                    child: Padding(
                        padding: EdgeInsets.only(left: 13),
                        child: Transform.rotate(
                            angle: -pi,
                            child: Image.asset(
                                "packages/polkawallet_plugin_acala/assets/images/right_white.png",
                                width: 27))))
                : Container(),
            _currentIndex + 1 < classes.length
                ? GestureDetector(
                    onTap: () {
                      _swiperController.move(_currentIndex + 1);
                    },
                    child: Padding(
                        padding: EdgeInsets.only(right: 13),
                        child: Image.asset(
                            "packages/polkawallet_plugin_acala/assets/images/right_white.png",
                            width: 27)))
                : Container()
          ],
        )
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final dic = I18n.of(context)!.getDic(i18n_full_dic_acala, 'acala');
    return PluginScaffold(
        appBar: PluginAppBar(
          title: Text('NFTs'),
          actions: [
            Padding(
                padding: EdgeInsets.only(right: 12),
                child: PluginIconButton(
                  icon: SvgPicture.asset(
                    'assets/images/icon_screening.svg',
                    color: PluginColorsDark.headline1,
                    width: 22,
                  ),
                  onPressed: () {
                    showCupertinoModalPopup(
                      context: context,
                      barrierDismissible: true,
                      builder: (BuildContext context) {
                        return PolkawalletActionSheet(
                          actions: [
                            ...filtersAll
                                .map((e) => PolkawalletActionSheetAction(
                                      child: Text(dic!['nft.$e']!),
                                      onPressed: () {
                                        Navigator.of(context).pop();
                                        setState(() {
                                          _filters = e;
                                        });
                                      },
                                    ))
                                .toList(),
                          ],
                          cancelButton: PolkawalletActionSheetAction(
                            onPressed: () {
                              Navigator.pop(context);
                            },
                            child: Text(I18n.of(context)!.getDic(
                                i18n_full_dic_acala, 'common')!['cancel']!),
                          ),
                        );
                      },
                    );
                  },
                )),
            PluginAccountInfoAction(widget.keyring)
          ],
        ),
        body: SafeArea(
          child: Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Observer(builder: (_) {
                final symbol = widget.plugin.networkState.tokenSymbol![0];
                final decimal = widget.plugin.networkState.tokenDecimals![0];
                final list = widget.plugin.store!.assets.nft.toList();
                if (list.length == 0) {
                  return Center(
                      child: Text(
                    I18n.of(context)!
                        .getDic(i18n_full_dic_ui, 'common')!['list.empty']!,
                    style: Theme.of(context)
                        .textTheme
                        .headline4
                        ?.copyWith(color: Colors.white),
                  ));
                }
                if (!_filters.contains(nft_filter_name_all)) {
                  list.retainWhere((e) => e.properties!.contains(_filters));
                }
                final classes = {};

                list.forEach((e) {
                  if (classes.keys.toList().indexOf(e.classId) < 0) {
                    classes[e.classId] = 1;
                  } else {
                    classes[e.classId] = classes[e.classId] + 1;
                  }
                });

                final item = list.firstWhere(
                    (e) => e.classId == classes.keys.toList()[_currentIndex]);
                final allProps = item.properties!.toList();
                final isMintable = item.properties!.contains('Mintable');
                final transferable = item.properties!.contains('Transferable');
                allProps.remove('ClassPropertiesMutable');
                if (!isMintable) {
                  allProps.add('Unmintable');
                }

                final deposit = Fmt.balance(item.deposit, decimal);

                final style = Theme.of(context)
                    .textTheme
                    .headline5
                    ?.copyWith(color: PluginColorsDark.headline1);
                return Stack(
                  children: [
                    ConnectionChecker(widget.plugin, onConnected: _queryNFTs),
                    RefreshIndicator(
                        color: Colors.black,
                        backgroundColor: Colors.white,
                        key: _refreshKey,
                        onRefresh: _queryNFTs,
                        child: SingleChildScrollView(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Padding(
                                  padding: EdgeInsets.only(top: 5),
                                  child: buildHeaderView(classes, list)),
                              Container(
                                  padding: EdgeInsets.symmetric(horizontal: 16),
                                  child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Wrap(
                                          crossAxisAlignment:
                                              WrapCrossAlignment.start,
                                          children: allProps
                                              .map((e) => Container(
                                                    margin: EdgeInsets.only(
                                                        right: 12),
                                                    padding:
                                                        EdgeInsets.symmetric(
                                                            horizontal: 6,
                                                            vertical: 5),
                                                    decoration: BoxDecoration(
                                                        color: e == 'Burnable'
                                                            ? PluginColorsDark
                                                                .primary
                                                            : e == 'Mintable'
                                                                ? PluginColorsDark
                                                                    .green
                                                                : PluginColorsDark
                                                                    .headline2,
                                                        borderRadius:
                                                            BorderRadius.all(
                                                                Radius.circular(
                                                                    2))),
                                                    child: Text(
                                                      dic!['nft.$e']!,
                                                      style: Theme.of(context)
                                                          .textTheme
                                                          .headline5
                                                          ?.copyWith(
                                                              color:
                                                                  Colors.black,
                                                              fontWeight:
                                                                  FontWeight
                                                                      .w600),
                                                    ),
                                                  ))
                                              .toList(),
                                        ),
                                        Container(
                                          margin: EdgeInsets.symmetric(
                                              vertical: 12),
                                          padding: EdgeInsets.all(16),
                                          decoration: BoxDecoration(
                                              color: PluginColorsDark.cardColor,
                                              borderRadius: BorderRadius.all(
                                                  Radius.circular(8))),
                                          child: Column(
                                            children: [
                                              InfoItemRow(dic!['nft.name']!,
                                                  item.metadata!['name'],
                                                  labelStyle: style,
                                                  contentStyle: style),
                                              Padding(
                                                  padding:
                                                      EdgeInsets.only(top: 5),
                                                  child: InfoItemRow(
                                                    dic['nft.description']!,
                                                    item.metadata![
                                                        'description'],
                                                    labelStyle: style,
                                                    contentStyle: style,
                                                    crossAxisAlignment:
                                                        CrossAxisAlignment
                                                            .start,
                                                  )),
                                              Padding(
                                                  padding:
                                                      EdgeInsets.only(top: 5),
                                                  child: InfoItemRow(
                                                    dic['nft.deposit']!,
                                                    '$deposit $symbol',
                                                    labelStyle: style,
                                                    contentStyle: style,
                                                    crossAxisAlignment:
                                                        CrossAxisAlignment
                                                            .start,
                                                  )),
                                              Padding(
                                                  padding:
                                                      EdgeInsets.only(top: 5),
                                                  child: InfoItemRow(
                                                    dic['nft.class']!,
                                                    item.classId,
                                                    labelStyle: style,
                                                    contentStyle: style,
                                                    crossAxisAlignment:
                                                        CrossAxisAlignment
                                                            .start,
                                                  )),
                                              Padding(
                                                  padding:
                                                      EdgeInsets.only(top: 5),
                                                  child: InfoItemRow(
                                                    dic['nft.quantity']!,
                                                    '${classes[item.classId]}',
                                                    labelStyle: style,
                                                    contentStyle: style,
                                                    crossAxisAlignment:
                                                        CrossAxisAlignment
                                                            .start,
                                                  ))
                                            ],
                                          ),
                                        ),
                                        Visibility(
                                            visible: transferable,
                                            child: PluginButton(
                                              title: dic['nft.transfer']!,
                                              onPressed: () =>
                                                  _onTransfer(item),
                                            )),
                                      ]))
                            ],
                          ),
                        )),
                    Container(
                      width: double.infinity,
                      margin: EdgeInsets.only(left: 16, right: 16, bottom: 5),
                      child: _TabBar(
                        list,
                        classes,
                        initIndex: _currentIndex,
                        onChange: (index) {
                          setState(() {
                            _currentIndex = index;
                          });
                          _swiperController.move(index);
                        },
                      ),
                    )
                  ],
                );
              })),
        ));
  }
}

class _TabBar extends StatefulWidget {
  _TabBar(this.nfts, this.datas, {Key? key, this.initIndex = 0, this.onChange})
      : super(key: key);
  final Map<dynamic, dynamic> datas;
  final List<NFTData> nfts;
  final int initIndex;
  final Function(int)? onChange;

  @override
  State<_TabBar> createState() => _TabBarState();
}

class _TabBarState extends State<_TabBar> {
  int _initIndex = 0;
  bool _isOpen = false;

  @override
  void initState() {
    _initIndex = widget.initIndex;
    super.initState();
  }

  @override
  void didUpdateWidget(covariant _TabBar oldWidget) {
    _initIndex = widget.initIndex;
    super.didUpdateWidget(oldWidget);
  }

  @override
  Widget build(BuildContext context) {
    final TextPainter textPainter = TextPainter(
        textDirection: TextDirection.ltr,
        text: TextSpan(
            text: widget.nfts[0].metadata!['name'],
            style: Theme.of(context).textTheme.headline5?.copyWith(
                fontSize: UI.getTextSize(12, context),
                fontWeight: FontWeight.w600,
                color: PluginColorsDark.headline1)))
      ..layout();
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 6, vertical: 7),
      decoration: BoxDecoration(
          color: Color(0xFF3c3e43),
          borderRadius: BorderRadius.all(Radius.circular(6))),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
              child: Container(
                  constraints: BoxConstraints(
                      maxHeight: _isOpen ? 1000 : textPainter.size.height + 10),
                  child: Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      clipBehavior: Clip.antiAliasWithSaveLayer,
                      children: widget.datas.keys.toList().map((e) {
                        final itemIndex = widget.nfts
                            .indexWhere((element) => element.classId == e);
                        return GestureDetector(
                          onTap: () {
                            setState(() {
                              _initIndex = itemIndex;
                              if (widget.onChange != null) {
                                widget.onChange!(_initIndex);
                              }
                            });
                          },
                          child: Container(
                            padding: EdgeInsets.symmetric(
                                horizontal: 5, vertical: 4),
                            decoration: BoxDecoration(
                                color: _initIndex == itemIndex
                                    ? Colors.white
                                    : Colors.white.withAlpha(28),
                                borderRadius:
                                    BorderRadius.all(Radius.circular(6))),
                            child: Text(
                              "${widget.nfts[itemIndex].metadata!['name']} x${widget.datas[e]}",
                              style: Theme.of(context)
                                  .textTheme
                                  .headline5
                                  ?.copyWith(
                                      fontSize: UI.getTextSize(12, context),
                                      fontWeight: FontWeight.w600,
                                      color: _initIndex == itemIndex
                                          ? Colors.black
                                          : PluginColorsDark.headline1),
                            ),
                          ),
                        );
                      }).toList()))),
          GestureDetector(
              onTap: () {
                setState(() {
                  _isOpen = !_isOpen;
                });
              },
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 6),
                child: Transform.rotate(
                    angle: _isOpen ? -pi : 0,
                    child: Icon(Icons.arrow_drop_down,
                        color: _isOpen
                            ? PluginColorsDark.headline1
                            : PluginColorsDark.primary,
                        size: 25)),
              ))
        ],
      ),
    );
  }
}
