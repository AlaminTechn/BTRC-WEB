# SNMP_AGENT Application - All-In-One Developer Guide (Review-Pending)

| Metadata | Value |
|----------|-------|
| **Document** | SNMP_AGENT All-In-One Developer Guide |
| **Version** | 0.9.2 (Plan-Aligned) |
| **Status** | REVIEW-PENDING |
| **Created** | 2026-01-15 |
| **Updated** | 2026-01-16 |
| **Author** | Technometrics |
| **Project** | BTRC Fixed Broadband QoS Monitoring System |
| **Alignment** | Validated against PRD v3.1, Data-Model v2.3, DB-Schema v1.1 |

---

## Document Purpose

This is the **comprehensive developer reference** for the SNMP_AGENT application component of the BTRC QoS Monitoring System. It consolidates all specifications into a single document:

| Audience | Sections |
|----------|----------|
| **Project Managers** | 1-3 (Overview, Features) |
| **Product Designers** | 4-5 (Features, Architecture) |
| **Developers** | 6-17 (All technical sections) |
| **DevOps/QA** | 12-17 (Files, Logging, Deployment, Troubleshooting) |

## Related Documents

| Document | Description |
|----------|-------------|
| [Data-Model(INGESTION)](../01-planning/BTRC-FXBB-QOS-POC_Data-Model(INGESTION)_DRAFT_v0.8.md) | Data model and API specifications |
| 01-PROJECT-BRIEF.md | Overall project scope and requirements |

---

# PART I: OVERVIEW & FEATURES

---

## 1. Executive Summary

The SNMP_AGENT is a containerized software application that collects network infrastructure metrics from ISP devices via SNMP protocol.

### Key Characteristics

| Aspect | Description |
|--------|-------------|
| **Deployment** | Standalone Docker/Podman container (no orchestration) |
| **Scope** | One agent per ISP OR per PoP (configurable) |
| **Configuration** | Call-home pattern with centralized config from Core |
| **Collection** | Parallel async workers for interface metrics and subscriber counts |
| **Resilience** | Store-and-forward with local queue persistence |

**Total Features**: 47 across 7 categories

---

## 2. Feature Summary by Category

| Category | Features | Description |
|----------|----------|-------------|
| A. Deployment & Container | 7 | Container runtime, volumes, lifecycle |
| B. SNMP Collection Engine | 12 | Polling, protocols, MIB profiles |
| C. Data Processing | 5 | Rate calculation, normalization |
| D. Threshold & Alerting | 6 | Monitoring, hysteresis, alerts |
| E. Local Storage | 6 | Data persistence, queue management |
| F. Core Communication | 7 | Submission, resilience, log forwarding |
| G. Timing & Scheduling | 4 | Intervals, alignment, timezone |
| **TOTAL** | **47** | |

---

## 3. Complete Feature List


### B. SNMP Collection Engine (12 features)

| # | Feature | Description |
|---|---------|-------------|
| B1 | Parallel collection | Non-blocking async workers per target type. |
| B2 | Hybrid architecture | Interface metrics worker + Subscriber counts worker (async). |
| B3 | SNMP v2c support | SNMPv2c with community string authentication. |
| B4 | SNMP v3 support | SNMPv3 with authPriv and authNoPriv modes. |
| B5 | Configurable timeout | Per-target SNMP timeout setting (from Core config). |
| B6 | Retry with backoff | Configurable retry count with exponential backoff. |
| B7 | Bulk GET operations | SNMP GETBULK for efficient multi-OID polling. |
| B8 | Vendor MIB profiles | STANDARD + VENDOR_EXT (Cisco, Juniper, Huawei, MikroTik, etc.) |
| B9 | Custom OID support | Additional OIDs per target (defined in Core config). |
| B10 | Counter wrap handling | Detect and handle 32-bit/64-bit counter wraps. |
| B11 | Poll scheduling | 3 polls per 15-min window at T+0, T+5, T+10. |
| B12 | Jitter/randomization | Random offset (0-30s) on startup to prevent thundering herd. |


### C. Data Processing & Calculation (5 features)

| # | Feature | Description |
|---|---------|-------------|
| C1 | Rate calculation | Calculate bps from counter deltas between polls. |
| C2 | Utilization calculation | Calculate % utilization from rate vs interface speed. |
| C3 | Interface status | Track admin_status + oper_status (UP/DOWN). |
| C4 | Subscriber session counts | Aggregate active_sessions, pppoe, dhcp, ipoe counts. |
| C5 | Data normalization | Normalize metrics across vendor differences. |

### D. Threshold & Alerting (6 features)

| # | Feature | Description |
|---|---------|-------------|
| D1 | Threshold monitoring | Compare metrics against thresholds (from Core config). |
| D2 | Hysteresis | Prevent alert flapping with raise/clear threshold delta. |
| D3 | Multi-level thresholds | WARNING and CRITICAL threshold levels. |
| D4 | Per-metric thresholds | Different thresholds configurable per metric type. |
| D5 | Local alert logging | Log threshold violations to /logs. |
| D6 | Alert in Core submission | Include active alerts in metric submission payload. |

### E. Local Storage & Persistence (6 features)

| # | Feature | Description |
|---|---------|-------------|
| E1 | Raw data storage | Store poll data locally in /data/polls/. |
| E2 | Configurable retention | Retention period in days (from Core config). |
| E3 | Storage rotation | Auto-cleanup of expired data files. |
| E4 | JSON file format | Store as JSON files (portable, human-readable). |
| E5 | Queue persistence | Persist pending submissions in /data/queue/ to survive restart. |
| E6 | Queue recovery on restart | Restore and retry queued submissions after crash/restart. |

### F. Core Communication & Resilience (7 features)

| # | Feature | Description |
|---|---------|-------------|
| F1 | Store-and-forward | Queue metric submissions when Core unreachable. |
| F2 | Retry with backoff | Retry failed submissions with exponential backoff. |
| F3 | Circuit breaker | Stop retries after N failures, auto-recover when Core up. |
| F4 | Partial submission | Submit available data even if some target polls failed. |
| F5 | Submission acknowledgment | Handle Core ACK/NACK response, retry on failure. |
| F6 | Queue retention limit | Keep queued submissions for N days (from Core config). |
| F7 | Log submission to Core | Submit agent logs to Core when debug_enabled=true. |

### G. Timing & Scheduling (4 features)

| # | Feature | Description |
|---|---------|-------------|
| G1 | Poll interval | 5-minute default (configurable from Core). |
| G2 | Submission interval | 15-minute window (configurable from Core). |
| G3 | Window alignment | Align submissions to clock boundaries (optional). |
| G4 | Timezone handling | All timestamps ISO8601 with +06:00 (BST). |

---

# PART II: ARCHITECTURE

---

## 4. Agent State Machine

```
                              ┌─────────────────┐
                              │   CONTAINER     │
                              │   STARTED       │
                              └────────┬────────┘
                                       │
                                       ▼
                         ┌─────────────────────────┐
                         │      BOOTSTRAP          │
                         │  Read local config      │
                         │  Authenticate with Core │
                         │  Fetch/cache config     │
                         │  Validate ISP           │
                         └────────────┬────────────┘
                                      │
                           ┌──────────┴──────────┐
                           │                     │
                           ▼                     ▼
                    Bootstrap FAILED       Bootstrap SUCCESS
                           │                     │
                           ▼                     ▼
                   ┌─────────────┐    ┌─────────────────────┐
                   │  BLOCKED    │    │ Check agent_enabled │
                   │  (EXIT)     │    └──────────┬──────────┘
                   └─────────────┘               │
                                      ┌──────────┴──────────┐
                                      │                     │
                                      ▼                     ▼
                              agent_enabled        agent_enabled
                                 =false               =true
                                      │                     │
                                      ▼                     ▼
                            ┌───────────────┐    ┌─────────────────────┐
                            │   DISABLED    │    │ Check maintenance   │
                            │  Wait for     │    │ _mode flag          │
                            │  SIGHUP       │    └──────────┬──────────┘
                            └───────────────┘               │
                                                 ┌──────────┴──────────┐
                                                 │                     │
                                                 ▼                     ▼
                                         maintenance          maintenance
                                            =true                =false
                                                 │                     │
                                                 ▼                     ▼
                                      ┌───────────────────┐  ┌───────────────────┐
                                      │   MAINTENANCE     │  │     ACTIVE        │
                                      │                   │  │                   │
                                      │  Poll: YES        │  │  Poll: YES        │
                                      │  Submit Metrics:  │  │  Submit Metrics:  │
                                      │    NO             │  │    YES            │
                                      │  Submit Logs:     │  │  Submit Logs:     │
                                      │    if debug=true  │  │    if debug=true  │
                                      └───────────────────┘  └───────────────────┘
```

