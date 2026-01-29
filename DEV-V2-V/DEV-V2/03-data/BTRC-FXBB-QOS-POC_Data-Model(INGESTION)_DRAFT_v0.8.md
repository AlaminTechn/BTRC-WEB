# Input Data Types - BTRC QoS Monitoring System

| Metadata | Value |
|----------|-------|
| **Version** | 2.3 |
| **Created** | 2026-01-10 |
| **Updated** | 2026-01-15 |
| **Status** | IN PROGRESS |
| **Purpose** | Document data types for each input channel |

> **REVIEW NOTE (2026-01-11)**: Major revision to SNMP_AGENT section based on ToR alignment review. Changes include: combined submission structure, hybrid collection architecture, interface status fields, device type classification, vendor/MIB support, and simplified BRAS structure. See Changelog for details.

---

## Summary Table (Quick Reference)

| #  | Channel       | Data Types Collected                                   |
|----|---------------|--------------------------------------------------------|
| 1  | SNMP_AGENT    | Interface counters, bandwidth utilization, interface status, device health, subscriber counts (BRAS/RAS), interface type classification (INTERNET/CACHE/IX/DOWNSTREAM), upstream operator identification |
| 2  | QOS_AGENT     | Download/upload speed, latency, jitter, packet loss, availability, DNS resolution, HTTP response time |
| 3  | ISP_API       | Subscriber data, bandwidth data, incidents, complaints, revenue, PoP locations, packages, coverage (via Infrastructure/PoP) |
| 4  | USER_APP      | Speed tests, latency, jitter, packet loss, DNS/HTTP timing, GPS, connection type, feedback |
| 5  | REG_APP       | Field reports, issues, recommendations, GPS |

---

## Detailed Data Types by Channel

### 1. SNMP_AGENT

> **REVIEW NOTE (2026-01-11)**: Updated to reflect ToR compliance review. Added interface status, device type classification, vendor/MIB support, upstream operator field. Renamed traffic type to interface_type. Simplified BRAS structure (per-ISP aggregation only, geo mapping via ISP_API). Implemented hybrid collection architecture.

| Data Type | Description |
|-----------|-------------|
| Interface counters (bytes in/out) | Raw byte counts per interface (in_bps, out_bps) |
| Interface status | Admin/operational status (UP/DOWN) per ToR requirement |
| Interface errors | Error and discard counters (in_errors, out_errors, in_discards, out_discards) |
| Bandwidth utilization (%) | Percentage of capacity used (utilization_in_pct, utilization_out_pct) |
| Device type | Classification: CORE_GATEWAY, AGGREGATION_DEVICE, BRAS, RAS, OTHER |
| Vendor/MIB profile | Device vendor and MIB support (CISCO, JUNIPER, HUAWEI, etc.) |
| Interface type | Traffic classification: INTERNET, CACHE, IX, DOWNSTREAM |
| Upstream operator | Peering/upstream provider name (null for DOWNSTREAM) |
| Subscriber counts (BRAS/RAS) | Active subscriber sessions from BRAS/RAS devices |

#### 1.1 Combined SNMP Submission Structure

> **REVIEW NOTE (2026-01-11)**: Changed from separate interface-metrics and subscriber-counts endpoints to single combined submission. Implements hybrid collection architecture where one agent collects all target types with internal async workers.

**Endpoint**: `POST /api/v1/submissions/snmp-combined`
**Content-Type**: `application/json`
**Authentication**: API Key (`X-API-Key` header)

