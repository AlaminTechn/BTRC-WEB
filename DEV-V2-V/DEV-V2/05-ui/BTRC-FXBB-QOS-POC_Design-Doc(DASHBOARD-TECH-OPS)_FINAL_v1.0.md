# BTRC Technical Operations Dashboard - Layout Plan v1.0

**Document Version**: 1.1
**Date**: 2026-01-08
**Project**: BTRC Fixed Broadband QoS Monitoring System
**Dashboard**: Technical Operations Dashboard
**Primary Audience**: BTRC Technical Team

---

## Executive Summary

This document defines the layout plan for the Technical Operations Dashboard, one of three internal BTRC dashboards. The dashboard is designed for BTRC technical staff to monitor platform health, measurement infrastructure, network metrics, and infrastructure analytics.

### Key Metrics
- **Total Components**: 17
- **Tabs**: 4
- **ToR Alignment**: 100% (All components aligned with ToR Sections 3.3-3.5, 3.8)
- **Primary Data Sources**: QoS Collector (11), SNMP Collector (3), ISP-Submitted (3)

---

## Component Inventory

### Full Component List with Descriptions

| # | Section | Component | Description | Primary Source |
|---|---------|-----------|-------------|----------------|
| 1 | 3.1 | Probe Status (64 Districts) | Real-time status of 2500 probes across all 64 districts. Shows online/offline/degraded counts. | QoS Collector |
| 2 | 3.1 | Probe Health & Performance | Individual probe performance metrics: CPU, memory, network latency, test execution rates. | QoS Collector |
| 3 | 3.1 | PoP Correlation for Coverage | Map probes to PoP coverage, identify coverage gaps, ensure adequate geographic distribution. | QoS Collector |
| 4 | 3.2 | Stream Processing Performance | Apache Kafka/Flink pipeline throughput, lag, error rates. Monitors 100K+ msg/sec capacity. | QoS Collector |
| 5 | 3.2 | Database Health | PostgreSQL/TimescaleDB metrics: connection pools, query perf, storage utilization, replication. | QoS Collector |
| 6 | 3.2 | API Response Times | RESTful API latency distribution, P50/P95/P99 percentiles, error rates by endpoint. | QoS Collector |
| 7 | 3.3 | Bandwidth Utilization | Network bandwidth consumption at monitoring infrastructure, ISP link capacities vs usage. | SNMP Collector |
| 8 | 3.3 | Latency Measurements | End-to-end latency tracking: probe-to-server, regional paths, historical trend analysis. | QoS Collector |
| 9 | 3.3 | Packet Loss Tracking | Packet loss percentage by probe, ISP, region. Alert thresholds and degradation patterns. | QoS Collector |
| 10 | 3.3 | PoP Performance Benchmarking | Individual PoP benchmarks vs baseline. Compare performance across divisions/districts. | QoS Collector |
| 11 | 3.4 | RESTful API Health | API gateway status, endpoint availability, rate limiting, authentication success rates. | QoS Collector |
| 12 | 3.4 | Webhook Status | Outbound webhook delivery rates, retry queues, ISP notification acknowledgment tracking. | QoS Collector |
| 13 | 3.4 | External API Specs | ISP API compliance status, integration health, data format validation results. | ISP-Submitted |
| 14 | 3.5 | Infrastructure Mapping | PoP equipment inventory, rack diagrams, capacity specs, geographic coordinates. | ISP-Submitted |
| 15 | 3.5 | Performance Benchmarking | PoP QoS scores vs division averages. Identify under/over-performing infrastructure. | QoS Collector |
| 16 | 3.5 | Traffic Analysis & Congestion | Traffic flow patterns, peak hour congestion, bottleneck identification by PoP/region. | SNMP Collector |
| 17 | 3.5 | Capacity Planning | Trend-based capacity analysis, 3/6/12 month projections based on historical data. | QoS Collector |

### Data Source Summary

| Data Source | Count | Percentage |
|-------------|-------|------------|
| QoS Collector | 11 | 64.7% |
| SNMP Collector | 3 | 17.6% |
| ISP-Submitted | 3 | 17.6% |
| Mobile App | 0 | 0% |
| Monitoring App | 0 | 0% |

---

## Tab Structure

### Tab Distribution