---

## 5. Operational Mode Matrix

| maintenance_mode | debug_enabled | POLLS? | METRICS? | LOGS TO CORE? |
|------------------|---------------|--------|----------|---------------|
| true | true | YES | NO | YES |
| true | false | YES | NO | NO |
| false | true | YES | YES | YES |
| false | false | YES | YES | NO |

---

## 6. Agent States Summary

| STATE | POLLS? | SUBMITS? | DESCRIPTION |
|-------|--------|----------|-------------|
| BOOTSTRAP | No | No | Loading config, authenticating |
| BLOCKED | No | No | ISP validation failed (exit) |
| DISABLED | No | No | agent_enabled=false, waiting for SIGHUP |
| MAINTENANCE | YES | Logs only | Testing SNMP, logging to Core if debug=true |
| ACTIVE | YES | YES | Full production operation |

---

## 7. Hybrid Collection Architecture

**Architecture Decision**: Single agent with internal async workers (HYBRID approach)

### Why Hybrid?

| Criteria | Separate Agents | Combined Agent | Hybrid (Chosen) |
|----------|-----------------|----------------|-----------------|
| Containers per ISP | 3-5 | 1 | 1 |
| API calls per 15-min | 3-5 | 1 | 1 |
| Fault isolation | Full | None | Internal |
| Partial submission | Yes | No | Yes |
| Operational complexity | High | Low | Low |

### Internal Worker Model

```
SNMP_AGENT Container
├── Interface Worker (async, 60s timeout)
│   └── Polls: Core routers, aggregation, BRAS interfaces
├── BRAS Worker (async, 30s timeout)
│   └── Polls: BRAS session counts
└── RAS Worker (async, 30s timeout)
    └── Polls: RAS session counts

All workers → Aggregator → Single Combined Submission
```

### Poll Cycle Flow

| Time | Action |
|------|--------|
| T+0:00 | Start poll cycle, launch all workers async |
| T+0:00 | Worker 1: Interface poll #1 |
| T+5:00 | Worker 1: Interface poll #2 |
| T+10:00 | Worker 1: Interface poll #3 |
| T+12:00 | All workers complete (or timeout) |
| T+12:05 | Assemble combined message |
| T+12:10 | Submit to Core API (single call) |

### Partial Submission Handling

- If Worker 1 (interfaces) times out but Workers 2/3 succeed → Submit with `partial_submission: true`
- Failed worker data included with `poll_status: TIMEOUT` and `metrics: null`
- Server-side processing handles missing data gracefully

---

## 8. Responsibility Separation

### Agent Responsibility (SNMP_AGENT)

- Poll BRAS/RAS devices via SNMP
- Report raw session counts per device
- Report device status (healthy/degraded/unreachable)
- Report poll status and errors
- Submit combined interface + subscriber data
- Calculate rate (bps) from counter deltas
- Calculate utilization percentage
- Detect threshold violations (local)
- Store-and-forward when Core unreachable

### Core/Server Responsibility

- Aggregate totals across all ISP BRAS/RAS devices
- Compute ISP-level subscriber totals
- Compare against ISP-reported subscriber counts (ISP_API)
- Calculate variance and trigger compliance alerts
- Perform geographic analysis using PoP data from ISP_API
- Handle counter wrap detection and data normalization
- Store time-series data
- Generate dashboards and reports

---

# PART III: CONFIGURATION

---

## 9. Configuration Architecture

### Overview

```
┌─────────────────────────────────────────────────────────────────────────┐
│                        CONFIGURATION FLOW                                │
├─────────────────────────────────────────────────────────────────────────┤
│                                                                          │
│   ┌──────────────────┐          ┌──────────────────┐                    │
│   │  BOOTSTRAP.JSON  │          │    CORE API      │                    │
│   │  (Static, Local) │          │  (Centralized)   │                    │
│   │                  │          │                  │                    │
│   │  • agent_uuid    │   ───►   │  GET /config     │                    │
│   │  • api_key       │          │                  │                    │
│   │  • core_url      │          │  Returns full    │                    │
│   └──────────────────┘          │  operational     │                    │
│                                 │  config          │                    │
│                                 └────────┬─────────┘                    │
│                                          │                              │
│                                          ▼                              │
│                                 ┌──────────────────┐                    │
│                                 │ AGENT-CONFIG.JSON│                    │
│                                 │ (Cached Locally) │                    │
│                                 │                  │                    │
│                                 │ • Full config    │                    │
│                                 │ • config_serial  │                    │
│                                 │ • All targets    │                    │
│                                 └──────────────────┘                    │
│                                                                          │
└─────────────────────────────────────────────────────────────────────────┘
```

---

## 10. Bootstrap Configuration

**Location**: `/config/bootstrap.json` (mounted read-only)

**Purpose**: Minimal static configuration for agent startup and Core authentication.

### Bootstrap JSON Structure

```json
{
  "agent_uuid": "7c9e6679-7425-40de-944b-e07fc1f90ae7",
  "core_url": "https://qos-core.btrc.gov.bd",
  "api_key": "sk-agent-xxxxxxxxxxxxxxxxxxxx"
}
```

### Bootstrap Field Specification

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `agent_uuid` | string (UUID) | YES | Unique agent identifier assigned by Core during registration |
| `core_url` | string (URL) | YES | Base URL of Core API for call-home configuration |
| `api_key` | string | YES | API key for authentication (can also be via ENV variable) |

### Environment Variable Override

The `api_key` can be provided via environment variable instead of bootstrap file:

```bash
docker run -e SNMP_AGENT_API_KEY="sk-agent-xxx" ...
```

**Priority**: ENV variable > bootstrap.json

---

## 11. Full Configuration Schema (From Core)

**Location**: `/data/config/agent-config.json` (cached locally)

**Source**: Fetched from Core API on startup and SIGHUP

### Complete JSON Example

```json
{
  "_meta": {
    "config_serial": 100,
    "fetched_at": "2026-01-15T10:00:00+06:00",
    "core_version": "1.2.0"
  },
  "agent": {
    "agent_enabled": true,
    "maintenance_mode": false,
    "debug_enabled": false,
    "log_level": "INFO",
    "prometheus_enabled": false,
    "prometheus_port": 9100
  },
  "identity": {
    "isp_id": 142,
    "isp_name": "Example ISP Ltd",
    "pop_ids": [1523, 1524],
    "deployment_scope": "ISP",
    "region": "DHAKA"
  },
  "timing": {
    "poll_interval_sec": 300,
    "submission_interval_sec": 900,
    "polls_per_window": 3,
    "startup_jitter_max_sec": 30,
    "window_alignment": true
  },
  "storage": {
    "retention_days": 7,
    "queue_retention_days": 3,
    "status_update_sec": 300
  },
  "snmp_defaults": {
    "timeout_sec": 5,
    "retries": 3,
    "backoff_multiplier": 2.0,
    "bulk_max_repetitions": 50
  },
  "targets": [
    {
      "target_id": "t-001",
      "hostname": "core-router-1.example-isp.bd",
      "ip_address": "10.0.1.1",
      "enabled": true,
      "device_type": "CORE_GATEWAY",
      "vendor_profile": "CISCO_IOS_XE",
      "snmp": {
        "version": "v2c",
        "port": 161,
        "community": "public"
      },
      "interfaces": [
        {
          "if_index": 1,
          "if_name": "GigabitEthernet0/0/0",
          "if_alias": "UPSTREAM-AAMRA",
          "if_type": "INTERNET",
          "speed_mbps": 10000,
          "monitor_enabled": true
        },
        {
          "if_index": 2,
          "if_name": "GigabitEthernet0/0/1",
          "if_alias": "PEERING-BDIX",
          "if_type": "IX",
          "speed_mbps": 10000,
          "monitor_enabled": true
        },
        {
          "if_index": 3,
          "if_name": "TenGigabitEthernet0/1/0",
          "if_alias": "GOOGLE-GGC",
          "if_type": "CACHE",
          "speed_mbps": 10000,
          "monitor_enabled": true
        }
      ],
      "custom_oids": []
    },
    {
      "target_id": "t-002",
      "hostname": "bras-1.example-isp.bd",
      "ip_address": "10.0.2.1",
      "enabled": true,
      "device_type": "BRAS",
      "vendor_profile": "HUAWEI_NE",
      "snmp": {
        "version": "v3",
        "port": 161,
        "username": "snmpuser",
        "auth_protocol": "SHA",
        "auth_password": "authpass123",
        "priv_protocol": "AES128",
        "priv_password": "privpass123",
        "security_level": "authPriv"
      },
      "interfaces": [],
      "custom_oids": [
        {
          "oid": "1.3.6.1.4.1.2011.5.2.1.1.1.3",
          "name": "hwUserOnlineNum",
          "type": "gauge"
        }
      ]
    }
  ],
  "thresholds": {
    "utilization_warning_pct": 70,
    "utilization_critical_pct": 90,
    "hysteresis_pct": 5,
    "consecutive_failures_degraded": 3,
    "consecutive_failures_unreachable": 5
  },
  "vendor_profiles": {
    "STANDARD": {
      "if_in_octets": "1.3.6.1.2.1.2.2.1.10",
      "if_out_octets": "1.3.6.1.2.1.2.2.1.16",
      "if_hc_in_octets": "1.3.6.1.2.1.31.1.1.1.6",
      "if_hc_out_octets": "1.3.6.1.2.1.31.1.1.1.10",
      "if_admin_status": "1.3.6.1.2.1.2.2.1.7",
      "if_oper_status": "1.3.6.1.2.1.2.2.1.8",
      "if_speed": "1.3.6.1.2.1.2.2.1.5",
      "if_high_speed": "1.3.6.1.2.1.31.1.1.1.15",
      "if_in_errors": "1.3.6.1.2.1.2.2.1.14",
      "if_out_errors": "1.3.6.1.2.1.2.2.1.20",
      "if_in_discards": "1.3.6.1.2.1.2.2.1.13",
      "if_out_discards": "1.3.6.1.2.1.2.2.1.19"
    },
    "CISCO_IOS_XE": {
      "_extends": "STANDARD",
      "cpu_usage": "1.3.6.1.4.1.9.9.109.1.1.1.1.5.1",
      "memory_used": "1.3.6.1.4.1.9.9.48.1.1.1.5.1"
    },
    "HUAWEI_NE": {
      "_extends": "STANDARD",
      "active_subscribers": "1.3.6.1.4.1.2011.5.2.1.33.1.5.0",
      "pppoe_sessions": "1.3.6.1.4.1.2011.5.2.1.33.1.6.0"
    },
    "JUNIPER": {
      "_extends": "STANDARD",
      "cpu_usage": "1.3.6.1.4.1.2636.3.1.13.1.8",
      "memory_used": "1.3.6.1.4.1.2636.3.1.13.1.11"
    },
    "MIKROTIK": {
      "_extends": "STANDARD",
      "active_users": "1.3.6.1.4.1.14988.1.1.5.3",
      "cpu_usage": "1.3.6.1.4.1.14988.1.1.3.100.1.2.0"
    }
  }
}
```

