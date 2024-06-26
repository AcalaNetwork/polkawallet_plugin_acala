const path = require("path");
const webpack = require("webpack");

const config = {
  entry: "./src/index.ts",
  output: {
    publicPath: path.resolve(__dirname, ""),
    path: path.resolve(__dirname, "dist"),
    filename: "main.js",
  },
  resolve: {
    extensions: [".ts", ".js", ".mjs", ".json", ".cjs"],
    fallback: {
      crypto: require.resolve("crypto-browserify"),
      stream: require.resolve("stream-browserify"),
      "http": require.resolve("stream-http"),
      "https": require.resolve("https-browserify"),
      "util": require.resolve("util/"),
      "url": require.resolve("url/"),
      "buffer": require.resolve("buffer"),
      "fs": false,
      "path": false,
    },
  },
  plugins: [
    new webpack.ProvidePlugin({
      Buffer: ['buffer', 'Buffer'],
    }),
    new webpack.ProvidePlugin({
      process: "process/browser.js",
    }),
  ],
  module: {
    rules: [
      {
        test: /\.ts$/,
        use: "babel-loader",
      },
      {
        test: /\.mjs$/,
        include: /node_modules/,
        type: "javascript/auto",
      },
      {
        test: /\.cjs$/,
        include: path.resolve(__dirname, "node_modules/@polkadot/"),
        use: "babel-loader",
      },
      {
        test: /\.js$/,
        include: path.resolve(__dirname, "node_modules/@polkadot/"),
        use: "babel-loader",
      },
      {
        test: /\.js$/,
        include: path.resolve(__dirname, "node_modules/@acala-network/"),
        use: "babel-loader",
      },
      {
        test: /\.js$/,
        include: path.resolve(__dirname, "node_modules/@nuts-finance/"),
        use: "babel-loader",
      },
    ],
  },
  // experiments: {
  //   syncWebAssembly: true
  // }
};

module.exports = config;
