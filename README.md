# search_words


# to add as a cronjob runs every 10sec
```bash
* * * * * for i in {1..6}; do /time_scan/scan_public_html.sh & sleep 10; done
```
##    then restart cron service
      ```bash
        systemctl restart crond
      ```
    