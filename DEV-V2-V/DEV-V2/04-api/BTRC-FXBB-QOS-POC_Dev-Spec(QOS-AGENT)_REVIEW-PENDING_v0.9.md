# QOS_AGENT Application - All-In-One Developer Guide (Review-Pending)

| Metadata | Value |
|----------|-------|
| **Document** | QOS_AGENT All-In-One Developer Guide |
| **Version** | 0.9.2 (Plan-Aligned) |
| **Status** | REVIEW-PENDING |
| **Created** | 2026-01-16 |
| **Updated** | 2026-01-16 |
| **Author** | Technometrics |
| **Project** | BTRC Fixed Broadband QoS Monitoring System |
| **Alignment** | Validated against PRD v3.1, Data-Model v2.3, DB-Schema v1.1 |

---

## Document Purpose

This is the **comprehensive developer reference** for the QOS_AGENT application component of the BTRC QoS Monitoring System. It consolidates all specifications into a single document:

| Audience | Sections |
|----------|----------|
| **Project Managers** | 1-3 (Overview, Features) |
| **Product Designers** | 4-5 (Features, Architecture) |
| **Developers** | 6-21 (All technical sections) |
| **DevOps/QA** | 28-38 (Files, Logging, Deployment, Troubleshooting) |

## Related Documents

| Document | Description |
|----------|-------------|
| [Data-Model(INGESTION)](../01-planning/BTRC-FXBB-QOS-POC_Data-Model(INGESTION)_DRAFT_v0.8.md) | Data model and API specifications |
| [Dev-Spec(SNMP-AGENT)](BTRC-FXBB-QOS-POC_Dev-Spec(SNMP-AGENT)_REVIEW-PENDING_v0.9.md) | SNMP_AGENT reference (sibling agent) |
| 01-PROJECT-BRIEF.md | Overall project scope and requirements |

---

# PART I: OVERVIEW & FEATURES

---

## 1. Executive Summary

The QOS_AGENT is a containerized software application that performs **active QoS testing** from ISP network locations to measure broadband service quality. Unlike SNMP_AGENT (passive collection), QOS_AGENT actively generates test traffic.

### Key Characteristics

| Aspect | Description |
|--------|-------------|
| **Deployment** | Standalone Docker/Podman container on ISP infrastructure |
| **Scope** | One agent per ISP OR per PoP (configurable) |
| **Configuration** | Call-home pattern with centralized config from Core |
| **Test Types** | Speed, Ping, DNS, HTTP, Traceroute |
| **Interval** | 15 minutes per ToR Section 3.8 |
| **Threshold Eval** | Agent-side (thresholds from Core config) |
| **Liveness** | Tracked via submissions (no separate heartbeat) |

**Total Features**: ~78 across 13 categories

---

## 2. Feature Summary by Category

| Category | Features | Description |
|----------|----------|-------------|
| A. Deployment & Container | 7 | Container runtime, volumes, lifecycle |
| C. Test Execution Engine | 10 | Test orchestration, sequencing, timing |
| D. Speed Test | 6 | Download/upload measurement |
| E. Ping Test | 6 | Latency, jitter, packet loss |
| F. DNS Test | 5 | Resolution time measurement |
| G. HTTP Test | 6 | Reachability, response time |
| H. Traceroute Test | 4 | Path discovery, hop analysis |
| I. Threshold & Status Flags | 6 | Per-test evaluation |
| J. Local Storage | 5 | Results persistence, queue |
| K. Core Communication | 6 | Submission, resilience |
| **TOTAL** | **78** | |

---

## 3. Complete Feature List

### A. Deployment & Container (7 features)

| # | Feature | Description |
|---|---------|-------------|
| A1 | Standalone container | Docker/Podman only. No orchestration (Swarm/K8s). |
| A2 | Flexible deployment scope | One agent per ISP OR per PoP (defined in Core config). |
| A3 | Volume mounts | /config (bootstrap), /data (storage+cache), /logs |
| A4 | Graceful shutdown | Handle SIGTERM/SIGINT, complete in-flight tests, flush queues. |
| A5 | Resource limits | Document recommended CPU/memory limits for sizing. |
| A6 | Restart policy | Recommend on-failure with max retries. |
| A7 | Environment variables | Support ENV for secrets (API key). Fallback to bootstrap file. |

### C. Test Execution Engine (10 features)

| # | Feature | Description |
|---|---------|-------------|
| C1 | Test orchestration | Coordinate all test types within 15-min window. |
| C2 | Sequential execution | Run tests in defined order: Speed → Ping → DNS → HTTP → Traceroute. |
| C3 | Test timeout handling | Per-test timeouts with graceful failure capture. |
| C4 | Partial results | Submit available results even if some tests fail. |
| C5 | Test scheduling | Align test cycles to 15-min boundaries (T+00, T+15, T+30, T+45). |
| C6 | Window management | Track reporting_period_start and reporting_period_end. |
| C7 | Retry on transient failure | Configurable retry count for transient test failures. |
| C8 | Test isolation | Each test runs independently; one failure doesn't block others.  |
| C9 | Resource throttling | Limit concurrent network usage during tests. Avoid parallel tests. |

### D. Speed Test (6 features)

| # | Feature | Description |
|---|---------|-------------|
| D1 | Single method configuration | One speed test method per agent (We will use Ookla, or prebuilt open source modules available). |
| D2 | Download measurement | Measure downstream throughput in Mbps. |
| D3 | Upload measurement | Measure upstream throughput in Mbps. |
| D4 | Multi-stream TCP | Support parallel TCP streams for accurate measurement. |
| D5 | Server latency capture | Record latency to speed test server. |
| D6 | Bytes transferred tracking | Log total bytes for validation. |

### E. Ping Test (6 features)

| # | Feature | Description |
|---|---------|-------------|
| E1 | Multi-target ping | Support up to 3 targets (NAT/IX/INTL). |
| E2 | 100-packet sample | Send 100 ICMP packets per target for statistical validity. |
| E3 | RTT statistics | Calculate min/max/avg/median/p95/p99 RTT. |
| E4 | Jitter calculation | Derive jitter from RTT standard deviation. |
| E5 | Packet loss tracking | Count lost packets, calculate loss percentage. |
| E6 | Loss pattern detection | Identify NONE/RANDOM/BURST/PERIODIC patterns. |

### F. DNS Test (5 features)

| # | Feature | Description |
|---|---------|-------------|
| F1 | Multi-domain queries | Test minimum 2 domains (.bd + international). |
| F2 | Resolution time | Measure DNS query response time in ms. |
| F3 | Response code capture | Record NOERROR/NXDOMAIN/SERVFAIL/REFUSED/TIMEOUT. |
| F4 | DNS server selection | Use ISP DNS or configured public DNS. |
| F5 | Resolved IP logging | Capture resolved IP addresses for validation. |

### G. HTTP Test (6 features)

| # | Feature | Description |
|---|---------|-------------|
| G1 | Weighted URL testing | Test 4-5 URLs with configurable weights (total=100). |
| G2 | Reachability scoring | Calculate weighted reachability score (0-100). |
| G3 | Timing breakdown | Capture DNS, TCP, SSL, TTFB, download times. |
| G4 | Status code capture | Record HTTP response status codes. |
| G5 | Protocol detection | Log HTTP/1.1 vs HTTP/2 protocol used. |
| G6 | Weighted response time | Calculate weighted average response time. |

### H. Traceroute Test (4 features)

| # | Feature | Description |
|---|---------|-------------|
| H1 | Dual-target traceroute | Test to NAT and INTL targets. |
| H2 | Hop discovery | Record each hop's IP, hostname, RTT. |
| H3 | Path completion | Detect if destination was reached. |
| H4 | Hop count tracking | Report total hops to destination. |

### I. Failure Detection & Status Flags (6 features)

> **ALIGNMENT NOTE**: We need to discuss further during development and figure out what flags to raise and how to handle them.

| # | Feature | Description |
|---|---------|-------------|
| I1 | Failure detection only | Detect obvious failures (timeout, connection refused, complete loss). |
| I2 | No agent-side threshold eval | Raw metrics sent to Core; Core applies configurable thresholds. |
| I3 | Failure flags per test | Set SUCCESS/FAILED status for each test (not PASS/DEGRADED/FAIL). |
| I4 | Connectivity status | Report FULL/PARTIAL/NONE connectivity status. |
| I5 | Failures list | Include list of detected failures with error codes. |
| I6 | Agent health in submission | Include agent resource usage (CPU, memory, disk) in submission. |

