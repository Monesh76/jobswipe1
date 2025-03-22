#!/usr/bin/env bash
set -e

# ── CONFIG ──
commits=20
start_date="2025-02-20T00:00:00"
end_date="2025-05-12T00:00:00"

# ── COLLECT FILES ──
files=()
while IFS= read -r file; do
  files+=("$file")
done < <(
  find . -type f \
    ! -path "./.git/*" \
    ! -path "*/.venv/*" \
    ! -path "*/venv/*" \
    ! -path "*/node_modules/*" \
    ! -name ".env" \
    | sort
)
total=${#files[@]}
batch_size=$(( (total + commits - 1) / commits ))

# ── CALCULATE TIMESTAMPS ──
start_ts=$(date -j -f "%Y-%m-%dT%H:%M:%S" "$start_date" "+%s")
end_ts=$(date -j -f "%Y-%m-%dT%H:%M:%S" "$end_date"   "+%s")
interval=$(( (end_ts - start_ts) / (commits - 1) ))

echo "Making $commits commits every $interval seconds."

# ── MAKE COMMITS ──
for ((i=0; i<commits; i++)); do
  chunk=( "${files[@]: i*batch_size : batch_size}" )
  git add -f "${chunk[@]}"


  this_ts=$(( start_ts + interval * i ))
  this_date=$(date -r "$this_ts" "+%Y-%m-%dT%H:%M:%S")

  GIT_AUTHOR_DATE="$this_date" \
  GIT_COMMITTER_DATE="$this_date" \
    git commit -m "Batch $((i+1)) of $commits"
done

# ── PUSH ──
git push -u origin main