---

## 12. Configuration Field Specifications

### 12.1 Meta Section (`_meta`)

| Field | Type | Description |
|-------|------|-------------|
| `config_serial` | integer | Version number for config change detection |
| `fetched_at` | string (ISO8601) | Timestamp when config was fetched from Core |
| `core_version` | string | Core API version that generated this config |

### 12.2 Agent Section (`agent`)

| Field | Type | Default | Description |
|-------|------|---------|-------------|
| `agent_enabled` | boolean | true | Master kill switch. false = DISABLED state |
| `maintenance_mode` | boolean | false | true = poll only, no metric submission |
| `debug_enabled` | boolean | false | true = submit logs to Core for remote validation |
| `log_level` | enum | "INFO" | DEBUG, INFO, WARN, ERROR |
| `prometheus_enabled` | boolean | false | Expose /metrics endpoint |
| `prometheus_port` | integer | 9100 | Port for Prometheus metrics |

### 12.3 Identity Section (`identity`)

| Field | Type | Description |
|-------|------|-------------|
| `isp_id` | integer | ISP identifier in Core system |
| `isp_name` | string | Human-readable ISP name (for logging) |
| `pop_ids` | array[integer] | POP identifiers this agent covers |
| `deployment_scope` | enum | "ISP" or "POP" - deployment model |
| `region` | string | Geographic region code |

### 12.4 Timing Section (`timing`)

| Field | Type | Default | Description |
|-------|------|---------|-------------|
| `poll_interval_sec` | integer | 300 | SNMP poll interval (seconds) |
| `submission_interval_sec` | integer | 900 | Metric submission window (seconds) |
| `polls_per_window` | integer | 3 | Number of polls per submission window |
| `startup_jitter_max_sec` | integer | 30 | Max random startup delay |
| `window_alignment` | boolean | true | Align submissions to clock boundaries |

### 12.5 Storage Section (`storage`)

| Field | Type | Default | Description |
|-------|------|---------|-------------|
| `retention_days` | integer | 7 | Local poll data retention period |
| `queue_retention_days` | integer | 3 | Queued submission retention period |
| `status_update_sec` | integer | 300 | Status file update interval |

### 12.6 SNMP Defaults Section (`snmp_defaults`)

| Field | Type | Default | Description |
|-------|------|---------|-------------|
| `timeout_sec` | integer | 5 | SNMP request timeout (seconds) |
| `retries` | integer | 3 | Retry count with exponential backoff |
| `backoff_multiplier` | float | 2.0 | Exponential backoff multiplier |
| `bulk_max_repetitions` | integer | 50 | GETBULK max-repetitions value |

### 12.7 Target Object (`targets[]`)

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `target_id` | string | YES | Unique target identifier |
| `hostname` | string | YES | FQDN or hostname |
| `ip_address` | string (IPv4/IPv6) | YES | Management IP address |
| `enabled` | boolean | YES | Target polling enabled |
| `device_type` | enum | YES | CORE_GATEWAY, AGGREGATION_DEVICE, BRAS, RAS, OTHER |
| `vendor_profile` | string | YES | Profile name from vendor_profiles |
| `snmp` | object | YES | SNMP credentials (see below) |
| `interfaces` | array | NO | Interface list for this target |
| `custom_oids` | array | NO | Additional OIDs to poll |

### 12.8 SNMP Credentials - SNMPv2c (`targets[].snmp`)

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `version` | string | YES | "v2c" |
| `port` | integer | NO | SNMP port (default 161) |
| `community` | string | YES | Community string |

### 12.9 SNMP Credentials - SNMPv3 (`targets[].snmp`)

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `version` | string | YES | "v3" |
| `port` | integer | NO | SNMP port (default 161) |
| `username` | string | YES | SNMPv3 username |
| `auth_protocol` | enum | YES | MD5, SHA, SHA224, SHA256, SHA384, SHA512 |
| `auth_password` | string | YES | Authentication password |
| `priv_protocol` | enum | Conditional | DES, AES128, AES192, AES256 (if authPriv) |
| `priv_password` | string | Conditional | Privacy password (if authPriv) |
| `security_level` | enum | YES | noAuthNoPriv, authNoPriv, authPriv |

### 12.10 Interface Object (`targets[].interfaces[]`)

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `if_index` | integer | YES | SNMP interface index |
| `if_name` | string | YES | Interface name (ifDescr) |
| `if_alias` | string | NO | Interface alias (ifAlias) |
| `if_type` | enum | YES | INTERNET, CACHE, IX, DOWNSTREAM |
| `speed_mbps` | integer | YES | Interface speed in Mbps |
| `monitor_enabled` | boolean | YES | Interface polling enabled |

### 12.11 Custom OID Object (`targets[].custom_oids[]`)

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `oid` | string | YES | Full OID string |
| `name` | string | YES | Human-readable name |
| `type` | enum | YES | counter32, counter64, gauge, string |

### 12.12 Threshold Configuration (`thresholds`)

| Field | Type | Default | Description |
|-------|------|---------|-------------|
| `utilization_warning_pct` | integer | 70 | Warning threshold (%) |
| `utilization_critical_pct` | integer | 90 | Critical threshold (%) |
| `hysteresis_pct` | integer | 5 | Clear threshold delta (prevents flapping) |
| `consecutive_failures_degraded` | integer | 3 | Failures before DEGRADED |
| `consecutive_failures_unreachable` | integer | 5 | Failures before UNREACHABLE |

---

## 13. Config Serial Flow

```
┌──────────────────────────────────────────────────────────────┐
│                        FIRST RUN                             │
├──────────────────────────────────────────────────────────────┤
│  1. Agent starts with bootstrap.json                         │
│  2. Calls: GET /api/v1/agent-snmp/config                          │
│  3. Core returns full config with config_serial: 100         │
│  4. Agent saves to /data/config/agent-config.json            │
│  5. Agent operates with fetched config                       │
└──────────────────────────────────────────────────────────────┘

┌──────────────────────────────────────────────────────────────┐
│                     SUBSEQUENT RUN                           │
├──────────────────────────────────────────────────────────────┤
│  1. Agent starts, loads cached config (serial: 100)          │
│  2. Calls: GET /api/v1/agent-snmp/config?config_serial=100               │
│  3. Core compares serials:                                   │
│     - If unchanged: 304 Not Modified (use cached)            │
│     - If updated:   200 OK with new config (serial: 101)     │
│  4. Agent updates cache if new config received               │
└──────────────────────────────────────────────────────────────┘

┌──────────────────────────────────────────────────────────────┐
│                        SIGHUP                                │
├──────────────────────────────────────────────────────────────┤
│  1. Operator sends: docker kill -s HUP <container>           │
│  2. Agent receives SIGHUP signal                             │
│  3. Same flow as SUBSEQUENT RUN (check serial → pull/skip)   │
│  4. Apply new config without container restart               │
└──────────────────────────────────────────────────────────────┘
```

