# DASHBOARD & REPORTING REQUIREMENTS - POC SCOPE

**Document Type:** Team Briefing
**Audience:** Project Manager, Development Team
**Scope:** POC Phase Only
**Version:** 1.0
**Date:** 2026-01-12

---

## 1. EXECUTIVE SUMMARY

### POC Scope Boundary

This document covers dashboard and reporting outputs for the **Proof of Concept** phase of BTRC Fixed Broadband QoS Monitoring System.

### Dashboard Overview

| Dashboard | Tabs | Components | Primary Audience |
|-----------|------|------------|------------------|
| Executive | 5 | 14 | BTRC Leadership |
| Regulatory | 5 | 13 | Compliance Officers |
| Technical Operations | 4 | 17 | System Administrators |
| **TOTAL** | **14** | **44** | - |

### Output Type Distribution

| Output Type | Component Count | Dashboards Using |
|-------------|-----------------|------------------|
| Time-Series Charts | 12 | All 3 |
| KPI Cards/Scorecards | 9 | All 3 |
| Leaderboards/Rankings | 6 | Executive, Regulatory |
| Geographic Maps | 5 | Executive, Regulatory |
| Data Tables | 7 | Regulatory, Technical |
| Bar/Radar/Pie Charts | 3 | Executive, Technical |
| Status Indicators | 2 | Technical |

---

## 2. OUTPUT TYPE: TIME-SERIES CHARTS

### Purpose
Display metric changes over time with selectable periods (1h, 24h, 7d, 30d).

### Components Using This Type

| Component | Dashboard | Tab | Metrics Displayed |
|-----------|-----------|-----|-------------------|
| Speed Trend Graph | Executive | Performance Scorecard | Avg download/upload speeds |
| Latency Trend | Executive | Performance Scorecard | Network latency over time |
| Compliance Trend | Executive | Compliance & Enforcement | SLA compliance % history |
| Consumer Sentiment Trend | Executive | Consumer Experience | Complaint volume over time |
| SLA Violation Trend | Regulatory | SLA Monitoring | Violation counts by period |
| Regional Performance Trend | Regulatory | Regional Analysis | Division-wise metrics |
| System Throughput | Technical | Platform Health | Messages processed/sec |
| Collector Performance | Technical | Measurement Network | Agent response times |
| Network Latency Trend | Technical | Network Metrics | SNMP-collected latency |
| Bandwidth Utilization | Technical | Network Metrics | Link utilization % |
| Storage Growth | Technical | Infrastructure Analytics | DB size over time |
| Query Performance | Technical | Infrastructure Analytics | Avg query latency |

### Requirement Mapping

| Source | Section | Requirement |
|--------|---------|-------------|
| TOR | 3.4 | Real-time QoS monitoring with historical trending |
| TOR | 3.8 | Time-series data storage and visualization |
| PRD | FR-8.1 | Multi-period trend analysis capability |
| PRD | FR-11.2 | Historical QoS metric visualization |

### Data Specification

```
Refresh: 5-minute intervals (configurable)
Retention: 90 days raw, 2 years aggregated
Resolution: 5min → 1hr → 1day rollups
Data Source: qos_measurements hypertable, snmp_metrics hypertable
```

---

## 3. OUTPUT TYPE: KPI CARDS / SCORECARDS

### Purpose
Display single numeric values with comparison indicators (vs previous period, vs target).

### Components Using This Type

| Component | Dashboard | Tab | KPI Displayed |
|-----------|-----------|-----|---------------|
| National Speed Index | Executive | Performance Scorecard | Weighted avg speed (Mbps) |
| ISP Count Card | Executive | Performance Scorecard | Active licensed ISPs |
| Compliance Rate Card | Executive | Compliance & Enforcement | Overall SLA compliance % |
| Active Violations Card | Executive | Compliance & Enforcement | Open violation count |
| Consumer Index | Executive | Consumer Experience | Satisfaction score |
| SLA Compliance Score | Regulatory | SLA Monitoring | Division-wise compliance % |
| Violation Count | Regulatory | Violation Reporting | Total violations (period) |
| System Uptime | Technical | Platform Health | Platform availability % |
| Active Collectors | Technical | Measurement Network | Online agent count |

