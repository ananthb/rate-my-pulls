/* Copyright 2020, Ananth Bhaskararaman

   This file is part of Rate My Pulls.

   Rate My Pulls is free software: you can redistribute it and/or modify
   it under the terms of the GNU Affero General Public License as
   published by the Free Software Foundation, version 3 of the License.

   Rate My Pulls is distributed in the hope that it will be useful,
   but WITHOUT ANY WARRANTY; without even the implied warranty of
   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
   GNU Affero General Public License for more details.

   You should have received a copy of the GNU Affero General Public
   License along with Rate My Pulls.  If not, see
   <https://www.gnu.org/licenses/>.
*/

import elm from "rollup-plugin-elm";
import { terser } from "rollup-plugin-terser";
import sass from "rollup-plugin-sass";

const terse = Boolean(process.env.TERSE);

const plugins = [
  elm({
    compiler: {
      debug: !terse,
      optimize: terse,
    }
  }),
  sass({
    insert: true,
    options: {
      outputStyle: terse ? "compressed" : "expanded",
    }
  })
];

if (terse) {
  const terserOpts = {
    ecma: 3,
    compress: {
      pure_funcs: [
        "F2", "F3", "F4", "F5", "F6", "F7", "F8", "F9",
        "A2", "A3", "A4", "A5", "A6", "A7", "A8", "A9"
      ],
      pure_getters: true,
      keep_fargs: false,
      unsafe_comps: true,
      unsafe: true,
      passes: 2
    },
    mangle: true
  };
  plugins.push(terser(terserOpts));
}

export default {
  input: ["index.js", "styles/styles.scss"],
  output: {
    dir: "public",
    format: "esm",
  },
  plugins: plugins
};
