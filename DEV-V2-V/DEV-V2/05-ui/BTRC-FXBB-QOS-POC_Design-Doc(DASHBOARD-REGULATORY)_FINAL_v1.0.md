# BTRC Regulatory Dashboard - Tabbed Layout Design

**Document Version**: 1.1
**Date**: 2026-01-08
**Project**: BTRC Fixed Broadband QoS Monitoring System
**Scope**: Regulatory Dashboard (BTRC Operations View)

---

## Overview

This document defines a **5-tab functional grouping** for the Regulatory Dashboard, organizing 13 components following a monitoring-first workflow for BTRC Operations staff.

### Design Principles

- **Monitoring-First**: Detect issues before taking action
- **ToR-Aligned**: All components derived from ToR requirements (PRD enhancements excluded)
- **Investigation-Ready**: Dedicated deep-dive capabilities
- **Within-Country Focus**: All comparisons at division/district level only

### Key Design Decisions

| Decision | Choice | Rationale |
|----------|--------|-----------|
| Section 2.8 Interconnection | REMOVED | Not in ToR scope (peering/IXP not required) |
| Section 2.3 Enforcement | RENAMED | Changed to "Violation Reporting" (ToR-aligned) |
| Fine Calculation | EXCLUDED | PRD enhancement, not ToR requirement |
| Tab 1 Split | YES | Separated SLA Monitoring from Regional Analysis |

---

## Tab Navigation Structure

```
+------------------------------------------------------------------------------+
| BTRC QoS Monitoring - Regulatory Operations              12 Alerts  Officer |
+------------------------------------------------------------------------------+
| +------------++------------++------------++------------++----------------+   |
| |    SLA     ||  REGIONAL  || VIOLATION  || INVESTI-   ||    LICENSE     |   |
| | MONITORING ||  ANALYSIS  || REPORTING  ||  GATION    ||   COMPLIANCE   |   |
| +------------++------------++------------++------------++----------------+   |
|  ^ ACTIVE                                                                    |
+------------------------------------------------------------------------------+
| ISP: All | Division: All | Period: Last 24h | Live | Export                  |
+------------------------------------------------------------------------------+
```

---

## Component Summary Table

### Section 2.1: SLA Tracking

| Component | Primary Source | Description |
|-----------|----------------|-------------|
| Automated monitoring vs packages | QoS Collector | Real-time comparison of measured QoS metrics against ISP-advertised package specifications; auto-flagging when delivered speed/latency deviates from committed SLA thresholds; package-level compliance percentages |
| PoP-level performance validation | QoS Collector | Granular performance validation at each Point of Presence; speed test results mapped to specific PoPs; identifies underperforming locations for targeted regulatory action |

### Section 2.2: Violation Detection

| Component | Primary Source | Description |
|-----------|----------------|-------------|
| Real-time threshold alerts | QoS Collector | Instant notifications when SLA thresholds are breached; configurable alert rules per ISP category, metric type, and severity level; alert queue with acknowledgment workflow; escalation timers |
| PoP-specific incident ID | QoS Collector | Unique incident tracking tied to specific PoP and violation type; incident lifecycle management (open - acknowledged - investigating - resolved); linkage to reporting |

### Section 2.3: Violation Reporting (Renamed from Enforcement Tools)

| Component | Primary Source | Description |
|-----------|----------------|-------------|
| Violation report generation | QoS Collector | Structured reports of detected SLA violations; filterable by ISP, time period, violation type, severity; exportable in PDF/Excel for external enforcement proceedings |
| Evidence documentation | QoS Collector | Detailed violation evidence packages with timestamped metrics, threshold comparisons, affected PoP/subscriber data; audit-ready format for regulatory use |

### Section 2.4: Investigation Support