**Collection Architecture**: Hybrid (single agent, multiple internal workers)
- Interface metrics: 3 polls per 15-minute window (T+0, T+5, T+10)
- Subscriber counts: 1 poll per 15-minute window
- Each worker runs async with timeout isolation
- Partial submission allowed if some targets fail

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
    "public_ip_fetch_time": "2026-01-10T10:14:30+06:00",
    "container_id": "a1b2c3d4e5f6",
    "status": "ACTIVE",
    "status_message": "Operating normally",
    "last_heartbeat": "2026-01-10T10:14:00+06:00",
    "uptime_seconds": 864000
  },
  "target_status": [
    {
      "target_id": "t-001",
      "device_type": "CORE_GATEWAY",
      "target_ip": "10.0.1.1",
      "target_hostname": "core-rtr-01.dhk.isp142.net",
      "status": "HEALTHY",
      "polls_attempted": 3,
      "polls_successful": 3,
      "polls_failed": 0,
      "last_success_time": "2026-01-10T10:10:00+06:00",
      "last_failure_time": null,
      "consecutive_failures": 0
    },
    {
      "target_id": "t-002",
      "device_type": "AGGREGATION_DEVICE",
      "target_ip": "10.0.2.1",
      "target_hostname": "agg-sw-01.dhk.isp142.net",
      "status": "HEALTHY",
      "polls_attempted": 3,
      "polls_successful": 3,
      "polls_failed": 0,
      "last_success_time": "2026-01-10T10:10:00+06:00",
      "last_failure_time": null,
      "consecutive_failures": 0
    },
    {
      "target_id": "t-003",
      "device_type": "BRAS",
      "target_ip": "10.0.3.1",
      "target_hostname": "bras-01.dhk.isp142.net",
      "status": "HEALTHY",
      "polls_attempted": 1,
      "polls_successful": 1,
      "polls_failed": 0,
      "last_success_time": "2026-01-10T10:00:00+06:00",
      "last_failure_time": null,
      "consecutive_failures": 0
    },
    {
      "target_id": "t-004",
      "device_type": "RAS",
      "target_ip": "10.0.4.1",
      "target_hostname": "ras-01.dhk.isp142.net",
      "status": "DEGRADED",
      "polls_attempted": 1,
      "polls_successful": 0,
      "polls_failed": 1,
      "last_success_time": "2026-01-10T09:45:00+06:00",
      "last_failure_time": "2026-01-10T10:00:00+06:00",
      "consecutive_failures": 1,
      "failure_reason": "TIMEOUT"
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
        "target_id": "t-001",
        "device_type": "CORE_GATEWAY",
        "vendor": "CISCO",
        "mib_profile": "STANDARD",
        "target_ip": "10.0.1.1",
        "target_hostname": "core-rtr-01.dhk.isp142.net",
        "if_index": 12,
        "if_name": "GigabitEthernet0/0/1",
        "if_description": "Uplink to AAMRA Gateway",
        "if_speed_mbps": 1000
      },
      "poll_status": "SUCCESS",
      "poll_duration_ms": 145,
      "metrics": {
        "admin_status": "UP",
        "oper_status": "UP",
        "in_bps": 847523840,
        "out_bps": 125698560,
        "in_errors": 0,
        "out_errors": 0,
        "in_discards": 12,
        "out_discards": 0,
        "utilization_in_pct": 84.75,
        "utilization_out_pct": 12.57
      }
    },
    {
      "time": "2026-01-10T10:00:00+06:00",
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
        "target_hostname": "core-rtr-01.dhk.isp142.net",
        "if_index": 14,
        "if_name": "TenGigabitEthernet0/1/0",
        "if_description": "BDIX Peering Link",
        "if_speed_mbps": 10000
      },
      "poll_status": "SUCCESS",
      "poll_duration_ms": 156,
      "metrics": {
        "admin_status": "UP",
        "oper_status": "UP",
        "in_bps": 5368709120,
        "out_bps": 1073741824,
        "in_errors": 0,
        "out_errors": 0,
        "in_discards": 0,
        "out_discards": 0,
        "utilization_in_pct": 53.69,
        "utilization_out_pct": 10.74
      }
    },
    {
      "time": "2026-01-10T10:00:00+06:00",
      "poll_sequence": 1,
      "pop_id": 1523,
      "interface_type": "CACHE",
      "upstream_operator": "Google GGC",
      "snmp_target": {
        "target_id": "t-002",
        "device_type": "AGGREGATION_DEVICE",
        "vendor": "JUNIPER",
        "mib_profile": "STANDARD",
        "target_ip": "10.0.2.1",
        "target_hostname": "agg-sw-01.dhk.isp142.net",
        "if_index": 48,
        "if_name": "xe-0/0/47",
        "if_description": "Google GGC Cache Link",
        "if_speed_mbps": 10000
      },
      "poll_status": "SUCCESS",
      "poll_duration_ms": 132,
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
    },
    {
      "time": "2026-01-10T10:00:00+06:00",
      "poll_sequence": 1,
      "pop_id": 1523,
      "interface_type": "DOWNSTREAM",
      "upstream_operator": null,
      "snmp_target": {
        "target_id": "t-003",
        "device_type": "BRAS",
        "vendor": "HUAWEI",
        "mib_profile": "VENDOR_EXT",
        "target_ip": "10.0.3.1",
        "target_hostname": "bras-01.dhk.isp142.net",
        "if_index": 1,
        "if_name": "Eth-Trunk1",
        "if_description": "Subscriber Aggregation - Dhaka",
        "if_speed_mbps": 100000
      },
      "poll_status": "SUCCESS",
      "poll_duration_ms": 165,
      "metrics": {
        "admin_status": "UP",
        "oper_status": "UP",
        "in_bps": 12884901888,
        "out_bps": 64424509440,
        "in_errors": 0,
        "out_errors": 0,
        "in_discards": 145,
        "out_discards": 32,
        "utilization_in_pct": 12.88,
        "utilization_out_pct": 64.42
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
        "target_id": "t-003",
        "device_type": "BRAS",
        "vendor": "HUAWEI",
        "mib_profile": "VENDOR_EXT",
        "target_ip": "10.0.3.1",
        "target_hostname": "bras-01.dhk.isp142.net",
        "oid_active_sessions": ".1.3.6.1.4.1.2011.5.2.1.33.1.2.0",
        "oid_pppoe_sessions": ".1.3.6.1.4.1.2011.5.2.1.33.1.3.0"
      },
      "poll_status": "SUCCESS",
      "poll_duration_ms": 125,
      "metrics": {
        "active_sessions": 48750,
        "pppoe_sessions": 46892,
        "dhcp_leases": 1858,
        "ipoe_sessions": 0
      }
    },
    {
      "time": "2026-01-10T10:00:00+06:00",
      "bras_id": "BRAS-CTG-01",
      "bras_name": "Chittagong BRAS",
      "region": "Chittagong Division",
      "snmp_target": {
        "target_id": "t-005",
        "device_type": "BRAS",
        "vendor": "HUAWEI",
        "mib_profile": "VENDOR_EXT",
        "target_ip": "10.0.3.2",
        "target_hostname": "bras-02.ctg.isp142.net",
        "oid_active_sessions": ".1.3.6.1.4.1.2011.5.2.1.33.1.2.0",
        "oid_pppoe_sessions": ".1.3.6.1.4.1.2011.5.2.1.33.1.3.0"
      },
      "poll_status": "SUCCESS",
      "poll_duration_ms": 118,
      "metrics": {
        "active_sessions": 15420,
        "pppoe_sessions": 14850,
        "dhcp_leases": 570,
        "ipoe_sessions": 0
      }
    },
    {
      "time": "2026-01-10T10:00:00+06:00",
      "bras_id": "RAS-DHK-01",
      "bras_name": "Dhaka RAS Server",
      "region": "Dhaka Division",
      "snmp_target": {
        "target_id": "t-006",
        "device_type": "RAS",
        "vendor": "MIKROTIK",
        "mib_profile": "VENDOR_EXT",
        "target_ip": "10.0.4.1",
        "target_hostname": "ras-01.dhk.isp142.net",
        "oid_active_sessions": ".1.3.6.1.4.1.14988.1.1.5.1.0",
        "oid_pppoe_sessions": ".1.3.6.1.4.1.14988.1.1.5.2.0"
      },
      "poll_status": "TIMEOUT",
      "poll_duration_ms": 5000,
      "error": {
        "code": "SNMP_TIMEOUT",
        "message": "SNMP request timed out after 5000ms",
        "retries_attempted": 2
      },
      "metrics": null
    },
    {
      "time": "2026-01-10T10:00:00+06:00",
      "bras_id": "RAS-DHK-02",
      "bras_name": "Dhaka RAS Server 2",
      "region": "Dhaka Division",
      "snmp_target": {
        "target_id": "t-007",
        "device_type": "RAS",
        "vendor": "MIKROTIK",
        "mib_profile": "VENDOR_EXT",
        "target_ip": "10.0.4.2",
        "target_hostname": "ras-02.dhk.isp142.net",
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
  ]
}
```

#### 1.2 Field Specifications

> **REVIEW NOTE (2026-01-11)**: Updated to reflect combined submission structure. Added summary block, device_type, vendor, mib_profile, interface_type, upstream_operator, admin_status, oper_status. Removed is_counter_wrap (handled server-side).

**Submission Header**

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

**Submission Summary** *(NEW in v1.6)*

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| summary.interface_records | INTEGER | Yes | Count of interface metric records |
| summary.subscriber_records | INTEGER | Yes | Count of subscriber count records |
| summary.total_records | INTEGER | Yes | Total records in submission |
| summary.successful_polls | INTEGER | Yes | Count of successful polls |
| summary.failed_polls | INTEGER | Yes | Count of failed polls |
| summary.partial_submission | BOOLEAN | Yes | true if some workers failed/timed out |

**Agent Status**

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

**Target Status (per SNMP target)**

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| target_id | STRING | Yes | SNMP target reference (e.g., "t-001") |
| device_type | ENUM | Yes | CORE_GATEWAY / AGGREGATION_DEVICE / BRAS / RAS / OTHER *(NEW)* |
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

**Device Type Values** *(NEW in v1.6)*

| Code | Description | ToR Reference |
|------|-------------|---------------|
| CORE_GATEWAY | Core routers, internet gateway devices | Page 6, Line 217 |
| AGGREGATION_DEVICE | Aggregation switches/routers | Page 6, Line 217 |
| BRAS | Broadband Remote Access Server | Page 6, Line 217 |
| RAS | Remote Access Server | Operational extension |
| OTHER | Other monitored devices | Catch-all |

**Target Status Values**

| Status | Condition |
|--------|-----------|
| HEALTHY | All polls successful (polls_failed = 0) |
| DEGRADED | Some polls failed (0 < polls_failed < polls_attempted) |
| UNREACHABLE | All polls failed (polls_failed = polls_attempted) |

**SNMP Target (per interface_metrics record)**

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| target_id | STRING | Yes | Reference to snmp_targets (e.g., "t-001") |
| device_type | ENUM | Yes | CORE_GATEWAY / AGGREGATION_DEVICE / BRAS / RAS / OTHER *(NEW)* |
| vendor | ENUM | Yes | CISCO / JUNIPER / HUAWEI / MIKROTIK / BDCOM / OTHER *(NEW)* |
| mib_profile | ENUM | Yes | STANDARD / VENDOR_EXT *(NEW)* |
| target_ip | IP | Yes | Device management IP being polled |
| target_hostname | STRING | No | Device hostname |
| if_index | INTEGER | Yes | SNMP interface index |
| if_name | STRING | Yes | Interface name (ifName) |
| if_description | STRING | No | Interface description (ifDescr) |
| if_speed_mbps | INTEGER | Yes | Interface speed in Mbps |

**Vendor Values** *(NEW in v1.6)*

| Code | Description |
|------|-------------|
| CISCO | Cisco Systems devices |
| JUNIPER | Juniper Networks devices |
| HUAWEI | Huawei devices |
| MIKROTIK | MikroTik devices |
| BDCOM | BDCOM devices |
| OTHER | Other vendors |

**MIB Profile Values** *(NEW in v1.6)*

| Code | Description |
|------|-------------|
| STANDARD | Uses standard MIBs (IF-MIB, etc.) |
| VENDOR_EXT | Requires vendor-specific MIB extensions |

**Poll Status (per record)**

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| poll_sequence | INTEGER | Yes | Position in batch (1, 2, or 3) |
| poll_status | ENUM | Yes | SUCCESS / TIMEOUT / ERROR |
| poll_duration_ms | INTEGER | Yes | Time taken for SNMP request |
| error | OBJECT | No | Present only if poll_status != SUCCESS |
| error.code | STRING | Yes* | Error code (see Error Codes table) |
| error.message | STRING | Yes* | Human-readable error description |
| error.retries_attempted | INTEGER | Yes* | Number of retries before giving up |

**Poll Status Values**

| Status | Description |
|--------|-------------|
| SUCCESS | Poll completed, metrics available |
| TIMEOUT | SNMP request timed out (no response within threshold) |
| ERROR | SNMP error (auth failure, no such OID, network error, etc.) |

**Error Codes**

| Code | Description |
|------|-------------|
| SNMP_TIMEOUT | Request timed out |
| SNMP_NO_RESPONSE | No response from agent |
| SNMP_AUTH_FAILURE | Community string / SNMPv3 auth failed |
| SNMP_NO_SUCH_OID | Requested OID not found |
| SNMP_TOOBIG | Response too large |
| NETWORK_UNREACHABLE | Cannot reach target IP |
| CONNECTION_REFUSED | Target refused connection |

**Interface Metrics Record** *(NEW structure in v1.6)*

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| time | ISO8601 | Yes | Poll timestamp |
| poll_sequence | INTEGER | Yes | Position in batch (1, 2, or 3) |
| pop_id | INTEGER | Yes | PoP identifier |
| interface_type | ENUM | Yes | INTERNET / CACHE / IX / DOWNSTREAM *(renamed from upstream_type)* |
| upstream_operator | STRING | No | Peering/upstream provider name; null for DOWNSTREAM *(NEW)* |

**Metrics (per interface_metrics record)**

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| admin_status | ENUM | Yes* | UP / DOWN / TESTING *(NEW - ToR compliance)* |
| oper_status | ENUM | Yes* | UP / DOWN / DORMANT *(NEW - ToR compliance)* |
| in_bps | BIGINT | Yes* | Inbound bits per second |
| out_bps | BIGINT | Yes* | Outbound bits per second |
| in_errors | INTEGER | No | Inbound error count |
| out_errors | INTEGER | No | Outbound error count |
| in_discards | INTEGER | No | Inbound discards |
| out_discards | INTEGER | No | Outbound discards |
| utilization_in_pct | DECIMAL | Yes* | Inbound utilization % |
| utilization_out_pct | DECIMAL | Yes* | Outbound utilization % |

*Note: metrics is null if poll_status != SUCCESS

> **REVIEW NOTE (2026-01-11)**: Removed `is_counter_wrap` field. Counter wrap detection is now handled server-side during post-receive processing, not in agent payload.

#### 1.3 Interface Type Values

> **REVIEW NOTE (2026-01-11)**: Renamed from "Upstream Type" to "Interface Type". Changed BDIX to IX for generalization. Interface type is a provisioned label assigned at interface configuration time.

| Code | Name | Direction | Examples |
|------|------|-----------|----------|
| INTERNET | International Gateway | UPSTREAM | AAMRA, Novocom, Summit, Fiber@Home |
| IX | Internet Exchange Peering | UPSTREAM | BDIX, regional IXPs |
| CACHE | CDN/Cache Server | UPSTREAM | Google GGC, Facebook FNA, Akamai, Netflix OCA |
| DOWNSTREAM | Subscriber Facing | DOWNSTREAM | BRAS/RAS subscriber aggregation interfaces |

**Purpose**: Enables traffic ratio calculation (% Internet vs Cache vs IX) for regulatory analytics.

#### 1.4 Timing Parameters

| Parameter | Value |
|-----------|-------|
| Poll Interval | 5 minutes (300 sec) |
| Submission Interval | 15 minutes (900 sec) |
| Heartbeat Interval | 1 minute (60 sec) |
| Dedup Window | 24 hours |

#### 1.5 Core Public IP Service

Agent calls this API before each submission to get its public IP for audit trail.

**Endpoints** (agent-type specific):

| Agent Type | Endpoint |
|------------|----------|
| SNMP_AGENT | `GET /api/v1/agent-snmp/public-ip` |
| QOS_AGENT | `GET /api/v1/agent-qos/public-ip` |

**Response**:
```json
{
  "public_ip": "103.45.120.15",
  "asn": "AS17494",
  "isp_name": "BDCOM Online Limited"
}
```

**Purpose**: ISP identification, location verification, tamper detection

#### 1.5.1 Hybrid Collection Architecture

> **REVIEW NOTE (2026-01-11)**: New section documenting the hybrid collection approach for operational simplicity and efficiency.

**Architecture Decision**: Single agent with internal async workers (HYBRID approach)

**Why Hybrid?**

| Criteria | Separate Agents | Combined Agent | Hybrid (Chosen) |
|----------|-----------------|----------------|-----------------|
| Containers per ISP | 3-5 | 1 | 1 |
| API calls per 15-min | 3-5 | 1 | 1 |
| Fault isolation | Full | None | Internal |
| Partial submission | Yes | No | Yes |
| Operational complexity | High | Low | Low |

**Internal Worker Model**:

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

**Poll Cycle Flow**:

| Time | Action |
|------|--------|
| T+0:00 | Start poll cycle, launch all workers async |
| T+0:00 | Worker 1: Interface poll #1 |
| T+0:05 | Worker 1: Interface poll #2 |
| T+0:10 | Worker 1: Interface poll #3 |
| T+2:00 | All workers complete (or timeout) |
| T+2:05 | Assemble combined message |
| T+2:10 | Submit to BTRC API (single call) |

**Partial Submission Handling**:
- If Worker 1 (interfaces) times out but Workers 2/3 succeed → Submit with `partial_submission: true`
- Failed worker data included with `poll_status: TIMEOUT` and `metrics: null`
- Server-side processing handles missing data gracefully

**Benefits**:
1. **Operational Simplicity**: Single container to deploy, configure, monitor
2. **Network Efficiency**: Single API call, single TCP connection, single auth
3. **Data Correlation**: All data shares same time reference
4. **Fault Tolerance**: One slow target doesn't block others

---

#### 1.6 Subscriber Counts - Field Specifications

> **REVIEW NOTE (2026-01-11)**: Subscriber counts are now part of the combined submission (section 1.1, `subscriber_counts` array). The separate `/api/v1/submissions/subscriber-counts` endpoint is deprecated. BRAS structure simplified: removed PoP-level disaggregation (geo mapping via ISP_API only).

**Subscriber Counts Record** (within combined submission)

See section 1.1 for complete JSON example. Subscriber counts are in the `subscriber_counts` array.

**Simplified Example** (single record):
```json
{
  "time": "2026-01-10T10:00:00+06:00",
  "bras_id": "BRAS-DHK-01",
  "bras_name": "Dhaka Central BRAS",
  "region": "Dhaka Division",
  "snmp_target": {
    "target_id": "t-003",
    "device_type": "BRAS",
    "vendor": "HUAWEI",
    "mib_profile": "VENDOR_EXT",
    "target_ip": "10.0.3.1",
    "target_hostname": "bras-01.dhk.isp142.net",
    "oid_active_sessions": ".1.3.6.1.4.1.2011.5.2.1.33.1.2.0",
    "oid_pppoe_sessions": ".1.3.6.1.4.1.2011.5.2.1.33.1.3.0"
  },
  "poll_status": "SUCCESS",
  "poll_duration_ms": 125,
  "metrics": {
    "active_sessions": 48750,
    "pppoe_sessions": 46892,
    "dhcp_leases": 1858,
    "ipoe_sessions": 0
  }
}
```

#### 1.7 Subscriber Counts - Field Specifications

> **REVIEW NOTE (2026-01-11)**: Simplified structure. Removed: bras_topology, pops_served, coverage object, disaggregation fields. BRAS aggregation is per-ISP only. Subscriber geo mapping is via ISP_API (Section 3.2), not SNMP_AGENT.

**Subscriber Counts Record**

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| time | ISO8601 | Yes | Poll timestamp |
| bras_id | STRING | Yes | Unique BRAS/RAS identifier |
| bras_name | STRING | Yes | Human-readable name |
| region | STRING | Yes | Geographic region (general location) |
| poll_status | ENUM | Yes | SUCCESS / TIMEOUT / ERROR |
| poll_duration_ms | INTEGER | Yes | Poll duration in ms |

**SNMP Target (per subscriber_counts record)**

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| target_id | STRING | Yes | SNMP target reference (e.g., "t-001") |
| device_type | ENUM | Yes | BRAS / RAS |
| vendor | ENUM | Yes | CISCO / JUNIPER / HUAWEI / MIKROTIK / BDCOM / OTHER |
| mib_profile | ENUM | Yes | STANDARD / VENDOR_EXT |
| target_ip | IP | Yes | Device management IP |
| target_hostname | STRING | No | Device hostname |
| oid_active_sessions | STRING | Yes | OID for active session count |
| oid_pppoe_sessions | STRING | No | OID for PPPoE sessions |

**Subscriber Metrics**

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| active_sessions | INTEGER | Yes* | Total active subscriber sessions |
| pppoe_sessions | INTEGER | No | PPPoE session count |
| dhcp_leases | INTEGER | No | DHCP lease count |
| ipoe_sessions | INTEGER | No | IPoE session count |

*Note: metrics is null if poll_status != SUCCESS

**DEPRECATED Fields** *(Removed in v1.6)*

| Removed Field | Reason | Alternative |
|---------------|--------|-------------|
| bras_topology | Simplified structure | Use target_status array |
| pops_served | No PoP-level disaggregation | ISP_API Section 3.2 |
| deployment_model | Simplified | Not needed for per-ISP aggregation |
| coverage.pop_ids | No PoP breakdown | ISP_API Section 3.2 |
| can_disaggregate | Removed | N/A |
| disaggregation_available | Removed | N/A |

**Metrics (per record)**

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| active_sessions | INTEGER | Yes* | Active subscriber session count |
| pppoe_sessions | INTEGER | No | PPPoE session count (null if N/A) |
| dhcp_leases | INTEGER | No | DHCP lease count (null if N/A) |

*Note: metrics is null if poll_status != SUCCESS

**Source Types**

| Type | Description |
|------|-------------|
| BRAS | Broadband Remote Access Server (PPPoE sessions via SNMP) |
| RADIUS | RADIUS server (active sessions via API/SNMP) |
| BILLING | Billing system (active accounts via DB query) |
| SNMP_MIB | Custom/Enterprise MIB polling |

**Query Methods**

| Method | Description |
|--------|-------------|
| SNMP | SNMP polling (standard or enterprise MIB) |
| API | REST API call to target system |
| DB_QUERY | Direct database query (PostgreSQL, MySQL, etc.) |

**Error Codes (Subscriber Counts)**

| Code | Description |
|------|-------------|
| SNMP_TIMEOUT | SNMP request timed out |
| SNMP_AUTH_FAILURE | SNMP authentication failed |
| SNMP_NO_SUCH_OID | OID not found on device |
| API_TIMEOUT | API request timed out |
| API_AUTH_FAILURE | API authentication failed |
| API_ERROR | API returned error response |
| DB_QUERY_TIMEOUT | Database query timed out |
| DB_CONNECTION_FAILED | Cannot connect to database |
| DB_AUTH_FAILURE | Database authentication failed |
| NETWORK_UNREACHABLE | Cannot reach target |

#### 1.8 Subscriber Counts - Timing Parameters

| Parameter | Value |
|-----------|-------|
| Poll Interval | 15 minutes (900 sec) |
| Submission Interval | 15 minutes (900 sec) |
| Records per Submission | 1 per BRAS device |

#### 1.9 Responsibility Separation

> **REVIEW NOTE (2026-01-11)**: Updated to reflect simplified per-ISP aggregation model. Removed PoP-level references. Geographic mapping is via ISP_API only.

**Agent Responsibility** (SNMP_AGENT)
- Poll BRAS/RAS devices via SNMP
- Report raw session counts per device
- Report device status (healthy/degraded/unreachable)
- Report poll status and errors
- Submit combined interface + subscriber data

**Core/Server Responsibility**
- Aggregate totals across all ISP BRAS/RAS devices
- Compute ISP-level subscriber totals
- Compare against ISP-reported subscriber counts (ISP_API Section 3.2)
- Calculate variance and trigger compliance alerts
- Perform geographic analysis using PoP data from ISP_API (Section 3.4)
- Handle counter wrap detection and data normalization

---

### 2. QOS_AGENT

> **REVISION NOTE (2026-01-11)**: Major revision based on ToR alignment review and optimization. Changes include: single speed test target (configurable, Speedtest API preferred), max 3 ping targets (National/IX/International), weighted HTTP scoring, hybrid detection architecture (Agent detects failures, Core applies thresholds), removed agent-side availability calculation.

| Data Type | Description |
|-----------|-------------|
| Download speed (Mbps) | Downstream throughput from single configured server |
| Upload speed (Mbps) | Upstream throughput from single configured server |
| Latency (ms) | Round-trip time to 3 targets (National, IX, International) |
| Jitter (ms) | Latency variation derived from ICMP RTT variance |
| Packet loss (%) | Lost packets percentage per ping target |
| DNS resolution time (ms) | Query response time for .bd and international domains |
| HTTP reachability score | Weighted pass/fail score (100-point scale) |
| HTTP response time (ms) | TTFB and total time per URL with weighted average |
| Traceroute hop count | Path completion and hop count to National/International targets |

#### 2.1 QoS Measurements - JSON Submission Structure

**Endpoint**: `POST /api/v1/submissions/qos-measurements`
**Content-Type**: `application/json`
**Authentication**: API Key (`X-API-Key` header)

**Polling Strategy**: All tests run every 15 minutes per ToR Section 3.8 (minimum data polling resolution)

**Test Categories**:

| # | Test Type | Targets | Metrics Derived | Config Source |
|---|-----------|---------|-----------------|---------------|
| 1 | Speed Test | 1 (single server) | Download/Upload Mbps | Configurable (Speedtest API preferred) |
| 2 | Ping Test | Max 3 (NAT/IX/INTL) | RTT, Jitter, Packet Loss (100 pkts each) | Agent config |
| 3 | DNS Test | Min 2 (.bd + international) | Resolution time, success rate | Agent config |
| 4 | HTTP Test | 4-5 URLs | Weighted reachability score, response time | Agent config with weights (total=100) |
| 5 | Traceroute | 2 (NAT + INTL) | Hop count, path completion | Agent config |

**Target Type Definitions**:
| Type | Abbreviation | Description |
|------|--------------|-------------|
| NATIONAL | NAT | Domestic reference server within Bangladesh |
| IX | IX | BDIX Internet Exchange peering point |
| INTERNATIONAL | INTL | Overseas reference server (e.g., Singapore) |
| LOCAL_BD | .bd | Bangladesh domain for DNS testing |

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
    "public_ip_source": "CORE_API",
    "public_ip_fetch_time": "2026-01-10T10:14:30+06:00",
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
    "test_uuid": "st-001-2026011010000",
    "time": "2026-01-10T10:00:00+06:00",
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
    "test_method": "OOKLA_API"
  },
  "ping_tests": [
    {
      "test_uuid": "ping-001-2026011010000",
      "time": "2026-01-10T10:00:45+06:00",
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
      "test_duration_ms": 10500
    },
    {
      "test_uuid": "ping-002-2026011010000",
      "time": "2026-01-10T10:00:56+06:00",
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
      "test_duration_ms": 10200
    },
    {
      "test_uuid": "ping-003-2026011010000",
      "time": "2026-01-10T10:01:07+06:00",
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
      "test_duration_ms": 12800
    }
  ],
  "dns_test": {
    "test_uuid": "dns-001-2026011010000",
    "time": "2026-01-10T10:01:20+06:00",
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
    "test_duration_ms": 250
  },
  "http_test": {
    "test_uuid": "http-001-2026011010000",
    "time": "2026-01-10T10:01:22+06:00",
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
    "test_duration_ms": 1850
  },
  "traceroute_tests": [
    {
      "test_uuid": "tr-001-2026011010000",
      "time": "2026-01-10T10:01:25+06:00",
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
      }
    },
    {
      "test_uuid": "tr-002-2026011010000",
      "time": "2026-01-10T10:01:35+06:00",
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
      }
    }
  ]
  // Note: Service Availability is calculated by Core from test results
  // Agent submits raw test data; Core applies threshold-based degradation detection
}
```

