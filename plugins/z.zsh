export Z_PLUGIN_DIR="/usr/local/etc/profile.d"

# Setup z
# -------
if [[ -r "$Z_PLUGIN_DIR/z.sh" ]]; then
  source $Z_PLUGIN_DIR/z.sh
fi