### J. Local Storage (5 features)

| # | Feature | Description |
|---|---------|-------------|
| J1 | Test results cache | Store test results locally before submission. |
| J2 | Submission queue | Queue submissions when Core unreachable. |
| J3 | Queue persistence | Persist queue to disk for crash recovery. |
| J4 | Queue management | FIFO processing with configurable max depth. |
| J5 | Disk space monitoring | Alert when storage threshold exceeded. |

### K. Core Communication (6 features)

| # | Feature | Description |
|---|---------|-------------|
| K1 | Combined submission | Submit all test results in single API call. |
| K2 | Store-and-forward | Queue locally when Core unreachable, retry later. |
| K3 | Retry with backoff | Exponential backoff on submission failure. |
| K4 | API key authentication | X-API-Key header for all requests. During POC, we will use a hardcoded API key for demo.|


---

# PART II: ARCHITECTURE


## 5. Test Execution Model

### 5.1 Test Sequencing (15-min Cycle)

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                    15-MINUTE TEST CYCLE TIMELINE                             │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                              │
│  T+0:00 ──┬── Speed Test Start                                              │
│           │   • Single server (Ookla/iPerf/custom)                          │
│           │   • Download + Upload measurement                               │
│  T+0:45 ──┴── Speed Test Complete (~45 sec)                                 │
│                                                                              │
│  T+0:45 ──┬── Ping Tests Start                                              │
│           │   • 3 targets: NAT, IX, INTL                                    │
│           │   • 100 packets each @ 100ms interval                           │
│  T+1:15 ──┴── Ping Tests Complete (~30 sec)                                 │
│                                                                              │
│  T+1:15 ──┬── DNS Tests Start                                               │
│           │   • .bd domain + international domain                           │
│  T+1:20 ──┴── DNS Tests Complete (~5 sec)                                   │
│                                                                              │
│  T+1:20 ──┬── HTTP Tests Start                                              │
│           │   • 4-5 URLs with weights                                       │
│  T+1:25 ──┴── HTTP Tests Complete (~5 sec)                                  │
│                                                                              │
│  T+1:25 ──┬── Traceroute Start                                              │
│           │   • NAT + INTL targets                                          │
│  T+1:40 ──┴── Traceroute Complete (~15 sec)                                 │
│                                                                              │
│  T+1:40 ─────► Idle / Wait                                                  │
│                                                                              │
│  T+14:00 ──── Prepare Submission                                            │
│              • Aggregate test results                                        │
│              • Evaluate thresholds                                          │
│              • Set status flags                                             │
│                                                                              │
│  T+15:00 ──── Submit to Core + Start Next Cycle                             │
│                                                                              │
└─────────────────────────────────────────────────────────────────────────────┘
```

### 5.2 Test Execution Flow

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                         TEST EXECUTION FLOW                                  │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                              │
│   ┌─────────┐    ┌─────────┐    ┌─────────┐    ┌─────────┐    ┌─────────┐  │
│   │  SPEED  │───►│  PING   │───►│   DNS   │───►│  HTTP   │───►│ TRACE   │  │
│   │  TEST   │    │  TEST   │    │  TEST   │    │  TEST   │    │ ROUTE   │  │
│   └────┬────┘    └────┬────┘    └────┬────┘    └────┬────┘    └────┬────┘  │
│        │              │              │              │              │        │
│        ▼              ▼              ▼              ▼              ▼        │
│   ┌─────────┐    ┌─────────┐    ┌─────────┐    ┌─────────┐    ┌─────────┐  │
│   │ Result  │    │ Result  │    │ Result  │    │ Result  │    │ Result  │  │
│   │  + Flag │    │  + Flag │    │  + Flag │    │  + Flag │    │  + Flag │  │
│   └────┬────┘    └────┬────┘    └────┬────┘    └────┬────┘    └────┬────┘  │
│        │              │              │              │              │        │
│        └──────────────┴──────────────┴──────────────┴──────────────┘        │
│                                      │                                       │
│                                      ▼                                       │
│                           ┌──────────────────┐                              │
│                           │    AGGREGATE     │                              │
│                           │    SUBMISSION    │                              │
│                           └────────┬─────────┘                              │
│                                    │                                         │
│                                    ▼                                         │
│                           ┌──────────────────┐                              │
│                           │   SUBMIT TO      │                              │
│                           │     CORE         │                              │
│                           └──────────────────┘                              │
│                                                                              │
└─────────────────────────────────────────────────────────────────────────────┘
```

### 5.3 Partial Results Handling

If any test fails, the agent still submits results for successful tests:

| Scenario | Action |
|----------|--------|
| Speed test timeout | Submit with `speed_test: null`, other tests included |
| One ping target unreachable | Submit 2/3 ping results, mark 1 as FAILED |
| DNS server timeout | Submit with `dns_test.test_status: "FAILED"` |
| HTTP URL unreachable | Include in results with `reachable: false` |
| All tests fail | Submit with `test_summary.successful_tests: 0` |

---

# PART III: CONFIGURATION

---

## 6. Configuration Architecture

During POC, we will use mock data for configuration, the call-home API will be getting mock data.

## 8. Full Configuration (Static JSON during POC)
The agent will read a static JSON file from `/data/config/agent-config.json`.
### 8.1 Complete Config Schema

**Location**: `/data/config/agent-config.json`

```json
{
  "_meta": {
    "config_serial": 100,
    "fetched_at": "2026-01-16T00:00:00+06:00",
    "core_version": "1.2.0"
  },

  "agent": {
    "agent_uuid": "8d0f7780-8536-51ef-055c-f18gd2g01bf8",
    "isp_id": 142,
    "isp_name": "Example ISP Ltd",
    "pop_id": 1523,
    "pop_name": "Dhaka Central",
    "deployment_scope": "POP",
    "state": "ACTIVE"
  },

  "timing": {
    "test_interval_minutes": 15,
    "submission_interval_minutes": 15,
    "config_refresh_minutes": 60,
    "test_timeout_seconds": 120,
    "submission_timeout_seconds": 30
  },

  "test_profile": {
    "profile_id": "default",
    "profile_name": "BTRC Standard",

    "speed_test": {
      "enabled": true,
      "method": "OOKLA_API",
      "server_id": 12345,
      "server_name": "BTRC Speed Test Server",
      "server_location": "Dhaka",
      "download_duration_sec": 15,
      "upload_duration_sec": 15,
      "streams": 4
    },

    "ping_targets": [
      {
        "target_id": "NAT-01",
        "type": "NATIONAL",
        "ip": "103.10.20.1",
        "name": "BTRC Reference Server",
        "location": "Dhaka",
        "packet_count": 100,
        "packet_size_bytes": 64,
        "interval_ms": 100,
        "timeout_ms": 1000
      },
      {
        "target_id": "IX-01",
        "type": "IX",
        "ip": "103.30.40.1",
        "name": "BDIX Peering Point",
        "location": "BDIX",
        "packet_count": 100,
        "packet_size_bytes": 64,
        "interval_ms": 100,
        "timeout_ms": 1000
      },
      {
        "target_id": "INTL-01",
        "type": "INTERNATIONAL",
        "ip": "203.100.50.1",
        "name": "Singapore Reference Server",
        "location": "Singapore",
        "packet_count": 100,
        "packet_size_bytes": 64,
        "interval_ms": 100,
        "timeout_ms": 2000
      }
    ],

    "dns_targets": [
      {
        "domain": "btrc.gov.bd",
        "domain_type": "LOCAL_BD",
        "record_type": "A"
      },
      {
        "domain": "google.com",
        "domain_type": "INTERNATIONAL",
        "record_type": "A"
      }
    ],

    "dns_server": {
      "use_isp_dns": true,
      "fallback_dns": ["8.8.8.8", "1.1.1.1"]
    },

    "http_targets": [
      {
        "url": "https://btrc.gov.bd",
        "weight": 25
      },
      {
        "url": "https://www.bdix.net",
        "weight": 20
      },
      {
        "url": "https://google.com",
        "weight": 25
      },
      {
        "url": "https://facebook.com",
        "weight": 15
      },
      {
        "url": "https://youtube.com",
        "weight": 15
      }
    ],

    "traceroute_targets": [
      {
        "target_id": "TR-NAT-01",
        "type": "NATIONAL",
        "ip": "103.10.20.1",
        "name": "BTRC Reference Server",
        "max_hops": 30,
        "timeout_ms": 5000
      },
      {
        "target_id": "TR-INTL-01",
        "type": "INTERNATIONAL",
        "ip": "203.100.50.1",
        "name": "Singapore Reference Server",
        "max_hops": 30,
        "timeout_ms": 10000
      }
    ]
  },

  "thresholds": {
    "speed_test": {
      "download_min_mbps": 100,
      "upload_min_mbps": 50,
      "status_pass": "download >= 100 AND upload >= 50",
      "status_degraded": "download >= 50 OR upload >= 25",
      "status_fail": "download < 50 AND upload < 25"
    },
    "ping": {
      "national": {
        "latency_max_ms": 20,
        "packet_loss_max_pct": 1.0,
        "jitter_max_ms": 10
      },
      "ix": {
        "latency_max_ms": 50,
        "packet_loss_max_pct": 1.0,
        "jitter_max_ms": 15
      },
      "international": {
        "latency_max_ms": 150,
        "packet_loss_max_pct": 2.0,
        "jitter_max_ms": 30
      }
    },
    "dns": {
      "resolution_max_ms": 100,
      "success_rate_min_pct": 100
    },
    "http": {
      "reachability_min_score": 80,
      "response_time_max_ms": 2000
    },
    "traceroute": {
      "path_complete_required": true,
      "max_hops": 20
    }
  },

  "observability": {
    "health_reporting": {
      "enabled": true,
      "include_cpu": true,
      "include_memory": true,
      "include_disk": true
    },
    "prometheus": {
      "enabled": false,
      "port": 9090,
      "path": "/metrics"
    },
    "log_level": "INFO",
    "log_forwarding": {
      "enabled": false,
      "endpoint": "/api/v1/agent-qos/logs"
    }
  },

  "resilience": {
    "queue_max_depth": 100,
    "retry_max_attempts": 5,
    "retry_initial_delay_ms": 1000,
    "retry_max_delay_ms": 300000,
    "retry_multiplier": 2.0
  },

  "reference_servers": [
    {
      "server_id": "REF-DHAKA-01",
      "server_name": "BTRC Reference Server - Dhaka",
      "server_ip": "103.10.20.1",
      "server_location": "Dhaka",
      "server_type": "PRIMARY"
    },
    {
      "server_id": "REF-BDIX-01",
      "server_name": "BDIX Reference Server",
      "server_ip": "103.30.40.1",
      "server_location": "BDIX",
      "server_type": "PEERING"
    },
    {
      "server_id": "REF-INTL-SG",
      "server_name": "Singapore Reference Server",
      "server_ip": "203.100.50.1",
      "server_location": "Singapore",
      "server_type": "INTERNATIONAL"
    }
  ]
}
```

