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
  random_epoch=$(( start_epoch + RANDOM % (end_epoch - start_epoch) ))
  date -d "@$random_epoch" +%Y-%m-%d
}

# Function to ensure the date is unique by incrementing by one day if needed
ensure_unique_date() {
  local base_date="$1"
  local unique_date="$base_date"
  while [[ " ${used_dates[*]} " =~ " $unique_date " ]]; do
    unique_date=$(date -d "$unique_date + 1 day" +%Y-%m-%d)
  done
  echo "$unique_date"
}

# Collect metadata for existing files
for filename in "$dir"/*; do
  if [[ -f "$filename" ]]; then
    # Check for YAML front matter
    if grep -q "^---$" "$filename"; then
      date_str=$(sed -n '/^---$/,/^---$/p' "$filename" | grep "^date:" | sed 's/date: //;s/ *$//')
      title=$(sed -n '/^---$/,/^---$/p' "$filename" | grep "^title:" | sed 's/title: //;s/ *$//')
      
      # Process content by removing YAML frontmatter
      content=$(sed -e '1{/^---$/!q;};/^---$/,/^---$/d' "$filename")
      
      if [[ -z "$date_str" || ! "$date_str" =~ ^[0-9]{4}-[0-9]{2}-[0-9]{2}$ ]]; then
        echo "Warning: Invalid or missing date in YAML for $filename, assigning random date" >&2
        date_str=$(random_date)
      fi
      if [[ -z "$title" ]]; then
        echo "Warning: No title in YAML for $filename, using first # header" >&2
        title=$(sed -n '/^---$/,/^---$/d;/^#/p' "$filename" | head -n 1 | sed 's/# //')
      fi
    else
      echo "Warning: No YAML front matter in $filename, assigning random date" >&2
      date_str=$(random_date)
      title=$(sed -n '/^#/p' "$filename" | head -n 1 | sed 's/# //')
      content=$(cat "$filename")
    fi
    
    if [[ -z "$title" ]]; then
      echo "Warning: No # header found in $filename, using filename as title" >&2
      title=$(basename "$filename" .md)
    fi
    
    til_array+=("$date_str:$filename:$title")
  fi
done

# Sort files by date (descending, newest first)
mapfile -t sorted_array < <(printf "%s\n" "${til_array[@]}" | sort -r -t':' -k1,1)
num_items="${#sorted_array[@]}"

# Add summary line to README.md
echo -e "_**${num_items}** TILs and counting..._\n" >> README.md

json_data=()
id=$((num_items))
used_dates=()  # Array to track used dates

for element in "${sorted_array[@]}"; do
  IFS=':' read -r date_str filename title <<< "$element"
  new_filename="$dir/$id.md"
  
  # Ensure unique date using a quick increment if needed
  unique_date=$(ensure_unique_date "$date_str")
  used_dates+=("$unique_date")
  
  # Rename the file if needed
  if [[ "$filename" != "$new_filename" ]]; then
    mv "$filename" "$new_filename"
    git add "$filename" "$new_filename"
  fi
  
  path=$(basename "$new_filename")
  
  # Read the file content
  if grep -q "^---$" "$new_filename"; then
    # For YAML posts, extract content without frontmatter (DO NOT prepend the title)
    content=$(sed -e '1{/^---$/!q;};/^---$/,/^---$/d' "$new_filename")
  else
    content=$(cat "$new_filename")
  fi

  # Add entry to README.md
  echo "- $unique_date: [$title](https://github.com/krisyotam/til/blob/main/$path)" >> README.md

  # Build JSON data entry
  json_data+=("$(jq -n \
    --arg content "$content" \
    --arg date "$unique_date" \
    --arg path "$path" \
    --arg title "$title" \
    --argjson id "$id" \
    '{"content": $content, "date": $date, "path": $path, "title": $title, "id": $id}')"
  )
  
  id=$((id - 1))
done

# Write feed.json in one go
printf '%s\n' "${json_data[@]}" | jq -s '.' > feed.json

# Stage updated files for commit
git add README.md feed.json
