alias git-churn="git log --format=format: --name-only | grep -v '^$' | sort | uniq -c | sort -rg"
# For windowed/daily-tuned variants (hot, who, bugs, cadence, fires), use `git pulse` (bin/git-pulse).

git-trust() {
  if [[ -d ".git" ]]; then
    mkdir -p .git/safe
    echo "trusting project \`.bin\` directory..."
  else
    echo "no git project to trust..."
  fi
}
