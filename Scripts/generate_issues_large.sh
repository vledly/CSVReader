#!/bin/sh

set -eu

if [ "$#" -ne 2 ]; then
    echo "Usage: $0 <output-file> <row-count>"
    exit 1
fi

output_file=$1
row_count=$2

awk -v row_count="$row_count" '
BEGIN {
    print "\"First name\",\"Sur name\",\"Issue count\",\"Date of birth\""

    for (row = 1; row <= row_count; row++) {
        iteration = int((row - 1) / 3) + 1
        position = (row - 1) % 3

        if (position == 0) {
            printf "\"Theo%d\",\"Jansen\",5,\"1978-01-02T00:00:00\"\n", iteration
        } else if (position == 1) {
            printf "\"Fiona%d\",\"de Vries\",7,\"1950-11-12T00:00:00\"\n", iteration
        } else {
            printf "\"Petra%d\",\"Boersma\",1,\"2001-04-20T00:00:00\"\n", iteration
        }
    }
}
' > "$output_file"
