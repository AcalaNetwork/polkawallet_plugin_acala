import { Wallet } from "@acala-network/sdk";
import { ApiPromise, WsProvider } from "@polkadot/api";
import { decodeAddress } from "@polkadot/util-crypto";
import { u8aToHex } from "@polkadot/util";

interface ChainData {
  name: string;
  paraChainId: number;
}

const chain_name_acala = "acala";
const chain_name_polkadot = "polkadot";
const chain_name_statemint = "statemint";
const chain_name_parallel = "parallel";
const chain_name_moon = "moonbeam";

const relay_chain_token = "DOT";

const chainNodes = {
  [chain_name_polkadot]: ["wss://rpc.polkadot.io", "wss://polkadot.api.onfinality.io/public-ws", "wss://polkadot-rpc.dwellir.com"],
  [chain_name_statemint]: [
    "wss://statemint-rpc.polkadot.io",
    "wss://statemint.api.onfinality.io/public-ws",
    "wss://statemint-rpc.dwellir.com",
  ],
  [chain_name_parallel]: ["wss://parallel.api.onfinality.io/public-ws", "wss://rpc.parallel.fi", "wss://parallel-rpc.dwellir.com"],
  [chain_name_moon]: [
    "wss://wss.api.moonbeam.network",
    "wss://moonbeam.public.blastapi.io",
    "wss://moonbeam-rpc.dwellir.com",
    "wss://moonbeam.api.onfinality.io/public-ws",
  ],
};
const xcm_dest_weight_v2 = "5000000000";
const xcm_dest_weight_unlimited = "Unlimited";

const xcmApi: Record<string, ApiPromise> = {};
// let xcmApi: ApiPromise;
let wallet: Wallet;

function getApi(chainName: string) {
  return xcmApi[chainName];
}

async function _connect(nodes: string[], chainName: string) {
  return new Promise(async (resolve, reject) => {
    const wsProvider = new WsProvider(nodes);
    try {
      const res = await ApiPromise.create({
        provider: wsProvider,
      });
      if (!xcmApi[chainName]) {
        xcmApi[chainName] = res;
        (<any>window).send("log", `${chainName} wss connected success`);
        resolve(chainName);
      } else {
        res.disconnect();
        (<any>window).send("log", `${chainName} wss success and disconnected`);
        resolve(chainName);
      }
    } catch (err) {
      (<any>window).send("log", `connect failed`);
      wsProvider.disconnect();
      resolve(null);
    }
  });
}

async function connectFromChain(chainName: string[]) {
  return Promise.all(chainName.map((e) => _connectFromChain(e)));
}

async function _connectFromChain(chainName: string) {
  if (!chainNodes[chainName]) return null;

  if (!wallet) {
    wallet = new Wallet((<any>window).api);
    await wallet.isReady;
  }

  return Promise.race(chainNodes[chainName].map((node) => _connect([node], chainName)));
}

async function disconnectFromChain(chainName: string[]) {
  chainName.map((e) => {
    if (!!xcmApi[e]) {
      xcmApi[e].disconnect();
      xcmApi[e] = undefined;
    }
  });
}

async function getBalances(chainName: string, address: string, tokenNames: string[]) {
  return Promise.all(tokenNames.map((e) => _getTokenBalance(chainName, address, e)));
}

async function _getTokenBalance(chain: string, address: string, tokenNameId: string) {
  const api = xcmApi[chain];
  if (!api) return null;

  const token = await wallet.getToken(tokenNameId);
  if (chain.match(chain_name_statemint) && tokenNameId !== relay_chain_token) {
    const res = await api.query.assets.account(token.locations?.generalIndex, address);
    return {
      amount: res.toJSON()["balance"].toString(),
      tokenNameId,
      decimals: token.decimals,
    };
  }

  if (chain.match(chain_name_parallel) && token.symbol !== "PARA") {
    const tokenIds: Record<string, number> = {
      ACA: 108,
      AUSD: 104,
      LDOT: 110,
    };

    if (!tokenIds[token.name]) return null;

    const res = await api.query.assets.account(tokenIds[token.name], address);
    return {
      amount: (res as any).unwrapOrDefault().balance.toString(),
      tokenNameId,
      decimals: token.decimals,
    };
  }

  const res = await api.derive.balances.all(address);
  return {
    amount: res.availableBalance.toString(),
    tokenNameId,
    decimals: token.decimals,
  };
}

