# BTRC Regulatory Dashboard - Datasets & Charts Reference

**Created**: 2026-02-01
**Dashboard**: Regulatory Operations Dashboard
**Total Datasets**: 18
**Total Charts**: 27

---

## Quick Reference

| Symbol | Meaning |
|--------|---------|
| 🔄 | Transformed/Calculated data |
| 📊 | Raw data with minimal formatting |
| 🔢 | Aggregated data |
| 📈 | Time-series data |

---

## TAB 1: SLA MONITORING

### Dataset: `reg_isp_compliance_detail`
| Property | Value |
|----------|-------|
| **Type** | 🔄 Transformed |
| **Source Tables** | `ts_qos_measurements`, `pops`, `isps`, `geo_districts`, `geo_divisions` |
| **Used By** | REG 1.1a, REG 1.1b, REG 1.1c (Big Numbers), Filters |

**Transformations:**
- Calculates `compliance_status` based on latency and packet loss thresholds
- Aggregates metrics per ISP with AVG functions
- Adds `division_id`, `division_name` for filtering

```sql
-- Key calculated field
CASE
    WHEN avg_latency < 50 AND avg_packet_loss < 0.5 THEN 'Compliant'
    WHEN avg_latency < 100 AND avg_packet_loss < 1.5 THEN 'At Risk'
    ELSE 'Violation'
END as compliance_status
```

---

### Dataset: `reg_package_compliance`
| Property | Value |
|----------|-------|
| **Type** | 🔄 Transformed |
| **Source Tables** | `packages`, `isps`, `pops`, `ts_qos_measurements` |
| **Used By** | REG 1.2 - Package Compliance Matrix |

**Transformations:**
- Groups packages into tiers (10 Mbps, 25 Mbps, etc.)
- Calculates gap percentage between target and actual speed
- Uses CASE statements for tier classification

---

### Dataset: `reg_realtime_alerts`
| Property | Value |
|----------|-------|
| **Type** | 🔄 Transformed |
| **Source Tables** | `sla_violations`, `isps`, `pops`, `geo_districts` |
| **Used By** | REG 1.3 - Real-Time Alerts |

**Transformations:**
- Calculates `time_ago` from detection_time
- Maps severity to display labels (Critical, Major, Minor)
- Formats alert_title and alert_details strings

---

### Dataset: `reg_pop_incidents`
| Property | Value |
|----------|-------|
| **Type** | 🔄 Transformed |
| **Source Tables** | `sla_violations`, `isps`, `pops`, `geo_districts` |
| **Used By** | REG 1.4 - PoP Incidents |

**Transformations:**
- Generates `incident_id` format (INC-YYYY-XXXX)
- Calculates duration from detection_time
- Formats PoP location string

---

## TAB 2: REGIONAL ANALYSIS

### Dataset: `reg_division_map`
| Property | Value |
|----------|-------|
| **Type** | 🔄 Transformed |
| **Source Tables** | `geo_divisions`, `geo_districts`, `pops`, `ts_qos_measurements` |
| **Used By** | REG 2.0 - Division Performance Map |

**Transformations:**
- Maps division names to ISO codes (BD-A, BD-B, etc.)
- Calculates composite score from speed, latency, packet loss
- Required for Country Map visualization

```sql
-- ISO Code mapping
CASE division_name
    WHEN 'Barishal' THEN 'BD-A'
    WHEN 'Chattogram' THEN 'BD-B'
    WHEN 'Dhaka' THEN 'BD-C'
    -- ... etc
END as iso_code
```

---

### Dataset: `reg_division_performance`
| Property | Value |
|----------|-------|
| **Type** | 🔄 Transformed |
| **Source Tables** | `geo_divisions`, `geo_districts`, `pops`, `isps`, `ts_qos_measurements`, `sla_violations` |
| **Used By** | REG 2.1 - Division Ranking |

**Transformations:**
- Calculates composite `score` (0-100) from multiple metrics
- Determines `health_status` (Good/Fair/Poor)
- Aggregates counts per division

---

### Dataset: `reg_district_performance`
| Property | Value |
|----------|-------|
| **Type** | 🔄 Transformed |
| **Source Tables** | `geo_divisions`, `geo_districts`, `pops`, `isps`, `ts_qos_measurements`, `sla_violations` |
| **Used By** | REG 2.2 - District Performance |

**Transformations:**
- Same scoring formula as division level
- Includes `division_id` for drill-down filtering

---