| Component | Primary Source | Description |
|-----------|----------------|-------------|
| Data drill-down & correlation | All Sources | Multi-dimensional query interface for deep analysis; cross-reference QoS data with SNMP metrics, ISP submissions, and consumer complaints; timeline correlation to identify root causes; evidence collection |
| PoP infrastructure impact | SNMP Collector | Analysis of how infrastructure issues affect service quality; correlation between PoP health metrics and QoS violations; identifies systemic vs isolated problems; capacity constraint detection |

### Section 2.5: Infrastructure Compliance

| Component | Primary Source | Description |
|-----------|----------------|-------------|
| PoP deployment adherence | ISP-Submitted | Tracking of ISP infrastructure deployment against license commitments; PoP count by district vs required minimums; deployment timeline compliance; gap analysis for underserved areas |
| Licensed commitment monitoring | ISP-Submitted | Monitoring of all license conditions: coverage targets, subscriber commitments, quality thresholds; license renewal readiness indicators; commitment vs actual performance trends |

### Section 2.6: Regional Service Equity

| Component | Primary Source | Description |
|-----------|----------------|-------------|
| Geographic performance tracking | QoS Collector | Division and district-level performance tracking; urban vs rural quality disparity metrics; identifies regions with consistently poor service; equity scoring for regulatory prioritization |
| ISP performance by area | QoS Collector | Per-ISP performance breakdown by geographic region; comparative analysis of ISPs serving same areas; identifies market concentration issues; supports competition policy decisions |

### Section 2.7: Capacity Utilization

| Component | Primary Source | Description |
|-----------|----------------|-------------|
| PoP capacity vs licensed | SNMP Collector | Real-time capacity utilization at each PoP compared to licensed/declared capacity; identifies over-subscribed PoPs; capacity headroom analysis; license violation detection for capacity misreporting |
| Utilization trends | SNMP Collector | Historical capacity utilization patterns; peak hour analysis; seasonal pattern detection; threshold-based alerts when utilization exceeds configured limits |

---

## Primary Source Distribution

| Primary Source | Count | Percentage | Components |
|----------------|-------|------------|------------|
| QoS Collector | 8 | 62% | SLA monitoring (2), Violation detection (2), Violation reporting (2), Regional equity (2) |
| SNMP Collector | 3 | 23% | PoP infrastructure impact, PoP capacity vs licensed, Utilization trends |
| ISP-Submitted | 2 | 15% | PoP deployment adherence, Licensed commitment monitoring |
| All Sources | 1 | - | Data drill-down & correlation (Investigation) |

---

## Tab Mapping

### Tab 1: SLA Monitoring (4 components)

**Purpose**: "Are ISPs meeting their service commitments?"
**Primary Source**: QoS Collector
**Refresh Rate**: 5 minutes (auto)
**Workflow Stage**: DETECT

| Component | From Section |
|-----------|--------------|
| Automated monitoring vs packages | 2.1 |
| PoP-level performance validation | 2.1 |
| Real-time threshold alerts | 2.2 |
| PoP-specific incident ID | 2.2 |

### Tab 2: Regional Analysis (2 components)

**Purpose**: "Where are service quality issues concentrated?"
**Primary Source**: QoS Collector
**Refresh Rate**: 15 minutes (auto)
**Workflow Stage**: LOCATE

| Component | From Section |
|-----------|--------------|
| Geographic performance tracking | 2.6 |
| ISP performance by area | 2.6 |

### Tab 3: Violation Reporting (2 components)

**Purpose**: "What violations need to be documented?"
**Primary Source**: QoS Collector
**Refresh Rate**: On-demand
**Workflow Stage**: DOCUMENT

| Component | From Section |
|-----------|--------------|
| Violation report generation | 2.3 |
| Evidence documentation | 2.3 |

### Tab 4: Investigation Center (2+ components)

**Purpose**: "What is causing this issue?"
**Primary Source**: All Sources
**Refresh Rate**: On-demand
**Workflow Stage**: ANALYZE

