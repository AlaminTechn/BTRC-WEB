# API_SERVER Application - All-In-One Developer Guide (Review-Pending)

| Metadata | Value |
|----------|-------|
| **Document** | API_SERVER All-In-One Developer Guide |
| **Version** | 0.9 (Initial Draft) |
| **Status** | REVIEW-PENDING |
| **Created** | 2026-01-17 |
| **Updated** | 2026-01-17 |
| **Author** | Technometrics |
| **Project** | BTRC Fixed Broadband QoS Monitoring System |
| **Alignment** | PRD v3.1, Data-Model v2.3, DB-Schema v1.1 |

---

## Document Purpose

This is the **comprehensive developer reference** for the API_SERVER application component of the BTRC QoS Monitoring System. It consolidates all specifications for the data ingestion and processing layer into a single document.

| Audience | Sections |
|----------|----------|
| **Project Managers** | 1-3 (Overview, Features) |
| **Architects** | 4-7 (Architecture, Data Flow, Database) |
| **Backend Developers** | 8-19 (APIs, Validation, Processing) |
| **DevOps/QA** | 20-22 (Deployment, Monitoring, Troubleshooting) |

## Scope

| Aspect | Value |
|--------|-------|
| **In Scope** | Ingest + Processing (SNMP, QOS, ISP-API channels) |
| **POC Exclusions** | USER_APP, REG_APP channels (deferred to Phase-II) |
| **Total Sections** | 22 |
| **Total Features** | 72 |

## Document Structure

This guide uses a **6-part structure** optimized for server-side components:

| Part | Content |
|------|---------|
| I | Overview & Features |
| II | Architecture |
| III | Database & Storage |
| IV | API Reference |
| V | Processing & Operations |
| VI | Appendices |

> **Note**: The companion agent guides (SNMP_AGENT, QOS_AGENT) use a 12-13 part structure appropriate for distributed agents, covering deployment, testing, CLI, and field operations. The structural difference reflects architectural intent—API_SERVER is a centralized service while agents are distributed components with different documentation needs.

## Related Documents

| Document | Description |
|----------|-------------|
| [Data-Model(INGESTION)](../01-planning/BTRC-FXBB-QOS-POC_Data-Model(INGESTION)_DRAFT_v0.8.md) | Data model and API specifications |
| [DB-Schema(INDEX)](../03-data/BTRC-FXBB-QOS-POC_DB-Schema(INDEX)_FINAL_v1.0.md) | Database schema reference |
| [Dev-Spec(SNMP-AGENT)](BTRC-FXBB-QOS-POC_Dev-Spec(SNMP-AGENT)_REVIEW-PENDING_v0.9.md) | SNMP Agent reference |
| [Dev-Spec(QOS-AGENT)](BTRC-FXBB-QOS-POC_Dev-Spec(QOS-AGENT)_REVIEW-PENDING_v0.9.md) | QOS Agent reference |
| 01-PROJECT-BRIEF.md | Overall project scope and requirements |

---

# PART I: OVERVIEW & FEATURES

---

## 1. Executive Summary

The API_SERVER is the central data ingestion and processing layer of the BTRC QoS Monitoring System. It receives telemetry data from distributed agents and ISP systems, validates, deduplicates, processes, and stores the data for dashboard consumption.

### Key Characteristics

| Aspect | Description |
|--------|-------------|
| **Architecture** | Per-channel containerized microservices |
| **Channels** | SNMP-CHANNEL, QOS-CHANNEL, ISP-API-CHANNEL |
| **Processing** | Shared PROCESSING container for cross-channel operations |
| **Database** | TimescaleDB (time-series), PostgreSQL (config), Redis (cache) |
| **Security** | API key authentication, TLS 1.2+, rate limiting |

**Total Features**: 72 across 10 categories

### Data Sources

| Source | Channel | Frequency | Data Type |
|--------|---------|-----------|-----------|
| SNMP_AGENT | SNMP-CHANNEL | Every 15 min | Interface metrics, subscriber counts |
| QOS_AGENT | QOS-CHANNEL | Every 15 min | Speed, latency, DNS, HTTP tests |
| ISP Portal | ISP-API-CHANNEL | Daily/Monthly | Packages, subscribers, PoPs, revenue |

### Processing Pipeline

```
┌──────────────┐    ┌──────────────┐    ┌──────────────┐    ┌──────────────┐
│   Receive    │───►│   Validate   │───►│   Dedup      │───►│    Store     │
│   (Auth)     │    │   (Schema)   │    │   (UUID)     │    │  (Timescale) │
└──────────────┘    └──────────────┘    └──────────────┘    └──────────────┘
                                                                    │
                                                                    ▼
┌──────────────┐    ┌──────────────┐    ┌──────────────┐    ┌──────────────┐
│   Dashboard  │◄───│   Aggregate  │◄───│    Alert     │◄───│  Threshold   │
│   (Query)    │    │   (Rollup)   │    │  (Generate)  │    │   (Eval)     │
└──────────────┘    └──────────────┘    └──────────────┘    └──────────────┘
```

---

## 2. Feature Summary by Category

| Category | Features | Description |
|----------|----------|-------------|
| A. Authentication & Security | 7 | API keys, TLS, rate limits | optional
| B. SNMP Ingest Pipeline | 7 | /snmp-combined endpoint |
| C. QOS Ingest Pipeline | 7 | /qos-measurements endpoint |
| D. ISP-API Ingest Pipeline | 10 | 9 data types + bulk |
| E. Validation Engine | 8 | Schema, types, bounds |
| F. Deduplication & Provenance | 6 | UUID check, trust levels | optional
| G. Threshold Evaluation | 8 | Per-channel thresholds | 
| H. Alert Generation | 7 | Create, dedup, auto-clear |
| I. Aggregation Pipeline | 6 | 15-min → hourly → daily |
| J. Observability & Monitoring | 6 | Logging, metrics, health |
| **TOTAL** | **72** | |

