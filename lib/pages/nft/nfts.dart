import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:polkawallet_plugin_acala/common/components/videoPlayerContainer.dart';
import 'package:polkawallet_plugin_acala/pages/nft/nftDetailPage.dart';
import 'package:polkawallet_plugin_acala/polkawallet_plugin_acala.dart';
import 'package:polkawallet_plugin_acala/utils/i18n/index.dart';
import 'package:polkawallet_sdk/storage/keyring.dart';
import 'package:polkawallet_sdk/utils/i18n.dart';
import 'package:polkawallet_ui/components/outlinedButtonSmall.dart';
import 'package:polkawallet_ui/components/roundedCard.dart';

class NFTs extends StatefulWidget {
  NFTs(this.plugin, this.keyring);
  final PluginAcala plugin;
  final Keyring keyring;

  @override
  _NFTsState createState() => _NFTsState();
}

const nft_filter_name_all = 'All';

class _NFTsState extends State<NFTs> {
  final GlobalKey<RefreshIndicatorState> _refreshKey =
      new GlobalKey<RefreshIndicatorState>();

  final List<String> filtersAll = [
    nft_filter_name_all,
    'Transferable',
    'Burnable',
    // 'Mintable',
    // 'ClassPropertiesMutable',
  ];
  List<String> _filters = [nft_filter_name_all];

  Future<void> _queryNFTs() async {
    final nft = await widget.plugin.api!.assets
        .queryNFTs(widget.keyring.current.address);
    if (nft != null) {
      widget.plugin.store!.assets.setNFTs(nft);
    }
  }

  @override
  Widget build(BuildContext context) {
    final dic = I18n.of(context)!.getDic(i18n_full_dic_acala, 'acala');
    return Observer(
      builder: (_) {
        final classes = {};
        final list = widget.plugin.store!.assets.nft.toList();
        if (_filters.length > 0 && !_filters.contains(nft_filter_name_all)) {
          list.retainWhere((e) => !_filters
              .map((prop) => e.properties!.contains(prop))
              .contains(false));
        }

        list.forEach((e) {
          if (classes.keys.toList().indexOf(e.classId) < 0) {
            classes[e.classId] = 1;
          } else {
            classes[e.classId] = classes[e.classId] + 1;
          }
        });
        final classKeys = classes.keys.toList();
        return Column(
          children: [
            Container(
              width: double.infinity,
              padding: EdgeInsets.fromLTRB(16, 8, 16, 16),
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 16.0,
                    spreadRadius: 4.0,
                    offset: Offset(2.0, 2.0),
                  )
                ],
              ),
              child: Wrap(
                children: filtersAll.map((e) {
                  return OutlinedButtonSmall(
                    content: dic!['nft.$e'],
                    active: _filters.contains(e),
                    padding: EdgeInsets.fromLTRB(8, 4, 8, 4),
                    margin: EdgeInsets.only(top: 8, right: 8),
                    onPressed: () async {
                      setState(() {
                        if (e == nft_filter_name_all) {
                          _filters = [nft_filter_name_all];
                        } else {
                          final old = _filters.toList();
                          if (old.contains(nft_filter_name_all)) {
                            old.remove(nft_filter_name_all);
                          }
                          if (_filters.contains(e)) {
                            old.remove(e);
                          } else {
                            old.add(e);
                          }
                          if (old.length == 0) {
                            old.add(nft_filter_name_all);
                          }
                          _filters = old;
                        }
                      });
                    },
                  );
                }).toList(),
              ),
            ),
            Expanded(
              child: Container(
                margin: EdgeInsets.all(8),
                child: RefreshIndicator(
                  key: _refreshKey,
                  onRefresh: _queryNFTs,
                  child: MasonryGridView.count(
                      crossAxisCount: 2,
                      mainAxisSpacing: 8,
                      crossAxisSpacing: 8,
                      itemCount: classKeys.length,
                      itemBuilder: (_, i) {
                        final item =
                            list.firstWhere((e) => e.classId == classKeys[i]);

                        final isMintable =
                            item.properties!.contains('Mintable');
                        final allProps = item.properties!.toList();
                        allProps.remove('ClassPropertiesMutable');
                        allProps.remove('Mintable');
                        if (!isMintable) {
                          allProps.add('Unmintable');
                        }

                        final imageUrl = item.metadata!['dwebImage'] as String;
                        return GestureDetector(
                          child: RoundedCard(
                            margin: EdgeInsets.only(bottom: 16),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(16),
                              child: Column(
                                children: [
                                  imageUrl.contains('.mp4')
                                      ? VideoPlayerContainer(imageUrl)
                                      : Image.network(
                                          '$imageUrl?imageView2/2/w/400'),
                                  Padding(
                                    padding: EdgeInsets.all(8),
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Expanded(
                                          child: Text(
                                            item.metadata!['name'],
                                            style: TextStyle(fontSize: 10),
                                          ),
                                        ),
                                        Text(
                                          'x${classes[item.classId]}',
                                          style: TextStyle(
                                              fontSize: 10,
                                              fontWeight: FontWeight.bold),
                                        )
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          onTap: () async {
                            final res = await Navigator.of(context).pushNamed(
                                NFTDetailPage.route,
                                arguments: item);
                            if (res != null) {
                              _refreshKey.currentState!.show();
                            }
                          },
                        );
                      }),
                ),
              ),
            )
          ],
        );
      },
    );
  }
}