| Component | From Section |
|-----------|--------------|
| Data drill-down & correlation | 2.4 |
| PoP infrastructure impact | 2.4 |
| Query Builder | Derived tool |
| Timeline Analyzer | Derived tool |

### Tab 5: License Compliance (4 components)

**Purpose**: "Are ISPs meeting infrastructure commitments?"
**Primary Source**: ISP-Submitted + SNMP
**Refresh Rate**: 30 minutes (auto)
**Workflow Stage**: AUDIT

| Component | From Section |
|-----------|--------------|
| PoP deployment adherence | 2.5 |
| Licensed commitment monitoring | 2.5 |
| PoP capacity vs licensed | 2.7 |
| Utilization trends | 2.7 |

---

## Workflow Alignment

```
MONITORING-FIRST WORKFLOW (Left to Right)

+----------+   +----------+   +----------+   +----------+   +----------+
|   SLA    |-->| REGIONAL |-->|VIOLATION |-->| INVESTI- |-->| LICENSE  |
|MONITORING|   | ANALYSIS |   |REPORTING |   |  GATION  |   |COMPLIANCE|
+----------+   +----------+   +----------+   +----------+   +----------+

DETECT         LOCATE         DOCUMENT       ANALYZE        AUDIT
"What?"        "Where?"       "Record it"    "Why?"         "License?"
```

---

## Tab 1: SLA Monitoring Layout

```
+------------------------------------------------------------------------------+
|                                                                              |
|  +------------------------------------------------------------------------+  |
|  |                    SLA COMPLIANCE OVERVIEW                             |  |
|  |                                                                        |  |
|  |   +-----------------+  +-----------------+  +-----------------+        |  |
|  |   | COMPLIANT       |  | AT RISK         |  | VIOLATION       |        |  |
|  |   |     847         |  |      89         |  |      34         |        |  |
|  |   |    ISPs         |  |     ISPs        |  |     ISPs        |        |  |
|  |   |  87% of total   |  |  9% of total    |  |  4% of total    |        |  |
|  |   +-----------------+  +-----------------+  +-----------------+        |  |
|  |                                                                        |  |
|  |   Total Monitored: 970 ISPs | Last Check: 2 min ago | Refresh         |  |
|  +------------------------------------------------------------------------+  |
|                                                                              |
|  +--------------------------------+  +------------------------------------+  |
|  |  PACKAGE COMPLIANCE MATRIX     |  |  REAL-TIME THRESHOLD ALERTS        |  |
|  |                                |  |                                    |  |
|  |  Package    |Target|Actual|Gap |  |  12 Active Alerts                  |  |
|  |  -----------|------|------|----+  |  ---------------------------------- |  |
|  |  10 Mbps    | 10.0 |  9.2 |-8% |  |  ISP-Alpha: Speed <50% (Dhaka)     |  |
|  |  25 Mbps    | 25.0 | 23.1 |-8% |  |     10.2 Mbps vs 25 Mbps | 45m ago |  |
|  |  50 Mbps    | 50.0 | 47.8 |-4% |  |  ---------------------------------- |  |
|  |  100 Mbps   |100.0 | 94.2 |-6% |  |  ISP-Beta: Availability <99%       |  |
|  |  200+ Mbps  |200.0 |189.5 |-5% |  |     97.2% uptime | 2h 15m ago      |  |
|  |                                |  |                                    |  |
|  |  [Filter by Category]          |  |  [View All Alerts] [Acknowledge]   |  |
|  +--------------------------------+  +------------------------------------+  |
|                                                                              |
|  +------------------------------------------------------------------------+  |
|  |                    PoP-LEVEL PERFORMANCE VALIDATION                    |  |
|  | -----------------------------------------------------------------------|  |
|  |                                                                        |  |
|  |  Incident ID | ISP          | PoP Location     | Metric  | Status     |  |
|  |  ------------|--------------|------------------|---------|----------- |  |
|  |  INC-2024-847| ISP-Alpha    | Dhaka-Gulshan    | Speed   | Open       |  |
|  |  INC-2024-846| ISP-Beta     | CTG-Agrabad      | Uptime  | Ack'd      |  |
|  |  INC-2024-845| ISP-Gamma    | Khulna-Sonadanga | Latency | Open       |  |
|  |  INC-2024-844| ISP-Delta    | Rajshahi-Saheb   | Speed   | Resolved   |  |
|  |                                                                        |  |
|  |  [Sort: Time] [Filter: Open] [Bulk Acknowledge] [Export to Report]    |  |
|  +------------------------------------------------------------------------+  |
|                                                                              |
+------------------------------------------------------------------------------+
```