| Tab | Name | Components | Source Sections | Workflow Purpose |
|-----|------|------------|-----------------|------------------|
| 1 | Platform Health | 5 | 3.8 | Monitor system status |
| 2 | Measurement Network | 4 | 3.2, 3.8 | Monitor data collection |
| 3 | Network Metrics | 4 | 3.4 | Track QoS measurements |
| 4 | Infrastructure Analytics | 4 | 3.5, 3.8 | Analyze PoP/capacity |

### Technical Operations Workflow

```
Monitor → Diagnose → Analyze → Plan
   │          │          │        │
   Tab 1      Tab 2      Tab 3    Tab 4
```

---

## Detailed Tab Specifications

### Tab 1: Platform Health

**Purpose**: Real-time monitoring of QoS platform systems

| Component | Description | Primary Source | Secondary Source |
|-----------|-------------|----------------|------------------|
| Stream Processing Performance | Kafka/Flink throughput, lag, errors | QoS Collector | - |
| Database Health | Connection pools, query perf, storage | QoS Collector | SNMP Collector |
| API Response Times | Latency P50/P95/P99, error rates | QoS Collector | Mobile App |
| RESTful API Health | Gateway status, rate limiting, auth | QoS Collector | ISP-Submitted |
| Webhook Status | Delivery rates, retry queues | QoS Collector | ISP-Submitted |

**Key Metrics**:
- Messages/second throughput
- Database connection utilization
- API response time percentiles
- Gateway availability percentage
- Webhook delivery success rate

---

### Tab 2: Measurement Network

**Purpose**: Data collection infrastructure monitoring

| Component | Description | Primary Source | Secondary Source |
|-----------|-------------|----------------|------------------|
| Probe Status (64 Districts) | Online/offline/degraded counts | QoS Collector | Monitoring App |
| Probe Health & Performance | CPU, memory, network metrics | QoS Collector | Monitoring App |
| PoP Correlation for Coverage | Coverage gap analysis | QoS Collector | ISP-Submitted |
| External API Specs | ISP integration health | ISP-Submitted | QoS Collector |

**Key Metrics**:
- Probe online percentage
- District coverage rate
- PoP correlation percentage
- API integration success rate

---

### Tab 3: Network Metrics

**Purpose**: Core QoS performance measurements

| Component | Description | Primary Source | Secondary Source |
|-----------|-------------|----------------|------------------|
| Bandwidth Utilization | Link capacity vs usage | SNMP Collector | QoS Collector |
| Latency Measurements | End-to-end, regional paths | QoS Collector | SNMP Collector |
| Packet Loss Tracking | Loss by probe, ISP, region | QoS Collector | SNMP Collector |
| PoP Performance Benchmarking | Benchmarks vs division baseline | QoS Collector | SNMP Collector |

**Key Metrics**:
- Bandwidth utilization percentage
- Latency P50/P95/P99
- Packet loss percentage
- PoP performance score

---

### Tab 4: Infrastructure Analytics

**Purpose**: PoP and capacity analysis

| Component | Description | Primary Source | Secondary Source |
|-----------|-------------|----------------|------------------|
| Infrastructure Mapping | Equipment inventory, coordinates | ISP-Submitted | Monitoring App |
| Performance Benchmarking | QoS scores vs division averages | QoS Collector | SNMP Collector |
| Traffic Analysis & Congestion | Peak hour patterns, bottlenecks | SNMP Collector | QoS Collector |
| Capacity Planning (Predictive) | 3/6/12 month projections | QoS Collector | ISP-Submitted |

**Key Metrics**:
- Total PoP count by status
- Performance score distribution
- Congestion percentage by time
- Capacity utilization projections

---

## Layout Mockups

### Tab 1: Platform Health