### Requirement Mapping

| Source | Section | Requirement |
|--------|---------|-------------|
| TOR | 3.3 | Operational metrics display |
| TOR | 3.4 | QoS performance indicators |
| PRD | FR-8.2 | KPI dashboard with drill-down |
| PRD | FR-10.1 | Operational status indicators |

### Data Specification

```
Refresh: 1-minute intervals
Calculation: Real-time aggregation from base tables
Comparison: vs T-1 day, T-7 day, Target threshold
Visual: Green/Yellow/Red based on threshold
Data Source: Continuous aggregates (hourly_qos_stats, daily_compliance_summary)
```

---

## 4. OUTPUT TYPE: LEADERBOARDS & RANKINGS

### Purpose
Display ranked lists of ISPs/regions by performance metrics.

### Components Using This Type

| Component | Dashboard | Tab | Ranking Criteria |
|-----------|-----------|-----|------------------|
| Top 10 ISPs | Executive | Performance Scorecard | By avg speed |
| Bottom 10 ISPs | Executive | Performance Scorecard | By avg speed |
| Regional Leaderboard | Executive | Geographic Intelligence | Division-wise performance |
| ISP Compliance Ranking | Regulatory | SLA Monitoring | By compliance % |
| Violation Leaderboard | Regulatory | Violation Reporting | By violation count |
| Regional Compliance Rank | Regulatory | Regional Analysis | Division compliance ranking |

### Requirement Mapping

| Source | Section | Requirement |
|--------|---------|-------------|
| TOR | 3.4.2 | Comparative ISP performance analysis |
| TOR | 3.5 | Package and service analytics |
| PRD | FR-8.3 | Comparative ranking displays |
| PRD | FR-11.4 | ISP benchmarking capability |

### Data Specification

```
Refresh: 15-minute intervals
Ranking Period: Last 24h, 7d, 30d (selectable)
Tie-breaker: Secondary metric (latency if speed tied)
Data Source: isp_performance_summary, regional_aggregates
```

### Sample Output Structure

```
┌─────┬──────────────────┬───────────┬─────────┬──────────┐
│Rank │ ISP Name         │ Avg Speed │ Latency │ Trend    │
├─────┼──────────────────┼───────────┼─────────┼──────────┤
│ 1   │ ISP Alpha        │ 98.5 Mbps │ 12ms    │ ▲ +2.1%  │
│ 2   │ ISP Beta         │ 95.2 Mbps │ 14ms    │ ▼ -0.5%  │
│ 3   │ ISP Gamma        │ 91.8 Mbps │ 15ms    │ ─  0.0%  │
└─────┴──────────────────┴───────────┴─────────┴──────────┘
```

---

## 5. OUTPUT TYPE: GEOGRAPHIC MAPS / HEATMAPS

### Purpose
Visualize performance metrics on Bangladesh map by division/district.

### Components Using This Type

| Component | Dashboard | Tab | Map Display |
|-----------|-----------|-----|-------------|
| National Coverage Map | Executive | Geographic Intelligence | ISP coverage by district |
| Performance Heatmap | Executive | Geographic Intelligence | Speed by region (color coded) |
| Infrastructure Map | Executive | Infrastructure Status | Collector locations |
| Regional Heatmap | Regulatory | Regional Analysis | Compliance by division |
| Investigation Map | Regulatory | Investigation | Violation hotspots |

### Requirement Mapping

| Source | Section | Requirement |
|--------|---------|-------------|
| TOR | 3.3.3 | Geographic distribution visualization |
| TOR | 3.4.4 | Regional QoS mapping |
| PRD | FR-8.4 | Interactive map-based visualization |
| PRD | FR-11.5 | Drill-down by geographic region |

### Data Specification

```
Refresh: 30-minute intervals
Granularity: Division → District → Upazila (drill-down)
Color Scale: Red (poor) → Yellow (fair) → Green (good)
Geo Reference: BBS geocode standard (8 divisions, 64 districts)
Data Source: regional_performance, collector_status joined with geo_locations
```

### Geographic Hierarchy