---

## 3. Complete Feature List


### B. SNMP Ingest Pipeline (7 features)

| # | Feature | Description |
|---|---------|-------------|
| B1 | Combined submission endpoint | POST /api/v1/submissions/snmp-combined |
| B2 | Interface metrics ingestion | 3 polls per 15-min window |
| B3 | Subscriber counts ingestion | BRAS/RAS device session counts |
| B4 | Target status tracking | HEALTHY/DEGRADED/UNREACHABLE |
| B5 | Partial submission handling | Accept available data when some targets fail |
| B6 | Counter wrap detection | Server-side 32/64-bit wrap handling |
| B7 | Rate/utilization recalculation | Verify agent calculations from raw counters |

### C. QOS Ingest Pipeline (7 features)

| # | Feature | Description |
|---|---------|-------------|
| C1 | Measurements submission endpoint | POST /api/v1/submissions/qos-measurements |
| C2 | Speed test results ingestion | Download/upload throughput |
| C3 | Ping test results ingestion | Latency, jitter, packet loss |
| C4 | DNS/HTTP/Traceroute ingestion | All active test types |
| C5 | Agent-detected failures handling | Process failure list from agent |
| C6 | Reference server status tracking | Per-server health tracking |
| C7 | Test summary validation | Verify counts match result arrays |

### D. ISP-API Ingest Pipeline (10 features)

| # | Feature | Description |
|---|---------|-------------|
| D1 | Subscriber summary ingestion | Total counts by type |
| D2 | Subscriber geo distribution | Division/district breakdown |
| D3 | Bandwidth allocation | Upstream capacity data |
| D4 | PoP information | Location and capacity |
| D5 | Service packages | Package definitions |
| D6 | SLA definitions | SLA terms *(PLANNED - Implementation TBD)* | optional
| D7 | Incident reports | Outage reporting *(PLANNED - Implementation TBD)* | optional
| D8 | Complaint summary | Customer complaints *(PLANNED - Implementation TBD)* | optional
| D9 | Revenue summary | Financial data |
| D10 | Bulk submission support | Multiple types in one call | optional


### I. Aggregation Pipeline (6 features)

| # | Feature | Description |
|---|---------|-------------|
| I1 | 15-minute raw data retention | 1 year retention |
| I2 | Hourly rollup aggregation | 1 year retention |
| I3 | Daily rollup aggregation | 3 years retention |
| I4 | Monthly summary aggregation | 7 years retention |
| I5 | ISP-level aggregation | Per-ISP totals |
| I6 | National-level aggregation | All-ISP summaries |

---

# PART II: ARCHITECTURE

---

## 4. System Architecture

### Per-Channel Container Topology

```

        ┌─────────────────────────┼─────────────────────────┐
        │                         │                         │
        ▼                         ▼                         ▼
┌───────────────────┐   ┌───────────────────┐   ┌───────────────────┐
│  SNMP-CHANNEL     │   │  QOS-CHANNEL      │   │  ISP-API-CHANNEL  │
│  CONTAINER        │   │  CONTAINER        │   │  CONTAINER        │
│                   │   │                   │   │                   │
│  /snmp-combined   │   │  /qos-measurements│   │  /isp/{id}/*      │
│  /agent-snmp/*    │   │  /agent-qos/*     │   │                   │
│                   │   │                   │   │                   │
│  Validation:SNMP  │   │  Validation:QOS   │   │  Validation:ISP   │
│  Dedup: 24hr      │   │  Dedup: 24hr      │   │  Dedup: Monthly   │
│  Trust: 95        │   │  Trust: 90        │   │  Trust: 70        │
└─────────┬─────────┘   └─────────┬─────────┘   └─────────┬─────────┘
          │                       │                       │
          └───────────────────────┼───────────────────────┘
                                  │
                    ┌─────────────────────────────┐
                    │    PROCESSING CONTAINER     │
                    │                             │
                    │  • Threshold Evaluation     │
                    │  • Aggregation Pipeline     │
                    └──────────────┬──────────────┘
                                   │
          ┌────────────────────────┼────────────────────────┐
          │                        │                        │
          ▼                        ▼                        ▼
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   TimescaleDB   │    │   PostgreSQL    │    │     Redis       │
│   (Time-series) │    │   (Config/Ref)  │    │   (Cache/Queue) │
└─────────────────┘    └─────────────────┘    └─────────────────┘
```

### Container Responsibilities

| Container | Responsibilities |
|-----------|------------------|
| **SNMP-CHANNEL** | Receive SNMP submissions, validate schema, store raw data |
| **QOS-CHANNEL** | Receive QOS measurements, validate schema, store raw data |
| **ISP-API-CHANNEL** | Receive ISP data, validate per-type schema, store |
| **PROCESSING** | aggregation,  |

### Per-Channel Policy Matrix

| Policy | SNMP-CHANNEL | QOS-CHANNEL | ISP-API-CHANNEL |
|--------|--------------|-------------|-----------------|
| Max Payload | 1 MB | 512 KB | 5 MB |
| Request Timeout | 30s | 30s | 60s |

---

## 5. Data Flow Diagrams

### 5.1 SNMP Channel Flow

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                           SNMP CHANNEL FLOW                                 │
└─────────────────────────────────────────────────────────────────────────────┘