#### 2.2 Field Specifications

**Submission Header**

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

**Test Summary**

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| speed_tests | INTEGER | Yes | Speed tests in submission |
| ping_tests | INTEGER | Yes | Ping tests (latency+loss) |
| dns_tests | INTEGER | Yes | DNS tests count |
| http_tests | INTEGER | Yes | HTTP tests count |
| traceroute_tests | INTEGER | Yes | Traceroute tests count |
| total_tests | INTEGER | Yes | Sum of all tests |
| successful_tests | INTEGER | Yes | Tests completed successfully |
| failed_tests | INTEGER | Yes | Tests that failed |

**Agent Status**

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| host_ip | IP | Yes | Private/LAN IP of agent host |
| public_ip | IP | Yes | NAT/Public IP (from core API) |
| public_ip_source | ENUM | Yes | CORE_API / EXTERNAL / STATIC |
| public_ip_fetch_time | ISO8601 | Yes | When public IP was resolved |
| status | ENUM | Yes | ACTIVE / INACTIVE / ERROR |
| cpu_usage_pct | DECIMAL | No | CPU utilization |
| memory_usage_pct | DECIMAL | No | Memory utilization |
| disk_usage_pct | DECIMAL | No | Disk utilization |
| uptime_seconds | INTEGER | No | Agent uptime |
| last_calibration | ISO8601 | No | Last calibration timestamp |