```
Bangladesh (Country)
├── Dhaka Division
│   ├── Dhaka District
│   │   ├── Dhanmondi Upazila
│   │   ├── Gulshan Upazila
│   │   └── ...
│   ├── Gazipur District
│   └── ...
├── Chittagong Division
└── ... (8 divisions total)
```

---

## 6. OUTPUT TYPE: DATA TABLES

### Purpose
Display detailed records with sorting, filtering, and export capabilities.

### Components Using This Type

| Component | Dashboard | Tab | Data Displayed |
|-----------|-----------|-----|----------------|
| Violation Detail Table | Regulatory | Violation Reporting | All violations with status |
| Investigation Queue | Regulatory | Investigation | Pending cases with priority |
| License Compliance Grid | Regulatory | License Compliance | ISP license status |
| Collector Status Table | Technical | Measurement Network | All agents with health |
| SNMP Device Table | Technical | Network Metrics | Monitored devices list |
| Alert History Table | Technical | Platform Health | Recent system alerts |
| Query Log Table | Technical | Infrastructure Analytics | Slow query analysis |

### Requirement Mapping

| Source | Section | Requirement |
|--------|---------|-------------|
| TOR | 3.3.1 | Detailed operational data access |
| TOR | 3.8.2 | Tabular data export capability |
| PRD | FR-8.5 | Sortable, filterable data grids |
| PRD | FR-10.3 | Operational log viewing |

### Data Specification

```
Refresh: On-demand with auto-refresh option
Page Size: 25/50/100 rows (configurable)
Export: CSV, Excel, PDF
Filters: Column-based, date range, status
Data Source: Direct table queries with pagination
```

### Sample Table Structure

```
┌────────────┬─────────────┬──────────┬──────────┬─────────┐
│ Violation# │ ISP         │ Type     │ Date     │ Status  │
├────────────┼─────────────┼──────────┼──────────┼─────────┤
│ V-2026-001 │ ISP Alpha   │ Speed    │ 01-10    │ Open    │
│ V-2026-002 │ ISP Beta    │ Latency  │ 01-11    │ Pending │
│ V-2026-003 │ ISP Gamma   │ Uptime   │ 01-12    │ Closed  │
└────────────┴─────────────┴──────────┴──────────┴─────────┘
[Export CSV] [Export Excel] [Refresh]
```

---

## 7. OUTPUT TYPE: BAR / RADAR / PIE CHARTS

### Purpose
Display categorical comparisons and distributions.

### Components Using This Type

| Component | Dashboard | Tab | Chart Type | Data Displayed |
|-----------|-----------|-----|------------|----------------|
| Package Distribution | Executive | Performance Scorecard | Pie | Subscriber by package tier |
| Technology Breakdown | Technical | Infrastructure Analytics | Bar | Fiber vs DSL vs Cable |
| Collector Coverage | Technical | Measurement Network | Radar | Agent metrics comparison |

### Requirement Mapping

| Source | Section | Requirement |
|--------|---------|-------------|
| TOR | 3.5.1 | Package analytics visualization |
| TOR | 3.5.2 | Technology distribution analysis |
| PRD | FR-9.2 | Package mix analysis charts |
| PRD | FR-10.4 | Infrastructure composition view |

### Data Specification

```
Refresh: Hourly
Chart Types:
  - Pie: Distribution/composition (max 8 segments)
  - Bar: Comparison across categories
  - Radar: Multi-metric comparison
Data Source: package_distribution, technology_breakdown views
```

---

## 8. OUTPUT TYPE: STATUS INDICATORS

### Purpose
Display system health using visual indicators (traffic lights, gauges).

### Components Using This Type

| Component | Dashboard | Tab | Indicator Type | Status Display |
|-----------|-----------|-----|----------------|----------------|
| Platform Health Gauge | Technical | Platform Health | Gauge | CPU/Memory/Disk % |
| Service Status Panel | Technical | Platform Health | Traffic Light | Service up/down |

### Requirement Mapping

| Source | Section | Requirement |
|--------|---------|-------------|
| TOR | 3.8.3 | System health monitoring |
| PRD | FR-10.5 | Infrastructure health indicators |

