# execute single query
clickhouse-client --host 127.0.0.1 --port 9000 --user default --query "SELECT version()"

# execute sql file
clickhouse-client --host 127.0.0.1 --user default --multiquery < ./queries.sql

# get csv or json
clickhouse-client --query "SELECT 1 AS a, 2 AS b FORMAT CSV"
clickhouse-client --query "SELECT 1 AS a, 2 AS b FORMAT JSONEachRow"

# execute with parameters
clickhouse-client --query "SET max_threads=4; SELECT count() FROM system.numbers LIMIT 100"


# Ingest files
clickhouse-client --query "INSERT INTO exam.raw_api_events FORMAT CSVWithNames" < events.csv
clickhouse-client --query "INSERT INTO exam.raw_api_events FORMAT TSVWithNames" < events.tsv
clickhouse-client --query "INSERT INTO exam.raw_api_events FORMAT JSONEachRow" < events.jsonl

# transformation via input()
clickhouse-client --query "
INSERT INTO exam.stg_api_events (request_id, event_time_minute, endpoint, props)
SELECT
  request_id,
  toStartOfMinute(event_time) AS event_time_minute,
  lower(endpoint) AS endpoint,
  if(props = '' OR props = '\"\"', '{}', props) AS props
FROM input('event_time DateTime64(3), request_id UUID, user_id UInt64, endpoint String, status_code UInt16, latency_ms UInt32, country String, props String')
FORMAT CSVWithNames
" < events.csv