```
┌─────────────────────────────────────────────────────────────────────────────┐
│ [Platform Health] [Measurement Network] [Network Metrics] [Infrastructure]  │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                             │
│  ┌─────────────────────────────────────────────────────────────────────┐   │
│  │              SYSTEM STATUS SUMMARY                                   │   │
│  │  ┌──────────┐ ┌──────────┐ ┌──────────┐ ┌──────────┐ ┌──────────┐  │   │
│  │  │ KAFKA    │ │ DATABASE │ │ API      │ │ WEBHOOKS │ │ OVERALL  │  │   │
│  │  │ ● GOOD   │ │ ● GOOD   │ │ ● GOOD   │ │ ○ WARN   │ │ ● 98.5%  │  │   │
│  │  │ 98.7K/s  │ │ 145ms    │ │ 23ms P50 │ │ 3 retry  │ │ Healthy  │  │   │
│  │  └──────────┘ └──────────┘ └──────────┘ └──────────┘ └──────────┘  │   │
│  └─────────────────────────────────────────────────────────────────────┘   │
│                                                                             │
│  ┌─────────────────────────────────┐ ┌─────────────────────────────────┐   │
│  │ STREAM PROCESSING PERFORMANCE  │ │ DATABASE HEALTH                 │   │
│  │                                 │ │                                 │   │
│  │  Messages/sec: 98,745          │ │  Connections: 245/500 (49%)    │   │
│  │  Lag: 0.3s (target: <1s)       │ │  Query P95: 145ms              │   │
│  │  Error Rate: 0.001%            │ │  Storage: 2.3TB/5TB (46%)      │   │
│  │                                 │ │  Replication: SYNC             │   │
│  │  ┌─────────────────────────┐   │ │                                 │   │
│  │  │▓▓▓▓▓▓▓▓▓▓▓▓▓▓░░░░░░░░░░│   │ │  ┌─────────────────────────┐   │   │
│  │  │    Throughput 24hr      │   │ │  │▓▓▓▓▓▓▓▓▓░░░░░░░░░░░░░░░│   │   │
│  │  │    █ Current ░ Average  │   │ │  │   Connection Pool 24hr  │   │   │
│  │  └─────────────────────────┘   │ │  └─────────────────────────┘   │   │
│  └─────────────────────────────────┘ └─────────────────────────────────┘   │
│                                                                             │
│  ┌─────────────────────────────────┐ ┌─────────────────────────────────┐   │
│  │ API RESPONSE TIMES             │ │ WEBHOOK STATUS                  │   │
│  │                                 │ │                                 │   │
│  │  Endpoint        P50   P95 P99 │ │  Total Pending: 1,245           │   │
│  │  ─────────────────────────────  │ │  Delivered/hr: 45,678          │   │
│  │  /qos/metrics    12ms  45  89  │ │  Retry Queue: 3                 │   │
│  │  /isp/dashboard  23ms  78  156 │ │  Failed (24hr): 12              │   │
│  │  /alerts/query   8ms   34  67  │ │                                 │   │
│  │  /reports/gen    89ms  234 456 │ │  ISP Endpoints: 45/45 ● Active  │   │
│  │                                 │ │  Avg Ack Time: 234ms           │   │
│  │  Error Rate: 0.02%             │ │                                 │   │
│  └─────────────────────────────────┘ └─────────────────────────────────┘   │
│                                                                             │
│  ┌─────────────────────────────────────────────────────────────────────┐   │
│  │ RESTFUL API HEALTH - REAL-TIME DASHBOARD                            │   │
│  │                                                                      │   │
│  │  Gateway Status: ● OPERATIONAL    Rate Limit: 12% utilized          │   │
│  │  Auth Success: 99.98%             Active Sessions: 1,245            │   │
│  │                                                                      │   │
│  │  ┌───────────────────────────────────────────────────────────────┐  │   │
│  │  │  00:00        06:00        12:00        18:00        24:00    │  │   │
│  │  │    ╭──────────────────────────────────────────────────────    │  │   │
│  │  │    │▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓    │  │   │
│  │  │    ╰──────────────────────────────────────────────────────    │  │   │
│  │  │         Request Volume & Response Time (24hr)                  │  │   │
│  │  └───────────────────────────────────────────────────────────────┘  │   │
│  └─────────────────────────────────────────────────────────────────────┘   │
│                                                                             │
└─────────────────────────────────────────────────────────────────────────────┘
```

---

### Tab 2: Measurement Network

