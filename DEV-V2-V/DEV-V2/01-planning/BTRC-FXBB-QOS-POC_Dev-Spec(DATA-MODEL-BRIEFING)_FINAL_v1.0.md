# BTRC QoS Monitoring - Data Model Team Briefing

| Metadata | Value |
|----------|-------|
| **Version** | 1.0 |
| **Created** | 2026-01-12 |
| **Purpose** | Technical briefing for PM and development team |
| **Scope** | POC - 3 Data Channels (SNMP_AGENT, QOS_AGENT, ISP_API) |
| **Source Documents** | Data Ingestion Model v2.3, DB Schema Index v1.1 |

---

## Table of Contents

1. [Executive Summary](#1-executive-summary)
2. [Data Acquisition Architecture](#2-data-acquisition-architecture)
3. [Channel 1: SNMP_AGENT](#3-channel-1-snmp_agent)
4. [Channel 2: QOS_AGENT](#4-channel-2-qos_agent)
5. [Channel 3: ISP_API](#5-channel-3-isp_api)
6. [Database Schema Overview](#6-database-schema-overview)
7. [Quick Reference Tables](#7-quick-reference-tables)

---

## 1. Executive Summary

### System Purpose

The BTRC Fixed Broadband QoS Monitoring System collects, validates, and analyzes Quality of Service data from 1,500+ ISPs across Bangladesh. The system uses a **tri-source data collection** model to ensure accuracy through cross-validation.

### Three Data Channels (POC Scope)

| Channel | Source | Trust | Frequency | Primary Data |
|---------|--------|-------|-----------|--------------|
| **SNMP_AGENT** | Docker agent at ISP | 95 | 15-min | Interface metrics, subscriber counts |
| **QOS_AGENT** | Docker agent at ISP | 90 | 15-min | Speed, latency, packet loss, DNS, HTTP |
| **ISP_API** | ISP self-reported | 70 | Monthly | Packages, subscribers, PoPs, revenue |

### High-Level Data Flow

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                           DATA ACQUISITION FLOW                             │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                             │
│   ISP PREMISES                      BTRC CORE                    STORAGE    │
│   ───────────                       ─────────                    ───────    │
│                                                                             │
│   ┌──────────────┐                                                          │
│   │ SNMP_AGENT   │──┐                                                       │
│   │ (Docker)     │  │     ┌─────────────────┐    ┌──────────────────────┐   │
│   └──────────────┘  │     │                 │    │                      │   │
│                     ├────►│  BTRC Core API  │───►│  PostgreSQL 15+      │   │
│   ┌──────────────┐  │     │                 │    │  + TimescaleDB 2.x   │   │
│   │ QOS_AGENT    │──┤     │  - Validation   │    │  + Redis 7.x         │   │
│   │ (Docker)     │  │     │  - Dedup        │    │                      │   │
│   └──────────────┘  │     │  - Transform    │    │  80 tables           │   │
│                     │     └─────────────────┘    │  6 hypertables       │   │
│   ┌──────────────┐  │              │             │  4 continuous aggs   │   │
│   │ ISP Portal   │──┘              │             └──────────────────────┘   │
│   │ (API/CSV)    │                 ▼                        │               │
│   └──────────────┘         ┌───────────────┐                ▼               │
│                            │ Cross-Validate │       ┌───────────────┐       │
│                            │ Agent vs ISP   │       │  Dashboards   │       │
│                            └───────────────┘       │  Reports      │       │
│                                                     │  Alerts       │       │
│                                                     └───────────────┘       │
└─────────────────────────────────────────────────────────────────────────────┘
```

---

## 2. Data Acquisition Architecture

### Data Originators & Trust Levels

| Originator | Description | Trust Level | Dedup Window | Validation |
|------------|-------------|-------------|--------------|------------|
| **SNMP_AGENT** | SNMP Docker agent | 95 | 24 hours | Metadata only |
| **QOS_AGENT** | QoS Docker agent | 90 | 24 hours | Metadata only |
| **ISP_API** | ISP-submitted data | 70 | Monthly | Full payload + cross-check |

> **Trust Level** determines precedence when data conflicts. Higher trust = more authoritative.

### Submission Frequencies

```
TIMELINE (POC)
══════════════════════════════════════════════════════════════════════════════

SNMP_AGENT    ├──15m──├──15m──├──15m──├──15m──├   (Real-time metrics)
               ▲       ▲       ▲       ▲
               └───────┴───────┴───────┴── Combined submission every 15 min

QOS_AGENT     ├──15m──├──15m──├──15m──├──15m──├   (Active measurements)
               ▲       ▲       ▲       ▲
               └───────┴───────┴───────┴── All tests + submit every 15 min

ISP_API       ├──────────────────MONTH──────────────────├  (Self-reported)
                                                        ▲
                                                        └── By 10th of next month
```

### POC Scope Boundaries

| In Scope (POC) | Out of Scope (Future) |
|----------------|----------------------|
| SNMP interface metrics | USER_APP mobile tests |
| SNMP subscriber counts | REG_APP field reports |
| QoS speed/latency/loss tests | ISP incident data |
| ISP packages, subscribers | ISP complaint data |
| ISP PoPs + bandwidth | Detailed provider breakdowns |
| ISP revenue by Package×Location | Hardware probe data |

### Related Schema

> **See**: [Step10-IntegrationAPI](../03-data/BTRC-FXBB-QOS-POC_DB-Schema(STEP-10-INTEGRATION-API)_FINAL_v1.0.md) — `api_submissions`, `data_provenance`, `discrepancy_detection`

---

## 3. Channel 1: SNMP_AGENT

### Purpose

Collects **network infrastructure metrics** directly from ISP routers, switches, and BRAS/RAS devices via SNMP polling.

### Responsibility Separation

| Agent Responsibility | Core/Server Responsibility |
|---------------------|---------------------------|
| Poll SNMP targets every 5 min | Aggregate across time periods |
| Report raw counters and status | Detect counter wraps (32-bit rollover) |
| Submit combined data every 15 min | Calculate utilization percentages |
| Report poll failures/timeouts | Compare with ISP-reported data |
| Track agent health | Generate compliance alerts |

### Hybrid Collection Architecture

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                    SNMP_AGENT HYBRID COLLECTION MODEL                       │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                             │
│   SNMP_AGENT Container (1 per ISP)                                          │
│   ════════════════════════════════                                          │
│                                                                             │
│   ┌─────────────────────────────────────────────────────────────────────┐   │
│   │                                                                     │   │
│   │  ┌─────────────────┐  ┌─────────────────┐  ┌─────────────────┐     │   │
│   │  │ Interface Worker│  │   BRAS Worker   │  │   RAS Worker    │     │   │
│   │  │   (async)       │  │   (async)       │  │   (async)       │     │   │
│   │  │                 │  │                 │  │                 │     │   │
│   │  │ Polls: 3x/15min │  │ Polls: 1x/15min │  │ Polls: 1x/15min │     │   │
│   │  │ Timeout: 60s    │  │ Timeout: 30s    │  │ Timeout: 30s    │     │   │
│   │  │                 │  │                 │  │                 │     │   │
│   │  │ Targets:        │  │ Targets:        │  │ Targets:        │     │   │
│   │  │ - Core routers  │  │ - BRAS devices  │  │ - RAS servers   │     │   │
│   │  │ - Aggregation   │  │                 │  │ - MikroTik      │     │   │
│   │  │ - BRAS ifaces   │  │                 │  │                 │     │   │
│   │  └────────┬────────┘  └────────┬────────┘  └────────┬────────┘     │   │
│   │           │                    │                    │               │   │
│   │           └────────────────────┼────────────────────┘               │   │
│   │                                ▼                                    │   │
│   │                    ┌───────────────────────┐                        │   │
│   │                    │     AGGREGATOR        │                        │   │
│   │                    │  Combine all results  │                        │   │
│   │                    │  Handle partial data  │                        │   │
│   │                    └───────────┬───────────┘                        │   │
│   │                                │                                    │   │
│   └────────────────────────────────┼────────────────────────────────────┘   │
│                                    ▼                                        │
│                    ┌───────────────────────────────┐                        │
│                    │  POST /api/v1/submissions/    │                        │
│                    │       snmp-combined           │                        │
│                    │  (Single API call per 15 min) │                        │
│                    └───────────────────────────────┘                        │
│                                                                             │
└─────────────────────────────────────────────────────────────────────────────┘
```

### Poll Cycle Timeline

```
15-MINUTE WINDOW
════════════════════════════════════════════════════════════════════

T+0:00   Interface Poll #1  ████
T+5:00   Interface Poll #2  ████
T+10:00  Interface Poll #3  ████
T+0:00   BRAS/RAS Poll      ██  (runs parallel with interface)

T+12:00  All workers complete (or timeout)
T+12:05  Assemble combined message
T+12:10  Fetch public IP from Core API
T+14:00  Submit to BTRC API
T+15:00  Start next cycle

════════════════════════════════════════════════════════════════════
```

### Combined Submission JSON Structure

**Endpoint**: `POST /api/v1/submissions/snmp-combined`

```json
{
  "submission": {
    "submission_uuid": "550e8400-e29b-41d4-a716-446655440000",
    "originator_type": "SNMP_AGENT",
    "agent_uuid": "7c9e6679-7425-40de-944b-e07fc1f90ae7",
    "agent_version": "1.2.3",
    "isp_id": 142,
    "submission_time": "2026-01-10T10:15:00+06:00",
    "reporting_period_start": "2026-01-10T10:00:00+06:00",
    "reporting_period_end": "2026-01-10T10:15:00+06:00",
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
    "status": "ACTIVE",
    "uptime_seconds": 864000
  },
  "target_status": [
    {
      "target_id": 4521,
      "device_type": "CORE_GATEWAY",
      "target_ip": "10.0.1.1",
      "status": "HEALTHY",
      "polls_attempted": 3,
      "polls_successful": 3,
      "consecutive_failures": 0
    }
  ],
  "interface_metrics": [
    {
      "time": "2026-01-10T10:00:00+06:00",
      "poll_sequence": 1,
      "pop_id": 1523,
      "interface_type": "INTERNET",
      "upstream_operator": "AAMRA Networks",
      "snmp_target": {
        "target_id": 4521,
        "device_type": "CORE_GATEWAY",
        "vendor": "CISCO",
        "mib_profile": "STANDARD",
        "if_index": 12,
        "if_name": "GigabitEthernet0/0/1",
        "if_speed_mbps": 1000
      },
      "poll_status": "SUCCESS",
      "metrics": {
        "admin_status": "UP",
        "oper_status": "UP",
        "in_bps": 847523840,
        "out_bps": 125698560,
        "utilization_in_pct": 84.75,
        "utilization_out_pct": 12.57
      }
    }
  ],
  "subscriber_counts": [
    {
      "time": "2026-01-10T10:00:00+06:00",
      "bras_id": "BRAS-DHK-01",
      "bras_name": "Dhaka Central BRAS",
      "region": "Dhaka Division",
      "snmp_target": {
        "target_id": 4530,
        "device_type": "BRAS",
        "vendor": "HUAWEI",
        "mib_profile": "VENDOR_EXT"
      },
      "poll_status": "SUCCESS",
      "metrics": {
        "active_sessions": 48750,
        "pppoe_sessions": 46892,
        "dhcp_leases": 1858
      }
    }
  ]
}
```

### Key Field Specifications

#### Submission Header

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `submission_uuid` | UUID | Yes | Unique per submission |
| `originator_type` | STRING | Yes | Always `"SNMP_AGENT"` |
| `agent_uuid` | UUID | Yes | Registered agent ID |
| `isp_id` | INTEGER | Yes | ISP identifier |
| `poll_interval_sec` | INTEGER | Yes | 300 (5 min) |
| `polls_in_batch` | INTEGER | Yes | 3 polls per window |

#### Device Types

| Code | Description | Typical Vendor |
|------|-------------|----------------|
| `CORE_GATEWAY` | Core routers, internet gateway | Cisco, Juniper |
| `AGGREGATION_DEVICE` | Aggregation switches/routers | Cisco, Huawei |
| `BRAS` | Broadband Remote Access Server | Huawei, Cisco |
| `RAS` | Remote Access Server | MikroTik |
| `OTHER` | Other monitored devices | Various |

#### Vendor & MIB Profile

| Vendor | MIB Profile | Notes |
|--------|-------------|-------|
| `CISCO` | STANDARD | IF-MIB, standard OIDs |
| `JUNIPER` | STANDARD | IF-MIB compatible |
| `HUAWEI` | VENDOR_EXT | Enterprise MIBs for BRAS |
| `MIKROTIK` | VENDOR_EXT | Custom OIDs for sessions |
| `BDCOM` | VENDOR_EXT | Local vendor support |

#### Interface Types

| Code | Name | Direction | Purpose |
|------|------|-----------|---------|
| `INTERNET` | International Gateway | UPSTREAM | IIG providers (AAMRA, Summit) |
| `IX` | Internet Exchange | UPSTREAM | BDIX, NIX peering |
| `CACHE` | CDN/Cache Server | UPSTREAM | Google GGC, Facebook FNA |
| `DOWNSTREAM` | Subscriber Facing | DOWNSTREAM | BRAS/RAS aggregation |

> **Purpose**: Enables traffic ratio calculation (% Internet vs Cache vs IX) for regulatory analytics.

#### Interface Metrics

| Field | Type | Description |
|-------|------|-------------|
| `admin_status` | ENUM | UP / DOWN / TESTING |
| `oper_status` | ENUM | UP / DOWN / DORMANT |
| `in_bps` | BIGINT | Inbound bits per second |
| `out_bps` | BIGINT | Outbound bits per second |
| `utilization_in_pct` | DECIMAL | Inbound utilization % |
| `utilization_out_pct` | DECIMAL | Outbound utilization % |

#### Subscriber Metrics

| Field | Type | Description |
|-------|------|-------------|
| `active_sessions` | INTEGER | Total active subscribers |
| `pppoe_sessions` | INTEGER | PPPoE session count |
| `dhcp_leases` | INTEGER | DHCP lease count |
| `ipoe_sessions` | INTEGER | IPoE session count |

### Target Status Values

| Status | Condition |
|--------|-----------|
| `HEALTHY` | All polls successful |
| `DEGRADED` | Some polls failed |
| `UNREACHABLE` | All polls failed |

### DB Mapping

| API Section | Target Table | Notes |
|-------------|--------------|-------|
| `interface_metrics[]` | `ts_interface_metrics` | Hypertable, 15-min chunks |
| `subscriber_counts[]` | `ts_subscriber_counts` | Hypertable, 15-min chunks |
| `agent_status` | `software_agents` | Update status/heartbeat |
| `target_status[]` | `snmp_targets` | Update health status |

### Related Schema Files

| Schema Step | Tables | Link |
|-------------|--------|------|
| Step02-Infrastructure | `software_agents`, `snmp_targets`, `pops` | [View](../03-data/BTRC-FXBB-QOS-POC_DB-Schema(STEP-02-INFRASTRUCTURE)_FINAL_v1.0.md) |
| Step04-TimeSeries | `ts_interface_metrics`, `ts_subscriber_counts` | [View](../03-data/BTRC-FXBB-QOS-POC_DB-Schema(STEP-04-TIMESERIES)_FINAL_v1.0.md) |

---

## 4. Channel 2: QOS_AGENT

### Purpose

Performs **active QoS measurements** from the ISP's network perspective using synthetic tests (speed, latency, DNS, HTTP, traceroute).

### Responsibility Separation

| Agent Responsibility | Core/Server Responsibility |
|---------------------|---------------------------|
| Execute all test types | Apply SLA thresholds |
| Report raw metrics | Calculate Service Availability |
| Detect obvious failures | Generate compliance scores |
| Track hardware health | Correlate with SNMP data |
| Submit every 15 min | Historical trend analysis |

### Test Categories

| # | Test Type | Targets | Metrics Derived |
|---|-----------|---------|-----------------|
| 1 | **Speed Test** | 1 server (Speedtest API) | Download/Upload Mbps |
| 2 | **Ping Test** | Max 3 (NAT/IX/INTL) | RTT, Jitter, Packet Loss |
| 3 | **DNS Test** | Min 2 (.bd + international) | Resolution time, success |
| 4 | **HTTP Test** | 4-5 URLs (weighted) | Reachability score, TTFB |
| 5 | **Traceroute** | 2 (NAT + INTL) | Hop count, path completion |

### Target Type Definitions

| Type | Abbrev | Description |
|------|--------|-------------|
| `NATIONAL` | NAT | Domestic Bangladesh server |
| `IX` | IX | BDIX peering point |
| `INTERNATIONAL` | INTL | Overseas (Singapore, etc.) |
| `LOCAL_BD` | .bd | Bangladesh domain for DNS |

### Test Schedule (15-min Window)

```
15-MINUTE TEST WINDOW
════════════════════════════════════════════════════════════════════

T+0:00  ┌─────────────────────────────────────────┐
        │  SPEED TEST                             │
        │  - Download: multi-stream TCP           │  ~30-45 sec
        │  - Upload: multi-stream TCP             │
T+0:45  └─────────────────────────────────────────┘

T+0:45  ┌─────────────────────────────────────────┐
        │  PING TESTS (3 targets parallel)        │
        │  - National: 100 ICMP packets           │  ~30 sec
        │  - IX: 100 ICMP packets                 │
        │  - International: 100 ICMP packets      │
T+1:15  └─────────────────────────────────────────┘

T+1:15  ┌──────────────┐
        │  DNS TEST    │  ~5 sec
        │  - btrc.gov.bd (LOCAL_BD)              │
        │  - google.com (INTERNATIONAL)           │
T+1:20  └──────────────┘

T+1:20  ┌──────────────┐
        │  HTTP TEST   │  ~5 sec
        │  - 4-5 URLs with weights               │
        │  - Measure TTFB, total time            │
T+1:25  └──────────────┘

T+1:25  ┌─────────────────────────────────────────┐
        │  TRACEROUTE (2 targets)                 │
        │  - National destination                 │  ~15 sec
        │  - International destination            │
T+1:40  └─────────────────────────────────────────┘

T+14:00  Prepare submission
T+15:00  Submit to Core API + Start next cycle

════════════════════════════════════════════════════════════════════
```

### QoS Measurement JSON Structure

**Endpoint**: `POST /api/v1/submissions/qos-measurements`

```json
{
  "submission": {
    "submission_uuid": "770g0611-g41d-63f6-c938-668877662222",
    "originator_type": "QOS_AGENT",
    "agent_uuid": "8d0f7780-8536-51ef-055c-f18gd2g01bf8",
    "agent_version": "2.1.0",
    "isp_id": 142,
    "pop_id": 1523,
    "submission_time": "2026-01-10T10:15:00+06:00",
    "reporting_period_start": "2026-01-10T10:00:00+06:00",
    "reporting_period_end": "2026-01-10T10:15:00+06:00",
    "test_summary": {
      "speed_tests": 1,
      "ping_tests": 3,
      "dns_tests": 1,
      "http_tests": 1,
      "traceroute_tests": 1,
      "total_tests": 7,
      "successful_tests": 7,
      "failed_tests": 0
    }
  },
  "agent_status": {
    "host_ip": "192.168.20.10",
    "public_ip": "103.45.120.20",
    "hardware_id": "QOS-PROBE-DHK-001",
    "status": "ACTIVE",
    "cpu_usage_pct": 12.5,
    "memory_usage_pct": 45.2
  },
  "agent_detected_failures": {
    "has_failures": false,
    "connectivity_status": "FULL",
    "failure_count": 0,
    "failures": []
  },
  "speed_test": {
    "test_uuid": "st-001-2026011010000",
    "time": "2026-01-10T10:00:00+06:00",
    "test_status": "SUCCESS",
    "target": {
      "type": "OOKLA_API",
      "server_id": 12345,
      "server_name": "BTRC Speed Test Server"
    },
    "download": {
      "speed_mbps": 847.25,
      "bytes_transferred": 3452108800,
      "duration_ms": 15000
    },
    "upload": {
      "speed_mbps": 423.50,
      "bytes_transferred": 1726054400,
      "duration_ms": 15000
    }
  },
  "ping_tests": [
    {
      "test_uuid": "ping-001-2026011010000",
      "test_status": "SUCCESS",
      "target": {
        "type": "NATIONAL",
        "ip": "103.10.20.1",
        "name": "BTRC Reference Server"
      },
      "config": {
        "packet_count": 100,
        "packet_size_bytes": 64,
        "interval_ms": 100
      },
      "latency": {
        "rtt_min_ms": 2.1,
        "rtt_max_ms": 8.5,
        "rtt_avg_ms": 3.2,
        "rtt_p95_ms": 5.8,
        "jitter_ms": 1.4
      },
      "packet_loss": {
        "packets_sent": 100,
        "packets_received": 99,
        "loss_pct": 1.00,
        "loss_pattern": "RANDOM"
      }
    }
  ],
  "dns_test": {
    "test_uuid": "dns-001-2026011010000",
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
        "resolution_time_ms": 12.5,
        "response_code": "NOERROR",
        "success": true
      }
    ],
    "summary": {
      "total_queries": 2,
      "successful": 2,
      "avg_resolution_ms": 10.35
    }
  },
  "http_test": {
    "test_uuid": "http-001-2026011010000",
    "test_status": "SUCCESS",
    "targets": [
      {
        "url": "https://btrc.gov.bd",
        "weight": 25,
        "reachable": true,
        "status_code": 200,
        "timing": {
          "ttfb_ms": 28.6,
          "total_time_ms": 209.2
        }
      },
      {
        "url": "https://google.com",
        "weight": 25,
        "reachable": true,
        "status_code": 200,
        "timing": {
          "ttfb_ms": 85.3,
          "total_time_ms": 314.2
        }
      }
    ],
    "summary": {
      "reachability_score": {
        "score": 100,
        "max_score": 100,
        "percentage": 100.0
      },
      "response_time": {
        "weighted_avg_ms": 311.86
      }
    }
  }
}
```

### Key Field Specifications

#### Ping Test - Latency Metrics

| Field | Type | Description |
|-------|------|-------------|
| `rtt_min_ms` | DECIMAL | Minimum round-trip time |
| `rtt_max_ms` | DECIMAL | Maximum round-trip time |
| `rtt_avg_ms` | DECIMAL | Average round-trip time |
| `rtt_p95_ms` | DECIMAL | 95th percentile RTT |
| `rtt_p99_ms` | DECIMAL | 99th percentile RTT |
| `jitter_ms` | DECIMAL | Inter-packet delay variation |

#### Ping Test - Packet Loss

| Field | Type | Description |
|-------|------|-------------|
| `packets_sent` | INTEGER | Total packets transmitted |
| `packets_received` | INTEGER | Packets with response |
| `loss_pct` | DECIMAL | Loss percentage |
| `loss_pattern` | ENUM | NONE / RANDOM / BURST / PERIODIC |

#### HTTP Weighted Scoring

| Field | Type | Description |
|-------|------|-------------|
| `weight` | INTEGER | URL weight (1-100, total=100) |
| `reachable` | BOOLEAN | HTTP 2xx/3xx received |
| `reachability_score.score` | DECIMAL | Sum of weights for reachable URLs |

### Service Availability Calculation (Core-Side)

The Core calculates Service Availability from QoS Agent submissions using a **two-tier model**:

```
┌─────────────────────────────────────────────────────────────────────────────┐
│              SERVICE AVAILABILITY CALCULATION (CORE)                        │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                             │
│   TIER 1: CONNECTIVITY CHECK (Binary)                                       │
│   ════════════════════════════════════                                      │
│                                                                             │
│   ┌─────────────────────────────────────────────────────────────────────┐   │
│   │  IF any condition TRUE → OUTAGE (score = 0.0)                       │   │
│   │                                                                     │   │
│   │  • No submission received for 15-min slot                           │   │
│   │  • agent_detected_failures.connectivity_status = NONE               │   │
│   │  • test_summary.successful_tests = 0                                │   │
│   │                                                                     │   │
│   │  ELSE → Proceed to Tier 2                                           │   │
│   └─────────────────────────────────────────────────────────────────────┘   │
│                              │                                              │
│                              ▼                                              │
│   TIER 2: QoS QUALITY SCORING (Weighted)                                    │
│   ═══════════════════════════════════════                                   │
│                                                                             │
│   ┌───────────────────────────┬──────────┬────────────────────────────┐     │
│   │ Metric                    │ Weight   │ Pass Condition             │     │
│   ├───────────────────────────┼──────────┼────────────────────────────┤     │
│   │ Speed Ratio               │   25%    │ ≥ 80% of advertised        │     │
│   │ Latency (National)        │   15%    │ ≤ 100 ms                   │     │
│   │ Latency (International)   │   10%    │ ≤ 300 ms                   │     │
│   │ Packet Loss               │   20%    │ ≤ 2%                       │     │
│   │ DNS Resolution            │   10%    │ ≤ 500 ms                   │     │
│   │ HTTP Reachability         │   15%    │ ≥ 80%                      │     │
│   │ Jitter                    │    5%    │ ≤ 30 ms                    │     │
│   └───────────────────────────┴──────────┴────────────────────────────┘     │
│                                                                             │
│   QoS Score = Σ (metric_weight × pass/fail)                                 │
│                                                                             │
│   INTERVAL STATUS MAPPING                                                   │
│   ═══════════════════════                                                   │
│                                                                             │
│   ┌─────────────────┬──────────────┬────────────────────────────────┐       │
│   │ QoS Score Range │ Status       │ Interval Value                 │       │
│   ├─────────────────┼──────────────┼────────────────────────────────┤       │
│   │ (Tier 1 fail)   │ OUTAGE       │ 0.00                           │       │
│   │ 0% - 49%        │ POOR         │ 0.25                           │       │
│   │ 50% - 79%       │ DEGRADED     │ 0.50                           │       │
│   │ 80% - 100%      │ AVAILABLE    │ 1.00                           │       │
│   └─────────────────┴──────────────┴────────────────────────────────┘       │
│                                                                             │
│   FORMULA:                                                                  │
│   ════════                                                                  │
│                        Σ (interval_value)                                   │
│   Availability % = ─────────────────────── × 100                            │
│                        total_intervals                                      │
│                                                                             │
│   Example (24 hours = 96 intervals):                                        │
│   • 80 AVAILABLE (×1.0) = 80.0                                              │
│   • 10 DEGRADED  (×0.5) =  5.0                                              │
│   •  4 POOR      (×0.25) = 1.0                                              │
│   •  2 OUTAGE    (×0.0) =  0.0                                              │
│   • Total: 86.0 / 96 = 89.6% Availability                                   │
│                                                                             │
└─────────────────────────────────────────────────────────────────────────────┘
```

### DB Mapping

| API Section | Target Table | Notes |
|-------------|--------------|-------|
| All test data | `ts_qos_measurements` | Hypertable, stores all test types |
| Calculated availability | `compliance_scores` | Monthly rollup |
| Threshold breaches | `sla_violations` | Per-incident tracking |

### Related Schema Files

| Schema Step | Tables | Link |
|-------------|--------|------|
| Step02-Infrastructure | `software_agents`, `test_targets` | [View](../03-data/BTRC-FXBB-QOS-POC_DB-Schema(STEP-02-INFRASTRUCTURE)_FINAL_v1.0.md) |
| Step04-TimeSeries | `ts_qos_measurements`, continuous aggregates | [View](../03-data/BTRC-FXBB-QOS-POC_DB-Schema(STEP-04-TIMESERIES)_FINAL_v1.0.md) |
| Step08-ComplianceSLA | `qos_parameters`, `sla_thresholds`, `sla_violations` | [View](../03-data/BTRC-FXBB-QOS-POC_DB-Schema(STEP-08-COMPLIANCE-SLA)_FINAL_v1.0.md) |

---

## 5. Channel 3: ISP_API

### Purpose

Receives **self-reported operational data** from ISPs via authenticated API endpoints. Data is cross-validated against agent-collected metrics.

### Trust Level & Validation

| Aspect | Value |
|--------|-------|
| Trust Level | 70 (lowest of 3 channels) |
| Authentication | OAuth 2.0 + API Key |
| Submission Methods | REST API, Bulk CSV, Web Portal |
| Frequency | Monthly (by 10th of following month) |
| Cross-Validation | Compare with SNMP_AGENT data |

### POC Data Categories

| Category | Endpoint | Description |
|----------|----------|-------------|
| **3.1 Packages** | `POST /api/v1/isp/{isp_id}/packages` | Broadband package definitions |
| **3.2 Subscribers** | `POST /api/v1/isp/{isp_id}/subscribers` | Subscriber counts by Package×Location |
| **3.4 PoPs + Bandwidth** | `POST /api/v1/isp/{isp_id}/pops` | Infrastructure + bandwidth capacity |
| **3.7 Revenue** | `POST /api/v1/isp/{isp_id}/revenue` | Revenue by Package×Location |

> **Out of Scope (POC)**: Incident data (3.5), Complaint data (3.6)

---

### 3.1 Package Definitions

**Endpoint**: `POST /api/v1/isp/{isp_id}/packages`

```json
{
  "period": "2026-01",
  "packages": [
    {
      "package_code": "PKG-HOME-100",
      "package_name": "Home Fiber 100",
      "download_speed_mbps": 100,
      "upload_speed_mbps": 50,
      "mir_mbps": 100,
      "cir_mbps": 50,
      "price_bdt": 1200.00,
      "data_cap_gb": null,
      "has_fup": true,
      "fup_threshold_gb": 500,
      "fup_speed_mbps": 10,
      "contract_months": 12,
      "installation_fee_bdt": 0,
      "status": "active"
    }
  ]
}
```

#### Field Specifications

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `package_code` | STRING | Yes | ISP's internal package ID |
| `package_name` | STRING | Yes | Display name |
| `download_speed_mbps` | INTEGER | Yes | Advertised download |
| `upload_speed_mbps` | INTEGER | Yes | Advertised upload |
| `mir_mbps` | INTEGER | Yes | Maximum Information Rate |
| `cir_mbps` | INTEGER | Yes | Committed Information Rate |
| `price_bdt` | DECIMAL | Yes | Monthly price (BDT) |
| `data_cap_gb` | INTEGER | No | Data cap (null = unlimited) |
| `has_fup` | BOOLEAN | Yes | Fair Usage Policy applies? |
| `fup_threshold_gb` | INTEGER | No | FUP trigger threshold |
| `fup_speed_mbps` | INTEGER | No | Speed after FUP |
| `status` | ENUM | Yes | `active` / `discontinued` |

#### DB Mapping

| API Field | DB Column | Logic |
|-----------|-----------|-------|
| `status` | `packages.is_active` | `active` → `true` |
| `package_code` | `packages.code` | Unique per ISP |

---

### 3.2 Subscriber Data

**Endpoint**: `POST /api/v1/isp/{isp_id}/subscribers`

```json
{
  "period": "2026-01",
  "subscribers": [
    {
      "package_code": "PKG-HOME-100",
      "location": {
        "bbs_code": "302614"
      },
      "current_count": 3250,
      "new_count": 120,
      "churned_count": 45
    },
    {
      "package_code": "PKG-HOME-100",
      "location": {
        "bbs_code": null,
        "division": "Dhaka",
        "district": "Dhaka",
        "upazila": "Banani"
      },
      "current_count": 2100,
      "new_count": 85,
      "churned_count": 32
    }
  ]
}
```

#### Field Specifications

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `package_code` | STRING | Yes | Reference to Package |
| `location` | OBJECT | Yes | Location (see below) |
| `current_count` | INTEGER | Yes | Active subscribers (snapshot) |
| `new_count` | INTEGER | Yes | New this month |
| `churned_count` | INTEGER | Yes | Removed this month |

#### Cross-Validation

| ISP Claim | Agent Data | Variance Threshold |
|-----------|------------|-------------------|
| `current_count` (monthly) | SUM(`active_sessions`) from BRAS | >10% triggers alert |

---

### 3.4 PoP + Bandwidth Data

**Endpoint**: `POST /api/v1/isp/{isp_id}/pops`

```json
{
  "period": "2026-01",
  "pops": [
    {
      "location": {
        "bbs_code": "302614"
      },
      "pop_count": 3,
      "pop_type": "distribution",
      "status": "active",
      "upstream_capacity_mbps": 10000,
      "bandwidth": {
        "international_mbps": 5000,
        "ix_mbps": 3000,
        "cache_mbps": 2000
      }
    }
  ]
}
```

#### Field Specifications

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `location` | OBJECT | Yes | Location reference |
| `pop_count` | INTEGER | Yes | Number of PoPs at location |
| `pop_type` | ENUM | Yes | `core` / `distribution` / `access` |
| `status` | ENUM | Yes | `active` / `inactive` |
| `upstream_capacity_mbps` | INTEGER | Yes | Total upstream capacity |
| `bandwidth.international_mbps` | INTEGER | Yes | IIG bandwidth |
| `bandwidth.ix_mbps` | INTEGER | Yes | BDIX/NIX bandwidth |
| `bandwidth.cache_mbps` | INTEGER | Yes | CDN/Cache bandwidth |

#### PoP Type Definitions

| Type | Description | Direct Subscribers? |
|------|-------------|---------------------|
| `core` | Central/backbone PoP | No |
| `distribution` | Regional aggregation | Sometimes |
| `access` | Last-mile, subscriber-facing | Yes |

#### DB Mapping

| API Field | DB Table/Column | Logic |
|-----------|-----------------|-------|
| `pop_count` | `pops` (individual records) | Expand: create N records |
| `pop_type` | `pops.category_id` | Map: `core`→`CORE_DC` |
| `bandwidth.*` | `bandwidth_snapshots` | Separate table with FK |

---

### 3.7 Revenue Data

**Endpoint**: `POST /api/v1/isp/{isp_id}/revenue`

```json
{
  "period": "2026-01",
  "revenue": [
    {
      "package_code": "PKG-HOME-100",
      "location": {
        "bbs_code": "302614"
      },
      "subscriber_revenue_bdt": 3900000.00,
      "vat_bdt": 585000.00,
      "subscriber_count": 3250
    }
  ]
}
```

#### Field Specifications

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `package_code` | STRING | Yes | Reference to Package |
| `location` | OBJECT | Yes | Location reference |
| `subscriber_revenue_bdt` | DECIMAL | Yes | Net revenue (BDT) |
| `vat_bdt` | DECIMAL | Yes | VAT collected |
| `subscriber_count` | INTEGER | Yes | Subscribers for verification |

#### Revenue Verification Rule

```
Expected = subscriber_count × package_price
Actual   = subscriber_revenue_bdt

Variance = |Expected - Actual| / Expected × 100

IF variance > 10% → Flag for review
```

---

### Location Object Specification (All ISP APIs)

ISP can specify location using **BBS code** (preferred) OR **text fields**:

```json
// Option 1: BBS Code (preferred)
{
  "bbs_code": "302614"
}

// Option 2: Text fields (system maps to BBS code)
{
  "bbs_code": null,
  "division": "Dhaka",
  "district": "Dhaka",
  "upazila": "Savar"
}
```

#### BBS Code Format

| Level | Digits | Example | Description |
|-------|--------|---------|-------------|
| Division | 2 | `30` | Dhaka Division |
| District | 4 | `3026` | Dhaka District |
| Upazila | 6 | `302614` | Savar Upazila |
| Thana | 8 | `30261401` | Specific Thana |

#### Validation Rules

1. If `bbs_code` provided and valid → Use directly
2. If `bbs_code` null → Text fields required
3. System maps text → BBS code via geo reference tables
4. No match → Submission rejected with valid options

### Related Schema Files

| Schema Step | Tables | Link |
|-------------|--------|------|
| Step01-Foundation | `isps`, `geo_divisions`, `geo_districts`, `geo_upazilas` | [View](../03-data/BTRC-FXBB-QOS-POC_DB-Schema(STEP-01-FOUNDATION)_FINAL_v1.0.md) |
| Step02-Infrastructure | `pops` | [View](../03-data/BTRC-FXBB-QOS-POC_DB-Schema(STEP-02-INFRASTRUCTURE)_FINAL_v1.0.md) |
| Step03-ProductSubscriber | `packages`, `subscriber_snapshots`, `bandwidth_snapshots` | [View](../03-data/BTRC-FXBB-QOS-POC_DB-Schema(STEP-03-PRODUCT-SUBSCRIBER)_FINAL_v1.0.md) |
| Step07-RevenueAnalytics | `revenue_snapshots`, `revenue_details` | [View](../03-data/BTRC-FXBB-QOS-POC_DB-Schema(STEP-07-REVENUE-ANALYTICS)_FINAL_v1.0.md) |

---

## 6. Database Schema Overview

### 12-Step Schema Summary

| Step | File | Tables | Key Contents |
|------|------|--------|--------------|
| 1 | [Foundation](../03-data/BTRC-FXBB-QOS-POC_DB-Schema(STEP-01-FOUNDATION)_FINAL_v1.0.md) | 9 | `isps`, `geo_*`, `license_categories` |
| 2 | [Infrastructure](../03-data/BTRC-FXBB-QOS-POC_DB-Schema(STEP-02-INFRASTRUCTURE)_FINAL_v1.0.md) | 10 | `pops`, `software_agents`, `snmp_targets` |
| 3 | [ProductSubscriber](../03-data/BTRC-FXBB-QOS-POC_DB-Schema(STEP-03-PRODUCT-SUBSCRIBER)_FINAL_v1.0.md) | 7 | `packages`, `subscriber_snapshots` |
| 4 | [TimeSeries](../03-data/BTRC-FXBB-QOS-POC_DB-Schema(STEP-04-TIMESERIES)_FINAL_v1.0.md) | 3+CA | `ts_interface_metrics`, `ts_qos_measurements` |
| 5 | [MobileApp](../03-data/BTRC-FXBB-QOS-POC_DB-Schema(STEP-05-MOBILE-APP)_FINAL_v1.0.md) | 8 | `ts_mobile_speed_tests` (future) |
| 6 | [Operational](../03-data/BTRC-FXBB-QOS-POC_DB-Schema(STEP-06-OPERATIONAL)_FINAL_v1.0.md) | 7 | `incidents`, `outages` |
| 7 | [RevenueAnalytics](../03-data/BTRC-FXBB-QOS-POC_DB-Schema(STEP-07-REVENUE-ANALYTICS)_FINAL_v1.0.md) | 4 | `revenue_snapshots`, `revenue_details` |
| 8 | [ComplianceSLA](../03-data/BTRC-FXBB-QOS-POC_DB-Schema(STEP-08-COMPLIANCE-SLA)_FINAL_v1.0.md) | 5 | `qos_parameters`, `sla_violations` |
| 9 | [UserSecurity](../03-data/BTRC-FXBB-QOS-POC_DB-Schema(STEP-09-USER-SECURITY)_FINAL_v1.0.md) | 8 | `users`, `audit_logs`, `api_keys` |
| 10 | [IntegrationAPI](../03-data/BTRC-FXBB-QOS-POC_DB-Schema(STEP-10-INTEGRATION-API)_FINAL_v1.0.md) | 9 | `api_submissions`, `data_provenance` |
| 11 | [SystemObservability](../03-data/BTRC-FXBB-QOS-POC_DB-Schema(STEP-11-SYSTEM-OBSERVABILITY)_FINAL_v1.0.md) | 10 | `alerts`, `system_health` |
| 12 | [SchemaOptimization](../03-data/BTRC-FXBB-QOS-POC_DB-Schema(STEP-12-SCHEMA-OPTIMIZATION)_FINAL_v1.0.md) | ~146 idx | Indexes, partitioning |

### Table Counts

| Category | Regular Tables | Hypertables | Continuous Aggregates |
|----------|----------------|-------------|----------------------|
| Foundation | 9 | 0 | 0 |
| Infrastructure | 10 | 0 | 0 |
| Product/Subscriber | 7 | 0 | 0 |
| Time-Series | 3 | **3** | **4** |
| Mobile App | 8 | 2 | 0 |
| Operational | 7 | 0 | 0 |
| Revenue/Analytics | 4 | 0 | 0 |
| Compliance/SLA | 5 | 0 | 0 |
| User/Security | 8 | 0 | 0 |
| Integration/API | 9 | 0 | 0 |
| System/Observability | 10 | 1 | 0 |
| **TOTAL** | **80** | **6** | **4** |

### Key Tables Per Channel

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                     KEY TABLES BY DATA CHANNEL                              │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                             │
│  SNMP_AGENT                                                                 │
│  ───────────                                                                │
│  ├── software_agents        (agent registration, health)                    │
│  ├── snmp_targets           (devices being polled)                          │
│  ├── ts_interface_metrics   ★ HYPERTABLE (interface counters)               │
│  └── ts_subscriber_counts   ★ HYPERTABLE (BRAS session counts)              │
│                                                                             │
│  QOS_AGENT                                                                  │
│  ──────────                                                                 │
│  ├── software_agents        (agent registration, health)                    │
│  ├── test_targets           (reference servers)                             │
│  ├── ts_qos_measurements    ★ HYPERTABLE (all QoS test results)             │
│  ├── qos_parameters         (threshold definitions)                         │
│  ├── sla_thresholds         (per-ISP SLA config)                            │
│  └── sla_violations         (breach records)                                │
│                                                                             │
│  ISP_API                                                                    │
│  ────────                                                                   │
│  ├── isps                   (ISP master records)                            │
│  ├── packages               (broadband package definitions)                 │
│  ├── pops                   (Points of Presence)                            │
│  ├── subscriber_snapshots   (monthly subscriber counts)                     │
│  ├── bandwidth_snapshots    (monthly bandwidth data)                        │
│  ├── revenue_snapshots      (ISP-level monthly revenue)                     │
│  ├── revenue_details        (Package×Location revenue)                      │
│                                                                             │
│  CROSS-CHANNEL                                                              │
│  ─────────────                                                              │
│  ├── geo_divisions          (8 divisions)                                   │
│  ├── geo_districts          (64 districts)                                  │
│  ├── geo_upazilas           (~500 upazilas)                                 │
│                                                                             │
│  ★ = TimescaleDB Hypertable (optimized time-series storage)                 │
│                                                                             │
└─────────────────────────────────────────────────────────────────────────────┘
```


### Simplified ERD - Key Relationships

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                    KEY TABLE RELATIONSHIPS (Simplified)                     │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                             │
│                           ┌──────────────┐                                  │
│                           │     isps     │                                  │
│                           │──────────────│                                  │
│                           │ id (PK)      │                                  │
│                           │ name         │                                  │
│                           │ license_id   │───┐                              │
│                           └──────┬───────┘   │                              │
│                                  │           │                              │
│          ┌───────────────────────┼───────────┼────────────────┐             │
│          │                       │           │                │             │
│          ▼                       ▼           ▼                ▼             │
│  ┌───────────────┐    ┌──────────────┐  ┌─────────┐   ┌─────────────────┐   │
│  │ software_     │    │   packages   │  │  pops   │   │ subscriber_     │   │
│  │ agents        │    │──────────────│  │─────────│   │ snapshots       │   │
│  │───────────────│    │ id (PK)      │  │ id (PK) │   │─────────────────│   │
│  │ id (PK)       │    │ isp_id (FK)  │  │ isp_id  │   │ isp_id (FK)     │   │
│  │ isp_id (FK)   │    │ code         │  │ district│   │ package_id (FK) │   │
│  │ agent_type    │    │ mir_mbps     │  │ status  │   │ district_id     │   │
│  │ pop_id (FK)   │    │ cir_mbps     │  └────┬────┘   │ current_count   │   │
│  └───────┬───────┘    └──────────────┘       │        └─────────────────┘   │
│          │                                   │                              │
│          │            ┌──────────────────────┘                              │
│          │            │                                                     │
│          ▼            ▼                                                     │
│  ┌───────────────────────────┐      ┌─────────────────────────────────┐    │
│  │     snmp_targets          │      │     bandwidth_snapshots         │    │
│  │───────────────────────────│      │─────────────────────────────────│    │
│  │ id (PK)                   │      │ id (PK)                         │    │
│  │ agent_id (FK)             │      │ pop_id (FK)                     │    │
│  │ pop_id (FK)               │      │ snapshot_month                  │    │
│  │ device_type               │      │ international_mbps              │    │
│  │ vendor                    │      │ ix_mbps                         │    │
│  └───────────┬───────────────┘      │ cache_mbps                      │    │
│              │                      └─────────────────────────────────┘    │
│              │                                                              │
│              ▼                                                              │
│  ╔═══════════════════════════════════════════════════════════════════════╗  │
│  ║              TIMESCALEDB HYPERTABLES (Time-Series)                    ║  │
│  ╠═══════════════════════════════════════════════════════════════════════╣  │
│  ║                                                                       ║  │
│  ║  ┌─────────────────────────┐  ┌─────────────────────────────────┐    ║  │
│  ║  │ ts_interface_metrics    │  │ ts_qos_measurements             │    ║  │
│  ║  │─────────────────────────│  │─────────────────────────────────│    ║  │
│  ║  │ time (PK, partitioned)  │  │ time (PK, partitioned)          │    ║  │
│  ║  │ isp_id                  │  │ isp_id                          │    ║  │
│  ║  │ pop_id                  │  │ pop_id                          │    ║  │
│  ║  │ snmp_target_id (FK)     │  │ test_type                       │    ║  │
│  ║  │ interface_type          │  │ download_mbps                   │    ║  │
│  ║  │ in_bps, out_bps         │  │ upload_mbps                     │    ║  │
│  ║  │ utilization_%           │  │ latency_ms, jitter_ms           │    ║  │
│  ║  └─────────────────────────┘  │ packet_loss_pct                 │    ║  │
│  ║                               └─────────────────────────────────┘    ║  │
│  ║                                                                       ║  │
│  ║  ┌─────────────────────────┐                                         ║  │
│  ║  │ ts_subscriber_counts    │                                         ║  │
│  ║  │─────────────────────────│                                         ║  │
│  ║  │ time (PK, partitioned)  │                                         ║  │
│  ║  │ isp_id                  │                                         ║  │
│  ║  │ bras_id                 │                                         ║  │
│  ║  │ active_sessions         │                                         ║  │
│  ║  │ pppoe_sessions          │                                         ║  │
│  ║  └─────────────────────────┘                                         ║  │
│  ║                                                                       ║  │
│  ╚═══════════════════════════════════════════════════════════════════════╝  │
│                                                                             │
└─────────────────────────────────────────────────────────────────────────────┘
```

---

## 7. Quick Reference Tables

### Timing Parameters (All Channels)

| Parameter | SNMP_AGENT | QOS_AGENT | ISP_API |
|-----------|------------|-----------|---------|
| Poll Interval | 5 min | N/A | N/A |
| Submission Interval | 15 min | 15 min | Monthly |
| Polls per Submission | 3 | 1 | 1 |
| Dedup Window | 24 hours | 24 hours | Monthly |
| Heartbeat | 1 min | 1 min | N/A |

### Agent Status Values

| Status | Description |
|--------|-------------|
| `ACTIVE` | Operating normally |
| `INACTIVE` | Registered but not sending data |
| `ERROR` | Experiencing issues |

### Target/Device Status Values

| Status | Condition |
|--------|-----------|
| `HEALTHY` | All polls/tests successful |
| `DEGRADED` | Some failures (partial success) |
| `UNREACHABLE` | All polls/tests failed |

### Poll/Test Status Values

| Status | Description |
|--------|-------------|
| `SUCCESS` | Completed, metrics available |
| `TIMEOUT` | No response within threshold |
| `ERROR` | Failed (auth, network, etc.) |

### Interface Types (SNMP_AGENT)

| Code | Direction | Examples |
|------|-----------|----------|
| `INTERNET` | UPSTREAM | AAMRA, Summit, Novocom |
| `IX` | UPSTREAM | BDIX, NIX |
| `CACHE` | UPSTREAM | Google GGC, Facebook FNA |
| `DOWNSTREAM` | DOWNSTREAM | Subscriber aggregation |

### Device Types (SNMP_AGENT)

| Code | Description |
|------|-------------|
| `CORE_GATEWAY` | Core routers, gateway |
| `AGGREGATION_DEVICE` | Aggregation layer |
| `BRAS` | Broadband Remote Access |
| `RAS` | Remote Access Server |
| `OTHER` | Other monitored devices |

### Vendor Codes

| Code | Description |
|------|-------------|
| `CISCO` | Cisco Systems |
| `JUNIPER` | Juniper Networks |
| `HUAWEI` | Huawei Technologies |
| `MIKROTIK` | MikroTik |
| `BDCOM` | BDCOM Networks |
| `OTHER` | Other vendors |

### MIB Profiles

| Code | Description |
|------|-------------|
| `STANDARD` | IF-MIB, standard OIDs |
| `VENDOR_EXT` | Vendor-specific MIB extensions |

### SNMP Error Codes

| Code | Description |
|------|-------------|
| `SNMP_TIMEOUT` | Request timed out |
| `SNMP_NO_RESPONSE` | No response from device |
| `SNMP_AUTH_FAILURE` | Community string failed |
| `SNMP_NO_SUCH_OID` | OID not found |
| `NETWORK_UNREACHABLE` | Cannot reach target |

### DNS Response Codes

| Code | Description |
|------|-------------|
| `NOERROR` | Successful resolution |
| `NXDOMAIN` | Domain does not exist |
| `SERVFAIL` | Server failure |
| `REFUSED` | Query refused |
| `TIMEOUT` | No response |

### Packet Loss Patterns

| Pattern | Description |
|---------|-------------|
| `NONE` | No packet loss |
| `RANDOM` | Random sporadic loss |
| `BURST` | Consecutive packet loss |
| `PERIODIC` | Regular interval loss |

### Service Availability Status

| Status | QoS Score | Interval Value |
|--------|-----------|----------------|
| `OUTAGE` | N/A (connectivity fail) | 0.00 |
| `POOR` | 0-49% | 0.25 |
| `DEGRADED` | 50-79% | 0.50 |
| `AVAILABLE` | 80-100% | 1.00 |

### PoP Types (ISP_API)

| Type | DB Mapping | Description |
|------|------------|-------------|
| `core` | `CORE_DC` | Backbone, no subscribers |
| `distribution` | `REGIONAL_POP` | Regional aggregation |
| `access` | `EDGE_POP` | Last-mile, subscriber-facing |

### Package Status (ISP_API)

| API Value | DB Column | Value |
|-----------|-----------|-------|
| `active` | `is_active` | `true` |
| `discontinued` | `is_active` | `false` |

---
