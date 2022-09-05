import {sassPlugin} from "esbuild-sass-plugin";
import esbuild from "esbuild";
import ElmPlugin from "esbuild-plugin-elm";

const watch = process.argv.includes("--watch")
const isProd = process.env.NODE_ENV === "production"

esbuild.build({
  entryPoints: ["index.js", "styles/styles.scss"],
  bundle: true,
  outdir: "public",
  minify: isProd,
  watch,
  plugins: [
    sassPlugin(),
    ElmPlugin({
      debug: !isProd,
      optimize: isProd,
      clearOnWatch: watch,
    }),
  ],
}).catch(_e => process.exit(1))