**Agent Detected Failures** (NEW - Hybrid Detection)

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| has_failures | BOOLEAN | Yes | True if any obvious failures detected |
| connectivity_status | ENUM | Yes | FULL / PARTIAL / NONE |
| failure_count | INTEGER | Yes | Number of failures detected |
| failures | ARRAY | Yes | List of failure objects |
| tests_impacted | ARRAY | Yes | Test types affected by failures |
| servers_affected | ARRAY | Yes | List of unreachable server identifiers |

**Failure Object**

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| failure_type | ENUM | Yes | TIMEOUT / CONNECTION_REFUSED / DNS_FAILURE / COMPLETE_LOSS / SERVER_UNREACHABLE |
| test_type | ENUM | Yes | SPEED / PING / DNS / HTTP / TRACEROUTE |
| target | STRING | Yes | Target IP/domain that failed |
| error_code | STRING | Yes | QOS-Exxxx error code |
| error_message | STRING | Yes | Human-readable error |
| detected_at | ISO8601 | Yes | When failure was detected |

**Target Types** (Updated)

| Type | Description |
|------|-------------|
| NATIONAL | Domestic Bangladesh reference server |
| IX | BDIX peering point server |
| INTERNATIONAL | International reference (Singapore, etc.) |
| LOCAL_BD | .bd domain (for DNS tests) |

**Reference Server Types**

| Type | Description |
|------|-------------|
| PRIMARY | BTRC-hosted reference server (domestic) |
| PEERING | BDIX peering point server |
| INTERNATIONAL | International reference (Singapore, etc.) |
| CACHE | CDN/Cache reference server |

#### 2.3 Speed Test Specifications

**Speed Test Metrics**

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| speed_mbps | DECIMAL | Yes | Measured speed in Mbps |
| bytes_transferred | BIGINT | Yes | Total bytes transferred |
| duration_ms | INTEGER | Yes | Test duration |
| streams | INTEGER | Yes | Parallel TCP streams used |
| consistency_pct | DECIMAL | Yes | Throughput stability (0-100%) |

**Test Methods**

| Method | Description |
|--------|-------------|
| OOKLA_API | Speedtest.net API (preferred method) |
| IPERF3 | iPerf3 multi-stream TCP/UDP test |
| HTTP_DOWNLOAD | HTTP GET with large file |
| HTTP_UPLOAD | HTTP POST with large payload |

#### 2.4 Ping Test Specifications (Combined Latency + Packet Loss)

**Test Configuration**

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| packet_count | INTEGER | Yes | Number of ICMP packets sent |
| packet_size_bytes | INTEGER | Yes | Payload size (typically 64) |
| interval_ms | INTEGER | Yes | Delay between packets |
| timeout_ms | INTEGER | Yes | Wait time for response |
| protocol | ENUM | Yes | ICMP / TCP (for firewall cases) |

**Latency Metrics (derived from ping)**

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| rtt_min_ms | DECIMAL | Yes | Minimum round-trip time |
| rtt_max_ms | DECIMAL | Yes | Maximum round-trip time |
| rtt_avg_ms | DECIMAL | Yes | Average round-trip time |
| rtt_median_ms | DECIMAL | Yes | Median (P50) RTT |
| rtt_stddev_ms | DECIMAL | Yes | Standard deviation |
| rtt_p95_ms | DECIMAL | Yes | 95th percentile RTT |
| rtt_p99_ms | DECIMAL | Yes | 99th percentile RTT |
| jitter_ms | DECIMAL | Yes | Inter-packet delay variation |

**Packet Loss Metrics (derived from ping)**

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| packets_sent | INTEGER | Yes | Total packets transmitted |
| packets_received | INTEGER | Yes | Packets with valid response |
| packets_lost | INTEGER | Yes | Packets with no response |
| loss_pct | DECIMAL | Yes | Loss percentage |
| loss_pattern | ENUM | Yes | NONE/RANDOM/BURST/PERIODIC |
| out_of_order | INTEGER | Yes | Packets received out of sequence |
| duplicates | INTEGER | Yes | Duplicate responses received |

#### 2.5 DNS Test Specifications

**DNS Server Types**

| Type | Description |
|------|-------------|
| ISP | ISP-provided DNS server |
| PUBLIC | Public DNS (Google, Cloudflare) |
| LOCAL | Local/regional DNS |

**DNS Response Codes**

| Code | Description |
|------|-------------|
| NOERROR | Successful resolution |
| NXDOMAIN | Domain does not exist |
| SERVFAIL | Server failure |
| REFUSED | Query refused |
| TIMEOUT | No response |

#### 2.6 HTTP Test Specifications

**HTTP Timing Breakdown**

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| dns_lookup_ms | DECIMAL | Yes | DNS resolution time |
| tcp_connect_ms | DECIMAL | Yes | TCP connection time |
| ssl_handshake_ms | DECIMAL | No | TLS negotiation (HTTPS only) |
| ttfb_ms | DECIMAL | Yes | Time to first byte |
| content_download_ms | DECIMAL | Yes | Content transfer time |
| total_time_ms | DECIMAL | Yes | Total request time |

**HTTP Weighted Scoring** (NEW - ToR Aligned)

Agent reports both reachability and response time per ToR requirements (Sections 3.4.7, 3.4.8).

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| weight | INTEGER | Yes | URL weight (1-100), total across all URLs = 100 |
| reachable | BOOLEAN | Yes | True if HTTP 2xx/3xx received |
| status_code | INTEGER | Yes | HTTP response status code |

**Reachability Score Summary**

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| score | DECIMAL | Yes | Sum of weights for reachable URLs |
| max_score | INTEGER | Yes | Always 100 |
| percentage | DECIMAL | Yes | (score / max_score) * 100 |
| urls_reachable | INTEGER | Yes | Count of reachable URLs |
| urls_total | INTEGER | Yes | Total URLs tested |

**Response Time Summary**

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| weighted_avg_ms | DECIMAL | Yes | Weighted average response time |
| min_ms | DECIMAL | Yes | Fastest response |
| max_ms | DECIMAL | Yes | Slowest response |

#### 2.7 Traceroute Specifications

**Hop Data**

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| hop | INTEGER | Yes | Hop number (1-based) |
| ip | IP | Yes | Router IP at this hop |
| hostname | STRING | No | Reverse DNS hostname |
| rtt_ms | DECIMAL | Yes | RTT to this hop |

**Traceroute Summary**

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| hop_count | INTEGER | Yes | Total hops to destination |
| total_rtt_ms | DECIMAL | Yes | Final hop RTT |
| path_complete | BOOLEAN | Yes | Reached destination |

#### 2.8 Timing Parameters

| Parameter | Value | Notes |
|-----------|-------|-------|
| Test Interval | 15 minutes | All tests run every 15 min (PRD NFR-1.2) |
| Submission Interval | 15 minutes | One batch per window |
| Speed Test Duration | ~30-45 sec | Multi-stream TCP test |
| Ping Samples | 100 packets | Per target server |
| Ping Interval | 100 ms | Between packets |
| Ping Targets | Max 3 | NATIONAL, IX, INTERNATIONAL |
| DNS Domains | Min 2 | LOCAL_BD (.bd) + INTERNATIONAL |
| HTTP URLs | 4-5 | Weighted scoring (total weight = 100) |
| Traceroute Targets | 2 | NATIONAL + INTERNATIONAL |

**Test Schedule Within 15-Min Window**

| Time | Activity |
|------|----------|
| T+0:00 | Speed Test Start |
| T+0:45 | Speed Test Complete |
| T+0:45 | Ping Tests Start (3 targets) |
| T+1:15 | Ping Tests Complete |
| T+1:15 | DNS Tests Start |
| T+1:20 | DNS Tests Complete |
| T+1:20 | HTTP Tests Start |
| T+1:25 | HTTP Tests Complete |
| T+1:25 | Traceroute Start |
| T+1:40 | Traceroute Complete |
| T+14:00 | Prepare Submission |
| T+15:00 | Submit to Core + Start Next Cycle |

#### 2.9 Responsibility Separation

**Agent Responsibility**
- Execute active measurement tests
- Report raw metrics per test
- Report test status/errors
- Maintain reference server connectivity
- Agent health monitoring

**Core Responsibility**
- Aggregate metrics across time periods
- Compare against SLA thresholds
- Calculate compliance percentages
- Generate alerts for threshold breaches
- Correlate with SNMP_AGENT data
- Calculate service availability from test results


### 3. ISP_API

ISP self-reported operational data submitted via authenticated API endpoints.