### Dataset: `reg_isp_area_performance`
| Property | Value |
|----------|-------|
| **Type** | 🔄 Transformed |
| **Source Tables** | `isps`, `pops`, `geo_districts`, `geo_divisions`, `ts_qos_measurements`, `sla_violations` |
| **Used By** | REG 2.3 - ISP Performance by Area |

**Transformations:**
- Calculates availability percentage
- Computes composite score per ISP per area
- Includes violation count

---

## TAB 3: VIOLATION REPORTING

### Dataset: `reg_violation_summary`
| Property | Value |
|----------|-------|
| **Type** | 🔢 Aggregated |
| **Source Tables** | `sla_violations` |
| **Used By** | REG 3.1a, REG 3.1b, REG 3.1c (Big Numbers) |

**Transformations:**
- COUNT with FILTER for status categories
- Simple aggregation, minimal transformation

```sql
COUNT(*) FILTER (WHERE status = 'DETECTED') as pending_report,
COUNT(*) FILTER (WHERE status = 'INVESTIGATING') as under_review,
COUNT(*) FILTER (WHERE status = 'RESOLVED') as completed
```

---

### Dataset: `reg_violation_reports`
| Property | Value |
|----------|-------|
| **Type** | 🔄 Transformed |
| **Source Tables** | `sla_violations`, `isps`, `pops`, `geo_districts`, `geo_divisions` |
| **Used By** | REG 3.2 - Violation Report Generator |

**Transformations:**
- Generates `violation_code` (VIO-YYYY-XXX)
- Maps violation_type to display labels
- Calculates duration string

---

### Dataset: `reg_evidence_documentation`
| Property | Value |
|----------|-------|
| **Type** | 🔄 Transformed |
| **Source Tables** | `sla_violations`, `isps`, `pops`, `geo_districts`, `geo_divisions` |
| **Used By** | REG 3.3 - Evidence Documentation |

**Transformations:**
- Formats gap percentage with +/- sign
- Estimates subscriber impact
- Formats duration in human-readable form

---

## TAB 4: INVESTIGATION CENTER

### Dataset: `reg_investigation_overview`
| Property | Value |
|----------|-------|
| **Type** | 🔢 Aggregated |
| **Source Tables** | `sla_violations` |
| **Used By** | REG 4.1a, REG 4.1b, REG 4.1c (Big Numbers) |

**Transformations:**
- Simple COUNT aggregations with FILTER
- COUNT DISTINCT for affected entities

---

### Dataset: `reg_timeline_analyzer`
| Property | Value |
|----------|-------|
| **Type** | 📈 Time-series |
| **Source Tables** | `ts_qos_measurements`, `pops`, `isps`, `geo_districts`, `geo_divisions` |
| **Used By** | REG 4.2 - Timeline Analyzer |

**Transformations:**
- DATE_TRUNC to hourly buckets
- AVG aggregations per time bucket
- Includes dimension columns for filtering

---

### Dataset: `reg_pop_infrastructure`
| Property | Value |
|----------|-------|
| **Type** | 🔄 Transformed |
| **Source Tables** | `pops`, `isps`, `geo_districts`, `geo_divisions`, `ts_interface_metrics`, `ts_qos_measurements`, `sla_violations` |
| **Used By** | REG 4.3 - PoP Infrastructure Impact |

**Transformations:**
- Calculates `health_score` (1-4 numeric) for conditional formatting
- Determines `health_status` string (Critical/Warning/Degraded/Healthy)
- Calculates `root_cause_code` and `root_cause` string
- Estimates subscriber count

```sql
-- Health score for conditional formatting
CASE
    WHEN utilization > 90 THEN 1  -- Critical
    WHEN utilization > 75 THEN 2  -- Warning
    WHEN avg_latency > 100 OR avg_packet_loss > 2 THEN 3  -- Degraded
    ELSE 4  -- Healthy
END as health_score
```

---

## TAB 5: LICENSE COMPLIANCE

### Dataset: `reg_license_overview`
| Property | Value |
|----------|-------|
| **Type** | 🔢 Aggregated |
| **Source Tables** | `isps`, `pops`, `geo_districts`, `ts_qos_measurements` |
| **Used By** | REG 5.1a, REG 5.1b, REG 5.1c (Big Numbers) |

**Transformations:**
- COUNT with FILTER for compliance categories
- Compliance logic based on PoP count, speed, availability

---

### Dataset: `reg_pop_deployment`
| Property | Value |
|----------|-------|
| **Type** | 🔄 Transformed |
| **Source Tables** | `geo_divisions`, `geo_districts`, `pops`, `isps` |
| **Used By** | REG 5.2 - PoP Deployment Adherence |