---

## Tab 2: Regional Analysis Layout

```
+------------------------------------------------------------------------------+
|                                                                              |
|  +-------------------------------------+  +----------------------------+     |
|  |         DIVISION PERFORMANCE MAP    |  |   DIVISION RANKING         |     |
|  |                                     |  |                            |     |
|  |  +-------------------------------+  |  |  Division    | Score |Trend|     |
|  |  |           BANGLADESH          |  |  |  ------------|-------|-----|     |
|  |  |      +-----+                  |  |  |  Dhaka       | 94.2  | Up  |     |
|  |  |      |RANG-|  +-----+         |  |  |  Chittagong  | 91.8  | --  |     |
|  |  |      |PUR  |  |SYLHT|         |  |  |  Khulna      | 88.5  | Up  |     |
|  |  |      |     |  |     |         |  |  |  Rajshahi    | 86.7  | Dn  |     |
|  |  |  +---+-----+--+-----+---+     |  |  |  Sylhet      | 82.3  | Dn  |     |
|  |  |  |      RAJSHAHI        |     |  |  |  Rangpur     | 81.9  | --  |     |
|  |  |  |                      |+----+  |  |  Barishal    | 78.4  | Up  |     |
|  |  |  +----------------------+|DHKA|  |  |  Mymensingh  | 74.1  | Dn  |     |
|  |  |       +----------+   +--+----+|  |  |                            |     |
|  |  |       | KHULNA   |   |CHTTGRM||  |  |  Score = Weighted avg of   |     |
|  |  |       +----------+   +-------+|  |  |  speed, availability,      |     |
|  |  |    +--------+      +--------+ |  |  |  latency compliance        |     |
|  |  |    |BARISHAL|      |MYMNSGH | |  |  |                            |     |
|  |  |    +--------+      +--------+ |  |  |  [Drill to District]       |     |
|  |  +-------------------------------+  |  +----------------------------+     |
|  |  Legend: >90  80-90  70-80  <70    |                                      |
|  |  [Toggle: Score | Speed | Avail]   |                                      |
|  +-------------------------------------+                                      |
|                                                                              |
|  +------------------------------------------------------------------------+  |
|  |                    ISP PERFORMANCE BY AREA                             |  |
|  | -----------------------------------------------------------------------|  |
|  |                                                                        |  |
|  |  Division: Mymensingh (Lowest Score: 74.1)         [Change Division]   |  |
|  |                                                                        |  |
|  |  ISP              | PoPs | Avg Speed | Availability | Violations |Score|  |
|  |  -----------------|------|-----------|--------------|------------|-----|  |
|  |  Link3            |  12  |  28.4 Mbps|    98.9%     |     2      |82.1 |  |
|  |  Amber IT         |   8  |  24.1 Mbps|    97.2%     |     5      |71.3 |  |
|  |  Carnival         |   6  |  21.8 Mbps|    96.8%     |     7      |68.9 |  |
|  |  Circle Net       |   4  |  19.2 Mbps|    95.1%     |     9      |62.4 |  |
|  |                                                                        |  |
|  |  4 ISPs below acceptable threshold (Score < 70)                        |  |
|  |                                                                        |  |
|  |  [Sort: Score] [Filter: Violations >5] [Generate Regional Report]     |  |
|  +------------------------------------------------------------------------+  |
|                                                                              |
+------------------------------------------------------------------------------+
```

