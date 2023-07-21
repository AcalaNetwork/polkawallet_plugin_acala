const plugin_cache_key = 'plugin_acala';

const plugin_genesis_hash =
    '0xfc41b9bd8ef8fe53d58c7ea67c794c7ec9a73daf05e6d54b14ff6342c99ba64c';
const acala_price_decimals = 18;
const acala_stable_coin = 'AUSD';
const acala_stable_coin_view = 'aSEED';
const acala_seed_coin = 'ASEED';
const acala_stable_coin_view_old = 'aUSD';
const acala_token_lc_dot = 'LCDOT';
const acala_token_lc_dot_view = 'lcDOT';
const acala_token_usdc = 'USDCET';
const acala_token_usdc_view = 'USDCet';

const relay_chain_name = 'polkadot';
const relay_chain_token_symbol = 'DOT';
const para_chain_name_moon = 'moonbeam';
const foreign_asset_xcm_dest_fee = '16000000000';
const xcm_dest_weight_v2 = '5000000000';

const acala_token_ids = [
  'ACA',
  'AUSD',
  'DOT',
  'LDOT',
  'LCDOT',
  'RENBTC',
  'XBTC',
  'POLKABTC',
  'PLM',
  'PHA'
];

const module_name_assets = 'assets';
const module_name_loan = 'loan';
const module_name_swap = 'swap';
const module_name_earn = 'earn';
const module_name_homa = 'homa';
const module_name_nft = 'nft';
const config_modules = {
  module_name_assets: {
    'visible': true,
    'enabled': true,
  },
  module_name_loan: {
    'visible': true,
    'enabled': true,
  },
  module_name_swap: {
    'visible': true,
    'enabled': true,
  },
  module_name_earn: {
    'visible': true,
    'enabled': true,
  },
  module_name_homa: {
    'visible': true,
    'enabled': false,
  },
  module_name_nft: {
    'visible': true,
    'enabled': true,
  },
};

const collateralFilterList = ['tDOT', 'USDCET'];
