#!/bin/bash

# Clear README.md
> README.md

# Add Title
echo -e '# Today I Learned\n' >> README.md
echo -e 'This is a collection of short notes of the things I have learned on a daily basis while working on different technologies. I share these notes as I [learn in public](https://www.learninpublic.org/).\n' >> README.md

# Initialize empty feed.json
jq -n '[]' > feed.json

dir="./learnings"
til_array=()

# Function to generate a random date between 2020-01-01 and 2025-01-01
random_date() {
  start_epoch=$(date -d "2020-01-01" +%s)
  end_epoch=$(date -d "2025-01-01" +%s)
  random_epoch=$((start_epoch + RANDOM % (end_epoch - start_epoch)))
  date -d "@$random_epoch" +%Y-%m-%d
}

# Collect metadata for existing files
for filename in "$dir"/*; do
  if [[ -f "$filename" ]]; then
    # Check for YAML front matter and extract date
    if grep -q "^---$" "$filename"; then
      date=$(sed -n '/^---$/,/^---$/p' "$filename" | grep "^date:" | sed 's/date: //;s/ *$//')
      if [[ -z "$date" || ! "$date" =~ ^[0-9]{4}-[0-9]{2}-[0-9]{2}$ ]]; then
        echo "Warning: Invalid or missing date in YAML for $filename, assigning random date" >&2
        date=$(random_date)
      fi
    else
      echo "Warning: No YAML front matter in $filename, assigning random date" >&2
      date=$(random_date)
    fi
    til_array+=("$date:$filename")
  fi
done

# Sort files by date (ascending, oldest first, newest last)
mapfile -t sorted_array < <(printf "%s\n" "${til_array[@]}" | sort -t':' -k1,1)

# Count the number of items
num_items="${#sorted_array[@]}"

# Add summary line to README.md
echo -e "_**${num_items}** TILs and counting..._\n" >> README.md

# Build JSON array and README entries
json_data=()
for element in "${sorted_array[@]}"; do
  IFS=':' read -r date filename <<< "$element"
  title=$(sed '1{/^---$/d;};1q' "$filename" | sed 's/# //')  # Skip YAML, get first non-YAML line
  path=$(basename "$filename")
  content=$(cat "$filename")

  # Add to README.md
  echo "- $date: [$title](https://github.com/krisyotam/til/blob/main/$path)" >> README.md

  # Collect JSON data
  json_data+=("$(jq -n \
    --arg content "$content" \
    --arg date "$date" \
    --arg path "$path" \
    --arg title "$title" \
    '{"content": $content, "date": $date, "path": $path, "title": $title}')"
  )
done

# Write feed.json in one go
printf '%s\n' "${json_data[@]}" | jq -s '.' > feed.json