---

## Tab 3: Violation Reporting Layout

```
+------------------------------------------------------------------------------+
|                                                                              |
|  +------------------------------------------------------------------------+  |
|  |                    VIOLATION SUMMARY                                   |  |
|  |                                                                        |  |
|  |   +-------------------+  +-------------------+  +-------------------+  |  |
|  |   |  PENDING REPORT   |  |  UNDER REVIEW     |  |  COMPLETED        |  |  |
|  |   |       23          |  |       12          |  |      156          |  |  |
|  |   |   violations      |  |   violations      |  |   this month      |  |  |
|  |   | Need documentation|  | Awaiting approval |  | Reports issued    |  |  |
|  |   +-------------------+  +-------------------+  +-------------------+  |  |
|  +------------------------------------------------------------------------+  |
|                                                                              |
|  +------------------------------------------------------------------------+  |
|  |                    VIOLATION REPORT GENERATOR                          |  |
|  | -----------------------------------------------------------------------|  |
|  |                                                                        |  |
|  |  Select Violations for Report:                                         |  |
|  |                                                                        |  |
|  |  Sel| ID          | ISP         | Type     | Severity | Duration |PoP |  |
|  |  ---|-------------|-------------|----------|----------|----------|--- |  |
|  |  [x]| VIO-2024-312| ISP-Alpha   | Speed    | Critical | 4h 23m   | 3  |  |
|  |  [x]| VIO-2024-311| ISP-Alpha   | Speed    | Major    | 2h 10m   | 1  |  |
|  |  [ ]| VIO-2024-310| ISP-Beta    | Uptime   | Critical | 1h 45m   | 2  |  |
|  |  [x]| VIO-2024-309| ISP-Gamma   | Latency  | Minor    | 45m      | 1  |  |
|  |                                                                        |  |
|  |  Selected: 3 violations | [Select All] [Clear] [Filter: Pending]      |  |
|  |                                                                        |  |
|  |  +------------------------------------------------------------------+  |  |
|  |  |  Report Options                                                  |  |  |
|  |  |  ( ) Individual Reports (one per violation)                      |  |  |
|  |  |  (o) Consolidated Report (group by ISP)                          |  |  |
|  |  |  ( ) Summary Report (statistics only)                            |  |  |
|  |  |                                                                  |  |  |
|  |  |  Format: [PDF]  Include: [x] Charts [x] Raw Data [x] Timestamps  |  |  |
|  |  +------------------------------------------------------------------+  |  |
|  |                                                                        |  |
|  |  [Preview Report]  [Generate & Download]  [Send to Review Queue]      |  |
|  +------------------------------------------------------------------------+  |
|                                                                              |
|  +------------------------------------------------------------------------+  |
|  |                    EVIDENCE DOCUMENTATION                              |  |
|  | -----------------------------------------------------------------------|  |
|  |                                                                        |  |
|  |  Selected Violation: VIO-2024-312 (ISP-Alpha, Speed, Critical)         |  |
|  |                                                                        |  |
|  |  +-------------------------+  +-------------------------------------+  |  |
|  |  |  METRIC SNAPSHOT        |  |  EVIDENCE PACKAGE                   |  |  |
|  |  |                         |  |                                     |  |  |
|  |  |  Metric: Download Speed |  |  [x] Time-series data (CSV)         |  |  |
|  |  |  Threshold: 25 Mbps     |  |  [x] Threshold breach log           |  |  |
|  |  |  Measured: 10.2 Mbps    |  |  [x] PoP identification             |  |  |
|  |  |  Gap: -59.2%            |  |  [x] Affected subscriber estimate   |  |  |
|  |  |  Duration: 4h 23m       |  |  [x] Historical comparison          |  |  |
|  |  |  Start: 2024-01-08 08:15|  |  [ ] SNMP correlation data          |  |  |
|  |  |  End: 2024-01-08 12:38  |  |  [ ] Consumer complaints (if any)   |  |  |
|  |  |                         |  |                                     |  |  |
|  |  |  Affected PoPs: 3       |  |  [Generate Evidence Package]        |  |  |
|  |  |  Est. Subscribers: ~4200|  |                                     |  |  |
|  |  +-------------------------+  +-------------------------------------+  |  |
|  +------------------------------------------------------------------------+  |
|                                                                              |
+------------------------------------------------------------------------------+
```