```
┌─────────────────────────────────────────────────────────────────────────────┐
│ [Platform Health] [Measurement Network] [Network Metrics] [Infrastructure]  │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                             │
│  ┌─────────────────────────────────────────────────────────────────────┐   │
│  │              PROBE NETWORK STATUS (64 Districts)                     │   │
│  │  ┌──────────────┐ ┌──────────────┐ ┌──────────────┐ ┌──────────────┐│   │
│  │  │ TOTAL PROBES │ │ ONLINE       │ │ DEGRADED     │ │ OFFLINE      ││   │
│  │  │    2,500     │ │ ● 2,423      │ │ ○ 54         │ │ ✗ 23         ││   │
│  │  │              │ │ (96.9%)      │ │ (2.2%)       │ │ (0.9%)       ││   │
│  │  └──────────────┘ └──────────────┘ └──────────────┘ └──────────────┘│   │
│  └─────────────────────────────────────────────────────────────────────┘   │
│                                                                             │
│  ┌─────────────────────────────────────────────────────────────────────┐   │
│  │ PROBE STATUS BY DIVISION                                             │   │
│  │                                                                      │   │
│  │  Division     │ Total │Online│Degrad│Offline│ Coverage │ Health    │   │
│  │  ─────────────┼───────┼──────┼──────┼───────┼──────────┼───────────│   │
│  │  Dhaka        │  645  │ 631  │  10  │   4   │  98.2%   │ ●●●●●     │   │
│  │  Chattogram   │  412  │ 398  │   9  │   5   │  96.6%   │ ●●●●○     │   │
│  │  Rajshahi     │  298  │ 289  │   6  │   3   │  97.0%   │ ●●●●○     │   │
│  │  Khulna       │  276  │ 268  │   5  │   3   │  97.1%   │ ●●●●○     │   │
│  │  Sylhet       │  234  │ 226  │   6  │   2   │  96.6%   │ ●●●●○     │   │
│  │  Rangpur      │  245  │ 238  │   5  │   2   │  97.1%   │ ●●●●○     │   │
│  │  Barishal     │  198  │ 191  │   5  │   2   │  96.5%   │ ●●●●○     │   │
│  │  Mymensingh   │  192  │ 182  │   8  │   2   │  94.8%   │ ●●●○○     │   │
│  └─────────────────────────────────────────────────────────────────────┘   │
│                                                                             │
│  ┌─────────────────────────────────┐ ┌─────────────────────────────────┐   │
│  │ PROBE HEALTH & PERFORMANCE     │ │ PoP CORRELATION COVERAGE        │   │
│  │                                 │ │                                 │   │
│  │  Avg CPU: 23%                  │ │  PoPs Covered: 1,847/1,892     │   │
│  │  Avg Memory: 45%               │ │  Coverage Rate: 97.6%          │   │
│  │  Avg Network Latency: 12ms     │ │                                 │   │
│  │  Tests/Hour: 450K              │ │  Gap Analysis:                 │   │
│  │                                 │ │  ├─ Sylhet: 12 PoPs uncovered │   │
│  │  Health Distribution:          │ │  ├─ Mymensingh: 18 PoPs        │   │
│  │  ┌───────────────────────────┐ │ │  └─ Barishal: 15 PoPs         │   │
│  │  │▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓░░░░░░░░│ │ │                                 │   │
│  │  │ Excellent Good  Fair Poor│ │ │  [View Coverage Map]            │   │
│  │  └───────────────────────────┘ │ │                                 │   │
│  └─────────────────────────────────┘ └─────────────────────────────────┘   │
│                                                                             │
│  ┌─────────────────────────────────────────────────────────────────────┐   │
│  │ EXTERNAL API INTEGRATION STATUS                                      │   │
│  │                                                                      │   │
│  │  ISP Name          API Status   Last Sync    Data Format  Errors   │   │
│  │  ─────────────────────────────────────────────────────────────────  │   │
│  │  Link3 Technologies  ● Active   2 min ago    JSON/Valid   0        │   │
│  │  Amber IT            ● Active   3 min ago    JSON/Valid   0        │   │
│  │  Carnival Internet   ● Active   1 min ago    JSON/Valid   0        │   │
│  │  Circle Network      ○ Delayed  15 min ago   JSON/Valid   2        │   │
│  │  BDCOM               ● Active   2 min ago    JSON/Valid   0        │   │
│  │                                                                      │   │
│  │  Integration Health: 44/45 ISPs Active (97.8%)                      │   │
│  └─────────────────────────────────────────────────────────────────────┘   │
│                                                                             │
└─────────────────────────────────────────────────────────────────────────────┘
```

