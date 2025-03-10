#!/bin/bash

# Exit immediately if a command exits with a non-zero status,
# Treat unset variables as an error, and
# Prevent errors in a pipeline from being masked
set -euo pipefail
IFS=$'\n\t'

# Log file
LOG_FILE="dc_log.txt"

# Default maximum file size (in bytes) - 1MB
MAX_SIZE=${MAX_SIZE:-1048576} # Allow override via environment variable

# Function to log messages
log() {
  echo "$1"
  echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" >> "$LOG_FILE"
}

# Function to check if a file or directory is ignored by .gitignore
is_ignored() {
  local path=$1
  if git check-ignore -q --no-index "$path"; then
    return 0 # Ignored
  else
    return 1 # Not ignored
  fi
}


# Function to check if a file is binary
is_binary() {
  local file=$1
  if ! command -v file &>/dev/null; then
    log "Warning: 'file' command not found. Skipping binary file check."
    return 1 # Assume it's not binary
  fi

  mime_type=$(file -b --mime-type "$file" 2>/dev/null || echo "unknown")
  if [[ "$mime_type" == text/* ]]; then
    return 1 # Not binary
  else
    return 0 # Binary
  fi
}

# Function to check if a file exceeds the maximum size
is_too_large() {
  local file=$1
  local file_size
  file_size=$(stat -c%s "$file" 2>/dev/null || echo 0)
  if [ "$file_size" -gt "$MAX_SIZE" ]; then
    return 0 # Too large
  else
    return 1 # Not too large
  fi
}

# Function to display file content if it's a text file and within size limits
dump_file_content() {
  local file=$1
  echo "[Contents of $file:]"

  if [ -f "$file" ]; then
    if is_binary "$file"; then
      echo "Skipping binary file."
    elif is_too_large "$file"; then
      echo "Skipping large file (size > $MAX_SIZE bytes)."
    else
      if ! cat "$file"; then
        echo "Permission denied or error reading $file."
      fi
    fi
  else
    echo "File not found."
  fi
  echo
}

# Function to list directory contents and filter out ignored files
list_dir_recursive() {
  local dir=$1
  echo "[Contents of $dir:]"

  # Include hidden files
  shopt -s nullglob dotglob
  for item in "$dir"/*; do
    if [ -e "$item" ]; then
      if is_ignored "$item"; then
        echo "Skipping ignored item: $item"
        continue
      fi
      if [ -L "$item" ]; then
        echo "Symlink: $item -> $(readlink "$item")"
      elif [ -d "$item" ]; then
        echo "Directory: $item"
        list_dir_recursive "$item" # Recursively list directory contents
      elif [ -f "$item" ]; then
        echo "File: $item"
        dump_file_content "$item"
      fi
    fi
  done
  shopt -u nullglob dotglob
}

# Check if we're in a git repository
if [ ! -d .git ]; then
  echo "No .git directory found. Make sure you are in a git repository."
  exit 1
fi

# Start the recursive listing and dumping process
list_dir_recursive .
