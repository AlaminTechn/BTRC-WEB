# BTRC QoS Monitoring - Database Schema Design
## Step 4: QoS Time-Series Data (TimescaleDB Hypertables)

| Metadata | Value |
|----------|-------|
| **Version** | 1.0 |
| **Status** | COMPLETED |
| **Created** | 2026-01-07 |
| **PRD Reference** | 16-PRD-BTRC-QoS-MONITORING-v3.1.md |
| **Database** | PostgreSQL + TimescaleDB |

---

## 4.1 Design Decisions

| Decision | Choice | Rationale |
|----------|--------|-----------|
| Counter Processing | Agent calculates rates | Agent handles counter wrapping, submits rates (bps) |
| Peak Hour Detection | Continuous aggregates | TimescaleDB auto-calculates hourly/daily rollups |
| Traceroute Storage | Status + hop count + JSON | Store summary fields + failed traces in metadata |
| Data Retention | 1 year raw, 3 years aggregated | Balance storage vs historical analysis |
| Chunk Interval | 1 day | Optimal for 5-minute polling across 1,500+ ISPs |

> **📋 Review Note**: For legacy devices with 32-bit counters at high speeds (>~34 Mbps), counter can wrap within 5-minute interval. Agent should implement RRD-style counter handling with wrap detection.

---

## 4.2 Table Definitions

### 4.2.1 ts_interface_metrics (Hypertable)
Time-series data for network interface metrics.

| Column | Type | Constraints | Description |
|--------|------|-------------|-------------|
| `time` | TIMESTAMPTZ | NOT NULL | Measurement timestamp |
| `pop_id` | INTEGER | NOT NULL | Source PoP |
| `upstream_type_id` | INTEGER | NOT NULL | Interface type (INTERNET/BDIX/CACHE/DOWNSTREAM) |
| `snmp_target_id` | INTEGER | | Source SNMP target config |
| `agent_id` | INTEGER | | Collecting agent |
| `in_bps` | BIGINT | | Inbound bits per second |
| `out_bps` | BIGINT | | Outbound bits per second |
| `in_errors` | INTEGER | | Inbound error count |
| `out_errors` | INTEGER | | Outbound error count |
| `in_discards` | INTEGER | | Inbound discards |
| `out_discards` | INTEGER | | Outbound discards |
| `utilization_in_pct` | DECIMAL(5,2) | | Inbound utilization % |
| `utilization_out_pct` | DECIMAL(5,2) | | Outbound utilization % |
| `is_counter_wrap` | BOOLEAN | DEFAULT false | Counter wrap detected |
| `quality_score` | SMALLINT | | Data quality score (1-100) |

**Hypertable Configuration**:
```sql
SELECT create_hypertable('ts_interface_metrics', 'time', chunk_time_interval => INTERVAL '1 day');
CREATE INDEX idx_ts_interface_pop_time ON ts_interface_metrics (pop_id, time DESC);
CREATE INDEX idx_ts_interface_upstream_time ON ts_interface_metrics (upstream_type_id, time DESC);
```

---

### 4.2.2 ts_subscriber_counts (Hypertable)
Time-series data for real-time subscriber counts from SNMP.

| Column | Type | Constraints | Description |
|--------|------|-------------|-------------|
| `time` | TIMESTAMPTZ | NOT NULL | Measurement timestamp |
| `pop_id` | INTEGER | NOT NULL | Source PoP |
| `source_id` | INTEGER | | subscriber_count_sources.id |
| `agent_id` | INTEGER | | Collecting agent |
| `active_sessions` | INTEGER | | Active session count |
| `pppoe_sessions` | INTEGER | | PPPoE session count |
| `dhcp_leases` | INTEGER | | DHCP lease count |
| `source_type` | VARCHAR(20) | | BRAS/RADIUS/BILLING |
| `quality_score` | SMALLINT | | Data quality score (1-100) |

**Hypertable Configuration**:
```sql
SELECT create_hypertable('ts_subscriber_counts', 'time', chunk_time_interval => INTERVAL '1 day');
CREATE INDEX idx_ts_subs_pop_time ON ts_subscriber_counts (pop_id, time DESC);
```

