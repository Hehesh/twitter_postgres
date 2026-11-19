#!/bin/sh

set -e

export PGPASSWORD=pass

files='
test-data.zip
'

echo 'load normalized'

for file in $files; do
    python3 load_tweets.py \
        --db "postgresql://postgres:pass@localhost:14588/postgres" \
        --inputs "$file"
done

echo 'load denormalized'

for file in $files; do
    unzip -p "$file" |
        python3 -c '
import sys

for line in sys.stdin:
    line = line.replace(r"\u0000", "")
    line = line.replace("\x00", "")
    sys.stdout.write(line)
' |
        psql \
            --host localhost \
            --port 14888 \
            --username postgres \
            --dbname postgres \
            --command "COPY tweets_jsonb (data) FROM STDIN WITH (FORMAT csv, DELIMITER E'\t', QUOTE E'\x01', ESCAPE E'\x02')"
done

