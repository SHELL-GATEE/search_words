#!/bin/bash
directory="public_html"
script_name="search_words.sh"
server_ip=$(curl -s ifconfig.me | grep -oE '([0-9]{1,3}\.){3}[0-9]{1,3}')
hostname=$(hostname)

wordlist_path="wordlist.txt"
mapfile -t words < <(grep -Ev "^$" "$wordlist_path")
emails_path="emails.txt"
mapfile -t recipient_email < <(grep -Ev "^$" "$emails_path")

public_dirs=$(find /home/*/public_html -type d -name "$directory" 2> /dev/null)
temp_file=$(mktemp)

##########################EXCLUDE##############################

exclusions_path="exclude.txt"
mapfile -t exclusions < <(grep -Ev "^$" "$exclusions_path")
exclusion_patterns=""
for exclusion in "${exclusions[@]}"; do
    exclusion_patterns+=" -not -path $exclusion "
done





######################## SEARCHING WORDS ######################
for dir in $public_dirs; do  #Find directories     
files=$(find "$dir" -depth -type f -mmin -0.25 $exclusion_patterns \
 | awk '{ if ($0 !~ /error_log$/ && $0 !~ /\/debug\/.*\.txt$/ && $0 !~ /\/qr\/.*\.png$/) print }')
  for file in $files; do  #iterate on each element of array 'files' created above
         for word in "${words[@]}"; do
                if grep -q "$word" "$file"; then
                echo "Found '$word' in file: $file" | tee -a "$temp_file"
                fi
         done 
  done
done



if [[ -s "$temp_file" ]]; then
   echo "Script Runtime $elapsed_time" >> $temp_file
   for email in "${recipient_email[@]}";do
         mail -s "$script_name report,[$server_ip] [$hostname]" "$email" < "$temp_file" 2> /dev/null
   done
fi

#Clean up
rm -f "$temp_file"


# Add to cron
if (! crontab -l | grep "for i in {1..6}; do /search_words/search_words.sh & sleep 10; done") > /dev/null; then
  cron_entry="* * * * * for i in {1..6}; do /search_words/search_words.sh & sleep 10; done"
  (crontab -l 2>/dev/null; echo "$cron_entry" ) | crontab -
  sudo systemctl restart crond
  echo "cronjob added"
fi