### Data Specification

```
Refresh: 30-second intervals
Thresholds:
  - Green: 0-70% utilization / Service UP
  - Yellow: 70-85% utilization / Service DEGRADED
  - Red: 85%+ utilization / Service DOWN
Data Source: system_metrics, service_health tables
```

### Visual Reference

```
Platform Health Gauge:
    ┌───────────────────────┐
    │      CPU: 45%         │
    │   ████████░░░░░░░░    │  [GREEN]
    │                       │
    │    Memory: 72%        │
    │   █████████████░░░    │  [YELLOW]
    │                       │
    │     Disk: 38%         │
    │   ██████░░░░░░░░░░    │  [GREEN]
    └───────────────────────┘

Service Status Panel:
    ┌───────────────────────┐
    │ API Gateway     [●]   │  GREEN = UP
    │ QoS Collector   [●]   │  GREEN = UP
    │ SNMP Poller     [●]   │  YELLOW = DEGRADED
    │ Report Service  [●]   │  GREEN = UP
    └───────────────────────┘
```

---

## 9. CROSS-REFERENCE MATRIX

### Component → Output Type → Dashboard → Requirement

| # | Component | Output Type | Dashboard | TOR | PRD |
|---|-----------|-------------|-----------|-----|-----|
| 1 | Speed Trend Graph | Time-Series | Executive | 3.4 | FR-11.2 |
| 2 | National Speed Index | KPI Card | Executive | 3.4 | FR-8.2 |
| 3 | Top 10 ISPs | Leaderboard | Executive | 3.4.2 | FR-8.3 |
| 4 | National Coverage Map | Map | Executive | 3.3.3 | FR-8.4 |
| 5 | Package Distribution | Pie Chart | Executive | 3.5.1 | FR-9.2 |
| 6 | Compliance Rate Card | KPI Card | Executive | 3.4 | FR-8.2 |
| 7 | Compliance Trend | Time-Series | Executive | 3.4 | FR-11.2 |
| 8 | Consumer Index | KPI Card | Executive | 3.4 | FR-8.2 |
| 9 | Infrastructure Map | Map | Executive | 3.3.3 | FR-8.4 |
| 10 | SLA Compliance Score | KPI Card | Regulatory | 3.4 | FR-8.2 |
| 11 | SLA Violation Trend | Time-Series | Regulatory | 3.4 | FR-11.2 |
| 12 | ISP Compliance Ranking | Leaderboard | Regulatory | 3.4.2 | FR-8.3 |
| 13 | Regional Heatmap | Map | Regulatory | 3.4.4 | FR-11.5 |
| 14 | Regional Performance Trend | Time-Series | Regulatory | 3.4 | FR-11.2 |
| 15 | Violation Detail Table | Table | Regulatory | 3.3.1 | FR-8.5 |
| 16 | Violation Leaderboard | Leaderboard | Regulatory | 3.4.2 | FR-8.3 |
| 17 | Investigation Queue | Table | Regulatory | 3.3.1 | FR-8.5 |
| 18 | Investigation Map | Map | Regulatory | 3.4.4 | FR-11.5 |
| 19 | License Compliance Grid | Table | Regulatory | 3.3.1 | FR-8.5 |
| 20 | System Uptime | KPI Card | Technical | 3.3 | FR-10.1 |
| 21 | System Throughput | Time-Series | Technical | 3.8 | FR-10.3 |
| 22 | Platform Health Gauge | Gauge | Technical | 3.8.3 | FR-10.5 |
| 23 | Service Status Panel | Traffic Light | Technical | 3.8.3 | FR-10.5 |
| 24 | Active Collectors | KPI Card | Technical | 3.3 | FR-10.1 |
| 25 | Collector Performance | Time-Series | Technical | 3.8 | FR-10.3 |
| 26 | Collector Status Table | Table | Technical | 3.3.1 | FR-10.3 |
| 27 | Collector Coverage | Radar | Technical | 3.8 | FR-10.4 |
| 28 | Network Latency Trend | Time-Series | Technical | 3.4 | FR-11.2 |
| 29 | Bandwidth Utilization | Time-Series | Technical | 3.4 | FR-11.2 |
| 30 | SNMP Device Table | Table | Technical | 3.3.1 | FR-10.3 |
| 31 | Technology Breakdown | Bar Chart | Technical | 3.5.2 | FR-10.4 |
| 32 | Storage Growth | Time-Series | Technical | 3.8 | FR-10.3 |
| 33 | Query Performance | Time-Series | Technical | 3.8 | FR-10.3 |
| 34 | Alert History Table | Table | Technical | 3.3.1 | FR-10.3 |
| 35 | Query Log Table | Table | Technical | 3.3.1 | FR-10.3 |

