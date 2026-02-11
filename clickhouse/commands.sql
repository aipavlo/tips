-- read files from server
INSERT INTO exam.raw_api_events
SELECT *
FROM file('events.csv', 'CSVWithNames');

-- quick sanity check
SELECT
  count() AS rows,
  min(event_time) AS min_t,
  max(event_time) AS max_t,
  groupUniqArray(country) AS countries
FROM exam.raw_api_events;

-- MergeTree
CREATE TABLE exam.raw_api_events
(
  event_time DateTime64(3),
  request_id UUID,
  user_id UInt64,
  endpoint LowCardinality(String) CODEC(ZSTD(1)),
  status_code UInt16,
  latency_ms UInt32,
  country LowCardinality(FixedString(2)),
  props String DEFAULT ''
)
ENGINE = MergeTree
PARTITION BY toYYYYMM(event_time)
ORDER BY (country, event_time, endpoint, user_id, request_id);

-- check objects
SHOW CREATE TABLE exam.raw_api_events;
DESCRIBE TABLE exam.raw_api_events;

-- Time-bucketing + metrics
SELECT
  toDate(event_time) AS day,
  endpoint,
  count() AS requests,
  countIf(status_code >= 400) AS errors,
  countIf(status_code >= 400) / toFloat64(count()) AS error_rate,
  uniqExact(user_id) AS uniq_users,
  quantile(0.95)(latency_ms) AS p95_latency
FROM exam.raw_api_events
GROUP BY day, endpoint
ORDER BY day, requests DESC;

-- last value via argMax
SELECT
  user_id,
  max(event_time) AS last_time,
  argMax(endpoint, event_time) AS last_endpoint,
  argMax(status_code, event_time) AS last_status
FROM exam.raw_api_events
GROUP BY user_id;

-- Top-N for period
WITH (SELECT max(event_time) FROM exam.raw_api_events) AS tmax
SELECT endpoint, count() AS cnt
FROM exam.raw_api_events
WHERE event_time >= tmax - INTERVAL 10 MINUTE
GROUP BY endpoint
ORDER BY cnt DESC
LIMIT 3;

-- Last action for user
SELECT user_id, event_time, endpoint, status_code
FROM exam.raw_api_events
ORDER BY user_id, event_time DESC, request_id
LIMIT 2 BY user_id;

-- top endpoint p95 in country
WITH (SELECT max(event_time) FROM exam.raw_api_events) AS tmax
SELECT
  country,
  endpoint,
  quantile(0.95)(latency_ms) AS p95_latency
FROM exam.raw_api_events
WHERE event_time >= tmax - INTERVAL 7 DAY
GROUP BY country, endpoint
ORDER BY p95_latency DESC
LIMIT 1 BY country;