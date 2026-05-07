import nodeResolve from '@rollup/plugin-node-resolve';

const external = ['@capacitor/core'];
const plugins = [nodeResolve()];

export default [
  // Core
  {
    input: 'dist/esm/index.js',
    output: [
      {
        file: 'dist/plugin.js',
        format: 'iife',
        name: 'capacitorFlybuy',
        globals: { '@capacitor/core': 'capacitorExports' },
        sourcemap: true,
        inlineDynamicImports: true,
      },
      {
        file: 'dist/plugin.cjs.js',
        format: 'cjs',
        sourcemap: true,
        inlineDynamicImports: true,
      },
    ],
    external,
    plugins,
  },
  // Pickup
  {
    input: 'dist/esm/pickup/index.js',
    output: [
      {
        file: 'dist/pickup/plugin.js',
        format: 'iife',
        name: 'capacitorFlybuyPickup',
        globals: { '@capacitor/core': 'capacitorExports' },
        sourcemap: true,
        inlineDynamicImports: true,
      },
      {
        file: 'dist/pickup/plugin.cjs.js',
        format: 'cjs',
        sourcemap: true,
        inlineDynamicImports: true,
      },
    ],
    external,
    plugins,
  },
  // Notify
  {
    input: 'dist/esm/notify/index.js',
    output: [
      {
        file: 'dist/notify/plugin.js',
        format: 'iife',
        name: 'capacitorFlybuyNotify',
        globals: { '@capacitor/core': 'capacitorExports' },
        sourcemap: true,
        inlineDynamicImports: true,
      },
      {
        file: 'dist/notify/plugin.cjs.js',
        format: 'cjs',
        sourcemap: true,
        inlineDynamicImports: true,
      },
    ],
    external,
    plugins,
  },
];