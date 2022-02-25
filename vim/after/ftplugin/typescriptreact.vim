" typescript react

autocmd User ProjectionistDetect
  \ call projectionist#append(getcwd(), {
  \    '*.tsx': {
  \      'alternate': [
  \        '{}.test.js', '{}.test.ts', '{}.test.tsx',
  \        '{}.stories.js', '{}.stories.ts', '{}.stories.tsx',
  \      ]
  \    },
  \    '*.test.tsx': {
  \      'alternate': [
  \        '{}.stories.js', '{}.stories.ts', '{}.stories.tsx',
  \        '{}.js', '{}.ts', '{}.tsx',
  \      ]
  \    },
  \    '*.stories.tsx': {
  \      'alternate': [
  \        '{}.js', '{}.ts', '{}.tsx',
  \        '{}.test.js', '{}.test.ts', '{}.test.tsx',
  \      ]
  \    },
  \ })