### 8.2 Field Specifications by Section

**Agent Section**

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| agent_uuid | UUID | Yes | Agent identifier |
| isp_id | INTEGER | Yes | ISP identifier |
| isp_name | STRING | Yes | ISP display name |
| pop_id | INTEGER | Yes | PoP identifier |
| pop_name | STRING | Yes | PoP display name |
| deployment_scope | ENUM | Yes | ISP or POP |
| state | ENUM | Yes | ACTIVE/BLOCKED/DISABLED/MAINTENANCE |

**Timing Section**

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| test_interval_minutes | INTEGER | Yes | Test cycle interval (default: 15) |
| submission_interval_minutes | INTEGER | Yes | Submission interval (default: 15) |
| config_refresh_minutes | INTEGER | Yes | Config check interval (default: 60) |
| test_timeout_seconds | INTEGER | Yes | Per-test timeout (default: 120) |
| submission_timeout_seconds | INTEGER | Yes | API call timeout (default: 30) |

### 8.3 Enum Values Reference

**Deployment Scope**

| Value | Description |
|-------|-------------|
| ISP | One agent covers entire ISP |
| POP | One agent per PoP location |

**Agent State**

| Value | Description |
|-------|-------------|
| ACTIVE | Normal operation |
| BLOCKED | Validation failed |
| DISABLED | Admin disabled |
| MAINTENANCE | Paused for maintenance |

**Target Type**

| Value | Description |
|-------|-------------|
| NATIONAL | Domestic Bangladesh server |
| IX | BDIX peering point |
| INTERNATIONAL | Overseas server |
| LOCAL_BD | .bd domain (DNS) |

**Speed Test Method**

| Value | Description |
|-------|-------------|
| OOKLA_API | Speedtest.net API |
| IPERF3 | iPerf3 server |
| HTTP_DOWNLOAD | HTTP GET large file |
| HTTP_UPLOAD | HTTP POST payload |

---

# PART IV: CORE API REFERENCE

---

## 10. API Overview

### 10.2 Common Headers

```http
X-Agent-UUID: 8d0f7780-8536-51ef-055c-f18gd2g01bf8
Content-Type: application/json
Accept: application/json
```

### 10.3 API Endpoints Summary

| Method | Endpoint | Description |
|--------|----------|-------------|
| POST | /api/v1/submissions/qos-measurements | Submit test results |

---

## 13. QoS Submission API

### 13.1 POST /api/v1/submissions/qos-measurements

**Request**:
```http
POST /api/v1/submissions/qos-measurements HTTP/1.1
Host: qos-core.btrc.gov.bd
Content-Type: application/json

{
  "submission": { ... },
  "agent_status": { ... },
  "speed_test": { ... },
  "ping_tests": [ ... ],
  "dns_test": { ... },
  "http_test": { ... },
  "traceroute_tests": [ ... ]
}
```

**Response 200** (accepted):
```json
{
  "status": "accepted",
  "submission_uuid": "770g0611-g41d-63f6-c938-668877662222",
  "received_at": "2026-01-16T10:15:00+06:00",
  "tests_processed": 7
}
```

**Response 202** (queued):
```json
{
  "status": "queued",
  "submission_uuid": "770g0611-g41d-63f6-c938-668877662222",
  "queue_position": 15,
  "estimated_processing_time_ms": 5000
}
```

### 13.2 Error Responses

| Code | Description | Retry? |
|------|-------------|--------|
| 400 | Invalid payload | No - fix payload |
| 401 | Authentication failed | No - check API key |
| 422 | Validation error | No - fix data |
| 429 | Rate limited | Yes - with backoff |
| 500 | Server error | Yes - with backoff |
| 503 | Service unavailable | Yes - with backoff |

---

# PART V: TEST SPECIFICATIONS

---

## 14. Speed Test

### 14.1 Test Parameters

| Parameter | Default | Description |
|-----------|---------|-------------|
| method | OOKLA_API | Test method (from config) |
| download_duration_sec | 15 | Download test duration |
| upload_duration_sec | 15 | Upload test duration |
| streams | 4 | Parallel TCP streams |
| server_id | (config) | Target server ID |

### 14.2 Supported Methods

| Method | Description | Use Case |
|--------|-------------|----------|
| OOKLA_API | Speedtest.net API | Preferred - standardized |
| IPERF3 | iPerf3 server | Alternative - self-hosted |
| HTTP_DOWNLOAD | Large file GET | Fallback method |
| HTTP_UPLOAD | Large POST | Fallback method |

### 14.3 Output JSON Structure

```json
{
  "test_uuid": "st-001-2026011610000",
  "time": "2026-01-16T10:00:00+06:00",
  "test_status": "SUCCESS",
  "test_duration_ms": 32500,
  "target": {
    "type": "OOKLA_API",
    "server_id": 12345,
    "server_name": "BTRC Speed Test Server",
    "server_location": "Dhaka"
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
  },
  "latency_to_server_ms": 3.2,
  "test_method": "OOKLA_API",
  "status_flag": "PASS"
}
```

### 14.4 Threshold Evaluation

```python
def evaluate_speed_test(result, thresholds):
    download = result["download"]["speed_mbps"]
    upload = result["upload"]["speed_mbps"]

    if download >= thresholds["download_min_mbps"] and \
       upload >= thresholds["upload_min_mbps"]:
        return "PASS"
    elif download >= thresholds["download_min_mbps"] * 0.5 or \
         upload >= thresholds["upload_min_mbps"] * 0.5:
        return "DEGRADED"
    else:
        return "FAIL"
```

### 14.5 Failure Handling

| Failure Type | Action |
|--------------|--------|
| Server unreachable | Mark FAILED, set error_code |
| Timeout | Mark FAILED, include partial data |
| Low bandwidth | Complete test, flag DEGRADED |

---

## 15. Ping Test

### 15.1 Test Parameters

| Parameter | Default | Description |
|-----------|---------|-------------|
| packet_count | 100 | ICMP packets per target |
| packet_size_bytes | 64 | Payload size |
| interval_ms | 100 | Between packets |
| timeout_ms | 1000-2000 | Wait for response |
| protocol | ICMP | ICMP or TCP |

