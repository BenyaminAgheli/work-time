#!/bin/bash

# Defaults
IS_JALALI=false
EXPORT_CSV=false
EXPORT_JSON=false
SINCE="1970-01-01"
TOTAL_HOURS=0
FILTER_DATE="0000-00-00"
JSON_OUTPUT=""

# Argument Parsing
while [[ $# -gt 0 ]]; do
    case $1 in
        -j) IS_JALALI=true; shift ;;
        --csv) EXPORT_CSV=true; shift ;;
        --json) EXPORT_JSON=true; shift ;;
        -w) FILTER_DATE=$(date -d "1 week ago" +%Y-%m-%d); shift ;;
        -m) FILTER_DATE=$(date -d "1 month ago" +%Y-%m-%d); shift ;;
        *) shift ;;
    esac
done

get-date() {
    journalctl --list-boots --no-pager | awk -v filter="$FILTER_DATE" '
        NR == 1 { next }
        {
            if ($4 < filter) next;
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

# Header Handling (Skip for JSON/CSV)
if [ "$EXPORT_CSV" = false ] && [ "$EXPORT_JSON" = false ]; then
    echo "+------------+----------+----------+-------+--------------------------------+"
    echo "|    DATE    |    IN    |    OUT   | HOURS |            VISUAL CHART        |"
    echo "+------------+----------+----------+-------+--------------------------------+"
elif [ "$EXPORT_CSV" = true ]; then
    echo "Date,In,Out,Hours"
fi

while read -r DAY DATE IN OUT; do
    
    RAW_DATE=$DATE
    if [ "$IS_JALALI" = true ]; then
        DATE=$(jdate -j ${DATE//\-/\/} +"%Y/%m/%d")
    fi

    start_sec=$(date -d "1970-01-01 $IN" +%s 2>/dev/null)
    end_sec=$(date -d "1970-01-01 $OUT" +%s 2>/dev/null)

    if [[ $? -eq 0 ]]; then
        diff_sec=$((end_sec - start_sec))
        if [ $diff_sec -lt 0 ]; then diff_sec=$((diff_sec + 86400)); fi

        hours=$(awk "BEGIN {printf \"%.2f\", $diff_sec/3600}")
        TOTAL_HOURS=$(awk "BEGIN {printf \"%.2f\", $TOTAL_HOURS + $hours}")

        if [ "$EXPORT_JSON" = true ]; then
            # Construct JSON object for this entry
            ENTRY="{\"date\":\"$DATE\",\"day\":\"$DAY\",\"in\":\"$IN\",\"out\":\"$OUT\",\"hours\":$hours}"
            if [ -z "$JSON_OUTPUT" ]; then
                JSON_OUTPUT="$ENTRY"
            else
                JSON_OUTPUT="$JSON_OUTPUT,$ENTRY"
            fi
        elif [ "$EXPORT_CSV" = true ]; then
            echo "$DATE,$IN,$OUT,$hours"
        else
            bar_count=$(awk "BEGIN {bc=int($hours * 2); print (bc>0?bc:0)}")
            bar=$(printf "%${bar_count}s" | tr ' ' '#')
            printf "| %-10s | %-8s | %-8s | %-5s | %-30s |\n" "$DATE" "$IN" "$OUT" "$hours" "$bar"
        fi
    fi

done < <(get-date)

# Footer / Final Output Handling
if [ "$EXPORT_JSON" = true ]; then
    echo "{\"total_hours\":$TOTAL_HOURS,\"sessions\":[$JSON_OUTPUT]}"
elif [ "$EXPORT_CSV" = false ]; then
    echo "+------------+----------+----------+-------+--------------------------------+"
    printf "| TOTAL ACCUMULATED HOURS: %-44s |\n" "$TOTAL_HOURS"
    echo "+------------+----------+----------+-------+--------------------------------+"
fi