---

## 10. LAYOUT FILE REFERENCES

### Dashboard Layout Plans

For detailed component specifications, wireframes, and interaction patterns, refer to:

| Dashboard | Layout File |
|-----------|-------------|
| Executive | [Design-Doc(DASHBOARD-EXECUTIVE)](BTRC-FXBB-QOS-POC_Design-Doc(DASHBOARD-EXECUTIVE)_FINAL_v1.0.md) |
| Regulatory | [Design-Doc(DASHBOARD-REGULATORY)](BTRC-FXBB-QOS-POC_Design-Doc(DASHBOARD-REGULATORY)_FINAL_v1.0.md) |
| Technical Operations | [Design-Doc(DASHBOARD-TECH-OPS)](BTRC-FXBB-QOS-POC_Design-Doc(DASHBOARD-TECH-OPS)_FINAL_v1.0.md) |

### Source Requirement Documents

| Document | Location |
|----------|----------|
| EOI/TOR Full Text | [EOI-PDF_to_MD-Full-Text.md](../../_INBOX/EOI-PDF_to_MD-Full-Text.md) |
| PRD v3.1 | [16-PRD-BTRC-QoS-MONITORING-v3.1.md](../../_INBOX/16-PRD-BTRC-QoS-MONITORING-v3.1.md) |

### Usage Notes

- Layout files contain detailed wireframe descriptions
- Use layout files for UI implementation specifications
- This document provides requirement-to-component traceability
- Cross-reference matrix (Section 9) enables impact analysis

---

## QUICK REFERENCE: OUTPUT TYPE BY DATA SOURCE

```
┌─────────────────────────────────────────────────────────────────────────┐
│                     DATA SOURCE → OUTPUT TYPE FLOW                      │
├─────────────────────────────────────────────────────────────────────────┤
│                                                                         │
│  ┌──────────────┐     ┌─────────────────┐     ┌───────────────────┐   │
│  │ QoS Agent    │────▶│ qos_measurements│────▶│ Time-Series       │   │
│  │ (Speed Test) │     │ (hypertable)    │     │ KPI Cards         │   │
│  └──────────────┘     └─────────────────┘     │ Leaderboards      │   │
│                                               └───────────────────┘   │
│  ┌──────────────┐     ┌─────────────────┐     ┌───────────────────┐   │
│  │ SNMP Agent   │────▶│ snmp_metrics    │────▶│ Time-Series       │   │
│  │ (Device Poll)│     │ (hypertable)    │     │ Data Tables       │   │
│  └──────────────┘     └─────────────────┘     │ Gauges            │   │
│                                               └───────────────────┘   │
│  ┌──────────────┐     ┌─────────────────┐     ┌───────────────────┐   │
│  │ ISP API      │────▶│ isp_submissions │────▶│ Data Tables       │   │
│  │ (Subscriber) │     │ (table)         │     │ Pie/Bar Charts    │   │
│  └──────────────┘     └─────────────────┘     │ Maps              │   │
│                                               └───────────────────┘   │
│  ┌──────────────┐     ┌─────────────────┐     ┌───────────────────┐   │
│  │ Continuous   │────▶│ hourly_stats    │────▶│ KPI Cards         │   │
│  │ Aggregates   │     │ daily_summary   │     │ Leaderboards      │   │
│  └──────────────┘     └─────────────────┘     │ Maps              │   │
│                                               └───────────────────┘   │
└─────────────────────────────────────────────────────────────────────────┘
```

---

**END OF DOCUMENT**