SNMP_AGENT                    SNMP-CHANNEL CONTAINER                    DATABASE
    │                                   │                                   │
    │  POST /snmp-combined              │                                   │
    │  + X-Agent-UUID                   │                                   │
    │──────────────────────────────────►│                                   │
    │                                   │                                   │
    │                         ┌─────────┴─────────┐                         │
    │                         │ 2. VALIDATE       │                         │
    │                         │    JSON schema    │                         │
    │                         │    Required fields│                         │
    │                         │    Data types     │                         │
    │                         └─────────┬─────────┘                         │
    │                                   │                                   │
    │                                   │                                   │
    │                         ┌─────────┴─────────┐                         │
    │                         │ 4. STORE          │────────────────────────►│
    │                         │    Raw metrics    │   INSERT snmp_raw       │
    │                         │    Provenance     │   INSERT submission_log │
    │                         └─────────┬─────────┘                         │
    │                                   │                                   │
    │                                   │                                   │
    │◄──────────────────────────────────│                                   │
    │  200 OK / 202 Accepted            │                                   │
    │  { submission_uuid, status }      │                                   │
```

### 5.2 QOS Channel Flow

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                            QOS CHANNEL FLOW                                 │
└─────────────────────────────────────────────────────────────────────────────┘

QOS_AGENT                     QOS-CHANNEL CONTAINER                     DATABASE
    │                                   │                                   │
    │  POST /qos-measurements           │                                   │
    │  + X-Agent-UUID                   │                                   │
    │──────────────────────────────────►│                                   │
    │                                   │                                   │
    │                         ┌─────────┴─────────┐                         │
    │                         │ 2. VALIDATE       │                         │
    │                         │    Test results   │                         │
    │                         │    Summary counts │                         │
    │                         └─────────┬─────────┘                         │
    │                                   │                                   │
    │                         ┌─────────┴─────────┐                         │
    │                         │ 4. STORE          │────────────────────────►│
    │                         │    Speed results  │   INSERT qos_speed      │
    │                         │    Ping results   │   INSERT qos_ping       │
    │                         │    DNS/HTTP/Trace │   INSERT qos_*          │
    │                         └─────────┬─────────┘                         │
    │                                   │                                   │
    │◄──────────────────────────────────│                                   │
    │  200 OK                           │                                   │
```

### 5.3 ISP-API Channel Flow

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                          ISP-API CHANNEL FLOW                               │
└─────────────────────────────────────────────────────────────────────────────┘

ISP Portal                  ISP-API-CHANNEL CONTAINER                   DATABASE
    │                                   │                                   │
    │  POST /isp/{isp_id}/subscribers   │                                   │
    │  + X-API-Key (ISP key)            │                                   │
    │──────────────────────────────────►│                                   │
    │                                   │                                   │
    │                         ┌─────────┴─────────┐                         │
    │                         │ 2. VALIDATE       │                         │
    │                         │    Type-specific  │                         │
    │                         │    schema         │                         │
    │                         └─────────┬─────────┘                         │
    │                                   │                                   │
    │                                   │                                   │
    │                         ┌─────────┴─────────┐                         │
    │                         │ 4. STORE          │────────────────────────►│
    │                         │    ISP data       │   UPSERT isp_*          │
    │                         └─────────┬─────────┘                         │
    │                                   │                                   │
    │◄──────────────────────────────────│                                   │
    │  200 OK                           │                                   │