---

## 14. Enum Values Reference

| Enum | Values |
|------|--------|
| `log_level` | DEBUG, INFO, WARN, ERROR |
| `deployment_scope` | ISP, POP |
| `device_type` | CORE_GATEWAY, AGGREGATION_DEVICE, BRAS, RAS, OTHER |
| `snmp_version` | v2c, v3 |
| `security_level` | noAuthNoPriv, authNoPriv, authPriv |
| `auth_protocol` | MD5, SHA, SHA224, SHA256, SHA384, SHA512 |
| `priv_protocol` | DES, AES128, AES192, AES256 |
| `if_type` | INTERNET, CACHE, IX, DOWNSTREAM |
| `oid_type` | counter32, counter64, gauge, string |
| `target_status` | HEALTHY, DEGRADED, UNREACHABLE |
| `poll_status` | SUCCESS, TIMEOUT, ERROR |

---

# PART IV: CORE API REFERENCE

---

## 15. Core API Overview

### Base URL

```
https://qos-core.btrc.gov.bd/api/v1
```

### Authentication

All API calls require the `X-API-Key` header:

```http
X-API-Key: sk-agent-xxxxxxxxxxxxxxxxxxxx
```

### TLS Requirements

- HTTPS only (TLS 1.2+)
- Agent must validate Core API certificate
- Self-signed certificates not supported in production

### Common Headers

```http
Content-Type: application/json
Accept: application/json
X-API-Key: sk-agent-xxxxxxxxxxxxxxxxxxxx
X-Agent-UUID: 7c9e6679-7425-40de-944b-e07fc1f90ae7
```

---

## 16. Core API Endpoints

### 16.1 Config Fetch API

**Endpoint**: `GET /api/v1/agent-snmp/config`

**Purpose**: Fetch full operational configuration

**Request Headers**:
```http
GET /api/v1/agent-snmp/config?config_serial=100 HTTP/1.1
Host: qos-core.btrc.gov.bd
X-API-Key: sk-agent-xxxxxxxxxxxxxxxxxxxx
X-Agent-UUID: 7c9e6679-7425-40de-944b-e07fc1f90ae7
```

**Query Parameters**:

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `config_serial` | integer | NO | Current cached config serial (omit on first run) |

**Response 200 OK** (new config available):
```json
{
  "_meta": {
    "config_serial": 101,
    "fetched_at": "2026-01-15T10:00:00+06:00",
    "core_version": "1.2.0"
  },
  "agent": { ... },
  "identity": { ... },
  "targets": [ ... ]
}
```

**Response 304 Not Modified** (use cached):
```http
HTTP/1.1 304 Not Modified
```

**Error Responses**:

| Status | Description |
|--------|-------------|
| 401 | Invalid API key |
| 403 | Agent not authorized |
| 404 | Agent UUID not found |
| 500 | Internal server error |

---

### 16.2 SNMP Combined Submission API

**Endpoint**: `POST /api/v1/submissions/snmp-combined`

**Purpose**: Submit interface metrics and subscriber counts

**Request Headers**:
```http
POST /api/v1/submissions/snmp-combined HTTP/1.1
Host: qos-core.btrc.gov.bd
Content-Type: application/json
X-API-Key: sk-agent-xxxxxxxxxxxxxxxxxxxx
X-Agent-UUID: 7c9e6679-7425-40de-944b-e07fc1f90ae7
```

**Request Body**: See Section 17 (Data Model)

**Response 200 OK** (accepted):
```json
{
  "status": "accepted",
  "submission_uuid": "550e8400-e29b-41d4-a716-446655440000",
  "records_processed": 11,
  "processing_time_ms": 45
}
```

**Response 202 Accepted** (queued for processing):
```json
{
  "status": "queued",
  "submission_uuid": "550e8400-e29b-41d4-a716-446655440000",
  "queue_position": 5
}
```

**Error Responses**:

| Status | Code | Description |
|--------|------|-------------|
| 400 | INVALID_JSON | Malformed JSON body |
| 400 | VALIDATION_ERROR | Schema validation failed |
| 401 | AUTH_FAILED | Invalid API key |
| 422 | DUPLICATE_SUBMISSION | submission_uuid already processed |
| 500 | INTERNAL_ERROR | Server error |

---

### 16.3 Log Submission API

**Endpoint**: `POST /api/v1/agent-snmp/logs`

**Purpose**: Submit agent logs (when debug_enabled=true)

**Request**:
```http
POST /api/v1/agent-snmp/logs HTTP/1.1
Host: qos-core.btrc.gov.bd
Content-Type: application/json
X-API-Key: sk-agent-xxxxxxxxxxxxxxxxxxxx
X-Agent-UUID: 7c9e6679-7425-40de-944b-e07fc1f90ae7
```

**Request Body**:
```json
{
  "agent_uuid": "7c9e6679-7425-40de-944b-e07fc1f90ae7",
  "timestamp": "2026-01-15T10:15:00+06:00",
  "logs": [
    {
      "timestamp": "2026-01-15T10:14:55.123+06:00",
      "level": "INFO",
      "logger": "snmp_agent.poller",
      "message": "Poll cycle completed",
      "context": {
        "targets_polled": 4,
        "successful": 3,
        "failed": 1
      }
    }
  ]
}
```

**Response 200 OK**:
```json
{
  "status": "accepted",
  "logs_received": 1
}
```

---

# PART V: DATA MODEL & SUBMISSION PAYLOAD

---

## 17. Combined Submission Structure

### Overview

The SNMP_AGENT submits a combined payload containing:
- Submission header and summary
- Agent status
- Target status array
- Interface metrics array
- Subscriber counts array

