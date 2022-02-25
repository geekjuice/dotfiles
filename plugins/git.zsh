export GH_FORCE_TTY="1"

alias git-churn="git log --format=format: --name-only | grep -v '^$' | sort | uniq -c | sort -rg"

git-trust() {
  if [[ -d ".git" ]]; then
    mkdir -p .git/safe
    echo "trusting project \`.bin\` directory..."
  else
    echo "no git project to trust..."
  fi
}
