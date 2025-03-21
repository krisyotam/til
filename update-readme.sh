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
    # Check for YAML front matter
    if grep -q "^---$" "$filename"; then
      date=$(sed -n '/^---$/,/^---$/p' "$filename" | grep "^date:" | sed 's/date: //;s/ *$//')
      title=$(sed -n '/^---$/,/^---$/p' "$filename" | grep "^title:" | sed 's/title: //;s/ *$//')
      
      # Process content by removing YAML frontmatter
      content=$(sed -e '1{/^---$/!q;};/^---$/,/^---$/d' "$filename")
      
      if [[ -z "$date" || ! "$date" =~ ^[0-9]{4}-[0-9]{2}-[0-9]{2}$ ]]; then
        echo "Warning: Invalid or missing date in YAML for $filename, assigning random date" >&2
        date=$(random_date)
      fi
      if [[ -z "$title" ]]; then
        echo "Warning: No title in YAML for $filename, using first # header" >&2
        title=$(sed -n '/^---$/,/^---$/d;/^#/p' "$filename" | head -n 1 | sed 's/# //')
      fi
    else
      echo "Warning: No YAML front matter in $filename, assigning random date" >&2
      date=$(random_date)
      title=$(sed -n '/^#/p' "$filename" | head -n 1 | sed 's/# //')
      content=$(cat "$filename")
    fi
    
    if [[ -z "$title" ]]; then
      echo "Warning: No # header found in $filename, using filename as title" >&2
      title=$(basename "$filename" .md)
    fi
    
    til_array+=("$date:$filename:$title")
  fi
done

# Sort files by date (descending, newest first, oldest last)
mapfile -t sorted_array < <(printf "%s\n" "${til_array[@]}" | sort -r -t':' -k1,1)

# Count the number of items
num_items="${#sorted_array[@]}"

# Add summary line to README.md
echo -e "_**${num_items}** TILs and counting..._\n" >> README.md

# Build JSON array and README entries with IDs
json_data=()
id=$((num_items))  # Start ID from total count (newest gets highest)
for element in "${sorted_array[@]}"; do
  IFS=':' read -r date filename title <<< "$element"
  new_filename="$dir/$id.md"
  
  # Rename the file
  if [[ "$filename" != "$new_filename" ]]; then
    mv "$filename" "$new_filename"
    git add "$filename" "$new_filename"  # Stage the rename for Git
  fi
  
  path=$(basename "$new_filename")
  
  # Read the file content
  if grep -q "^---$" "$new_filename"; then
    # For files with YAML, extract content without frontmatter and prepend title
    content=$(sed -e '1{/^---$/!q;};/^---$/,/^---$/d' "$new_filename")
    content="# $title\n\n$content"
  else
    # For files without YAML, just read the content normally
    content=$(cat "$new_filename")
  fi

  # Add to README.md
  echo "- $date: [$title](https://github.com/krisyotam/til/blob/main/$path)" >> README.md

  # Collect JSON data with ID
  json_data+=("$(jq -n \
    --arg content "$content" \
    --arg date "$date" \
    --arg path "$path" \
    --arg title "$title" \
    --argjson id "$id" \
    '{"content": $content, "date": $date, "path": $path, "title": $title, "id": $id}')"
  )
  
  id=$((id - 1))  # Decrement ID for next (older) entry
done

# Write feed.json in one go
printf '%s\n' "${json_data[@]}" | jq -s '.' > feed.json

# Stage renamed files and updated README.md/feed.json for commit
git add README.md feed.json