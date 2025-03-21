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

# Collect metadata for existing files
for filename in "$dir"/*; do
  if [[ -f "$filename" ]]; then
    git_timestamp=$(git log --format="%ci" --diff-filter=A -- "$filename" 2>/dev/null || echo "1970-01-01 00:00:00 +0000")
    date="${git_timestamp%% *}"  # Use only the date part (e.g., "2025-03-20")
    til_array+=("$date:$filename")
  fi
done

# Sort files by date (descending)
mapfile -t sorted_array < <(printf "%s\n" "${til_array[@]}" | sort -r -t':' -k1,1)

# Count the number of items
num_items="${#sorted_array[@]}"

# Add summary line to README.md
echo -e "_**${num_items}** TILs and counting..._\n" >> README.md

# Build JSON array and README entries
json_data=()
for element in "${sorted_array[@]}"; do
  IFS=':' read -r date filename <<< "$element"
  title=$(head -n 1 "$filename" | sed 's/# //')
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