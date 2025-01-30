#!/bin/bash

# Clear README.md
cat /dev/null > README.md

# Add Title
echo -e '# Today I Learned\n' >> README.md
echo -e 'This is a collection of short notes of the things I have learned on a daily basis while working on different technologies. I share these notes as I [learn in public](https://www.learninpublic.org/).\n' >> README.md

# Initialize empty feed.json (to remove entries for deleted files)
jq -n '[]' > feed.json

dir=./learnings
til_array=()

# Collect metadata for existing files
for filename in "$dir"/*
do
  if [[ -f "$filename" ]]; then
    git_timestamp=$(git log --format="format:%ci" --diff-filter=A -- "$filename")
    date=($git_timestamp)
    til_array+=("$date:$filename")
  fi
done

# Sort files by date
sorted_array=($(printf "%s\n" "${til_array[@]}" | sort -r -k1,1 -t':'))

# Count the number of items
num_items=${#sorted_array[@]}

# Add the summary line to README.md
echo -e "_**${num_items}** TILs and counting..._\n" >> README.md

# Process each file and update README.md and feed.json
for element in "${sorted_array[@]}"; do
    IFS=: read date filename <<< "$element"
    title=$(head -n 1 "$filename" | sed 's/# //')
    path=$(basename "$filename")
    content=$(cat "$filename")

    # Update feed.json with the current data
    jq \
        --arg content "$content" \
        --arg date "$date" \
        --arg path "$path" \
        --arg title "$title" \
        '. += [{"content": $content, "date": $date, "path": $path, "title": $title}]' \
        feed.json > feed.json.tmp

    mv feed.json.tmp feed.json

    # Add entry to README.md
    echo "- $date: [$title](https://github.com/krisyotam/til/blob/main/$filename)" >> README.md
done