### 15.2 Target Types

| Type | Abbrev | Description | Typical Latency |
|------|--------|-------------|-----------------|
| NATIONAL | NAT | Domestic server | < 20ms |
| IX | IX | BDIX peering | < 50ms |
| INTERNATIONAL | INTL | Overseas server | 50-150ms |

### 15.3 Metrics Calculation

**RTT Statistics**:
```python
def calculate_rtt_stats(rtt_samples):
    return {
        "rtt_min_ms": min(rtt_samples),
        "rtt_max_ms": max(rtt_samples),
        "rtt_avg_ms": sum(rtt_samples) / len(rtt_samples),
        "rtt_median_ms": median(rtt_samples),
        "rtt_stddev_ms": stdev(rtt_samples),
        "rtt_p95_ms": percentile(rtt_samples, 95),
        "rtt_p99_ms": percentile(rtt_samples, 99)
    }
```

**Jitter Calculation**:
```python
def calculate_jitter(rtt_samples):
    # Inter-packet delay variation (RFC 3550)
    differences = [abs(rtt_samples[i] - rtt_samples[i-1])
                   for i in range(1, len(rtt_samples))]
    return sum(differences) / len(differences)
```

**Packet Loss**:
```python
def calculate_packet_loss(sent, received):
    lost = sent - received
    loss_pct = (lost / sent) * 100
    return {
        "packets_sent": sent,
        "packets_received": received,
        "packets_lost": lost,
        "loss_pct": round(loss_pct, 2)
    }
```

### 15.4 Output JSON Structure

```json
{
  "test_uuid": "ping-001-2026011610000",
  "time": "2026-01-16T10:00:45+06:00",
  "test_status": "SUCCESS",
  "target": {
    "type": "NATIONAL",
    "ip": "103.10.20.1",
    "name": "BTRC Reference Server",
    "location": "Dhaka"
  },
  "config": {
    "packet_count": 100,
    "packet_size_bytes": 64,
    "interval_ms": 100,
    "timeout_ms": 1000,
    "protocol": "ICMP"
  },
  "latency": {
    "rtt_min_ms": 2.1,
    "rtt_max_ms": 8.5,
    "rtt_avg_ms": 3.2,
    "rtt_median_ms": 2.9,
    "rtt_stddev_ms": 1.1,
    "rtt_p95_ms": 5.8,
    "rtt_p99_ms": 7.2,
    "jitter_ms": 1.4
  },
  "packet_loss": {
    "packets_sent": 100,
    "packets_received": 99,
    "packets_lost": 1,
    "loss_pct": 1.00,
    "loss_pattern": "RANDOM",
    "out_of_order": 0,
    "duplicates": 0
  },
  "test_duration_ms": 10500,
  "status_flag": "PASS"
}
```

### 15.5 Loss Pattern Detection

| Pattern | Description | Detection |
|---------|-------------|-----------|
| NONE | No loss | loss_pct = 0 |
| RANDOM | Sporadic drops | Non-consecutive losses |
| BURST | Consecutive drops | 3+ consecutive losses |
| PERIODIC | Regular pattern | Losses at fixed intervals |

---

## 16. DNS Test

### 16.1 Test Parameters

| Parameter | Default | Description |
|-----------|---------|-------------|
| domains | 2+ | .bd + international |
| record_type | A | DNS record type |
| timeout_ms | 5000 | Query timeout |
| dns_server | ISP DNS | Server to query |

### 16.2 Domain Types

| Type | Example | Purpose |
|------|---------|---------|
| LOCAL_BD | btrc.gov.bd | Bangladesh domain resolution |
| INTERNATIONAL | google.com | Global domain resolution |

### 16.3 Output JSON Structure

```json
{
  "test_uuid": "dns-001-2026011610000",
  "time": "2026-01-16T10:01:20+06:00",
  "test_status": "SUCCESS",
  "dns_server_used": {
    "ip": "103.45.120.1",
    "name": "ISP DNS Server",
    "type": "ISP"
  },
  "queries": [
    {
      "domain": "btrc.gov.bd",
      "domain_type": "LOCAL_BD",
      "record_type": "A",
      "resolution_time_ms": 8.2,
      "response_code": "NOERROR",
      "resolved_ip": "202.51.182.198",
      "success": true
    },
    {
      "domain": "google.com",
      "domain_type": "INTERNATIONAL",
      "record_type": "A",
      "resolution_time_ms": 12.5,
      "response_code": "NOERROR",
      "resolved_ip": "142.250.193.206",
      "success": true
    }
  ],
  "summary": {
    "total_queries": 2,
    "successful": 2,
    "failed": 0,
    "avg_resolution_ms": 10.35,
    "min_resolution_ms": 8.2,
    "max_resolution_ms": 12.5
  },
  "test_duration_ms": 250,
  "status_flag": "PASS"
}
```

### 16.4 DNS Response Codes

| Code | Description |
|------|-------------|
| NOERROR | Successful resolution |
| NXDOMAIN | Domain does not exist |
| SERVFAIL | Server failure |
| REFUSED | Query refused |
| TIMEOUT | No response |

---

## 17. HTTP Test

### 17.1 Test Parameters

| Parameter | Default | Description |
|-----------|---------|-------------|
| urls | 4-5 | Target URLs |
| weights | sum=100 | Per-URL weights |
| timeout_ms | 10000 | Request timeout |
| follow_redirects | true | Follow HTTP 3xx |

### 17.2 URL Targets with Weights

```json
{
  "http_targets": [
    {"url": "https://btrc.gov.bd", "weight": 25},
    {"url": "https://www.bdix.net", "weight": 20},
    {"url": "https://google.com", "weight": 25},
    {"url": "https://facebook.com", "weight": 15},
    {"url": "https://youtube.com", "weight": 15}
  ]
}
```

**Weight Rules**:
- Total weights must equal 100
- Higher weight = more important URL
- Score = sum of weights for reachable URLs

### 17.3 Timing Breakdown

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                      HTTP REQUEST TIMING BREAKDOWN                           │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                              │
│   dns_lookup_ms ──► tcp_connect_ms ──► ssl_handshake_ms ──► ttfb_ms         │
│        │                  │                   │                │             │
│        ▼                  ▼                   ▼                ▼             │
│   ┌─────────┐        ┌─────────┐        ┌─────────┐      ┌─────────┐        │
│   │  DNS    │        │   TCP   │        │   TLS   │      │  First  │        │
│   │ Lookup  │───────►│  SYN/   │───────►│  Hand-  │─────►│  Byte   │        │
│   │         │        │  ACK    │        │  shake  │      │         │        │
│   └─────────┘        └─────────┘        └─────────┘      └─────────┘        │
│                                                                │             │
│                                                                ▼             │
│                                                          ┌─────────┐        │
│                                                          │ Content │        │
│                                                          │Download │        │
│                                                          └─────────┘        │
│                                                                              │
│   total_time_ms = dns + tcp + ssl + ttfb + content_download                 │
│                                                                              │
└─────────────────────────────────────────────────────────────────────────────┘
```

### 17.4 Reachability Score Calculation

```python
def calculate_reachability_score(results):
    score = 0
    max_score = 100

    for result in results:
        if result["reachable"]:
            score += result["weight"]

    return {
        "score": score,
        "max_score": max_score,
        "percentage": (score / max_score) * 100
    }
