vim.cmd([[
  autocmd User ProjectionistDetect
    \ call projectionist#append(getcwd(), {
    \    '*.js': {
    \      'alternate': [
    \        '{}.test.js', '{}.test.ts', '{}.test.tsx',
    \        '{}.stories.js', '{}.stories.ts', '{}.stories.tsx',
    \      ]
    \    },
    \    '*.test.js': {
    \      'alternate': [
    \        '{}.stories.js', '{}.stories.ts', '{}.stories.tsx',
    \        '{}.js', '{}.ts', '{}.tsx',
    \      ]
    \    },
    \    '*.stories.js': {
    \      'alternate': [
    \        '{}.js', '{}.ts', '{}.tsx',
    \        '{}.test.js', '{}.test.ts', '{}.test.tsx',
    \      ]
    \    },
    \ })
]])
