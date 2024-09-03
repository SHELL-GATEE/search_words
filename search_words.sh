#!/bin/bash
directory="public_html"

wordlist_path="wordlist.txt"
mapfile -t words < <(grep -Ev "^$" "$wordlist_path")
emails_path="emails.txt"
mapfile -t recipient_email < <(grep -Ev "^$" "$emails_path")

##########################EXCLUDE##############################
exclusions_path="exclude.txt"
mapfile -t exclusions < <(grep -Ev "^$" "$exclusions_path")
exclusion_patterns=""
for exclusion in "${exclusions[@]}"; do
    exclusion_patterns+=" -not -path $exclusion "
done
###############################################################

public_dirs=$(find /home/*/public_html -type d -name "$directory" 2> /dev/null)
temp_file=$(mktemp)



for dir in $public_dirs; do  #Find directories     
files=$(find "$dir" -depth -type f $exclusion_patterns \
 | awk '{ if ($0 !~ /error_log$/ && $0 !~ /\/debug\/.*\.txt$/) print }')
  for file in $files; do  #iterate on each element of array 'files' created above
         for word in "${words[@]}"; do
                if grep -q "$word" "$file"; then
                echo "Found '$word' in file: $file" | tee -a "$temp_file"
                fi
         done 
  done
done



if [[ -s "$temp_file" ]]; then
  mail -s "Word Search Results" "${recipient_email[@]}" < "$temp_file"
fi

#Clean up
rm -f "$temp_file"