#!/bin/bash

set -euo pipefail

INSTALL_DIR="$HOME/.local/bin"
SCRIPT_NAME="dump_context"
SOURCE_SCRIPT="dump_context.sh"

# Ensure the installation directory exists
mkdir -p "$INSTALL_DIR"

# Copy the script to the installation directory
if [ ! -f "$SOURCE_SCRIPT" ]; then
  echo "Error: Source script '$SOURCE_SCRIPT' not found in the current directory."
  exit 1
fi

# Check for existing installation
if [ -f "$INSTALL_DIR/$SCRIPT_NAME" ]; then
  echo "Found existing installation at $INSTALL_DIR/$SCRIPT_NAME. Overwriting with the new version..."
fi

cp "$SOURCE_SCRIPT" "$INSTALL_DIR/$SCRIPT_NAME"
chmod +x "$INSTALL_DIR/$SCRIPT_NAME"

# Detect shell profile file
SHELL_RC=""
if [ -n "${BASH_VERSION-}" ]; then
  SHELL_RC="$HOME/.bashrc"
elif [ -n "${ZSH_VERSION-}" ]; then
  SHELL_RC="$HOME/.zshrc"
elif [ -n "${KSH_VERSION-}" ]; then
  SHELL_RC="$HOME/.kshrc"
elif [ -f "$HOME/.profile" ]; then
  SHELL_RC="$HOME/.profile"
else
  echo "Could not determine shell profile file. Please add '$INSTALL_DIR' to your PATH manually."
  exit 1
fi

# Ensure ~/.local/bin is in PATH
if ! echo "$PATH" | grep -q "$INSTALL_DIR"; then
  echo 'export PATH="$HOME/.local/bin:$PATH"' >> "$SHELL_RC"
  echo "Updated PATH in $SHELL_RC. Run 'source $SHELL_RC' or restart your terminal to apply changes."
fi

echo "Installation complete. You can now use '$SCRIPT_NAME' as a command."
