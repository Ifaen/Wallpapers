#!/usr/bin/env bash

WALLPAPER_DIR="$HOME/Media/Wallpapers"
OUTPUT_FILE="$WALLPAPER_DIR/README.md"
METADATA_FILE="wallpapers.json"

# Temp file to build new README content
TMP_FILE=$(mktemp)

# Header for README
echo "| File | Author | Source | Description |" > "$TMP_FILE"
echo "|------|--------|--------|-------------|" >> "$TMP_FILE"

# Initialize the metadata file if it doesn't exist
if [ ! -f "$METADATA_FILE" ]; then
  echo "[]" > "$METADATA_FILE"
fi

# Load existing metadata into an associative array
declare -A metadata_map
while IFS=$'\t' read -r filename author source description; do
  metadata_map["$filename"]="| $filename | $author | $source | $description |"
done < <(jq -r '.[] | [.filename, .author, .source, .description] | @tsv' "$METADATA_FILE")

# Collect current filenames and keep order
current_files=()
while IFS= read -r filepath; do
  filename=$(basename "$filepath")
  current_files+=("$filename")

  if [[ -z "${metadata_map[$filename]}" ]]; then
    metadata_map["$filename"]="| $filename | Unknown | Unknown | TODO |"
  fi
done < <(find "$WALLPAPER_DIR" -maxdepth 1 -type f \( -iname '*.jpg' -o -iname '*.jpeg' -o -iname '*.png' -o -iname '*.webp' \) | sort)

# Write sorted entries to README
for filename in "${current_files[@]}"; do
  echo "${metadata_map[$filename]}" >> "$TMP_FILE"
done

# Generate updated JSON metadata
{
  for filename in "${current_files[@]}"; do
    line="${metadata_map[$filename]}"
    # Extract fields using delimiter
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
mv "$TMP_FILE" "$OUTPUT_FILE"
