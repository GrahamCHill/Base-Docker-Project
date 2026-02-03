// eslint.config.js
import js from "@eslint/js";
import tsParser from "@typescript-eslint/parser";
import vue from "eslint-plugin-vue";
import globals from "globals";
import vueParser from "vue-eslint-parser";

export default [
  // --------------------------------------------------
  // Base JavaScript (browser)
  // --------------------------------------------------
  {
    ...js.configs.recommended,
    languageOptions : {
      ecmaVersion : "latest",
      sourceType : "module",
      globals : {
        ...globals.browser,
      },
    },
  },

  // --------------------------------------------------
  // Vue / Nuxt SFCs (script + template)
  // --------------------------------------------------
  {
    files : [ "**/*.vue" ],
    languageOptions : {
      parser : vueParser,
      parserOptions : {
        parser : tsParser, // 🔴 THIS WAS MISSING
        ecmaVersion : "latest",
        sourceType : "module",
        extraFileExtensions : [ ".vue" ],
      },
      globals : {
        // Nuxt auto-imports
        definePageMeta : "readonly",
        useSeo : "readonly",
        useRoute : "readonly",
        useRouter : "readonly",
      },
    },
    plugins : {
      vue,
    },
    rules : {
      // Vue sanity
      "vue/multi-word-component-names" : "off",
      "vue/no-mutating-props" : "error",
      "vue/no-unused-components" : "warn",

      // Nuxt realities
      "no-undef" : "off",

      // Allow unused composables during development
      "no-unused-vars" : [ "warn", {argsIgnorePattern : "^_"} ],
    },
  },

  // --------------------------------------------------
  // Ignore generated output
  // --------------------------------------------------
  {
    ignores : [
      "node_modules/**",
      "dist/**",
      "build/**",
      "coverage/**",
    ],
  },
];