---

## Tab 4: Investigation Center Layout

```
+------------------------------------------------------------------------------+
|                                                                              |
|  +------------------------------------------------------------------------+  |
|  |  QUERY BUILDER                                                  [Save] |  |
|  | -----------------------------------------------------------------------|  |
|  |                                                                        |  |
|  |  Data Source: [QoS Collector] [+ Add Source]                           |  |
|  |                                                                        |  |
|  |  +------------------------------------------------------------------+  |  |
|  |  | WHERE                                                            |  |  |
|  |  | +--------------+ +--------+ +-----------------+                  |  |  |
|  |  | | isp_id       | | =      | | ISP-Alpha       | [+ Add Condition]|  |  |
|  |  | +--------------+ +--------+ +-----------------+                  |  |  |
|  |  | AND                                                              |  |  |
|  |  | +--------------+ +--------+ +-----------------+                  |  |  |
|  |  | | metric_type  | | =      | | download_speed  | [x]              |  |  |
|  |  | +--------------+ +--------+ +-----------------+                  |  |  |
|  |  | AND                                                              |  |  |
|  |  | +--------------+ +--------+ +-----------------+                  |  |  |
|  |  | | timestamp    | | between| | Last 7 days     | [x]              |  |  |
|  |  | +--------------+ +--------+ +-----------------+                  |  |  |
|  |  +------------------------------------------------------------------+  |  |
|  |                                                                        |  |
|  |  [Run Query]  [Clear]  [Load Saved Query]                              |  |
|  +------------------------------------------------------------------------+  |
|                                                                              |
|  +------------------------------------+  +--------------------------------+  |
|  |  TIMELINE ANALYZER                 |  |  CROSS-SOURCE CORRELATION      |  |
|  |                                    |  |                                |  |
|  |  ISP-Alpha Speed (Last 7 Days)     |  |  Correlating: Speed Drop Event |  |
|  |                                    |  |  Time: 2024-01-08 08:15        |  |
|  |  50|                               |  |                                |  |
|  |    |==================            |  |  +----------------------------+ |  |
|  |  25|======================        |  |  | QoS Collector              | |  |
|  |    |----------------------------- |  |  | Speed: 10.2 Mbps (!)       | |  |
|  |   0|==========================    |  |  +----------------------------+ |  |
|  |    +--Mon-Tue-Wed-Thu-Fri-Sat-Sun |  |           |                     |  |
|  |         ^                         |  |           v                     |  |
|  |    Anomaly detected: Thu 08:15    |  |  +----------------------------+ |  |
|  |                                    |  |  | SNMP Collector             | |  |
|  |  [Zoom] [Pan] [Export]             |  |  | Interface util: 98.7% (!)  | |  |
|  +------------------------------------+  |  | Errors: 1,247 packets      | |  |
|                                          |  +----------------------------+ |  |
|  +------------------------------------+  |           |                     |  |
|  |  PoP INFRASTRUCTURE IMPACT         |  |           v                     |  |
|  |                                    |  |  +----------------------------+ |  |
|  |  Affected PoPs for ISP-Alpha:      |  |  | ISP-Submitted              | |  |
|  |                                    |  |  | Capacity: 1 Gbps           | |  |
|  |  PoP          | Util | Health |Sub |  |  | Subscribers: 4,200         | |  |
|  |  -------------|------|--------|----+  |  +----------------------------+ |  |
|  |  Dhaka-Gulshan| 98%  | Crit   |2.1k|  |                                |  |
|  |  Dhaka-Banani | 87%  | Warn   |1.4k|  |  FINDING: Capacity exhaustion |  |
|  |  Dhaka-Uttara | 72%  | OK     |0.7k|  |  at Gulshan PoP likely cause  |  |
|  |                                    |  |                                |  |
|  |  Root Cause: Capacity constraint   |  |  [Generate Investigation Report]|
|  +------------------------------------+  +--------------------------------+  |
|                                                                              |
+------------------------------------------------------------------------------+
```