### Complete JSON Submission Example

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
      }
    },
    {
      "time": "2026-01-15T10:00:00+06:00",
      "poll_sequence": 1,
      "pop_id": 1523,
      "interface_type": "IX",
      "upstream_operator": "BDIX",
      "snmp_target": {
        "target_id": "t-001",
        "device_type": "CORE_GATEWAY",
        "vendor": "CISCO",
        "mib_profile": "STANDARD",
        "target_ip": "10.0.1.1",
        "target_hostname": "core-rtr-01.isp.net",
        "if_index": 2,
        "if_name": "GigabitEthernet0/0/1",
        "if_description": "BDIX Peering Link",
        "if_speed_mbps": 10000
      },
      "poll_status": "SUCCESS",
      "poll_duration_ms": 156,
      "metrics": {
        "admin_status": "UP",
        "oper_status": "UP",
        "in_bps": 4294967296,
        "out_bps": 104857600,
        "in_errors": 0,
        "out_errors": 0,
        "in_discards": 0,
        "out_discards": 0,
        "utilization_in_pct": 42.95,
        "utilization_out_pct": 1.05
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
        "target_hostname": "bras-01.isp.net",
        "oid_active_sessions": ".1.3.6.1.4.1.2011.5.2.1.33.1.2.0",
        "oid_pppoe_sessions": ".1.3.6.1.4.1.2011.5.2.1.33.1.3.0"
      },
      "poll_status": "TIMEOUT",
      "poll_duration_ms": 5000,
      "error": {
        "code": "SNMP_TIMEOUT",
        "message": "SNMP request timed out after 5000ms",
        "retries_attempted": 3
      },
      "metrics": null
    },
    {
      "time": "2026-01-15T10:00:00+06:00",
      "bras_id": "RAS-DHK-01",
      "bras_name": "Dhaka RAS Server",
      "region": "Dhaka Division",
      "snmp_target": {
        "target_id": "t-003",
        "device_type": "RAS",
        "vendor": "MIKROTIK",
        "mib_profile": "VENDOR_EXT",
        "target_ip": "10.0.3.1",
        "target_hostname": "ras-01.isp.net",
        "oid_active_sessions": ".1.3.6.1.4.1.14988.1.1.5.1.0",
        "oid_pppoe_sessions": ".1.3.6.1.4.1.14988.1.1.5.2.0"
      },
      "poll_status": "SUCCESS",
      "poll_duration_ms": 95,
      "metrics": {
        "active_sessions": 2340,
        "pppoe_sessions": 2340,
        "dhcp_leases": 0,
        "ipoe_sessions": 0
      }
    }
  ],
  "alerts": [
    {
      "alert_id": "alert-001",
      "alert_type": "THRESHOLD_VIOLATION",
      "severity": "WARNING",
      "target_id": "t-001",
      "interface_index": 1,
      "metric": "utilization_in_pct",
      "current_value": 53.69,
      "threshold_value": 70,
      "raised_at": "2026-01-15T09:45:00+06:00",
      "status": "CLEARED"
    }
  ]
}
```

---

## 18. Submission Field Specifications

### 18.1 Submission Header

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| submission_uuid | UUID | Yes | Unique identifier per submission |
| originator_type | STRING | Yes | Always "SNMP_AGENT" |
| agent_uuid | UUID | Yes | Registered agent identifier |
| agent_version | STRING | Yes | Agent software version |
| isp_id | INTEGER | Yes | ISP identifier |
| submission_time | ISO8601 | Yes | When submitted |
| reporting_period_start | ISO8601 | Yes | 15-min window start |
| reporting_period_end | ISO8601 | Yes | 15-min window end |
| poll_interval_sec | INTEGER | Yes | Poll interval (300 = 5 min) |
| polls_in_batch | INTEGER | Yes | Number of polls in batch (3) |

### 18.2 Submission Summary

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| interface_records | INTEGER | Yes | Count of interface metric records |
| subscriber_records | INTEGER | Yes | Count of subscriber count records |
| total_records | INTEGER | Yes | Total records in submission |
| successful_polls | INTEGER | Yes | Count of successful polls |
| failed_polls | INTEGER | Yes | Count of failed polls |
| partial_submission | BOOLEAN | Yes | true if some workers failed/timed out |

### 18.3 Agent Status

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| host_ip | IP | Yes | Private/LAN IP of agent host |
| public_ip | IP | Yes | NAT/Public IP (from core API) |
| public_ip_source | ENUM | Yes | CORE_API / EXTERNAL / STATIC |
| public_ip_fetch_time | ISO8601 | Yes | When public IP was resolved |
| container_id | STRING | No | Docker container ID |
| status | ENUM | Yes | ACTIVE / INACTIVE / ERROR |
| status_message | STRING | No | Status details |
| last_heartbeat | ISO8601 | Yes | Last heartbeat timestamp |
| uptime_seconds | INTEGER | No | Agent uptime |

### 18.4 Target Status

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| target_id | STRING | Yes | SNMP target reference |
| device_type | ENUM | Yes | CORE_GATEWAY / AGGREGATION_DEVICE / BRAS / RAS / OTHER |
| target_ip | IP | Yes | Device IP |
| target_hostname | STRING | No | Device hostname |
| status | ENUM | Yes | HEALTHY / DEGRADED / UNREACHABLE |
| polls_attempted | INTEGER | Yes | Total polls attempted |
| polls_successful | INTEGER | Yes | Successful poll count |
| polls_failed | INTEGER | Yes | Failed poll count |
| last_success_time | ISO8601 | No | Last successful poll time |
| last_failure_time | ISO8601 | No | Last failed poll time |
| consecutive_failures | INTEGER | Yes | Running count of consecutive failures |
| failure_reason | STRING | No | If UNREACHABLE: TIMEOUT/AUTH/NETWORK |

### 18.5 Interface Metrics

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| time | ISO8601 | Yes | Poll timestamp |
| poll_sequence | INTEGER | Yes | Position in batch (1, 2, or 3) |
| pop_id | INTEGER | Yes | PoP identifier |
| interface_type | ENUM | Yes | INTERNET / CACHE / IX / DOWNSTREAM |
| upstream_operator | STRING | No | Peering/upstream provider name; null for DOWNSTREAM |
| snmp_target | OBJECT | Yes | Target details (see below) |
| poll_status | ENUM | Yes | SUCCESS / TIMEOUT / ERROR |
| poll_duration_ms | INTEGER | Yes | Time taken for SNMP request |
| metrics | OBJECT | Conditional | Metrics object (null if poll failed) |

### 18.6 Interface Metrics Values

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| admin_status | ENUM | Yes* | UP / DOWN / TESTING |
| oper_status | ENUM | Yes* | UP / DOWN / DORMANT |
| in_bps | BIGINT | Yes* | Inbound bits per second |
| out_bps | BIGINT | Yes* | Outbound bits per second |
| in_errors | INTEGER | No | Inbound error count |
| out_errors | INTEGER | No | Outbound error count |
| in_discards | INTEGER | No | Inbound discards |
| out_discards | INTEGER | No | Outbound discards |
| utilization_in_pct | DECIMAL | Yes* | Inbound utilization % |
| utilization_out_pct | DECIMAL | Yes* | Outbound utilization % |

*Note: metrics is null if poll_status != SUCCESS

### 18.7 Subscriber Counts

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| time | ISO8601 | Yes | Poll timestamp |
| bras_id | STRING | Yes | Unique BRAS/RAS identifier |
| bras_name | STRING | Yes | Human-readable name |
| region | STRING | Yes | Geographic region |
| snmp_target | OBJECT | Yes | Target details |
| poll_status | ENUM | Yes | SUCCESS / TIMEOUT / ERROR |
| poll_duration_ms | INTEGER | Yes | Poll duration in ms |
| metrics | OBJECT | Conditional | Metrics (null if failed) |

### 18.8 Subscriber Metrics

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| active_sessions | INTEGER | Yes* | Total active subscriber sessions |
| pppoe_sessions | INTEGER | No | PPPoE session count |
| dhcp_leases | INTEGER | No | DHCP lease count |
| ipoe_sessions | INTEGER | No | IPoE session count |

---

# PART VI: SNMP POLLING REFERENCE

---

## 19. Standard MIB OIDs (IF-MIB)

### Interface Table OIDs

| OID | Name | Type | Description |
|-----|------|------|-------------|
| 1.3.6.1.2.1.2.2.1.1 | ifIndex | INTEGER | Interface index |
| 1.3.6.1.2.1.2.2.1.2 | ifDescr | STRING | Interface description |
| 1.3.6.1.2.1.2.2.1.5 | ifSpeed | Gauge32 | Interface speed (bps) |
| 1.3.6.1.2.1.2.2.1.7 | ifAdminStatus | INTEGER | Admin status (1=up, 2=down, 3=testing) |
| 1.3.6.1.2.1.2.2.1.8 | ifOperStatus | INTEGER | Operational status |
| 1.3.6.1.2.1.2.2.1.10 | ifInOctets | Counter32 | Inbound octets |
| 1.3.6.1.2.1.2.2.1.13 | ifInDiscards | Counter32 | Inbound discards |
| 1.3.6.1.2.1.2.2.1.14 | ifInErrors | Counter32 | Inbound errors |
| 1.3.6.1.2.1.2.2.1.16 | ifOutOctets | Counter32 | Outbound octets |
| 1.3.6.1.2.1.2.2.1.19 | ifOutDiscards | Counter32 | Outbound discards |
| 1.3.6.1.2.1.2.2.1.20 | ifOutErrors | Counter32 | Outbound errors |

### High-Capacity Counters (64-bit)

| OID | Name | Type | Description |
|-----|------|------|-------------|
| 1.3.6.1.2.1.31.1.1.1.6 | ifHCInOctets | Counter64 | 64-bit inbound octets |
| 1.3.6.1.2.1.31.1.1.1.10 | ifHCOutOctets | Counter64 | 64-bit outbound octets |
| 1.3.6.1.2.1.31.1.1.1.15 | ifHighSpeed | Gauge32 | Interface speed (Mbps) |

---

## 20. Vendor-Specific OIDs

### Cisco IOS/IOS-XE

| OID | Name | Type | Description |
|-----|------|------|-------------|
| 1.3.6.1.4.1.9.9.109.1.1.1.1.5.1 | cpmCPUTotal5min | Gauge32 | 5-min CPU utilization |
| 1.3.6.1.4.1.9.9.48.1.1.1.5.1 | ciscoMemoryPoolUsed | Gauge32 | Memory pool used |
| 1.3.6.1.4.1.9.9.48.1.1.1.6.1 | ciscoMemoryPoolFree | Gauge32 | Memory pool free |

### Huawei NE Series

| OID | Name | Type | Description |
|-----|------|------|-------------|
| 1.3.6.1.4.1.2011.5.2.1.33.1.5.0 | hwUserOnlineNum | Gauge32 | Online users count |
| 1.3.6.1.4.1.2011.5.2.1.33.1.6.0 | hwPPPoEOnlineNum | Gauge32 | PPPoE sessions |
| 1.3.6.1.4.1.2011.5.6.1.1.1.4 | hwDhcpSnpBindNum | Gauge32 | DHCP bindings |

### Juniper JunOS

| OID | Name | Type | Description |
|-----|------|------|-------------|
| 1.3.6.1.4.1.2636.3.1.13.1.8 | jnxOperatingCPU | Gauge32 | CPU utilization |
| 1.3.6.1.4.1.2636.3.1.13.1.11 | jnxOperatingBuffer | Gauge32 | Buffer utilization |

### MikroTik RouterOS

| OID | Name | Type | Description |
|-----|------|------|-------------|
| 1.3.6.1.4.1.14988.1.1.5.1.0 | mtxrWlApClientCount | Gauge32 | Wireless client count |
| 1.3.6.1.4.1.14988.1.1.5.3 | mtxrHotspotActiveUsersCount | Gauge32 | Active hotspot users |
| 1.3.6.1.4.1.14988.1.1.3.100.1.2.0 | mtxrGaugeCpuFrequency | Gauge32 | CPU frequency |

---

## 21. Raw SNMP Poll Examples

### snmpwalk Interface Table (SNMPv2c)

```bash
$ snmpwalk -v2c -c public 10.0.1.1 1.3.6.1.2.1.2.2.1