```

### 17.5 Output JSON Structure

```json
{
  "test_uuid": "http-001-2026011610000",
  "time": "2026-01-16T10:01:22+06:00",
  "test_status": "SUCCESS",
  "targets": [
    {
      "url": "https://btrc.gov.bd",
      "weight": 25,
      "reachable": true,
      "status_code": 200,
      "timing": {
        "dns_lookup_ms": 8.2,
        "tcp_connect_ms": 5.1,
        "ssl_handshake_ms": 42.3,
        "ttfb_ms": 28.6,
        "content_download_ms": 125.0,
        "total_time_ms": 209.2
      },
      "protocol": "HTTP/2"
    }
  ],
  "summary": {
    "reachability_score": {
      "score": 100,
      "max_score": 100,
      "percentage": 100.0,
      "targets_reached": 5,
      "targets_failed": 0
    },
    "response_time": {
      "weighted_avg_ms": 311.86,
      "simple_avg_ms": 311.86,
      "min_ms": 181.2,
      "max_ms": 456.2
    }
  },
  "test_duration_ms": 1850,
  "status_flag": "PASS"
}
```

---

## 18. Traceroute Test

### 18.1 Test Parameters

| Parameter | Default | Description |
|-----------|---------|-------------|
| targets | 2 | NAT + INTL |
| max_hops | 30 | Maximum hops |
| timeout_ms | 5000-10000 | Per-hop timeout |
| protocol | ICMP | ICMP or UDP |

### 18.2 Output JSON Structure

```json
{
  "test_uuid": "tr-001-2026011610000",
  "time": "2026-01-16T10:01:25+06:00",
  "test_status": "SUCCESS",
  "target": {
    "type": "NATIONAL",
    "ip": "103.10.20.1",
    "name": "BTRC Reference Server"
  },
  "hops": [
    {"hop": 1, "ip": "192.168.20.1", "hostname": "gateway.local", "rtt_ms": 0.5},
    {"hop": 2, "ip": "10.0.1.1", "hostname": "core-rtr.isp142.net", "rtt_ms": 1.2},
    {"hop": 3, "ip": "103.45.120.1", "hostname": "pe-dhk.isp142.net", "rtt_ms": 2.1},
    {"hop": 4, "ip": "103.10.20.1", "hostname": "btrc-ref-01.gov.bd", "rtt_ms": 3.2}
  ],
  "summary": {
    "hop_count": 4,
    "total_rtt_ms": 3.2,
    "path_complete": true
  },
  "status_flag": "PASS"
}
```

### 18.3 Path Completion Detection

| Scenario | path_complete | Description |
|----------|---------------|-------------|
| Reached destination | true | Final hop matches target IP |
| Max hops reached | false | 30 hops without reaching target |
| All hops timeout | false | No responses received |

---

# PART VI: DATA MODEL & SUBMISSION

---

## 19. Combined Submission Structure

### 19.1 Payload Overview

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                     QOS_AGENT SUBMISSION PAYLOAD                             │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                              │
│  {                                                                           │
│    "submission": { ... }           ◄── Header, timing, summary              │
│    "agent_status": { ... }         ◄── Agent health, IPs                    │
│    "agent_detected_failures": { }  ◄── Connectivity issues                  │
│    "reference_servers": [ ... ]    ◄── Server status list                   │
│    "speed_test": { ... }           ◄── Speed test results                   │
│    "ping_tests": [ ... ]           ◄── Array of ping results (up to 3)     │
│    "dns_test": { ... }             ◄── DNS test results                     │
│    "http_test": { ... }            ◄── HTTP test results                    │
│    "traceroute_tests": [ ... ]     ◄── Array of traceroute results          │
│  }                                                                           │
│                                                                              │
└─────────────────────────────────────────────────────────────────────────────┘
```

### 19.2 Complete JSON Example