---

### 4.2.3 ts_qos_measurements (Hypertable)
Time-series data for QoS synthetic tests (latency, packet loss, jitter, traceroute).

| Column | Type | Constraints | Description |
|--------|------|-------------|-------------|
| `time` | TIMESTAMPTZ | NOT NULL | Measurement timestamp |
| `pop_id` | INTEGER | NOT NULL | Source PoP |
| `agent_id` | INTEGER | | Testing agent |
| `test_target_id` | INTEGER | | Target being tested |
| `test_type` | VARCHAR(20) | NOT NULL | ICMP/HTTP/DNS/TRACEROUTE/SPEEDTEST |
| `target_host` | VARCHAR(255) | | Target hostname/IP |
| `is_bdix` | BOOLEAN | | BDIX-local target |
| `latency_ms` | DECIMAL(10,3) | | Round-trip latency (ms) |
| `jitter_ms` | DECIMAL(10,3) | | Jitter (ms) |
| `packet_loss_pct` | DECIMAL(5,2) | | Packet loss percentage |
| `download_mbps` | DECIMAL(10,2) | | Download speed (speedtest) |
| `upload_mbps` | DECIMAL(10,2) | | Upload speed (speedtest) |
| `dns_resolution_ms` | DECIMAL(10,3) | | DNS resolution time |
| `http_response_ms` | DECIMAL(10,3) | | HTTP response time |
| `http_status_code` | INTEGER | | HTTP status code |
| `traceroute_status` | VARCHAR(20) | | SUCCESS/PARTIAL/FAILED |
| `traceroute_hops` | INTEGER | | Number of hops |
| `traceroute_metadata` | JSONB | | Failed traces, AS path details |
| `test_status` | VARCHAR(20) | DEFAULT 'SUCCESS' | SUCCESS/TIMEOUT/ERROR |
| `error_message` | TEXT | | Error details if failed |
| `quality_score` | SMALLINT | | Data quality score (1-100) |

**Hypertable Configuration**:
```sql
SELECT create_hypertable('ts_qos_measurements', 'time', chunk_time_interval => INTERVAL '1 day');
CREATE INDEX idx_ts_qos_pop_time ON ts_qos_measurements (pop_id, time DESC);
CREATE INDEX idx_ts_qos_type_time ON ts_qos_measurements (test_type, time DESC);
CREATE INDEX idx_ts_qos_target_time ON ts_qos_measurements (test_target_id, time DESC);
```

**Traceroute Metadata JSON Example**:
```json
{
  "hops": [
    {"hop": 1, "ip": "192.168.1.1", "rtt_ms": 1.2, "asn": null},
    {"hop": 2, "ip": "103.x.x.x", "rtt_ms": 5.4, "asn": "AS17494"},
    {"hop": 3, "ip": "*", "rtt_ms": null, "timeout": true}
  ],
  "failed_at_hop": 3,
  "failure_reason": "timeout"
}
```

---

## 4.3 Continuous Aggregates

### 4.3.1 Hourly Interface Metrics

```sql
CREATE MATERIALIZED VIEW ts_interface_metrics_hourly
WITH (timescaledb.continuous) AS
SELECT
    time_bucket('1 hour', time) AS bucket,
    pop_id,
    upstream_type_id,
    AVG(in_bps) AS avg_in_bps,
    AVG(out_bps) AS avg_out_bps,
    MAX(in_bps) AS max_in_bps,
    MAX(out_bps) AS max_out_bps,
    AVG(utilization_in_pct) AS avg_util_in,
    AVG(utilization_out_pct) AS avg_util_out,
    MAX(utilization_in_pct) AS peak_util_in,
    MAX(utilization_out_pct) AS peak_util_out,
    COUNT(*) AS sample_count
FROM ts_interface_metrics
GROUP BY bucket, pop_id, upstream_type_id
WITH NO DATA;

-- Refresh policy
SELECT add_continuous_aggregate_policy('ts_interface_metrics_hourly',
    start_offset => INTERVAL '3 hours',
    end_offset => INTERVAL '1 hour',
    schedule_interval => INTERVAL '1 hour');
```