**Trust Level**: 70 (validated against agent-collected data)
**Submission Methods**: REST API, Bulk CSV Upload, Web Portal
**Authentication**: OAuth 2.0 + API Key

| Category | Data Type | Frequency | Core Validation | POC Scope |
|----------|-----------|-----------|-----------------|-----------|
| 3.1 | Package Definitions | Monthly | Cross-reference with subscriber claims | ✓ |
| 3.2 | Subscriber Data | Monthly | Compare with SNMP_AGENT counts | ✓ |
| 3.3 | Bandwidth Data | Monthly | Compare with SNMP_AGENT utilization | → 3.4 |
| 3.4 | Infrastructure (PoP) + Bandwidth | Monthly | Verify agent deployment | ✓ |
| 3.5 | Incident Data | Weekly/Monthly | Correlate with QOS_AGENT outages | ⚠ (optional) |
| 3.6 | Complaint Data | Monthly | Cross-validate with USER_APP feedback | ⚠ (optional) |
| 3.7 | Subscriber Revenue | Monthly | Verify: Cat 1 × Cat 2 = Cat 7 | ✓ |

> **POC SCOPE NOTE (2026-01-17, Updated)**: For POC, categories 3.1, 3.2, 3.4 (with bandwidth), and 3.7 are in scope. Categories 3.5 (Incidents) and 3.6 (Complaints) are **OPTIONAL** for POC - scheduled for end of POC phase with simplified single-line submission format. Full-featured incident/complaint management (timeline tracking, PoP correlation, MTTR analytics) is Phase 2 scope. Bandwidth data (3.3) is merged into POP (3.4). Location can be specified via `bbs_code` OR text fields (division/district/upazila) - system maps text to BBS code. All frequencies are Monthly.

---

#### 3.1 Package Definitions - JSON Submission Structure

**Endpoint**: `POST /api/v1/isp/{isp_id}/packages`
**Content-Type**: `application/json`
**Authentication**: OAuth 2.0 Bearer Token
**Submission Frequency**: Monthly (snapshot of all active/discontinued packages)

```json
{
  "period": "2026-01",
  "packages": [
    {
      "package_code": "PKG-HOME-100",
      "package_name": "Home Fiber 100",
      "package_type": "RESIDENTIAL",
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
      "status": "active",
      "subscriber_count": 12000
    },
    {
      "package_code": "PKG-HOME-50",
      "package_name": "Home Fiber 50",
      "package_type": "RESIDENTIAL",
      "download_speed_mbps": 50,
      "upload_speed_mbps": 25,
      "mir_mbps": 50,
      "cir_mbps": 25,
      "price_bdt": 800.00,
      "data_cap_gb": null,
      "has_fup": true,
      "fup_threshold_gb": 300,
      "fup_speed_mbps": 5,
      "contract_months": 12,
      "installation_fee_bdt": 0,
      "status": "active",
      "subscriber_count": 25000
    },
    {
      "package_code": "PKG-BIZ-200",
      "package_name": "Business Fiber 200",
      "package_type": "CORPORATE",
      "download_speed_mbps": 200,
      "upload_speed_mbps": 200,
      "mir_mbps": 200,
      "cir_mbps": 180,
      "price_bdt": 5000.00,
      "data_cap_gb": null,
      "has_fup": false,
      "fup_threshold_gb": null,
      "fup_speed_mbps": null,
      "contract_months": 12,
      "installation_fee_bdt": 0,
      "status": "active",
      "subscriber_count": 800
    },
    {
      "package_code": "PKG-HOME-30",
      "package_name": "Home Basic 30",
      "package_type": "RESIDENTIAL",
      "download_speed_mbps": 30,
      "upload_speed_mbps": 15,
      "mir_mbps": 30,
      "cir_mbps": 15,
      "price_bdt": 500.00,
      "data_cap_gb": 150,
      "has_fup": true,
      "fup_threshold_gb": 150,
      "fup_speed_mbps": 2,
      "contract_months": 6,
      "installation_fee_bdt": 500,
      "status": "discontinued",
      "subscriber_count": 0
    }
  ]
}
```

#### 3.1.1 Package Field Specifications (POC)

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| package_code | STRING | Yes | ISP's internal package identifier |
| package_name | STRING | Yes | Display name |
| package_type | ENUM | Yes | RESIDENTIAL, CORPORATE |
| download_speed_mbps | INTEGER | Yes | Advertised download speed |
| upload_speed_mbps | INTEGER | Yes | Advertised upload speed |
| mir_mbps | INTEGER | Yes | Maximum Information Rate |
| cir_mbps | INTEGER | Yes | Committed Information Rate |
| price_bdt | DECIMAL | Yes | Monthly price (BDT) |
| data_cap_gb | INTEGER | No | Data cap in GB (null = unlimited) |
| has_fup | BOOLEAN | Yes | Fair Usage Policy applies? |
| fup_threshold_gb | INTEGER | No | FUP trigger threshold |
| fup_speed_mbps | INTEGER | No | Speed after FUP triggered |
| contract_months | INTEGER | No | Minimum contract period |
| installation_fee_bdt | DECIMAL | No | One-time installation fee |
| status | ENUM | Yes | active, discontinued |
| subscriber_count | INTEGER | No | Current subscriber count for this package |

#### 3.1.2 Ingestion Layer Notes

| API Field | DB Mapping | Logic |
|-----------|------------|-------|
| `status` | `packages.is_active` | `active` → `true`, `discontinued` → `false` |
| `package_code` | `packages.code` | Stored with `isp_id` to ensure uniqueness per ISP |

---

#### 3.2 Subscriber Data - JSON Submission Structure

**Endpoint**: `POST /api/v1/isp/{isp_id}/subscribers`
**Content-Type**: `application/json`
**Authentication**: OAuth 2.0 Bearer Token
**Submission Frequency**: Monthly (by 10th of following month)

> **POC Structure**: Subscribers are reported as Package × Location matrix. Location can be specified via `bbs_code` OR text fields (see Section 3.4.2).

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
    },
    {
      "package_code": "PKG-HOME-50",
      "location": {
        "bbs_code": "302614"
      },
      "current_count": 4120,
      "new_count": 156,
      "churned_count": 78
    },
    {
      "package_code": "PKG-BIZ-200",
      "location": {
        "bbs_code": "200102"
      },
      "current_count": 420,
      "new_count": 15,
      "churned_count": 8
    }
  ]
}
```

#### 3.2.1 Subscriber Field Specifications (POC)

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| package_code | STRING | Yes | Reference to Package |
| location | OBJECT | Yes | Location reference (see Section 3.4.2) |
| current_count | INTEGER | Yes | Total active subscribers (snapshot) |
| new_count | INTEGER | Yes | New subscribers added this month |
| churned_count | INTEGER | Yes | Subscribers removed this month |

#### 3.2.2 Ingestion Layer Notes

| API Field | DB Mapping | Logic |
|-----------|------------|-------|
| `package_code` | `subscriber_snapshots.package_id` | Lookup by `(isp_id, package_code)` → `packages.id` |
| `location` | `subscriber_snapshots.district_id` | Parse `bbs_code` OR lookup text fields → FK |

> **📋 REVIEW NOTE (2026-01-12)**: Geo structure columns (upazila_id, thana_id) in `subscriber_snapshots` deferred for later decision. Current schema has `district_id` only.

#### 3.2.3 Data Source Separation

| Source | Table | Use Case |
|--------|-------|----------|
| ISP_API (Monthly) | `subscriber_snapshots` | Revenue calculation, compliance reporting |
| SNMP_AGENT (Real-time) | `ts_subscriber_counts` | Time-series dashboards, trend analysis |

**Cross-Validation**: Compare ISP `current_count` vs SUM(BRAS `active_sessions`). Variance >10% triggers investigation alert.

---

#### 3.3 Bandwidth Data - JSON Submission Structure

> **POC STATUS: MERGED INTO POP (3.4)** - Bandwidth data (international, IX, cache) is now included as attributes in the POP submission (Section 3.4). The detailed per-provider breakdown structure below is retained for future implementation if granular bandwidth tracking is required.

**Endpoint**: `POST /api/v1/isp/bandwidth`
**Content-Type**: `application/json`
**Authentication**: OAuth 2.0 Bearer Token
**Submission Frequency**: Monthly (by 10th of following month)

```json
{
  "submission": {
    "submission_uuid": "aa2j3944-j74g-96i9-f261-991100995555",
    "isp_id": 142,
    "isp_name": "Example ISP Ltd.",
    "submission_time": "2026-02-05T10:00:00+06:00",
    "reporting_period": "2026-01",
    "reporting_period_start": "2026-01-01",
    "reporting_period_end": "2026-01-31"
  },
  "isp_totals": {
    "international_gbps": 42.5,
    "ix_gbps": 25.0,
    "cache_gbps": 35.0,
    "total_upstream_gbps": 102.5
  },
  "international": {
    "by_provider": [
      {
        "provider_name": "AAMRA Networks",
        "provider_type": "IIG",
        "contracted_gbps": 25.0,
        "provisioned_gbps": 22.5,
        "peak_utilization_pct": 78.5,
        "avg_utilization_pct": 52.3,
        "p95_utilization_pct": 72.1
      },
      {
        "provider_name": "Summit Communications",
        "provider_type": "IIG",
        "contracted_gbps": 20.0,
        "provisioned_gbps": 20.0,
        "peak_utilization_pct": 82.1,
        "avg_utilization_pct": 58.7,
        "p95_utilization_pct": 76.4
      }
    ],
    "total": {
      "contracted_gbps": 45.0,
      "provisioned_gbps": 42.5,
      "peak_utilization_pct": 80.3,
      "avg_utilization_pct": 55.5
    }
  },
  "ix": {
    "by_provider": [
      {
        "provider_name": "BDIX",
        "provider_type": "IXP",
        "contracted_gbps": 15.0,
        "provisioned_gbps": 15.0,
        "peak_utilization_pct": 65.2,
        "avg_utilization_pct": 42.8,
        "p95_utilization_pct": 58.9
      },
      {
        "provider_name": "NIX",
        "provider_type": "IXP",
        "contracted_gbps": 10.0,
        "provisioned_gbps": 10.0,
        "peak_utilization_pct": 58.4,
        "avg_utilization_pct": 38.2,
        "p95_utilization_pct": 52.6
      }
    ],
    "total": {
      "contracted_gbps": 25.0,
      "provisioned_gbps": 25.0,
      "peak_utilization_pct": 61.8,
      "avg_utilization_pct": 40.5
    }
  },
  "cache": {
    "_note": "Total capacity only - individual CDN details not required",
    "total_provisioned_gbps": 35.0,
    "providers_count": 5
  },
  "by_pop": [
    {
      "pop_id": 1523,
      "pop_code": "DHK-GULSHAN",
      "international": {
        "provisioned_gbps": 12.0,
        "peak_utilization_pct": 75.2,
        "avg_utilization_pct": 48.5
      },
      "ix": {
        "provisioned_gbps": 8.0,
        "peak_utilization_pct": 62.1,
        "avg_utilization_pct": 38.7
      },
      "cache": {
        "provisioned_gbps": 10.0
      }
    },
    {
      "pop_id": 1524,
      "pop_code": "DHK-BANANI",
      "international": {
        "provisioned_gbps": 8.0,
        "peak_utilization_pct": 82.5,
        "avg_utilization_pct": 55.2
      },
      "ix": {
        "provisioned_gbps": 5.0,
        "peak_utilization_pct": 68.4,
        "avg_utilization_pct": 42.1
      },
      "cache": {
        "provisioned_gbps": 8.0
      }
    },
    {
      "pop_id": 1601,
      "pop_code": "CTG-AGRABAD",
      "international": {
        "provisioned_gbps": 10.5,
        "peak_utilization_pct": 78.9,
        "avg_utilization_pct": 52.8
      },
      "ix": {
        "provisioned_gbps": 6.0,
        "peak_utilization_pct": 58.2,
        "avg_utilization_pct": 35.4
      },
      "cache": {
        "provisioned_gbps": 8.0
      }
    }
  ]
}
```

#### 3.3.1 Bandwidth Type Definitions

| Type | Description |
|------|-------------|
| INTERNATIONAL | Bandwidth from IIG providers (international gateway) |
| IX | Bandwidth from Internet Exchange Points (BDIX, NIX) |
| CACHE | Total CDN/Cache capacity (aggregated) |

#### 3.3.2 Utilization Metrics

| Metric | Description |
|--------|-------------|
| contracted_gbps | Contracted/purchased capacity |
| provisioned_gbps | Actually provisioned/installed |
| peak_utilization_pct | Maximum utilization during period |
| avg_utilization_pct | Average utilization during period |
| p95_utilization_pct | 95th percentile utilization |

---

#### 3.4 Infrastructure (PoP Data) - JSON Submission Structure

**Endpoint**: `POST /api/v1/isp/{isp_id}/pops`
**Content-Type**: `application/json`
**Authentication**: OAuth 2.0 Bearer Token
**Submission Frequency**: Monthly (snapshot)

> **POC Structure**: POPs are reported as aggregate count per location. Includes bandwidth data per ToR 3.2.2. Location can be specified via `bbs_code` OR text fields (system maps to BBS code).

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
    },
    {
      "location": {
        "bbs_code": null,
        "division": "Dhaka",
        "district": "Dhaka",
        "upazila": "Banani"
      },
      "pop_count": 2,
      "pop_type": "access",
      "status": "active",
      "upstream_capacity_mbps": 5000,
      "bandwidth": {
        "international_mbps": 3000,
        "ix_mbps": 1500,
        "cache_mbps": 500
      }
    },
    {
      "location": {
        "bbs_code": "200102"
      },
      "pop_count": 1,
      "pop_type": "core",
      "status": "active",
      "upstream_capacity_mbps": 20000,
      "bandwidth": {
        "international_mbps": 15000,
        "ix_mbps": 5000,
        "cache_mbps": 0
      }
    }
  ]
}
```