**Transformations:**
- Hardcoded `committed` targets per division (can be moved to config table)
- Calculates `gap` (actual - committed)
- Determines `status` (Met/Below Target)

```sql
-- Hardcoded targets (should ideally come from a config table)
CASE division_name
    WHEN 'Dhaka' THEN 45
    WHEN 'Chattogram' THEN 32
    -- ... etc
END as committed
```

---

### Dataset: `reg_license_commitment`
| Property | Value |
|----------|-------|
| **Type** | 🔄 Transformed (Pivoted) |
| **Source Tables** | `isps`, `isp_license_categories`, `pops`, `geo_districts`, `ts_qos_measurements` |
| **Used By** | REG 5.3 - Licensed Commitment Monitoring |

**Transformations:**
- **PIVOTED structure** - metrics as rows, not columns
- Uses UNION ALL to create row-based view
- Targets based on license category (Nationwide/Zonal/Local)
- Calculates gap for each metric

```sql
-- Pivot structure using UNION ALL
SELECT 'Coverage (dist)' as commitment, target, actual, gap FROM ...
UNION ALL
SELECT 'PoP Count' as commitment, target, actual, gap FROM ...
UNION ALL
-- ... etc
```

---

### Dataset: `reg_pop_capacity`
| Property | Value |
|----------|-------|
| **Type** | 🔄 Transformed |
| **Source Tables** | `pops`, `isps`, `geo_districts`, `geo_divisions`, `ts_interface_metrics` |
| **Used By** | REG 5.4 - PoP Capacity vs Licensed |

**Transformations:**
- Formats capacity as human-readable (1 Gbps, 500 Mbps)
- Calculates utilization percentage
- Used with Cell Bars visualization

```sql
-- Capacity formatting
CASE
    WHEN bandwidth >= 1000 THEN CONCAT((bandwidth / 1000)::text, ' Gbps')
    ELSE CONCAT(bandwidth::text, ' Mbps')
END as license_capacity
```

---

### Dataset: `reg_utilization_trends`
| Property | Value |
|----------|-------|
| **Type** | 📈 Time-series |
| **Source Tables** | `ts_interface_metrics`, `pops`, `geo_districts`, `geo_divisions` |
| **Used By** | REG 5.5 - Utilization Trends |

**Transformations:**
- DATE_TRUNC to daily buckets
- AVG and MAX aggregations
- Static threshold line (85%)

---

## FILTER DATASETS

### Dataset: `filter_isps`
| Property | Value |
|----------|-------|
| **Type** | 📊 Raw |
| **Source Tables** | `isps` |
| **Used By** | ISP filter across all tabs |

```sql
SELECT id, name_en as isp_name FROM isps ORDER BY name_en
```

---

### Dataset: `filter_divisions`
| Property | Value |
|----------|-------|
| **Type** | 📊 Raw |
| **Source Tables** | `geo_divisions` |
| **Used By** | Division filter across all tabs |

```sql
SELECT id, name_en as division_name FROM geo_divisions ORDER BY name_en
```

---

## SUMMARY TABLE

| # | Dataset | Tab | Type | Key Transformations |
|---|---------|-----|------|---------------------|
| 1 | reg_isp_compliance_detail | 1 | 🔄 Transformed | Compliance status calculation |
| 2 | reg_package_compliance | 1 | 🔄 Transformed | Package tier grouping, gap % |
| 3 | reg_realtime_alerts | 1 | 🔄 Transformed | Time ago, severity mapping |
| 4 | reg_pop_incidents | 1 | 🔄 Transformed | Incident ID format, duration |
| 5 | reg_division_map | 2 | 🔄 Transformed | ISO codes, composite score |
| 6 | reg_division_performance | 2 | 🔄 Transformed | Score calculation, health status |
| 7 | reg_district_performance | 2 | 🔄 Transformed | Score calculation |
| 8 | reg_isp_area_performance | 2 | 🔄 Transformed | Availability %, score |
| 9 | reg_violation_summary | 3 | 🔢 Aggregated | COUNT with FILTER |
| 10 | reg_violation_reports | 3 | 🔄 Transformed | Violation code, duration |
| 11 | reg_evidence_documentation | 3 | 🔄 Transformed | Gap formatting, estimates |
| 12 | reg_investigation_overview | 4 | 🔢 Aggregated | COUNT with FILTER |
| 13 | reg_timeline_analyzer | 4 | 📈 Time-series | Hourly buckets, AVG |
| 14 | reg_pop_infrastructure | 4 | 🔄 Transformed | Health score/status, root cause |
| 15 | reg_license_overview | 5 | 🔢 Aggregated | COUNT with FILTER |
| 16 | reg_pop_deployment | 5 | 🔄 Transformed | Hardcoded targets, gap |
| 17 | reg_license_commitment | 5 | 🔄 Transformed | **PIVOTED** structure |
| 18 | reg_pop_capacity | 5 | 🔄 Transformed | Capacity formatting, utilization |
| 19 | reg_utilization_trends | 5 | 📈 Time-series | Daily buckets, threshold |
| 20 | filter_isps | All | 📊 Raw | Simple SELECT |
| 21 | filter_divisions | All | 📊 Raw | Simple SELECT |