async function getTransferTx(chainFrom: ChainData, chainTo: ChainData, tokenName: string, amount: string, addressTo: string, sendFee: any) {
  if (!wallet) {
    wallet = new Wallet((<any>window).api);
    await wallet.isReady;
  }

  const token = await wallet.getToken(tokenName);

  // from acala
  if (chainFrom.name === chain_name_acala) {
    const useNewDestWeight = (<any>window).api.tx.xTokens.transfer.meta.args[3].type.toString() === "XcmV2WeightLimit";

    let dst: any;
    if (chainTo.name === chain_name_polkadot) {
      // to relay-chain
      dst = { parents: 1, interior: { X1: { AccountId32: { id: u8aToHex(decodeAddress(addressTo)), network: "Any" } } } };
    } else if (chainTo.name === chain_name_moon) {
      // to moon beam
      dst = {
        parents: 1,
        interior: {
          X2: [{ Parachain: chainTo.paraChainId }, { AccountKey20: { key: addressTo, network: "Any" } }],
        },
      };
      return token.name === "ACA" || token.name === "AUSD" || token.name === "fa://0"
        ? {
            module: "xTokens",
            call: "transfer",
            params: [token.toChainData(), amount, { V1: dst }, useNewDestWeight ? xcm_dest_weight_unlimited : xcm_dest_weight_v2],
          }
        : {
            module: "xTokens",
            call: "transferMulticurrencies",
            params: [
              [[token.toChainData(), amount], sendFee],
              1,
              { V1: dst },
              useNewDestWeight ? xcm_dest_weight_unlimited : xcm_dest_weight_v2,
            ],
          };
    } else {
      // to other parachains
      dst = {
        parents: 1,
        interior: {
          X2: [{ Parachain: chainTo.paraChainId }, { AccountId32: { id: u8aToHex(decodeAddress(addressTo)), network: "Any" } }],
        },
      };
    }

    return chainTo.name === chain_name_statemint
      ? {
          module: "xTokens",
          call: "transferMulticurrencies",
          params: [
            [[token.toChainData(), amount], sendFee],
            1,
            { V1: dst },
            useNewDestWeight ? xcm_dest_weight_unlimited : xcm_dest_weight_v2,
          ],
        }
      : {
          module: "xTokens",
          call: "transfer",
          params: [token.toChainData() as any, amount, { V1: dst }, useNewDestWeight ? xcm_dest_weight_unlimited : xcm_dest_weight_v2],
        };
  }

  // from other chains to acala
  // polkadot
  if (chainFrom.name === chain_name_polkadot && tokenName === relay_chain_token) {
    const dst = { X1: { ParaChain: chainTo.paraChainId } };
    const acc = { X1: { AccountId32: { id: u8aToHex(decodeAddress(addressTo)), network: "Any" } } };
    const ass = [{ ConcreteFungible: { amount } }];

    return {
      module: "xcmPallet",
      call: "reserveTransferAssets",
      params: [{ V0: dst }, { V0: acc }, { V0: ass }, 0],
    };
  }

  // statemint
  if (chainFrom.name === chain_name_statemint && chainTo.name === chain_name_acala) {
    const dst = { X2: ["Parent", { ParaChain: chainTo.paraChainId }] };
    const acc = { X1: { AccountId32: { id: u8aToHex(decodeAddress(addressTo)), network: "Any" } } };
    const ass = [
      {
        ConcreteFungible: {
          id: { X2: [{ PalletInstance: token.locations?.palletInstance }, { GeneralIndex: token.locations?.generalIndex }] },
          amount,
        },
      },
    ];

    return {
      module: "polkadotXcm",
      call: "limitedReserveTransferAssets",
      params: [{ V0: dst }, { V0: acc }, { V0: ass }, 0, "Unlimited"],
    };
  }

  // parallel
  if (chainFrom.name === chain_name_parallel) {
    const tokenIds: Record<string, number> = {
      "fa://1": 1,
      ACA: 108,
      AUSD: 104,
      LDOT: 110,
    };

    if (typeof tokenIds[token.name] === "undefined") return;

    const dst = {
      parents: 1,
      interior: { X2: [{ Parachain: chainTo.paraChainId }, { AccountId32: { id: u8aToHex(decodeAddress(addressTo)), network: "Any" } }] },
    };

    return {
      module: "xTokens",
      call: "transfer",
      params: [tokenIds[token.name], amount, { V1: dst }, xcm_dest_weight_unlimited],
    };
  }

  return null;
}

async function getTransferParams(
  chainFrom: ChainData,
  chainTo: ChainData,
  tokenName: string,
  amount: string,
  addressTo: string,
  sendFee: any
) {
  const res = await getTransferTx(chainFrom, chainTo, tokenName, amount, addressTo, sendFee);
  if (!res) return null;

  const { module, call, params } = res;
  const tx = (chainFrom.name === "acala" ? (<any>window).api : getApi(chainFrom.name)).tx[module][call](...params);
  return {
    module,
    call,
    params: tx.args.map((e) => e.toHuman()),
    txHex: tx.toHex(),
  };
}

export default { getApi, connectFromChain, disconnectFromChain, getBalances, getTransferParams };