---

### Tab 3: Network Metrics

```
┌─────────────────────────────────────────────────────────────────────────────┐
│ [Platform Health] [Measurement Network] [Network Metrics] [Infrastructure]  │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                             │
│  ┌─────────────────────────────────────────────────────────────────────┐   │
│  │              NETWORK PERFORMANCE SUMMARY                             │   │
│  │  ┌──────────────┐ ┌──────────────┐ ┌──────────────┐ ┌──────────────┐│   │
│  │  │ BANDWIDTH    │ │ AVG LATENCY  │ │ PACKET LOSS  │ │ PoP HEALTH   ││   │
│  │  │ 78% Util     │ │ 23.4ms       │ │ 0.12%        │ │ 94.2%        ││   │
│  │  │ ↑ 3%         │ │ ↓ 2ms        │ │ → Stable     │ │ ↑ 1.2%       ││   │
│  │  └──────────────┘ └──────────────┘ └──────────────┘ └──────────────┘│   │
│  └─────────────────────────────────────────────────────────────────────┘   │
│                                                                             │
│  ┌─────────────────────────────────┐ ┌─────────────────────────────────┐   │
│  │ BANDWIDTH UTILIZATION          │ │ LATENCY MEASUREMENTS            │   │
│  │                                 │ │                                 │   │
│  │  Division      Util%  Trend    │ │  Division      Avg    P95  P99 │   │
│  │  ────────────────────────────  │ │  ────────────────────────────── │   │
│  │  Dhaka         82%    ↑        │ │  Dhaka        18ms   34   67   │   │
│  │  Chattogram    76%    →        │ │  Chattogram   24ms   45   89   │   │
│  │  Rajshahi      71%    ↓        │ │  Rajshahi     28ms   52   98   │   │
│  │  Khulna        69%    →        │ │  Khulna       26ms   48   92   │   │
│  │  Sylhet        74%    ↑        │ │  Sylhet       31ms   58  112   │   │
│  │  Rangpur       68%    →        │ │  Rangpur      29ms   54  103   │   │
│  │  Barishal      65%    ↓        │ │  Barishal     27ms   51   97   │   │
│  │  Mymensingh    73%    ↑        │ │  Mymensingh   32ms   62  118   │   │
│  │                                 │ │                                 │   │
│  │  ┌────────────────────────────┐│ │  ┌────────────────────────────┐│   │
│  │  │▓▓▓▓▓▓▓▓▓▓▓▓░░░░░░░░░░░░░░││ │  │▓▓▓▓▓░░░░░░░░░░░░░░░░░░░░░░││   │
│  │  │    Bandwidth Trend (7d)   ││ │  │    Latency Trend (7d)      ││   │
│  │  └────────────────────────────┘│ │  └────────────────────────────┘│   │
│  └─────────────────────────────────┘ └─────────────────────────────────┘   │
│                                                                             │
│  ┌─────────────────────────────────┐ ┌─────────────────────────────────┐   │
│  │ PACKET LOSS TRACKING           │ │ PoP PERFORMANCE BENCHMARKING    │   │
│  │                                 │ │                                 │   │
│  │  Division      Loss%  Status   │ │  Benchmark vs Division Average  │   │
│  │  ────────────────────────────  │ │                                 │   │
│  │  Dhaka         0.08%  ● Good   │ │  ┌───────────────────────────┐ │   │
│  │  Chattogram    0.11%  ● Good   │ │  │  Above Average  ▓▓▓ 45%  │ │   │
│  │  Rajshahi      0.14%  ● Good   │ │  │  At Average     ░░░ 38%  │ │   │
│  │  Khulna        0.12%  ● Good   │ │  │  Below Average  ░░░ 17%  │ │   │
│  │  Sylhet        0.18%  ○ Warn   │ │  └───────────────────────────┘ │   │
│  │  Rangpur       0.15%  ● Good   │ │                                 │   │
│  │  Barishal      0.13%  ● Good   │ │  Top Performers:               │   │
│  │  Mymensingh    0.21%  ○ Warn   │ │  1. Dhaka PoP-D23 (Score: 98) │   │
│  │                                 │ │  2. Chatt PoP-C11 (Score: 96) │   │
│  │  Alert Threshold: 0.5%         │ │  3. Dhaka PoP-D45 (Score: 95) │   │
│  └─────────────────────────────────┘ └─────────────────────────────────┘   │
│                                                                             │
└─────────────────────────────────────────────────────────────────────────────┘
```

