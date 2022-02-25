" typescript

autocmd User ProjectionistDetect
  \ call projectionist#append(getcwd(), {
  \    '*.ts': {
  \      'alternate': [
  \        '{}.test.js', '{}.test.ts', '{}.test.tsx',
  \        '{}.stories.js', '{}.stories.ts', '{}.stories.tsx',
  \      ]
  \    },
  \    '*.test.ts': {
  \      'alternate': [
  \        '{}.stories.js', '{}.stories.ts', '{}.stories.tsx',
  \        '{}.js', '{}.ts', '{}.tsx',
  \      ]
  \    },
  \    '*.stories.ts': {
  \      'alternate': [
  \        '{}.js', '{}.ts', '{}.tsx',
  \        '{}.test.js', '{}.test.ts', '{}.test.tsx',
  \      ]
  \    },
  \ })