#### 3.4.1 PoP Field Specifications (POC)

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| location | OBJECT | Yes | Location reference (see 3.4.2) |
| pop_count | INTEGER | Yes | Number of POPs at this location |
| pop_type | ENUM | Yes | core, distribution, access |
| status | ENUM | Yes | active, inactive |
| upstream_capacity_mbps | INTEGER | Yes | Total upstream capacity at this location |
| bandwidth.international_mbps | INTEGER | Yes | International gateway bandwidth (IIG) |
| bandwidth.ix_mbps | INTEGER | Yes | Internet Exchange bandwidth (BDIX, NIX) |
| bandwidth.cache_mbps | INTEGER | Yes | CDN/Cache bandwidth |

#### 3.4.2 Location Object Specification (All APIs)

ISP can specify location using EITHER `bbs_code` (preferred) OR text fields. System maps text to BBS code.

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| bbs_code | STRING | Conditional | BBS geocode (preferred) - 2/4/6/8 digits |
| division | STRING | Conditional | Division name (if bbs_code not provided) |
| district | STRING | Conditional | District name (if bbs_code not provided) |
| upazila | STRING | Conditional | Upazila name (if bbs_code not provided) |

**BBS Code Format:**
| Level | Digits | Example | Description |
|-------|--------|---------|-------------|
| Division | 2 | `30` | Dhaka Division |
| District | 4 | `3026` | Dhaka District |
| Upazila | 6 | `302614` | Savar Upazila |
| Thana | 8 | `30261401` | Specific Thana |

**Validation Rules:**
- If `bbs_code` provided and valid → use directly
- If `bbs_code` null → text fields required, system maps to BBS code
- If text fields don't match geo tables → submission rejected with error

**System Behavior:**
1. Lookup text in geo_* reference tables (exact match)
2. If match found → map to bbs_code for storage
3. If no match → reject with list of valid options for that level

**Reference Data:**
- Division codes: See `BBS-Geocode-Divisions.json`
- District codes: See `BBS-Geocode-Districts.json`
- Upazila codes: See `BBS-Geocode-Upazilas.json`

#### 3.4.3 PoP Type Definitions

| Type | Description |
|------|-------------|
| core | Central/backbone PoP (no direct subscribers) |
| distribution | Regional aggregation PoP |
| access | Last-mile/subscriber-facing PoP |

#### 3.4.4 Ingestion Layer Notes

| API Field | DB Mapping | Logic |
|-----------|------------|-------|
| `pop_count` | Individual `pops` records | Expand: create/update N individual POP records per location |
| `pop_type` | `pops.category_id` | Map: `core`→`CORE_DC`, `distribution`→`REGIONAL_POP`, `access`→`EDGE_POP` |
| `status` | `pops.status` | Map: `active`→`ACTIVE`, `inactive`→`DECOMMISSIONED` |
| `upstream_capacity_mbps` | `pops.total_capacity_mbps` | Direct (DB column renamed from Gbps to Mbps) |
| `bandwidth.*` | `bandwidth_snapshots` table | Store in separate table with `pop_id` and `snapshot_month` |

**Storage Model**: API accepts aggregates per location. Ingestion layer:
1. Creates/updates individual POP records in `pops` table
2. Creates monthly snapshot in `bandwidth_snapshots` table

---

> **LEGACY STRUCTURE BELOW** - The detailed individual PoP structure is retained for reference but not used in POC.

<details>
<summary>Click to expand legacy PoP structure</summary>

```json
{
  "submission": {
    "submission_uuid": "bb3k4055-k85h-07j0-g372-002211006666",
    "isp_id": 142,
    "isp_name": "Example ISP Ltd.",
    "submission_time": "2026-02-05T10:00:00+06:00",
    "reporting_period": "2026-01",
    "total_pops": 45,
    "operational_pops": 42,
    "planned_pops": 3
  },
  "pops": [
    {
      "pop_id": 1523,
      "pop_code": "DHK-GULSHAN",
      "pop_name": "Dhaka Gulshan PoP",
      "pop_type": "ACCESS",
      "status": "OPERATIONAL",
      "location": {
        "division": "Dhaka",
        "district": "Dhaka",
        "upazila": "Gulshan",
        "thana": "Gulshan",
        "address": "House 45, Road 11, Gulshan-1",
        "gps_lat": 23.7925,
        "gps_lon": 90.4078,
        "gps_accuracy": "SURVEYED"
      },
      "infrastructure": {
        "technology": ["FTTH", "GPON"],
        "upstream_capacity_gbps": 10.0
      },
      "subscribers": {
        "active": 8540
      },
      "lifecycle": {
        "commissioned_date": "2020-03-15",
        "planned_decommission_date": null
      },
      "agent_references": {
        "snmp_agent_uuid": "7c9e6679-7425-40de-944b-e07fc1f90ae7",
        "snmp_targets": [
          {
            "target_id": "t-001",
            "target_type": "CORE_ROUTER"
          },
          {
            "target_id": "t-002",
            "target_type": "BDIX_ROUTER"
          }
        ],
        "qos_agent_uuid": "8d0f7780-8536-51ef-055c-f18gd2g01bf8"
      }
    },
    {
      "pop_id": 1524,
      "pop_code": "DHK-BANANI",
      "pop_name": "Dhaka Banani PoP",
      "pop_type": "ACCESS",
      "status": "OPERATIONAL",
      "location": {
        "division": "Dhaka",
        "district": "Dhaka",
        "upazila": "Banani",
        "thana": "Banani",
        "address": "Block B, Road 12, Banani",
        "gps_lat": 23.7938,
        "gps_lon": 90.4012,
        "gps_accuracy": "SURVEYED"
      },
      "infrastructure": {
        "technology": ["FTTH", "GPON"],
        "upstream_capacity_gbps": 8.0
      },
      "subscribers": {
        "active": 6250
      },
      "lifecycle": {
        "commissioned_date": "2021-06-20",
        "planned_decommission_date": null
      },
      "agent_references": {
        "snmp_agent_uuid": "7c9e6679-7425-40de-944b-e07fc1f90ae7",
        "snmp_targets": [
          {
            "target_id": "t-010",
            "target_type": "ACCESS_SWITCH"
          }
        ],
        "qos_agent_uuid": "8d0f7780-8536-51ef-055c-f18gd2g01bf9"
      }
    },
    {
      "pop_id": 1500,
      "pop_code": "DHK-CORE",
      "pop_name": "Dhaka Core PoP",
      "pop_type": "CORE",
      "status": "OPERATIONAL",
      "location": {
        "division": "Dhaka",
        "district": "Dhaka",
        "upazila": "Motijheel",
        "thana": "Motijheel",
        "address": "Telecom Tower, Motijheel",
        "gps_lat": 23.7258,
        "gps_lon": 90.4172,
        "gps_accuracy": "SURVEYED"
      },
      "infrastructure": {
        "technology": ["MPLS", "BGP"],
        "upstream_capacity_gbps": 100.0
      },
      "subscribers": {
        "active": 0
      },
      "lifecycle": {
        "commissioned_date": "2018-01-01",
        "planned_decommission_date": null
      },
      "agent_references": {
        "snmp_agent_uuid": "7c9e6679-7425-40de-944b-e07fc1f90ae0",
        "snmp_targets": [
          {
            "target_id": "t-011",
            "target_type": "CORE_ROUTER"
          },
          {
            "target_id": "t-012",
            "target_type": "CORE_ROUTER"
          }
        ],
        "qos_agent_uuid": null
      }
    },
    {
      "pop_id": 1601,
      "pop_code": "CTG-AGRABAD",
      "pop_name": "Chittagong Agrabad PoP",
      "pop_type": "DISTRIBUTION",
      "status": "OPERATIONAL",
      "location": {
        "division": "Chittagong",
        "district": "Chittagong",
        "upazila": "Kotwali",
        "thana": "Agrabad",
        "address": "CDA Tower, Agrabad",
        "gps_lat": 22.3289,
        "gps_lon": 91.8127,
        "gps_accuracy": "SURVEYED"
      },
      "infrastructure": {
        "technology": ["FTTH", "GPON", "MPLS"],
        "upstream_capacity_gbps": 20.0
      },
      "subscribers": {
        "active": 8540
      },
      "lifecycle": {
        "commissioned_date": "2019-08-15",
        "planned_decommission_date": null
      },
      "agent_references": {
        "snmp_agent_uuid": "8e0g7781-9647-62fg-166d-g29he3h12cg0",
        "snmp_targets": [
          {
            "target_id": "t-013",
            "target_type": "DISTRIBUTION_ROUTER"
          }
        ],
        "qos_agent_uuid": "9e1g8891-9647-62fg-166d-g29he3h12ch1"
      }
    },
    {
      "pop_id": 1650,
      "pop_code": "CTG-NEW",
      "pop_name": "Chittagong Expansion PoP",
      "pop_type": "ACCESS",
      "status": "PLANNED",
      "location": {
        "division": "Chittagong",
        "district": "Chittagong",
        "upazila": "Pahartali",
        "thana": "Pahartali",
        "address": "TBD",
        "gps_lat": 22.3785,
        "gps_lon": 91.7892,
        "gps_accuracy": "ESTIMATED"
      },
      "infrastructure": {
        "technology": ["FTTH", "GPON"],
        "upstream_capacity_gbps": 10.0
      },
      "subscribers": {
        "active": 0
      },
      "lifecycle": {
        "commissioned_date": null,
        "planned_commission_date": "2026-06-01",
        "planned_decommission_date": null
      },
      "agent_references": {
        "snmp_agent_uuid": null,
        "snmp_targets": [],
        "qos_agent_uuid": null
      }
    }
  ]
}
```