---

## Tab 5: License Compliance Layout

```
+------------------------------------------------------------------------------+
|                                                                              |
|  +------------------------------------------------------------------------+  |
|  |                    LICENSE COMPLIANCE OVERVIEW                         |  |
|  |                                                                        |  |
|  |   +-----------------+  +-----------------+  +-----------------+        |  |
|  |   | COMPLIANT       |  | PARTIAL         |  | NON-COMPLIANT   |        |  |
|  |   |     892         |  |      56         |  |      22         |        |  |
|  |   |    ISPs         |  |     ISPs        |  |     ISPs        |        |  |
|  |   |  Meeting all    |  |  1-2 gaps       |  |  3+ gaps or     |        |  |
|  |   |  commitments    |  |                 |  |  critical miss  |        |  |
|  |   +-----------------+  +-----------------+  +-----------------+        |  |
|  +------------------------------------------------------------------------+  |
|                                                                              |
|  +--------------------------------+  +------------------------------------+  |
|  |  PoP DEPLOYMENT ADHERENCE      |  |  LICENSED COMMITMENT MONITORING    |  |
|  |                                |  |                                    |  |
|  |  Division     |Commit|Actual|Gap| |  ISP: [Select ISP]                 |  |
|  |  -------------|------|------|---|  |                                    |  |
|  |  Dhaka        |  450 |  487 |+37|  |  ISP-Alpha License Summary:        |  |
|  |  Chittagong   |  320 |  298 |-22|  |  ---------------------------------- |  |
|  |  Khulna       |  180 |  175 | -5|  |                                    |  |
|  |  Rajshahi     |  150 |  142 | -8|  |  Commitment      |Target|Actual|Gap|  |
|  |  Sylhet       |  120 |  108 |-12|  |  -----------------|------|------|--|  |
|  |  Rangpur      |  100 |   94 | -6|  |  Coverage (dist)  |  45  |  42  |-3|  |
|  |  Barishal     |   80 |   71 | -9|  |  PoP Count        | 120  | 115  |-5|  |
|  |  Mymensingh   |   60 |   49 |-11|  |  Min Speed (Mbps) |  25  |  23  |-2|  |
|  |                                |  |  Availability (%) |99.5  |99.1  |-.4| |
|  |  TOTAL        | 1460 | 1424 |-36|  |  Subscribers (k)  | 150  | 142  |-8|  |
|  |                                |  |                                    |  |
|  |  5 divisions below target      |  |  License Status: PARTIAL           |  |
|  |  [View Gap Details]            |  |  Next Review: 2024-06-30           |  |
|  +--------------------------------+  +------------------------------------+  |
|                                                                              |
|  +------------------------------------------------------------------------+  |
|  |                    CAPACITY UTILIZATION                                |  |
|  | -----------------------------------------------------------------------|  |
|  |                                                                        |  |
|  |  +-----------------------------------+  +----------------------------+ |  |
|  |  |  PoP CAPACITY vs LICENSED         |  |  UTILIZATION TRENDS        | |  |
|  |  |                                   |  |                            | |  |
|  |  |  ISP-Alpha PoPs:                  |  |  ISP-Alpha Avg Utilization | |  |
|  |  |                                   |  |  (Last 8 Months)           | |  |
|  |  |  PoP          |License|Actual|Util|  |  100%|                      | |  |
|  |  |  -------------|-------|------|----+  |      |              ===     | |  |
|  |  |  Dhaka-Gulshan| 1 Gbps|1 Gbps| 98%|  |   75%|- - - - - - - ===- -  | |  |
|  |  |  Dhaka-Banani | 1 Gbps|1 Gbps| 87%|  |      |      ===  ===Thresh  | |  |
|  |  |  Dhaka-Uttara | 1 Gbps|1 Gbps| 72%|  |   50%|===  ===              | |  |
|  |  |  Dhaka-Mirpur |500Mbps|500Mb | 65%|  |      +-J-F-M-A-M-J-J-A-    | |  |
|  |  |  Dhaka-Motijh |500Mbps|500Mb | 58%|  |                            | |  |
|  |  |                                   |  |  (!) 2 PoPs currently      | |  |
|  |  |  2 PoPs above 85% threshold       |  |  above 85% threshold       | |  |
|  |  |  [View All PoPs]                  |  |                            | |  |
|  |  +-----------------------------------+  +----------------------------+ |  |
|  |                                                                        |  |
|  |  [Generate License Compliance Report]  [Export Capacity Analysis]     |  |
|  +------------------------------------------------------------------------+  |
|                                                                              |
+------------------------------------------------------------------------------+
```

