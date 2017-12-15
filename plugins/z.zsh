export Z_PLUGIN_DIR="/usr/share/z"

# Setup z
# -------
if [[ -r "$Z_PLUGIN_DIR/z.sh"  ]]; then
  source "$Z_PLUGIN_DIR/z.sh" 2> /dev/null
fi