```json
{
  "submission": {
    "submission_uuid": "770g0611-g41d-63f6-c938-668877662222",
    "originator_type": "QOS_AGENT",
    "agent_uuid": "8d0f7780-8536-51ef-055c-f18gd2g01bf8",
    "agent_version": "2.1.0",
    "isp_id": 142,
    "pop_id": 1523,
    "submission_time": "2026-01-16T10:15:00+06:00",
    "reporting_period_start": "2026-01-16T10:00:00+06:00",
    "reporting_period_end": "2026-01-16T10:15:00+06:00",
    "test_summary": {
      "speed_tests": 1,
      "ping_tests": 3,
      "dns_tests": 1,
      "http_tests": 1,
      "traceroute_tests": 2,
      "total_tests": 8,
      "successful_tests": 8,
      "failed_tests": 0
    }
  },
  "agent_status": {
    "host_ip": "192.168.20.10",
    "public_ip": "103.45.120.20",
    "public_ip_source": "CORE_API",
    "public_ip_fetch_time": "2026-01-16T10:14:30+06:00",
    "status": "ACTIVE",
    "cpu_usage_pct": 12.5,
    "memory_usage_pct": 45.2,
    "disk_usage_pct": 28.0,
    "uptime_seconds": 1728000
  },
  "agent_detected_failures": {
    "has_failures": false,
    "connectivity_status": "FULL",
    "failure_count": 0,
    "failures": [],
    "tests_impacted": [],
    "servers_affected": []
  },
  "reference_servers": [
    {
      "server_id": "REF-DHAKA-01",
      "server_name": "BTRC Reference Server - Dhaka",
      "server_ip": "103.10.20.1",
      "server_location": "Dhaka",
      "server_type": "PRIMARY",
      "status": "REACHABLE"
    },
    {
      "server_id": "REF-BDIX-01",
      "server_name": "BDIX Reference Server",
      "server_ip": "103.30.40.1",
      "server_location": "BDIX",
      "server_type": "PEERING",
      "status": "REACHABLE"
    },
    {
      "server_id": "REF-INTL-SG",
      "server_name": "Singapore Reference Server",
      "server_ip": "203.100.50.1",
      "server_location": "Singapore",
      "server_type": "INTERNATIONAL",
      "status": "REACHABLE"
    }
  ],
  "speed_test": {
    "test_uuid": "st-001-2026011610000",
    "time": "2026-01-16T10:00:00+06:00",
    "test_status": "SUCCESS",
    "test_duration_ms": 32500,
    "target": {
      "type": "OOKLA_API",
      "server_id": 12345,
      "server_name": "BTRC Speed Test Server",
      "server_location": "Dhaka"
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
    },
    "latency_to_server_ms": 3.2,
    "test_method": "OOKLA_API",
    "status_flag": "PASS"
  },
  "ping_tests": [
    {
      "test_uuid": "ping-001-2026011610000",
      "time": "2026-01-16T10:00:45+06:00",
      "test_status": "SUCCESS",
      "target": {
        "type": "NATIONAL",
        "ip": "103.10.20.1",
        "name": "BTRC Reference Server",
        "location": "Dhaka"
      },
      "config": {
        "packet_count": 100,
        "packet_size_bytes": 64,
        "interval_ms": 100,
        "timeout_ms": 1000,
        "protocol": "ICMP"
      },
      "latency": {
        "rtt_min_ms": 2.1,
        "rtt_max_ms": 8.5,
        "rtt_avg_ms": 3.2,
        "rtt_median_ms": 2.9,
        "rtt_stddev_ms": 1.1,
        "rtt_p95_ms": 5.8,
        "rtt_p99_ms": 7.2,
        "jitter_ms": 1.4
      },
      "packet_loss": {
        "packets_sent": 100,
        "packets_received": 99,
        "packets_lost": 1,
        "loss_pct": 1.00,
        "loss_pattern": "RANDOM",
        "out_of_order": 0,
        "duplicates": 0
      },
      "test_duration_ms": 10500,
      "status_flag": "PASS"
    },
    {
      "test_uuid": "ping-002-2026011610000",
      "time": "2026-01-16T10:00:56+06:00",
      "test_status": "SUCCESS",
      "target": {
        "type": "IX",
        "ip": "103.30.40.1",
        "name": "BDIX Peering Point",
        "location": "BDIX"
      },
      "config": {
        "packet_count": 100,
        "packet_size_bytes": 64,
        "interval_ms": 100,
        "timeout_ms": 1000,
        "protocol": "ICMP"
      },
      "latency": {
        "rtt_min_ms": 4.5,
        "rtt_max_ms": 12.3,
        "rtt_avg_ms": 6.8,
        "rtt_median_ms": 6.2,
        "rtt_stddev_ms": 1.8,
        "rtt_p95_ms": 10.1,
        "rtt_p99_ms": 11.8,
        "jitter_ms": 2.1
      },
      "packet_loss": {
        "packets_sent": 100,
        "packets_received": 100,
        "packets_lost": 0,
        "loss_pct": 0.00,
        "loss_pattern": "NONE",
        "out_of_order": 0,
        "duplicates": 0
      },
      "test_duration_ms": 10200,
      "status_flag": "PASS"
    },
    {
      "test_uuid": "ping-003-2026011610000",
      "time": "2026-01-16T10:01:07+06:00",
      "test_status": "SUCCESS",
      "target": {
        "type": "INTERNATIONAL",
        "ip": "203.100.50.1",
        "name": "Singapore Reference Server",
        "location": "Singapore"
      },
      "config": {
        "packet_count": 100,
        "packet_size_bytes": 64,
        "interval_ms": 100,
        "timeout_ms": 2000,
        "protocol": "ICMP"
      },
      "latency": {
        "rtt_min_ms": 52.3,
        "rtt_max_ms": 78.9,
        "rtt_avg_ms": 58.4,
        "rtt_median_ms": 56.8,
        "rtt_stddev_ms": 5.2,
        "rtt_p95_ms": 68.5,
        "rtt_p99_ms": 75.2,
        "jitter_ms": 4.8
      },
      "packet_loss": {
        "packets_sent": 100,
        "packets_received": 98,
        "packets_lost": 2,
        "loss_pct": 2.00,
        "loss_pattern": "RANDOM",
        "out_of_order": 1,
        "duplicates": 0
      },
      "test_duration_ms": 12800,
      "status_flag": "PASS"
    }
  ],
  "dns_test": {
    "test_uuid": "dns-001-2026011610000",
    "time": "2026-01-16T10:01:20+06:00",
    "test_status": "SUCCESS",
    "dns_server_used": {
      "ip": "103.45.120.1",
      "name": "ISP DNS Server",
      "type": "ISP"
    },
    "queries": [
      {
        "domain": "btrc.gov.bd",
        "domain_type": "LOCAL_BD",
        "record_type": "A",
        "resolution_time_ms": 8.2,
        "response_code": "NOERROR",
        "resolved_ip": "202.51.182.198",
        "success": true
      },
      {
        "domain": "google.com",
        "domain_type": "INTERNATIONAL",
        "record_type": "A",
        "resolution_time_ms": 12.5,
        "response_code": "NOERROR",
        "resolved_ip": "142.250.193.206",
        "success": true
      }
    ],
    "summary": {
      "total_queries": 2,
      "successful": 2,
      "failed": 0,
      "avg_resolution_ms": 10.35,
      "min_resolution_ms": 8.2,
      "max_resolution_ms": 12.5
    },
    "test_duration_ms": 250,
    "status_flag": "PASS"
  },
  "http_test": {
    "test_uuid": "http-001-2026011610000",
    "time": "2026-01-16T10:01:22+06:00",
    "test_status": "SUCCESS",
    "targets": [
      {
        "url": "https://btrc.gov.bd",
        "weight": 25,
        "reachable": true,
        "status_code": 200,
        "timing": {
          "dns_lookup_ms": 8.2,
          "tcp_connect_ms": 5.1,
          "ssl_handshake_ms": 42.3,
          "ttfb_ms": 28.6,
          "content_download_ms": 125.0,
          "total_time_ms": 209.2
        },
        "protocol": "HTTP/2"
      },
      {
        "url": "https://www.bdix.net",
        "weight": 20,
        "reachable": true,
        "status_code": 200,
        "timing": {
          "dns_lookup_ms": 5.4,
          "tcp_connect_ms": 6.8,
          "ssl_handshake_ms": 38.5,
          "ttfb_ms": 45.2,
          "content_download_ms": 85.3,
          "total_time_ms": 181.2
        },
        "protocol": "HTTP/2"
      },
      {
        "url": "https://google.com",
        "weight": 25,
        "reachable": true,
        "status_code": 200,
        "timing": {
          "dns_lookup_ms": 12.5,
          "tcp_connect_ms": 58.2,
          "ssl_handshake_ms": 112.4,
          "ttfb_ms": 85.3,
          "content_download_ms": 45.8,
          "total_time_ms": 314.2
        },
        "protocol": "HTTP/2"
      },
      {
        "url": "https://facebook.com",
        "weight": 15,
        "reachable": true,
        "status_code": 200,
        "timing": {
          "dns_lookup_ms": 15.2,
          "tcp_connect_ms": 62.1,
          "ssl_handshake_ms": 108.5,
          "ttfb_ms": 92.1,
          "content_download_ms": 120.6,
          "total_time_ms": 398.5
        },
        "protocol": "HTTP/2"
      },
      {
        "url": "https://youtube.com",
        "weight": 15,
        "reachable": true,
        "status_code": 200,
        "timing": {
          "dns_lookup_ms": 11.8,
          "tcp_connect_ms": 55.4,
          "ssl_handshake_ms": 115.2,
          "ttfb_ms": 88.6,
          "content_download_ms": 185.2,
          "total_time_ms": 456.2
        },
        "protocol": "HTTP/2"
      }
    ],
    "summary": {
      "reachability_score": {
        "score": 100,
        "max_score": 100,
        "percentage": 100.0,
        "targets_reached": 5,
        "targets_failed": 0
      },
      "response_time": {
        "weighted_avg_ms": 311.86,
        "simple_avg_ms": 311.86,
        "min_ms": 181.2,
        "max_ms": 456.2
      }
    },
    "test_duration_ms": 1850,
    "status_flag": "PASS"
  },
  "traceroute_tests": [
    {
      "test_uuid": "tr-001-2026011610000",
      "time": "2026-01-16T10:01:25+06:00",
      "test_status": "SUCCESS",
      "target": {
        "type": "NATIONAL",
        "ip": "103.10.20.1",
        "name": "BTRC Reference Server"
      },
      "hops": [
        {"hop": 1, "ip": "192.168.20.1", "hostname": "gateway.local", "rtt_ms": 0.5},
        {"hop": 2, "ip": "10.0.1.1", "hostname": "core-rtr.isp142.net", "rtt_ms": 1.2},
        {"hop": 3, "ip": "103.45.120.1", "hostname": "pe-dhk.isp142.net", "rtt_ms": 2.1},
        {"hop": 4, "ip": "103.10.20.1", "hostname": "btrc-ref-01.gov.bd", "rtt_ms": 3.2}
      ],
      "summary": {
        "hop_count": 4,
        "total_rtt_ms": 3.2,
        "path_complete": true
      },
      "status_flag": "PASS"
    },
    {
      "test_uuid": "tr-002-2026011610000",
      "time": "2026-01-16T10:01:35+06:00",
      "test_status": "SUCCESS",
      "target": {
        "type": "INTERNATIONAL",
        "ip": "203.100.50.1",
        "name": "Singapore Reference Server"
      },
      "hops": [
        {"hop": 1, "ip": "192.168.20.1", "hostname": "gateway.local", "rtt_ms": 0.5},
        {"hop": 2, "ip": "10.0.1.1", "hostname": "core-rtr.isp142.net", "rtt_ms": 1.2},
        {"hop": 3, "ip": "103.45.120.1", "hostname": "pe-dhk.isp142.net", "rtt_ms": 2.1},
        {"hop": 4, "ip": "103.200.10.1", "hostname": "sgw.isp142.net", "rtt_ms": 5.8},
        {"hop": 5, "ip": "202.150.80.1", "hostname": "sgix-peer.sg", "rtt_ms": 48.2},
        {"hop": 6, "ip": "203.100.50.1", "hostname": "ref-sg-01.btrc.int", "rtt_ms": 52.5}
      ],
      "summary": {
        "hop_count": 6,
        "total_rtt_ms": 52.5,
        "path_complete": true
      },
      "status_flag": "PASS"
    }
  ]
}
```

---

## 20. Field Specifications

### 20.1 Submission Header Fields

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| submission_uuid | UUID | Yes | Unique identifier per submission |
| originator_type | STRING | Yes | Always "QOS_AGENT" |
| agent_uuid | UUID | Yes | Registered agent identifier |
| agent_version | STRING | Yes | Agent software version |
| isp_id | INTEGER | Yes | ISP identifier |
| pop_id | INTEGER | Yes | PoP location identifier |
| submission_time | ISO8601 | Yes | When submitted |
| reporting_period_start | ISO8601 | Yes | 15-min window start |
| reporting_period_end | ISO8601 | Yes | 15-min window end |

### 20.2 Test Summary Fields

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| speed_tests | INTEGER | Yes | Speed tests in submission |
| ping_tests | INTEGER | Yes | Ping tests count |
| dns_tests | INTEGER | Yes | DNS tests count |
| http_tests | INTEGER | Yes | HTTP tests count |
| traceroute_tests | INTEGER | Yes | Traceroute tests count |
| total_tests | INTEGER | Yes | Sum of all tests |
| successful_tests | INTEGER | Yes | Tests completed successfully |
| failed_tests | INTEGER | Yes | Tests that failed |

### 20.3 Agent Status Fields

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| host_ip | IP | Yes | Private/LAN IP of agent host |
| public_ip | IP | Yes | NAT/Public IP (from Core API) |
| public_ip_source | ENUM | Yes | CORE_API / EXTERNAL / STATIC |
| public_ip_fetch_time | ISO8601 | Yes | When public IP was resolved |
| status | ENUM | Yes | ACTIVE / INACTIVE / ERROR |
| cpu_usage_pct | DECIMAL | No | CPU utilization (optional) |
| memory_usage_pct | DECIMAL | No | Memory utilization (optional) |
| disk_usage_pct | DECIMAL | No | Disk utilization (optional) |
| uptime_seconds | INTEGER | No | Agent uptime (optional) |

