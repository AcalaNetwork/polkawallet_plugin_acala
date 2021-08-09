const Map<String, String> enDex = {
  'acala': 'Acala Defi Hub',
  'airdrop': 'Airdrop',
  'transfer': 'Transfer',
  'receive': 'Receive',
  'dex.title': 'Swap',
  'dex.pay': 'Pay',
  'dex.receive': 'Receive',
  'dex.rate': 'Price',
  'dex.route': 'Route',
  'dex.slippage': 'Slippage Tolerance',
  'dex.slippage.error': 'Valid Slippage: 0.1%~49.9%',
  'dex.tx.pay': 'Pay with',
  'dex.tx.receive': 'Receive',
  'dex.min': 'Minimum received',
  'dex.max': 'Maximum sold',
  'dex.fee': 'Liquidity provider fee',
  'dex.impact': 'Price impact',
  'dex.lp': 'Liquidity',
  'dex.lp.add': 'Add Liquidity',
  'dex.lp.remove': 'Remove Liquidity',
  'boot.title': 'Bootstrap',
  'boot.provision': 'Provisioning',
  'boot.enabled': 'Enabled',
  'boot.provision.info':
      'The pool will start when the following conditions are met:',
  'boot.provision.condition.1': 'The liquidity target reaches',
  'boot.provision.condition.2': 'Time after',
  'boot.provision.or': 'or',
  'boot.provision.met': 'met',
  'boot.provision.add': 'Add Provision',
  'boot.ratio': 'Current ratio',
  'boot.total': 'Total',
  'boot.my': 'My Liquidity Provision',
  'boot.my.est': 'Est.',
  'boot.my.share': 'Share',
  'boot.add': 'Add',
  'loan.title': 'Mint aUSD',
  'loan.title.KSM': 'Mint kUSD',
  'loan.borrowed': 'Owed',
  'loan.collateral': 'Collateral',
  'loan.ratio': 'Collateral Ratio',
  'loan.ratio.info':
      '\nThe ratio between the USD value of your vault collateral and the amount of aUSD minted (collateral value in USD / aUSD minted).\n',
  'loan.ratio.info.KSM':
      '\nThe ratio between the USD value of your vault collateral and the amount of kUSD minted (collateral value in USD / kUSD minted).\n',
  'loan.mint': 'Mint',
  'loan.payback': 'Payback',
  'loan.deposit': 'Deposit',
  'loan.withdraw': 'Withdraw',
  'loan.withdraw.all': 'Withdraw all collateral in the meanwhile',
  'loan.create': 'Create Vault',
  'loan.liquidate': 'Liquidate',
  'liquid.price': 'Liquidation Price',
  'liquid.ratio': 'Liquidation Ratio',
  'liquid.ratio.require': 'Required Ratio',
  'liquid.price.new': 'New Liquidation Price',
  'liquid.ratio.current': 'Current Ratio',
  'liquid.ratio.new': 'New Collateral Ratio',
  'collateral.price': 'Price',
  'collateral.price.current': 'Current Price',
  'collateral.interest': 'Stability Fee',
  'collateral.require': 'Required',
  'borrow.limit': 'Mint Limit',
  'borrow.able': 'Able to MInt',
  'withdraw.able': 'Able to Withdraw',
  'loan.amount': 'Amount',
  'loan.amount.debit': 'How much would you like to mint?',
  'loan.amount.collateral': 'How much would you deposit as collateral?',
  'loan.max': 'Max',
  'loan.txs': 'History',
  'loan.warn':
      'Debt should be greater than 1aUSD or payback all, this action will have 1aUSD debt left. Are you sure to continue?',
  'loan.warn.KSM':
      'Debt should be greater than 1kUSD or payback all, this action will have 1kUSD debt left. Are you sure to continue?',
  'loan.warn.back': 'Back to modify',
  'loan.my': 'My Vaults',
  'loan.incentive': 'Incentives',
  'txs.action': 'Action',
  'payback.small': 'The remaining debt is too small',
  'earn.title': 'Earn',
  'earn.add': 'Add Liquidity',
  'earn.remove': 'Remove Liquidity',
  'earn.reward.year': 'Annualized Rewards',
  'earn.fee': 'Swap Fee',
  'earn.fee.info':
      '\nTrading fees will be automatically received when you remove liquidity.\n',
  'earn.pool': 'Liquid Pool',
  'earn.stake.pool': 'Staking Pool',
  'earn.share': 'Share',
  'earn.reward': 'Rewards',
  'earn.available': 'Available',
  'earn.stake': 'Stake',
  'earn.unStake': 'Unstake',
  'earn.unStake.info':
      'Note: unstake LP tokens before program ends will claim earned rewards & lose Loyalty Bonus.',
  'earn.staked': 'Staked',
  'earn.claim': 'Claim Rewards',
  'earn.claim.info':
      'Note: Claim now will forego your Loyalty Bonus. Are you sure to continue?',
  'earn.apy': 'APR',
  'earn.incentive': 'Mining',
  'earn.saving': 'Interest',
  'earn.loyal': 'Loyalty Bonus',
  'earn.loyal.info':
      '\nIf rewards are kept in the pool until the end of the program, there\'s an extra bonus.\n',
  'earn.withStake': 'with stake',
  'earn.withStake.txt':
      '\nwhether to stake added LP Tokens to obtain rewards.\n',
  'earn.withStake.all': 'stake all',
  'earn.withStake.all.txt': 'stake all your LP Tokens',
  'earn.withStake.info': 'Stake LP Tokens for Liquidity Mining Rewards',
  'earn.fromPool': 'with auto unstake',
  'earn.fromPool.txt':
      '\nAutomatically unstake LP Tokens and remove liquidity based on the input amount.\n',
  'faucet.title': 'Faucet',
  'faucet.brief': 'Get test Tokens of Acala testnet.',
  'faucet.ok': 'Test Tokens were sent.',
  'faucet.limit': 'Exceeds limited amount.',
  'faucet.error': 'Request error, try again later.',
  'homa.title': 'Liquid',
  'homa.mint': 'Mint',
  'homa.redeem': 'Redeem',
  'homa.now': 'Redeem Now',
  'homa.era': 'Redeem in Era',
  'homa.unbond': 'Wait for Unbounding',
  'homa.pool': 'Staking Pool',
  'homa.pool.total': 'Total',
  'homa.pool.bonded': 'Total Bonded',
  'homa.pool.free': 'Total Free',
  'homa.pool.unbonding': 'Unbonding',
  'homa.pool.ratio': 'Bond Ratio',
  'homa.pool.low': 'Insufficient pool balance',
  'homa.user': 'My DOT Redeem',
  'homa.user.unbonding': 'Unbonding',
  'homa.user.time': 'Unlock Time',
  'homa.user.blocks': 'Blocks',
  'homa.user.redeemable': 'Redeemable',
  'homa.mint.profit': 'Estimated Profit / Era',
  'homa.redeem.fee': 'Claim Fee',
  'homa.redeem.era': 'Current Era',
  'homa.redeem.period': 'Unbonding Period',
  'homa.redeem.day': 'Days',
  'homa.redeem.free': 'Pool',
  'tx.fee.or': 'or equivalent in other tokens',
  'nft.title': 'NFTs',
  'nft.testnet': 'Mandala testnet badge',
  'candy.title': 'Candy Claim',
  'candy.claim': 'Claim',
  'candy.amount': 'Candies to claim',
  'candy.claimed': 'Claimed',
  'cross.chain': 'To Chain',
  'cross.xcm': 'Cross Chain',
  'cross.chain.select': 'Select Network',
  'cross.exist': 'destination chain existential deposit',
  'cross.exist.msg':
      '\nThe minimum amount that an account should have to be deemed active.\n',
  'cross.fee': 'destination chain transfer fee',
  'cross.warn': 'Warning',
  'cross.warn.network':
      'Exchanges do not currently support direct transfers of KSM to/from Karura. In order to successfully send KSM to an exchange address, it is required that you first complete an Cross-Chain-Transfer of the token(s) from Karura to Kusama.',
  'transfer.exist': 'existential deposit',
  'transfer.fee': 'estimated transfer fee',
};
