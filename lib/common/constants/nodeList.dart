import 'package:polkawallet_plugin_acala/common/constants/base.dart';

const node_list = [
  {
    'name': 'Acala (via Dwellir)',
    'ss58': ss58_prefix_acala,
    'endpoint': 'wss://acala-rpc.dwellir.com',
  },
  {
    'name': 'Acala (via Polkawallet)',
    'ss58': ss58_prefix_acala,
    'endpoint': 'wss://acala.polkawallet.io',
  },
  {
    'name': 'Acala (via Acala Foundation 0)',
    'ss58': ss58_prefix_acala,
    'endpoint': 'wss://acala-rpc-0.aca-api.network',
  },
  {
    'name': 'Acala (via Acala Foundation 1)',
    'ss58': ss58_prefix_acala,
    'endpoint': 'wss://acala-rpc-1.aca-api.network',
  },
  {
    'name': 'Acala (via Acala Foundation 2)',
    'ss58': ss58_prefix_acala,
    'endpoint': 'wss://acala-rpc-2.aca-api.network/ws',
  },
  {
    'name': 'Acala (via Acala Foundation 3)',
    'ss58': ss58_prefix_acala,
    'endpoint': 'wss://acala-rpc-3.aca-api.network/ws',
  },
  // {
  //   'name': 'Acala (acala dev node)',
  //   'ss58': ss58_prefix_acala,
  //   'endpoint': 'wss://testnet.aca-dev.network/wendala',
  // },
];
