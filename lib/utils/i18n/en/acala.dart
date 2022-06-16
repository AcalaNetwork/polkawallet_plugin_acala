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
  'dex.swap': 'Swap',
  'dex.addLiquidity': 'Add Liquidity',
  'dex.removeLiquidity': 'Remove Liquidity',
  'dex.addProvision': 'Add Provision',
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
  'loan.borrowed': 'Owed',
  'loan.collateral': 'Collateral',
  'loan.ratio': 'Collateral Ratio',
  'loan.ratio.info':
      '\nThe ratio between the USD value of your vault collateral and the amount of aUSD minted (collateral value in USD / aUSD minted).\n',
  'loan.mint': 'Mint',
  'loan.payback': 'Payback',
  'loan.deposit': 'Deposit',
  'loan.deposit.col': 'Deposit collateral',
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
  'borrow.min': 'Min. Mint',
  'withdraw.able': 'Able to Withdraw',
  'loan.amount': 'Amount',
  'loan.amount.debit': 'How much would you like to mint?',
  'loan.amount.collateral': 'How much would you deposit as collateral?',
  'loan.max': 'Max',
  'loan.txs': 'History',
  'loan.warn':
      'Debt should be greater than 1 aUSD or payback all, this action will have 1 aUSD debt left. Are you sure to continue?',
  'loan.warn1': 'Debt should be greater than ',
  'loan.warn2': ' aUSD or payback all, this action will have ',
  'loan.warn3': ' aUSD debt left. Are you sure to continue?',
  'loan.warn4': 'To keep your vault alive, you have to mint at least ',
  'loan.warn5': ' aUSD for this time',
  'loan.warn.back': 'Back to modify',
  'loan.my': 'My Vaults',
  'loan.incentive': 'Earn',
  'loan.activate': 'Activate Rewards',
  'loan.activate.1': 'Click Here',
  'loan.activate.2': 'to activate your rewards.',
  'loan.close': 'Close Vault',
  'loan.close.dex': 'Close Vault',
  'loan.close.dex.info':
      'Part of your collateral will be sold on Swap to pay back all outstanding aUSD. The remaining collateral will be returned to your account. Are you sure to proceed?',
  'loan.close.receive': 'Estimated Receive',
  'txs.action': 'Action',
  'payback.small': 'The remaining debt is too small',
  'earn.title': 'Earn',
  'earn.dex': 'LP Staking',
  'earn.loan': 'Collateral Staking',
  'earn.add': 'Add Liquidity',
  'earn.remove': 'Remove Liquidity',
  'earn.reward.year': 'Annualized Rewards',
  'earn.fee': 'Swap Fee',
  'earn.fee.info':
      '\nTrading fees will be automatically received when you remove liquidity.\n',
  'earn.pool': 'Pool',
  'earn.stake.pool': 'Staking Pool',
  'earn.share': 'Share',
  'earn.reward': 'Rewards',
  'earn.available': 'Available',
  'earn.stake': 'Stake',
  'earn.unStake': 'Unstake',
  'earn.unStake.info':
      'Note: unstake LP tokens before program ends will claim earned rewards & lose Loyalty Bonus.',
  'earn.staked': 'Staked',
  'earn.claim': 'Claim Reward',
  'earn.claim.info':
      'Note: Claim now will forego your Loyalty Bonus. Are you sure to continue?',
  'earn.apy': 'APR',
  'earn.apy.0': 'APR w/o Loyalty',
  'earn.incentive': 'Mining',
  'earn.saving': 'Interest',
  'earn.loyal': 'Loyalty Bonus',
  'earn.loyal.end': 'loyalty program ends',
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
  'earn.DepositDexShare': 'Stake LP',
  'earn.WithdrawDexShare': 'Unstake LP',
  'earn.ClaimRewards': 'Claim Rewards',
  'earn.PayoutRewards': 'Payout Rewards',
  'earn.incentive.end': 'Ends in',
  'earn.incentive.blocks': 'blocks',
  'earn.incentive.est': 'Est.',
  'homa.title': 'Liquid',
  'homa.mint': 'Mint',
  'homa.redeem': 'Redeem',
  'homa.fast': 'Fast Redeem',
  'homa.era': 'Redeem in Era',
  'homa.confirm': 'Confirm',
  'homa.unbond': 'Wait for Unbounding',
  'homa.pool': 'Staking Pool',
  'homa.pool.cap': 'Pool Cap',
  'homa.pool.bonded': 'Total Bonded',
  'homa.pool.ratio': 'Bond Ratio',
  'homa.pool.min': 'Min bond',
  'homa.pool.redeem': 'Min redeem',
  'homa.pool.issuance': 'Issuance',
  'homa.pool.cap.error': 'Exceeds the staking pool cap.',
  'homa.pool.low': 'Insufficient pool balance',
  'homa.user': 'My DOT Redeem',
  'homa.user.unbonding': 'Unbonding',
  'homa.user.time': 'Unlock Time',
  'homa.user.blocks': 'Blocks',
  'homa.user.redeemable': 'Redeemable',
  'homa.user.stats': 'My Stats',
  'homa.mint.profit': 'Estimated Profit / Era',
  'homa.redeem.fee': 'Claim Fee',
  'homa.redeem.era': 'Current Era',
  'homa.redeem.period': 'Unbonding Period',
  'homa.redeem.day': 'Days',
  'homa.redeem.free': 'Pool',
  'homa.redeem.unbonding': 'Max Unbonding Period',
  'homa.redeem.receive': 'Expected to receive',
  'homa.redeem.cancel': 'Cancel',
  'homa.redeem.pending': 'You have a pending redeem request',
  'homa.redeem.replace':
      'By sending a new redeem request, the pending one will be canceled.',
  'homa.redeem.hint':
      'Cancel the pending redeem DOT request and receive your LDOT. Are you sure to continue?',
  'homa.Minted': 'Mint',
  'homa.Redeemed': 'Redeemed',
  'homa.RedeemRequest': 'Redeem Request',
  'homa.RedeemRequestCancelled': 'Cancel Redeem',
  'homa.RedeemedByFastMatch': 'Fast Redeemed',
  'homa.WithdrawRedemption': 'Claim Redeemed',
  'homa.RedeemedByUnbond': 'Redeemed',
  'homa.unbonding': 'Unbondings',
  'homa.claimable': 'Claimable',
  'homa.claim': 'Claim',
  'tx.fee.or': 'or equivalent in other tokens',
  'nft.title': 'NFTs',
  'nft.testnet': 'Mandala testnet badge',
  'nft.transfer': 'Transfer',
  'nft.burn': 'Burn',
  'nft.quantity': 'Quantity',
  'nft.Transferable': 'Transferable',
  'nft.Burnable': 'Burnable',
  'nft.Mintable': 'Mintable',
  'nft.Unmintable': 'Unmintable',
  'nft.ClassPropertiesMutable': 'Mutable',
  'nft.All': 'All',
  'nft.name': 'Name',
  'nft.description': 'Description',
  'nft.class': 'ClassID',
  'nft.publisher': 'Publisher',
  'nft.deposit': 'Deposit',
  'candy.title': 'Candy Claim',
  'candy.claim': 'Claim',
  'candy.amount': 'Candies to claim',
  'candy.claimed': 'Claimed',
  'cross.chain': 'To Chain',
  'cross.chain.from': 'Origin Chain',
  'cross.xcm': 'Cross Chain',
  'cross.chain.select': 'Select Network',
  'cross.exist': 'dest chain ED',
  'cross.exist.msg':
      'ED (existential deposit): The minimum amount that an account should have to be deemed active.',
  'cross.fee': 'dest chain transfer fee',
  'cross.warn': 'Warning',
  'cross.edit': 'Edit To Address',
  'cross.warn.info':
      'Editing cross-chain destination address is not recommended.\nAdvanced users only.',
  'transfer.exist': 'existential deposit',
  'transfer.fee': 'estimated transfer fee',
  'warn.fee': 'The transaction may fail due to insufficient ACA balance.',
  'v3.totalBalance': 'Balance',
  'v3.myDefi': 'My DeFi',
  'v3.totalStaked': 'Total Staked',
  'v3.total': 'Total',
  'v3.myStats': 'My Stats',
  'v3.unbonding': 'Unbonding',
  'v3.claim': 'Claim',
  'v3.createVaultText': 'Create a vault to start your DeFi adventure',
  'v3.loan.canMint': 'Can Mint',
  'v3.loan.loanRatio': 'Loan Ratio',
  'v3.loan.submit': 'Submit',
  'v3.homa.minStakingAmount': 'Minimum Staking Amount',
  'v3.homa.minUnstakingAmount': 'Minimum Unstaking Amount',
  'v3.homa.unbond': 'Unbond',
  'v3.homa.unbond.describe':
      'Redeem through unbond method will go through 28 eras (28 days approximately).',
  'v3.homa.stake': 'Stake',
  'v3.homa.stake.describe':
      'Stake DOT will mint LDOT and enjoy the protocol APY.',
  'v3.homa.stake.method': 'Stake Method',
  'v3.homa.stake.more': 'Stake LDOT for rewards',
  'v3.homa.stake.more.describe':
      'By staking LDOT for reward, you can mint aUSD in your vault.',
  'v3.homa.stake.apy.total': 'Total APY',
  'v3.homa.stake.apy.protocol': 'Protocol APY',
  'v3.homa.stake.apy.reward': 'Reward APY',
  'v3.selectRedeemMethod': 'Select redeem method',
  'v3.maxCanMint': 'Max can mint',
  'v3.minimumGenerate': 'Minimum generate',
  'v3.loan.iUnderstand': 'I understand',
  'v3.loan.paybackMessage':
      'You have paid back all the minted aUSD while you still have collateral DOT.If you want to close the vault, you can withdraw all the collateral DOT at the same time.',
  'v3.earn.lpTokenReceived': 'LP Token received',
  'v3.earn.amount': 'Amount',
  'v3.earn.tokenReceived': 'Token received',
  'v3.swap.max': 'Max Swap',
  'v3.earn.totalValueLocked': 'Total Value Locked',
  'v3.earn.extraEarn': 'Extra Earn',
  'v3.earn.stakedLpInfo': 'Staked LP Info',
  'v3.earn.inviteFriends': 'Invite Friends',
  'v3.earn.copyLink': 'Copy Link',
  'v3.earn.scanMessage': 'Scan the QR code to start mining and earn rewards!',
  'v3.tap': 'TAP',
  'v3.swap.selectToken': 'select Token',
  'v3.loan.errorMessage1': 'Insufficient balance of collateral, add',
  'v3.loan.errorMessage2': 'to deposit the collateral',
  'v3.loan.errorMessage3': 'No enough balance to mint, add',
  'v3.loan.errorMessage4': 'to payback debt',
  'v3.earn.addLiquidityEarn': 'Add liquidity to earn',
  'v3.loan.min': 'min',
  'v3.loan.max': 'max',
  'v3.earn.staked': 'My Staked',
  'v3.earn.stakedValue': 'Staked Value',
  'homa.fast.describe':
      'Fast redeem will try to redeem as fast as the system can, but it may failed by some reasons, if fast redeem failed, the system will not charge the fast redeem fee.',
  'dex.swap.describe': 'Redeem through swap will charge the trading fee.',
  'v3.fastRedeemError': 'The fast redeem is not available at the present.',
  'v3.loan.closeVault':
      'There is no minted aUSD in your current vault, are you sure you want to withdraw all your collateral and close the vault?',
  'v3.loan.errorMessage5': 'The minimum requirement for the Vault is ',
  'v3.loan.errorMessage6':
      ' aUSD, you have to deposit more collateral to mint enough aUSD',
  'v3.loan.inCollateral': 'in collateral',
  'v3.loan.minted': 'minted',
  'v3.loan.canPayback': 'Can Payback',
  'v3.loan.annualStabilityFee': 'Annual Stability Fee',
  'v3.loan.currentMinted': 'Current Minted',
  'v3.loan.adjustCollateral': 'Adjust Collateral',
  'v3.loan.adjustMinted': 'Adjust Minted',
  'v3.loan.mintMeanwhile': 'Mint more meanwhile',
  'v3.loan.paybackMeanwhile': 'Payback meanwhile',
  'v3.loan.depositMeanwhile': 'Deposit more meanwhile',
  'v3.loan.withdrawMeanwhile': 'Withdraw meanwhile',
  'v3.loan.newloanRatio': 'New Loan Ratio',
  'v3.loan.currentCollateral': 'Current Collateral',
  'v3.loan.requiredSafety': 'Required for safety',
  'v3.loan.newLiquidationPrice': 'New Liquidation Price',
  'v3.loan.liquidRatio': 'Liquidation Loan Ratio',
  'event.vault.rewards': '🚀 LDOT staking launched! Max. APY up to',
  'loan.multiply.maxMultiple': 'Max Multiple',
  'loan.multiply.variableAnnualFee': 'Variable Annual Fee',
  'loan.multiply.with': 'With',
  'loan.multiply.message1': 'Get up to',
  'loan.multiply.message2': 'exposure',
  'loan.multiply.debt': 'Debt',
  'loan.multiply.highRisk': 'High risk',
  'loan.multiply.totalExposure': 'Total exposure',
  'loan.multiply.adjustMultiple': 'Adjust Multiple',
  'loan.multiply.adjustYourMultiply': 'Adjust your Multiply',
  'loan.multiply.orderInfo': 'Order Info',
  'loan.multiply.buying': 'Buying',
  'loan.multiply.outstandingDebt': 'Outstanding debt',
  'loan.multiply.slippageLimit': 'Slippage limit',
  'loan.multiply.adjustInfo': 'Adjust Info',
  'loan.multiply.selling': 'Selling',
  'loan.multiply.example': 'Example',
  'loan.multiply.manageYourVault': 'Manage your vault',
  'loan.multiply.message3':
      'The collateral ratio is too low that may face the risk of being liquidated and this transaction might be failed. ',
  'earn.dex.sort0': 'By default',
  'earn.dex.sort1': 'By apy',
  'earn.dex.sort2': 'By staked LP',
  'earn.dex.sort3': 'By earn',
  'earn.dex.edError1': 'The Claims may fail due to',
  'earn.dex.edError2': 'is required as ED',
};
