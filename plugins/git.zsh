alias git-churn="git log --format=format: --name-only | grep -v '^$' | sort | uniq -c | sort -rg"

git-trust() {
  if [[ -d ".git" ]]; then
    mkdir -p .git/safe
    echo "trusting project \`.bin\` directory..."
  else
    echo "no git project to trust..."
  fi
}

git-pull-all() {
  local DEV=1

  if [[ "$DEV" == 1 ]]; then
    echo "still developing..."
    return
  fi

  local projects=()
  for project in */; do
    if [[ -d "$project/.git" ]]; then
      projects+=("$project")
    fi
  done

  for project in "${projects[@]}"; do
    echo "- ${project%?}"
  done

  echo
  read "confirm?update projects? [y/N] "

  if [[ "$confirm" =~ ^([yY])$ ]]; then
    for project in "${projects[@]}"; do
      $(cd $project && git pull)
    done
  else
    exit 1
  fi
}
