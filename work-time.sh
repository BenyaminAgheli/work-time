#!/bin/bash

IS_JALALI=false
while [[ $# -gt 0 ]]; do
    case $1 in
        -j) IS_JALALI=true; shift ;;
        *) shift ;; # Ignore other arguments
    esac
done

get-date() {
    journalctl --list-boots --no-pager | awk '
   	NR == 1 { next }
   	{
        d=$4; 
        s=$3" "$4" "$5; 
        e=$9; 
        if(!(d in f)) {
            f[d]=s; 
            o[++c]=d
        } 
        l[d]=e
    } 
    END {
        for(i=1;i<=c;i++) print f[o[i]] " " l[o[i]]
    }'
}

echo "+------------+----------+----------+-------+--------------------------------+"
echo "|    DATE    |    IN    |    OUT   | HOURS |           VISUAL CHART         |"
echo "+------------+----------+----------+-------+--------------------------------+"

get-date | while read -r DAY DATE IN OUT; do
    if [ "$IS_JALALI" = true ]; then
        DATE=$(jdate -j ${DATE//\-/\/} +"%Y/%m/%d")
    fi
    start_sec=$(date -d "1970-01-01 $IN" +%s 2>/dev/null)
    end_sec=$(date -d "1970-01-01 $OUT" +%s 2>/dev/null)

    if [[ $? -eq 0 ]]; then
        diff_sec=$((end_sec - start_sec))
        if [ $diff_sec -lt 0 ]; then diff_sec=$((diff_sec + 86400)); fi

        hours=$(awk "BEGIN {printf \"%.2f\", $diff_sec/3600}")

        # Calculate bar count (1 block per 30 mins)
        # We use a check to ensure bar_count is at least 0
        bar_count=$(awk "BEGIN {bc=int($hours * 2); print (bc>0?bc:0)}")

        if [ "$bar_count" -gt 0 ]; then
            bar=$(printf "%${bar_count}s" | tr ' ' '#')
        else
            bar=""
        fi
    else
        # This handles lines that don't fit the time format
        continue
    fi

    printf "| %-10s | %-8s | %-5s | %-5s | %-30s |\n" "$DATE" "$IN" "$OUT" "$hours" "$bar"

done

echo "+------------+----------+----------+-------+--------------------------------+"