**Legacy PoP Type Definitions**

| Type | Description |
|------|-------------|
| CORE | Central/backbone PoP (no direct subscribers) |
| DISTRIBUTION | Regional aggregation PoP |
| ACCESS | Last-mile/subscriber-facing PoP |

**Legacy PoP Status Values**

| Status | Description |
|--------|-------------|
| OPERATIONAL | Active and serving subscribers |
| PLANNED | Not yet commissioned |
| UNDER_CONSTRUCTION | Being built/installed |
| MAINTENANCE | Temporarily offline |
| DECOMMISSIONED | No longer operational |

</details>

---

#### 3.5 Incident Data - JSON Submission Structure

> **POC STATUS: OUT OF SCOPE** - Incident reporting is deferred for POC phase. The structure below is retained for future implementation.

**Endpoint**: `POST /api/v1/isp/incidents`
**Content-Type**: `application/json`
**Authentication**: OAuth 2.0 Bearer Token
**Submission Frequency**: Weekly or Monthly

```json
{
  "submission": {
    "submission_uuid": "cc4l5166-l96i-18k1-h483-113322117777",
    "isp_id": 142,
    "isp_name": "Example ISP Ltd.",
    "submission_time": "2026-02-05T10:00:00+06:00",
    "reporting_period": "2026-01",
    "reporting_period_start": "2026-01-01",
    "reporting_period_end": "2026-01-31",
    "incident_count": 8
  },
  "summary": {
    "total_incidents": 8,
    "by_type": {
      "OUTAGE": 3,
      "DEGRADATION": 4,
      "SECURITY": 0,
      "UPSTREAM": 1
    },
    "by_severity": {
      "CRITICAL": 1,
      "MAJOR": 3,
      "MINOR": 4
    },
    "avg_mttr_minutes": 142
  },
  "incidents": [
    {
      "incident_id": "INC-2026-00145",
      "incident_type": "OUTAGE",
      "severity": "MAJOR",
      "status": "RESOLVED",
      "timeline": {
        "detected_time": "2026-01-15T14:30:00+06:00",
        "reported_time": "2026-01-15T14:35:00+06:00",
        "acknowledged_time": "2026-01-15T14:40:00+06:00",
        "work_started_time": "2026-01-15T14:45:00+06:00",
        "resolved_time": "2026-01-15T18:45:00+06:00",
        "duration_minutes": 255,
        "mttr_minutes": 250
      },
      "impact": {
        "affected_pops": [
          {
            "pop_id": 1523,
            "pop_code": "DHK-GULSHAN"
          },
          {
            "pop_id": 1524,
            "pop_code": "DHK-BANANI"
          }
        ],
        "service_impact": "COMPLETE_OUTAGE"
      },
      "location": {
        "division": "Dhaka",
        "district": "Dhaka",
        "upazila": "Gulshan",
        "thana": "Gulshan"
      },
      "description": "Fiber cut on primary uplink affecting Gulshan and Banani areas"
    },
    {
      "incident_id": "INC-2026-00152",
      "incident_type": "DEGRADATION",
      "severity": "MINOR",
      "status": "RESOLVED",
      "timeline": {
        "detected_time": "2026-01-18T09:15:00+06:00",
        "reported_time": "2026-01-18T09:20:00+06:00",
        "acknowledged_time": "2026-01-18T09:25:00+06:00",
        "work_started_time": "2026-01-18T09:30:00+06:00",
        "resolved_time": "2026-01-18T10:45:00+06:00",
        "duration_minutes": 90,
        "mttr_minutes": 85
      },
      "impact": {
        "affected_pops": [
          {
            "pop_id": 1601,
            "pop_code": "CTG-AGRABAD"
          }
        ],
        "service_impact": "PARTIAL_DEGRADATION"
      },
      "location": {
        "division": "Chittagong",
        "district": "Chittagong",
        "upazila": "Kotwali",
        "thana": "Agrabad"
      },
      "description": "Increased latency on BDIX peering link"
    },
    {
      "incident_id": "INC-2026-00168",
      "incident_type": "UPSTREAM",
      "severity": "CRITICAL",
      "status": "RESOLVED",
      "timeline": {
        "detected_time": "2026-01-22T20:00:00+06:00",
        "reported_time": "2026-01-22T20:05:00+06:00",
        "acknowledged_time": "2026-01-22T20:10:00+06:00",
        "work_started_time": "2026-01-22T20:15:00+06:00",
        "resolved_time": "2026-01-23T02:30:00+06:00",
        "duration_minutes": 390,
        "mttr_minutes": 380
      },
      "impact": {
        "affected_pops": [
          {
            "pop_id": 1500,
            "pop_code": "DHK-CORE"
          }
        ],
        "service_impact": "COMPLETE_OUTAGE"
      },
      "location": {
        "division": "Dhaka",
        "district": "Dhaka",
        "upazila": "Motijheel",
        "thana": "Motijheel"
      },
      "description": "Upstream provider AAMRA international link failure"
    }
  ]
}
```

#### 3.5.1 Incident Type Definitions

| Type | Description |
|------|-------------|
| OUTAGE | Complete service interruption |
| DEGRADATION | Reduced performance (speed, latency) |
| SECURITY | Security-related incident |
| UPSTREAM | Caused by upstream provider |

**Note**: MAINTENANCE is NOT included - planned maintenance is not reported as an incident.

#### 3.5.2 Severity Levels

| Severity | Description |
|----------|-------------|
| CRITICAL | Total network outage, >50% subscribers affected |
| MAJOR | Significant impact, 10-50% subscribers affected |
| MINOR | Limited impact, <10% subscribers affected |

#### 3.5.3 Service Impact Values

| Impact | Description |
|--------|-------------|
| COMPLETE_OUTAGE | No service available |
| PARTIAL_OUTAGE | Some services unavailable |
| PARTIAL_DEGRADATION | Reduced performance |
| MINIMAL | Minor impact, most services normal |

#### 3.5.4 Timeline Fields

| Field | Type | Description |
|-------|------|-------------|
| detected_time | ISO8601 | When ISP detected the issue |
| reported_time | ISO8601 | When reported to NOC/ticket created |
| acknowledged_time | ISO8601 | When engineer acknowledged |
| work_started_time | ISO8601 | When remediation began |
| resolved_time | ISO8601 | When service restored |
| duration_minutes | INTEGER | Total incident duration |
| mttr_minutes | INTEGER | Mean time to repair (work_started to resolved) |

---

#### 3.6 Complaint Data - JSON Submission Structure

> **POC STATUS: OUT OF SCOPE** - Complaint reporting is deferred for POC phase. The structure below is retained for future implementation.

**Endpoint**: `POST /api/v1/isp/complaints`
**Content-Type**: `application/json`
**Authentication**: OAuth 2.0 Bearer Token
**Submission Frequency**: Monthly (by 10th of following month)

```json
{
  "submission": {
    "submission_uuid": "dd5m6277-m07j-29l2-i594-224433228888",
    "isp_id": 142,
    "isp_name": "Example ISP Ltd.",
    "submission_time": "2026-02-05T10:00:00+06:00",
    "reporting_period": "2026-01",
    "reporting_period_start": "2026-01-01",
    "reporting_period_end": "2026-01-31"
  },
  "summary": {
    "total_received": 310,
    "total_resolved": 298,
    "resolution_rate_pct": 96.13,
    "avg_mttr_hours": 14.2
  },
  "by_category": [
    {
      "category": "BANDWIDTH",
      "description": "Speed below advertised/expected",
      "received": 125,
      "resolved": 120,
      "mttr_hours": 12.5
    },
    {
      "category": "OUTAGE",
      "description": "Complete service interruption",
      "received": 85,
      "resolved": 82,
      "mttr_hours": 8.2
    },
    {
      "category": "UPSTREAM",
      "description": "International/IX connectivity issues",
      "received": 42,
      "resolved": 40,
      "mttr_hours": 24.5
    },
    {
      "category": "WEBSITE_UNREACHABLE",
      "description": "Specific websites not accessible",
      "received": 35,
      "resolved": 34,
      "mttr_hours": 18.6
    },
    {
      "category": "LATENCY",
      "description": "High ping/lag complaints",
      "received": 23,
      "resolved": 22,
      "mttr_hours": 10.8
    }
  ]
}
```