---

### Tab 4: Infrastructure Analytics

```
┌─────────────────────────────────────────────────────────────────────────────┐
│ [Platform Health] [Measurement Network] [Network Metrics] [Infrastructure]  │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                             │
│  ┌─────────────────────────────────────────────────────────────────────┐   │
│  │              INFRASTRUCTURE OVERVIEW                                 │   │
│  │  ┌──────────────┐ ┌──────────────┐ ┌──────────────┐ ┌──────────────┐│   │
│  │  │ TOTAL PoPs   │ │ CAPACITY OK  │ │ CONGESTED    │ │ PLANNED      ││   │
│  │  │   1,892      │ │ ● 1,654      │ │ ○ 178        │ │ ○ 60         ││   │
│  │  │              │ │ (87.4%)      │ │ (9.4%)       │ │ (3.2%)       ││   │
│  │  └──────────────┘ └──────────────┘ └──────────────┘ └──────────────┘│   │
│  └─────────────────────────────────────────────────────────────────────┘   │
│                                                                             │
│  ┌─────────────────────────────────────────────────────────────────────┐   │
│  │ INFRASTRUCTURE MAPPING                                               │   │
│  │                                                                      │   │
│  │  ┌─────────────────────────────────────────────────────────────┐    │   │
│  │  │                    BANGLADESH PoP MAP                        │    │   │
│  │  │                                                              │    │   │
│  │  │       ○ Rangpur (312)                                        │    │   │
│  │  │              ╲                                               │    │   │
│  │  │               ○ Mymensingh (189)    ○ Sylhet (234)           │    │   │
│  │  │                 ╲                  ╱                          │    │   │
│  │  │      ○ Rajshahi   ●═══ DHAKA (645) ═══╮                      │    │   │
│  │  │       (298)              │            │                       │    │   │
│  │  │                  ○ Khulna │           ● Chattogram            │    │   │
│  │  │                   (276)  │            (412)                   │    │   │
│  │  │                          ○ Barishal                           │    │   │
│  │  │                           (198)                               │    │   │
│  │  │                                                              │    │   │
│  │  │  ● Major Hub (>400 PoPs)  ○ Regional Hub (<400 PoPs)         │    │   │
│  │  └─────────────────────────────────────────────────────────────┘    │   │
│  └─────────────────────────────────────────────────────────────────────┘   │
│                                                                             │
│  ┌─────────────────────────────────┐ ┌─────────────────────────────────┐   │
│  │ TRAFFIC ANALYSIS & CONGESTION  │ │ CAPACITY PLANNING (PREDICTIVE)  │   │
│  │                                 │ │                                 │   │
│  │  Peak Hour Congestion:         │ │  3-Month Projection:            │   │
│  │  ┌───────────────────────────┐ │ │  ┌───────────────────────────┐ │   │
│  │  │ 08:00 ░░░░░░░░░░░░ 34%   │ │ │  │ Current: 78% Utilized    │ │   │
│  │  │ 12:00 ░░░░░░░░░░░░ 45%   │ │ │  │ +3 Mo:   83% Estimated   │ │   │
│  │  │ 18:00 ▓▓▓▓▓▓▓▓▓▓▓▓ 78%   │ │ │  │ +6 Mo:   87% Estimated   │ │   │
│  │  │ 21:00 ▓▓▓▓▓▓▓▓▓▓▓▓▓ 89%  │ │ │  │ +12 Mo:  94% Estimated   │ │   │
│  │  │ 00:00 ░░░░░░░░░░░░ 23%   │ │ │  └───────────────────────────┘ │   │
│  │  └───────────────────────────┘ │ │                                 │   │
│  │                                 │ │  Upgrade Recommendations:      │   │
│  │  Bottleneck PoPs (Top 5):      │ │  ├─ Dhaka: +200 Gbps needed   │   │
│  │  1. Dhaka PoP-D12: 94%         │ │  ├─ Chattogram: +80 Gbps      │   │
│  │  2. Dhaka PoP-D45: 91%         │ │  └─ Sylhet: +40 Gbps          │   │
│  │  3. Chatt PoP-C08: 89%         │ │                                 │   │
│  │  4. Dhaka PoP-D78: 87%         │ │  Investment Required: ৳45 Cr  │   │
│  │  5. Sylhet PoP-S03: 86%        │ │                                 │   │
│  └─────────────────────────────────┘ └─────────────────────────────────┘   │
│                                                                             │
│  ┌─────────────────────────────────────────────────────────────────────┐   │
│  │ PERFORMANCE BENCHMARKING BY DIVISION                                 │   │
│  │                                                                      │   │
│  │  Division     │ PoPs │ Avg Score│ vs National │ Trend │ Status     │   │
│  │  ─────────────┼──────┼──────────┼─────────────┼───────┼────────────│   │
│  │  Dhaka        │  645 │   92.3   │   +4.1      │  ↑    │ Excellent  │   │
│  │  Chattogram   │  412 │   89.7   │   +1.5      │  →    │ Good       │   │
│  │  Rajshahi     │  298 │   87.4   │   -0.8      │  ↓    │ Good       │   │
│  │  Khulna       │  276 │   86.9   │   -1.3      │  →    │ Good       │   │
│  │  Sylhet       │  234 │   84.2   │   -4.0      │  ↑    │ Fair       │   │
│  │  Rangpur      │  312 │   85.8   │   -2.4      │  →    │ Fair       │   │
│  │  Barishal     │  198 │   83.1   │   -5.1      │  ↓    │ Fair       │   │
│  │  Mymensingh   │  189 │   81.6   │   -6.6      │  ↑    │ Needs Attn │   │
│  │                                                                      │   │
│  │  National Average: 88.2                                              │   │
│  └─────────────────────────────────────────────────────────────────────┘   │
│                                                                             │
└─────────────────────────────────────────────────────────────────────────────┘
```