### 4.3.2 Daily Interface Metrics

```sql
CREATE MATERIALIZED VIEW ts_interface_metrics_daily
WITH (timescaledb.continuous) AS
SELECT
    time_bucket('1 day', time) AS bucket,
    pop_id,
    upstream_type_id,
    AVG(in_bps) AS avg_in_bps,
    AVG(out_bps) AS avg_out_bps,
    MAX(in_bps) AS max_in_bps,
    MAX(out_bps) AS max_out_bps,
    PERCENTILE_CONT(0.95) WITHIN GROUP (ORDER BY in_bps) AS p95_in_bps,
    PERCENTILE_CONT(0.95) WITHIN GROUP (ORDER BY out_bps) AS p95_out_bps,
    COUNT(*) AS sample_count
FROM ts_interface_metrics
GROUP BY bucket, pop_id, upstream_type_id
WITH NO DATA;
```

### 4.3.3 Hourly QoS Metrics

```sql
CREATE MATERIALIZED VIEW ts_qos_measurements_hourly
WITH (timescaledb.continuous) AS
SELECT
    time_bucket('1 hour', time) AS bucket,
    pop_id,
    test_type,
    is_bdix,
    AVG(latency_ms) AS avg_latency_ms,
    MAX(latency_ms) AS max_latency_ms,
    MIN(latency_ms) AS min_latency_ms,
    PERCENTILE_CONT(0.95) WITHIN GROUP (ORDER BY latency_ms) AS p95_latency_ms,
    AVG(jitter_ms) AS avg_jitter_ms,
    AVG(packet_loss_pct) AS avg_packet_loss_pct,
    AVG(download_mbps) AS avg_download_mbps,
    AVG(upload_mbps) AS avg_upload_mbps,
    COUNT(*) FILTER (WHERE test_status = 'SUCCESS') AS success_count,
    COUNT(*) AS total_count
FROM ts_qos_measurements
GROUP BY bucket, pop_id, test_type, is_bdix
WITH NO DATA;
```

---

## 4.4 Data Retention Policies

```sql
-- Raw data: 1 year retention
SELECT add_retention_policy('ts_interface_metrics', INTERVAL '1 year');
SELECT add_retention_policy('ts_subscriber_counts', INTERVAL '1 year');
SELECT add_retention_policy('ts_qos_measurements', INTERVAL '1 year');

-- Hourly aggregates: 2 years retention
SELECT add_retention_policy('ts_interface_metrics_hourly', INTERVAL '2 years');
SELECT add_retention_policy('ts_qos_measurements_hourly', INTERVAL '2 years');

-- Daily aggregates: 3 years retention
SELECT add_retention_policy('ts_interface_metrics_daily', INTERVAL '3 years');
```

---

## 4.5 Entity Relationship Summary

```
pops
    ├── ts_interface_metrics (hypertable)
    │       ├── ts_interface_metrics_hourly (continuous aggregate)
    │       └── ts_interface_metrics_daily (continuous aggregate)
    │
    ├── ts_subscriber_counts (hypertable)
    │
    └── ts_qos_measurements (hypertable)
            └── ts_qos_measurements_hourly (continuous aggregate)

test_targets
    └── ts_qos_measurements
```

---

## 4.6 Estimated Data Volume

| Table | Records/Day | Records/Year | Storage/Year |
|-------|-------------|--------------|--------------|
| ts_interface_metrics | ~5.8M | ~2.1B | ~200 GB |
| ts_subscriber_counts | ~1.4M | ~520M | ~50 GB |
| ts_qos_measurements | ~2.9M | ~1.1B | ~150 GB |
| **Total Raw** | ~10M | ~3.7B | ~400 GB |
| Hourly Aggregates | ~120K | ~44M | ~10 GB |
| Daily Aggregates | ~5K | ~1.8M | ~500 MB |

**Assumptions**:
- 5,000 PoPs × 4 upstream types × 288 samples/day = 5.76M interface metrics
- 5,000 PoPs × 288 samples/day = 1.44M subscriber counts
- 5,000 PoPs × 2 test types × 288 samples/day = 2.88M QoS measurements

---

**End of Step 4 Documentation**