#### 3.6.1 Complaint Category Definitions

| Category | Description |
|----------|-------------|
| BANDWIDTH | Speed below advertised or expected levels |
| OUTAGE | Complete service interruption reported by subscriber |
| UPSTREAM | International or IX connectivity issues |
| WEBSITE_UNREACHABLE | Specific websites/services not accessible |
| LATENCY | High ping, lag, slow response times |

**Note**: Categories like BILLING, INSTALLATION, INTERMITTENT, and OTHER are excluded from QoS monitoring scope.

#### 3.6.2 Complaint Metrics

| Field | Type | Description |
|-------|------|-------------|
| received | INTEGER | Total complaints received in period |
| resolved | INTEGER | Complaints resolved in period |
| mttr_hours | DECIMAL | Average time to resolution (hours) |

**Note**: Core calculates resolution_rate_pct from received/resolved values.

---

#### 3.7 Subscriber Revenue - JSON Submission Structure

**Endpoint**: `POST /api/v1/isp/{isp_id}/revenue`
**Content-Type**: `application/json`
**Authentication**: OAuth 2.0 Bearer Token
**Submission Frequency**: Monthly (by 10th of following month)

> **POC Structure**: Revenue is reported as Package × Location matrix. Location can be specified via `bbs_code` OR text fields (see Section 3.4.2). Actual revenue is required (not derived from subscriber × price).

```json
{
  "period": "2026-01",
  "revenue": [
    {
      "package_code": "PKG-HOME-100",
      "location": {
        "bbs_code": "302614"
      },
      "subscriber_revenue_bdt": 3390217.50,
      "vat_bdt": 508532.50
    },
    {
      "package_code": "PKG-HOME-100",
      "location": {
        "bbs_code": null,
        "division": "Dhaka",
        "district": "Dhaka",
        "upazila": "Banani"
      },
      "subscriber_revenue_bdt": 2191308.00,
      "vat_bdt": 328692.00
    },
    {
      "package_code": "PKG-HOME-50",
      "location": {
        "bbs_code": "302614"
      },
      "subscriber_revenue_bdt": 2866078.00,
      "vat_bdt": 429922.00
    },
    {
      "package_code": "PKG-BIZ-200",
      "location": {
        "bbs_code": "200102"
      },
      "subscriber_revenue_bdt": 1826086.20,
      "vat_bdt": 273913.80
    }
  ]
}
```

#### 3.7.1 Revenue Field Specifications (POC)

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| package_code | STRING | Yes | Reference to Package |
| location | OBJECT | Yes | Location reference (see Section 3.4.2) |
| subscriber_revenue_bdt | DECIMAL | Yes | Net subscriber revenue (excluding VAT) |
| vat_bdt | DECIMAL | Yes | VAT collected |

#### 3.7.2 Revenue Verification Model

**Core validates ISP-reported revenue using**:
- **Category 1** (Package Definitions): `net_fee_bdt` per package
- **Category 2** (Subscriber Data): Subscriber counts by package
- **Category 7** (Revenue): Actual reported revenue

**Verification Formula**:
```
Expected Revenue = SUM(Package.net_fee_bdt × Subscriber.count)
Variance = |Reported Revenue - Expected Revenue| / Expected Revenue × 100%
```

**Variance Thresholds**:
- **<5%**: Normal (acceptable)
- **5-10%**: Warning (review)
- **>10%**: Alert (investigation required)

#### 3.7.3 Cross-Reference IDs

Revenue data uses the same IDs as other categories for cross-validation:
- `pop_id` → Category 4 (Infrastructure)
- `package_id` → Category 1 (Package Definitions)

Geolocation is derived from Category 4 (Infrastructure) based on `pop_id`.

#### 3.7.4 Ingestion Layer Notes

| API Field | DB Mapping | Logic |
|-----------|------------|-------|
| `package_code` | `revenue_details.package_id` | Lookup by `(isp_id, package_code)` → `packages.id` |
| `location` | `revenue_details.bbs_code` | Parse or lookup as per Section 3.4.2 |
| `subscriber_revenue_bdt` | `revenue_details.subscriber_revenue_bdt` | Direct storage |
| `vat_bdt` | `revenue_details.vat_bdt` | Direct storage |

**Storage Model**:
- **Granular data** → `revenue_details` table (Package × Location per month)
- **ISP aggregates** → `revenue_snapshots` table (calculated from revenue_details)

> **📋 REVIEW NOTE (2026-01-12)**: Revenue verification logic location TBD. Options: application layer (flexible), database triggers (automatic), scheduled batch job (async). Evaluate based on performance requirements.

---

### 4. USER_APP

| Data Type | Description |
|-----------|-------------|
| Download speed (Mbps) | User-measured downstream |
| Upload speed (Mbps) | User-measured upstream |
| Latency (ms) | User-perceived delay |
| Jitter (ms) | Connection stability |
| Packet loss (%) | Quality indicator |
| DNS resolution time (ms) | DNS performance |
| HTTP response time (ms) | Web browsing speed |
| Video buffer ratio | Streaming quality |
| GPS coordinates | Optional location |
| Connection type | WIFI/ETHERNET/MOBILE_DATA |
| Feedback/complaints | User-submitted issues |

**Elaboration**: *(To be added)*

---

### 5. REG_APP

| Data Type | Description |
|-----------|-------------|
| Field inspection reports | Inspector findings |
| Compliance status | COMPLIANT/NON_COMPLIANT/PARTIAL |
| Issues found | Structured JSON list |
| Recommendations | Inspector suggestions |
| Photos | Evidence attachments |
| Documents | Supporting files |
| GPS coordinates | Inspection location |
| Speed test results | Linked measurements |
| PoP audit data | Infrastructure verification |
| Inspection type | ROUTINE/COMPLAINT_FOLLOWUP/AUDIT |

**Elaboration**: *(To be added)*

---

## Changelog

| Date | Version | Changes |
|------|---------|---------|
| 2026-01-10 | 1.0 | Initial document with summary table and basic structure |
| 2026-01-10 | 1.1 | Added SNMP_AGENT interface metrics JSON structure, field specs, public IP service |
| 2026-01-10 | 1.2 | Updated to 3-poll batching (5-min intervals), added target_status array, poll timeout/error handling |
| 2026-01-10 | 1.3 | Added Subscriber Counts JSON structure (sections 1.6-1.9), BRAS topology, deployment models, coverage mapping |
| 2026-01-10 | 1.4 | Added QOS_AGENT JSON structure (sections 2.1-2.9), combined ping test (latency+packet loss), 15-min polling per PRD |
| 2026-01-10 | 1.5 | Added ISP_API JSON structures (sections 3.1-3.7): Package Definitions, Subscriber Data, Bandwidth Data, Infrastructure/PoP, Incidents, Complaints, Revenue; cross-validation model |
| 2026-01-11 | 1.6 | **ToR Alignment Revision**: Combined interface + subscriber submission endpoint; Hybrid collection architecture (single agent, async workers); New fields: device_type, vendor, mib_profile, admin_status, oper_status, interface_type, upstream_operator; Renamed upstream_type to interface_type, BDIX to IX; Simplified BRAS structure (per-ISP only, removed PoP disaggregation); Counter wrap detection moved to server-side; Updated responsibility separation |
| 2026-01-11 | 1.7 | **QOS_AGENT ToR Alignment**: Single speed_test object (OOKLA_API preferred); Target types (NATIONAL/IX/INTERNATIONAL/LOCAL_BD); agent_detected_failures block for hybrid detection (Agent: obvious failures, Core: thresholds); HTTP weighted scoring with separate reachability + response time (ToR 3.4.7, 3.4.8); DNS domain_type classification; Removed agent-side availability (Core calculates); Updated timing parameters; Added failure object specs, target types, HTTP scoring specs |
| 2026-01-11 | 1.8 | **Section 2.10 Added**: Core-Side Service Availability Calculation specification; Connectivity-First model with two-tier evaluation (connectivity check + QoS quality scoring); Configurable threshold profiles; Interval status mapping (OUTAGE/POOR/DEGRADED/AVAILABLE); Missing data handling; Reporting periods; Review note for BTRC stakeholder validation |
| 2026-01-12 | 1.9 | **ISP_API POC Revision**: Simplified JSON structures for POC scope; All endpoints use `geo_id` (system location UID) instead of text location fields; Package × Location matrix for Subscribers (3.2) and Revenue (3.7); POP data uses `pop_count` aggregate per geo_id (3.4); All frequencies set to Monthly; Added POC scope column to summary table; Marked sections 3.3, 3.5, 3.6 as out of scope; Added MIR/CIR fields to Package (3.1); Legacy structures preserved in collapsible sections |
| 2026-01-12 | 2.0 | **ISP_API ToR Alignment Update**: Added bandwidth fields (international, IX, cache) to POP structure (3.4) per ToR 3.2.2; Implemented hybrid location input - ISP can submit `geo_id` OR text fields (division/district/upazila), system maps to geo_id; Added Location Object Specification (3.4.2) referenced by all location-based APIs; Updated Subscriber (3.2) and Revenue (3.7) to use location object; Marked 3.3 as "Merged into POP" instead of out of scope |
| 2026-01-12 | 2.1 | **DB Schema Compliance Resolution**: Removed `connection_type` field from Package API (3.1); Added Ingestion Layer Notes sections (3.1.2, 3.2.2, 3.2.3, 3.4.4, 3.7.4) documenting API→DB field mappings; Added Data Source Separation for Subscribers (ISP_API vs SNMP_AGENT); Added review notes for deferred decisions (geo structure, revenue verification); Documents DB changes required: mir_mbps, cir_mbps columns in packages; Mbps unit standardization; revenue_details table |
| 2026-01-12 | 2.2 | **BBS Geocode Standard**: Replaced `geo_id` with `bbs_code` throughout; Updated Location Object Specification (3.4.2) with BBS code format (2/4/6/8 digits); Added reference to BBS geocode JSON data files; All sample JSON updated to use BBS codes (e.g., "302614" for Dhaka/Savar) |
| 2026-01-15 | 2.3 | **QOS_AGENT Software Deployment Model**: Removed `hardware_id` and `hardware_model` fields from agent_status (Section 2.1, 2.2); QOS_AGENT now assumes software container/VM deployment on ISP infrastructure rather than dedicated hardware probes; Agent identification via existing `agent_uuid` in submission header; Renamed "Hardware health monitoring" to "Agent health monitoring" in responsibility separation (Section 2.9) |

---

**End of Document**