IF-MIB::ifIndex.1 = INTEGER: 1
IF-MIB::ifIndex.2 = INTEGER: 2
IF-MIB::ifDescr.1 = STRING: GigabitEthernet0/0/0
IF-MIB::ifDescr.2 = STRING: GigabitEthernet0/0/1
IF-MIB::ifSpeed.1 = Gauge32: 1000000000
IF-MIB::ifSpeed.2 = Gauge32: 10000000000
IF-MIB::ifAdminStatus.1 = INTEGER: up(1)
IF-MIB::ifAdminStatus.2 = INTEGER: up(1)
IF-MIB::ifOperStatus.1 = INTEGER: up(1)
IF-MIB::ifOperStatus.2 = INTEGER: up(1)
IF-MIB::ifInOctets.1 = Counter32: 3847523840
IF-MIB::ifInOctets.2 = Counter32: 1256985600
IF-MIB::ifOutOctets.1 = Counter32: 982456320
IF-MIB::ifOutOctets.2 = Counter32: 4523698710
```

### snmpget Specific OID (SNMPv2c)

```bash
$ snmpget -v2c -c public 10.0.1.1 \
    1.3.6.1.2.1.31.1.1.1.6.1 \
    1.3.6.1.2.1.31.1.1.1.10.1

IF-MIB::ifHCInOctets.1 = Counter64: 1234567890123456
IF-MIB::ifHCOutOctets.1 = Counter64: 987654321098765
```

### snmpbulkget Multiple OIDs (SNMPv2c)

```bash
$ snmpbulkget -v2c -c public -Cn0 -Cr10 10.0.1.1 \
    1.3.6.1.2.1.31.1.1.1.6 \
    1.3.6.1.2.1.31.1.1.1.10

IF-MIB::ifHCInOctets.1 = Counter64: 1234567890123456
IF-MIB::ifHCInOctets.2 = Counter64: 2345678901234567
IF-MIB::ifHCOutOctets.1 = Counter64: 987654321098765
IF-MIB::ifHCOutOctets.2 = Counter64: 876543210987654
```

### SNMPv3 Authentication

```bash
$ snmpget -v3 \
    -u snmpuser \
    -l authPriv \
    -a SHA \
    -A "authpass123" \
    -x AES \
    -X "privpass123" \
    10.0.2.1 \
    1.3.6.1.4.1.2011.5.2.1.33.1.5.0

SNMPv2-SMI::enterprises.2011.5.2.1.33.1.5.0 = Gauge32: 48750
```

---

## 22. Metric Calculations

### 22.1 Rate Calculation (bps)

**Formula**:
```
rate_bps = (counter_current - counter_previous) * 8 / interval_seconds
```

**Example**:
```
Poll at T+0:   ifHCInOctets = 1,000,000,000,000 bytes
Poll at T+5:   ifHCInOctets = 1,105,966,080,000 bytes
Interval:      300 seconds

rate_bps = (1,105,966,080,000 - 1,000,000,000,000) * 8 / 300
         = 105,966,080,000 * 8 / 300
         = 847,728,640,000 / 300
         = 2,825,762,133 bps
         ≈ 2.83 Gbps
```

### 22.2 Utilization Calculation (%)

**Formula**:
```
utilization_pct = (rate_bps / interface_speed_bps) * 100
```

**Example**:
```
rate_bps:           2,825,762,133 bps
interface_speed:    10,000,000,000 bps (10 Gbps)

utilization_pct = (2,825,762,133 / 10,000,000,000) * 100
                = 0.2826 * 100
                = 28.26%
```

### 22.3 Counter Wrap Handling (32-bit Rollover)

#### The Problem

32-bit SNMP counters (ifInOctets, ifOutOctets) have a maximum value of **4,294,967,295** (2^32 - 1). On high-speed interfaces, these counters wrap around frequently:

| Interface Speed | Time to Wrap (Full Utilization) |
|-----------------|--------------------------------|
| 100 Mbps | ~5.7 minutes |
| 1 Gbps | ~34 seconds |
| 10 Gbps | ~3.4 seconds |
| 100 Gbps | ~0.34 seconds |

**Critical**: At 1 Gbps and above, 32-bit counters can wrap **multiple times** between 5-minute poll intervals!

#### Counter Selection Strategy

```
┌─────────────────────────────────────────────────────────────────────────┐
│                    COUNTER SELECTION DECISION TREE                       │
├─────────────────────────────────────────────────────────────────────────┤
│                                                                          │
│   1. Try ifHCInOctets/ifHCOutOctets (64-bit) FIRST                      │
│      └── OID: 1.3.6.1.2.1.31.1.1.1.6 / 1.3.6.1.2.1.31.1.1.1.10         │
│                                                                          │
│   2. If 64-bit not supported (noSuchObject):                            │
│      └── Fall back to ifInOctets/ifOutOctets (32-bit)                   │
│      └── OID: 1.3.6.1.2.1.2.2.1.10 / 1.3.6.1.2.1.2.2.1.16              │
│                                                                          │
│   3. Store counter_type in target config for future polls               │
│                                                                          │
└─────────────────────────────────────────────────────────────────────────┘
```

#### 32-bit Wrap Detection Algorithm

```python
MAX_32BIT = 4294967295  # 2^32 - 1

def calculate_delta_with_wrap(counter_current, counter_previous, counter_type="32bit"):
    """
    Calculate counter delta, handling wrap-around.
    Returns: (delta, wrapped_flag)
    """
    if counter_type == "64bit":
        MAX_VALUE = 18446744073709551615  # 2^64 - 1
    else:
        MAX_VALUE = 4294967295  # 2^32 - 1

    if counter_current >= counter_previous:
        # Normal case: no wrap
        delta = counter_current - counter_previous
        return (delta, False)
    else:
        # Counter wrapped around
        delta = (MAX_VALUE - counter_previous) + counter_current + 1
        return (delta, True)
```

#### Rate Calculation with Wrap Handling

```python
def calculate_rate_bps(current_octets, previous_octets, interval_sec, counter_type="32bit"):
    """
    Calculate bits per second from octet counters.
    Handles 32-bit counter wrap-around.
    """
    delta, wrapped = calculate_delta_with_wrap(current_octets, previous_octets, counter_type)

    # Sanity check: detect likely device reboot or counter reset
    # If delta implies rate > interface_speed * 2, likely invalid
    rate_bps = (delta * 8) / interval_sec

    return {
        "rate_bps": rate_bps,
        "delta_octets": delta,
        "counter_wrapped": wrapped,
        "interval_sec": interval_sec
    }
```

#### Multiple Wrap Detection (High-Speed Interfaces)

**Problem**: On 10Gbps+ interfaces with 5-minute poll intervals, the counter may wrap **multiple times**, making accurate calculation impossible with 32-bit counters.

```
Poll Interval: 300 seconds
Interface Speed: 10 Gbps = 1,250,000,000 bytes/sec at 100% utilization

Max bytes in 300 sec: 1,250,000,000 × 300 = 375,000,000,000 bytes
32-bit max: 4,294,967,295 bytes