```

---

## 6. Processing Pipeline

### 6.1 Asynchronous Processing (Background)

| Step | Operation | Trigger | Latency |
|------|-----------|---------|---------|
| 1 | Hourly Aggregation | Cron (every hour) | < 60s |
| 2 | Daily Aggregation | Cron (daily 01:00) | < 5min |

---

## 7. Database Schema Reference

### Key Tables by Channel

| Channel | Primary Tables | Purpose |
|---------|----------------|---------|
| **SNMP** | `snmp_interface_metrics`, `snmp_subscriber_counts`, `snmp_target_status` | Raw SNMP data |
| **QOS** | `qos_speed_results`, `qos_ping_results`, `qos_dns_results`, `qos_http_results` | Raw QOS data |
| **ISP-API** | `isp_packages`, `isp_subscribers`, `isp_pops`, `isp_revenue` | ISP-reported data |
| **Processing** | `aggregation_hourly`, `aggregation_daily` | Processed data |
| **Common** | `submission_log`, , `isp_registry` | Reference data |

---

# PART III: SNMP CHANNEL API REFERENCE

---

## 8. SNMP Combined Submission API

### 8.1 Endpoint

```
POST /api/v1/submissions/snmp-combined
```

### 8.2 Request Headers

| Header | Required | Description |
|--------|----------|-------------|
| `Content-Type` | Yes | `application/json` |
| `X-Agent-UUID` | Yes | Registered agent UUID |

### 8.3 Request Body Schema

```json
{
  "submission": {
    "submission_uuid": "UUID - unique per submission",
    "originator_type": "SNMP_AGENT",
    "agent_uuid": "UUID - agent identifier", 
    "agent_version": "string - semver",
    "isp_id": "integer - ISP identifier",
    "submission_time": "ISO8601 - when submitted",
    "reporting_period_start": "ISO8601 - window start",
    "reporting_period_end": "ISO8601 - window end",
    "poll_interval_sec": "integer - poll interval (300)",
    "polls_in_batch": "integer - polls per window (3)",
    "summary": {
      "interface_records": "integer",
      "subscriber_records": "integer",
      "total_records": "integer",
      "successful_polls": "integer",
      "failed_polls": "integer",
      "partial_submission": "boolean"
    }
  },
  "agent_status": { "..." },
  "target_status": [ "..." ],
  "interface_metrics": [ "..." ],
  "subscriber_counts": [ "..." ],
  "alerts": [ "..." ]
}
```

### 8.4 Full Request Example

```json
{
  "submission": {
    "submission_uuid": "550e8400-e29b-41d4-a716-446655440000",
    "originator_type": "SNMP_AGENT",
    "agent_uuid": "7c9e6679-7425-40de-944b-e07fc1f90ae7",
    "agent_version": "1.2.3",
    "isp_id": 142,
    "submission_time": "2026-01-15T10:15:00+06:00",
    "reporting_period_start": "2026-01-15T10:00:00+06:00",
    "reporting_period_end": "2026-01-15T10:15:00+06:00",
    "poll_interval_sec": 300,
    "polls_in_batch": 3,
    "summary": {
      "interface_records": 7,
      "subscriber_records": 4,
      "total_records": 11,
      "successful_polls": 9,
      "failed_polls": 2,
      "partial_submission": false
    }
  },
  "agent_status": {
    "host_ip": "192.168.10.50",
    "public_ip": "103.45.120.15",
    "public_ip_source": "CORE_API",
    "public_ip_fetch_time": "2026-01-15T10:14:30+06:00",
    "container_id": "a1b2c3d4e5f6",
    "status": "ACTIVE",
    "status_message": "Operating normally",
    "last_heartbeat": "2026-01-15T10:14:00+06:00",
    "uptime_seconds": 864000
  },
  "target_status": [
    {
      "target_id": "t-001",
      "device_type": "CORE_GATEWAY",
      "target_ip": "10.0.1.1",
      "target_hostname": "core-rtr-01.isp.net",
      "status": "HEALTHY",
      "polls_attempted": 3,
      "polls_successful": 3,
      "polls_failed": 0,
      "last_success_time": "2026-01-15T10:10:00+06:00",
      "last_failure_time": null,
      "consecutive_failures": 0
    },
    {
      "target_id": "t-002",
      "device_type": "BRAS",
      "target_ip": "10.0.2.1",
      "target_hostname": "bras-01.isp.net",
      "status": "DEGRADED",
      "polls_attempted": 1,
      "polls_successful": 0,
      "polls_failed": 1,
      "last_success_time": "2026-01-15T09:45:00+06:00",
      "last_failure_time": "2026-01-15T10:00:00+06:00",
      "consecutive_failures": 1,
      "failure_reason": "TIMEOUT"
    }
  ],
  "interface_metrics": [
    {
      "time": "2026-01-15T10:00:00+06:00",
      "poll_sequence": 1,
      "pop_id": 1523,
      "interface_type": "INTERNET",
      "upstream_operator": "AAMRA Networks",
      "snmp_target": {
        "target_id": "t-001",
        "device_type": "CORE_GATEWAY",
        "vendor": "CISCO",
        "mib_profile": "STANDARD",
        "target_ip": "10.0.1.1",
        "target_hostname": "core-rtr-01.isp.net",
        "if_index": 1,
        "if_name": "GigabitEthernet0/0/0",
        "if_description": "Uplink to AAMRA Gateway",
        "if_speed_mbps": 10000
      },
      "poll_status": "SUCCESS",
      "poll_duration_ms": 145,
      "metrics": {
        "admin_status": "UP",
        "oper_status": "UP",
        "in_bps": 5368709120,
        "out_bps": 1073741824,
        "in_errors": 0,
        "out_errors": 0,
        "in_discards": 12,
        "out_discards": 0,
        "utilization_in_pct": 53.69,
        "utilization_out_pct": 10.74
      },
      "threshold_flags": {
        "utilization_warning": false,
        "utilization_critical": false
      }
    }
  ],
  "subscriber_counts": [
    {
      "time": "2026-01-15T10:00:00+06:00",
      "bras_id": "BRAS-DHK-01",
      "bras_name": "Dhaka Central BRAS",
      "region": "Dhaka Division",
      "snmp_target": {
        "target_id": "t-002",
        "device_type": "BRAS",
        "vendor": "HUAWEI",
        "mib_profile": "VENDOR_EXT",
        "target_ip": "10.0.2.1",
        "target_hostname": "bras-01.isp.net"
      },
      "poll_status": "SUCCESS",
      "poll_duration_ms": 95,
      "metrics": {
        "active_sessions": 48750,
        "pppoe_sessions": 45000,
        "dhcp_leases": 3750,
        "ipoe_sessions": 0
      }
    }
  ],
  "alerts": []
}
```

### 8.5 Response Formats

#### 200 OK - Accepted

```json
{
  "status": "accepted",
  "submission_uuid": "550e8400-e29b-41d4-a716-446655440000",
  "records_processed": 11,
  "processing_time_ms": 45
}
```

#### 202 Accepted - Queued

```json
{
  "status": "queued",
  "submission_uuid": "550e8400-e29b-41d4-a716-446655440000",
  "queue_position": 5
}
```

#### 400 Bad Request - Validation Error

```json
{
  "status": "error",
  "error_code": "VALIDATION_ERROR",
  "message": "Request validation failed",
  "errors": [
    {
      "field": "submission.isp_id",
      "code": "REQUIRED",
      "message": "Field is required"
    },
    {
      "field": "interface_metrics[0].metrics.in_bps",
      "code": "INVALID_TYPE",
      "message": "Expected integer, got string"
    }
  ]
}
```

#### 401 Unauthorized

```json
{
  "status": "error",
  "error_code": "AUTH_FAILED",
  "message": "Invalid API key"
}
```

#### 422 Unprocessable Entity - Duplicate

```json
{
  "status": "error",
  "error_code": "DUPLICATE_SUBMISSION",
  "message": "Submission UUID already processed",
  "submission_uuid": "550e8400-e29b-41d4-a716-446655440000",
  "original_received_at": "2026-01-15T10:15:01+06:00"
}
```

#### 429 Too Many Requests

```json
{
  "status": "error",
  "error_code": "RATE_LIMIT_EXCEEDED",
  "message": "Rate limit exceeded",
  "retry_after_seconds": 60
}
```

#### 500 Internal Server Error

```json
{
  "status": "error",
  "error_code": "INTERNAL_ERROR",
  "message": "Internal server error",
  "trace_id": "abc123def456"
}
```

#### 503 Service Unavailable

```json
{
  "status": "error",
  "error_code": "SERVICE_UNAVAILABLE",
  "message": "Database connection unavailable",
  "retry_after_seconds": 30
}
```

---

## 9. SNMP Validation Rules

### 9.1 Schema Validation

| Field | Type | Required | Validation |
|-------|------|----------|------------|
| `submission.submission_uuid` | UUID | Yes | Valid UUIDv4 format |
| `submission.originator_type` | Enum | Yes | Must be "SNMP_AGENT" |
| `submission.agent_uuid` | UUID | Yes | Must match X-Agent-UUID header |
| `submission.isp_id` | Integer | Yes | Must exist in ISP registry |
| `submission.submission_time` | ISO8601 | Yes | Not in future (> 5 min tolerance) |
| `submission.reporting_period_start` | ISO8601 | Yes | < reporting_period_end |
| `interface_metrics[].metrics.in_bps` | BigInt | Yes* | >= 0 |
| `interface_metrics[].metrics.utilization_in_pct` | Decimal | Yes* | 0.0 - 100.0 |

*Required when poll_status = SUCCESS




# PART IV: QOS CHANNEL API REFERENCE

---

## 11. QOS Measurements Submission API

### 11.1 Endpoint

```
POST /api/v1/submissions/qos-measurements
```

### 11.2 Request Headers

| Header | Required | Description |
|--------|----------|-------------|
| `Content-Type` | Yes | `application/json` |
| `X-Agent-UUID` | Yes | Registered agent UUID |

### 11.3 Request Body Schema

```json
{
  "submission": {
    "submission_uuid": "UUID",
    "originator_type": "QOS_AGENT",
    "agent_uuid": "UUID",
    "agent_version": "string",
    "isp_id": "integer",
    "submission_time": "ISO8601",
    "reporting_period_start": "ISO8601",
    "reporting_period_end": "ISO8601",
    "test_summary": {
      "speed_tests": "integer",
      "ping_tests": "integer",
      "dns_tests": "integer",
      "http_tests": "integer",
      "traceroute_tests": "integer",
      "total_tests": "integer",
      "successful_tests": "integer",
      "failed_tests": "integer"
    }
  },
  "agent_status": { "..." },
  "speed_test": { "..." },
  "ping_tests": [ "..." ],
  "dns_test": { "..." },
  "http_test": { "..." },
  "traceroute_tests": [ "..." ],
  "failures": [ "..." ],
  "threshold_flags": { "..." }
}
```

### 11.4 Full Request Example

```json
{
  "submission": {
    "submission_uuid": "660e8400-e29b-41d4-a716-446655440001",
    "originator_type": "QOS_AGENT",
    "agent_uuid": "8d9e6679-7425-40de-944b-e07fc1f90ae8",
    "agent_version": "1.1.0",
    "isp_id": 142,
    "submission_time": "2026-01-15T10:15:00+06:00",
    "reporting_period_start": "2026-01-15T10:00:00+06:00",
    "reporting_period_end": "2026-01-15T10:15:00+06:00",
    "test_summary": {
      "speed_tests": 3,
      "ping_tests": 6,
      "dns_tests": 3,
      "http_tests": 3,
      "traceroute_tests": 2,
      "total_tests": 17,
      "successful_tests": 15,
      "failed_tests": 2
    }
  },
  "agent_status": {
    "host_ip": "192.168.20.100",
    "public_ip": "103.45.120.20",
    "public_ip_source": "CORE_API",
    "public_ip_fetch_time": "2026-01-15T10:14:30+06:00",
    "status": "ACTIVE",
    "cpu_usage_pct": 12.5,
    "memory_usage_pct": 45.2,
    "disk_usage_pct": 28.0,
    "uptime_seconds": 1728000
  },
  "speed_test": {
    "test_uuid": "st-001-2026011510050",
    "time": "2026-01-15T10:05:00+06:00",
    "test_status": "SUCCESS",
    "test_duration_ms": 32500,
    "target": {
      "type": "OOKLA_API",
      "server_id": 12345,
      "server_name": "BTRC Speed Test Server",
      "server_location": "Dhaka"
    },
    "download": {
      "speed_mbps": 95.5,
      "bytes_transferred": 119375000,
      "duration_ms": 15000
    },
    "upload": {
      "speed_mbps": 48.2,
      "bytes_transferred": 60250000,
      "duration_ms": 15000
    },
    "latency_to_server_ms": 3.2,
    "test_method": "OOKLA_API",
    "threshold_flags": {
      "download_below_minimum": false,
      "upload_below_minimum": false
    }
  },
  "ping_tests": [
    {
      "test_id": "ping-001",
      "time": "2026-01-15T10:02:00+06:00",
      "target_type": "NATIONAL",
      "target_server": {
        "server_id": "nat-dhk-01",
        "server_ip": "103.10.20.30"
      },
      "test_status": "SUCCESS",
      "results": {
        "packets_sent": 10,
        "packets_received": 10,
        "packet_loss_pct": 0.0,
        "rtt_min_ms": 5.2,
        "rtt_avg_ms": 8.5,
        "rtt_max_ms": 12.3,
        "jitter_ms": 2.1
      },
      "threshold_flags": {
        "latency_exceeded": false,
        "packet_loss_exceeded": false,
        "jitter_exceeded": false
      }
    },
    {
      "test_id": "ping-002",
      "time": "2026-01-15T10:02:30+06:00",
      "target_type": "IX",
      "target_server": {
        "server_id": "ix-bdix-01",
        "server_ip": "103.30.40.50"
      },
      "test_status": "SUCCESS",
      "results": {
        "packets_sent": 10,
        "packets_received": 10,
        "packet_loss_pct": 0.0,
        "rtt_min_ms": 15.1,
        "rtt_avg_ms": 22.4,
        "rtt_max_ms": 35.8,
        "jitter_ms": 5.2
      }
    },
    {
      "test_id": "ping-003",
      "time": "2026-01-15T10:03:00+06:00",
      "target_type": "INTERNATIONAL",
      "target_server": {
        "server_id": "intl-sgp-01",
        "server_ip": "103.50.60.70"
      },
      "test_status": "SUCCESS",
      "results": {
        "packets_sent": 10,
        "packets_received": 9,
        "packet_loss_pct": 10.0,
        "rtt_min_ms": 85.2,
        "rtt_avg_ms": 120.5,
        "rtt_max_ms": 180.3,
        "jitter_ms": 25.4
      },
      "threshold_flags": {
        "latency_exceeded": false,
        "packet_loss_exceeded": true,
        "jitter_exceeded": false
      }
    }
  ],
  "dns_test": {
    "test_uuid": "dns-001-2026011510040",
    "time": "2026-01-15T10:04:00+06:00",
    "test_status": "SUCCESS",
    "queries": [
      {
        "domain": "btrc.gov.bd",
        "domain_type": "LOCAL_BD",
        "resolution_time_ms": 8.2,
        "response_code": "NOERROR",
        "success": true
      },
      {
        "domain": "google.com",
        "domain_type": "INTERNATIONAL",
        "resolution_time_ms": 25.3,
        "response_code": "NOERROR",
        "success": true
      }
    ],
    "summary": {
      "total_queries": 2,
      "successful": 2,
      "avg_resolution_ms": 16.75
    }
  },
  "http_test": {
    "test_uuid": "http-001-2026011510043",
    "time": "2026-01-15T10:04:30+06:00",
    "test_status": "SUCCESS",
    "targets": [
      {
        "url": "https://btrc.gov.bd",
        "weight": 25,
        "reachable": true,
        "status_code": 200,
        "timing": {
          "ttfb_ms": 120.5,
          "total_time_ms": 350.8
        }
      }
    ],
    "summary": {
      "reachability_score": {
        "score": 100,
        "max_score": 100,
        "percentage": 100.0,
        "targets_reached": 1,
        "targets_failed": 0
      },
      "response_time": {
        "weighted_avg_ms": 350.8,
        "simple_avg_ms": 350.8,
        "min_ms": 350.8,
        "max_ms": 350.8
      }
    }
  },
  "traceroute_tests": [
    {
      "test_id": "trace-001",
      "time": "2026-01-15T10:08:00+06:00",
      "target_ip": "8.8.8.8",
      "test_status": "SUCCESS",
      "results": {
        "hop_count": 12,
        "hops": [
          {"hop": 1, "ip": "192.168.1.1", "rtt_ms": 1.2, "hostname": "gateway.local"},
          {"hop": 2, "ip": "10.0.0.1", "rtt_ms": 5.5, "hostname": null},
          {"hop": 3, "ip": "103.45.120.1", "rtt_ms": 8.3, "hostname": "pe-dhk.isp.net"}
        ]
      }
    }
  ],
  "failures": [
    {
      "test_id": "ping-004",
      "test_type": "PING",
      "time": "2026-01-15T10:09:00+06:00",
      "target_type": "INTERNATIONAL",
      "target_server": {
        "server_id": "intl-lon-01",
        "server_ip": "185.60.70.80"
      },
      "failure_reason": "TIMEOUT",
      "error_message": "No response after 5000ms"
    }
  ],
  "threshold_flags": {
    "any_speed_below_minimum": false,
    "any_latency_exceeded": false,
    "any_packet_loss_exceeded": true,
    "overall_pass": false
  }
}
```

### 11.5 Response Formats

Same as SNMP API (Section 8.5)

---

## 12. QOS Validation Rules

### 12.1 Schema Validation

| Field | Type | Required | Validation |
|-------|------|----------|------------|
| `submission.originator_type` | Enum | Yes | Must be "QOS_AGENT" |
| `speed_results[].results.download_mbps` | Decimal | Yes* | >= 0 |
| `ping_tests[].results.rtt_avg_ms` | Decimal | Yes* | >= 0 |
| `ping_tests[].results.packet_loss_pct` | Decimal | Yes* | 0.0 - 100.0 |


## 13. QOS Threshold Evaluation

### 13.1 Speed Test Thresholds

Per ToR Section 3.8 requirements:

| Package Speed | Minimum Download | Minimum Upload |
|---------------|------------------|----------------|
| ≤ 5 Mbps | 40% of advertised | 40% of advertised |
| 5-20 Mbps | 50% of advertised | 50% of advertised |
| 20-100 Mbps | 60% of advertised | 60% of advertised |
| > 100 Mbps | 70% of advertised | 70% of advertised |

### 13.2 Latency Thresholds

| Target Type | Warning (ms) | Critical (ms) |
|-------------|--------------|---------------|
| NAT (National) | 20 | 50 |
| IX (Exchange) | 50 | 100 |
| INTL (International) | 150 | 300 |
| CACHE (CDN) | 30 | 75 |

### 13.3 Packet Loss Thresholds

| Target Type | Warning | Critical |
|-------------|---------|----------|
| All types | 1% | 5% |

### 13.4 Jitter Thresholds

| Target Type | Warning (ms) | Critical (ms) |
|-------------|--------------|---------------|
| NAT | 10 | 30 |
| IX | 20 | 50 |
| INTL | 50 | 100 |

### 13.5 HTTP Reachability Thresholds

| Metric | Warning | Critical |
|--------|---------|----------|
| TTFB (Time to First Byte) | 500ms | 2000ms |
| Total Time | 3000ms | 10000ms |
| Failure Rate | 5% | 20% |

### 13.6 DNS Resolution Thresholds

| Metric | Warning | Critical |
|--------|---------|----------|
| Resolution Time | 100ms | 500ms |
| Failure Rate | 1% | 5% |

**QOS Threshold Evaluation Logic:**

```python
def evaluate_qos_thresholds(submission, thresholds):
    """
    Evaluate all QOS test results against thresholds
    Agent sets threshold_flags, Core validates and generates alerts
    """
    alerts = []

    # Speed tests
    for speed in submission.speed_results:
        if speed.test_status != "SUCCESS":
            continue

        min_download = get_minimum_speed(
            speed.target_type,
            submission.isp_package_speed
        )

        if speed.results.download_mbps < min_download:
            alerts.append(create_alert(
                type="SPEED_BELOW_MINIMUM",
                severity="WARNING",
                metric="download_mbps",
                value=speed.results.download_mbps,
                threshold=min_download
            ))

    # Ping tests
    for ping in submission.ping_results:
        if ping.test_status != "SUCCESS":
            continue

        latency_thresholds = thresholds.latency[ping.target_type]

        if ping.results.rtt_avg_ms >= latency_thresholds.critical:
            alerts.append(create_alert(
                type="LATENCY_EXCEEDED",
                severity="CRITICAL",
                target_type=ping.target_type,
                value=ping.results.rtt_avg_ms,
                threshold=latency_thresholds.critical
            ))
        elif ping.results.rtt_avg_ms >= latency_thresholds.warning:
            alerts.append(create_alert(
                type="LATENCY_EXCEEDED",
                severity="WARNING",
                ...
            ))

        # Packet loss
        if ping.results.packet_loss_pct >= thresholds.packet_loss.critical:
            alerts.append(create_alert(
                type="PACKET_LOSS_EXCEEDED",
                severity="CRITICAL",
                ...
            ))

    return alerts
