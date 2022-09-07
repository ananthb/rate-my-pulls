import { sassPlugin } from "esbuild-sass-plugin";
import esbuild from "esbuild";
import ElmPlugin from "esbuild-plugin-elm";
import path from "path";

const watch = process.argv.includes("--watch")
const isProd = process.env.NODE_ENV === "production"

esbuild.build({
  entryPoints: ["index.js", "styles.scss"],
  outdir: "public",
  bundle: true,
  minify: isProd,
  watch: watch,
  loader: {
    '.png': 'dataurl',
    '.woff': 'dataurl',
    '.woff2': 'dataurl',
    '.eot': 'dataurl',
    '.ttf': 'dataurl',
    '.svg': 'dataurl',
  },
  plugins: [
    sassPlugin({
      precompile(source, pathname) {
        const basedir = path.dirname(pathname)
        return source.replace(/(url\(['"]?)(\.\.?\/)([^'")]+['"]?\))/g, `$1${basedir}/$2$3`)
      }
    }),
    ElmPlugin({
      debug: !isProd,
      optimize: isProd,
      clearOnWatch: watch,
    }),
  ],
}).catch(_e => process.exit(1))