---

## Tab Architecture Summary

| Tab | Components | Primary Source | Refresh Rate | Workflow |
|-----|------------|----------------|--------------|----------|
| 1. SLA Monitoring | 4 | QoS Collector | 5 min (auto) | DETECT |
| 2. Regional Analysis | 2 | QoS Collector | 15 min (auto) | LOCATE |
| 3. Violation Reporting | 2 | QoS Collector | On-demand | DOCUMENT |
| 4. Investigation Center | 2+ | All Sources | On-demand | ANALYZE |
| 5. License Compliance | 4 | ISP + SNMP | 30 min (auto) | AUDIT |
| **TOTAL** | **14+** | **Multi-source** | **Variable** | |

---

## Navigation Features

- **Persistent header** with global filters (ISP, Division, Time Period)
- **Cross-tab drill-down** (click violation -> jumps to Investigation)
- **Tab-specific filters** (within-tab filtering)
- **Export/Print per tab**
- **Alert badge per tab** (pending items count)
- **Within-country focus** - All comparisons at division/district level only

---

## Comparison: Executive vs Regulatory Dashboard

| Aspect | Executive (5 tabs) | Regulatory (5 tabs) |
|--------|-------------------|---------------------|
| Components | 14 | 13 (+2 derived tools) |
| Primary Focus | Strategic KPIs | Operational compliance |
| Workflow | Overview -> Drill-down | Detect -> Document -> Analyze |
| Action Orientation | Policy decisions | Violation documentation |
| Unique Feature | Infrastructure Status | Investigation Center |
| Tab Balance | 4-5-2-2-1 | 4-2-2-2+-4 |

---

## Removed/Excluded Components

| Component | Original Section | Reason |
|-----------|-----------------|--------|
| Peering relationships | 2.8 | Not in ToR scope |
| Traffic exchange efficiency | 2.8 | Not in ToR scope |
| Automated fine calculation | 2.3 | PRD enhancement, not ToR |
| Notice generation | 2.3 | PRD enhancement, not ToR |
| Location-based severity | 2.3 | PRD enhancement, not ToR |

---

## Changelog

| Date | Version | Changes |
|------|---------|---------|
| 2026-01-08 | 1.0 | Initial regulatory dashboard design; ToR-aligned components only |
| 2026-01-08 | 1.1 | Removed predictive language from "Utilization trends" (growth projections, capacity exhaustion forecasting) - no ToR basis. Updated comparison table to reflect Executive Dashboard changes. |

---

**Source Document**: `Dashboard_2_Data-Source.md`
**Related Documents**: `btrc-executive-dashboard-layout-plan-v1.0.md`, `11-DASHBOARD-DESIGN.md`