Wraps in interval: 375,000,000,000 / 4,294,967,295 ≈ 87 times!
```

**Solution**: For high-speed interfaces (≥1 Gbps):

| Scenario | Action |
|----------|--------|
| 64-bit counters available | Use ifHCInOctets/ifHCOutOctets (REQUIRED) |
| 64-bit NOT available | Flag data as UNRELIABLE, log warning |
| Multiple wraps detected | Set `utilization_pct = null`, include `data_quality: "UNRELIABLE"` |

#### Wrap Detection in Time-Series Data

When storing time-series utilization data, include wrap metadata:

```json
{
  "time": "2026-01-15T10:05:00+06:00",
  "interface_id": 1,
  "metrics": {
    "in_bps": 5368709120,
    "out_bps": 1073741824,
    "utilization_in_pct": 53.69,
    "utilization_out_pct": 10.74
  },
  "counter_metadata": {
    "counter_type": "32bit",
    "in_counter_wrapped": false,
    "out_counter_wrapped": true,
    "in_counter_raw": 1234567890,
    "out_counter_raw": 987654321,
    "data_quality": "RELIABLE"
  }
}
```

#### Data Quality Flags

| Flag | Condition | Action |
|------|-----------|--------|
| `RELIABLE` | No wrap OR single wrap detected and handled | Use data normally |
| `WRAPPED` | Counter wrapped, delta calculated correctly | Use data, flag for review |
| `UNRELIABLE` | Multiple wraps possible (32-bit on high-speed) | Exclude from aggregations |
| `RESET` | Counter decreased significantly (device reboot) | Discard this interval |

#### Device Reboot Detection

A device reboot resets counters to zero or a low value. Detect this scenario:

```python
def detect_reboot(counter_current, counter_previous, interface_speed_bps, interval_sec):
    """
    Detect likely device reboot vs legitimate wrap.
    """
    # Calculate theoretical max bytes in interval
    max_bytes = (interface_speed_bps / 8) * interval_sec

    if counter_current < counter_previous:
        # Could be wrap or reboot
        wrap_delta = (MAX_32BIT - counter_previous) + counter_current + 1

        # If wrap_delta > 2x theoretical max, likely reboot
        if wrap_delta > (max_bytes * 2):
            return "REBOOT_DETECTED"
        else:
            return "COUNTER_WRAPPED"

    return "NORMAL"
```

#### Implementation Recommendations

1. **Always try 64-bit counters first** (ifHCInOctets/ifHCOutOctets)
2. **Cache counter type per interface** after first successful poll
3. **For interfaces ≥1 Gbps**: Require 64-bit counters, reject 32-bit as unreliable
4. **Include wrap metadata** in all submissions for Core-side validation
5. **Log warnings** when forced to use 32-bit on high-speed interfaces
6. **Shorten poll interval** if stuck with 32-bit on fast interfaces (not recommended)

#### Example: Handling Wrap in Submission

```json
{
  "interface_metrics": [
    {
      "time": "2026-01-15T10:05:00+06:00",
      "snmp_target": {
        "target_id": "t-001",
        "if_index": 1,
        "if_speed_mbps": 10000
      },
      "poll_status": "SUCCESS",
      "metrics": {
        "in_bps": 5368709120,
        "utilization_in_pct": 53.69
      },
      "counter_info": {
        "counter_type": "64bit",
        "oid_used": "1.3.6.1.2.1.31.1.1.1.6",
        "raw_value": 98765432109876543,
        "previous_value": 98765430000000000,
        "wrapped": false,
        "data_quality": "RELIABLE"
      }
    },
    {
      "time": "2026-01-15T10:05:00+06:00",
      "snmp_target": {
        "target_id": "t-002",
        "if_index": 5,
        "if_speed_mbps": 1000
      },
      "poll_status": "SUCCESS",
      "metrics": {
        "in_bps": 847523840,
        "utilization_in_pct": 84.75
      },
      "counter_info": {
        "counter_type": "32bit",
        "oid_used": "1.3.6.1.2.1.2.2.1.10",
        "raw_value": 1234567890,
        "previous_value": 4123456789,
        "wrapped": true,
        "wrap_count": 1,
        "data_quality": "WRAPPED"
      }
    }
  ]
}
```

---

# PART VII: ERROR HANDLING

---

## 23. SNMP Error Codes

| Code | Description | Action |
|------|-------------|--------|
| SNMP_TIMEOUT | Request timed out | Retry with backoff |
| SNMP_NO_RESPONSE | No response from agent | Check network connectivity |
| SNMP_AUTH_FAILURE | Community/SNMPv3 auth failed | Verify credentials |
| SNMP_NO_SUCH_OID | Requested OID not found | Check OID compatibility |
| SNMP_TOOBIG | Response too large | Reduce GETBULK repetitions |
| NETWORK_UNREACHABLE | Cannot reach target IP | Check routing/firewall |
| CONNECTION_REFUSED | Target refused connection | Verify SNMP is enabled |

---

## 24. HTTP Error Codes (Core API)

| Status | Code | Description | Action |
|--------|------|-------------|--------|
| 400 | INVALID_JSON | Malformed JSON body | Fix JSON syntax |
| 400 | VALIDATION_ERROR | Schema validation failed | Check field types/values |
| 401 | AUTH_FAILED | Invalid API key | Verify api_key |
| 403 | FORBIDDEN | Agent not authorized | Contact administrator |
| 404 | NOT_FOUND | Agent UUID not found | Re-register agent |
| 422 | DUPLICATE | submission_uuid already processed | Generate new UUID |
| 429 | RATE_LIMITED | Too many requests | Implement backoff |
| 500 | INTERNAL_ERROR | Server error | Retry later |
| 502 | BAD_GATEWAY | Upstream error | Retry later |
| 503 | UNAVAILABLE | Service unavailable | Queue and retry |

---

## 25. Retry Logic & Backoff

### Exponential Backoff Formula

```
delay = min(base_delay * (multiplier ^ attempt), max_delay)
```

**Example**:
```
base_delay:   1 second
multiplier:   2.0
max_delay:    300 seconds (5 min)

Attempt 1: delay = min(1 * 2^1, 300) = 2 seconds
Attempt 2: delay = min(1 * 2^2, 300) = 4 seconds
Attempt 3: delay = min(1 * 2^3, 300) = 8 seconds
Attempt 4: delay = min(1 * 2^4, 300) = 16 seconds
...
Attempt 9: delay = min(1 * 2^9, 300) = 300 seconds (capped)
```

### Circuit Breaker Pattern

```
State: CLOSED (normal operation)
  ├── On success: reset failure count
  └── On failure: increment failure count
      └── If failures >= threshold: transition to OPEN

State: OPEN (circuit broken)
  ├── Reject all requests immediately
  └── After timeout: transition to HALF_OPEN

State: HALF_OPEN (testing recovery)
  ├── Allow single request
  ├── On success: transition to CLOSED
  └── On failure: transition to OPEN
```

---

# PART VIII: LOCAL FILE STRUCTURES

---

## 26. Volume Structure

```
/config/                          (MOUNT: read-only bootstrap)
└── bootstrap.json                Static: agent_uuid, api_key, core_url

/data/                            (MOUNT: read-write persistent)
├── config/
│   └── agent-config.json         Cached config from Core (with serial)
├── polls/
│   └── YYYY-MM-DD/               Daily poll data (JSON files)
│       ├── poll-100000.json      Poll at 10:00:00
│       ├── poll-100500.json      Poll at 10:05:00
│       └── poll-101000.json      Poll at 10:10:00
├── queue/
│   └── pending-*.json            Queued submissions (store-and-forward)
└── agent-status.json             Current status (updated every 5 min)

/logs/                            (MOUNT: read-write)
├── agent.log                     Current log file
├── agent.log.1                   Rotated log
└── agent.log.2.gz                Compressed rotated log
```

---

## 27. Queue File Structure

**Location**: `/data/queue/pending-{timestamp}-{uuid}.json`

**Example Filename**: `pending-20260115T101500-abc123.json`

```json
{
  "queue_id": "q-20260115T101500-abc123",
  "created_at": "2026-01-15T10:15:00+06:00",
  "retry_count": 2,
  "last_retry": "2026-01-15T10:17:30+06:00",
  "next_retry": "2026-01-15T10:21:30+06:00",
  "expires_at": "2026-01-18T10:15:00+06:00",
  "submission": {
    "submission_uuid": "550e8400-e29b-41d4-a716-446655440000",
    "originator_type": "SNMP_AGENT",
    "...": "full submission payload"
  }
}
```

---

## 28. Poll Data File Structure

**Location**: `/data/polls/YYYY-MM-DD/poll-HHMMSS.json`

**Example**: `/data/polls/2026-01-15/poll-100000.json`

```json
{
  "poll_time": "2026-01-15T10:00:00+06:00",
  "poll_sequence": 1,
  "poll_duration_ms": 2340,
  "targets": [
    {
      "target_id": "t-001",
      "status": "SUCCESS",
      "duration_ms": 145,
      "interfaces": [
        {
          "if_index": 1,
          "if_in_octets": 1234567890123456,
          "if_out_octets": 987654321098765,
          "if_admin_status": 1,
          "if_oper_status": 1
        }
      ]
    }
  ]
}
```

# PART IX: ALERTING & THRESHOLDS

---

## 29. Threshold Configuration

### Threshold Levels

| Level | Purpose | Action |
|-------|---------|--------|
| WARNING | Early warning | Log locally, include in submission |
| CRITICAL | Immediate attention | Log locally, include in submission |

### Hysteresis Logic

```
RAISE threshold: 70%
CLEAR threshold: 70% - 5% = 65%

