#!/usr/bin/env bash
# Rewrites the "latest projects" block of README.md with the most recently
# created public, non-fork repositories of the profile owner.
set -euo pipefail

OWNER="${OWNER:-MartinVermel}"
COUNT="${COUNT:-6}"

list=$(gh api "users/${OWNER}/repos?type=owner&sort=created&direction=desc&per_page=100" \
  --jq "[.[] | select(.fork == false and .private == false and .name != \"${OWNER}\")]
        | .[:${COUNT}][]
        | \"| [\(.name)](\(.html_url)) | \((.description // \"\") | gsub(\"\\\\|\"; \"/\")) |\"")

block_file=$(mktemp)
{
  echo '| Project | Description |'
  echo '|---|---|'
  echo "$list"
} > "$block_file"

awk -v block_file="$block_file" '
  /<!-- LATEST:START -->/ {
    print
    while ((getline line < block_file) > 0) print line
    skip = 1
    next
  }
  /<!-- LATEST:END -->/ { skip = 0 }
  !skip
' README.md > README.tmp && mv README.tmp README.md
rm -f "$block_file"