```

---

# PART V: ISP-API CHANNEL REFERENCE

---

## 14. ISP Data Submission APIs

### 14.1 Package Definitions

**Endpoint:**
```
POST /api/v1/isp/{isp_id}/packages
```

**Request Example:**

```json
{
  "submission_uuid": "770e8400-e29b-41d4-a716-446655440002",
  "submission_time": "2026-01-15T12:00:00+06:00",
  "reporting_month": "2026-01",
  "packages": [
    {
      "package_code": "PKG-HOME-10",
      "package_name": "Home Basic 10",
      "package_type": "RESIDENTIAL",
      "download_speed_mbps": 10,
      "upload_speed_mbps": 5,
      "mir_mbps": 10,
      "cir_mbps": 5,
      "price_bdt": 500.00,
      "data_cap_gb": null,
      "has_fup": true,
      "fup_threshold_gb": 200,
      "fup_speed_mbps": 2,
      "contract_months": 12,
      "installation_fee_bdt": 0,
      "status": "active",
      "subscriber_count": 15000
    },
    {
      "package_code": "PKG-HOME-25",
      "package_name": "Home Standard 25",
      "package_type": "RESIDENTIAL",
      "download_speed_mbps": 25,
      "upload_speed_mbps": 10,
      "mir_mbps": 25,
      "cir_mbps": 12,
      "price_bdt": 800.00,
      "data_cap_gb": null,
      "has_fup": true,
      "fup_threshold_gb": 400,
      "fup_speed_mbps": 5,
      "contract_months": 12,
      "installation_fee_bdt": 0,
      "status": "active",
      "subscriber_count": 25000
    },
    {
      "package_code": "PKG-BIZ-100",
      "package_name": "Business Pro 100",
      "package_type": "CORPORATE",
      "download_speed_mbps": 100,
      "upload_speed_mbps": 50,
      "mir_mbps": 100,
      "cir_mbps": 90,
      "price_bdt": 5000.00,
      "data_cap_gb": null,
      "has_fup": false,
      "fup_threshold_gb": null,
      "fup_speed_mbps": null,
      "contract_months": 12,
      "installation_fee_bdt": 0,
      "status": "active",
      "subscriber_count": 500
    }
  ]
}
```

**Response 200 OK:**

```json
{
  "status": "accepted",
  "submission_uuid": "770e8400-e29b-41d4-a716-446655440002",
  "records_processed": 3,
  "records_created": 1,
  "records_updated": 2
}
```

---

### 14.2 Subscriber Data

**Endpoint:**
```
POST /api/v1/isp/{isp_id}/subscribers
```

**Request Example:**

> **Structure**: Package × Location matrix for granular regulatory analysis. Summaries computed server-side.

```json
{
  "submission_uuid": "880e8400-e29b-41d4-a716-446655440003",
  "submission_time": "2026-01-15T12:00:00+06:00",
  "reporting_month": "2026-01",
  "subscribers": [
    {
      "package_code": "PKG-HOME-10",
      "location": {
        "bbs_code": "302614"
      },
      "current_count": 8500,
      "new_count": 320,
      "churned_count": 145
    },
    {
      "package_code": "PKG-HOME-10",
      "location": {
        "bbs_code": null,
        "division": "Dhaka",
        "district": "Dhaka",
        "upazila": "Banani"
      },
      "current_count": 6500,
      "new_count": 185,
      "churned_count": 92
    },
    {
      "package_code": "PKG-HOME-25",
      "location": {
        "bbs_code": "302614"
      },
      "current_count": 12500,
      "new_count": 456,
      "churned_count": 178
    },
    {
      "package_code": "PKG-HOME-25",
      "location": {
        "bbs_code": "100205"
      },
      "current_count": 12500,
      "new_count": 280,
      "churned_count": 120
    },
    {
      "package_code": "PKG-BIZ-100",
      "location": {
        "bbs_code": "302614"
      },
      "current_count": 500,
      "new_count": 25,
      "churned_count": 8
    }
  ]
}
```

**Field Specifications:**

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| package_code | STRING | Yes | Reference to Package (from packages submission) |
| location | OBJECT | Yes | Location via bbs_code OR division/district/upazila |
| current_count | INTEGER | Yes | Total active subscribers (snapshot) |
| new_count | INTEGER | Yes | New subscribers added this month |
| churned_count | INTEGER | Yes | Subscribers removed this month |

---

### 14.3 PoP and Bandwidth Data

**Endpoint:**
```
POST /api/v1/isp/{isp_id}/pops
```

**Request Example:**

```json
{
  "submission_uuid": "990e8400-e29b-41d4-a716-446655440004",
  "submission_time": "2026-01-15T12:00:00+06:00",
  "reporting_month": "2026-01",
  "pops": [
    {
      "pop_id": "pop-dhk-01",
      "pop_name": "Dhaka Central PoP",
      "location": {
        "division": "Dhaka",
        "district": "Dhaka",
        "address": "123 Main Street, Motijheel",
        "latitude": 23.7104,
        "longitude": 90.4074
      },
      "capacity": {
        "total_ports": 1000,
        "used_ports": 850,
        "available_ports": 150
      },
      "bandwidth": {
        "total_upstream_gbps": 100,
        "internet_upstream_gbps": 60,
        "ix_upstream_gbps": 30,
        "cache_upstream_gbps": 10
      },
      "subscribers_served": 45000
    },
    {
      "pop_id": "pop-ctg-01",
      "pop_name": "Chittagong Main PoP",
      "location": {
        "division": "Chittagong",
        "district": "Chittagong",
        "address": "456 Port Road, Agrabad",
        "latitude": 22.3569,
        "longitude": 91.7832
      },
      "capacity": {
        "total_ports": 500,
        "used_ports": 420,
        "available_ports": 80
      },
      "bandwidth": {
        "total_upstream_gbps": 50,
        "internet_upstream_gbps": 30,
        "ix_upstream_gbps": 15,
        "cache_upstream_gbps": 5
      },
      "subscribers_served": 25000
    }
  ]
}
```

---

### 14.4 Revenue Summary

**Endpoint:**
```
POST /api/v1/isp/{isp_id}/revenue
```

**Request Example:**

```json
{
  "submission_uuid": "aa0e8400-e29b-41d4-a716-446655440005",
  "submission_time": "2026-01-15T12:00:00+06:00",
  "reporting_month": "2026-01",
  "revenue": {
    "total_revenue_bdt": 125000000,
    "residential_revenue_bdt": 95000000,
    "corporate_revenue_bdt": 30000000,
    "arpu_bdt": 1000,
    "new_connections": 2500,
    "disconnections": 1200,
    "net_additions": 1300
  }
}
```

---

### 14.8 Response Formats

All ISP-API endpoints return consistent response format:

**200 OK:**
```json
{
  "status": "accepted",
  "submission_uuid": "...",
  "records_processed": 10,
  "records_created": 5,
  "records_updated": 5
}
```

**400 Bad Request:**
```json
{
  "status": "error",
  "error_code": "VALIDATION_ERROR",
  "message": "Validation failed",
  "errors": [...]
}
```

**403 Forbidden:**
```json
{
  "status": "error",
  "error_code": "ISP_MISMATCH",
  "message": "API key does not belong to ISP 142"
}
```

---

## 15. ISP Validation Rules

### 15.1 Authentication

| Rule | Description |
|------|-------------|
| ISP API Key | Must be valid ISP-issued key (separate from agent keys) |
| ISP Ownership | API key must belong to {isp_id} in URL path |

### 15.2 Common Validation Rules

| Field | Validation |
|-------|------------|
| `submission_uuid` | Valid UUIDv4, unique within monthly window |
| `submission_time` | Valid ISO8601, not in future |
| `reporting_month` | Format YYYY-MM, not in future |

### 15.3 Per-Type Validation

| Type | Key Validations |
|------|-----------------|
| **Packages** | package_id unique, speeds > 0, price >= 0 |
| **Subscribers** | total = sum of divisions, counts >= 0 |
| **PoPs** | valid lat/long, bandwidth values >= 0 |

**Note:** Bandwidth allocation validation is relaxed because ISPs may have other customer types (non-broadband) that consume upstream capacity.

---



# APPENDICES

---