---

## CHARTS SUMMARY

| # | Chart | Tab | Type | Dataset |
|---|-------|-----|------|---------|
| 1 | REG 1.1a - Compliant ISPs | 1 | Big Number | reg_isp_compliance_detail |
| 2 | REG 1.1b - At Risk ISPs | 1 | Big Number | reg_isp_compliance_detail |
| 3 | REG 1.1c - Violation ISPs | 1 | Big Number | reg_isp_compliance_detail |
| 4 | REG 1.2 - Package Compliance Matrix | 1 | Table | reg_package_compliance |
| 5 | REG 1.3 - Real-Time Alerts | 1 | Table | reg_realtime_alerts |
| 6 | REG 1.4 - PoP Incidents | 1 | Table | reg_pop_incidents |
| 7 | REG 2.0 - Division Performance Map | 2 | Country Map | reg_division_map |
| 8 | REG 2.1 - Division Ranking | 2 | Table | reg_division_performance |
| 9 | REG 2.2 - District Performance | 2 | Table | reg_district_performance |
| 10 | REG 2.3 - ISP Performance by Area | 2 | Table | reg_isp_area_performance |
| 11 | REG 3.1a - Pending Report | 3 | Big Number | reg_violation_summary |
| 12 | REG 3.1b - Under Review | 3 | Big Number | reg_violation_summary |
| 13 | REG 3.1c - Completed | 3 | Big Number | reg_violation_summary |
| 14 | REG 3.2 - Violation Report Generator | 3 | Table | reg_violation_reports |
| 15 | REG 3.3 - Evidence Documentation | 3 | Table | reg_evidence_documentation |
| 16 | REG 4.1a - Open Cases | 4 | Big Number | reg_investigation_overview |
| 17 | REG 4.1b - In Progress | 4 | Big Number | reg_investigation_overview |
| 18 | REG 4.1c - Affected PoPs | 4 | Big Number | reg_investigation_overview |
| 19 | REG 4.2 - Timeline Analyzer | 4 | Line Chart | reg_timeline_analyzer |
| 20 | REG 4.3 - PoP Infrastructure Impact | 4 | Table | reg_pop_infrastructure |
| 21 | REG 5.1a - Compliant ISPs | 5 | Big Number | reg_license_overview |
| 22 | REG 5.1b - Partial Compliance | 5 | Big Number | reg_license_overview |
| 23 | REG 5.1c - Non-Compliant | 5 | Big Number | reg_license_overview |
| 24 | REG 5.2 - PoP Deployment Adherence | 5 | Table | reg_pop_deployment |
| 25 | REG 5.3 - Licensed Commitment Monitoring | 5 | Table | reg_license_commitment |
| 26 | REG 5.4 - PoP Capacity vs Licensed | 5 | Table | reg_pop_capacity |
| 27 | REG 5.5 - Utilization Trends | 5 | Line Chart | reg_utilization_trends |

---

## NOTES

### Conditional Formatting Requirements
Superset conditional formatting only works with **numeric columns**. For string-based status fields, we create:
- A numeric `_score` or `_code` column for formatting
- A string `_status` column for display

Example:
```sql
health_score (1-4 numeric) -> for conditional formatting
health_status (Critical/Warning/Degraded/Healthy) -> for display
```

### Hardcoded Values to Consider Moving to Config Tables
1. `reg_pop_deployment` - Division PoP targets
2. `reg_license_commitment` - License category targets
3. Threshold values (85% utilization, 50ms latency, etc.)

### Drill-Down Hierarchy
```
Division → District → ISP → PoP
```

All datasets include `division_id`, `district_id`, `isp_id` where applicable for filtering.

---

**End of Document**
