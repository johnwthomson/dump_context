#!/bin/bash
set -euo pipefail

INSTALL_DIR="$HOME/.local/bin"
SCRIPT_NAME="dump_context"

# Remove the installed script
if [ -f "$INSTALL_DIR/$SCRIPT_NAME" ]; then
  rm "$INSTALL_DIR/$SCRIPT_NAME"
  echo "Removed $INSTALL_DIR/$SCRIPT_NAME."
else
  echo "No installed script found at $INSTALL_DIR/$SCRIPT_NAME."
fi

# Detect shell profile file (same logic as in the installer)
SHELL_RC=""
if [ -n "${BASH_VERSION-}" ]; then
  SHELL_RC="$HOME/.bashrc"
elif [ -n "${ZSH_VERSION-}" ]; then
  SHELL_RC="$HOME/.zshrc"
elif [ -n "${KSH_VERSION-}" ]; then
  SHELL_RC="$HOME/.kshrc"
elif [ -f "$HOME/.profile" ]; then
  SHELL_RC="$HOME/.profile"
fi

# If ~/.local/bin is empty (or only has hidden files), remove it and the PATH export line
if [ -d "$INSTALL_DIR" ]; then
  if [ -z "$(ls -A "$INSTALL_DIR")" ]; then
    # Remove directory if it's truly empty
    rmdir "$INSTALL_DIR"
    echo "Removed empty directory $INSTALL_DIR."
    
    # If we found a shell RC file, try removing the export line that was originally added
    if [ -n "$SHELL_RC" ] && [ -f "$SHELL_RC" ]; then
      # Remove the exact line: export PATH="$HOME/.local/bin:$PATH"
      grep -xq 'export PATH=\"$HOME/.local/bin:$PATH\"' "$SHELL_RC" 2>/dev/null && \
        sed -i '/^export PATH=\"$HOME\\/\\.local\\/bin:\\$PATH\"$/d' "$SHELL_RC"
      echo "Removed PATH export line from $SHELL_RC."
      echo "If you want to be sure, inspect $SHELL_RC manually."
    fi
  else
    echo "Directory $INSTALL_DIR is not empty. Keeping it, along with any PATH changes."
  fi
fi

echo "Uninstallation complete."