### 20.4 Agent Detected Failures

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| has_failures | BOOLEAN | Yes | True if any failures detected |
| connectivity_status | ENUM | Yes | FULL / PARTIAL / NONE |
| failure_count | INTEGER | Yes | Number of failures detected |
| failures | ARRAY | Yes | List of failure objects |
| tests_impacted | ARRAY | Yes | Test types affected |
| servers_affected | ARRAY | Yes | Unreachable server IDs |

---

## 21. Enum Values & Constants

### 21.1 Test Status Values

| Value | Description |
|-------|-------------|
| SUCCESS | Test completed successfully |
| FAILED | Test failed to complete |
| TIMEOUT | Test timed out |
| PARTIAL | Some targets failed |

### 21.2 Status Flag Values

| Value | Description |
|-------|-------------|
| PASS | Meets all thresholds |
| DEGRADED | Below optimal, above minimum |
| FAIL | Below minimum threshold |

### 21.3 Target Types

| Value | Description |
|-------|-------------|
| NATIONAL | Domestic Bangladesh server |
| IX | BDIX peering point |
| INTERNATIONAL | Overseas server |
| LOCAL_BD | .bd domain (DNS only) |

### 21.4 Connectivity Status

| Value | Description |
|-------|-------------|
| FULL | All targets reachable |
| PARTIAL | Some targets unreachable |
| NONE | All targets unreachable |

### 21.5 Loss Pattern Types

| Value | Description |
|-------|-------------|
| NONE | No packet loss |
| RANDOM | Sporadic, non-consecutive |
| BURST | Consecutive packet drops |
| PERIODIC | Regular pattern of loss |

---

# PART VII: THRESHOLD & STATUS EVALUATION

---

## 22. Threshold Architecture

### 22.1 Threshold Flow

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                        THRESHOLD EVALUATION FLOW                             │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                              │
│   CORE                           AGENT                          SUBMISSION  │
│   ┌─────────────┐               ┌─────────────┐               ┌───────────┐ │
│   │ Define      │               │ Execute     │               │ Include   │ │
│   │ Thresholds  │ ──────────►   │ Tests       │ ──────────►   │ Results   │ │
│   │ in Config   │   config      │             │               │ + Status  │ │
│   └─────────────┘               │ Evaluate    │               │ Flags     │ │
│                                 │ Against     │               └───────────┘ │
│                                 │ Thresholds  │                             │
│                                 │             │                             │
│                                 │ Set Status  │                             │
│                                 │ Flags       │                             │
│                                 └─────────────┘                             │
│                                                                              │
└─────────────────────────────────────────────────────────────────────────────┘
```

### 22.2 Per-Test Threshold Structure

```json
{
  "thresholds": {
    "speed_test": {
      "download_min_mbps": 100,
      "upload_min_mbps": 50
    },
    "ping": {
      "national": {
        "latency_max_ms": 20,
        "packet_loss_max_pct": 1.0,
        "jitter_max_ms": 10
      },
      "ix": {
        "latency_max_ms": 50,
        "packet_loss_max_pct": 1.0,
        "jitter_max_ms": 15
      },
      "international": {
        "latency_max_ms": 150,
        "packet_loss_max_pct": 2.0,
        "jitter_max_ms": 30
      }
    },
    "dns": {
      "resolution_max_ms": 100
    },
    "http": {
      "reachability_min_score": 80,
      "response_time_max_ms": 2000
    }
  }
}
```

### 22.3 Multi-Level Thresholds

| Level | Description | Typical Use |
|-------|-------------|-------------|
| PASS | Meets or exceeds target | Normal operation |
| DEGRADED | Below target, above minimum | Warning state |
| FAIL | Below minimum acceptable | Alert/action required |

---

## 23. Status Flag Evaluation

### 23.1 Agent-Side Evaluation Logic

```python
def evaluate_ping_test(result, thresholds):
    target_type = result["target"]["type"].lower()
    threshold = thresholds["ping"][target_type]

    latency = result["latency"]["rtt_avg_ms"]
    loss = result["packet_loss"]["loss_pct"]
    jitter = result["latency"]["jitter_ms"]

    # Check all metrics
    latency_ok = latency <= threshold["latency_max_ms"]
    loss_ok = loss <= threshold["packet_loss_max_pct"]
    jitter_ok = jitter <= threshold["jitter_max_ms"]

    if latency_ok and loss_ok and jitter_ok:
        return "PASS"
    elif latency_ok or loss_ok:  # At least some metrics OK
        return "DEGRADED"
    else:
        return "FAIL"
```

### 23.2 Status Flag per Test Type

| Test Type | PASS Condition | DEGRADED Condition | FAIL Condition |
|-----------|----------------|---------------------|----------------|
| Speed | download >= min AND upload >= min | Either meets 50% of min | Both below 50% |
| Ping | All metrics within threshold | 1-2 metrics exceeded | All metrics exceeded |
| DNS | Resolution time within limit | N/A | Resolution timeout/failure |
| HTTP | Reachability >= 80% | Reachability 50-79% | Reachability < 50% |
| Traceroute | Path complete, hops <= max | Path complete, hops > max | Path incomplete |

---


# PART VIII: ERROR HANDLING & RESILIENCE

---

## 25. Test Failure Handling

### 25.1 Per-Test Failure Types

| Test | Failure Type | Error Code | Action |
|------|--------------|------------|--------|
| Speed | Server unreachable | QOS-E1001 | Mark FAILED, skip test |
| Speed | Timeout | QOS-E1002 | Mark FAILED, include partial |
| Ping | Target unreachable | QOS-E2001 | Mark target FAILED, continue others |
| Ping | 100% packet loss | QOS-E2002 | Mark FAILED |
| DNS | Server timeout | QOS-E3001 | Try fallback DNS |
| DNS | NXDOMAIN | QOS-E3002 | Mark query FAILED |
| HTTP | Connection refused | QOS-E4001 | Mark URL unreachable |
| HTTP | SSL error | QOS-E4002 | Mark URL FAILED |
| Traceroute | Max hops reached | QOS-E5001 | Mark path incomplete |

### 25.2 Retry Logic

```python
def execute_test_with_retry(test_func, max_retries=3):
    for attempt in range(max_retries):
        try:
            result = test_func()
            return result
        except TransientError as e:
            if attempt < max_retries - 1:
                delay = (2 ** attempt) * 1000  # Exponential backoff
                time.sleep(delay / 1000)
            else:
                return create_failed_result(e)
        except PermanentError as e:
            return create_failed_result(e)
```

### 25.3 Agent Detected Failures Object

When failures are detected, populate the `agent_detected_failures` object:

```json
{
  "agent_detected_failures": {
    "has_failures": true,
    "connectivity_status": "PARTIAL",
    "failure_count": 1,
    "failures": [
      {
        "failure_type": "TIMEOUT",
        "test_type": "SPEED",
        "target": "speedtest.btrc.gov.bd",
        "error_code": "QOS-E1002",
        "error_message": "Speed test timed out after 120 seconds",
        "detected_at": "2026-01-16T10:00:45+06:00"
      }
    ],
    "tests_impacted": ["SPEED"],
    "servers_affected": ["speedtest.btrc.gov.bd"]
  }
}
```

---

## 26. Network Failure Handling

### 26.1 Core Unreachable

When Core API is unreachable:

1. **Detect**: Connection timeout, DNS failure, or HTTP 5xx
2. **Queue**: Store submission locally in `/data/queue/`
3. **Retry**: Exponential backoff (1s, 2s, 4s, ... up to 5min)
4. **Continue**: Keep running test cycles
5. **Drain**: When Core recovers, submit queued data FIFO

### 26.2 Store-and-Forward Pattern

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                      STORE-AND-FORWARD RESILIENCE                            │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                              │
│   Test Cycle Complete                                                       │
│         │                                                                    │
│         ▼                                                                    │
│   ┌───────────────┐     Success    ┌───────────────┐                        │
│   │ Submit to     │ ──────────────► │    Done       │                        │
│   │ Core API      │                 └───────────────┘                        │
│   └───────┬───────┘                                                          │
│           │                                                                  │
│           │ Failure                                                          │
│           ▼                                                                  │
│   ┌───────────────┐                                                          │
│   │ Queue Locally │                                                          │
│   │ /data/queue/  │                                                          │
│   └───────┬───────┘                                                          │
│           │                                                                  │
│           │ Background retry                                                 │
│           ▼                                                                  │
│   ┌───────────────┐     Success    ┌───────────────┐                        │
│   │ Retry with    │ ──────────────► │ Remove from   │                        │
│   │ Backoff       │                 │ Queue         │                        │
│   └───────────────┘                 └───────────────┘                        │
│                                                                              │
└─────────────────────────────────────────────────────────────────────────────┘
```

