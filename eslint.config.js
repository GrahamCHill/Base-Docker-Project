// eslint.config.js
import js from "@eslint/js";

export default [
  js.configs.recommended,
  {
    ignores: [
      "node_modules/**",
      "dist/**",
      "build/**",
      "coverage/**",
    ],
    rules: {
      // keep this minimal at first
      "no-unused-vars": "warn",
      "no-undef": "error",
    },
  },
];
