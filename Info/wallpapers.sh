#!/usr/bin/env bash

# Ensure jq is installed
if ! command -v jq &> /dev/null; then
  echo "jq is not installed. Please install jq to run this script."
  exit 1
fi

process_wallpapers() {
  local IMAGE_DIR="$1"
  local METADATA_NAME="$2"
  local INFO_DIR="$WALLPAPER_DIR/Info"
  local METADATA_FILE="$INFO_DIR/${METADATA_NAME}.json"
  local README_FILE="$IMAGE_DIR/README.md"

  # Make backup
  cp "$METADATA_FILE" "${METADATA_FILE}.bak" 2>/dev/null

  # Temp file to build new README content
  TMP_FILE=$(mktemp)

  # Header for README
  echo "| File | Author | Source | Description |" > "$TMP_FILE"
  echo "|------|--------|--------|-------------|" >> "$TMP_FILE"

  # Initialize metadata file if it doesn't exist
  if [ ! -f "$METADATA_FILE" ]; then
    echo "[]" > "$METADATA_FILE"
  fi

  # Load existing metadata
  declare -A metadata_map
  while IFS=$'\t' read -r filename author source description; do
    metadata_map["$filename"]="| $filename | $author | $source | $description |"
  done < <(jq -r '.[] | [.filename, .author, .source, .description] | @tsv' "$METADATA_FILE")

  # Collect current filenames
  current_files=()
  while IFS= read -r filepath; do
    filename=$(basename "$filepath")
    current_files+=("$filename")
    if [[ -z "${metadata_map[$filename]}" ]]; then
      metadata_map["$filename"]="| $filename | Unknown | Unknown | TODO |"
    fi
  done < <(find "$IMAGE_DIR" -maxdepth 1 -type f \( -iname '*.jpg' -o -iname '*.jpeg' -o -iname '*.png' -o -iname '*.webp' \) | sort)

  # Write to README
  for filename in "${current_files[@]}"; do
    echo "${metadata_map[$filename]}" >> "$TMP_FILE"
  done

  # Write updated JSON
  {
    for filename in "${current_files[@]}"; do
      line="${metadata_map[$filename]}"
      IFS='|' read -r _ f a s d _ <<< "$line"
      f=$(echo "$f" | xargs)
      a=$(echo "$a" | xargs)
      s=$(echo "$s" | xargs)
      d=$(echo "$d" | xargs)
      jq -n --arg f "$f" --arg a "$a" --arg s "$s" --arg d "$d" \
        '{filename: $f, author: $a, source: $s, description: $d}'
    done
  } | jq -s '.' > "$METADATA_FILE"

  # Move new README into place
  mv "$TMP_FILE" "$README_FILE"
  echo "Updated: $IMAGE_DIR -> $(basename "$METADATA_FILE")"
}

# Set dirs
WALLPAPER_DIR="$HOME/Media/Wallpapers"
MOBILE_WALLPAPER_DIR="$WALLPAPER_DIR/Mobile"

# Run for both folders, storing metadata in Info/
process_wallpapers "$WALLPAPER_DIR" "wallpapers"
process_wallpapers "$MOBILE_WALLPAPER_DIR" "mobile_wallpapers"
