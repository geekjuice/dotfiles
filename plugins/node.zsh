node() {
  ensure_node_version
  eval "command node $@"
}

npm() {
  ensure_node_version
  eval "command npm $@"
}

npx() {
  ensure_node_version
  eval "command npx $@"
}