Timeline:
- 10:00 - utilization = 68% → No alert
- 10:05 - utilization = 72% → ALERT RAISED (crossed 70%)
- 10:10 - utilization = 69% → Alert ACTIVE (above 65%)
- 10:15 - utilization = 66% → Alert ACTIVE (above 65%)
- 10:20 - utilization = 64% → ALERT CLEARED (below 65%)
```

---

## 30. Alert Object Structure

```json
{
  "alert_id": "alert-20260115-001",
  "alert_type": "THRESHOLD_VIOLATION",
  "severity": "WARNING",
  "target_id": "t-001",
  "interface_index": 1,
  "interface_name": "GigabitEthernet0/0/0",
  "metric": "utilization_in_pct",
  "current_value": 72.5,
  "threshold_value": 70,
  "threshold_type": "WARNING",
  "raised_at": "2026-01-15T10:05:00+06:00",
  "last_value_at": "2026-01-15T10:15:00+06:00",
  "status": "ACTIVE",
  "cleared_at": null
}
```

---

# PART XI: DEPLOYMENT REFERENCE

---

## 31. Deployment Lifecycle

### Phase 1: Registration

1. Operator creates agent in Core (gets UUID + API key)
2. Core sets: `agent_enabled=false`, `maintenance_mode=true`, `debug_enabled=true`
3. Operator deploys container with bootstrap config
4. Agent authenticates → enters DISABLED state (waits)

### Phase 2: Activation

1. Operator configures targets in Core
2. Operator sets: `agent_enabled=true` (bumps serial)
3. Send SIGHUP to container OR wait for restart
4. Agent pulls new config → enters MAINTENANCE mode

### Phase 3: Validation

1. Agent polls SNMP targets
2. Agent submits LOGS to Core (not metrics)
3. Operator views logs in Core dashboard (remote validation)
4. Validates all targets reachable and healthy
5. If issues → fix, agent retries on next poll cycle

### Phase 4: Go Live

1. Operator confirms all targets healthy
2. Operator sets: `maintenance_mode=false` (bumps serial)
3. Optionally sets: `debug_enabled=false`
4. Agent pulls new config → enters ACTIVE mode
5. Agent submits METRICS to Core (production)

---

## 32. Docker Compose Example

```yaml
version: '3.8'

services:
  snmp-agent:
    image: btrc/snmp-agent:1.2.3
    container_name: snmp-agent-isp142
    restart: on-failure:5
    environment:
      - SNMP_AGENT_API_KEY=${SNMP_AGENT_API_KEY}
      - TZ=Asia/Dhaka
    volumes:
      - ./config:/config:ro
      - snmp-data:/data
      - snmp-logs:/logs
    networks:
      - monitoring
    deploy:
      resources:
        limits:
          cpus: '1.0'
          memory: 512M
        reservations:
          cpus: '0.25'
          memory: 128M

volumes:
  snmp-data:
  snmp-logs:

networks:
  monitoring:
    driver: bridge
```

---

## 33. Environment Variables

| Variable | Required | Description |
|----------|----------|-------------|
| SNMP_AGENT_API_KEY | NO | API key (overrides bootstrap.json) |
| TZ | YES | Timezone (Asia/Dhaka for BST) |
| LOG_LEVEL | NO | Override config log level |

---

## 34. Resource Recommendations

| Targets | CPU | Memory | Disk |
|---------|-----|--------|------|
| 1-10 | 0.5 cores | 256 MB | 1 GB |
| 11-50 | 1.0 cores | 512 MB | 5 GB |
| 51-100 | 2.0 cores | 1 GB | 10 GB |

---

# PART XIII: TROUBLESHOOTING

---

## 35. Common Issues

### Agent Stuck in BOOTSTRAP

**Symptoms**: Agent never reaches ACTIVE state

**Causes**:
1. Core API unreachable
2. Invalid API key
3. ISP validation failed

**Diagnosis**:
```bash
docker logs snmp-agent | grep -E "(ERROR|WARN)"
docker exec snmp-agent snmp-agent status
```

### All Targets UNREACHABLE

**Symptoms**: All polls fail

**Causes**:
1. Network/firewall blocking SNMP (UDP 161)
2. Wrong SNMP credentials
3. SNMP disabled on targets

**Diagnosis**:
```bash
docker exec snmp-agent snmp-agent test-target t-001
```

### Queue Growing Continuously

**Symptoms**: Submissions not being processed

**Causes**:
1. Core API unreachable
2. Rate limiting
3. Persistent validation errors

**Diagnosis**:
```bash
docker exec snmp-agent snmp-agent status
ls -la /data/queue/
```

---

## 36. Diagnostic Checklist

```
[ ] Agent container running?
    docker ps | grep snmp-agent

[ ] Bootstrap config valid?
    docker exec snmp-agent cat /config/bootstrap.json

[ ] Core API reachable?
    docker exec snmp-agent curl -I https://qos-core.btrc.gov.bd/health

[ ] Config fetched successfully?
    docker exec snmp-agent cat /data/config/agent-config.json

[ ] ISP validation passed?
    docker exec snmp-agent snmp-agent status | grep State

[ ] SNMP targets reachable?
    docker exec snmp-agent snmp-agent test-target t-001

[ ] Submissions succeeding?
    docker exec snmp-agent snmp-agent status | grep Submission

[ ] No errors in logs?
    docker logs snmp-agent --tail 100 | grep ERROR
```

---

# APPENDICES

---

## Appendix A: Changelog

| Version | Date | Changes |
|---------|------|---------|
| 0.1 | 2026-01-15 | Initial feature list with user requirements |
| 0.2 | 2026-01-15 | Added clarifications: SNMPv3, hot-reload, storage format |
| 0.3 | 2026-01-15 | Removed heartbeat, updated queue retention, status file interval |
| 0.4 | 2026-01-15 | Call-home config pattern, flexible deployment scope |
| 0.5 | 2026-01-15 | Config serial caching, agent_enabled vs maintenance_mode |
| 0.6 | 2026-01-15 | Debug mode log submission to Core for remote validation |
| 0.7 | 2026-01-15 | Complete JSON configuration schema with field specs and enums |
| 0.9 | 2026-01-15 | **AIO Guide Beta**: Consolidated all specifications into single document. Added Core API reference, data model, SNMP polling reference, metric calculations, error handling, file structures, logging, alerting, CLI reference, deployment guide, troubleshooting. |
| 0.9.2 | 2026-01-16 | **Plan Alignment**: Updated agent API endpoints from `/agent/*` to `/agent-snmp/*` for agent-type identification. Changed config parameter from `serial` to `config_serial`. Aligned with SNMP_AGENT Plan v0.2. |

---

## Appendix B: Glossary

| Term | Definition |
|------|------------|
| **BRAS** | Broadband Remote Access Server |
| **BST** | Bangladesh Standard Time (UTC+6) |
| **Core** | Central QoS monitoring system (BTRC) |
| **GETBULK** | SNMP operation to retrieve multiple OIDs efficiently |
| **Hysteresis** | Threshold buffer to prevent alert flapping |
| **IF-MIB** | Interface MIB (RFC 2863) |
| **ISP** | Internet Service Provider |
| **IX** | Internet Exchange |
| **MIB** | Management Information Base |
| **OID** | Object Identifier |
| **POP** | Point of Presence |
| **PPPoE** | Point-to-Point Protocol over Ethernet |
| **RAS** | Remote Access Server |
| **SIGHUP** | Signal to reload configuration |
| **SNMP** | Simple Network Management Protocol |
| **TLS** | Transport Layer Security |

---

## Appendix C: Quick Reference Card

### States

| State | Polls | Submits |
|-------|-------|---------|
| BOOTSTRAP | No | No |
| BLOCKED | No | No |
| DISABLED | No | No |
| MAINTENANCE | Yes | Logs only |
| ACTIVE | Yes | Yes |

### Key Files

| File | Location |
|------|----------|
| Bootstrap | /config/bootstrap.json |
| Config | /data/config/agent-config.json |
| Status | /data/agent-status.json |
| Logs | /logs/agent.log |

### Key Commands

```bash
# Status
docker exec snmp-agent snmp-agent status

# Test target
docker exec snmp-agent snmp-agent test-target t-001

# Hot-reload config
docker kill -s HUP snmp-agent

# View logs
docker logs snmp-agent --tail 100
```

### Timing

| Parameter | Default |
|-----------|---------|
| Poll Interval | 5 min |
| Submission Window | 15 min |
| Polls per Window | 3 |
| Status Update | 5 min |

---

**End of Document**