---

## ToR/EOI Alignment Verification

### EOI Section 3.8: Data Storage, Analytics and Dashboard

| EOI Requirement | Dashboard Coverage | Status |
|-----------------|-------------------|--------|
| Centralized database(s) | Tab 1: Database Health | ✓ Aligned |
| SNMP integration | Tab 2: External API, Tab 3: Bandwidth | ✓ Aligned |
| API-based integration | Tab 1: API Health, Tab 2: External API | ✓ Aligned |
| Real-time dashboards | All tabs with live metrics | ✓ Aligned |
| Role-based access | Dashboard-level access control | ✓ Aligned |
| Custom report builder | Tab 4: Capacity Planning | ✓ Aligned |

**Result**: All 17 components are ToR/EOI-aligned.

> **Note**: AI/ML Analytics (Anomaly Detection AI, Capacity Forecasting, Performance Correlation, Network Topology) were removed as they have no ToR/EOI basis. PRD v3.1 explicitly removed FR-7.4 (AI/ML Analytics) stating: "Not in EOI scope; no ToR basis for predictive analytics."

---

## Design Principles

### 1. Within-Country Comparisons Only
- All benchmarks are against division/district averages
- No global or international comparisons
- National average as baseline reference

### 2. Technical Operations Focus
- Platform monitoring for system reliability
- Network metrics for QoS assurance
- Trend-based capacity planning for proactive maintenance

### 3. Workflow Alignment
```
Monitor → Diagnose → Analyze → Plan
```
- Tab 1-2: Monitor system and collection
- Tab 3: Diagnose network issues
- Tab 4: Analyze and plan capacity

---

## Related Documents

| Document | Purpose |
|----------|---------|
| `Dashboard_2_Data-Source.md` | Source data mapping |
| `btrc-executive_dashboard-layout-plan-v1.0.md` | Executive Dashboard layout |
| `btrc-regulatory-dashboard-layout-plan-v1.0.md` | Regulatory Dashboard layout |
| `11-DASHBOARD-DESIGN.md` | Master dashboard specifications |

---

## Revision History

| Version | Date | Author | Changes |
|---------|------|--------|---------|
| 1.0 | 2026-01-08 | Claude + User | Initial version |
| 1.1 | 2026-01-08 | Claude + User | Removed Tab 5 (Advanced Analytics) - no ToR/EOI basis. Reduced from 21 to 17 components, 5 to 4 tabs. |

---

**End of Document**
