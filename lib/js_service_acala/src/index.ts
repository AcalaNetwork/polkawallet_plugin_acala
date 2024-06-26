import { WsProvider, ApiPromise, ApiRx } from "@polkadot/api";
import { EvmRpcProvider } from "@acala-network/eth-providers";
import { firstValueFrom } from "rxjs";
import { subscribeMessage, getNetworkConst, getNetworkProperties } from "./service/setting";
// import keyring from "./service/keyring";
import { options } from "@acala-network/api";
import { Wallet } from "@acala-network/sdk";
import acala from "./service/acala";
import xcm from "./service/xcm";
import { genLinks } from "./utils/config/config";

// console.log will send message to MsgChannel to App
function send(path: string, data: any) {
  console.log(JSON.stringify({ path, data }));
}
send("log", "acala main js loaded");
(<any>window).send = send;

async function connectAll(nodes: string[]) {
  return Promise.race(nodes.map((node) => connect([node])));
}

async function connect(nodes: string[]) {
  (<any>window).api = undefined;

  return new Promise(async (resolve, reject) => {
    const wsProvider = new WsProvider(nodes);
    try {
      const res = new ApiPromise(options({ provider: wsProvider }));
      const resRx = new ApiRx(options({ provider: wsProvider }));
      await res.isReady;
      await firstValueFrom(resRx.isReady);
      if (!(<any>window).api) {
        (<any>window).api = res;
        (<any>window).apiRx = resRx;
        // console.log(res);
        const url = (<any>res)._options.provider.endpoint;
        await _initAcalaSDK(res, url);
        send("log", `${url} wss connected success`);
        resolve(url);
      } else {
        res.disconnect();
        const url = (<any>res)._options.provider.endpoint;
        send("log", `${url} wss success and disconnected`);
        resolve(url);
      }
    } catch (err) {
      send("log", `connect failed`);
      wsProvider.disconnect();
      resolve(null);
    }
  });
}

async function _initAcalaSDK(api: ApiPromise, url: string) {
  const evmProvider = new EvmRpcProvider(url, {
    maxBlockCacheSize: 1,
    storageCacheSize: 100,
  });
  (<any>window).wallet = new Wallet(api, { evmProvider });
  await (<any>window).wallet.isReady;
}

async function test() {}

(<any>window).settings = {
  test,
  connectAll,
  connect,
  getNetworkConst,
  getNetworkProperties,
  subscribeMessage,
  genLinks,
};
// (<any>window).keyring = keyring;
(<any>window).acala = acala;
(<any>window).xcm = xcm;
