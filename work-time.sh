#!/bin/bash

# Defaults
IS_JALALI=false
EXPORT_CSV=false
TOTAL_HOURS=0
FILTER_DATE="0000-00-00"

# Argument Parsing
while [[ $# -gt 0 ]]; do
    case $1 in
        -j) IS_JALALI=true; shift ;;
        --csv) EXPORT_CSV=true; shift ;;
        -w) FILTER_DATE=$(date -d "1 week ago" +%Y-%m-%d); shift ;;
        -m) FILTER_DATE=$(date -d "1 month ago" +%Y-%m-%d); shift ;;
        *) shift ;;
    esac
done

get-date() {
    # We pass the FILTER_DATE into awk to handle the filtering manually
    journalctl --list-boots --no-pager | awk -v filter="$FILTER_DATE" '
        NR == 1 { next }
        {
            # $4 is the date in YYYY-MM-DD format
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

# Header Handling
if [ "$EXPORT_CSV" = false ]; then
    echo "+------------+----------+----------+-------+--------------------------------+"
    echo "|    DATE    |    IN    |    OUT   | HOURS |            VISUAL CHART        |"
    echo "+------------+----------+----------+-------+--------------------------------+"
else
    echo "Date,In,Out,Hours"
fi

while read -r DAY DATE IN OUT; do
    
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

        bar_count=$(awk "BEGIN {bc=int($hours * 2); print (bc>0?bc:0)}")
        bar=$(printf "%${bar_count}s" | tr ' ' '#')
    else
        continue
    fi

    if [ "$EXPORT_CSV" = true ]; then
        echo "$DATE,$IN,$OUT,$hours"
    else
        printf "| %-10s | %-8s | %-8s | %-5s | %-30s |\n" "$DATE" "$IN" "$OUT" "$hours" "$bar"
    fi

done < <(get-date)

# Footer
if [ "$EXPORT_CSV" = false ]; then
    echo "+------------+----------+----------+-------+--------------------------------+"
    printf "| TOTAL ACCUMULATED HOURS: %-44s     |\n" "$TOTAL_HOURS"                      
    echo "+------------+----------+----------+-------+--------------------------------+"
fi