### 26.3 Queue Management

| Parameter | Default | Description |
|-----------|---------|-------------|
| queue_max_depth | 100 | Maximum queued submissions |
| retry_max_attempts | 5 | Retries per submission |
| retry_initial_delay_ms | 1000 | Initial retry delay |
| retry_max_delay_ms | 300000 | Max delay (5 min) |
| retry_multiplier | 2.0 | Exponential factor |

---

## 27. HTTP Error Codes (Core API)

### 27.1 Error Response Format

```json
{
  "error": {
    "code": "VALIDATION_ERROR",
    "message": "Invalid submission payload",
    "details": [
      {"field": "speed_test.download.speed_mbps", "error": "must be positive"}
    ],
    "request_id": "req-abc123"
  }
}
```

### 27.2 Error Code Reference

| HTTP Code | Error Code | Retry? | Action |
|-----------|------------|--------|--------|
| 400 | VALIDATION_ERROR | No | Fix payload |
| 401 | AUTH_FAILED | No | Check API key |
| 403 | FORBIDDEN | No | Contact admin |
| 404 | NOT_FOUND | No | Check endpoint |
| 422 | UNPROCESSABLE | No | Fix data format |
| 429 | RATE_LIMITED | Yes | Backoff + retry |
| 500 | SERVER_ERROR | Yes | Retry |
| 502 | BAD_GATEWAY | Yes | Retry |
| 503 | UNAVAILABLE | Yes | Retry |
| 504 | GATEWAY_TIMEOUT | Yes | Retry |

---

# PART IX: LOCAL FILE STRUCTURES

---

## 28. Volume Structure

```
/config/                          ◄── Bootstrap config (read-only mount)
├── bootstrap.json

/data/                            ◄── Persistent data (read-write mount)
├── config/
│   └── agent-config.json         ◄── Cached config from Core
├── queue/
│   ├── pending-001.json          ◄── Queued submissions
│   └── pending-002.json
├── results/
│   └── 2026-01-16/
│       ├── 10-00.json            ◄── Test results by time
│       └── 10-15.json
└── agent-status.json             ◄── Current agent status

/logs/                            ◄── Log files (read-write mount)
├── qos-agent.log
└── qos-agent.log.1
```

---

## 29. Status File

### 29.1 Location

`/data/agent-status.json`

### 29.2 Complete JSON Example

```json
{
  "agent_uuid": "8d0f7780-8536-51ef-055c-f18gd2g01bf8",
  "state": "ACTIVE",
  "last_updated": "2026-01-16T10:15:00+06:00",
  "uptime_seconds": 1728000,
  "config": {
    "serial": 100,
    "loaded_at": "2026-01-16T00:00:00+06:00",
    "profile_id": "default"
  },
  "last_test_cycle": {
    "time": "2026-01-16T10:00:00+06:00",
    "tests_total": 8,
    "tests_successful": 8,
    "tests_failed": 0,
    "duration_ms": 100000
  },
  "last_submission": {
    "time": "2026-01-16T10:15:00+06:00",
    "status": "SUCCESS",
    "submission_uuid": "770g0611-g41d-63f6-c938-668877662222"
  },
  "queue": {
    "pending_submissions": 0,
    "oldest_queued": null
  },
  "connectivity": {
    "core_api": "REACHABLE",
    "reference_servers": {
      "REF-DHAKA-01": "REACHABLE",
      "REF-BDIX-01": "REACHABLE",
      "REF-INTL-SG": "REACHABLE"
    }
  }
}
```

---

## 30. Queue Files

### 30.1 Location

`/data/queue/pending-{sequence}.json`

### 30.2 Queue File Structure

```json
{
  "queue_id": "q-001",
  "queued_at": "2026-01-16T10:15:00+06:00",
  "retry_count": 0,
  "next_retry_at": "2026-01-16T10:16:00+06:00",
  "payload": {
    "submission": { ... },
    "agent_status": { ... },
    "speed_test": { ... },
    "ping_tests": [ ... ],
    "dns_test": { ... },
    "http_test": { ... },
    "traceroute_tests": [ ... ]
  }
}
```

---

## 31. Test Results Cache

### 31.1 Location

`/data/results/YYYY-MM-DD/HH-MM.json`

### 31.2 Purpose

- Local backup of test results
- Debug/troubleshooting reference
- Recovery after crash

---

## 32. Cached Config

### 32.1 Location

`/data/config/agent-config.json`

### 32.2 Purpose

- Cache of last successful config from Core
- Used when Core is unreachable at startup
- Includes config_serial for change detection

---

# PART X: LOGGING & OBSERVABILITY

---

## 33. Log Format Specification

### 33.1 JSON Log Structure

```json
{
  "timestamp": "2026-01-16T10:15:02.345+06:00",
  "level": "INFO",
  "logger": "qos_agent.submission",
  "message": "Submission successful",
  "context": {
    "submission_uuid": "770g0611-g41d-63f6-c938-668877662222",
    "tests_submitted": 8,
    "response_time_ms": 245
  }
}
```

### 33.2 Log Level Examples

**DEBUG**:
```json
{
  "timestamp": "2026-01-16T10:00:00.100+06:00",
  "level": "DEBUG",
  "logger": "qos_agent.speed_test",
  "message": "Starting speed test",
  "context": {
    "server_id": 12345,
    "method": "OOKLA_API"
  }
}
```

**INFO**:
```json
{
  "timestamp": "2026-01-16T10:00:45.500+06:00",
  "level": "INFO",
  "logger": "qos_agent.speed_test",
  "message": "Speed test completed",
  "context": {
    "download_mbps": 847.25,
    "upload_mbps": 423.50,
    "duration_ms": 32500,
    "status_flag": "PASS"
  }
}
```

**WARN**:
```json
{
  "timestamp": "2026-01-16T10:01:07.800+06:00",
  "level": "WARN",
  "logger": "qos_agent.ping_test",
  "message": "Elevated packet loss detected",
  "context": {
    "target": "INTERNATIONAL",
    "loss_pct": 2.0,
    "threshold_pct": 2.0
  }
}
```

**ERROR**:
```json
{
  "timestamp": "2026-01-16T10:15:01.000+06:00",
  "level": "ERROR",
  "logger": "qos_agent.submission",
  "message": "Submission failed, queuing locally",
  "context": {
    "error_code": "CONNECTION_TIMEOUT",
    "core_url": "https://qos-core.btrc.gov.bd",
    "retry_in_ms": 1000
  }
}
```

## B. Glossary

| Term | Definition |
|------|------------|
| **QOS_AGENT** | Active testing agent for QoS measurement |
| **Core** | Central BTRC monitoring system |
| **PoP** | Point of Presence - ISP network location |
| **NAT** | National target (domestic Bangladesh) |
| **IX** | Internet Exchange (BDIX) |
| **INTL** | International target |
| **RTT** | Round-Trip Time (latency) |
| **TTFB** | Time To First Byte |
| **Jitter** | Latency variation |

---

## C. Quick Reference Card

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                    QOS_AGENT QUICK REFERENCE                                 │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                              │
│  TEST INTERVAL:     15 minutes                                              │
│  SUBMISSION:        POST /api/v1/submissions/qos-measurements               │
│  CONFIG:            GET /api/v1/agent-qos/config                                │
│                                                                              │
│  TESTS:             Speed (1) + Ping (3) + DNS (1) + HTTP (1) + Trace (2)  │
│  TOTAL:             8 tests per cycle                                       │
│                                                                              │
│  STATUS FLAGS:      PASS | DEGRADED | FAIL                                  │
│  CONNECTIVITY:      FULL | PARTIAL | NONE                                   │
│                                                                              │
│  VOLUMES:           /config (bootstrap), /data (cache), /logs               │
│                                                                              │
│  LIVENESS:          Tracked via submissions (no heartbeat)                  │
│  RESILIENCE:        Store-and-forward when Core unreachable                │
│                                                                              │
└─────────────────────────────────────────────────────────────────────────────┘
```

---

**End of Document**
