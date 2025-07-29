#!/bin/bash
cd easyconfigs
for i in *.eb; do
    URL=$(cat $i|awk -F[\'\"] '/homepage/ {print $2}')
    STATUS=$(curl -LIso /dev/null -w %{http_code} $URL)
    if [ $STATUS -ne 200 ]; then
        echo "$i $URL"
    fi
done
