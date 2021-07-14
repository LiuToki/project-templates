const path = require("path");
const HtmlWebpackPlugin = require("html-webpack-plugin");

module.exports = {
    entry: path.resolve(__dirname, "client/src", "index.tsx"),
    output: {
        path: path.resolve(__dirname, "dist/client"),
        filename: "client.js",
    },
    module: {
        rules: [
            {
                test: /\.[jt]sx?$/,
                use: ["babel-loader"],
                exclude: /node_modules/,
            },
        ],
    },
    plugins: [
        new HtmlWebpackPlugin({
            template: path.resolve(__dirname, "./client/src/index.html"),
        })
    ],
    resolve: {
        extensions: ['.js', '.jsx', '.ts', '.tsx'],
    },
};
