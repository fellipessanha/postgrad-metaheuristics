#!/bin/bash
# Generate LaTeX table rows from benchmark results
# Output format: greedy & ilp & brkga for each time (60s, 120s, 180s)

cd "$(dirname "$0")"

# Get unique instance identifiers (size + instance number)
# Extract from filenames like: result_01_id_101b_objs_500_...
# We need: instance_num (01-05) and size (500, 700, 800, 1000)

declare -A instances

# Build list of unique instances from 60s folder
for f in 60_s_run/result_*.json; do
    basename=$(basename "$f" .json)
    # Extract instance number (first 2 digits after result_)
    inst_num=$(echo "$basename" | sed 's/result_\([0-9]*\)_.*/\1/')
    # Extract size from objs_XXX
    size=$(echo "$basename" | grep -oP 'objs_\K[0-9]+')
    instances["${size}_${inst_num}"]="$basename"
done

# Sort by size then instance number
for key in $(echo "${!instances[@]}" | tr ' ' '\n' | sort -t_ -k1,1n -k2,2n); do
    size=$(echo "$key" | cut -d_ -f1)
    inst_num=$(echo "$key" | cut -d_ -f2)
    basename="${instances[$key]}"
    
    # Get scores for each time limit
    row=""
    for time_dir in 60_s_run 120_s_run 180_s_run; do
        file="${time_dir}/${basename}.json"
        if [[ -f "$file" ]]; then
            greedy=$(jq -r '.greedy.objective' "$file")
            ilp=$(jq -r '.ilp.objective | floor' "$file")
            brkga=$(jq -r '.brkga.objective' "$file")
            row="${row}${greedy} & ${ilp} & ${brkga} & "
        else
            row="${row}- & - & - & "
        fi
    done
    
    # Remove trailing " & "
    row="${row% & }"
    
    # Output: size, instance_num, scores
    echo "${size} & ${inst_num} & ${row} \\\\"
done
