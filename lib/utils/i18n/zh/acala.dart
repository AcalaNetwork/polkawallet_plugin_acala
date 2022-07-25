const Map<String, String> zhDex = {
  'acala': 'Acala Defi 中心',
  'airdrop': '空投',
  'transfer': '转账',
  'receive': '收款',
  'dex.title': '兑换',
  'dex.pay': '支付',
  'dex.receive': '收到',
  'dex.receiveEstimate': '收到(预估)',
  'dex.rate': '价格',
  'dex.route': '兑换路径',
  'dex.slippage': '可接受滑点',
  'dex.slippage.error': '允许的滑点范围：0.1%～49.9%',
  'dex.tx.pay': '支付',
  'dex.tx.receive': '收到',
  'dex.min': '最少收到',
  'dex.max': '最多卖出',
  'dex.fee': '交易费',
  'dex.impact': '价格影响',
  'dex.lp': '流动性',
  'dex.swap': '兑换',
  'dex.addLiquidity': '添加流动性',
  'dex.removeLiquidity': '提取流动性',
  'dex.addProvision': '添加初始流动性',
  'dex.Swap': '兑换',
  'dex.AddLiquidity': '添加流动性',
  'dex.RemoveLiquidity': '提取流动性',
  'dex.AddProvision': '添加初始流动性',
  'boot.title': '启动器',
  'boot.provision': '待启动',
  'boot.enabled': '已启动',
  'boot.provision.info': '该交易池将在以下条件达成时启动：',
  'boot.provision.condition.1': '流动性池达到',
  'boot.provision.condition.2': '时间达到',
  'boot.provision.or': '或',
  'boot.provision.met': '达成',
  'boot.provision.add': '添加初始流动性',
  'boot.ratio': '当前配比',
  'boot.total': '总量',
  'boot.my': '我提供的流动性',
  'boot.my.est': '预估',
  'boot.my.share': '份额',
  'boot.add': '添加',
  'loan.title': '生成 aUSD',
  'loan.borrowed': '当前债务',
  'loan.collateral': '质押',
  'loan.ratio': '质押率',
  'loan.ratio.info':
      '\n你的债仓中质押物的市场价值（USD计价）与你生成的 aUSD 的价值之间的比例。（即：质押物价值 / aUSD 价值）\n',
  'loan.mint': '生成',
  'loan.payback': '销毁',
  'loan.deposit': '存入',
  'loan.deposit.col': '存入质押物',
  'loan.withdraw': '取出',
  'loan.withdraw.all': '同时取出所有质押物',
  'loan.create': '创建债仓',
  'loan.liquidate': '清算',
  'liquid.price': '清算价格',
  'liquid.ratio': '清算质押率',
  'liquid.ratio.require': '安全质押率',
  'liquid.price.new': '新的清算价格',
  'liquid.ratio.current': '当前质押率',
  'liquid.ratio.new': '新的质押率',
  'collateral.price': '当前市价',
  'collateral.price.current': '当前价格',
  'collateral.interest': '稳定费率',
  'collateral.require': '安全质押数量',
  'borrow.limit': '最大额度',
  'borrow.able': '可生成',
  'borrow.min': '最低生成',
  'withdraw.able': '可取',
  'loan.amount': '数量',
  'loan.amount.debit': '您要生成多少稳定币？',
  'loan.amount.collateral': '您要存入多少质押物？',
  'loan.max': '最大值',
  'loan.txs': '交易记录',
  'loan.warn': '债仓未清零时，余额不能小于 1 aUSD，本次操作后将剩余 1 aUSD 的债务。确认继续吗？',
  'loan.warn1': '债仓未清零时，余额不能小于 ',
  'loan.warn2': 'aUSD，本次操作后将剩余 ',
  'loan.warn3': 'aUSD 的债务。确认继续吗？',
  'loan.warn4': '为了使你的债仓保持活跃，您本次必须最少铸造 ',
  'loan.warn5': 'aUSD',
  'loan.warn.back': '返回修改',
  'loan.my': '我的债仓',
  'loan.incentive': '盈利',
  'loan.activate': '激活奖励',
  'loan.activate.1': '点击这里',
  'loan.activate.2': '激活你的奖励',
  'loan.close': '关闭债仓',
  'loan.close.dex': '关闭债仓',
  'loan.close.dex.info':
      '你的一部分质押物会通过 Swap 卖掉，以归还全部 aUSD 债务，剩余的质押物将退回你的账户。确认继续吗？',
  'loan.close.receive': '预估退回质押物',
  'txs.action': '操作类型',
  'payback.small': '剩余债务过小',
  'earn.title': '盈利',
  'earn.dex': '流动性挖矿',
  'earn.loan': '债仓挖矿',
  'earn.add': '添加流动性',
  'earn.remove': '提取流动性',
  'earn.reward.year': '年化奖励',
  'earn.fee': '交易费率',
  'earn.fee.info': '\n流动性提供者提取流动性时，会自动收到交易池赚取的交易费。\n',
  'earn.pool': '流动性池',
  'earn.stake.pool': '质押池',
  'earn.share': '份额',
  'earn.reward': '收益',
  'earn.available': '可用',
  'earn.stake': '质押',
  'earn.unStake': '提取',
  'earn.unStake.info': '注意: 挖矿活动结束前从质押池中取出 LP Token 将自动领取挖矿奖励，同时损失忠诚奖励。',
  'earn.staked': '已质押',
  'earn.claim': '领取收益',
  'earn.claim.info': '提示: 现在领取将会损失你的忠诚奖励。确认现在领取吗？',
  'earn.apy': 'APR',
  'earn.apy.0': ' APR w/o Loyalty',
  'earn.incentive': '挖矿奖励',
  'earn.saving': '存款利息',
  'earn.loyal': '忠诚奖励',
  'earn.loyal.end': '忠诚奖励结束时间',
  'earn.loyal.info': '\n如果等到挖矿活动结束后才领取奖励，将会获得额外奖励。\n',
  'earn.withStake': '同时质押',
  'earn.withStake.txt': '\n是否同时将获得的 LP Token 进行质押以赚取收益。\n',
  'earn.withStake.all': '质押全部',
  'earn.withStake.all.txt': '质押全部 LP Token',
  'earn.withStake.info': '质押 LP Token 以获得流动性挖矿收益',
  'earn.fromPool': '自动解除质押',
  'earn.fromPool.txt': '\n根据输入数量自动将 LP Token 解除质押并提取流动性。\n',
  'earn.DepositDexShare': '质押 LP',
  'earn.WithdrawDexShare': '提取 LP',
  'earn.ClaimRewards': '领取收益',
  'earn.PayoutRewards': '发放奖励',
  'earn.incentive.end': '距离结束',
  'earn.incentive.blocks': '区块',
  'earn.incentive.est': '预估',
  'homa.title': 'Liquid',
  'homa.mint': '生成',
  'homa.redeem': '提取',
  'homa.fast': '快速取回',
  'homa.era': '指定 Era',
  'homa.confirm': '确定',
  'homa.unbond': '等待 DOT 解锁',
  'homa.pool': '锁定资金池',
  'homa.pool.cap': '资金池上限',
  'homa.pool.bonded': '锁定数量',
  'homa.pool.ratio': '质押率',
  'homa.pool.min': '最低质押',
  'homa.pool.redeem': '最低赎回',
  'homa.pool.issuance': '发行量',
  'homa.pool.cap.error': '超出资金池上限',
  'homa.pool.low': '资金池余额不足',
  'homa.user': '我的 DOT 提取',
  'homa.user.unbonding': '解绑中',
  'homa.user.time': '解锁时间',
  'homa.user.blocks': '区块',
  'homa.user.redeemable': '可取回',
  'homa.user.stats': '我的数据',
  'homa.mint.profit': '预估收益（每Era）',
  'homa.redeem.fee': '手续费',
  'homa.redeem.era': '当前 Era',
  'homa.redeem.period': '解锁周期',
  'homa.redeem.day': '天',
  'homa.redeem.free': '资金池',
  'homa.redeem.unbonding': '最长解锁期',
  'homa.redeem.receive': '预计收到',
  'homa.redeem.cancel': '取消',
  'homa.redeem.pending': '你当前有一笔等待中的提取请求',
  'homa.redeem.replace': '发送新的提取请求将会取消当前等待中的提取请求。',
  'homa.redeem.hint': '取消进行中的 DOT 提取请求并取回你的 LDOT。确认继续吗？',
  'homa.Minted': '生成',
  'homa.Redeemed': '提取',
  'homaLite.Redeemed': '提取',
  'homa.RedeemRequest': '提取请求',
  'homa.RequestedRedeem': '提取请求',
  'homaLite.RedeemRequested': '提取请求',
  'homa.RedeemRequestCancelled': '取消提取',
  'homa.RedeemedByFastMatch': '快速提取',
  'homa.WithdrawRedemption': '取回',
  'homa.RedeemedByUnbond': '提取',
  'homa.unbonding': '解绑中',
  'homa.claimable': '可取回',
  'homa.claim': '取回',
  'tx.fee.or': '或等额其他代币',
  'nft.title': 'NFTs',
  'nft.testnet': 'Mandala 测试网徽章',
  'nft.transfer': '发送',
  'nft.burn': '销毁',
  'nft.quantity': '数量',
  'nft.Transferable': '可转移',
  'nft.Burnable': '可销毁',
  'nft.Mintable': '可增发',
  'nft.Unmintable': '不可增发',
  'nft.ClassPropertiesMutable': '可修改',
  'nft.All': '全部',
  'nft.name': '名称',
  'nft.description': '描述',
  'nft.class': 'ClassID',
  'nft.deposit': '质押金',
  'candy.title': '领糖果',
  'candy.claim': '马上领取',
  'candy.amount': '待领取',
  'candy.claimed': '已领取',
  'cross.chain': '收款网络',
  'cross.chain.from': '转出网络',
  'cross.xcm': '跨链转账',
  'cross.chain.select': '选择网络',
  'cross.exist': '收款链存活余额',
  'cross.exist.msg': '账户在网络上存活所需要的最小余额。',
  'cross.fee': '收款链手续费',
  'cross.warn': '警告',
  'cross.edit': '修改收款地址',
  'cross.warn.info': '不建议修改跨链转账的收款地址。\n该功能仅限高级用户使用。',
  'transfer.exist': '存活余额',
  'transfer.fee': '预估手续费',
  'warn.fee': '因 ACA 余额不足，交易可能会执行失败。',
  'v3.totalBalance': '余额',
  'v3.myDefi': '我的DeFi',
  'v3.totalStaked': '总质押',
  'v3.total': '总发行',
  'v3.myStats': '我的数据',
  'v3.unbonding': '正在解绑',
  'v3.claim': '可领取',
  'v3.createVaultText': '创建一个债仓开始你的DeFi之旅',
  'v3.loan.canMint': '可铸造',
  'v3.loan.loanRatio': '借贷率',
  'v3.loan.submit': '提交',
  'v3.loan.unavailable': '生成 aUSD 暂不可用',
  'v3.homa.minStakingAmount': '质押最小值',
  'v3.homa.minUnstakingAmount': '提取最小值',
  'v3.homa.unbond': '解绑',
  'v3.homa.unbond.describe': '通过【解绑】进行提取将经历28个era（大概28天）',
  'v3.homa.stake': '质押',
  'v3.homa.stake.describe': '质押 DOT 可以获得 LDOT 并享有协议 APY.',
  'v3.homa.stake.method': '质押方式',
  'v3.homa.stake.more': '质押 LDOT 已获取奖励',
  'v3.homa.stake.more.describe': '通过质押 LDOT 获取奖励, 你还可以在债仓中 mint aUSD.',
  'v3.homa.stake.apy.total': '总 APY',
  'v3.homa.stake.apy.protocol': '协议 APY',
  'v3.homa.stake.apy.reward': '奖励 APY',
  'v3.selectRedeemMethod': '选择提取方式',
  'v3.maxCanMint': '最大可生成',
  'v3.minimumGenerate': '最少生成',
  'v3.loan.iUnderstand': '我明白了',
  'v3.loan.paybackMessage':
      '您已经销毁了所有已铸造的 aUSD，但是你仍然有已抵押的 DOT。如果您想关闭债仓，您可以同时提取所有抵押的 DOT。',
  'loan.warn.KSM1': '债仓未清零时，余额不能小于 ',
  'loan.warn.KSM2': ' aUSD，本次操作后将剩余 ',
  'loan.warn.KSM3': ' aUSD 的债务。确认继续吗？',
  'loan.warn.KSM4': '为了使你的债仓保持活跃，您本次必须最少铸造 ',
  'loan.warn.KSM5': ' aUSD',
  'v3.earn.lpTokenReceived': '至少收到',
  'v3.earn.amount': '数量',
  'v3.earn.tokenReceived': '收到的Token',
  'v3.swap.max': '最大兑换',
  'v3.earn.totalValueLocked': '总质押价值',
  'v3.earn.extraEarn': '额外收益',
  'v3.earn.stakedLpInfo': 'LP质押信息',
  'v3.earn.inviteFriends': '分享好友',
  'v3.earn.copyLink': '复制链接',
  'v3.earn.scanMessage': '扫一扫二维码，开启流动性挖矿赚取收益',
  'v3.tap': '切换',
  'v3.swap.selectToken': '选择代币',
  'v3.loan.errorMessage1': '抵押物余额不足，增加',
  'v3.loan.errorMessage2': '存入抵押物',
  'v3.loan.errorMessage3': '没有足够的余额来铸造，增加',
  'v3.loan.errorMessage4': '来偿还债务',
  'v3.earn.addLiquidityEarn': '增加流动性来盈利',
  'v3.loan.min': '最小值',
  'v3.loan.max': '最大值',
  'v3.earn.staked': '我的质押',
  'v3.earn.stakedValue': '质押值',
  'homa.fast.describe': '系统会尽快进行提取，但有可能因为某些原因导致提取失败。如果快速提取失败，系统将不会收取快速提取费。',
  'dex.swap.describe': '通过【兑换】进行提取将收取交易费',
  'v3.fastRedeemError': '快速赎回当前不可用。',
  'v3.loan.closeVault': '你当前的债仓中没有aUSD债务，您确定要提取所有质押物并关闭债仓吗？',
  'v3.loan.errorMessage5': '债仓中生成债务的最低要求是 ',
  'v3.loan.errorMessage6': ' aUSD, 你必须存入更多的抵押品才能生成足够的aUSD',
  'v3.loan.inCollateral': '在质押',
  'v3.loan.minted': '已生成',
  'v3.loan.canPayback': '可销毁',
  'v3.loan.annualStabilityFee': '稳定年费率',
  'v3.loan.currentMinted': '当前已生成',
  'v3.loan.adjustCollateral': '调整抵押',
  'v3.loan.adjustMinted': '调整铸造',
  'v3.loan.mintMeanwhile': '同时铸造更多',
  'v3.loan.paybackMeanwhile': '同时销毁',
  'v3.loan.depositMeanwhile': '同时质押更多',
  'v3.loan.withdrawMeanwhile': '同时提取',
  'v3.loan.newloanRatio': '新借贷率',
  'v3.loan.currentCollateral': '当前质押',
  'v3.loan.requiredSafety': '安全需求',
  'v3.loan.newLiquidationPrice': '新清算价格',
  'v3.loan.liquidRatio': '清算质押率',
  'event.vault.rewards': '🚀 LDOT 质押挖矿已开启! APY 最高可达',
  'loan.multiply.maxMultiple': '最大倍数',
  'loan.multiply.variableAnnualFee': '稳定费率（可波动）',
  'loan.multiply.with': '',
  'loan.multiply.message1': '敞口最高可达',
  'loan.multiply.message2': '',
  'loan.multiply.debt': '债务',
  'loan.multiply.highRisk': '高风险',
  'loan.multiply.totalExposure': '总敞口',
  'loan.multiply.adjustMultiple': '调整倍数',
  'loan.multiply.adjustYourMultiply': '调整你的倍数',
  'loan.multiply.orderInfo': '详细信息',
  'loan.multiply.buying': '购买',
  'loan.multiply.outstandingDebt': '未偿债务',
  'loan.multiply.slippageLimit': '滑点限制',
  'loan.multiply.adjustInfo': '调整信息',
  'loan.multiply.selling': '抛售',
  'loan.multiply.example': '示例',
  'loan.multiply.manageYourVault': '管理您的债仓',
  'loan.multiply.message3': '您的质押率太低，可能面临被清算的风险，本次交易有可能失败。',
  'loan.multiply.shrinkPositionDebit': '调整债仓',
  'loan.multiply.expandPositionCollateral': '调整债仓',
  'earn.dex.sort0': '默认',
  'earn.dex.sort1': '年利率最高',
  'earn.dex.sort2': '质押量最大',
  'earn.dex.sort3': '获利最多',
  'earn.dex.searchPools': '搜索池子',
  'earn.dex.joinPool': '加入LDOT-DOT池子',
  'earn.dex.joinPool.describe': '通过将流动性添加到 Taiga 的 DOT-LDOT 池中，您将获得大量奖励。',
  'earn.dex.joinPool.completed': '完成',
  'earn.dex.joinPool.back': '返回',
  'earn.dex.joinPool.message1': '为',
  'earn.dex.joinPool.message2': '池增加流动性，可获得高达',
  'earn.dex.joinPool.message3': '年利率的奖励!',
  'earn.taiga.claimAirdrop': '领取空投',
  'earn.taiga.stakeNotRequired': '无需质押',
  'earn.taiga.claimMessage': '点击认领查看您的LP详细信息并认领您的奖励',
  'earn.taiga.addLiquidity': '按代币占比添加所有资产',
  'earn.taiga.poolSize': '池子大小',
  'earn.taiga.edMessage': '由于当前地址中存活余额不足，本次交易可能失败',
  'v3.loan.message1': '最多可生成',
  'v3.loan.totalMinted': '总铸造',
  'v3.loan.needAdjust': '需要调整',
  'v3.loan.ableWithdraw': '能取回'
};
