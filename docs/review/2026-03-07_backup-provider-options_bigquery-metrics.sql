-- Backup provider config metrics (24h rolling)
-- Replace <project_id> with your Firebase-linked BigQuery project id.

DECLARE window_start TIMESTAMP DEFAULT TIMESTAMP_SUB(CURRENT_TIMESTAMP(), INTERVAL 24 HOUR);
DECLARE window_end TIMESTAMP DEFAULT CURRENT_TIMESTAMP();

WITH base AS (
  SELECT
    TIMESTAMP_MICROS(event_timestamp) AS event_ts,
    (
      SELECT ep.value.string_value
      FROM UNNEST(event_params) ep
      WHERE ep.key = 'status'
    ) AS status,
    LOWER(
      COALESCE(
        (
          SELECT ep.value.string_value
          FROM UNNEST(event_params) ep
          WHERE ep.key = 'used_default'
        ),
        CAST(
          (
            SELECT ep.value.int_value
            FROM UNNEST(event_params) ep
            WHERE ep.key = 'used_default'
          ) AS STRING
        ),
        'false'
      )
    ) AS used_default_raw,
    COALESCE(
      (
        SELECT ep.value.int_value
        FROM UNNEST(event_params) ep
        WHERE ep.key = 'raw_count'
      ),
      0
    ) AS raw_count,
    COALESCE(
      (
        SELECT ep.value.int_value
        FROM UNNEST(event_params) ep
        WHERE ep.key = 'applied_count'
      ),
      0
    ) AS applied_count,
    COALESCE(
      (
        SELECT ep.value.int_value
        FROM UNNEST(event_params) ep
        WHERE ep.key = 'invalid_count'
      ),
      0
    ) AS invalid_count,
    COALESCE(
      (
        SELECT ep.value.int_value
        FROM UNNEST(event_params) ep
        WHERE ep.key = 'duplicate_count'
      ),
      0
    ) AS duplicate_count
  FROM `analytics_<project_id>.events_*`
  WHERE event_name = 'backup_provider_config_resolved'
    AND _TABLE_SUFFIX BETWEEN FORMAT_DATE('%Y%m%d', DATE(window_start))
                         AND FORMAT_DATE('%Y%m%d', DATE(window_end))
    AND TIMESTAMP_MICROS(event_timestamp) BETWEEN window_start AND window_end
),
normalized AS (
  SELECT
    event_ts,
    status,
    CASE
      WHEN used_default_raw IN ('true', '1') THEN 1
      ELSE 0
    END AS used_default,
    raw_count,
    applied_count,
    invalid_count,
    duplicate_count
  FROM base
)
SELECT
  window_end AS window_end_at,
  COUNT(*) AS total_events,
  SUM(CASE WHEN status IN ('parsed', 'parsed_with_drops') THEN 1 ELSE 0 END) AS parse_success_events,
  SUM(CASE WHEN status = 'parsed_with_drops' THEN 1 ELSE 0 END) AS parsed_with_drops_events,
  SUM(CASE WHEN status IN ('invalid_json', 'invalid_shape', 'no_valid_rows') THEN 1 ELSE 0 END) AS hard_failure_events,
  SUM(used_default) AS default_fallback_events,
  SAFE_DIVIDE(
    SUM(CASE WHEN status IN ('parsed', 'parsed_with_drops') THEN 1 ELSE 0 END),
    COUNT(*)
  ) AS parse_success_rate,
  SAFE_DIVIDE(
    SUM(CASE WHEN status = 'parsed_with_drops' THEN 1 ELSE 0 END),
    COUNT(*)
  ) AS parsed_with_drops_rate,
  SAFE_DIVIDE(SUM(used_default), COUNT(*)) AS default_fallback_rate,
  SAFE_DIVIDE(
    SUM(CASE WHEN status IN ('invalid_json', 'invalid_shape', 'no_valid_rows') THEN 1 ELSE 0 END),
    COUNT(*)
  ) AS hard_failure_rate,
  SAFE_DIVIDE(
    SUM(invalid_count + duplicate_count),
    GREATEST(SUM(GREATEST(raw_count, 1)), 1)
  ) AS row_drop_rate,
  SAFE_DIVIDE(
    SUM(CASE WHEN status = 'missing' THEN 1 ELSE 0 END),
    COUNT(*)
  ) AS missing_rate,
  SUM(raw_count) AS raw_row_total,
  SUM(applied_count) AS applied_row_total,
  SUM(invalid_count) AS invalid_row_total,
  SUM(duplicate_count) AS duplicate_row_total
FROM normalized;
